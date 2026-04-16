# Forge → OpenCUDA → OpenPTXas → GPU — Shared-Memory Neighborhood (FORGE21-24)

**Date**: 2026-04-16
**Hardware**: RTX 5090 (SM_120, Blackwell)
**Status**: **PASS** (255/255 computing threads correct)

## What this proves

Forge can express a single-block cooperative shared-memory staging
pattern:

1. each thread writes one element into block-local `__shared__`
2. one block-wide barrier (`syncthreads`)
3. each thread reads its own slot + the next slot to compute a result

The full toolchain lowers Forge's `shared<u32>[256]` declaration into
`.shared .u32 smem[256]`, generates `st.shared.u32` / `ld.shared.u32`
PTX with a `bar.sync 0` between phases, and OpenPTXas emits SASS with
`STS` / `LDS.32` / `BAR.SYNC` / `STG` — the canonical CUDA shared-mem
shape.

## Forge source

```rust
fn vec_shared_neighbor(a: span<u32>, out: span<u32>, n: u32, n_minus_1: u32)
    requires n <= a.len
    requires n <= out.len
    requires n <= 256u32
    requires n_minus_1 + 1u32 == n
    requires n > 0u32
{
    let smem: shared<u32>[256] = 0;
    let tid: u32 = threadIdx_x;
    if tid < n { smem[tid] = a[tid]; };
    syncthreads();
    if tid < n_minus_1 {
        let v0: u32 = smem[tid];
        let v1: u32 = smem[tid + 1u32];
        out[tid] = v0 + v1;
    };
}
```

3/3 Z3 obligations discharged (one global span bound + one shared
bound + one global span bound).

## Address-space mapping

| Forge construct | CUDA C | PTX (OpenCUDA) | SASS (OpenPTXas) |
|---|---|---|---|
| `shared<u32>[256]` | `__shared__ uint32_t smem[256]` | `.shared .u32 smem[256]` | block-local SMEM region |
| `smem[tid] = a[tid]` | same | `st.shared.u32 [%rdN], %rM` | `STS` (op 0x388) |
| `syncthreads()` | `__syncthreads()` | `bar.sync 0` | `BAR.SYNC` (op 0xb1d) |
| `let v = smem[tid]` | same | `ld.shared.u32 %rN, [%rdM]` | `LDS.32` (op 0x984) |
| `a[tid]` | same | `ld.global.u32 %rN, [%rdM]` | `LDG.E.32` (op 0x981) |
| `out[tid] = ...` | same | `st.global.u32 [%rdN], %rM` | `STG` (op 0x986) |

Pointers to global vs shared use **distinct address-space PTX
instructions** — no aliasing path exists.

## SASS summary (31 active instrs)

```
LDC + S2R + LDCUs + S2UR              # preamble + tid
ISETP.UR + (predicated body):
   LDC + IMAD + MOV + IADD.64         # build a's address
   LDG.E.32                           # v_load = a[tid]
   ULEA + STS                         # smem[tid] = v_load
BAR.SYNC                              # block-wide barrier
@P EXIT                               # threads >= n_minus_1 exit
IMAD + LDCU + HFMA2 + IADD.64-UR + UIADD
   LDS.32                             # v0 = smem[tid]
   LDS.32                             # v1 = smem[tid+1]
   IADD.64-UR + IADD.64               # build out's address + sum
STG                                   # out[tid] = v0 + v1
EXIT + BRA
```

## GPU execution

Test inputs: `a[i] = i² + 11` for `i ∈ [0, 256)`.
Computing threads: 255 (last thread `tid=255` exits because
`tid < n_minus_1 = 255` is false).

| metric | value |
|---|:-:|
| Threads launched | 256 (1 block) |
| Threads computing | 255 |
| Correct outputs | **255 / 255** |
| GPU error rate | **0%** |

Sample (first 6 threads):
```
tid=0: smem[0] + smem[1]   = 11 + 12 = 23 ✓
tid=1: smem[1] + smem[2]   = 12 + 15 = 27 ✓
tid=2: smem[2] + smem[3]   = 15 + 20 = 35 ✓
tid=3: smem[3] + smem[4]   = 20 + 27 = 47 ✓
tid=4: smem[4] + smem[5]   = 27 + 36 = 63 ✓
tid=5: smem[5] + smem[6]   = 36 + 47 = 83 ✓
```

## Validation summary

| harness | result |
|---|:-:|
| Forge proof | 3/3 obligations discharged |
| OpenCUDA emit | clean PTX with `.shared`, `st.shared.u32`, `ld.shared.u32`, `bar.sync 0` |
| OpenPTXas → cubin | 6440 bytes, 31 active SASS instrs |
| GPU run | 255/255 correct |
| OpenPTXas pytest | **865/865** clean |
| OpenPTXas GPU harness | 127 PASS / 10 FAIL / 7 RUN_EXC (unchanged) |
| OpenPTXas frontier | BYTE_EXACT 66 / STRUCTURAL 78 (unchanged) |
| Backend changes | **ZERO** (no OpenPTXas/OpenCUDA code touched) |

## What is intentionally excluded

- Multi-block kernels (this slice uses a single block)
- Atomic operations
- Warp-level intrinsics (`__shfl_*`)
- Loops (no tree reduction, no grid-stride)
- Cross-block synchronization

These remain to be unlocked in subsequent slices.

## Capability envelope after FORGE21-24

Verified end-to-end through Forge → OpenCUDA → OpenPTXas → GPU:

| family | example slice | status |
|---|---|:-:|
| arithmetic + clamp | FORGE01 | ✓ |
| predicates / branching | FORGE05 | ✓ |
| multi-array memory | FORGE09 | ✓ |
| chained map composition | FORGE13 | ✓ |
| pairwise reduction step | FORGE17 | ✓ |
| **shared-mem stage + barrier + neighbor read** | **FORGE21** | **✓** |

## Reproduction

```bash
cd /mnt/c/users/kraken/forge
opam exec -- ./_build/default/bin/main.exe cuda demos/1104_forge_shared_neighbor.fg
cd /mnt/c/users/kraken/opencuda
python -m opencuda /mnt/c/users/kraken/forge/demos/1104_forge_shared_neighbor.cu --emit-ptx
cd /mnt/c/users/kraken/openptxas
python -c "from sass.pipeline import compile_ptx_source
ptx = open('/mnt/c/users/kraken/forge/demos/1104_forge_shared_neighbor.ptx').read()
cubin = next(iter(compile_ptx_source(ptx).values()))
open('/mnt/c/users/kraken/forge/demos/1104_forge_shared_neighbor.cubin','wb').write(cubin)"
# Run on GPU - see harness in this commit for the cuLaunchKernel test.
```
