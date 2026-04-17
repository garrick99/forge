# Forge → OpenCUDA → OpenPTXas → GPU — 5-Point 2D Stencil (FORGE49-52)

**Date**: 2026-04-16
**Hardware**: RTX 5090 (SM_120, Blackwell)
**Status**: **PASS** (9/9 — 3 shapes × 3 patterns)

## What this proves

Forge can express a 2D stencil kernel that reads 5 neighbors per
output element (center + north + south + west + east), with correct
boundary handling and 2D thread/block indexing.  All 6 Z3 obligations
discharge.  The kernel runs correctly on up to 64×64 grids (16 blocks).

## Forge source (6/6 obligations discharged)

```rust
#[kernel]
fn stencil_5pt(inp: span<u32>, out: span<u32>,
               width: u32, height: u32)
    requires width > 2u32
    requires height > 2u32
    requires width * height <= inp.len
    requires width * height <= out.len
    requires threadIdx_x < 16u32
    requires threadIdx_y < 16u32
{
    let col: u32 = blockIdx_x * 16u32 + threadIdx_x;
    let row: u32 = blockIdx_y * 16u32 + threadIdx_y;

    if col > 0u32 {
        if row > 0u32 {
            if col + 1u32 < width {
                if row + 1u32 < height {
                    let idx:   u32 = row * width + col;
                    let idx_n: u32 = idx - width;
                    let idx_s: u32 = idx + width;
                    let idx_w: u32 = idx - 1u32;
                    let idx_e: u32 = idx + 1u32;
                    if idx_s < inp.len {
                        let val: u32 = inp[idx] + inp[idx_n] + inp[idx_s]
                                     + inp[idx_w] + inp[idx_e];
                        if idx < out.len { out[idx] = val; };
                    };
                };
            };
        };
    };
}
```

## Stencil mapping diagram

```
                    in[r-1, c]
                        |
       in[r, c-1] — in[r, c] — in[r, c+1]
                        |
                    in[r+1, c]

  out[r, c] = center + north + south + west + east
```

Index equations (row-major, stride = width):
- center: `idx = row * width + col`
- north:  `idx - width`
- south:  `idx + width`
- west:   `idx - 1`
- east:   `idx + 1`

## Example element movement (sequential input, 16×16)

```
position (2, 3):
  center = in[35]  = 35
  north  = in[19]  = 19
  south  = in[51]  = 51
  west   = in[34]  = 34
  east   = in[36]  = 36
  sum    = 35 + 19 + 51 + 34 + 36 = 175  ✓
```

## GPU stress matrix

| run | shape (HxW) | pattern | interior pts | mismatches | result |
|---:|---|---|---:|---:|:-:|
| 1 | 16×16 | sequential | 196 | 0 | **PASS** |
| 2 | 16×16 | affine | 196 | 0 | **PASS** |
| 3 | 16×16 | lcg-random | 196 | 0 | **PASS** |
| 4 | 32×32 | sequential | 900 | 0 | **PASS** |
| 5 | 32×32 | affine | 900 | 0 | **PASS** |
| 6 | 32×32 | lcg-random | 900 | 0 | **PASS** |
| 7 | 64×64 | sequential | 3844 | 0 | **PASS** |
| 8 | 64×64 | affine | 3844 | 0 | **PASS** |
| 9 | 64×64 | lcg-random | 3844 | 0 | **PASS** |

## Backend fix discovered during this slice

OpenPTXas `sub.u32` with immediate used the literal pool (cbuf[0]
constant bank), but the CUDA driver zeroes the literal region past
params at launch.  Fix: inline negated IADD3 immediate (commit
`04f6a19` in openptxas).  Zero regressions.

## What this slice excludes

- **shared memory tile**: this slice uses direct global reads (5 LDG
  per output element).  A shared-memory version with halo loading
  would reduce global memory traffic from 5× to ~1× per element.
- **halo loading**: the tile-border threads don't load extra cells for
  neighbor access across tile boundaries.
- **diagonal neighbors**: only 5-point (von Neumann) stencil, not
  9-point (Moore).
- **normalization**: raw sum, no division by 5 (blur) or weights.
- **non-square tiles**: 16×16 blocks only.

## Validation summary

| harness | result |
|---|:-:|
| Forge proof | 6/6 obligations discharged |
| OpenCUDA emit | clean PTX |
| OpenPTXas → cubin | 5840 bytes |
| GPU stress (9 runs) | **9/9** correct (up to 64×64 / 16 blocks) |
| OpenPTXas pytest | **865/865** clean |
| OpenPTXas GPU harness | 127 PASS / 10 FAIL / 7 RUN_EXC (unchanged) |
| OpenPTXas frontier | BYTE_EXACT 66 / STRUCTURAL 78 (unchanged) |
| Backend changes | 1 fix: sub.u32 inline negated IADD3 |

## Capability envelope after FORGE49-52

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
| **5-point 2D stencil** | **FORGE49** | **✓** |
