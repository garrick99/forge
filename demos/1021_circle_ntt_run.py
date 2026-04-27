"""Forge-native Circle NTT butterfly kernels (M31, CM31) — GPU validation harness.

Demo 1021 has 3 kernels:
  circle_ntt_layer  (re, twiddle, half, n)        u = re[i], v = re[i+half]; tv = tw*v;
                                                   re[i] = u+tv; re[i+half] = u-tv  (M31)
  circle_intt_layer (re, twiddle, half, n)        same with -tw (inverse twiddle)
  circle_ntt_layer_cm31 (re_arr, im_arr, tw_re, tw_im, half, n)  CM31 butterfly
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1021_circle_ntt.cubin'))
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
def m31_neg(a):    return ((P - a.astype(np.int64)) % P).astype(np.uint32)
def cm31_mul(ar, ai, br, bi):
    return m31_sub(m31_mul(ar, br), m31_mul(ai, bi)), m31_add(m31_mul(ar, bi), m31_mul(ai, br))


def rand_m31(rng, *shape): return rng.integers(0, P, size=shape, dtype=np.uint32)
def alloc_copy_to_dev(arr):
    nbytes = arr.nbytes
    d = ctypes.c_uint64(); ck(cuda.cuMemAlloc_v2(ctypes.byref(d), nbytes))
    ck(cuda.cuMemcpyHtoD_v2(d, arr.ctypes.data_as(ctypes.c_void_p), nbytes))
    return d, nbytes
def fetch(d, arr): ck(cuda.cuMemcpyDtoH_v2(arr.ctypes.data, d, arr.nbytes))
def make_params(*items):
    holders = list(items)
    addrs = (ctypes.c_void_p * len(holders))(*[ctypes.cast(ctypes.pointer(h), ctypes.c_void_p) for h in holders])
    return holders, addrs


print("FORGE: 1021_circle_ntt (M31/CM31 butterfly)")
print("-" * 60)
ok, total = 0, 0
ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))


# circle_ntt_layer + circle_intt_layer (intt negates the twiddle)
for kname, neg_tw in [(b"circle_ntt_layer", False), (b"circle_intt_layer", True)]:
    fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, kname))
    for half in [16, 64, 256]:
        n = 2 * half
        rng = np.random.default_rng(half * 31 + (1 if neg_tw else 0))
        re = rand_m31(rng, n)
        twiddle = rand_m31(rng, half)
        re_in = re.copy()
        d_re, _ = alloc_copy_to_dev(re); d_tw, _ = alloc_copy_to_dev(twiddle)
        items = [ctypes.c_uint64(d_re.value), ctypes.c_uint64(n),
                 ctypes.c_uint64(d_tw.value), ctypes.c_uint64(half),
                 ctypes.c_uint64(half), ctypes.c_uint64(n)]
        _, params = make_params(*items)
        BLOCK = 256; GRID = (half + BLOCK - 1) // BLOCK
        ck(cuda.cuLaunchKernel(fn, GRID, 1, 1, BLOCK, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
        ck(cuda.cuCtxSynchronize())
        fetch(d_re, re)

        u = re_in[:half]; v = re_in[half:]
        tw = m31_neg(twiddle) if neg_tw else twiddle
        tv = m31_mul(tw, v)
        exp_top = m31_add(u, tv); exp_bot = m31_sub(u, tv)
        correct = bool((re[:half] == exp_top).all() and (re[half:] == exp_bot).all())
        total += 1; ok += int(correct)
        print(f"  {kname.decode():>22} half={half:>4}  {'PASS' if correct else 'FAIL'}")
        cuda.cuMemFree_v2(d_re); cuda.cuMemFree_v2(d_tw)


# circle_ntt_layer_cm31
fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"circle_ntt_layer_cm31"))
for half in [16, 64, 256]:
    n = 2 * half
    rng = np.random.default_rng(half + 7)
    re_arr = rand_m31(rng, n); im_arr = rand_m31(rng, n)
    tw_re = rand_m31(rng, half); tw_im = rand_m31(rng, half)
    re_in = re_arr.copy(); im_in = im_arr.copy()
    d_r, _ = alloc_copy_to_dev(re_arr); d_i, _ = alloc_copy_to_dev(im_arr)
    d_tr, _ = alloc_copy_to_dev(tw_re); d_ti, _ = alloc_copy_to_dev(tw_im)
    items = [ctypes.c_uint64(d_r.value), ctypes.c_uint64(n),
             ctypes.c_uint64(d_i.value), ctypes.c_uint64(n),
             ctypes.c_uint64(d_tr.value), ctypes.c_uint64(half),
             ctypes.c_uint64(d_ti.value), ctypes.c_uint64(half),
             ctypes.c_uint64(half), ctypes.c_uint64(n)]
    _, params = make_params(*items)
    BLOCK = 256; GRID = (half + BLOCK - 1) // BLOCK
    ck(cuda.cuLaunchKernel(fn, GRID, 1, 1, BLOCK, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    fetch(d_r, re_arr); fetch(d_i, im_arr)

    u_re, u_im = re_in[:half], im_in[:half]
    v_re, v_im = re_in[half:], im_in[half:]
    tv_re, tv_im = cm31_mul(tw_re, tw_im, v_re, v_im)
    exp_top_re = m31_add(u_re, tv_re); exp_top_im = m31_add(u_im, tv_im)
    exp_bot_re = m31_sub(u_re, tv_re); exp_bot_im = m31_sub(u_im, tv_im)
    correct = bool((re_arr[:half] == exp_top_re).all() and (im_arr[:half] == exp_top_im).all()
                   and (re_arr[half:] == exp_bot_re).all() and (im_arr[half:] == exp_bot_im).all())
    total += 1; ok += int(correct)
    print(f"  {'circle_ntt_layer_cm31':>22} half={half:>4}  {'PASS' if correct else 'FAIL'}")
    cuda.cuMemFree_v2(d_r); cuda.cuMemFree_v2(d_i)
    cuda.cuMemFree_v2(d_tr); cuda.cuMemFree_v2(d_ti)


cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 60); print(f"OVERALL: {ok}/{total}")
