"""Forge-native log_softmax (single-warp, n_cols<=32) - GPU validation harness.

Kernel: log_softmax(inp: span<f32>, out: span<f32>, n_cols: u64)
        y[i,j] = (x[i,j] - max(x[i,:])) - log(sum(exp(x[i,:] - max)))
"""
import ctypes, os
import numpy as np
from scipy.special import log_softmax as log_softmax_ref

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1146_forge_log_softmax.cubin'))

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


# n_cols <= 32 for the warp-shuffle path
shapes = [(4, 8), (8, 16), (16, 32), (64, 32), (256, 16)]

print("FORGE: log_softmax - proof-verified .fg -> CUDA C -> PTX -> SASS")
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
    ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"log_softmax"))

    np.random.seed(R * 31 + C)
    x = np.random.randn(R, C).astype(np.float32)
    y_gpu = np.zeros((R, C), dtype=np.float32)

    nbytes = R * C * 4
    d_in = ctypes.c_uint64()
    d_out = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_in), nbytes))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_out), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_in, x.ctypes.data_as(ctypes.c_void_p), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_out, y_gpu.ctypes.data_as(ctypes.c_void_p), nbytes))

    p_in_data = ctypes.c_uint64(d_in.value)
    p_in_len = ctypes.c_uint64(R * C)
    p_out_data = ctypes.c_uint64(d_out.value)
    p_out_len = ctypes.c_uint64(R * C)
    p_n_cols = ctypes.c_uint64(C)
    params = (ctypes.c_void_p * 5)(
        ctypes.cast(ctypes.pointer(p_in_data), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_in_len), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_out_data), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_out_len), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_n_cols), ctypes.c_void_p),
    )
    BLOCK = 32
    ck(cuda.cuLaunchKernel(fn, R, 1, 1, BLOCK, 1, 1,
                           0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(y_gpu.ctypes.data, d_out, nbytes))

    y_ref = log_softmax_ref(x, axis=-1).astype(np.float32)
    err = np.abs(y_gpu - y_ref)
    max_err = float(err.max())
    mean_err = float(err.mean())
    correct = max_err < 1e-4
    total += 1
    if correct:
        ok += 1
    print(f"{R:>5} {C:>5}  {'PASS' if correct else 'FAIL':>8}  {max_err:>10.2e}  {mean_err:>10.2e}")

    cuda.cuMemFree_v2(d_in)
    cuda.cuMemFree_v2(d_out)
    cuda.cuModuleUnload(mod)
    cuda.cuCtxDestroy_v2(ctx)

print("-" * 52)
print(f"OVERALL: {ok}/{total}")
