# Forge → OpenCUDA → OpenPTXas → GPU — Pairwise Reduction (FORGE17-20)

**Date**: 2026-04-16
**Hardware**: RTX 5090 (SM_120, Blackwell)
**Status**: **PASS** (255/255 threads correct)

## What this proves

Forge can express a per-thread reduction step (`a[tid] + a[tid+1]`) —
the building block of every pairwise reduction tree — and the full
toolchain compiles it into correct GPU code with two LDGs from the
same array, dependent address compute, and a bounded entry guard.

## Forge source

```rust
fn vec_pairwise_sum(a: span<u32>, out: span<u32>, n: u32, n_minus_1: u32)
    requires n <= a.len
    requires n <= out.len
    requires n_minus_1 + 1u32 == n
    requires n > 0u32
{
    let tid: u32 = blockIdx_x * blockDim_x + threadIdx_x;
    if tid < n_minus_1 {
        let i_next: u32 = tid + 1u32;
        let v0: u32 = a[tid];
        let v1: u32 = a[i_next];
        out[tid] = v0 + v1;
    };
}
```

3/3 Z3 obligations discharged.

## Pipeline

| stage | artifact | notes |
|---|---|---|
| Forge → CUDA C | `1103_forge_pairwise_sum.cu` | clean u32 emit |
| OpenCUDA → PTX | `1103_forge_pairwise_sum.ptx` | SSA-distinct vregs (`%r0-%r12`); two `ld.global.u32` from same array |
| OpenPTXas → cubin | `1103_forge_pairwise_sum.cubin` | 4928 bytes |

## Value flow (per thread)

```
v0 = a[tid]                              # LDG #1
v1 = a[tid + 1]                          # LDG #2 (different address, same array)
out[tid] = v0 + v1                       # IADD3 + STG
```

The two LDGs use distinct address registers (`%rd2 = a + tid*4` then
`%rd2 = a + (tid+1)*4`) and write to distinct dest vregs (`%r9` and
`%r11`). The OCUDA01-08 SSA emission guarantees no value-identity
corruption from OpenPTXas' LDG dest reorder.

## GPU execution

Test inputs: `a[i] = i² + 7` for `i ∈ [0, 256)`.
Computing threads: 255 (last thread `tid=255` exits because
`tid < n_minus_1 = 255` is false).

| metric | value |
|---|:-:|
| Threads launched | 256 |
| Threads computing | 255 |
| Correct outputs | **255 / 255** |
| GPU error rate | **0%** |

Sample (first 6 threads):
```
tid=0: a[0]+a[1] =   7 +  8 = 15  ✓
tid=1: a[1]+a[2] =   8 + 11 = 19  ✓
tid=2: a[2]+a[3] =  11 + 16 = 27  ✓
tid=3: a[3]+a[4] =  16 + 23 = 39  ✓
tid=4: a[4]+a[5] =  23 + 32 = 55  ✓
tid=5: a[5]+a[6] =  32 + 43 = 75  ✓
```

## Validation summary

| harness | result |
|---|:-:|
| Forge proof | 3/3 obligations discharged |
| OpenCUDA emit | clean PTX, 1 kernel |
| OpenPTXas → cubin | 4928 bytes |
| GPU run | 255/255 correct |
| OpenPTXas pytest | **865/865** clean |
| OpenPTXas GPU harness | 127 PASS / 10 FAIL / 7 RUN_EXC (unchanged) |
| OpenPTXas frontier | BYTE_EXACT 66 / STRUCTURAL 78 (unchanged) |
| Backend changes | **ZERO** (no OpenPTXas/OpenCUDA code touched) |

## Capability envelope after FORGE17-20

Verified end-to-end through Forge → OpenCUDA → OpenPTXas → GPU:

| family | example slice | status |
|---|---|:-:|
| arithmetic + clamp | FORGE01 vec_compute_clamp | ✓ |
| predicates / branching | FORGE05 vec_diff_branch | ✓ |
| multi-array memory | FORGE09 vec_memory_mix3 | ✓ |
| chained map composition | FORGE13 vec_map_compose | ✓ |
| **pairwise reduction step** | **FORGE17 vec_pairwise_sum** | **✓** |

Next planned phase (per FORGE17-20 spec): expand to shared memory,
warp-level ops, and full tree reductions.

## Reproduction

```bash
cd /mnt/c/users/kraken/forge
opam exec -- ./_build/default/bin/main.exe cuda demos/1103_forge_pairwise_sum.fg
cd /mnt/c/users/kraken/opencuda
python -m opencuda /mnt/c/users/kraken/forge/demos/1103_forge_pairwise_sum.cu --emit-ptx
cd /mnt/c/users/kraken/openptxas
python -c "from sass.pipeline import compile_ptx_source
ptx = open('/mnt/c/users/kraken/forge/demos/1103_forge_pairwise_sum.ptx').read()
cubin = next(iter(compile_ptx_source(ptx).values()))
open('/mnt/c/users/kraken/forge/demos/1103_forge_pairwise_sum.cubin','wb').write(cubin)"
# Run on GPU - see harness in this commit for the cuLaunchKernel test.
```
