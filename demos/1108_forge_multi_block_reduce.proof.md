# Forge → OpenCUDA → OpenPTXas → GPU — Multi-Block Reduction (FORGE37-40)

**Date**: 2026-04-16
**Hardware**: RTX 5090 (SM_120, Blackwell)
**Status**: **PASS** (4/4 stress runs, up to 1024 contributing threads)

## What this proves

Forge can express a complete reduction primitive that **composes**
shared memory, block-wide barriers, manual tree reduction, and
atomic global accumulation across **multiple blocks**.  Final
`out[0]` equals `sum(a)` exactly across all four test patterns.

This is the canonical GPU reduction kernel pattern — verified
end-to-end through Forge with zero backend changes.

## Forge source

```rust
extern fn atom_add_u32(ptr: raw<u32>, val: u32) -> u32 = "forge_gpu";

#[kernel]
fn vec_block_reduce(a: span<u32>, out_ptr: raw<u32>, n: u32, n_minus_1: u32) {
    let smem: shared<u32>[32] = 0;
    let tid: u32 = threadIdx_x;
    let gid: u32 = blockIdx_x * blockDim_x + threadIdx_x;

    if gid < n { smem[tid] = a[gid]; } else { smem[tid] = 0u32; };
    syncthreads();

    if tid < 16u32 { smem[tid] = smem[tid] + smem[tid + 16u32]; };
    syncthreads();
    if tid < 8u32  { smem[tid] = smem[tid] + smem[tid + 8u32];  };
    syncthreads();
    if tid < 4u32  { smem[tid] = smem[tid] + smem[tid + 4u32];  };
    syncthreads();
    if tid < 2u32  { smem[tid] = smem[tid] + smem[tid + 2u32];  };
    syncthreads();
    if tid < 1u32  { smem[tid] = smem[tid] + smem[tid + 1u32];  };
    syncthreads();

    if tid == 0u32 {
        let _old: u32 = atom_add_u32(out_ptr, smem[0u32]);
    };
}
```

7/7 Z3 obligations discharged (load span + 6 shared-array bounds).

## Address-space mapping

| Forge | CUDA | PTX | SASS |
|---|---|---|---|
| `a[gid]` | global ptr deref | `ld.global.u32` | `LDG.E.32` |
| `shared<u32>[32]` | `__shared__ uint32_t smem[32]` | `.shared .u32 smem[32]` | block SMEM |
| `smem[i] = ...` | `smem[i] = ...` | `st.shared.u32` | `STS` |
| `... = smem[i]` | `... = smem[i]` | `ld.shared.u32` | `LDS.32` |
| `syncthreads()` | `__syncthreads()` | `bar.sync 0` | `BAR.SYNC` |
| `atom_add_u32(p, v)` | `atomicAdd(p, v)` | `atom.global.add.u32` | `ATOMG.E.ADD.u32` |

Three distinct address spaces (global, shared, atomic-global) all
exercised in one kernel; six barriers; one atomic per block.

## GPU stress matrix

| run | N | blocks × threads | input pattern | expected sum | actual | result |
|---:|---:|---:|---|---:|---:|:-:|
| 1 | 128 | 4 × 32 | `a[i] = i` | 8 128 | 8 128 | PASS |
| 2 | 128 | 4 × 32 | `a[i] = 1` (max contention) | 128 | 128 | PASS |
| 3 | 512 | 16 × 32 | LCG pseudo-random | 24 035 168 | 24 035 168 | PASS |
| 4 | 1024 | 32 × 32 | `a[i] = i` | 523 776 | 523 776 | PASS |

All 4 runs match CPU reference `sum(a)` exactly.  Run 4 specifically
stresses cross-block atomic correctness: 32 blocks each contribute
their partial sum to `out[0]`; if any contribution were lost or
double-counted, the final sum would be wrong.

## Validation summary

| harness | result |
|---|:-:|
| Forge proof | 7/7 obligations discharged |
| OpenCUDA emit | clean PTX with `.shared`, `bar.sync 0`, `atom.global.add.u32` |
| OpenPTXas → cubin | 7160 bytes |
| GPU stress (4 runs) | **4/4** correct (up to 1024 contributing threads, 32 blocks) |
| OpenPTXas pytest | **865/865** clean |
| OpenPTXas GPU harness | 127 PASS / 10 FAIL / 7 RUN_EXC (unchanged) |
| OpenPTXas frontier | BYTE_EXACT 66 / STRUCTURAL 78 (unchanged) |
| Backend changes | **ZERO** (no OpenPTXas / OpenCUDA / Forge code touched) |

## Capability envelope after FORGE37-40

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
| **multi-block reduction (combined)** | **FORGE37** | **✓** |

This is the **first slice that composes shared mem + barriers +
multi-block atomics in one kernel** and passes end-to-end.  Real-world
GPU reduction kernels (cuBLAS-style) are within reach of the current
Forge envelope.

## Reproduction

```bash
cd /mnt/c/users/kraken/forge
opam exec -- ./_build/default/bin/main.exe cuda demos/1108_forge_multi_block_reduce.fg
cd /mnt/c/users/kraken/opencuda
python -m opencuda /mnt/c/users/kraken/forge/demos/1108_forge_multi_block_reduce.cu --emit-ptx
cd /mnt/c/users/kraken/openptxas
python -c "from sass.pipeline import compile_ptx_source
ptx = open('/mnt/c/users/kraken/forge/demos/1108_forge_multi_block_reduce.ptx').read()
cubin = next(iter(compile_ptx_source(ptx).values()))
open('/mnt/c/users/kraken/forge/demos/1108_forge_multi_block_reduce.cubin','wb').write(cubin)"
# Run on GPU - see harness in this commit for the cuLaunchKernel test.
```
