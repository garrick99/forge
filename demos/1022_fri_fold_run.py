"""Forge-native FRI fold kernels (M31, CM31) — GPU validation harness.

Demo 1022 has 3 kernels:
  fri_fold_layer    (new, old, alpha, half, n)        new[i] = old[i] + alpha*old[i+half]
  fri_unfold_layer  (new, old, alpha, half, n)        new[i] = old[i] - alpha*old[i+half]
  fri_fold_layer_cm31 (new_re/im, old_re/im, alpha_re/im, half, n)   CM31 variant

All M31 = Z/(2^31-1)Z arithmetic.
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1022_fri_fold.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


P = (1 << 31) - 1   # M31 prime


def m31_add(a, b):
    s = a.astype(np.uint64) + b.astype(np.uint64)
    return (s % P).astype(np.uint32)


def m31_sub(a, b):
    s = (a.astype(np.int64) - b.astype(np.int64)) % P
    return s.astype(np.uint32)


def m31_mul(a, b):
    return ((a.astype(np.uint64) * b.astype(np.uint64)) % P).astype(np.uint32)


def cm31_mul(ar, ai, br, bi):
    re = m31_sub(m31_mul(ar, br), m31_mul(ai, bi))
    im = m31_add(m31_mul(ar, bi), m31_mul(ai, br))
    return re, im


def rand_m31(rng, *shape):
    return rng.integers(0, P, size=shape, dtype=np.uint32)


def alloc_copy_to_dev(arr):
    nbytes = arr.nbytes
    d = ctypes.c_uint64(); ck(cuda.cuMemAlloc_v2(ctypes.byref(d), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d, arr.ctypes.data_as(ctypes.c_void_p), nbytes))
    return d, nbytes


def fetch(d, arr):
    ck(cuda.cuMemcpyDtoH_v2(arr.ctypes.data, d, arr.nbytes))


def make_params(*items):
    holders = list(items)
    addrs = (ctypes.c_void_p * len(holders))(*[ctypes.cast(ctypes.pointer(h), ctypes.c_void_p) for h in holders])
    return holders, addrs


print("FORGE: 1022_fri_fold (M31/CM31)")
print("-" * 60)
ok, total = 0, 0

ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))


# fri_fold_layer + fri_unfold_layer
for kname, op_sign in [(b"fri_fold_layer", +1), (b"fri_unfold_layer", -1)]:
    fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, kname))
    for half in [16, 64, 256]:
        n = 2 * half
        rng = np.random.default_rng(half * 17 + (1 if op_sign > 0 else 2))
        old_evals = rand_m31(rng, n)
        new_evals = np.zeros(half, dtype=np.uint32)
        alpha = rng.integers(0, P, dtype=np.uint32)

        d_old, _ = alloc_copy_to_dev(old_evals)
        d_new, _ = alloc_copy_to_dev(new_evals)
        items = [ctypes.c_uint64(d_new.value), ctypes.c_uint64(half),
                 ctypes.c_uint64(d_old.value), ctypes.c_uint64(n),
                 ctypes.c_uint32(int(alpha)), ctypes.c_uint64(half), ctypes.c_uint64(n)]
        _, params = make_params(*items)
        BLOCK = 256; GRID = (half + BLOCK - 1) // BLOCK
        ck(cuda.cuLaunchKernel(fn, GRID, 1, 1, BLOCK, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
        ck(cuda.cuCtxSynchronize())
        fetch(d_new, new_evals)

        a, b = old_evals[:half], old_evals[half:]
        ab = m31_mul(np.full(half, alpha, dtype=np.uint32), b)
        if op_sign > 0:
            expected = m31_add(a, ab)
        else:
            expected = m31_sub(a, ab)
        correct = bool((new_evals == expected).all())
        total += 1; ok += int(correct)
        print(f"  {kname.decode():>20} half={half:>4}  {'PASS' if correct else 'FAIL'}")
        cuda.cuMemFree_v2(d_old); cuda.cuMemFree_v2(d_new)


# fri_fold_layer_cm31
fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"fri_fold_layer_cm31"))
for half in [16, 64, 256]:
    n = 2 * half
    rng = np.random.default_rng(half + 99)
    old_re = rand_m31(rng, n); old_im = rand_m31(rng, n)
    new_re = np.zeros(half, dtype=np.uint32); new_im = np.zeros(half, dtype=np.uint32)
    alpha_re = rng.integers(0, P, dtype=np.uint32)
    alpha_im = rng.integers(0, P, dtype=np.uint32)
    d_or, _ = alloc_copy_to_dev(old_re); d_oi, _ = alloc_copy_to_dev(old_im)
    d_nr, _ = alloc_copy_to_dev(new_re); d_ni, _ = alloc_copy_to_dev(new_im)
    items = [ctypes.c_uint64(d_nr.value), ctypes.c_uint64(half),
             ctypes.c_uint64(d_ni.value), ctypes.c_uint64(half),
             ctypes.c_uint64(d_or.value), ctypes.c_uint64(n),
             ctypes.c_uint64(d_oi.value), ctypes.c_uint64(n),
             ctypes.c_uint32(int(alpha_re)), ctypes.c_uint32(int(alpha_im)),
             ctypes.c_uint64(half), ctypes.c_uint64(n)]
    _, params = make_params(*items)
    BLOCK = 256; GRID = (half + BLOCK - 1) // BLOCK
    ck(cuda.cuLaunchKernel(fn, GRID, 1, 1, BLOCK, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    fetch(d_nr, new_re); fetch(d_ni, new_im)

    a_re, a_im = old_re[:half], old_im[:half]
    b_re, b_im = old_re[half:], old_im[half:]
    ar_full = np.full(half, alpha_re, dtype=np.uint32)
    ai_full = np.full(half, alpha_im, dtype=np.uint32)
    ab_re, ab_im = cm31_mul(ar_full, ai_full, b_re, b_im)
    exp_re = m31_add(a_re, ab_re); exp_im = m31_add(a_im, ab_im)
    correct = bool((new_re == exp_re).all() and (new_im == exp_im).all())
    total += 1; ok += int(correct)
    print(f"  {'fri_fold_layer_cm31':>20} half={half:>4}  {'PASS' if correct else 'FAIL'}")
    cuda.cuMemFree_v2(d_or); cuda.cuMemFree_v2(d_oi); cuda.cuMemFree_v2(d_nr); cuda.cuMemFree_v2(d_ni)


cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 60); print(f"OVERALL: {ok}/{total}")
