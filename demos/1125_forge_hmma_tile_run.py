"""Forge-native tensor-core HMMA tile (m16n8k16 fp16->f32) — GPU validation.

Kernel: hmma_tile(A: span<u16>, B: span<u16>, C: span<f32>)
        Single warp (32 lanes), single mma.sync.aligned.m16n8k16.row.col instruction.
        D = A (16x16 fp16) @ B (16x8 fp16) + C (16x8 f32).

PTX m16n8k16 row/col fragment layout (per PTX 8.x docs):
  group_id = tid / 4   (0..7),  thread_in_group = tid % 4   (0..3)
  A is 16x16 row-major; per thread holds 8 fp16:
    a0..1 = A[group_id,    2*tig + 0..1]
    a2..3 = A[group_id+8,  2*tig + 0..1]
    a4..5 = A[group_id,    2*tig + 8..9]
    a6..7 = A[group_id+8,  2*tig + 8..9]
  B is 16x8 col-major (.col layout); per thread holds 4 fp16:
    b0..1 = B[2*tig + 0..1,  group_id]
    b2..3 = B[2*tig + 8..9,  group_id]
  C is 16x8 row-major; per thread holds 4 f32:
    c0..1 = C[group_id,    2*tig + 0..1]
    c2..3 = C[group_id+8,  2*tig + 0..1]
The Forge kernel reads/writes per-lane storage at base + tid*sizeof(fragment).
A: 8 fp16 per lane = 16 bytes/lane;  B: 4 fp16/lane = 8 bytes/lane;  C: 4 f32/lane = 16 bytes/lane.
Total flat sizes: A=256 fp16, B=128 fp16, C=128 f32.
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1125_forge_hmma_tile.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


def pack_A_frag(A_mat):
    """A_mat is 16x16 fp16; returns 256-element fp16 array in per-lane order."""
    out = np.empty(256, dtype=np.float16)
    for tid in range(32):
        g = tid // 4; tig = tid % 4
        base = tid * 8
        out[base + 0] = A_mat[g,        2 * tig + 0]
        out[base + 1] = A_mat[g,        2 * tig + 1]
        out[base + 2] = A_mat[g + 8,    2 * tig + 0]
        out[base + 3] = A_mat[g + 8,    2 * tig + 1]
        out[base + 4] = A_mat[g,        2 * tig + 8]
        out[base + 5] = A_mat[g,        2 * tig + 9]
        out[base + 6] = A_mat[g + 8,    2 * tig + 8]
        out[base + 7] = A_mat[g + 8,    2 * tig + 9]
    return out


def pack_B_frag(B_mat):
    """B_mat is 16x8 fp16; returns 128-element fp16 array in per-lane order."""
    out = np.empty(128, dtype=np.float16)
    for tid in range(32):
        g = tid // 4; tig = tid % 4
        base = tid * 4
        out[base + 0] = B_mat[2 * tig + 0,  g]
        out[base + 1] = B_mat[2 * tig + 1,  g]
        out[base + 2] = B_mat[2 * tig + 8,  g]
        out[base + 3] = B_mat[2 * tig + 9,  g]
    return out


def pack_C_frag(C_mat):
    """C_mat is 16x8 f32; returns 128-element f32 array in per-lane order."""
    out = np.empty(128, dtype=np.float32)
    for tid in range(32):
        g = tid // 4; tig = tid % 4
        base = tid * 4
        out[base + 0] = C_mat[g,        2 * tig + 0]
        out[base + 1] = C_mat[g,        2 * tig + 1]
        out[base + 2] = C_mat[g + 8,    2 * tig + 0]
        out[base + 3] = C_mat[g + 8,    2 * tig + 1]
    return out


def unpack_D_frag(D_frag):
    """Inverse of pack_C_frag — recover 16x8 f32 matrix from per-lane fragment."""
    out = np.empty((16, 8), dtype=np.float32)
    for tid in range(32):
        g = tid // 4; tig = tid % 4
        base = tid * 4
        out[g,        2 * tig + 0] = D_frag[base + 0]
        out[g,        2 * tig + 1] = D_frag[base + 1]
        out[g + 8,    2 * tig + 0] = D_frag[base + 2]
        out[g + 8,    2 * tig + 1] = D_frag[base + 3]
    return out


print("FORGE: 1125_hmma_tile (m16n8k16 fp16 -> f32)")
print("-" * 60)
ok, total = 0, 0
ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"hmma_tile"))


for trial in range(5):
    rng = np.random.default_rng(trial * 17 + 1)
    A_mat = rng.standard_normal((16, 16)).astype(np.float16)
    B_mat = rng.standard_normal((16, 8)).astype(np.float16)
    C_mat = rng.standard_normal((16, 8)).astype(np.float32) * 0.1
    A_frag = pack_A_frag(A_mat); B_frag = pack_B_frag(B_mat); C_frag = pack_C_frag(C_mat)
    A_u16 = A_frag.view(np.uint16); B_u16 = B_frag.view(np.uint16)
    D_frag_gpu = C_frag.copy()  # kernel writes back to same C buffer

    d_a = ctypes.c_uint64(); d_b = ctypes.c_uint64(); d_c = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_a), A_u16.nbytes))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_b), B_u16.nbytes))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_c), C_frag.nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_a, A_u16.ctypes.data_as(ctypes.c_void_p), A_u16.nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_b, B_u16.ctypes.data_as(ctypes.c_void_p), B_u16.nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_c, D_frag_gpu.ctypes.data_as(ctypes.c_void_p), C_frag.nbytes))
    items = [ctypes.c_uint64(d_a.value), ctypes.c_uint64(256),
             ctypes.c_uint64(d_b.value), ctypes.c_uint64(128),
             ctypes.c_uint64(d_c.value), ctypes.c_uint64(128)]
    addrs = [ctypes.cast(ctypes.pointer(x), ctypes.c_void_p) for x in items]
    params = (ctypes.c_void_p * len(addrs))(*addrs)
    ck(cuda.cuLaunchKernel(fn, 1, 1, 1, 32, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(D_frag_gpu.ctypes.data, d_c, C_frag.nbytes))

    D_gpu = unpack_D_frag(D_frag_gpu)
    D_ref = (A_mat.astype(np.float32) @ B_mat.astype(np.float32)) + C_mat
    err = np.abs(D_gpu - D_ref); max_err, mean_err = float(err.max()), float(err.mean())
    # mma.sync.f16 accumulates in f32 with fma rounding — ULP at scale ~k*1.0 is ~1e-3
    correct = max_err < 5e-3
    total += 1; ok += int(correct)
    print(f"  trial {trial}  max_err={max_err:.2e}  mean_err={mean_err:.2e}  {'PASS' if correct else 'FAIL'}")

    cuda.cuMemFree_v2(d_a); cuda.cuMemFree_v2(d_b); cuda.cuMemFree_v2(d_c)


cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 60); print(f"OVERALL: {ok}/{total}")
