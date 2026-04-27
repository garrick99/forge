"""Forge-native embedding_gather (block-per-position, lane-per-dim).
Kernel: embedding_gather(ids, embed, out, seq_len, vocab_size, d)
        out[i, e] = embed[ids[i], e]
"""
import ctypes, os
import numpy as np

CUBIN = os.path.abspath(os.path.join(os.path.dirname(__file__), '1141_forge_embedding_gather.cubin'))
cuda = ctypes.CDLL("nvcuda.dll")
cuda.cuMemcpyHtoD_v2.argtypes = [ctypes.c_uint64, ctypes.c_void_p, ctypes.c_size_t]
cuda.cuMemcpyDtoH_v2.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.c_size_t]
cuda.cuMemAlloc_v2.argtypes = [ctypes.POINTER(ctypes.c_uint64), ctypes.c_size_t]
def ck(e, msg=""):
    if e != 0: raise RuntimeError(f"{msg}: cuda err {e}")
ck(cuda.cuInit(0)); DEV = ctypes.c_int(); ck(cuda.cuDeviceGet(ctypes.byref(DEV), 0))


cases = [(8, 100, 32), (16, 256, 64), (32, 512, 128), (64, 1024, 256), (128, 4096, 512)]
print("FORGE: embedding_gather - proof-verified .fg -> CUDA C -> PTX -> SASS")
print(f"{'seq':>5} {'vocab':>6} {'d':>5}  {'correct':>8}  {'mismatches':>11}")
print("-" * 52)
ok, total = 0, 0
for (seq_len, vocab, d) in cases:
    ctx = ctypes.c_void_p(); ck(cuda.cuCtxCreate_v2(ctypes.byref(ctx), 0, DEV))
    mod = ctypes.c_void_p(); ck(cuda.cuModuleLoad(ctypes.byref(mod), CUBIN.encode()))
    fn = ctypes.c_void_p(); ck(cuda.cuModuleGetFunction(ctypes.byref(fn), mod, b"embedding_gather"))
    np.random.seed(seq_len * 17 + vocab + d)
    ids = np.random.randint(0, vocab, size=seq_len).astype(np.uint32)
    embed = np.random.randn(vocab, d).astype(np.float32)
    out_gpu = np.zeros((seq_len, d), dtype=np.float32)

    n_ids = seq_len * 4; n_emb = vocab * d * 4; n_out = seq_len * d * 4
    d_ids = ctypes.c_uint64(); d_emb = ctypes.c_uint64(); d_out = ctypes.c_uint64()
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_ids), n_ids))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_emb), n_emb))
    ck(cuda.cuMemAlloc_v2(ctypes.byref(d_out), n_out))
    ck(cuda.cuMemcpyHtoD_v2(d_ids, ids.ctypes.data_as(ctypes.c_void_p), n_ids))
    ck(cuda.cuMemcpyHtoD_v2(d_emb, embed.ctypes.data_as(ctypes.c_void_p), n_emb))
    ck(cuda.cuMemcpyHtoD_v2(d_out, out_gpu.ctypes.data_as(ctypes.c_void_p), n_out))
    p = [ctypes.c_uint64(d_ids.value), ctypes.c_uint64(seq_len),
         ctypes.c_uint64(d_emb.value), ctypes.c_uint64(vocab * d),
         ctypes.c_uint64(d_out.value), ctypes.c_uint64(seq_len * d),
         ctypes.c_uint64(seq_len), ctypes.c_uint64(vocab), ctypes.c_uint64(d)]
    params = (ctypes.c_void_p * 9)(*[ctypes.cast(ctypes.pointer(pi), ctypes.c_void_p) for pi in p])
    ck(cuda.cuLaunchKernel(fn, seq_len, 1, 1, d, 1, 1, 0, ctypes.c_void_p(0), params, ctypes.c_void_p(0)))
    ck(cuda.cuCtxSynchronize())
    ck(cuda.cuMemcpyDtoH_v2(out_gpu.ctypes.data, d_out, n_out))

    out_ref = embed[ids]
    mismatches = int((out_gpu != out_ref).sum())
    correct = mismatches == 0
    total += 1; ok += int(correct)
    print(f"{seq_len:>5} {vocab:>6} {d:>5}  {'PASS' if correct else 'FAIL':>8}  {mismatches:>11}")

    cuda.cuMemFree_v2(d_ids); cuda.cuMemFree_v2(d_emb); cuda.cuMemFree_v2(d_out)
    cuda.cuModuleUnload(mod); cuda.cuCtxDestroy_v2(ctx)
print("-" * 52); print(f"OVERALL: {ok}/{total}")
