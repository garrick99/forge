"""Forge-native tensor-core FP8 MMA tile (m16n8k32 e4m3 -> f32) — GPU validation.

Kernel: fp8_mma_tile(A: span<u8>, B: span<u8>, C: span<f32>)
        Single warp, mma.sync.aligned.m16n8k32.row.col.f32.e4m3.e4m3.f32.
        D = A (16x32 e4m3) @ B (32x8 e4m3) + C (16x8 f32)

PTX m16n8k32 fp8 row/col fragment layout:
  group_id = tid / 4,  thread_in_group = tid % 4
  A is 16x32 row-major; per thread holds 16 fp8 = 4 .b32 regs:
    a[0..3]   = A[group_id,    4*tig + 0..3]
    a[4..7]   = A[group_id+8,  4*tig + 0..3]
    a[8..11]  = A[group_id,    4*tig + 16..19]
    a[12..15] = A[group_id+8,  4*tig + 16..19]
  B is 32x8 col-major; per thread holds 8 fp8 = 2 .b32 regs:
    b[0..3] = B[4*tig + 0..3,  group_id]
    b[4..7] = B[4*tig + 16..19, group_id]
  C/D is 16x8 row-major; per thread holds 4 f32 (same as fp16 MMA).

Total flat sizes: A=512 fp8, B=256 fp8, C=128 f32.

To avoid implementing an E4M3 encoder, this harness restricts inputs to
values exactly representable in E4M3 (small integers like {-4,-2,-1,0,1,2,4})
and uses pre-built bit patterns. With small integer inputs the matmul result
fits comfortably within f32 precision and the e4m3 encoding has no rounding.
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1127_forge_fp8_mma.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


# E4M3 bit patterns for the values we'll use:
#   sign(1) | exp(4, bias=7) | mantissa(3)
#   1.0 = 1.0 * 2^0 → exp_field=7=0b0111, mant=0 → 0b00111000 = 0x38
#   2.0 = 1.0 * 2^1 → exp_field=8, mant=0 → 0x40
#   4.0 = 1.0 * 2^2 → exp_field=9, mant=0 → 0x48
#   3.0 = 1.5 * 2^1 → exp_field=8, mant=4 → 0x44
#   negatives: same | 0x80
E4M3_TABLE = {
    -4.0: 0xC8, -3.0: 0xC4, -2.0: 0xC0, -1.5: 0xBC, -1.0: 0xB8, -0.5: 0xB0,
     0.0: 0x00,
     0.5: 0x30,  1.0: 0x38,  1.5: 0x3C,  2.0: 0x40,  3.0: 0x44,  4.0: 0x48,
}
SUPPORTED = sorted(E4M3_TABLE.keys())


def f32_to_e4m3_table(x_arr):
    """Encode f32 -> e4m3 byte using a small table of exact values."""
    out = np.empty(x_arr.shape, dtype=np.uint8)
    flat = x_arr.flat; out_flat = out.flat
    for i, v in enumerate(flat):
        v_round = float(v)
        # Snap to nearest supported value
        nearest = min(SUPPORTED, key=lambda s: abs(s - v_round))
        out_flat[i] = E4M3_TABLE[nearest]
    return out


def random_supported(rng, *shape):
    """Pick random values from SUPPORTED list."""
    idx = rng.integers(0, len(SUPPORTED), size=shape)
    out = np.empty(shape, dtype=np.float32)
    out_flat = out.flat
    idx_flat = idx.flat
    for i, j in enumerate(idx_flat):
        out_flat[i] = SUPPORTED[j]
    return out


def pack_A_frag_e4m3(A_mat):
    """A is 16x32 e4m3 (uint8); return 512-element u8 in per-lane order."""
    out = np.empty(512, dtype=np.uint8)
    for tid in range(32):
        g = tid // 4; tig = tid % 4
        base = tid * 16
        for j in range(4):
            out[base + j]      = A_mat[g,        4 * tig + j]
            out[base + 4 + j]  = A_mat[g + 8,    4 * tig + j]
            out[base + 8 + j]  = A_mat[g,        4 * tig + 16 + j]
            out[base + 12 + j] = A_mat[g + 8,    4 * tig + 16 + j]
    return out


def pack_B_frag_e4m3(B_mat):
    """B is 32x8 e4m3 col-major (uint8); return 256-element u8 in per-lane order."""
    out = np.empty(256, dtype=np.uint8)
    for tid in range(32):
        g = tid // 4; tig = tid % 4
        base = tid * 8
        for j in range(4):
            out[base + j]      = B_mat[4 * tig + j,       g]
            out[base + 4 + j]  = B_mat[4 * tig + 16 + j,  g]
    return out


def pack_C_frag(C_mat):
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
    out = np.empty((16, 8), dtype=np.float32)
    for tid in range(32):
        g = tid // 4; tig = tid % 4
        base = tid * 4
        out[g,        2 * tig + 0] = D_frag[base + 0]
        out[g,        2 * tig + 1] = D_frag[base + 1]
        out[g + 8,    2 * tig + 0] = D_frag[base + 2]
        out[g + 8,    2 * tig + 1] = D_frag[base + 3]
    return out


print("FORGE: 1127_fp8_mma (m16n8k32 e4m3 -> f32)")
print("-" * 60)
ok, total = 0, 0
ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"fp8_mma_tile"))


for trial in range(5):
    rng = np.random.default_rng(trial * 11 + 1)
    # Use small values to keep accumulator within f32 precision
    A_f32 = random_supported(rng, 16, 32)   # values in {-4..4}
    B_f32 = random_supported(rng, 32, 8)
    C_f32 = (rng.standard_normal((16, 8)) * 0.1).astype(np.float32)

    A_e4m3 = f32_to_e4m3_table(A_f32)
    B_e4m3 = f32_to_e4m3_table(B_f32)
    A_frag = pack_A_frag_e4m3(A_e4m3)
    B_frag = pack_B_frag_e4m3(B_e4m3)
    C_frag = pack_C_frag(C_f32.copy())
    D_gpu_buf = C_frag.copy()

    d_a = ctypes.c_uint64(); d_b = ctypes.c_uint64(); d_c = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_a), A_frag.nbytes))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_b), B_frag.nbytes))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_c), C_frag.nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_a, A_frag.ctypes.data_as(ctypes.c_void_p), A_frag.nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_b, B_frag.ctypes.data_as(ctypes.c_void_p), B_frag.nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_c, D_gpu_buf.ctypes.data_as(ctypes.c_void_p), C_frag.nbytes))
    items = [ctypes.c_uint64(d_a.value), ctypes.c_uint64(512),
             ctypes.c_uint64(d_b.value), ctypes.c_uint64(256),
             ctypes.c_uint64(d_c.value), ctypes.c_uint64(128)]
    addrs = [ctypes.cast(ctypes.pointer(x), ctypes.c_void_p) for x in items]
    params = (ctypes.c_void_p * len(addrs))(*addrs)
    ck(cuda.cuLaunchKernel(fn, 1, 1, 1, 32, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(D_gpu_buf.ctypes.data, d_c, C_frag.nbytes))

    D_gpu = unpack_D_frag(D_gpu_buf)
    D_ref = (A_f32 @ B_f32) + C_f32
    err = np.abs(D_gpu - D_ref); max_err, mean_err = float(err.max()), float(err.mean())
    # f32 accumulate of 32 small-int e4m3 products — exact in f32
    correct = max_err < 1e-4
    total += 1; ok += int(correct)
    print(f"  trial {trial}  max_err={max_err:.2e}  mean_err={mean_err:.2e}  {'PASS' if correct else 'FAIL'}")

    cuda.cuMemFree_v2(d_a); cuda.cuMemFree_v2(d_b); cuda.cuMemFree_v2(d_c)


cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 60); print(f"OVERALL: {ok}/{total}")
