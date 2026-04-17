# Forge → OpenCUDA → OpenPTXas → GPU — Atomic Add (FORGE29-32)

**Date**: 2026-04-16
**Hardware**: RTX 5090 (SM_120, Blackwell)
**Status**: **PASS** (5/5 stress runs correct under contention)

## What this proves

Forge can express atomic global accumulation correctly through the
full toolchain.  Each thread independently calls
`atomicAdd(&out[0], a[tid])`.  The final value of `out[0]` equals
`sum(a)` exactly, with **zero lost updates** under contention up to
4096 threads × 16 blocks.

## Forge source

```rust
extern fn atom_add_u32(ptr: raw<u32>, val: u32) -> u32 = "forge_gpu";

#[kernel]
fn vec_atomic_sum(a: span<u32>, out_ptr: raw<u32>, n: u32)
    requires n <= a.len
    requires n > 0u32
{
    let tid: u32 = blockIdx_x * blockDim_x + threadIdx_x;
    if tid < n {
        let v: u32 = a[tid];
        let _old: u32 = atom_add_u32(out_ptr, v);
    };
}
```

1/1 Z3 obligation discharged (`tid < a.len` for the load).

## Forge-side change (one line)

`lib/codegen/codegen_cuda.ml`: added `atom_add_u32` → `atomicAdd`
mapping alongside the existing `atom_add` → `atomicAdd` rule.
CUDA's `atomicAdd` is overloaded — the C++ frontend resolves to
the u32 overload from the `uint32_t*` argument.

## Atomic op mapping

| Forge | CUDA C | PTX | SASS (OpenPTXas) |
|---|---|---|---|
| `atom_add_u32(p, v)` | `atomicAdd(p, v)` | `atom.global.add.u32 %ret, [%addr], %v` | `ATOMG.E.{ADD\|MIN\|MAX\|EXCH}.u32` (op `0x9a8`) |

## Stress test results

5 runs with varying input patterns and grid sizes:

| run | N | grid | block | input pattern | expected | actual | result |
|---:|---:|---:|---:|---|---:|---:|:-:|
| 1 | 256 | 1 | 256 | `a[i] = i` | 32640 | 32640 | PASS |
| 2 | 256 | 1 | 256 | `a[i] = 1` | 256 | 256 | PASS |
| 3 | 256 | 1 | 256 | `a[i] = 7i+3` | 229248 | 229248 | PASS |
| 4 | 1024 | 4 | 256 | `a[i] = 2i` | 1047552 | 1047552 | PASS |
| 5 | 4096 | 16 | 256 | `a[i] = 1` | 4096 | 4096 | PASS |

All runs match the CPU reference `sum(a)` exactly.  Run 5 specifically
stress-tests contention: 4096 threads in 16 blocks all simultaneously
hammering `out[0]`; if any update were lost, the final count would be
< 4096.

## Validation summary

| harness | result |
|---|:-:|
| Forge proof | 1/1 obligation discharged |
| OpenCUDA emit | clean PTX with `atom.global.add.u32` |
| OpenPTXas → cubin | 5728 bytes, ATOMG.E.ADD.u32 emitted |
| GPU runs (5×, up to 4096 threads) | 5/5 correct, zero lost updates |
| OpenPTXas pytest | **865/865** clean |
| OpenPTXas GPU harness | 127 PASS / 10 FAIL / 7 RUN_EXC (unchanged) |
| OpenPTXas frontier | BYTE_EXACT 66 / STRUCTURAL 78 (unchanged) |
| Backend changes | **ZERO** OpenPTXas/OpenCUDA changes; 1 line added to Forge codegen for u32-typed atom_add binding |

## Capability envelope after FORGE29-32

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
| **atomic global accumulation** | **FORGE29** | **✓** |

## Reproduction

```bash
cd /mnt/c/users/kraken/forge
opam exec -- ./_build/default/bin/main.exe cuda demos/1106_forge_atomic_add.fg
cd /mnt/c/users/kraken/opencuda
python -m opencuda /mnt/c/users/kraken/forge/demos/1106_forge_atomic_add.cu --emit-ptx
cd /mnt/c/users/kraken/openptxas
python -c "from sass.pipeline import compile_ptx_source
ptx = open('/mnt/c/users/kraken/forge/demos/1106_forge_atomic_add.ptx').read()
cubin = next(iter(compile_ptx_source(ptx).values()))
open('/mnt/c/users/kraken/forge/demos/1106_forge_atomic_add.cubin','wb').write(cubin)"
# Run on GPU - see harness in this commit for the cuLaunchKernel test.
```
