"""Forge-native RoPE (Rotary Position Embedding, d=32 fixed).
Kernel: rope_rotate(inp, out, seq_len) — pair-wise rotation by theta(pos, lane).
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1137_forge_rope.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


D = 32
def rope_cpu(x, seq_len, d=D):
    pos = np.arange(seq_len, dtype=np.float32)[:, None]
    i = np.arange(d // 2, dtype=np.float32)[None, :]
    inv_freq = np.exp(-(2 * i / d) * np.log(10000.0))
    theta = pos * inv_freq
    c = np.cos(theta); s = np.sin(theta)
    out = np.zeros_like(x)
    out[:, 0::2] = x[:, 0::2] * c - x[:, 1::2] * s
    out[:, 1::2] = x[:, 0::2] * s + x[:, 1::2] * c
    return out


seqs = [4, 16, 64, 256, 1024]
print(f"FORGE: rope_rotate (d={D}) - proof-verified .fg -> CUDA C -> PTX -> SASS")
print(f"{'seq_len':>8}  {'correct':>8}  {'max_err':>10}  {'mean_err':>10}")
print("-" * 48)
ok, total = 0, 0
for L in seqs:
    ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
    mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
    fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"rope_rotate"))
    np.random.seed(L)
    x = np.random.randn(L, D).astype(np.float32)
    y_gpu = np.zeros((L, D), dtype=np.float32)
    nbytes = L * D * 4
    d_in = ctypes.c_uint64(); d_out = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_in), nbytes))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_out), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_in, x.ctypes.data_as(ctypes.c_void_p), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_out, y_gpu.ctypes.data_as(ctypes.c_void_p), nbytes))
    p = [ctypes.c_uint64(d_in.value), ctypes.c_uint64(L * D),
         ctypes.c_uint64(d_out.value), ctypes.c_uint64(L * D), ctypes.c_uint64(L)]
    params = (ctypes.c_void_p * 5)(*[ctypes.cast(ctypes.pointer(pi), ctypes.c_void_p) for pi in p])
    ck(cuda.cuLaunchKernel(fn, L, 1, 1, 16, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(y_gpu.ctypes.data, d_out, nbytes))

    y_ref = rope_cpu(x, L).astype(np.float32)
    err = np.abs(y_gpu - y_ref); max_err, mean_err = float(err.max()), float(err.mean())
    tol = 5e-4 if L > 256 else 1e-4   # sin/cos.approx degrades with theta
    correct = max_err < tol
    total += 1; ok += int(correct)
    print(f"{L:>8}  {'PASS' if correct else 'FAIL':>8}  {max_err:>10.2e}  {mean_err:>10.2e}")

    cuda.cuMemFree_v2(d_in); cuda.cuMemFree_v2(d_out)
    cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 48); print(f"OVERALL: {ok}/{total}")
