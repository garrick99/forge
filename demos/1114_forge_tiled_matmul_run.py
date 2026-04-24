"""FORGE61-64 GPU harness — tiled matmul microkernel (K=16)."""
import ctypes
import numpy as np

cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]

CUBIN = r"C:\users\kraken\forge\demos\1114_forge_tiled_matmul.cubin"
K = 16

def chk(err, msg=""):
    if err != 0:
        raise RuntimeError(f"{msg}: cuda err {err}")

def lcg(n, seed=0xC0FFEEAB):
    arr = np.empty(n, dtype=np.uint32)
    s = np.uint32(seed)
    for i in range(n):
        s = np.uint32(np.uint64(s) * np.uint64(1103515245) + np.uint64(12345))
        arr[i] = np.uint32(s & 0xF)  # small to avoid overflow
    return arr

def cpu_matmul(a, b, M, N, K_):
    c = np.zeros(M * N, dtype=np.uint32)
    for r in range(M):
        for col in range(N):
            s = np.uint32(0)
            for k in range(K_):
                s = np.uint32(s + np.uint32(a[r * K_ + k]) * np.uint32(b[k * N + col]))
            c[r * N + col] = s
    return c

chk(cuda.cuInit(0))
DEV = ctypes.c_int()
chk(cuda.cuDeviceGet(ctypes.byref(DEV), 0))

TILE = 16
# (M, N) pairs — K is always 16
shapes = [(16, 16), (32, 16), (16, 32), (32, 32)]
patterns = [
    ("sequential", lambda n: np.arange(n, dtype=np.uint32) & 0xF),
    ("affine",     lambda n: ((3 * np.arange(n, dtype=np.uint32) + 1) & 0xF).astype(np.uint32)),
    ("lcg-random", lcg),
]

ok_total = 0
n_total = 0
for (M, N) in shapes:
    for pname, pfn in patterns:
        ctx = ctypes.c_void_p()
        chk(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
        mod = ctypes.c_void_p()
        chk(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
        fn = ctypes.c_void_p()
        chk(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"matmul_16"))

        a_data = pfn(M * K)
        b_data = pfn(K * N)
        c_gpu = np.zeros(M * N, dtype=np.uint32)

        na = M * K * 4; nb = K * N * 4; nc = M * N * 4
        d_a = ctypes.c_uint64(); d_b = ctypes.c_uint64(); d_c = ctypes.c_uint64()
        chk(cuda.cuMemAlloc_v2(ctypes.byref(d_a), na))
        chk(cuda.cuMemAlloc_v2(ctypes.byref(d_b), nb))
        chk(cuda.cuMemAlloc_v2(ctypes.byref(d_c), nc))
        chk(cuda.cuMemcpyHtoD_v2(d_a, a_data.ctypes.data_as(ctypes.c_void_p), na))
        chk(cuda.cuMemcpyHtoD_v2(d_b, b_data.ctypes.data_as(ctypes.c_void_p), nb))
        chk(cuda.cuMemcpyHtoD_v2(d_c, c_gpu.ctypes.data_as(ctypes.c_void_p), nc))

        p_a    = ctypes.c_uint64(d_a.value)
        p_alen = ctypes.c_uint64(M * K)
        p_b    = ctypes.c_uint64(d_b.value)
        p_blen = ctypes.c_uint64(K * N)
        p_c    = ctypes.c_uint64(d_c.value)
        p_clen = ctypes.c_uint64(M * N)
        p_m    = ctypes.c_uint32(M)
        p_n    = ctypes.c_uint32(N)
        
        params = (ctypes.c_void_p * 8)(*[
            ctypes.cast(ctypes.pointer(x), ctypes.c_void_p)
            for x in [p_a, p_alen, p_b, p_blen, p_c, p_clen, p_m, p_n]
        ])

        bx = (N + TILE - 1) // TILE
        by = (M + TILE - 1) // TILE

        e1 = cuda.cuLaunchKernel(fn, bx, by, 1, TILE, TILE, 1,
                                  0, ctypes.c_void_p(0), params, ctypes.c_void_p(0))
        e2 = cuda.cuCtxSynchronize()
        chk(cuda.cuMemcpyDtoH_v2(c_gpu.ctypes.data, d_c, nc))

        expected = cpu_matmul(a_data, b_data, M, N, K)
        mis = int(np.sum(c_gpu != expected))

        n_total += 1
        res = "PASS" if (e1 == 0 and e2 == 0 and mis == 0) else "FAIL"
        if res == "PASS":
            ok_total += 1
        label = f"{M}x{K} × {K}x{N}"
        print(f"  {label:15s}  pat {pname:<12}  mismatches {mis:>5}  -> {res}")

        cuda.cuMemFree_v2(d_a); cuda.cuMemFree_v2(d_b); cuda.cuMemFree_v2(d_c)
        cuda.cuCtxDestroy_v2(ctx)

print(f"\nOVERALL: {ok_total}/{n_total}")
