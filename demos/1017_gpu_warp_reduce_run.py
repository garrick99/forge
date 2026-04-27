"""Forge-native warp-reduce + vector ops — GPU validation harness.

Demo 1017 has 6 kernels:
  reduce_sum (data, n, result_ptr)         u64 warp-shuffle + atom_add
  reduce_max (data, n, result_ptr)         u64 warp-shuffle + atom_max
  saxpy      (x, y, a, n)                  y[i] = a*x[i] + y[i]
  vec_add    (a, b, c, n)                  c[i] = a[i] + b[i]
  vec_mul    (a, b, c, n)                  c[i] = a[i] * b[i]
  histogram  (data, n, bins_ptr, nbins)    atom_add per-bin counter

reduce_sum/reduce_max also test u64 warp-shuffle splitting (d0a4442).
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1017_gpu_warp_reduce.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


print("FORGE: 1017_gpu_warp_reduce")
print("-" * 60)
ok, total = 0, 0

ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))


def make_params(items):
    """Build a c_void_p array of pointers to the c-typed values in `items`."""
    holders = list(items)  # keep alive for duration
    addrs = (ctypes.c_void_p * len(holders))(*[ctypes.cast(ctypes.pointer(h), ctypes.c_void_p) for h in holders])
    return holders, addrs


# ----- vec_add / vec_mul / saxpy -----
for kname, op in [(b"vec_add", lambda a, b: a + b),
                  (b"vec_mul", lambda a, b: a * b)]:
    fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, kname))
    for N in [256, 1024, 4096]:
        np.random.seed(N + hash(kname) % 1000)
        a = np.random.randint(0, 100, size=N).astype(np.uint64)
        b = np.random.randint(0, 100, size=N).astype(np.uint64)
        c = np.zeros(N, dtype=np.uint64)
        nbytes = N * 8
        d_a = ctypes.c_uint64(); d_b = ctypes.c_uint64(); d_c = ctypes.c_uint64()
        ck(cuda.cuMemAlloc_v2(ctypes.byref(d_a), nbytes))
        ck(cuda.cuMemAlloc_v2(ctypes.byref(d_b), nbytes))
        ck(cuda.cuMemAlloc_v2(ctypes.byref(d_c), nbytes))
        ck(cuda.cuMemcpyHtoD_v2(d_a, a.ctypes.data_as(ctypes.c_void_p), nbytes))
        ck(cuda.cuMemcpyHtoD_v2(d_b, b.ctypes.data_as(ctypes.c_void_p), nbytes))
        ck(cuda.cuMemcpyHtoD_v2(d_c, c.ctypes.data_as(ctypes.c_void_p), nbytes))
        items = [ctypes.c_uint64(d_a.value), ctypes.c_uint64(N),
                 ctypes.c_uint64(d_b.value), ctypes.c_uint64(N),
                 ctypes.c_uint64(d_c.value), ctypes.c_uint64(N), ctypes.c_uint64(N)]
        holders, params = make_params(items)
        BLOCK = 256; GRID = (N + BLOCK - 1) // BLOCK
        ck(cuda.cuLaunchKernel(fn, GRID, 1, 1, BLOCK, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
        ck(cuda.cuCtxSynchronize())
        ck(cuda.cuMemcpyDtoH_v2(c.ctypes.data, d_c, nbytes))
        expected = op(a, b)
        correct = bool((c == expected).all())
        total += 1; ok += int(correct)
        print(f"  {kname.decode():>10} N={N:>5}  {'PASS' if correct else 'FAIL'}")
        cuda.cuMemFree_v2(d_a); cuda.cuMemFree_v2(d_b); cuda.cuMemFree_v2(d_c)


# saxpy: y = a*x + y
fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"saxpy"))
for N in [256, 1024, 4096]:
    np.random.seed(N * 13)
    x = np.random.randint(0, 100, size=N).astype(np.uint64)
    y = np.random.randint(0, 100, size=N).astype(np.uint64)
    y_init = y.copy()
    a = np.uint64(7)
    nbytes = N * 8
    d_x = ctypes.c_uint64(); d_y = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_x), nbytes)); ck(cuda.cuMemAlloc_v2(ctypes.byref(d_y), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_x, x.ctypes.data_as(ctypes.c_void_p), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_y, y.ctypes.data_as(ctypes.c_void_p), nbytes))
    items = [ctypes.c_uint64(d_x.value), ctypes.c_uint64(N),
             ctypes.c_uint64(d_y.value), ctypes.c_uint64(N),
             ctypes.c_uint64(int(a)), ctypes.c_uint64(N)]
    holders, params = make_params(items)
    BLOCK = 256; GRID = (N + BLOCK - 1) // BLOCK
    ck(cuda.cuLaunchKernel(fn, GRID, 1, 1, BLOCK, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(y.ctypes.data, d_y, nbytes))
    expected = a * x + y_init
    correct = bool((y == expected).all())
    total += 1; ok += int(correct)
    print(f"  {'saxpy':>10} N={N:>5}  {'PASS' if correct else 'FAIL'}")
    cuda.cuMemFree_v2(d_x); cuda.cuMemFree_v2(d_y)


# reduce_sum: result_ptr is a single u64 cell (atomic add target)
fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"reduce_sum"))
for N in [256, 1024, 4096]:
    np.random.seed(N * 7)
    data = np.random.randint(0, 1000, size=N).astype(np.uint64)
    result = np.zeros(1, dtype=np.uint64)
    nbytes = N * 8
    d_data = ctypes.c_uint64(); d_res = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_data), nbytes)); ck(cuda.cuMemAlloc_v2(ctypes.byref(d_res), 8))
    ck(cuda.cuMemcpyHtoD_v2(d_data, data.ctypes.data_as(ctypes.c_void_p), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_res, result.ctypes.data_as(ctypes.c_void_p), 8))
    items = [ctypes.c_uint64(d_data.value), ctypes.c_uint64(N),
             ctypes.c_uint64(N), ctypes.c_uint64(d_res.value)]
    holders, params = make_params(items)
    BLOCK = 256; GRID = (N + BLOCK - 1) // BLOCK
    ck(cuda.cuLaunchKernel(fn, GRID, 1, 1, BLOCK, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(result.ctypes.data, d_res, 8))
    expected = int(data.sum())
    correct = int(result[0]) == expected
    total += 1; ok += int(correct)
    print(f"  {'reduce_sum':>10} N={N:>5}  expect={expected:>10}  got={int(result[0]):>10}  {'PASS' if correct else 'FAIL'}")
    cuda.cuMemFree_v2(d_data); cuda.cuMemFree_v2(d_res)


cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 60); print(f"OVERALL: {ok}/{total}")
