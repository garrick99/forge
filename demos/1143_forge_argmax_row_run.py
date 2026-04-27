"""Forge-native argmax_row (single-warp, n_classes<=32).
Kernel: argmax_row(logits, out, n_classes) — out[row] = argmax_j logits[row, j].
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1143_forge_argmax_row.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


shapes = [(4, 8), (8, 16), (16, 32), (64, 32), (256, 16)]
print("FORGE: argmax_row - proof-verified .fg -> CUDA C -> PTX -> SASS")
print(f"{'rows':>5} {'cols':>5}  {'correct':>8}  {'mismatches':>11}")
print("-" * 48)
ok, total = 0, 0
for (R, C) in shapes:
    ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
    mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
    fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"argmax_row"))
    np.random.seed(R * 31 + C)
    x = np.random.randn(R, C).astype(np.float32)
    out_gpu = np.zeros(R, dtype=np.uint32)

    nbytes_x = R * C * 4; nbytes_o = R * 4
    d_in = ctypes.c_uint64(); d_out = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_in), nbytes_x))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_out), nbytes_o))
    ck(cuda.cuMemcpyHtoD_v2(d_in, x.ctypes.data_as(ctypes.c_void_p), nbytes_x))
    ck(cuda.cuMemcpyHtoD_v2(d_out, out_gpu.ctypes.data_as(ctypes.c_void_p), nbytes_o))
    p = [ctypes.c_uint64(d_in.value), ctypes.c_uint64(R*C),
         ctypes.c_uint64(d_out.value), ctypes.c_uint64(R), ctypes.c_uint64(C)]
    params = (ctypes.c_void_p * 5)(*[ctypes.cast(ctypes.pointer(pi), ctypes.c_void_p) for pi in p])
    ck(cuda.cuLaunchKernel(fn, R, 1, 1, 32, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(out_gpu.ctypes.data, d_out, nbytes_o))

    out_ref = x.argmax(axis=-1).astype(np.uint32)
    mismatches = int((out_gpu != out_ref).sum())
    correct = mismatches == 0
    total += 1; ok += int(correct)
    print(f"{R:>5} {C:>5}  {'PASS' if correct else 'FAIL':>8}  {mismatches:>11}")

    cuda.cuMemFree_v2(d_in); cuda.cuMemFree_v2(d_out)
    cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 48); print(f"OVERALL: {ok}/{total}")
