"""Forge-native QM31 kernels — GPU validation harness.

Demo 1024 has 3 kernels:
  qm31_accumulate_kernel    out += alpha * v          (QM31 multiply-accumulate)
  qm31_fri_fold_kernel      new[i] = old[i] + alpha * old[i+half]
  qm31_pointwise_mul_kernel out[i] = a[i] * b[i]

QM31 = CM31[j]/(j^2 - (2+i)),  CM31 = M31[i]/(i^2+1)
Element = (a, b) in CM31, stored as (a.re, a.im, b.re, b.im) — 4 M31 words.
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1024_qm31_kernels.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


P = (1 << 31) - 1
def m31_add(a, b): return ((a.astype(np.uint64) + b.astype(np.uint64)) % P).astype(np.uint32)
def m31_sub(a, b): return ((a.astype(np.int64) - b.astype(np.int64)) % P).astype(np.uint32)
def m31_mul(a, b): return ((a.astype(np.uint64) * b.astype(np.uint64)) % P).astype(np.uint32)


def cm31_add(ar, ai, br, bi): return m31_add(ar, br), m31_add(ai, bi)
def cm31_sub(ar, ai, br, bi): return m31_sub(ar, br), m31_sub(ai, bi)
def cm31_mul(ar, ai, br, bi):
    re = m31_sub(m31_mul(ar, br), m31_mul(ai, bi))
    im = m31_add(m31_mul(ar, bi), m31_mul(ai, br))
    return re, im


def qm31_mul(a_rr, a_ri, a_ir, a_ii, b_rr, b_ri, b_ir, b_ii):
    """(a + bj)(c + dj) = (ac + bd*(2+i)) + (ad + bc)j  in QM31."""
    # a*c
    ac_r, ac_i = cm31_mul(a_rr, a_ri, b_rr, b_ri)
    # b*d
    bd_r, bd_i = cm31_mul(a_ir, a_ii, b_ir, b_ii)
    # b*d * (2+i): multiply by CM31 (2, 1)
    two = np.full_like(bd_r, 2 % P, dtype=np.uint32)
    one = np.full_like(bd_r, 1 % P, dtype=np.uint32)
    bdmul_r, bdmul_i = cm31_mul(bd_r, bd_i, two, one)
    # a-component = a*c + b*d*(2+i)
    out_a_r, out_a_i = cm31_add(ac_r, ac_i, bdmul_r, bdmul_i)
    # a*d
    ad_r, ad_i = cm31_mul(a_rr, a_ri, b_ir, b_ii)
    # b*c
    bc_r, bc_i = cm31_mul(a_ir, a_ii, b_rr, b_ri)
    # b-component = a*d + b*c
    out_b_r, out_b_i = cm31_add(ad_r, ad_i, bc_r, bc_i)
    return out_a_r, out_a_i, out_b_r, out_b_i


def qm31_add(a_rr, a_ri, a_ir, a_ii, b_rr, b_ri, b_ir, b_ii):
    return m31_add(a_rr, b_rr), m31_add(a_ri, b_ri), m31_add(a_ir, b_ir), m31_add(a_ii, b_ii)


def rand_m31(rng, *shape): return rng.integers(0, P, size=shape, dtype=np.uint32)
def alloc_copy_to_dev(arr):
    d = ctypes.c_uint64(); ck(cuda.cuMemAlloc_v2(ctypes.byref(d), arr.nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d, arr.ctypes.data_as(ctypes.c_void_p), arr.nbytes))
    return d
def fetch(d, arr): ck(cuda.cuMemcpyDtoH_v2(arr.ctypes.data, d, arr.nbytes))
def make_params(*items):
    holders = list(items)
    addrs = (ctypes.c_void_p * len(holders))(*[ctypes.cast(ctypes.pointer(h), ctypes.c_void_p) for h in holders])
    return holders, addrs


print("FORGE: 1024_qm31_kernels (accumulate / fri_fold / pointwise_mul)")
print("-" * 64)
ok, total = 0, 0
ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))


# ---- qm31_accumulate_kernel: out += alpha * v ----
fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"qm31_accumulate_kernel"))
for n in [16, 64, 256]:
    rng = np.random.default_rng(n + 1)
    out_arr = [rand_m31(rng, n) for _ in range(4)]
    v_arr = [rand_m31(rng, n) for _ in range(4)]
    alpha = [int(rng.integers(0, P, dtype=np.uint32)) for _ in range(4)]
    out_init = [a.copy() for a in out_arr]
    d_outs = [alloc_copy_to_dev(a) for a in out_arr]
    d_vs = [alloc_copy_to_dev(a) for a in v_arr]
    items = []
    for d in d_outs: items += [ctypes.c_uint64(d.value), ctypes.c_uint64(n)]
    for d in d_vs:   items += [ctypes.c_uint64(d.value), ctypes.c_uint64(n)]
    items += [ctypes.c_uint32(alpha[0]), ctypes.c_uint32(alpha[1]),
              ctypes.c_uint32(alpha[2]), ctypes.c_uint32(alpha[3]), ctypes.c_uint64(n)]
    _, params = make_params(*items)
    BLOCK = 256; GRID = (n + BLOCK - 1) // BLOCK
    ck(cuda.cuLaunchKernel(fn, GRID, 1, 1, BLOCK, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    for d, a in zip(d_outs, out_arr): fetch(d, a)

    a_alpha = [np.full(n, ai, dtype=np.uint32) for ai in alpha]
    av = qm31_mul(*a_alpha, *v_arr)
    expected = qm31_add(*out_init, *av)
    correct = all(bool((g == e).all()) for g, e in zip(out_arr, expected))
    total += 1; ok += int(correct)
    print(f"  qm31_accumulate    n={n:>4}  {'PASS' if correct else 'FAIL'}")
    for d in d_outs + d_vs: cuda.cuMemFree_v2(d)


# ---- qm31_fri_fold_kernel: new[i] = old[i] + alpha * old[i+half] ----
fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"qm31_fri_fold_kernel"))
for half in [16, 64, 256]:
    n = 2 * half
    rng = np.random.default_rng(half + 31)
    old_arr = [rand_m31(rng, n) for _ in range(4)]
    new_arr = [np.zeros(half, dtype=np.uint32) for _ in range(4)]
    alpha = [int(rng.integers(0, P, dtype=np.uint32)) for _ in range(4)]
    d_news = [alloc_copy_to_dev(a) for a in new_arr]
    d_olds = [alloc_copy_to_dev(a) for a in old_arr]
    items = []
    for d in d_news: items += [ctypes.c_uint64(d.value), ctypes.c_uint64(half)]
    for d in d_olds: items += [ctypes.c_uint64(d.value), ctypes.c_uint64(n)]
    items += [ctypes.c_uint32(alpha[0]), ctypes.c_uint32(alpha[1]),
              ctypes.c_uint32(alpha[2]), ctypes.c_uint32(alpha[3]),
              ctypes.c_uint64(half), ctypes.c_uint64(n)]
    _, params = make_params(*items)
    BLOCK = 256; GRID = (half + BLOCK - 1) // BLOCK
    ck(cuda.cuLaunchKernel(fn, GRID, 1, 1, BLOCK, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    for d, a in zip(d_news, new_arr): fetch(d, a)

    a_old = [a[:half] for a in old_arr]; b_old = [a[half:] for a in old_arr]
    a_alpha = [np.full(half, ai, dtype=np.uint32) for ai in alpha]
    ab = qm31_mul(*a_alpha, *b_old)
    expected = qm31_add(*a_old, *ab)
    correct = all(bool((g == e).all()) for g, e in zip(new_arr, expected))
    total += 1; ok += int(correct)
    print(f"  qm31_fri_fold      half={half:>4}  {'PASS' if correct else 'FAIL'}")
    for d in d_news + d_olds: cuda.cuMemFree_v2(d)


# ---- qm31_pointwise_mul_kernel: out[i] = a[i] * b[i] ----
fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"qm31_pointwise_mul_kernel"))
for n in [16, 64, 256]:
    rng = np.random.default_rng(n + 99)
    out_arr = [np.zeros(n, dtype=np.uint32) for _ in range(4)]
    a_arr = [rand_m31(rng, n) for _ in range(4)]
    b_arr = [rand_m31(rng, n) for _ in range(4)]
    d_outs = [alloc_copy_to_dev(a) for a in out_arr]
    d_as = [alloc_copy_to_dev(a) for a in a_arr]
    d_bs = [alloc_copy_to_dev(a) for a in b_arr]
    items = []
    for d in d_outs: items += [ctypes.c_uint64(d.value), ctypes.c_uint64(n)]
    for d in d_as:   items += [ctypes.c_uint64(d.value), ctypes.c_uint64(n)]
    for d in d_bs:   items += [ctypes.c_uint64(d.value), ctypes.c_uint64(n)]
    items += [ctypes.c_uint64(n)]
    _, params = make_params(*items)
    BLOCK = 256; GRID = (n + BLOCK - 1) // BLOCK
    ck(cuda.cuLaunchKernel(fn, GRID, 1, 1, BLOCK, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    for d, a in zip(d_outs, out_arr): fetch(d, a)

    expected = qm31_mul(*a_arr, *b_arr)
    correct = all(bool((g == e).all()) for g, e in zip(out_arr, expected))
    total += 1; ok += int(correct)
    print(f"  qm31_pointwise_mul n={n:>4}  {'PASS' if correct else 'FAIL'}")
    for d in d_outs + d_as + d_bs: cuda.cuMemFree_v2(d)


cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 64); print(f"OVERALL: {ok}/{total}")
