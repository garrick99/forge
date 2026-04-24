"""FORGE65-68 harness — full tiled matmul C = A*B with arbitrary K.

Bench against numpy reference at several (M, N, K) sizes, all multiples of
TILE=16.  Reports correctness + timing.
"""
import ctypes
import time

import numpy as np

cuda = ctypes.CDLL("nvcuda.dll")
for fn in ("cuMemcpyHtoD_v2", "cuMemcpyDtoH_v2", "cuMemAlloc_v2"):
    pass

import os, sys
OURS = r"C:\users\kraken\forge\demos\1115_forge_tiled_matmul_kloop.cubin"
REF  = r"C:\users\kraken\forge\demos\1115_forge_tiled_matmul_kloop_REF.cubin"
CUBIN = os.environ.get('CUBIN', OURS)
WHICH = 'OpenPTXas' if CUBIN == OURS else 'ptxas(REF)'
print(f"Using cubin: {CUBIN}  [{WHICH}]")
TILE = 16


def chk(err, msg=""):
    if err != 0:
        raise RuntimeError(f"{msg}: cuda err {err}")


def cpu_matmul(a, b, M, N, K):
    # Use numpy with uint32 semantics (wraps modulo 2^32 like the GPU kernel)
    A = a.reshape(M, K).astype(np.uint64)
    B = b.reshape(K, N).astype(np.uint64)
    C = (A @ B).astype(np.uint32)
    return C.reshape(-1)


def lcg(n, seed=0xC0FFEEAB):
    arr = np.empty(n, dtype=np.uint32)
    s = np.uint32(seed)
    for i in range(n):
        s = np.uint32(np.uint64(s) * np.uint64(1103515245) + np.uint64(12345))
        arr[i] = np.uint32(s & 0xF)  # small values to keep uint32 headroom
    return arr


chk(cuda.cuInit(0))
DEV = ctypes.c_int()
chk(cuda.cuDeviceGet(ctypes.byref(DEV), 0))

shapes = [
    (16, 16, 16),
    (16, 16, 32),
    (32, 32, 64),
    (64, 64, 128),
    (128, 128, 256),
    (256, 256, 512),
]

print(f"{'M':>4} {'N':>4} {'K':>5}  "
      f"{'correct':>8}  "
      f"{'GPU ms':>8}  "
      f"{'CPU ms':>8}  "
      f"{'speedup':>8}")
print("-" * 60)

ok_total = 0
n_total = 0
for (M, N, K) in shapes:
    ctx = ctypes.c_void_p()
    chk(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
    mod = ctypes.c_void_p()
    chk(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
    fn = ctypes.c_void_p()
    chk(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"matmul_kloop"))

    a_data = lcg(M * K, seed=0xC0FFEEAB + M * 31)
    b_data = lcg(K * N, seed=0xDEADBEEF + N * 31)
    c_gpu = np.zeros(M * N, dtype=np.uint32)

    na = M * K * 4
    nb = K * N * 4
    nc = M * N * 4
    d_a = ctypes.c_uint64(); d_b = ctypes.c_uint64(); d_c = ctypes.c_uint64()
    chk(cuda.cuMemAlloc_v2(ctypes.byref(d_a), na))
    chk(cuda.cuMemAlloc_v2(ctypes.byref(d_b), nb))
    chk(cuda.cuMemAlloc_v2(ctypes.byref(d_c), nc))
    cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
    cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
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
    p_k    = ctypes.c_uint32(K)

    params = (ctypes.c_void_p * 9)(*[
        ctypes.cast(ctypes.pointer(x), ctypes.c_void_p)
        for x in [p_a, p_alen, p_b, p_blen, p_c, p_clen, p_m, p_n, p_k]
    ])

    bx = (N + TILE - 1) // TILE
    by = (M + TILE - 1) // TILE

    # Warmup
    cuda.cuLaunchKernel(fn, bx, by, 1, TILE, TILE, 1,
                        0, ctypes.c_void_p(0), params, ctypes.c_void_p(0))
    cuda.cuCtxSynchronize()

    # Time GPU (average of 5 launches)
    n_iters = 5
    t0 = time.perf_counter()
    for _ in range(n_iters):
        cuda.cuLaunchKernel(fn, bx, by, 1, TILE, TILE, 1,
                            0, ctypes.c_void_p(0), params, ctypes.c_void_p(0))
    cuda.cuCtxSynchronize()
    gpu_ms = (time.perf_counter() - t0) * 1000 / n_iters

    chk(cuda.cuMemcpyDtoH_v2(c_gpu.ctypes.data, d_c, nc))

    # CPU reference timing
    t0 = time.perf_counter()
    expected = cpu_matmul(a_data, b_data, M, N, K)
    cpu_ms = (time.perf_counter() - t0) * 1000

    mis = int(np.sum(c_gpu != expected))
    correct = mis == 0
    n_total += 1
    if correct:
        ok_total += 1
    speedup = cpu_ms / gpu_ms if gpu_ms > 0 else 0.0
    print(f"{M:>4} {N:>4} {K:>5}  "
          f"{'PASS' if correct else 'FAIL':>8}  "
          f"{gpu_ms:>8.3f}  "
          f"{cpu_ms:>8.3f}  "
          f"{speedup:>7.1f}x")
    cuda.cuMemFree_v2(d_a)
    cuda.cuMemFree_v2(d_b)
    cuda.cuMemFree_v2(d_c)
    cuda.cuModuleUnload(mod)
    cuda.cuCtxDestroy_v2(ctx)

print("-" * 60)
print(f"OVERALL: {ok_total}/{n_total}")
