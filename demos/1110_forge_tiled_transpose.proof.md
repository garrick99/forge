# Forge → OpenCUDA → OpenPTXas → GPU — Tiled Transpose (FORGE45-48)

**Date**: 2026-04-16
**Hardware**: RTX 5090 (SM_120, Blackwell)
**Status**: **FORGE_TRANSPOSE_BLOCKED** — Forge / OpenCUDA / PTX correct; OpenPTXas SASS lowering bug for dual-CTAID 2D-grid pattern.

## TL;DR

Forge expresses the canonical 16×16 tiled transpose end-to-end:
shared-memory staging, `__syncthreads()` barrier, 2D thread + 2D
block indexing, transposed read in phase 2.  All Z3 obligations
discharge.  OpenCUDA emits clean PTX with the correct address-space
mapping.

The same Forge-emitted PTX, when assembled by **NVIDIA `ptxas`**,
runs **12/12 test cases correct** (all four shapes, all three
patterns).  When assembled by **OpenPTXas**, the cubin crashes with
`CUDA_ERROR_ILLEGAL_INSTRUCTION` (715) on every shape.

Root cause is a SASS-side register-routing bug in OpenPTXas when two
`S2UR` instructions are emitted for `CTAID.X` and `CTAID.Y` and both
results are then consumed by vector ALU ops.  The downstream IMAD
reads uninitialized vector regs `R14`/`R15` instead of the uniform
regs `UR8`/`UR9` that hold the CTAID values.  This is a backend
issue, not a Forge issue.

## Forge source (5/5 obligations discharged)

```rust
#[kernel]
fn transpose_tile(inp: span<u32>, out: span<u32>,
                  width: u32, height: u32)
    requires width > 0u32
    requires height > 0u32
    requires width * height <= inp.len
    requires width * height <= out.len
    requires threadIdx_x < 16u32
    requires threadIdx_y < 16u32
{
    let smem: shared<u32>[256] = 0;

    let x: u32 = threadIdx_x;
    let y: u32 = threadIdx_y;
    let bx: u32 = blockIdx_x;
    let by: u32 = blockIdx_y;

    // Phase 1: load in[gy, gx] -> smem[y, x]
    let gx: u32 = bx * 16u32 + x;
    let gy: u32 = by * 16u32 + y;
    if gx < width {
        if gy < height {
            let in_idx: u32  = gy * width + gx;
            let sw_idx: u32  = y * 16u32 + x;
            smem[sw_idx] = inp[in_idx];
        };
    };

    syncthreads();

    // Phase 2: write smem[x, y] (transposed read) -> out[ty, tx]
    let tx: u32 = by * 16u32 + x;
    let ty: u32 = bx * 16u32 + y;
    if tx < height {
        if ty < width {
            let out_idx: u32 = ty * height + tx;
            let sr_idx: u32  = x * 16u32 + y;
            if out_idx < out.len {
                out[out_idx] = smem[sr_idx];
            };
        };
    };
}
```

## Index equations

| symbol | definition | bound at use |
|---|---|---|
| `x`        | `threadIdx_x`           | `x < 16` (precondition) |
| `y`        | `threadIdx_y`           | `y < 16` (precondition) |
| `bx`       | `blockIdx_x`            | `bx * TILE + x < width`  guarded |
| `by`       | `blockIdx_y`            | `by * TILE + y < height` guarded |
| `gx`       | `bx*TILE + x`           | `gx < width`  (phase-1 guard) |
| `gy`       | `by*TILE + y`           | `gy < height` (phase-1 guard) |
| `in_idx`   | `gy*width + gx`         | `< width*height ≤ inp.len` |
| `sw_idx`   | `y*TILE + x`            | `≤ 15*16 + 15 = 255 < 256` |
| `tx`       | `by*TILE + x`           | `tx < height` (phase-2 guard) |
| `ty`       | `bx*TILE + y`           | `ty < width`  (phase-2 guard) |
| `out_idx`  | `ty*height + tx`        | explicit `out_idx < out.len` guard |
| `sr_idx`   | `x*TILE + y`            | `≤ 15*16 + 15 = 255 < 256` |

## Tile mapping diagram (single 16×16 tile)

```
            in[gy, gx]                          out[c, r]
       gx →  0 1 2 .. 15                  ty →  0 1 2 .. 15
   gy ↓ +-----------+              tx ↓        +-----------+
      0 |  in row 0 |                       0  |  out row 0|
      1 |  in row 1 |   transpose tile      1  |  out row 1|
      2 |  in row 2 |  ===============>     2  |  out row 2|
      ⋮ |    ⋮      |                       ⋮  |    ⋮      |
     15 |  in row15 |                      15  |  out row15|
        +-----------+                          +-----------+

shared tile (smem[y*16 + x]):
   write side (phase 1):  smem[y, x] = in[gy, gx]   (lane (x,y) writes [y][x])
   read  side (phase 2):  out[ty, tx] = smem[x, y]  (lane (x,y) reads  [x][y])

example movement:    in[r=3, c=7]
   phase 1 (block thread (x=7, y=3)):  smem[3*16 + 7] = in[3*width + 7]
   phase 2 (block thread (x=3, y=7)):  out[7*height + 3] = smem[3*16 + 7]
   net:                                out[c=7, r=3]  =  in[r=3, c=7]   ✓
```

## Address-space mapping (OpenCUDA-emitted PTX)

| Forge | CUDA C | PTX | SASS |
|---|---|---|---|
| `inp[in_idx]`           | `inp[in_idx]`            | `ld.global.u32`  | `LDG.E.32` |
| `shared<u32>[256]`      | `__shared__ uint32_t smem[256]` | `.shared .u32 smem[256]` | block SMEM |
| `smem[sw_idx] = ...`    | `smem[sw_idx] = ...`     | `st.shared.u32`  | `STS` |
| `syncthreads()`         | `__syncthreads()`        | `bar.sync 0`     | `BAR.SYNC.DEFER_BLOCKING` |
| `... = smem[sr_idx]`    | `... = smem[sr_idx]`     | `ld.shared.u32`  | `LDS` |
| `out[out_idx] = ...`    | `out[out_idx] = ...`     | `st.global.u32`  | `STG.E.32` |

PTX is correct: `mov.u64 %rd0, smem` initializes the shared base; phase 1
emits `ld.global.u32 -> st.shared.u32`; barrier; phase 2 emits
`ld.shared.u32 -> st.global.u32`.

## GPU execution

Two cubins were assembled from the **same** Forge-emitted PTX:

| cubin | assembler | result on test matrix |
|---|---|---|
| `1110_forge_tiled_transpose_REF.cubin`   | NVIDIA `ptxas` v13.0     | **12/12 PASS** |
| `1110_forge_tiled_transpose.cubin`       | OpenPTXas (this repo)    | crashes — CUDA_ERROR_ILLEGAL_INSTRUCTION on first launch |

Test matrix (12 cases = 4 shapes × 3 patterns):

| run | shape (HxW) | pattern    | expected | NVIDIA-ref result | OpenPTXas result |
|---:|---|---|---:|:-:|:-:|
|  1 | 16×16 | sequential  | exact transpose | PASS | RUN_ERR (715) |
|  2 | 16×16 | affine      | exact transpose | PASS | RUN_ERR (715) |
|  3 | 16×16 | lcg-random  | exact transpose | PASS | RUN_ERR (715) |
|  4 | 16×32 | sequential  | exact transpose | PASS | RUN_ERR (715) |
|  5 | 16×32 | affine      | exact transpose | PASS | RUN_ERR (715) |
|  6 | 16×32 | lcg-random  | exact transpose | PASS | RUN_ERR (715) |
|  7 | 32×16 | sequential  | exact transpose | PASS | RUN_ERR (715) |
|  8 | 32×16 | affine      | exact transpose | PASS | RUN_ERR (715) |
|  9 | 32×16 | lcg-random  | exact transpose | PASS | RUN_ERR (715) |
| 10 | 64×64 | sequential  | exact transpose | PASS | RUN_ERR (715) |
| 11 | 64×64 | affine      | exact transpose | PASS | RUN_ERR (715) |
| 12 | 64×64 | lcg-random  | exact transpose | PASS | RUN_ERR (715) |

All 12 reference results were verified element-by-element against
`np.transpose(in.reshape(H, W))`.

Coalescing analysis (from PTX address pattern):
- **Phase 1 (global → shared)**: lanes with consecutive `threadIdx.x`
  (= `gx` increments by 1) read consecutive `in[gy*width + gx]` —
  **fully coalesced LDG**.
- **Phase 2 (shared → global)**: lanes with consecutive `threadIdx.x`
  (= `tx` increments by 1) write consecutive `out[ty*height + tx]` —
  **fully coalesced STG**.

This is exactly the reason for using a tile + barrier + transposed
shared read: it lets you keep both global passes coalesced even
though the in-memory layout is transposed.

## OpenPTXas root-cause evidence

NVIDIA `ptxas` emits S2R into vector regs (R5, R3) for both CTAIDs:

```sass
/*0050*/  S2R R5, SR_CTAID.X ;       <- vector reg R5
/*0070*/  S2R R3, SR_CTAID.Y ;       <- vector reg R3
/*00c0*/  IMAD R0, R5, 0x10, R6 ;    <- correct: reads R5
/*00d0*/  IMAD R4, R3, 0x10, R6 ;    <- correct: reads R3
```

OpenPTXas emits S2UR into uniform regs (UR8, UR9), then the IMAD
reads UNINITIALIZED vector regs R14/R15:

```sass
/*00e0*/  S2UR UR8, SR_CTAID.X ;     <- uniform reg UR8
/*00f0*/  S2UR UR9, SR_CTAID.Y ;     <- uniform reg UR9
/*0100*/  IMAD.SHL.U32 R16, R14, 0x10, RZ ;  <- BUG: R14 never written
/*0130*/  IMAD.SHL.U32 R16, R15, 0x10, RZ ;  <- BUG: R15 never written
```

Compare to the previously-working single-CTAID slice (1108 multi-block
reduce), where one `S2UR UR4, SR_CTAID.X` is correctly consumed
directly by `IMAD R2, R3, UR4, R8`.  The bug is specific to the
**dual-CTAID** pattern: when both `ctaid.x` and `ctaid.y` are read,
the SSA→phys mapping desynchronises and the IMAD operand reference
no longer matches the S2UR destination.

This is the first slice in the FORGE family to exercise `%ctaid.y`
end-to-end through OpenPTXas, so the bug has been latent since
2D-grid lowering was added.

## What this slice excludes

- **bank-conflict padding** (smem[256] declared as flat 16×16 — no
  +1 padding per row; OK for u32 on SM_120 with 32 banks since
  16 lanes × 4B = 64B per row stays within 16 banks)
- **vectorized loads** (no `ldg.v2 / ldg.v4`)
- **looped tiles** (each thread handles one element per phase, not
  multiple elements per loop iteration)
- **non-square block shapes** (16×16 only; rectangular tiles would
  trigger a different sm_x/sm_y interplay)
- **`grid_w_log2` / divmod tricks** to avoid CTAID.Y were tried as
  a workaround but trigger a separate OpenPTXas RCP-divmod register-
  routing bug; the natural CTAID.X+CTAID.Y form is the cleanest
  Forge expression of the kernel and is what is captured here.

## Validation summary

| harness | result |
|---|:-:|
| Forge proof | **5/5 obligations discharged** |
| OpenCUDA emit | clean PTX (`.shared .u32 smem[256]`, `bar.sync 0`, LDG/STG/LDS/STS) |
| NVIDIA ptxas → cubin | 6944 bytes, **12/12 GPU PASS** (4 shapes × 3 patterns) |
| OpenPTXas → cubin | 5632 bytes, **0/12 GPU PASS** (CUDA_ERROR_ILLEGAL_INSTRUCTION) |
| OpenPTXas pytest | **865/865** clean (unchanged) |
| OpenPTXas GPU harness | 127 PASS / 10 FAIL / 7 RUN_EXC (unchanged baseline) |
| OpenPTXas frontier | BYTE_EXACT 66 / STRUCTURAL 78 (unchanged) |
| Backend changes | **ZERO** (no Forge / OpenCUDA / OpenPTXas code modified) |

## Capability envelope after FORGE45-48

Verified end-to-end through Forge → OpenCUDA → OpenPTXas → GPU:

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
| **tiled transpose (combined)** | **FORGE45** | **BLOCKED — OpenPTXas dual-CTAID** |

The Forge-side capability is fully present (proof + correct PTX +
NVIDIA-ref runs perfectly).  The blocker is downstream and confined
to OpenPTXas's SASS register routing for the dual-S2UR CTAID pattern.

## Reproduction

```bash
cd /mnt/c/users/kraken/forge
opam exec -- ./_build/default/bin/main.exe cuda demos/1110_forge_tiled_transpose.fg

cd /mnt/c/users/kraken/opencuda
python3 -m opencuda /mnt/c/users/kraken/forge/demos/1110_forge_tiled_transpose.cu --emit-ptx

# OpenPTXas cubin (under test — fails)
cd /mnt/c/users/kraken/openptxas
python3 -c "from sass.pipeline import compile_ptx_source
ptx = open('/mnt/c/users/kraken/forge/demos/1110_forge_tiled_transpose.ptx').read()
cubin = next(iter(compile_ptx_source(ptx).values()))
open('/mnt/c/users/kraken/forge/demos/1110_forge_tiled_transpose.cubin','wb').write(cubin)"

# NVIDIA-ptxas cubin (oracle — passes 12/12)
ptxas -arch=sm_120 demos/1110_forge_tiled_transpose.ptx \
      -o demos/1110_forge_tiled_transpose_REF.cubin

# Run
py demos/1110_forge_tiled_transpose_run.py
```
