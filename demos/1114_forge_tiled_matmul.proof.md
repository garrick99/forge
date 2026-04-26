# FORGE61-64 — Tiled matmul microkernel (K = 16 fixed)

**Kernel:** `C[M, N] = A[M, 16] × B[16, N]` for any M, N. K is hardcoded to 16
and the kernel runs as a single shared-memory pass: each block computes one
16×16 tile of C, with a 2D blockDim (16, 16) and a 2D grid covering M and N.

This is the foundation slice that `FORGE65-68` extends with an outer K-tile
loop for arbitrary K = 16k.

## Proof artifact

```
$ ./_build/default/bin/main.exe cuda demos/1114_forge_tiled_matmul.fg
[forge] demos/1114_forge_tiled_matmul.fg (CUDA target)
[forge] parsing...
[forge] parsed 27 top-level items
[forge] type checking...
[forge] 9 proof obligations generated
[forge] discharging proof obligations...
  ✓ [SMT]    demos/1114_forge_tiled_matmul.fg:42 bounds check: shared
  ✓ [SMT]    demos/1114_forge_tiled_matmul.fg:42 bounds check: span
  ✓ [SMT]    demos/1114_forge_tiled_matmul.fg:48 bounds check: shared
  ✓ [SMT]    demos/1114_forge_tiled_matmul.fg:48 bounds check: span
  ✓ [SMT]    demos/1114_forge_tiled_matmul.fg:59 invariant: while_entry
  ✓ [SMT]    demos/1114_forge_tiled_matmul.fg:64 bounds check: shared
  ✓ [SMT]    demos/1114_forge_tiled_matmul.fg:65 bounds check: shared
  ✓ [SMT]    demos/1114_forge_tiled_matmul.fg:59 invariant: while_preserved
  ✓ [SMT]    demos/1114_forge_tiled_matmul.fg:71 bounds check: span
[forge] proof summary: 9 total, 9 SMT, 0 guided, 0 manual, 0 failed
[forge] all obligations discharged
[forge] erasing proofs...
[forge] emitting optimized CUDA C...
[forge] assume audit: 0 assumptions (clean)
```

**9 / 9 obligations discharged by Z3. 0 assumes. 0 manual-proved hatches.**

What gets proven before a byte of CUDA C is emitted:

| Line | Obligation | What it covers |
|------|-----------|----------------|
| 42 | bounds check: shared | A-tile shared-memory write `as_tile[s_idx]` — `s_idx < 256` |
| 42 | bounds check: span   | A global load `a[a_idx]` — `a_idx < a.len` |
| 48 | bounds check: shared | B-tile shared-memory write `bs_tile[s_idx]` — `s_idx < 256` |
| 48 | bounds check: span   | B global load `b[b_idx]` — `b_idx < b.len` |
| 59 | invariant: while_entry | inner ki loop entry — `0 ≤ ki ≤ 16` |
| 64 | bounds check: shared | A-tile shared-memory read `as_tile[a_s]` — `a_s < 256` |
| 65 | bounds check: shared | B-tile shared-memory read `bs_tile[b_s]` — `b_s < 256` |
| 59 | invariant: while_preserved | ki invariant preserved across iteration |
| 71 | bounds check: span   | C global store `c[c_idx]` — `c_idx < c.len` |

## Pipeline

```
1114_forge_tiled_matmul.fg          (Forge source, 77 lines)
    │  forge cuda   ← Z3 proof discharge + C99/CUDA C emission
    ▼
1114_forge_tiled_matmul.cu          (CUDA C)
    │  python -m opencuda           ← CUDA C → PTX (pure Python)
    ▼
1114_forge_tiled_matmul.ptx         (PTX 8.8)
    │  openptxas compile_ptx_source  ← PTX → SASS → cubin
    ▼
1114_forge_tiled_matmul.cubin       (SM_120 ELF)
    │  cuModuleLoad + cuLaunchKernel
    ▼
RTX 5090 GPU — correct output
```

No NVIDIA compiler is involved at any stage. The `ptxas`-built reference cubin
(`_REF.cubin`) is kept only for differential verification.

## GPU results (RTX 5090, SM_120)

```
   shape           pattern        mismatches    result
------------------------------------------------------
  16×16 × 16×16    sequential          0         PASS
  16×16 × 16×16    affine              0         PASS
  16×16 × 16×16    lcg-random          0         PASS
  32×16 × 16×16    sequential          0         PASS
  32×16 × 16×16    affine              0         PASS
  32×16 × 16×16    lcg-random          0         PASS
  16×16 × 16×32    sequential          0         PASS
  16×16 × 16×32    affine              0         PASS
  16×16 × 16×32    lcg-random          0         PASS
  32×16 × 16×32    sequential          0         PASS
  32×16 × 16×32    affine              0         PASS
  32×16 × 16×32    lcg-random          0         PASS
------------------------------------------------------
OVERALL: 12 / 12 correct against uint32-modular numpy reference
```

Four (M, N) shapes × three input patterns. The patterns stress different
parts of the kernel: `sequential` exposes index-monotonic behavior,
`affine` puts predictable coefficients across rows and columns, and
`lcg-random` runs scrambled (but reproducible) values through every
multiply-accumulate slot. All twelve cases are byte-exact against the
CPU reference.

## What just happened

A tiled matmul microkernel, written in Forge's verified-systems language, was
proven by Z3 (9 obligations), lowered by Forge to standard CUDA C, compiled
by **OpenCUDA** (Python) to PTX, assembled by **OpenPTXas** (Python) to a
SM_120 cubin, and executed on an RTX 5090 with correct output across every
shape × pattern combination tested.

Every stage is open-source Python or OCaml. No `nvcc`, no `ptxas`, no LLVM,
no closed-source GPU compilers anywhere in the pipeline.

The proven invariants (loop entry/preservation, every shared-memory index,
every global load and store) are machine-checked — a miscompile that
violated them would have been caught at the Forge stage, before CUDA
emission. The codegen stages (OpenCUDA + OpenPTXas) are the untrusted
part; their correctness is verified by differential testing
(`openptxas/fuzzer/`) and by GPU execution matching `ptxas` byte-for-byte.

## Closed OpenPTXas blocker

The original FORGE61-64 slice (`5f19270`, 2026-04-17) compiled and proved
cleanly but produced an all-zero output cubin from OpenPTXas. The
`while + bar.sync + nested-if` composition exceeded the backend's control-
flow capability at the time. That blocker was closed by `PTXAS-R18`
(commit `710dd69` in OpenPTXas, the canonical-entry fix for
`BRA.U !UP0` offset bumps) plus follow-on work (multi-ret fix, sub.f32
operand inversion, UR4 clobber). Re-run on 2026-04-23 against
OpenPTXas HEAD `75a4a054f5` produced 12/12 GPU PASS — recorded in
`e8f7e29`. This proof artifact reflects that re-verification.

## Files

| File | Role |
|------|------|
| `1114_forge_tiled_matmul.fg` | Forge source with proofs |
| `1114_forge_tiled_matmul.cu` | Forge-emitted CUDA C |
| `1114_forge_tiled_matmul.ptx` | Forge-emitted PTX (direct backend) |
| `1114_forge_tiled_matmul.cubin` | OpenPTXas-emitted SM_120 cubin |
| `1114_forge_tiled_matmul_REF.cubin` | ptxas-emitted reference (for diff verification) |
| `1114_forge_tiled_matmul_run.py` | GPU harness — 4 shapes × 3 patterns, correctness check |

Run everything:

```bash
cd forge
./_build/default/bin/main.exe cuda demos/1114_forge_tiled_matmul.fg
cd ../opencuda
python -m opencuda --emit-ptx ../forge/demos/1114_forge_tiled_matmul.cu \
    --out ../forge/demos/1114_forge_tiled_matmul.ptx
cd ../openptxas
python -c "import sys; sys.path.insert(0, '.'); \
    from sass.pipeline import compile_ptx_source; \
    ptx = open('../forge/demos/1114_forge_tiled_matmul.ptx').read(); \
    open('../forge/demos/1114_forge_tiled_matmul.cubin', 'wb').write(\
        compile_ptx_source(ptx)['matmul_16'])"
cd ../forge
python demos/1114_forge_tiled_matmul_run.py
```
