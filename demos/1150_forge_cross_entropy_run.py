"""Forge-native cross_entropy (single-warp, n_classes<=32).
Kernel: cross_entropy(logits, targets, loss, n_classes)
        loss[row] = -log(softmax(logits[row])[targets[row]])
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1150_forge_cross_entropy.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


def cross_entropy_cpu(logits, targets):
    m = logits.max(axis=-1, keepdims=True)
    log_z = m.squeeze(-1) + np.log(np.exp(logits - m).sum(axis=-1))
    picked = np.take_along_axis(logits, targets[:, None].astype(np.intp), axis=1).squeeze(-1)
    return log_z - picked


shapes = [(4, 8), (8, 16), (16, 32), (64, 32), (256, 16)]
print("FORGE: cross_entropy - proof-verified .fg -> CUDA C -> PTX -> SASS")
print(f"{'rows':>5} {'cols':>5}  {'correct':>8}  {'max_err':>10}  {'mean_err':>10}")
print("-" * 52)
ok, total = 0, 0
for (R, C) in shapes:
    ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
    mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
    fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"cross_entropy"))
    np.random.seed(R * 31 + C)
    logits = np.random.randn(R, C).astype(np.float32)
    targets = np.random.randint(0, C, size=R).astype(np.uint32)
    loss_gpu = np.zeros(R, dtype=np.float32)

    nbytes_l = R * C * 4; nbytes_t = R * 4; nbytes_o = R * 4
    d_l = ctypes.c_uint64(); d_t = ctypes.c_uint64(); d_o = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_l), nbytes_l))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_t), nbytes_t))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_o), nbytes_o))
    ck(cuda.cuMemcpyHtoD_v2(d_l, logits.ctypes.data_as(ctypes.c_void_p), nbytes_l))
    ck(cuda.cuMemcpyHtoD_v2(d_t, targets.ctypes.data_as(ctypes.c_void_p), nbytes_t))
    ck(cuda.cuMemcpyHtoD_v2(d_o, loss_gpu.ctypes.data_as(ctypes.c_void_p), nbytes_o))
    p = [ctypes.c_uint64(d_l.value), ctypes.c_uint64(R*C),
         ctypes.c_uint64(d_t.value), ctypes.c_uint64(R),
         ctypes.c_uint64(d_o.value), ctypes.c_uint64(R), ctypes.c_uint64(C)]
    params = (ctypes.c_void_p * 7)(*[ctypes.cast(ctypes.pointer(pi), ctypes.c_void_p) for pi in p])
    ck(cuda.cuLaunchKernel(fn, R, 1, 1, 32, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(loss_gpu.ctypes.data, d_o, nbytes_o))

    loss_ref = cross_entropy_cpu(logits, targets).astype(np.float32)
    err = np.abs(loss_gpu - loss_ref); max_err, mean_err = float(err.max()), float(err.mean())
    correct = max_err < 1e-4; total += 1; ok += int(correct)
    print(f"{R:>5} {C:>5}  {'PASS' if correct else 'FAIL':>8}  {max_err:>10.2e}  {mean_err:>10.2e}")

    cuda.cuMemFree_v2(d_l); cuda.cuMemFree_v2(d_t); cuda.cuMemFree_v2(d_o)
    cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 52); print(f"OVERALL: {ok}/{total}")
