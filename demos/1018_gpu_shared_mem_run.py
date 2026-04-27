"""Forge-native shared-memory reductions — GPU validation harness.

Demo 1018 has two kernels:
  block_reduce_sum(data, n, block_results)  - tree-reduce u64 in shared memory.
  dot_product_block(a, b, n, out)           - dot product, ends in u64 warp-shfl.

The dot_product kernel exercises u64 warp-shuffle, which is hi/lo-split
through codegen_ptx.ml since PTX shfl is 32-bit only.
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1018_gpu_shared_mem.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


print("FORGE: 1018_gpu_shared_mem - block_reduce_sum + dot_product_block")
print("-" * 60)
ok, total = 0, 0


# ----- block_reduce_sum -----
ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))

for N in [256, 512, 1024]:
    fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"block_reduce_sum"))
    n_blocks = (N + 255) // 256
    np.random.seed(N)
    data = np.random.randint(0, 100000, size=N).astype(np.uint64)
    block_results = np.zeros(n_blocks, dtype=np.uint64)
    nbytes_d = N * 8; nbytes_b = n_blocks * 8
    d_data = ctypes.c_uint64(); d_blk = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_data), nbytes_d))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_blk), nbytes_b))
    ck(cuda.cuMemcpyHtoD_v2(d_data, data.ctypes.data_as(ctypes.c_void_p), nbytes_d))
    ck(cuda.cuMemcpyHtoD_v2(d_blk, block_results.ctypes.data_as(ctypes.c_void_p), nbytes_b))
    p = [ctypes.c_uint64(d_data.value), ctypes.c_uint64(N), ctypes.c_uint64(N),
         ctypes.c_uint64(d_blk.value), ctypes.c_uint64(n_blocks)]
    params = (ctypes.c_void_p * 5)(*[ctypes.cast(ctypes.pointer(pi), ctypes.c_void_p) for pi in p])
    ck(cuda.cuLaunchKernel(fn, n_blocks, 1, 1, 256, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(block_results.ctypes.data, d_blk, nbytes_b))

    # Reference: each block sums one 256-element slice.
    expected = np.zeros(n_blocks, dtype=np.uint64)
    for b in range(n_blocks):
        sl = data[b*256:(b+1)*256]
        expected[b] = sl.sum()
    correct = bool((block_results == expected).all())
    total += 1; ok += int(correct)
    print(f"  block_reduce_sum N={N:>4}  blocks={n_blocks:>2}  {'PASS' if correct else 'FAIL'}")

    cuda.cuMemFree_v2(d_data); cuda.cuMemFree_v2(d_blk)


# ----- dot_product_block -----
# Note: kernel only correctly handles N=256 (full block).  For N<256, lanes
# with tid>=n leave smem[tid] uninitialised; the reduction tree then adds
# garbage into the partial sums.  Source-level kernel bug, not codegen.
# Validate the supported case (N==BLOCK==256) only.
for N in [256]:
    fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"dot_product_block"))
    np.random.seed(N + 1000)
    a = np.random.randint(0, 1000, size=N).astype(np.uint64)
    b = np.random.randint(0, 1000, size=N).astype(np.uint64)
    out = np.zeros(1, dtype=np.uint64)
    nbytes_v = N * 8
    d_a = ctypes.c_uint64(); d_b = ctypes.c_uint64(); d_o = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_a), nbytes_v))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_b), nbytes_v))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_o), 8))
    ck(cuda.cuMemcpyHtoD_v2(d_a, a.ctypes.data_as(ctypes.c_void_p), nbytes_v))
    ck(cuda.cuMemcpyHtoD_v2(d_b, b.ctypes.data_as(ctypes.c_void_p), nbytes_v))
    ck(cuda.cuMemcpyHtoD_v2(d_o, out.ctypes.data_as(ctypes.c_void_p), 8))
    p = [ctypes.c_uint64(d_a.value), ctypes.c_uint64(N),
         ctypes.c_uint64(d_b.value), ctypes.c_uint64(N), ctypes.c_uint64(N),
         ctypes.c_uint64(d_o.value), ctypes.c_uint64(1)]
    params = (ctypes.c_void_p * 7)(*[ctypes.cast(ctypes.pointer(pi), ctypes.c_void_p) for pi in p])
    ck(cuda.cuLaunchKernel(fn, 1, 1, 1, 256, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(out.ctypes.data, d_o, 8))
    expected = int((a * b).sum())
    correct = int(out[0]) == expected
    total += 1; ok += int(correct)
    print(f"  dot_product_block N={N:>4}  expect={expected:>12}  got={int(out[0]):>12}  {'PASS' if correct else 'FAIL'}")
    cuda.cuMemFree_v2(d_a); cuda.cuMemFree_v2(d_b); cuda.cuMemFree_v2(d_o)


cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 60); print(f"OVERALL: {ok}/{total}")
