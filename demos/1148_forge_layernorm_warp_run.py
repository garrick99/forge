"""Forge-native LayerNorm warp variant (single-warp, n_cols<=32).

Kernel: layernorm_warp(inp, out, gamma, beta, n_cols)
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1148_forge_layernorm_warp.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]


def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")


ck(cuda.cuInit(0))
DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))
EPS = 1e-5


def layernorm_affine_cpu(x, gamma, beta):
    m = x.mean(axis=-1, keepdims=True); v = x.var(axis=-1, keepdims=True)
    return ((x - m) / np.sqrt(v + EPS)) * gamma + beta


shapes = [(4, 8), (8, 16), (16, 32), (64, 32), (256, 16)]
print("FORGE: layernorm_warp - proof-verified .fg -> CUDA C -> PTX -> SASS")
print(f"{'rows':>5} {'cols':>5}  {'correct':>8}  {'max_err':>10}  {'mean_err':>10}")
print("-" * 52)
ok, total = 0, 0
for (R, C) in shapes:
    ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
    mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
    fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"layernorm_warp"))

    np.random.seed(R * 31 + C)
    x = np.random.randn(R, C).astype(np.float32)
    gamma = (np.random.rand(C).astype(np.float32) + 0.5)
    beta = (np.random.randn(C).astype(np.float32) * 0.1)
    y_gpu = np.zeros((R, C), dtype=np.float32)

    nbytes_xy = R * C * 4; nbytes_g = C * 4
    d_in = ctypes.c_uint64(); d_out = ctypes.c_uint64()
    d_g = ctypes.c_uint64(); d_b = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_in), nbytes_xy))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_out), nbytes_xy))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_g), nbytes_g))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_b), nbytes_g))
    ck(cuda.cuMemcpyHtoD_v2(d_in, x.ctypes.data_as(ctypes.c_void_p), nbytes_xy))
    ck(cuda.cuMemcpyHtoD_v2(d_out, y_gpu.ctypes.data_as(ctypes.c_void_p), nbytes_xy))
    ck(cuda.cuMemcpyHtoD_v2(d_g, gamma.ctypes.data_as(ctypes.c_void_p), nbytes_g))
    ck(cuda.cuMemcpyHtoD_v2(d_b, beta.ctypes.data_as(ctypes.c_void_p), nbytes_g))

    p = [ctypes.c_uint64(d_in.value), ctypes.c_uint64(R*C),
         ctypes.c_uint64(d_out.value), ctypes.c_uint64(R*C),
         ctypes.c_uint64(d_g.value), ctypes.c_uint64(C),
         ctypes.c_uint64(d_b.value), ctypes.c_uint64(C),
         ctypes.c_uint64(C)]
    params = (ctypes.c_void_p * 9)(*[ctypes.cast(ctypes.pointer(pi), ctypes.c_void_p) for pi in p])

    BLOCK = 32
    ck(cuda.cuLaunchKernel(fn, R, 1, 1, BLOCK, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(y_gpu.ctypes.data, d_out, nbytes_xy))

    y_ref = layernorm_affine_cpu(x, gamma, beta).astype(np.float32)
    err = np.abs(y_gpu - y_ref)
    max_err, mean_err = float(err.max()), float(err.mean())
    correct = max_err < 1e-4
    total += 1; ok += int(correct)
    print(f"{R:>5} {C:>5}  {'PASS' if correct else 'FAIL':>8}  {max_err:>10.2e}  {mean_err:>10.2e}")

    cuda.cuMemFree_v2(d_in); cuda.cuMemFree_v2(d_out)
    cuda.cuMemFree_v2(d_g); cuda.cuMemFree_v2(d_b)
    cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)

print("-" * 52); print(f"OVERALL: {ok}/{total}")
