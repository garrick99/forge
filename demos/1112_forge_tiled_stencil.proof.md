# Forge → OpenCUDA → OpenPTXas → GPU — Shared-Memory Tiled 5-Point Stencil (FORGE53-56)

**Date**: 2026-04-16
**Hardware**: RTX 5090 (SM_120, Blackwell)
**Status**: **PASS** (9/9 — 3 shapes × 3 patterns)

## What this proves

Forge can compose shared-memory tiling, barrier synchronization,
2D thread/block indexing, AND neighborhood computation (stencil)
in one kernel — the canonical building block for image processing,
PDE solvers, and convolution.  Each block cooperatively loads a
16×16 tile, then interior threads read 5 neighbors from shared
memory and write the sum to global output.

## Forge source (8/8 obligations discharged)

```rust
#[kernel]
fn tiled_stencil_5pt(inp: span<u32>, out: span<u32>,
                     width: u32, height: u32)
{
    let smem: shared<u32>[256] = 0;
    let s_idx: u32 = threadIdx_y * 16u32 + threadIdx_x;
    let col: u32 = blockIdx_x * 16u32 + threadIdx_x;
    let row: u32 = blockIdx_y * 16u32 + threadIdx_y;

    // Phase 1: load tile from global
    if col < width && row < height {
        smem[s_idx] = inp[row * width + col];
    };
    syncthreads();

    // Phase 2: interior threads compute stencil from shared reads
    if x ∈ [1,14] && y ∈ [1,14] && col ∈ [1,W-2] && row ∈ [1,H-2] {
        out[row*width+col] = smem[s_idx] + smem[s_idx-16]
                           + smem[s_idx+16] + smem[s_idx-1] + smem[s_idx+1];
    };
}
```

8 obligations: 1 global load, 1 shared store, 5 shared reads (center,
north, south, west, east), 1 global store — all discharged by Z3.

## Tile diagram

```
shared tile (16×16):
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |L|L|L|L|L|L|L|L|L|L|L|L|L|L|L|L|  y=0  (load-only)
  |L|C|C|C|C|C|C|C|C|C|C|C|C|C|C|L|  y=1  (C=compute)
  |L|C|C|C|C|C|C|C|C|C|C|C|C|C|C|L|  y=2
  ⋮                                ⋮
  |L|C|C|C|C|C|C|C|C|C|C|C|C|C|C|L|  y=14
  |L|L|L|L|L|L|L|L|L|L|L|L|L|L|L|L|  y=15 (load-only)
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   x=0                          x=15

Interior threads: (x,y) ∈ [1,14]² = 14×14 = 196 per block.
Tile-edge threads (L): load data for neighbors but don't write output.
```

## Center/neighbor mapping in shared memory

```
for thread (x=5, y=3):
  s_idx   = 3*16 + 5 = 53
  center  = smem[53]          = in[row, col]
  north   = smem[53-16] = smem[37]  = in[row-1, col]
  south   = smem[53+16] = smem[69]  = in[row+1, col]
  west    = smem[53-1]  = smem[52]  = in[row, col-1]
  east    = smem[53+1]  = smem[54]  = in[row, col+1]
```

## Memory-space mapping (OpenCUDA PTX)

| Forge | CUDA | PTX | SASS |
|---|---|---|---|
| `inp[g_idx]`           | `inp[g_idx]`            | `ld.global.u32`  | `LDG.E.32` |
| `shared<u32>[256]`     | `__shared__ uint32_t smem[256]` | `.shared .u32 smem[256]` | block SMEM |
| `smem[s_idx] = ...`    | `smem[s_idx] = ...`     | `st.shared.u32`  | `STS` |
| `syncthreads()`        | `__syncthreads()`       | `bar.sync 0`     | `BAR.SYNC` |
| `... = smem[s_idx±K]`  | `... = smem[s_idx±K]`   | `ld.shared.u32`  | `LDS` |
| `out[o_idx] = val`     | `out[o_idx] = val`      | `st.global.u32`  | `STG.E.32` |

## GPU stress matrix

| run | shape | pattern | checked pts | mismatches | result |
|---:|---|---|---:|---:|:-:|
| 1 | 16×16 | sequential | 196 | 0 | **PASS** |
| 2 | 16×16 | affine | 196 | 0 | **PASS** |
| 3 | 16×16 | lcg-random | 196 | 0 | **PASS** |
| 4 | 32×32 | sequential | 784 | 0 | **PASS** |
| 5 | 32×32 | affine | 784 | 0 | **PASS** |
| 6 | 32×32 | lcg-random | 784 | 0 | **PASS** |
| 7 | 64×64 | sequential | 3136 | 0 | **PASS** |
| 8 | 64×64 | affine | 3136 | 0 | **PASS** |
| 9 | 64×64 | lcg-random | 3136 | 0 | **PASS** |

Checked points = tile-interior AND global-interior intersection.
For 32×32 with 2×2 blocks: 4 blocks × 196 interior = 784.

## Backend fix discovered during this slice

OpenPTXas scheduler hoisted multi-CTAID S2R to the preamble, where
the allocator let intermediate computations reuse the same GPR (WAW
hazard). Fix: allocate S2R destinations from scratch GPR pool above
the allocator's range (commit `52f7c19`). Zero regressions.

## What this slice excludes

- **halo loading**: tile-border cells don't have neighbor data from
  adjacent tiles; their positions are skipped. A full-coverage version
  would load an 18×18 region per 16×16 output tile.
- **bank-conflict padding**: smem[256] = 16×16, no +1 padding.
- **diagonal neighbors**: 5-point (von Neumann), not 9-point (Moore).
- **normalization/weights**: raw sum, no division or coefficients.
- **looped tiles**: single tile per block, no tiling over K dimension.

## Validation summary

| harness | result |
|---|:-:|
| Forge proof | 8/8 obligations discharged |
| OpenCUDA emit | clean PTX (.shared, bar.sync, 1 LDG, 5 LDS, 1 STS, 1 STG) |
| OpenPTXas → cubin | 6680 bytes |
| GPU stress (9 runs) | **9/9** correct |
| OpenPTXas pytest | **865/865** clean |
| OpenPTXas GPU harness | 127/10/7 (unchanged) |
| OpenPTXas frontier | 66/78 (unchanged) |
| Backend changes | 1 fix: scratch GPR for multi-CTAID S2R |

## Capability envelope after FORGE53-56

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
| tiled transpose | FORGE45 | ✓ |
| 5-point 2D stencil (global) | FORGE49 | ✓ |
| **tiled stencil (shared mem)** | **FORGE53** | **✓** |
