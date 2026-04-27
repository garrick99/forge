"""Forge-native masked_softmax (single-warp, n_cols<=32) - GPU validation harness.

Kernel: masked_softmax(scores: span<f32>, mask: span<u32>, out: span<f32>, n_cols: u64)
        positions where mask==0 fold to -inf; standard softmax over the survivors.
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1144_forge_masked_softmax.cubin'))

cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]


def ck(e, msg=""):
    if e != 0:
        raise RuntimeError(f"{msg}: cuda err {e}")


ck(cuda.cuInit(0))
DEV = ctypes.c_int()
ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


def masked_softmax_cpu(scores, mask):
    masked = np.where(mask != 0, scores, -np.inf)
    m = masked.max(axis=-1, keepdims=True)
    e = np.exp(masked - m)
    return e / e.sum(axis=-1, keepdims=True)


shapes = [(4, 8), (8, 16), (16, 32), (64, 16), (256, 32)]

print("FORGE: masked_softmax - proof-verified .fg -> CUDA C -> PTX -> SASS")
print(f"{'rows':>5} {'cols':>5}  {'correct':>8}  {'max_err':>10}  {'mean_err':>10}")
print("-" * 52)
ok = 0
total = 0
for (R, C) in shapes:
    ctx = ctypes.c_void_p()
    ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
    mod = ctypes.c_void_p()
    ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
    fn = ctypes.c_void_p()
    ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"masked_softmax"))

    np.random.seed(R * 31 + C)
    scores = np.random.randn(R, C).astype(np.float32)
    # Random mask, but ensure at least one keep bit per row (kernel precondition).
    mask = (np.random.rand(R, C) > 0.3).astype(np.uint32)
    for r in range(R):
        if mask[r].sum() == 0:
            mask[r, 0] = 1
    out_gpu = np.zeros((R, C), dtype=np.float32)

    nbytes_f = R * C * 4
    nbytes_u = R * C * 4
    d_scores = ctypes.c_uint64()
    d_mask = ctypes.c_uint64()
    d_out = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_scores), nbytes_f))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_mask), nbytes_u))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_out), nbytes_f))
    ck(cuda.cuMemcpyHtoD_v2(d_scores, scores.ctypes.data_as(ctypes.c_void_p), nbytes_f))
    ck(cuda.cuMemcpyHtoD_v2(d_mask, mask.ctypes.data_as(ctypes.c_void_p), nbytes_u))
    ck(cuda.cuMemcpyHtoD_v2(d_out, out_gpu.ctypes.data_as(ctypes.c_void_p), nbytes_f))

    p_s_data = ctypes.c_uint64(d_scores.value)
    p_s_len = ctypes.c_uint64(R * C)
    p_m_data = ctypes.c_uint64(d_mask.value)
    p_m_len = ctypes.c_uint64(R * C)
    p_o_data = ctypes.c_uint64(d_out.value)
    p_o_len = ctypes.c_uint64(R * C)
    p_n_cols = ctypes.c_uint64(C)
    params = (ctypes.c_void_p * 7)(
        ctypes.cast(ctypes.pointer(p_s_data), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_s_len), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_m_data), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_m_len), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_o_data), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_o_len), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_n_cols), ctypes.c_void_p),
    )
    BLOCK = 32
    ck(cuda.cuLaunchKernel(fn, R, 1, 1, BLOCK, 1, 1,
                           0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(out_gpu.ctypes.data, d_out, nbytes_f))

    out_ref = masked_softmax_cpu(scores, mask).astype(np.float32)
    err = np.abs(out_gpu - out_ref)
    max_err = float(err.max())
    mean_err = float(err.mean())
    correct = max_err < 1e-4
    total += 1
    if correct:
        ok += 1
    print(f"{R:>5} {C:>5}  {'PASS' if correct else 'FAIL':>8}  {max_err:>10.2e}  {mean_err:>10.2e}")

    cuda.cuMemFree_v2(d_scores)
    cuda.cuMemFree_v2(d_mask)
    cuda.cuMemFree_v2(d_out)
    cuda.cuModuleUnload(mod)
    cuda.cuCtxDestroy_v2(ctx)

print("-" * 52)
print(f"OVERALL: {ok}/{total}")
