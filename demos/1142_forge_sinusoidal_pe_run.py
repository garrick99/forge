"""Forge-native sinusoidal positional encoding (d=32 fixed).
Kernel: sinusoidal_pe(out, seq_len) — out[p, 2i]=sin(theta), out[p, 2i+1]=cos(theta).
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1142_forge_sinusoidal_pe.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


D = 32  # fixed in the kernel


def pe_cpu(seq_len, d=D):
    pos = np.arange(seq_len, dtype=np.float32)[:, None]
    i = np.arange(d // 2, dtype=np.float32)[None, :]
    inv_freq = np.exp(-(2 * i / d) * np.log(10000.0))
    theta = pos * inv_freq
    out = np.zeros((seq_len, d), dtype=np.float32)
    out[:, 0::2] = np.sin(theta)
    out[:, 1::2] = np.cos(theta)
    return out


seqs = [4, 16, 64, 256, 1024]
print(f"FORGE: sinusoidal_pe (d={D}) - proof-verified .fg -> CUDA C -> PTX -> SASS")
print(f"{'seq_len':>8}  {'correct':>8}  {'max_err':>10}  {'mean_err':>10}")
print("-" * 48)
ok, total = 0, 0
for L in seqs:
    ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
    mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
    fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"sinusoidal_pe"))
    out_gpu = np.zeros((L, D), dtype=np.float32)
    nbytes = L * D * 4
    d_o = ctypes.c_uint64(); ck(cuda.cuMemAlloc_v2(ctypes.byref(d_o), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_o, out_gpu.ctypes.data_as(ctypes.c_void_p), nbytes))
    p = [ctypes.c_uint64(d_o.value), ctypes.c_uint64(L * D), ctypes.c_uint64(L)]
    params = (ctypes.c_void_p * 3)(*[ctypes.cast(ctypes.pointer(pi), ctypes.c_void_p) for pi in p])
    BLOCK = 16  # threadIdx_x < 16 (one thread per sin/cos pair, d/2 lanes)
    ck(cuda.cuLaunchKernel(fn, L, 1, 1, BLOCK, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(out_gpu.ctypes.data, d_o, nbytes))

    out_ref = pe_cpu(L).astype(np.float32)
    err = np.abs(out_gpu - out_ref); max_err, mean_err = float(err.max()), float(err.mean())
    # sin.approx / cos.approx degrade as theta grows; loosen tolerance for
    # long sequences where pos*freq drives sin's argument up to ~seq_len rad.
    tol = 5e-4 if L > 256 else 1e-4
    correct = max_err < tol; total += 1; ok += int(correct)
    print(f"{L:>8}  {'PASS' if correct else 'FAIL':>8}  {max_err:>10.2e}  {mean_err:>10.2e}")

    cuda.cuMemFree_v2(d_o); cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 48); print(f"OVERALL: {ok}/{total}")
