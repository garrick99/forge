"""Forge-native tiled attention (one block per query row, 128 threads).
Kernel: tiled_attention(Q, K, V, O, seq_len, d) — d <= 32, seq_len <= 128.
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1123_forge_tiled_attention.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


def attention_cpu(Q, K, V):
    d = Q.shape[-1]
    s = (Q @ K.T) / np.sqrt(d)
    s -= s.max(axis=-1, keepdims=True); e = np.exp(s)
    w = e / e.sum(axis=-1, keepdims=True)
    return w @ V


cases = [(8, 8), (16, 16), (32, 32), (64, 32), (128, 16)]
print("FORGE: tiled_attention - proof-verified .fg -> CUDA C -> PTX -> SASS")
print(f"{'seq':>5} {'d':>5}  {'correct':>8}  {'max_err':>10}  {'mean_err':>10}")
print("-" * 52)
ok, total = 0, 0
for (S, D) in cases:
    ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
    mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
    fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"tiled_attention"))
    np.random.seed(S * 31 + D)
    Q = np.random.randn(S, D).astype(np.float32) * 0.5
    K = np.random.randn(S, D).astype(np.float32) * 0.5
    V = np.random.randn(S, D).astype(np.float32) * 0.5
    O = np.zeros((S, D), dtype=np.float32)
    nbytes = S * D * 4
    d_q = ctypes.c_uint64(); d_k = ctypes.c_uint64(); d_v = ctypes.c_uint64(); d_o = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_q), nbytes))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_k), nbytes))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_v), nbytes))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_o), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_q, Q.ctypes.data_as(ctypes.c_void_p), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_k, K.ctypes.data_as(ctypes.c_void_p), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_v, V.ctypes.data_as(ctypes.c_void_p), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_o, O.ctypes.data_as(ctypes.c_void_p), nbytes))
    items = [ctypes.c_uint64(d_q.value), ctypes.c_uint64(S * D),
             ctypes.c_uint64(d_k.value), ctypes.c_uint64(S * D),
             ctypes.c_uint64(d_v.value), ctypes.c_uint64(S * D),
             ctypes.c_uint64(d_o.value), ctypes.c_uint64(S * D),
             ctypes.c_uint64(S), ctypes.c_uint64(D)]
    addrs = [ctypes.cast(ctypes.pointer(x), ctypes.c_void_p) for x in items]
    params = (ctypes.c_void_p * len(addrs))(*addrs)
    BLOCK = 128
    ck(cuda.cuLaunchKernel(fn, S, 1, 1, BLOCK, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(O.ctypes.data, d_o, nbytes))
    O_ref = attention_cpu(Q, K, V).astype(np.float32)
    err = np.abs(O - O_ref); max_err, mean_err = float(err.max()), float(err.mean())
    correct = max_err < 1e-3
    total += 1; ok += int(correct)
    print(f"{S:>5} {D:>5}  {'PASS' if correct else 'FAIL':>8}  {max_err:>10.2e}  {mean_err:>10.2e}")
    cuda.cuMemFree_v2(d_q); cuda.cuMemFree_v2(d_k); cuda.cuMemFree_v2(d_v); cuda.cuMemFree_v2(d_o)
    cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 52); print(f"OVERALL: {ok}/{total}")
