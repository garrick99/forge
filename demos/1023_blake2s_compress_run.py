"""Forge-native blake2s_leaf_hash — GPU smoke test.

The kernel body is bounds-check assertions only (proof-side), no functional
payload.  This harness verifies the cubin loads, launches, and synchronises
without error — which is all that can be validated without a real Blake2s
compression implementation in the kernel.
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1023_blake2s_compress.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


print("FORGE: 1023_blake2s_compress (kernel is bounds-check stub — smoke test only)")
print("-" * 70)
ok, total = 0, 0
ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"blake2s_leaf_hash"))


for n in [4, 16, 64]:
    # output: 8*n u32 words; input: 16*n u32 words
    output = np.zeros(8 * n, dtype=np.uint32)
    inp = np.arange(16 * n, dtype=np.uint32)
    nbytes_o = output.nbytes; nbytes_i = inp.nbytes
    d_o = ctypes.c_uint64(); d_i = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_o), nbytes_o))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_i), nbytes_i))
    ck(cuda.cuMemcpyHtoD_v2(d_o, output.ctypes.data_as(ctypes.c_void_p), nbytes_o))
    ck(cuda.cuMemcpyHtoD_v2(d_i, inp.ctypes.data_as(ctypes.c_void_p), nbytes_i))
    items = [ctypes.c_uint64(d_o.value), ctypes.c_uint64(8 * n),
             ctypes.c_uint64(d_i.value), ctypes.c_uint64(16 * n), ctypes.c_uint64(n)]
    addrs = [ctypes.cast(ctypes.pointer(x), ctypes.c_void_p) for x in items]
    params = (ctypes.c_void_p * len(addrs))(*addrs)
    BLOCK = 256; GRID = (n + BLOCK - 1) // BLOCK
    try:
        ck(cuda.cuLaunchKernel(fn, GRID, 1, 1, BLOCK, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
        ck(cuda.cuCtxSynchronize())
        smoke_ok = True
    except RuntimeError:
        smoke_ok = False
    total += 1; ok += int(smoke_ok)
    print(f"  blake2s_leaf_hash n={n:>3}  {'LAUNCH-OK' if smoke_ok else 'LAUNCH-FAIL'}")
    cuda.cuMemFree_v2(d_o); cuda.cuMemFree_v2(d_i)


cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 70); print(f"OVERALL: {ok}/{total}")
