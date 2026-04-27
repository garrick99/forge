"""Forge-native GELU (tanh approximation) — GPU validation harness.

Kernel: gelu_kernel(inp: span<f32>, out: span<f32>, n: u64)
        y = 0.5 * x * (1 + tanhf(sqrt(2/pi) * (x + 0.044715 * x^3)))
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1129_forge_gelu.cubin'))

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


def gelu_cpu(x):
    c = np.float32(np.sqrt(2.0 / np.pi))
    return 0.5 * x * (1.0 + np.tanh(c * (x + 0.044715 * x * x * x)))


sizes = [16, 256, 1024, 4096, 65536]

print("FORGE: gelu_kernel - proof-verified .fg -> CUDA C -> PTX -> SASS")
print(f"{'n':>8}  {'correct':>8}  {'max_err':>10}  {'mean_err':>10}")
print("-" * 48)
ok = 0
total = 0
for N in sizes:
    ctx = ctypes.c_void_p()
    ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
    mod = ctypes.c_void_p()
    ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
    fn = ctypes.c_void_p()
    ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"gelu_kernel"))

    np.random.seed(N)
    x = (np.random.randn(N).astype(np.float32) * 2.0)
    y_gpu = np.zeros(N, dtype=np.float32)

    nbytes = N * 4
    d_in = ctypes.c_uint64()
    d_out = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_in), nbytes))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_out), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_in, x.ctypes.data_as(ctypes.c_void_p), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_out, y_gpu.ctypes.data_as(ctypes.c_void_p), nbytes))

    p_in_data = ctypes.c_uint64(d_in.value)
    p_in_len = ctypes.c_uint64(N)
    p_out_data = ctypes.c_uint64(d_out.value)
    p_out_len = ctypes.c_uint64(N)
    p_n = ctypes.c_uint64(N)
    params = (ctypes.c_void_p * 5)(
        ctypes.cast(ctypes.pointer(p_in_data), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_in_len), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_out_data), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_out_len), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_n), ctypes.c_void_p),
    )
    BLOCK = 256
    GRID = (N + BLOCK - 1) // BLOCK
    ck(cuda.cuLaunchKernel(fn, GRID, 1, 1, BLOCK, 1, 1,
                           0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(y_gpu.ctypes.data, d_out, nbytes))

    y_ref = gelu_cpu(x).astype(np.float32)
    err = np.abs(y_gpu - y_ref)
    max_err = float(err.max())
    mean_err = float(err.mean())
    correct = max_err < 1e-4   # tanh approx + numpy float64 ref => looser
    total += 1
    if correct:
        ok += 1
    print(f"{N:>8}  {'PASS' if correct else 'FAIL':>8}  {max_err:>10.2e}  {mean_err:>10.2e}")

    cuda.cuMemFree_v2(d_in)
    cuda.cuMemFree_v2(d_out)
    cuda.cuModuleUnload(mod)
    cuda.cuCtxDestroy_v2(ctx)

print("-" * 48)
print(f"OVERALL: {ok}/{total}")
