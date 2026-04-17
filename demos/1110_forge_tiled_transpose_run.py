"""FORGE45-48 GPU harness — tiled transpose.

Tests two cubins built from the SAME Forge-emitted PTX:
  1. OpenPTXas (under test) — `1110_forge_tiled_transpose.cubin`
  2. NVIDIA ptxas (reference, oracle) — `1110_forge_tiled_transpose_REF.cubin`

If both produce zero mismatches, the slice is FORGE_TRANSPOSE_SUCCESS.
If only the reference passes, the OpenPTXas backend is the blocker
(Forge / OpenCUDA / PTX are correct).
"""
import ctypes
import sys
import numpy as np

cuda = ctypes.CDLL("nvcuda.dll")

CUBIN_OURS = r"C:\users\kraken\forge\demos\1110_forge_tiled_transpose.cubin"
CUBIN_REF  = r"C:\users\kraken\forge\demos\1110_forge_tiled_transpose_REF.cubin"

def chk(err, msg=""):
    if err != 0:
        raise RuntimeError(f"{msg}: cuda err {err}")

cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes   = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]

def lcg(n, seed=0xC0FFEEAB):
    arr = np.empty(n, dtype=np.uint32)
    s = np.uint32(seed)
    for i in range(n):
        s = np.uint32(np.uint64(s) * np.uint64(1103515245) + np.uint64(12345))
        arr[i] = s & 0xFFFFFFFF
    return arr

PATTERNS = [
    ("sequential",  lambda n: np.arange(n, dtype=np.uint32)),
    ("affine",      lambda n: (3 * np.arange(n, dtype=np.uint32) + 7).astype(np.uint32)),
    ("lcg-random",  lcg),
]
SHAPES = [(16, 16), (32, 16), (16, 32), (64, 64)]

def run_one(fn, width, height, inp):
    n = width * height
    out = np.zeros(n, dtype=np.uint32)
    nb = n * 4
    d_in  = ctypes.c_uint64()
    d_out = ctypes.c_uint64()
    chk(cuda.cuMemAlloc_v2(ctypes.byref(d_in),  nb),  "memAlloc in")
    chk(cuda.cuMemAlloc_v2(ctypes.byref(d_out), nb),  "memAlloc out")
    chk(cuda.cuMemcpyHtoD_v2(d_in,  inp.ctypes.data_as(ctypes.c_void_p), nb), "HtoD in")
    chk(cuda.cuMemcpyHtoD_v2(d_out, out.ctypes.data_as(ctypes.c_void_p), nb), "HtoD out")

    p_in    = ctypes.c_uint64(d_in.value)
    p_inlen = ctypes.c_uint64(n)
    p_out   = ctypes.c_uint64(d_out.value)
    p_outln = ctypes.c_uint64(n)
    p_w     = ctypes.c_uint32(width)
    p_h     = ctypes.c_uint32(height)
    params = (ctypes.c_void_p * 6)(*[
        ctypes.cast(ctypes.pointer(x), ctypes.c_void_p)
        for x in [p_in, p_inlen, p_out, p_outln, p_w, p_h]
    ])

    TILE = 16
    bx = (width  + TILE - 1) // TILE
    by = (height + TILE - 1) // TILE

    err = cuda.cuLaunchKernel(
        fn,
        bx, by, 1,
        TILE, TILE, 1,
        0, ctypes.c_void_p(0),
        params, ctypes.c_void_p(0),
    )
    if err != 0:
        cuda.cuMemFree_v2(d_in); cuda.cuMemFree_v2(d_out)
        return None, f"launch err {err}"
    err = cuda.cuCtxSynchronize()
    if err != 0:
        cuda.cuMemFree_v2(d_in); cuda.cuMemFree_v2(d_out)
        return None, f"sync err {err}"
    chk(cuda.cuMemcpyDtoH_v2(out.ctypes.data, d_out, nb), "DtoH")
    cuda.cuMemFree_v2(d_in)
    cuda.cuMemFree_v2(d_out)
    return out, None

chk(cuda.cuInit(0), "cuInit")
DEV = ctypes.c_int()
chk(cuda.cuDeviceGet(ctypes.byref(DEV), 0), "cuDeviceGet")

def test_cubin(label, path):
    print(f"\n=== {label} ===")
    print(f"cubin: {path}")
    all_ok = True
    for (W, H) in SHAPES:
        for pname, pfn in PATTERNS:
            ctx = ctypes.c_void_p()
            chk(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV), "cuCtxCreate")
            mod = ctypes.c_void_p()
            err = cuda.cuModuleLoad(ctypes.byref(mod), path.encode())
            if err != 0:
                print(f"  cuModuleLoad failed: err {err}")
                cuda.cuCtxDestroy_v2(ctx)
                return False
            fn = ctypes.c_void_p()
            chk(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"transpose_tile"), "getFn")
            inp = pfn(W * H)
            out, err = run_one(fn, W, H, inp)
            if out is None:
                print(f"  shape {H:>3}x{W:<3}  pat {pname:<12}  -> RUN_ERR ({err})")
                all_ok = False
            else:
                exp = inp.reshape(H, W).T.reshape(-1).astype(np.uint32, copy=False)
                mis = int(np.sum(out != exp))
                res = "PASS" if mis == 0 else "FAIL"
                print(f"  shape {H:>3}x{W:<3} (HxW)  pat {pname:<12}  mismatches {mis:>5}  -> {res}")
                if mis != 0:
                    all_ok = False
            cuda.cuCtxDestroy_v2(ctx)
    return all_ok

ours_ok = test_cubin("OpenPTXas (UNDER TEST)", CUBIN_OURS)
ref_ok  = test_cubin("NVIDIA ptxas (REFERENCE)", CUBIN_REF)

print()
print("=" * 60)
print(f"OpenPTXas:    {'PASS' if ours_ok else 'FAIL'}")
print(f"NVIDIA ref:   {'PASS' if ref_ok  else 'FAIL'}")
if ours_ok and ref_ok:
    print("CLASSIFICATION: FORGE_TRANSPOSE_SUCCESS")
elif ref_ok and not ours_ok:
    print("CLASSIFICATION: FORGE_TRANSPOSE_BLOCKED (OpenPTXas backend blocker; PTX is correct)")
else:
    print("CLASSIFICATION: ERROR — reference also failing")
print("=" * 60)
