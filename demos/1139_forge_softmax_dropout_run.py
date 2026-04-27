"""Forge-native softmax_dropout (single-warp, n_cols<=32).
Kernel: softmax_dropout(inp, mask, out, n_cols, keep_scale)
        out[j] = (mask[j] != 0) ? softmax(x)[j] * keep_scale : 0
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1139_forge_softmax_dropout.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


def softmax_dropout_cpu(x, mask, keep_scale):
    m = x.max(axis=-1, keepdims=True); e = np.exp(x - m)
    p = e / e.sum(axis=-1, keepdims=True)
    return np.where(mask != 0, p * keep_scale, 0.0)


cases = [(4, 8, 0.5), (8, 16, 0.7), (16, 32, 0.9), (64, 32, 0.5), (256, 16, 0.8)]
print("FORGE: softmax_dropout - proof-verified .fg -> CUDA C -> PTX -> SASS")
print(f"{'rows':>5} {'cols':>5} {'kp':>5}  {'correct':>8}  {'max_err':>10}  {'mean_err':>10}")
print("-" * 58)
ok, total = 0, 0
for (R, C, p_keep) in cases:
    ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
    mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
    fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"softmax_dropout"))
    np.random.seed(R * 31 + C)
    x = np.random.randn(R, C).astype(np.float32)
    mask = (np.random.rand(R, C) < p_keep).astype(np.uint32)
    out_gpu = np.zeros((R, C), dtype=np.float32)
    keep_scale = 1.0 / p_keep

    nbytes_x = R * C * 4
    d_in = ctypes.c_uint64(); d_m = ctypes.c_uint64(); d_o = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_in), nbytes_x))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_m), nbytes_x))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_o), nbytes_x))
    ck(cuda.cuMemcpyHtoD_v2(d_in, x.ctypes.data_as(ctypes.c_void_p), nbytes_x))
    ck(cuda.cuMemcpyHtoD_v2(d_m, mask.ctypes.data_as(ctypes.c_void_p), nbytes_x))
    ck(cuda.cuMemcpyHtoD_v2(d_o, out_gpu.ctypes.data_as(ctypes.c_void_p), nbytes_x))
    p_keep_f = ctypes.c_float(keep_scale)
    p = [ctypes.c_uint64(d_in.value), ctypes.c_uint64(R*C),
         ctypes.c_uint64(d_m.value), ctypes.c_uint64(R*C),
         ctypes.c_uint64(d_o.value), ctypes.c_uint64(R*C), ctypes.c_uint64(C)]
    addrs = [ctypes.cast(ctypes.pointer(pi), ctypes.c_void_p) for pi in p]
    addrs.append(ctypes.cast(ctypes.pointer(p_keep_f), ctypes.c_void_p))
    params = (ctypes.c_void_p * 8)(*addrs)
    ck(cuda.cuLaunchKernel(fn, R, 1, 1, 32, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(out_gpu.ctypes.data, d_o, nbytes_x))

    out_ref = softmax_dropout_cpu(x, mask, keep_scale).astype(np.float32)
    err = np.abs(out_gpu - out_ref); max_err, mean_err = float(err.max()), float(err.mean())
    correct = max_err < 1e-4; total += 1; ok += int(correct)
    print(f"{R:>5} {C:>5} {p_keep:>5.1f}  {'PASS' if correct else 'FAIL':>8}  {max_err:>10.2e}  {mean_err:>10.2e}")

    cuda.cuMemFree_v2(d_in); cuda.cuMemFree_v2(d_m); cuda.cuMemFree_v2(d_o)
    cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 58); print(f"OVERALL: {ok}/{total}")
