"""Forge-native scaled_add (AXPBY) — GPU validation harness.

Kernel: scaled_add(x: span<f32>, y: span<f32>, out: span<f32>,
                   n: u64, alpha: f32, beta: f32)
        out[i] = alpha * x[i] + beta * y[i]
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1147_forge_scaled_add.cubin'))

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


cases = [
    (16, 1.0, 1.0),
    (256, 0.5, 0.5),
    (1024, 2.0, -1.0),
    (4096, 0.7071, 0.7071),
    (65536, 1.5, 0.25),
]

print("FORGE: scaled_add - proof-verified .fg -> CUDA C -> PTX -> SASS")
print(f"{'n':>8}  {'alpha':>6}  {'beta':>6}  {'correct':>8}  {'max_err':>10}  {'mean_err':>10}")
print("-" * 64)
ok = 0
total = 0
for (N, alpha, beta) in cases:
    ctx = ctypes.c_void_p()
    ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
    mod = ctypes.c_void_p()
    ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
    fn = ctypes.c_void_p()
    ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"scaled_add"))

    np.random.seed(N)
    x = np.random.randn(N).astype(np.float32)
    y = np.random.randn(N).astype(np.float32)
    out_gpu = np.zeros(N, dtype=np.float32)

    nbytes = N * 4
    d_x = ctypes.c_uint64()
    d_y = ctypes.c_uint64()
    d_out = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_x), nbytes))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_y), nbytes))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_out), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_x, x.ctypes.data_as(ctypes.c_void_p), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_y, y.ctypes.data_as(ctypes.c_void_p), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_out, out_gpu.ctypes.data_as(ctypes.c_void_p), nbytes))

    p_x_data = ctypes.c_uint64(d_x.value)
    p_x_len = ctypes.c_uint64(N)
    p_y_data = ctypes.c_uint64(d_y.value)
    p_y_len = ctypes.c_uint64(N)
    p_out_data = ctypes.c_uint64(d_out.value)
    p_out_len = ctypes.c_uint64(N)
    p_n = ctypes.c_uint64(N)
    p_alpha = ctypes.c_float(alpha)
    p_beta = ctypes.c_float(beta)
    params = (ctypes.c_void_p * 9)(
        ctypes.cast(ctypes.pointer(p_x_data), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_x_len), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_y_data), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_y_len), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_out_data), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_out_len), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_n), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_alpha), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_beta), ctypes.c_void_p),
    )
    BLOCK = 256
    GRID = (N + BLOCK - 1) // BLOCK
    ck(cuda.cuLaunchKernel(fn, GRID, 1, 1, BLOCK, 1, 1,
                           0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(out_gpu.ctypes.data, d_out, nbytes))

    out_ref = (alpha * x + beta * y).astype(np.float32)
    err = np.abs(out_gpu - out_ref)
    max_err = float(err.max())
    mean_err = float(err.mean())
    correct = max_err < 1e-5
    total += 1
    if correct:
        ok += 1
    print(f"{N:>8}  {alpha:>6.2f}  {beta:>6.2f}  {'PASS' if correct else 'FAIL':>8}  {max_err:>10.2e}  {mean_err:>10.2e}")

    cuda.cuMemFree_v2(d_x)
    cuda.cuMemFree_v2(d_y)
    cuda.cuMemFree_v2(d_out)
    cuda.cuModuleUnload(mod)
    cuda.cuCtxDestroy_v2(ctx)

print("-" * 64)
print(f"OVERALL: {ok}/{total}")
