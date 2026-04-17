# Forge → OpenCUDA → OpenPTXas → GPU — 2D Indexing + Coalesced Access (FORGE41-44)

**Date**: 2026-04-16
**Hardware**: RTX 5090 (SM_120, Blackwell)
**Status**: **PASS** (4/4 stress runs, up to 8192 threads / 256 blocks)

## What this proves

Forge can express the canonical 2D-grid → 1D-linear index mapping
(`idx = y * width + x`) and pass it through the full pipeline with
fully **coalesced** global memory access on every block.  The same
SASS pattern that powers row-major matrix kernels and image-processing
stencils is now reachable from Forge.

## Forge source

```rust
#[kernel]
fn vec_2d_add(a: span<u32>, b: span<u32>, out: span<u32>,
              n: u32, width: u32)
    requires n <= a.len
    requires n <= b.len
    requires n <= out.len
    requires n > 0u32
    requires width > 0u32
{
    let x: u32 = threadIdx_x;
    let y: u32 = blockIdx_x;
    let idx: u32 = y * width + x;
    if idx < n {
        let va: u32 = a[idx];
        let vb: u32 = b[idx];
        out[idx] = va + vb;
    };
}
```

3/3 Z3 obligations discharged (a / b / out load+store bounds via
`idx < n` and `n <= len` chain).

## Index mapping (width = 32)

| blockIdx_x (y) | threadIdx_x (x) | idx = y*32 + x | memory bank |
|---:|---:|---:|---|
| 0 | 0..31 | 0..31    | block 0 row |
| 1 | 0..31 | 32..63   | block 1 row |
| 2 | 0..31 | 64..95   | block 2 row |
| ⋮ | ⋮ | ⋮ | ⋮ |
| k | 0..31 | 32k..32k+31 | block k row |

Each block reads/writes a contiguous 128-byte strip → **single
coalesced 32-lane transaction** per LDG/STG.

## PTX (key slice)

```
mov.u32        %r2, %tid.x;          // x
mov.u32        %r3, %ctaid.x;        // y
mul.lo.u32     %r4, %r3, %r1;        // y * width
add.u32        %r5, %r4, %r2;        // idx = y*width + x
setp.lt.u32    %p0, %r5, %r0;        // idx < n
@!%p0 ret;
shl.b32        %r6, %r5, 2;          // idx * 4 (u32 stride)
cvt.u64.u32    %rd4, %r6;
add.u64        %rd0, %rd0, %rd4;
ld.global.u32  %r7, [%rd0];          // a[idx]
add.u64        %rd1, %rd1, %rd4;
ld.global.u32  %r8, [%rd1];          // b[idx]
add.u64        %rd2, %rd2, %rd4;
add.u32        %r9, %r7, %r8;
st.global.u32  [%rd2], %r9;          // out[idx]
```

SSA-distinct vregs `%r0..%r9` — produced cleanly by the OCUDA01-08
SSA emission (no aliasing, no allocator value-lifetime hazards).

## SASS shape

| op family | role |
|---|---|
| `S2R` × 2 | load `tid.x`, `ctaid.x` |
| `IMAD` | `y * width + x` (folds the linearization into one fused op) |
| `ISETP.LT` + `EXIT @P0` | bounds guard |
| `IADD3` / `IADD.64-UR` | base + offset for a, b, out |
| `LDG.E.32` × 2 | coalesced load of `a[idx]`, `b[idx]` |
| `IADD` | `va + vb` |
| `STG.E.32` × 1 | coalesced store of `out[idx]` |

The two LDGs and one STG are address-contiguous across the 32 lanes
of a warp, so SM_120 issues them as single 128-byte sector
transactions — the canonical CUDA fast path.

## GPU stress matrix

| run | N | blocks × threads | width | input pattern | result |
|---:|---:|---:|---:|---|:-:|
| 1 | 1024 | 32 × 32 | 32 | `a[i] = i`, `b[i] = 2*i`           | **PASS** (0 / 1024 errors) |
| 2 | 512  | 16 × 32 | 32 | `a[i] = 1`, `b[i] = 1`             | **PASS** (0 / 512 errors)  |
| 3 | 2048 | 64 × 32 | 32 | LCG pseudo-random in both arrays   | **PASS** (0 / 2048 errors) |
| 4 | 8192 | 256 × 32 | 32 | `a[i] = i`, `b[i] = 0xDEADBEEF ^ i` | **PASS** (0 / 8192 errors) |

Run 4 specifically covers 256 blocks — every block computes its row
of `idx = y*32 + x`, every lane within the block stays coalesced,
and every `out[idx]` matches CPU reference exactly.

## Validation summary

| harness | result |
|---|:-:|
| Forge proof | 3/3 obligations discharged |
| OpenCUDA emit | clean PTX with SSA `%r0..%r9`, single MUL + ADD for `y*width + x` |
| OpenPTXas → cubin | 4984 bytes |
| GPU stress (4 runs) | **4/4** correct (up to 8192 threads / 256 blocks) |
| OpenPTXas pytest | **865/865** clean |
| OpenPTXas GPU harness | 127 PASS / 10 FAIL / 7 RUN_EXC (unchanged) |
| OpenPTXas frontier | BYTE_EXACT 66 / STRUCTURAL 78 (unchanged) |
| Backend changes | **ZERO** (no OpenPTXas / OpenCUDA / Forge code touched) |

## Capability envelope after FORGE41-44

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
| multi-block reduction (combined) | FORGE37 | ✓ |
| **2D indexing + coalesced access** | **FORGE41** | **✓** |

This slice is the foundational shape for row-major matrix kernels
(matmul, transpose, stencil, image filters).  The fact that it
lowers to one MUL + one ADD + coalesced LDG/STG with no backend
changes means the dense-matrix family is now within reach of the
Forge envelope as configured today.

## Reproduction

```bash
cd /mnt/c/users/kraken/forge
opam exec -- ./_build/default/bin/main.exe cuda demos/1109_forge_2d_indexing.fg
cd /mnt/c/users/kraken/opencuda
python -m opencuda /mnt/c/users/kraken/forge/demos/1109_forge_2d_indexing.cu --emit-ptx
cd /mnt/c/users/kraken/openptxas
python -c "from sass.pipeline import compile_ptx_source
ptx = open('/mnt/c/users/kraken/forge/demos/1109_forge_2d_indexing.ptx').read()
cubin = next(iter(compile_ptx_source(ptx).values()))
open('/mnt/c/users/kraken/forge/demos/1109_forge_2d_indexing.cubin','wb').write(cubin)"
# Run on GPU - see harness in this commit for the cuLaunchKernel test.
```
