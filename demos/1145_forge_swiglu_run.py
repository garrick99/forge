"""Forge-native SwiGLU — GPU validation harness.

Kernel: swiglu(gate: span<f32>, up: span<f32>, out: span<f32>, n: u64)
        y[i] = silu(gate[i]) * up[i]
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1145_forge_swiglu.cubin'))

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


def swiglu_cpu(g, u):
    return (g / (1.0 + np.exp(-g))) * u


sizes = [16, 256, 1024, 4096, 65536]

print("FORGE: swiglu - proof-verified .fg -> CUDA C -> PTX -> SASS")
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
    ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"swiglu"))

    np.random.seed(N)
    g = (np.random.randn(N).astype(np.float32) * 2.0)
    u = (np.random.randn(N).astype(np.float32) * 2.0)
    out_gpu = np.zeros(N, dtype=np.float32)

    nbytes = N * 4
    d_g = ctypes.c_uint64()
    d_u = ctypes.c_uint64()
    d_out = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_g), nbytes))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_u), nbytes))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_out), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_g, g.ctypes.data_as(ctypes.c_void_p), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_u, u.ctypes.data_as(ctypes.c_void_p), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_out, out_gpu.ctypes.data_as(ctypes.c_void_p), nbytes))

    p_g_data = ctypes.c_uint64(d_g.value)
    p_g_len = ctypes.c_uint64(N)
    p_u_data = ctypes.c_uint64(d_u.value)
    p_u_len = ctypes.c_uint64(N)
    p_out_data = ctypes.c_uint64(d_out.value)
    p_out_len = ctypes.c_uint64(N)
    p_n = ctypes.c_uint64(N)
    params = (ctypes.c_void_p * 7)(
        ctypes.cast(ctypes.pointer(p_g_data), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_g_len), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_u_data), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_u_len), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_out_data), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_out_len), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_n), ctypes.c_void_p),
    )
    BLOCK = 256
    GRID = (N + BLOCK - 1) // BLOCK
    ck(cuda.cuLaunchKernel(fn, GRID, 1, 1, BLOCK, 1, 1,
                           0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(out_gpu.ctypes.data, d_out, nbytes))

    out_ref = swiglu_cpu(g, u).astype(np.float32)
    err = np.abs(out_gpu - out_ref)
    max_err = float(err.max())
    mean_err = float(err.mean())
    correct = max_err < 1e-5
    total += 1
    if correct:
        ok += 1
    print(f"{N:>8}  {'PASS' if correct else 'FAIL':>8}  {max_err:>10.2e}  {mean_err:>10.2e}")

    cuda.cuMemFree_v2(d_g)
    cuda.cuMemFree_v2(d_u)
    cuda.cuMemFree_v2(d_out)
    cuda.cuModuleUnload(mod)
    cuda.cuCtxDestroy_v2(ctx)

print("-" * 48)
print(f"OVERALL: {ok}/{total}")
