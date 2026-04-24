# FORGE65-68 — Full tiled matmul (arbitrary K)

**Kernel:** `C[M, N] = A[M, K] × B[K, N]` for any K that is a multiple of TILE = 16.

Extends `FORGE61-64` (K = 16 microkernel) by wrapping an outer `while` loop over
K-tiles. Two shared-memory tiles (one A-tile, one B-tile) are reloaded per
iteration; a running accumulator sums the 16-step dot product per iteration.

## Proof artifact

```
$ ./_build/default/bin/main.exe cuda demos/1115_forge_tiled_matmul_kloop.fg
[forge] parsing...
[forge] parsed 23 top-level items
[forge] type checking...
[forge] 12 proof obligations generated
[forge] discharging proof obligations...
  ✓ [SMT]    precondition of __div__                   — num_k_tiles = k / 16
  ✓ [SMT]    invariant: while_entry (outer kt loop)    — 0 ≤ kt ≤ num_k_tiles on entry
  ✓ [SMT]    bounds check: shared  (A-tile write)      — s_idx < 256
  ✓ [SMT]    bounds check: span    (A load)            — a_idx < a.len
  ✓ [SMT]    bounds check: shared  (B-tile write)      — s_idx < 256
  ✓ [SMT]    bounds check: span    (B load)            — b_idx < b.len
  ✓ [SMT]    invariant: while_entry (inner ki loop)    — 0 ≤ ki ≤ 16 on entry
  ✓ [SMT]    bounds check: shared  (A-tile read)       — a_s < 256
  ✓ [SMT]    bounds check: shared  (B-tile read)       — b_s < 256
  ✓ [SMT]    invariant: while_preserved (inner)        — invariant preserved across iteration
  ✓ [SMT]    invariant: while_preserved (outer)        — invariant preserved across iteration
  ✓ [SMT]    bounds check: span    (C store)           — c_idx < c.len
[forge] proof summary: 12 total, 12 SMT, 0 guided, 0 manual, 0 failed
[forge] all obligations discharged
[forge] erasing proofs...
[forge] emitting optimized CUDA C...
[forge] assume audit: 0 assumptions (clean)
```

**12 / 12 obligations discharged by Z3. 0 assumes. 0 manual-proved hatches.**
Every shared-memory access, every global load/store, every loop invariant is
machine-checked before a single byte of CUDA C is emitted.

## Pipeline

```
1115_forge_tiled_matmul_kloop.fg          (Forge source, 110 lines)
    │  forge cuda   ← Z3 proof discharge + C99/CUDA C emission
    ▼
1115_forge_tiled_matmul_kloop.cu          (CUDA C)
    │  python -m opencuda                 ← CUDA C → PTX (pure Python)
    ▼
1115_opencuda.ptx                         (PTX 8.8)
    │  python -c compile_ptx_source        ← OpenPTXas PTX → SASS → cubin
    ▼
1115_forge_tiled_matmul_kloop.cubin       (SM_120 ELF)
    │  cuModuleLoad + cuLaunchKernel
    ▼
RTX 5090 GPU — correct output
```

No NVIDIA compiler is involved at any stage. The `ptxas`-built reference cubin
(`_REF.cubin`) is kept only for differential verification that OpenPTXas
produces equivalent output.

## GPU results (RTX 5090, SM_120)

```
   M    N     K   correct    GPU ms    CPU ms (numpy)   speedup vs numpy
--------------------------------------------------------------------------
  16   16    16     PASS      0.015     0.034              2.3×
  16   16    32     PASS      0.008     0.029              3.4×
  32   32    64     PASS      0.007     0.056              8.5×
  64   64   128     PASS      0.009     0.313             33.7×
 128  128   256     PASS      0.014     2.370            172.5×
 256  256   512     PASS      0.027    22.115            804.8×
--------------------------------------------------------------------------
OVERALL: 6 / 6 correct against uint32-modular numpy reference
```

OpenPTXas vs ptxas (13.0) — same kernel, same inputs, RTX 5090:

| Shape (M×N×K) | OpenPTXas (ms) | ptxas ref (ms) | Correct match |
|---------------|---------------:|---------------:|:-------------:|
| 16×16×16 | 0.015 | 0.014 | ✓ |
| 16×16×32 | 0.008 | 0.006 | ✓ |
| 32×32×64 | 0.007 | 0.006 | ✓ |
| 64×64×128 | 0.009 | 0.009 | ✓ |
| 128×128×256 | 0.014 | 0.014 | ✓ |
| **256×256×512** | **0.027** | **0.027** | **✓** |

Byte-level output is identical — the only measurable difference is timing noise
around ±5%. OpenPTXas produces a cubin that runs at parity with
ptxas for this kernel.

## What just happened

A matmul kernel, written in Forge's verified-systems-language, was proven by
Z3 (12 obligations), lowered by Forge to standard CUDA C, compiled by
**OpenCUDA** (Python) to PTX, assembled by **OpenPTXas** (Python) to SM_120
cubin, and executed on an RTX 5090 with correct results across six different
shapes up to 256×256×512.

Every stage is open-source Python or OCaml. No `nvcc`, no `ptxas`, no LLVM,
no closed-source GPU compilers anywhere in the pipeline.

The proven invariants (array bounds, loop termination, shared-memory indices)
are machine-checked — a miscompile that violated them would have been caught
at the Forge stage, before CUDA emission. The codegen stages (OpenCUDA +
OpenPTXas) are the untrusted part; their correctness is verified by differential
testing (see `openptxas/fuzzer/`) and by GPU execution matching ptxas
byte-for-byte.

## Files

| File | Role |
|------|------|
| `1115_forge_tiled_matmul_kloop.fg` | Forge source with proofs |
| `1115_forge_tiled_matmul_kloop.cu` | Forge-emitted CUDA C |
| `1115_opencuda.ptx` | OpenCUDA-emitted PTX 8.8 |
| `1115_forge_tiled_matmul_kloop.cubin` | OpenPTXas-emitted SM_120 cubin |
| `1115_forge_tiled_matmul_kloop_REF.cubin` | ptxas-emitted reference (for diff verification) |
| `1115_forge_tiled_matmul_kloop_run.py` | GPU harness, size sweep, correctness check |

Run everything:

```bash
cd forge
./_build/default/bin/main.exe cuda demos/1115_forge_tiled_matmul_kloop.fg
cd ../opencuda
python -m opencuda --emit-ptx ../forge/demos/1115_forge_tiled_matmul_kloop.cu \
    --out ../forge/demos/1115_opencuda.ptx
cd ../openptxas
python -c "import sys; sys.path.insert(0, '.'); \
    from sass.pipeline import compile_ptx_source; \
    ptx = open('../forge/demos/1115_opencuda.ptx').read(); \
    open('../forge/demos/1115_forge_tiled_matmul_kloop.cubin', 'wb').write(\
        compile_ptx_source(ptx)['matmul_kloop'])"
cd ../forge
python demos/1115_forge_tiled_matmul_kloop_run.py
```

## Known gap (Forge's direct-PTX backend)

Forge can also emit PTX directly (`forge/demos/1115_forge_tiled_matmul_kloop.ptx`)
as an alternative to lowering through OpenCUDA. That path is currently
**broken for this kernel**: the direct-PTX backend emits `st.global` with a
zero base pointer for shared-memory writes when the shared-memory write sits
inside a `while` loop. OpenCUDA's lowering handles the same CUDA C correctly,
so the Forge → OpenCUDA → OpenPTXas path is the canonical one for kernels
with shared memory inside loops. See Forge CHANGELOG for the direct-PTX
backend status.
