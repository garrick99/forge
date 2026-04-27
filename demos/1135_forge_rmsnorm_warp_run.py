"""Forge-native rmsnorm_warp (single-warp, n_cols<=32).
Kernel: rmsnorm_warp(inp, out, n_cols) — RMS norm via warp-shuffle.
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1135_forge_rmsnorm_warp.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


EPS = 1e-5
def rmsnorm_cpu(x):
    rms = np.sqrt(np.mean(x * x, axis=-1, keepdims=True) + EPS)
    return x / rms


shapes = [(4, 8), (8, 16), (16, 32), (64, 32), (256, 16)]
print("FORGE: rmsnorm_warp - proof-verified .fg -> CUDA C -> PTX -> SASS")
print(f"{'rows':>5} {'cols':>5}  {'correct':>8}  {'max_err':>10}  {'mean_err':>10}")
print("-" * 52)
ok, total = 0, 0
for (R, C) in shapes:
    ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
    mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
    fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"rmsnorm_warp"))
    np.random.seed(R * 31 + C)
    x = np.random.randn(R, C).astype(np.float32); y_gpu = np.zeros((R, C), dtype=np.float32)
    nbytes = R * C * 4
    d_in = ctypes.c_uint64(); d_out = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_in), nbytes)); ck(cuda.cuMemAlloc_v2(ctypes.byref(d_out), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_in, x.ctypes.data_as(ctypes.c_void_p), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_out, y_gpu.ctypes.data_as(ctypes.c_void_p), nbytes))
    p = [ctypes.c_uint64(d_in.value), ctypes.c_uint64(R*C),
         ctypes.c_uint64(d_out.value), ctypes.c_uint64(R*C), ctypes.c_uint64(C)]
    params = (ctypes.c_void_p * 5)(*[ctypes.cast(ctypes.pointer(pi), ctypes.c_void_p) for pi in p])
    ck(cuda.cuLaunchKernel(fn, R, 1, 1, 32, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(y_gpu.ctypes.data, d_out, nbytes))
    y_ref = rmsnorm_cpu(x).astype(np.float32)
    err = np.abs(y_gpu - y_ref); max_err, mean_err = float(err.max()), float(err.mean())
    correct = max_err < 1e-4; total += 1; ok += int(correct)
    print(f"{R:>5} {C:>5}  {'PASS' if correct else 'FAIL':>8}  {max_err:>10.2e}  {mean_err:>10.2e}")
    cuda.cuMemFree_v2(d_in); cuda.cuMemFree_v2(d_out)
    cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 52); print(f"OVERALL: {ok}/{total}")
