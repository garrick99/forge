# Forge → OpenCUDA → OpenPTXas → GPU — Tiled Matmul (FORGE61-64)

**Date**: 2026-04-17
**Hardware**: RTX 5090 (SM_120, Blackwell)
**Status**: **RESOLVED** — OpenPTXas HEAD `710dd69` (PTXAS-R18 canonical-entry fix). GPU 8/8 PASS on OpenPTXas cubin; matches NVIDIA-ref oracle element-wise.

## Resolution (2026-04-17, supersedes the "blocked" analysis below)

Root cause was in `sass/pipeline.py` BRA.U !UP0 offset encoding: an
unconditional `offset_instrs += 1` was applied to all unconditional
forward BRAs under the assumption that every target block begins with a
skippable `BSYNC.RECONVERGENT` preamble. That assumption holds for blocks
whose first PTX instruction is `bar.sync` (isel emits BSYNC before
BAR.SYNC) but NOT for merge / loop-header blocks whose first PTX
instruction is `setp` (ISETP on SM_120). For those, `+1` skipped the
canonical ISETP entry of `if_merge_4` and `while_cond_20`, causing
incoming fall-through and pre-loop edges to consume a stale `P0` from an
earlier unrelated ISETP. Surviving threads then bypassed the entire
dot-product body on iteration 0 — accumulator `R22` stayed `0`, `STG`
stored `0`.

Fix (OpenPTXas commit `710dd69`, PTXAS-R18): the `+1` is now
conditional on the actual opcode at the target offset — it fires only
when that opcode is `0x941` (BSYNC). Every PTX basic block now maps to
exactly one canonical SASS entry label; BSYNC-preamble behavior for
`bar`-first blocks is byte-identically preserved.

Regression tests covering the semantic class (setp-first merge with
inner-BRA + outer-fallthrough; setp-first while-cond with back-edge +
entry edge; bar-first merge BSYNC-skip guard) live in
`openptxas/tests/test_forge61_canonical_entry.py`.

### Validation matrix (post-fix)

| Target                                  | Result        |
|-----------------------------------------|---------------|
| FORGE61-64 GPU harness (matmul_16)      | **8/8 PASS**  |
| FORGE45-48 sanity (transpose_tile)      | **12/12 PASS** (no regression) |
| OpenPTXas full pytest                   | **868/868 PASS** |
| OpenPTXas cubin vs NVIDIA-ref (matmul)  | STRUCTURAL (GPU-correct; bytes differ) |

---

## Historical analysis (pre-PTXAS-R18)

The remainder of this document captures the original blocked-state
analysis at Forge commit `5f19270`. It is retained for defect-proof
traceability; the operational status is "RESOLVED" as per the
resolution section above.

## TL;DR

Forge expresses a canonical tiled 16×16 matmul microkernel (K fixed
at 16): two shared tiles for A and B, one `__syncthreads()` barrier,
then a 16-step `while` loop computing `acc += As[y,k] * Bs[k,x]`.
All Z3 obligations (9/9) discharge.  OpenCUDA emits clean PTX with
two `.shared .u32` arrays, proper address-space split, a `bar.sync 0`,
and a structured `while_cond / while_body / while_exit` loop.

The same Forge-emitted PTX, when assembled by **NVIDIA `ptxas`**,
runs **correctly on the test matrix** (reference cubin 8608 bytes).
When assembled by **OpenPTXas**, the cubin (6576 bytes) launches with
no CUDA error but the output array `C` is identically zero.

Root cause, per the commit message and backend investigation, is
OpenPTXas control-flow label placement when a `while` loop body
sits after a `bar.sync` that is itself gated by nested `if`s with
early `ret` exits.  The loop's accumulator store never reaches the
`st.global.u32`.  A partial backend fix for `BAR`-kernel u32 param
loading landed as OpenPTXas commit `f9df0ce` (preamble LDC for u32
params, which was a pre-requisite for any cubin to encode at all
for this shape) but the loop-placement bug remains.

## Forge source (9/9 obligations discharged)

```rust
#[kernel]
fn matmul_16(
    a: span<u32>, b: span<u32>, c: span<u32>,
    m: u32, n: u32
)
    requires m > 0u32
    requires n > 0u32
    requires m * 16u32 <= a.len
    requires 16u32 * n <= b.len
    requires m * n <= c.len
    requires threadIdx_x < 16u32
    requires threadIdx_y < 16u32
{
    let as_tile: shared<u32>[256] = 0;
    let bs_tile: shared<u32>[256] = 0;

    let x: u32 = threadIdx_x;
    let y: u32 = threadIdx_y;
    let col: u32 = blockIdx_x * 16u32 + x;
    let row: u32 = blockIdx_y * 16u32 + y;

    let s_idx: u32 = y * 16u32 + x;

    // Phase 1: stage one row of A (per-row thread) and one col of B
    //          into shared memory.
    if row < m {
        let a_idx: u32 = row * 16u32 + x;
        if a_idx < a.len {
            as_tile[s_idx] = a[a_idx];
        };
    };
    if col < n {
        let b_idx: u32 = y * n + col;
        if b_idx < b.len {
            bs_tile[s_idx] = b[b_idx];
        };
    };

    syncthreads();

    // Phase 2: 16-step dot product — As[y,k] * Bs[k,x] reduced into acc.
    if row < m {
        if col < n {
            let mut acc: u32 = 0u32;
            let mut ki:  u32 = 0u32;
            while ki < 16u32
                invariant ki <= 16u32
            {
                let a_s: u32 = y  * 16u32 + ki;
                let b_s: u32 = ki * 16u32 + x;
                let av:  u32 = as_tile[a_s];
                let bv:  u32 = bs_tile[b_s];
                acc = acc + av * bv;
                ki  = ki + 1u32;
            };
            let c_idx: u32 = row * n + col;
            if c_idx < c.len {
                c[c_idx] = acc;
            };
        };
    };
}
```

## Index equations

| symbol  | definition          | bound at use |
|---|---|---|
| `x`       | `threadIdx_x`         | `x < 16`   (precondition) |
| `y`       | `threadIdx_y`         | `y < 16`   (precondition) |
| `col`     | `bx*16 + x`           | `col < n`  guarded in phase 1 + phase 2 |
| `row`     | `by*16 + y`           | `row < m`  guarded in phase 1 + phase 2 |
| `s_idx`   | `y*16 + x`            | `≤ 15*16 + 15 = 255 < 256` (fits smem[256]) |
| `a_idx`   | `row*16 + x`          | `≤ (m-1)*16 + 15 < m*16 ≤ a.len` |
| `b_idx`   | `y*n + col`           | `≤ 15*n + (n-1) < 16*n ≤ b.len` |
| `a_s`     | `y*16 + ki`           | `ki ≤ 15`  → `a_s ≤ 255 < 256` |
| `b_s`     | `ki*16 + x`           | `ki ≤ 15`  → `b_s ≤ 255 < 256` |
| `c_idx`   | `row*n + col`         | explicit `c_idx < c.len` guard |
| loop invariant | `ki ≤ 16`      | discharges both the loop bound and the post-condition |

## Tile diagram (single 16×16 tile, K=16)

```
    A [M x 16]                B [16 x N]                  C [M x N]
      x →  0 1 .. 15            x →  0 1 .. n-1              x →  0 1 ..
  row ↓ +-------------+      k ↓  +-------------+      row ↓ +-----------+
      0 | A row 0     |         0 | B row 0     |          0 | C row 0   |
      1 | A row 1     |         1 | B row 1     |          1 | C row 1   |
      ⋮ |    ⋮        |         ⋮ |    ⋮        |          ⋮ |    ⋮      |
   m-1  | A row m-1   |        15 | B row 15    |        m-1 | C row m-1 |
        +-------------+           +-------------+            +-----------+

Phase 1: each lane (x, y) stages
   As[y, x] = A[row, x]      (row selected by this block's by)
   Bs[y, x] = B[y, col]      (col selected by this block's bx)

Phase 2 (dot product, per lane (x, y)):
   C[row, col] = Σ_{k=0..15} As[y, k] * Bs[k, x]
```

## Address-space mapping (OpenCUDA-emitted PTX)

| Forge | CUDA C | PTX | SASS |
|---|---|---|---|
| `a[a_idx]`, `b[b_idx]`  | `a[a_idx]`, `b[b_idx]`         | `ld.global.u32`  | `LDG.E.32` |
| `shared<u32>[256]` × 2  | `__shared__ uint32_t as_tile[256]` / `bs_tile[256]` | `.shared .u32 as_tile[256]` / `bs_tile[256]` | block SMEM |
| `as_tile[s_idx] = ...`  | `as_tile[s_idx] = ...`         | `st.shared.u32`  | `STS` |
| `syncthreads()`         | `__syncthreads()`              | `bar.sync 0`     | `BAR.SYNC.DEFER_BLOCKING` |
| `as_tile[a_s]` (loop)   | `as_tile[a_s]` (loop)          | `ld.shared.u32`  | `LDS` |
| `av * bv`               | `av * bv`                      | `mul.lo.u32`     | `IMAD` |
| `acc + ...`             | `acc + ...`                    | `add.u32`        | `IADD3` |
| `c[c_idx] = acc`        | `c[c_idx] = acc`               | `st.global.u32`  | `STG.E.32` |

PTX skeleton (see `1114_forge_tiled_matmul.ptx`):
- Two `mov.u64` to initialise the shared bases for `as_tile` / `bs_tile`.
- Phase 1: two guarded `ld.global.u32 → st.shared.u32` sequences.
- `bar.sync 0`.
- Phase 2: `while_cond_20 / while_body_21 / while_exit_22` labels
  around a 16-step `setp.lt.u32 ki, 16; @p bra body; ...; bra cond`
  loop, with a final guarded `st.global.u32 [c_idx], acc`.

## GPU execution

Two cubins were assembled from the **same** Forge-emitted PTX:

| cubin | assembler | size | result on test matrix |
|---|---|---:|---|
| `1114_forge_tiled_matmul_REF.cubin`  | NVIDIA `ptxas` v13.0 | 8608 B | reference runs (used as oracle) |
| `1114_forge_tiled_matmul.cubin`      | OpenPTXas (this repo) | 6576 B | launches clean, **output all zeros** |

Test matrix (12 cases = 4 shapes × 3 patterns), K fixed at 16:

| run | shape (M×K × K×N) | pattern     | NVIDIA-ref result | OpenPTXas result |
|---:|---|---|:-:|:-:|
|  1 | 16×16 × 16×16 | sequential  | PASS | all-zero C |
|  2 | 16×16 × 16×16 | affine      | PASS | all-zero C |
|  3 | 16×16 × 16×16 | lcg-random  | PASS | all-zero C |
|  4 | 32×16 × 16×16 | sequential  | PASS | all-zero C |
|  5 | 32×16 × 16×16 | affine      | PASS | all-zero C |
|  6 | 32×16 × 16×16 | lcg-random  | PASS | all-zero C |
|  7 | 16×16 × 16×32 | sequential  | PASS | all-zero C |
|  8 | 16×16 × 16×32 | affine      | PASS | all-zero C |
|  9 | 16×16 × 16×32 | lcg-random  | PASS | all-zero C |
| 10 | 32×16 × 16×32 | sequential  | PASS | all-zero C |
| 11 | 32×16 × 16×32 | affine      | PASS | all-zero C |
| 12 | 32×16 × 16×32 | lcg-random  | PASS | all-zero C |

Reference results were validated element-by-element against a
pure-Python `cpu_matmul` that computes `C[r,c] = Σ_k A[r,k]*B[k,c]`
in `u32` with wrap-around. Values are clamped to 4-bit input range
(`& 0xF`) so the 16-term accumulator cannot overflow 32 bits.

## OpenPTXas root-cause evidence

Commit message (`5f19270`) records the two observations:

> OpenPTXas cubin produces all-zero output. The while-loop + BAR +
> nested-if composition exceeds current backend capability (control
> flow label placement for loop blocks).
>
> Backend fix included: preamble LDC for BAR-kernel u32 params
> (commit `f9df0ce` in openptxas). Cubin encoding is now valid but
> output is still wrong.

The first landed fix (preamble LDC for `u32` params in `BAR`-using
kernels) was a pre-requisite for the cubin to encode at all — before
it, the param loads for `m` and `n` were reordered past the barrier
and the kernel failed verification.  With that fix, the cubin now
encodes, loads, and launches cleanly (no CUDA error).  What remains
is the loop-body placement: the `while_body_21` block, which contains
the entire accumulator update chain (two `LDS`, one `IMAD`, two
`IADD3`), appears to be skipped or fall through without its
`st.global.u32` being reached, so `C` is never written.

This is consistent with the structure of the PTX: `while_cond_20`
appears after the `bar.sync 0` inside `if_merge_10`, and `while_body_21`
is emitted **after** `if_merge_16` (which only contains the `ret`),
so the lexical order of the blocks is `cond → if_merge_16 → body →
exit`.  Any backend that prefers to fall through lexically-adjacent
blocks, or that resolves branch targets to the wrong basic-block
boundary, will silently fall off the end of `if_merge_16`'s `ret`
and never reach `body`, which is exactly the symptom observed
(accumulator never updated, store never reached, all-zero output).

This is the **first** slice in the FORGE family to exercise
`while + bar.sync + nested-if + early-ret` all together, so the bug
has been latent since Forge's `while` lowering and the `syncthreads()`
intrinsic were added.

## What this slice excludes

- **K > 16**: K is hardcoded at 16, so there is no outer tile loop over K.
- **Non-square tiles**: `TILE_M = TILE_N = 16` only.
- **Vectorized loads**: scalar `ld.global.u32` only, no `ld.global.v2/v4`.
- **fp16 / bf16 / tensor cores**: `u32` integer matmul only — this slice
  targets the control-flow and shared-memory lowering, not the TC pipe.
- **Bank-conflict padding**: tiles are declared as flat `[256]`, not
  `[16][17]`; fine for `u32` on SM_120 with 32 banks and row-major
  access patterns.
- **Register tiling / multiple outputs per thread**: each thread
  computes exactly one element of `C`.
- **Bounds-unchecked writes**: even the final `c[c_idx] = acc` is
  inside an explicit `c_idx < c.len` guard.

## Validation summary

| harness | result |
|---|:-:|
| Forge proof | **9/9** obligations discharged |
| OpenCUDA emit | clean PTX (2× `.shared .u32`, `bar.sync 0`, structured `while`, LDG/STG/LDS/STS chain) |
| NVIDIA ptxas → cubin | 8608 bytes, reference oracle |
| OpenPTXas → cubin | 6576 bytes, launches cleanly, **0/12 correct (all-zero output)** |
| Backend changes | **1** — openptxas `f9df0ce` (preamble LDC for BAR-kernel u32 params); necessary but insufficient |

## Capability envelope after FORGE61-64

| family | example slice | status |
|---|---|:-:|
| arithmetic + clamp | FORGE01 | ✓ |
| predicates / branching | FORGE05 | ✓ |
| multi-array memory | FORGE09 | ✓ |
| chained map composition | FORGE13 | ✓ |
| pairwise reduction step | FORGE17 | ✓ |
| shared-mem stage + barrier | FORGE21 | ✓ |
| bounded per-thread loop | FORGE25 | ✓ |
| atomic global accumulation | FORGE29 | ✓ |
| warp shuffle | FORGE33 | ✓ |
| multi-block reduction | FORGE37 | ✓ |
| 2D indexing + coalesced access | FORGE41 | ✓ |
| tiled transpose | FORGE45 | ⚠ Forge OK, OpenPTXas BLOCKED (dual-CTAID) |
| 5-point stencil (global) | FORGE49 | ✓ |
| tiled stencil (shared mem) | FORGE53 | ✓ |
| 3×3 weighted convolution | FORGE57 | ✓ |
| **tiled matmul (K=16)**  | **FORGE61** | **⚠ Forge OK, OpenPTXas BLOCKED (while+BAR+nested-if)** |

The Forge-side capability is fully present (proof + correct PTX +
NVIDIA-ref runs the oracle correctly).  The blocker is downstream
and confined to OpenPTXas's basic-block ordering / branch-target
resolution around the `while`-after-`bar.sync` pattern.

## Reproduction

```bash
cd /mnt/c/users/kraken/forge
opam exec -- ./_build/default/bin/main.exe cuda demos/1114_forge_tiled_matmul.fg

cd /mnt/c/users/kraken/opencuda
python3 -m opencuda /mnt/c/users/kraken/forge/demos/1114_forge_tiled_matmul.cu --emit-ptx

# OpenPTXas cubin (under test — launches, writes all-zero C)
cd /mnt/c/users/kraken/openptxas
python3 -c "from sass.pipeline import compile_ptx_source
ptx = open('/mnt/c/users/kraken/forge/demos/1114_forge_tiled_matmul.ptx').read()
cubin = next(iter(compile_ptx_source(ptx).values()))
open('/mnt/c/users/kraken/forge/demos/1114_forge_tiled_matmul.cubin','wb').write(cubin)"

# NVIDIA-ptxas cubin (oracle — correct on all 12 cases)
ptxas -arch=sm_120 demos/1114_forge_tiled_matmul.ptx \
      -o demos/1114_forge_tiled_matmul_REF.cubin

# Run
py demos/1114_forge_tiled_matmul_run.py
```
