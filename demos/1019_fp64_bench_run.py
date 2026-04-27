"""Forge-native fp64_bench — GPU validation harness.

Kernel: fp64_bench(out: span<f64>, n_iters: u64, b: f64, c: f64)
        Each thread iterates 4 a = a*b + c accumulators n_iters times, stores sum.
        Reference: compute the same sequence in numpy float64.
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1019_fp64_bench.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


def fp64_bench_cpu(n_iters, b, c):
    a = np.array([1.0, 2.0, 3.0, 4.0], dtype=np.float64)
    bv = np.float64(b); cv = np.float64(c)
    for _ in range(n_iters):
        a = a * bv + cv
    return a.sum()


# (n_threads, n_iters, b, c) — keep n_iters small to avoid runaway accumulators
cases = [
    (256, 1, 1.0, 0.0),
    (256, 10, 1.0, 0.0),
    (1024, 100, 1.0, 0.0),
    (256, 5, 0.5, 0.5),
    (1024, 10, 1.0, 1.0),
]
print("FORGE: fp64_bench - proof-verified .fg -> CUDA C -> PTX -> SASS")
print(f"{'thr':>5} {'iter':>5} {'b':>5} {'c':>5}  {'correct':>8}  {'max_err':>10}")
print("-" * 56)
ok, total = 0, 0
for (T, n_iters, b, c) in cases:
    ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
    mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
    fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"fp64_bench"))
    out_gpu = np.zeros(T, dtype=np.float64)
    nbytes = T * 8
    d_o = ctypes.c_uint64(); ck(cuda.cuMemAlloc_v2(ctypes.byref(d_o), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_o, out_gpu.ctypes.data_as(ctypes.c_void_p), nbytes))
    p_o_data = ctypes.c_uint64(d_o.value); p_o_len = ctypes.c_uint64(T)
    p_n = ctypes.c_uint64(n_iters); p_b = ctypes.c_double(b); p_c = ctypes.c_double(c)
    addrs = [
        ctypes.cast(ctypes.pointer(p_o_data), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_o_len), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_n), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_b), ctypes.c_void_p),
        ctypes.cast(ctypes.pointer(p_c), ctypes.c_void_p),
    ]
    params = (ctypes.c_void_p * 5)(*addrs)
    BLOCK = 256; GRID = (T + BLOCK - 1) // BLOCK
    ck(cuda.cuLaunchKernel(fn, GRID, 1, 1, BLOCK, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(out_gpu.ctypes.data, d_o, nbytes))

    expected = fp64_bench_cpu(n_iters, b, c)
    err = float(np.abs(out_gpu - expected).max())
    correct = err == 0.0   # exact bit-match expected (mul + add, no FMA)
    total += 1; ok += int(correct)
    print(f"{T:>5} {n_iters:>5} {b:>5.1f} {c:>5.1f}  {'PASS' if correct else 'FAIL':>8}  {err:>10.2e}")
    cuda.cuMemFree_v2(d_o); cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 56); print(f"OVERALL: {ok}/{total}")
