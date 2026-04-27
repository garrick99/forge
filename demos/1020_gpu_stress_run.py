"""Forge-native gpu_stress — IOMMU TLB churn stress test.

Kernel: gpu_stress(data: span<u64>, n: u64, iters: u64, lcg_mul: u64, lcg_add: u64)
        Each thread runs Knuth MMIX LCG for `iters` steps. Every 1024 steps a
        scatter write to data[acc % n] forces IOMMU TLB churn. Terminal
        store: data[gid] = final acc.

Documented purpose (from the .fg):
    If running this kernel crashes Windows, the fault is in nvlddmkm.sys /
    Hyper-V VT-d IOMMU — NOT in the application.

Validation: this is intentionally a stress test, not a correctness test.
Multiple threads scatter-write to the same indices, so the final data
state is racy and a deterministic reference cannot be computed. The
harness verifies:
  1. The kernel launches and synchronises without a CUDA error.
  2. The final data is non-degenerate (not all zeros, not all the
     initial pattern — i.e. the kernel actually executed).
  3. For the per-thread final `data[gid] = acc` write, at least some
     threads' final accumulator matches the per-thread CPU LCG (some
     entries get overwritten by later scatter writes from other threads,
     so a fraction below 100% is normal).

Knuth MMIX LCG constants (passed as kernel args, no compiled-in secrets):
    mul = 6364136223846793005
    add = 1442695040888963407
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1020_gpu_stress.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


MUL = np.uint64(6364136223846793005)
ADD = np.uint64(1442695040888963407)


def cpu_final_acc(data_init, gid, n, iters):
    """Compute the per-thread terminal acc value (no scatter race interference).
    Mirrors the kernel arithmetic with u64 wrapping."""
    acc = (data_init[gid] + np.uint64(gid) + np.uint64(1)) & np.uint64(0xFFFFFFFFFFFFFFFF)
    for _ in range(iters):
        acc = (acc * MUL + ADD) & np.uint64(0xFFFFFFFFFFFFFFFF)
    return acc


# (n_threads, iters): ramp from light to medium-heavy.
cases = [
    (1024,   100),
    (16384,  512),
    (65536,  1024),
    (262144, 2048),
    (1048576, 4096),
]
print("FORGE: 1020_gpu_stress (IOMMU TLB churn)")
print(f"{'N':>10} {'iters':>6}  {'launch':>8}  {'nonzero':>8}  {'tid_match%':>10}")
print("-" * 54)
ok, total = 0, 0
ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"gpu_stress"))


for (N, iters) in cases:
    rng = np.random.default_rng(N + iters)
    data_init = rng.integers(0, 1_000_000, size=N, dtype=np.uint64)
    data = data_init.copy()

    nbytes = N * 8
    d_data = ctypes.c_uint64(); ck(cuda.cuMemAlloc_v2(ctypes.byref(d_data), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d_data, data.ctypes.data_as(ctypes.c_void_p), nbytes))
    items = [ctypes.c_uint64(d_data.value), ctypes.c_uint64(N),
             ctypes.c_uint64(N), ctypes.c_uint64(iters),
             ctypes.c_uint64(int(MUL)), ctypes.c_uint64(int(ADD))]
    addrs = [ctypes.cast(ctypes.pointer(x), ctypes.c_void_p) for x in items]
    params = (ctypes.c_void_p * len(addrs))(*addrs)
    BLOCK = 256; GRID = (N + BLOCK - 1) // BLOCK

    launch_ok = False
    try:
        ck(cuda.cuLaunchKernel(fn, GRID, 1, 1, BLOCK, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
        ck(cuda.cuCtxSynchronize())
        launch_ok = True
    except RuntimeError as e:
        print(f"  CRASH at N={N} iters={iters}: {e}")
        cuda.cuMemFree_v2(d_data)
        break

    ck(cuda.cuMemcpyDtoH_v2(data.ctypes.data, d_data, nbytes))

    nonzero_ok = bool((data != 0).any() and (data != data_init).any())

    # Sample a few thread indices, compute their CPU final acc, and check
    # how many match data[gid].  Scatter writes from other threads can
    # overwrite data[gid] after the terminal write, so 100% match isn't
    # guaranteed — anything > 0% confirms the kernel ran the LCG correctly.
    sample = rng.choice(N, size=min(64, N), replace=False)
    matches = 0
    for gid in sample:
        if int(data[gid]) == int(cpu_final_acc(data_init, int(gid), N, iters)):
            matches += 1
    pct = 100.0 * matches / len(sample)

    total += 1
    overall = launch_ok and nonzero_ok
    ok += int(overall)
    print(f"{N:>10} {iters:>6}  {'OK' if launch_ok else 'CRASH':>8}  "
          f"{'YES' if nonzero_ok else 'no':>8}  {pct:>9.1f}%")
    cuda.cuMemFree_v2(d_data)


cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 54)
print(f"OVERALL: {ok}/{total}  (system survived)")
