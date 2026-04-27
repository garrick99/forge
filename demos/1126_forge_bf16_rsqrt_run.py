"""Forge-native bf16_rsqrt — GPU validation harness.

bf16 has same exponent range as f32 but only 7 mantissa bits.
We work with bf16 stored as u16 (top 16 bits of the f32 bit pattern).
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1126_forge_bf16_rsqrt.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


def f32_to_bf16(x):
    """Truncate-to-zero conversion (matches CUDA __float2bfloat16_rz)."""
    return (x.view(np.uint32) >> 16).astype(np.uint16)


def bf16_to_f32(x_u16):
    return (x_u16.astype(np.uint32) << 16).view(np.float32)


sizes = [16, 256, 1024, 4096, 65536]
print("FORGE: bf16_rsqrt - proof-verified .fg -> CUDA C -> PTX -> SASS")
print(f"{'n':>8}  {'correct':>8}  {'max_err':>10}  {'mean_err':>10}")
print("-" * 48)
ok, total = 0, 0
for N in sizes:
    ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
    mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
    fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"bf16_rsqrt"))
    np.random.seed(N)
    x_f32 = (np.random.rand(N).astype(np.float32) * 9.0 + 0.5)
    x_u16 = f32_to_bf16(x_f32)
    # Re-decode to ensure we use the same starting value as the GPU
    x_bf16_as_f32 = bf16_to_f32(x_u16)
    y_u16_gpu = np.zeros(N, dtype=np.uint16)

    nbytes = N * 2
    d_in = ctypes.c_uint64(); d_out = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_in), nbytes))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_out), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_in, x_u16.ctypes.data_as(ctypes.c_void_p), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_out, y_u16_gpu.ctypes.data_as(ctypes.c_void_p), nbytes))
    p = [ctypes.c_uint64(d_in.value), ctypes.c_uint64(N),
         ctypes.c_uint64(d_out.value), ctypes.c_uint64(N), ctypes.c_uint64(N)]
    params = (ctypes.c_void_p * 5)(*[ctypes.cast(ctypes.pointer(pi), ctypes.c_void_p) for pi in p])
    BLOCK = 256; GRID = (N + BLOCK - 1) // BLOCK
    ck(cuda.cuLaunchKernel(fn, GRID, 1, 1, BLOCK, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(y_u16_gpu.ctypes.data, d_out, nbytes))

    y_gpu = bf16_to_f32(y_u16_gpu)
    y_ref_f32 = 1.0 / np.sqrt(x_bf16_as_f32)
    y_ref = bf16_to_f32(f32_to_bf16(y_ref_f32))
    err = np.abs(y_gpu - y_ref); max_err, mean_err = float(err.max()), float(err.mean())
    # bf16 has 7 mantissa bits; ULP at 1.0 is ~7.8e-3
    correct = max_err < 1e-2
    total += 1; ok += int(correct)
    print(f"{N:>8}  {'PASS' if correct else 'FAIL':>8}  {max_err:>10.2e}  {mean_err:>10.2e}")

    cuda.cuMemFree_v2(d_in); cuda.cuMemFree_v2(d_out)
    cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 48); print(f"OVERALL: {ok}/{total}")
