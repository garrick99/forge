"""Forge-native causal_softmax (single-warp, seq_len<=32) - GPU validation harness.

Kernel: causal_softmax(scores: span<f32>, out: span<f32>, seq_len: u64)
        Row i: softmax(scores[i, 0..=i]); positions j>i forced to -inf.
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1138_forge_causal_softmax.cubin'))

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


def causal_softmax_cpu(scores, seq_len):
    rows = scores.shape[0]
    out = np.zeros_like(scores)
    for i in range(rows):
        row_seq = i + 1   # query at position i sees keys 0..=i
        # but the kernel processes the full seq_len row, masking j>i.
        # Actually the kernel design is: blockIdx_x iterates queries within
        # a single seq_len row (each block handles one query position).
        # So row i has seq_len entries, and lane j in [0, seq_len) maps to
        # key j; mask: j > (row index modulo seq_len). The kernel's
        # `row` is blockIdx_x, but only blockIdx_x < seq_len. So 1 row per query.
        masked = scores[i].copy()
        masked[i+1:] = -np.inf  # j > i -> -inf
        m = masked.max()
        e = np.exp(masked - m)
        out[i] = e / e.sum()
    return out


# rows == seq_len  (kernel: blockIdx_x < seq_len)
seqs = [4, 8, 16, 32]

print("FORGE: causal_softmax - proof-verified .fg -> CUDA C -> PTX -> SASS")
print(f"{'seq_len':>8}  {'correct':>8}  {'max_err':>10}  {'mean_err':>10}")
print("-" * 52)
ok = 0
total = 0
for L in seqs:
    R = L  # one query per row
    ctx = ctypes.c_void_p()
    ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
    mod = ctypes.c_void_p()
    ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
    fn = ctypes.c_void_p()
    ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"causal_softmax"))

    np.random.seed(L)
    x = np.random.randn(R, L).astype(np.float32)
    y_gpu = np.zeros((R, L), dtype=np.float32)

    nbytes = R * L * 4
    d_in = ctypes.c_uint64()
    d_out = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_in), nbytes))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_out), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_in, x.ctypes.data_as(ctypes.c_void_p), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_out, y_gpu.ctypes.data_as(ctypes.c_void_p), nbytes))

    p_in_data = ctypes.c_uint64(d_in.value)
    p_in_len = ctypes.c_uint64(R * L)
    p_out_data = ctypes.c_uint64(d_out.value)
    p_out_len = ctypes.c_uint64(R * L)
    p_seq_len = ctypes.c_uint64(L)
    params = (ctypes.c_void_p * 5)(
        ctypes.cast(ctypes.pointer(p_in_data), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_in_len), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_out_data), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_out_len), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_seq_len), ctypes.c_void_p),
    )
    BLOCK = 32
    ck(cuda.cuLaunchKernel(fn, R, 1, 1, BLOCK, 1, 1,
                           0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(y_gpu.ctypes.data, d_out, nbytes))

    y_ref = causal_softmax_cpu(x, L).astype(np.float32)
    err = np.abs(y_gpu - y_ref)
    max_err = float(err.max())
    mean_err = float(err.mean())
    correct = max_err < 1e-4
    total += 1
    if correct:
        ok += 1
    print(f"{L:>8}  {'PASS' if correct else 'FAIL':>8}  {max_err:>10.2e}  {mean_err:>10.2e}")

    cuda.cuMemFree_v2(d_in)
    cuda.cuMemFree_v2(d_out)
    cuda.cuModuleUnload(mod)
    cuda.cuCtxDestroy_v2(ctx)

print("-" * 52)
print(f"OVERALL: {ok}/{total}")
