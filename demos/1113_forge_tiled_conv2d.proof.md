# Forge → OpenCUDA → OpenPTXas → GPU — Tiled 3×3 Weighted Convolution (FORGE57-60)

**Date**: 2026-04-17
**Hardware**: RTX 5090 (SM_120, Blackwell)
**Status**: **PASS** (9/9 — 3 shapes × 3 patterns, zero backend changes)

## What this proves

Forge can express a complete 3×3 weighted 2D convolution kernel with
shared-memory tiling: 9 neighbor reads from shared memory, 9
multiply-add operations per output element, all boundary handling
proven safe by Z3.  This is the canonical pattern for image
processing (blur, sharpen, edge detection) and neural network
inference (depthwise conv layers).

## Forge source (12/12 obligations discharged)

```rust
#[kernel]
fn conv2d_3x3(inp: span<u32>, out: span<u32>,
              width: u32, height: u32) { ... }
```

Weights (unnormalized Gaussian blur, sum = 16):
```
[ 1  2  1 ]
[ 2  4  2 ]
[ 1  2  1 ]
```

12 obligations: 1 global load, 1 shared store, 9 shared reads
(nw, n, ne, w, c, e, sw, s, se), 1 global store.

## Tile diagram (3×3 neighborhood)

```
shared tile (16×16):
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  |L|L|L|L|L|L|L|L|L|L|L|L|L|L|L|L|  y=0
  |L|C|C|C|C|C|C|C|C|C|C|C|C|C|C|L|  y=1
  ⋮                                ⋮
  |L|C|C|C|C|C|C|C|C|C|C|C|C|C|C|L|  y=14
  |L|L|L|L|L|L|L|L|L|L|L|L|L|L|L|L|  y=15
  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

For thread (x=5, y=3), s_idx = 53:
  nw = smem[53-17] = smem[36]    ×1
  n  = smem[53-16] = smem[37]    ×2
  ne = smem[53-15] = smem[38]    ×1
  w  = smem[53-1]  = smem[52]    ×2
  c  = smem[53]    = smem[53]    ×4
  e  = smem[53+1]  = smem[54]    ×2
  sw = smem[53+15] = smem[68]    ×1
  s  = smem[53+16] = smem[69]    ×2
  se = smem[53+17] = smem[70]    ×1
```

## Weight application mapping

| position | smem offset | weight | instruction pattern |
|---|---|---|---|
| nw | s_idx - 17 | ×1 | direct add |
| n  | s_idx - 16 | ×2 | `IMAD val, 2, n` or `IADD3 n, n` |
| ne | s_idx - 15 | ×1 | direct add |
| w  | s_idx - 1  | ×2 | multiply-add |
| c  | s_idx      | ×4 | multiply-add |
| e  | s_idx + 1  | ×2 | multiply-add |
| sw | s_idx + 15 | ×1 | direct add |
| s  | s_idx + 16 | ×2 | multiply-add |
| se | s_idx + 17 | ×1 | direct add |

## PTX + SASS summary

PTX: 9× `ld.shared.u32` → 9× `LDS`. 4× `mul.lo.u32` (for ×2 and ×4 weights) → `IMAD` or `IMAD.SHL`. 8× `add.u32` → `IADD3`. 1× `st.global.u32` → `STG.E.32`. `bar.sync 0` → `BAR.SYNC`.

Cubin size: 7320 bytes. No backend changes required.

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

## Exclusions

- **normalization**: raw weighted sum, no division by 16
- **halo loading**: tile-border cells skipped (no cross-tile neighbors)
- **vectorized loads**: scalar LDG only
- **looped tiles**: single tile per block
- **float weights**: u32 integer weights only
- **runtime kernel**: weights hardcoded, not passed as parameters

## Validation summary

| harness | result |
|---|:-:|
| Forge proof | **12/12** obligations discharged |
| OpenCUDA emit | clean PTX (9 ld.shared, bar.sync, mul/add chain, st.global) |
| OpenPTXas → cubin | 7320 bytes |
| GPU stress (9 runs) | **9/9** correct |
| OpenPTXas pytest | **865/865** clean |
| OpenPTXas GPU harness | 127/10/7 (unchanged) |
| OpenPTXas frontier | 66/78 (unchanged) |
| Backend changes | **ZERO** |

## Capability envelope after FORGE57-60

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
| 5-point stencil (global) | FORGE49 | ✓ |
| tiled stencil (shared mem) | FORGE53 | ✓ |
| **3×3 weighted convolution** | **FORGE57** | **✓** |

This is the first Forge slice that exercises **multiply-add chains**
(9 weighted reads per output element) combined with shared-memory
tiling.  The pattern directly maps to depthwise convolution layers
in neural networks and all standard image-processing filters.
