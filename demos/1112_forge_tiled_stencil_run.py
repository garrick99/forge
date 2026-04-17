"""FORGE53-56 GPU harness — shared-memory tiled 5-point stencil."""
import ctypes
import numpy as np

cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]

CUBIN = r"C:\users\kraken\forge\demos\1112_forge_tiled_stencil.cubin"

def chk(err, msg=""):
    if err != 0:
        raise RuntimeError(f"{msg}: cuda err {err}")

def lcg(n, seed=0xC0FFEEAB):
    arr = np.empty(n, dtype=np.uint32)
    s = np.uint32(seed)
    for i in range(n):
        s = np.uint32(np.uint64(s) * np.uint64(1103515245) + np.uint64(12345))
        arr[i] = s & 0xFFFF
    return arr

def cpu_stencil_5pt(inp, W, H):
    out = np.zeros(W * H, dtype=np.uint32)
    for r in range(1, H - 1):
        for c in range(1, W - 1):
            out[r * W + c] = np.uint32(
                np.uint32(inp[r * W + c])
                + np.uint32(inp[(r - 1) * W + c])
                + np.uint32(inp[(r + 1) * W + c])
                + np.uint32(inp[r * W + (c - 1)])
                + np.uint32(inp[r * W + (c + 1)]))
    return out

chk(cuda.cuInit(0))
DEV = ctypes.c_int()
chk(cuda.cuDeviceGet(ctypes.byref(DEV), 0))

TILE = 16
shapes = [(16, 16), (32, 32), (64, 64)]
patterns = [
    ("sequential", lambda n: np.arange(n, dtype=np.uint32)),
    ("affine",     lambda n: (3 * np.arange(n, dtype=np.uint32) + 7).astype(np.uint32)),
    ("lcg-random", lcg),
]

ok_total = 0
n_total = 0
for (W, H) in shapes:
    for pname, pfn in patterns:
        ctx = ctypes.c_void_p()
        chk(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
        mod = ctypes.c_void_p()
        chk(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
        fn = ctypes.c_void_p()
        chk(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"tiled_stencil_5pt"))

        n = W * H
        nb = n * 4
        inp = pfn(n)
        out_gpu = np.zeros(n, dtype=np.uint32)

        d_in = ctypes.c_uint64()
        d_out = ctypes.c_uint64()
        chk(cuda.cuMemAlloc_v2(ctypes.byref(d_in), nb))
        chk(cuda.cuMemAlloc_v2(ctypes.byref(d_out), nb))
        chk(cuda.cuMemcpyHtoD_v2(d_in, inp.ctypes.data_as(ctypes.c_void_p), nb))
        chk(cuda.cuMemcpyHtoD_v2(d_out, out_gpu.ctypes.data_as(ctypes.c_void_p), nb))

        p_in   = ctypes.c_uint64(d_in.value)
        p_inl  = ctypes.c_uint64(n)
        p_out  = ctypes.c_uint64(d_out.value)
        p_outl = ctypes.c_uint64(n)
        p_w    = ctypes.c_uint32(W)
        p_h    = ctypes.c_uint32(H)
        params = (ctypes.c_void_p * 6)(*[
            ctypes.cast(ctypes.pointer(x), ctypes.c_void_p)
            for x in [p_in, p_inl, p_out, p_outl, p_w, p_h]
        ])

        bx = (W + TILE - 1) // TILE
        by = (H + TILE - 1) // TILE

        e1 = cuda.cuLaunchKernel(fn, bx, by, 1, TILE, TILE, 1,
                                  0, ctypes.c_void_p(0), params, ctypes.c_void_p(0))
        e2 = cuda.cuCtxSynchronize()
        chk(cuda.cuMemcpyDtoH_v2(out_gpu.ctypes.data, d_out, nb))

        expected = cpu_stencil_5pt(inp, W, H)

        # Check only tile-interior points that each block computes.
        # Block (bx_i, by_i) computes tile interior: x in [1,14], y in [1,14]
        # → global col in [bx_i*16+1, bx_i*16+14], row in [by_i*16+1, by_i*16+14]
        # Also must be global interior: col > 0, col < W-1, row > 0, row < H-1.
        mis = 0
        n_checked = 0
        for byi in range(by):
            for bxi in range(bx):
                for ty in range(1, 15):
                    for tx in range(1, 15):
                        col = bxi * TILE + tx
                        row = byi * TILE + ty
                        if col > 0 and col < W - 1 and row > 0 and row < H - 1:
                            idx = row * W + col
                            n_checked += 1
                            if out_gpu[idx] != expected[idx]:
                                mis += 1

        n_total += 1
        res = "PASS" if (e1 == 0 and e2 == 0 and mis == 0) else "FAIL"
        if res == "PASS":
            ok_total += 1
        print(f"  shape {H:>3}x{W:<3}  pat {pname:<12}  checked {n_checked:>5}  "
              f"mismatches {mis:>5}  -> {res}")

        cuda.cuMemFree_v2(d_in)
        cuda.cuMemFree_v2(d_out)
        cuda.cuCtxDestroy_v2(ctx)

print(f"\nOVERALL: {ok_total}/{n_total}")
