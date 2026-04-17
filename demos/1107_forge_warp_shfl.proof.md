# Forge → OpenCUDA → OpenPTXas → GPU — Warp Shuffle (FORGE33-36)

**Date**: 2026-04-16
**Hardware**: RTX 5090 (SM_120, Blackwell)
**Status**: **PASS** (32/32 lanes correct, 2 test patterns)

## What this proves

Forge can express intra-warp data movement via `__shfl_xor_sync`,
the canonical building block for warp-level reductions and stencils.
Each lane reads its own `a[tid]` and the value held by lane `tid^1`
in a single SASS instruction — no shared memory, no atomics, no
loops.

## Forge source

```rust
extern fn shfl_xor_sync_u32(val: u32, mask: u32, width: u32) -> u32
    = "forge_gpu";

#[kernel]
fn vec_shfl_pair(a: span<u32>, out: span<u32>, n: u32) {
    let tid: u32 = threadIdx_x;
    if tid < n {
        let x: u32 = a[tid];
        let y: u32 = shfl_xor_sync_u32(x, 1u32, 32u32);
        out[tid] = x + y;
    };
}
```

2/2 Z3 obligations discharged (load + store bounds).

## Forge-side change (one line)

`lib/codegen/codegen_cuda.ml`: added `shfl_xor_sync_u32` →
`__shfl_xor_sync(0xffffffff, ...)` mapping alongside the existing
u64 form.  CUDA's `__shfl_xor_sync` is overloaded; the C++ frontend
resolves to the u32 instantiation from the `uint32_t val` argument.

## Lowering map

| Forge | CUDA | PTX | SASS |
|---|---|---|---|
| `shfl_xor_sync_u32(x, 1, 32)` | `__shfl_xor_sync(0xffffffff, x, 1U, 32U)` | `shfl.sync.bfly.b32 %r4, %r3, 1, 31, 0xffffffff` | `SHFL.IMM` (op `0xf89`) |

The PTX `1` is the lane mask (XOR pattern), `31` is the clamp/width
mask (lower 5 bits = warp size mask), `0xffffffff` is the active-thread
mask.

## Lane mapping (warp = 32 lanes, mask = 1 → pairwise swap)

```
lane:   0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15
       16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
pair:  ↕  ↕  ↕  ↕  ↕  ↕  ↕  ↕  ↕  ↕  ↕  ↕  ↕  ↕  ↕  ↕
       1  0  3  2  5  4  7  6  9  8 11 10 13 12 15 14
       17 16 19 18 21 20 23 22 25 24 27 26 29 28 31 30
```

Each lane `i` reads from lane `i^1`.

## SASS summary (18 active instrs)

```
LDC + S2R + LDCU + ISETP.UR + EXIT @P0  # preamble + tid + bounds guard
LDCU + IMAD.IMM + HFMA2 + LDCU          # address compute (a + tid*4)
IADD.64-UR + LDCU + LDG.E.32             # load a[tid]
IADD.64-UR                               # address compute (out + tid*4)
SHFL.IMM                                 # warp shuffle (lane^1)
IADD.64                                  # x + y
STG                                       # store result
EXIT + BRA
```

The `SHFL.IMM` (op `0xf89`) is the canonical SM_120 SASS for
`shfl.sync.bfly.b32` with immediate XOR mask.

## GPU execution

| run | input pattern | result |
|---:|---|:-:|
| 1 | `a[i] = i` (sequential) | **32 / 32** correct |
| 2 | `a[i] = LCG-pseudo-random` | **32 / 32** correct |

Sample (run 1):
```
tid=0: a[0]+a[1]   = 0+1   =  1 ✓     tid=1: a[1]+a[0]   = 1+0   =  1 ✓
tid=2: a[2]+a[3]   = 2+3   =  5 ✓     tid=3: a[3]+a[2]   = 3+2   =  5 ✓
tid=4: a[4]+a[5]   = 4+5   =  9 ✓     tid=5: a[5]+a[4]   = 5+4   =  9 ✓
tid=6: a[6]+a[7]   = 6+7   = 13 ✓     tid=7: a[7]+a[6]   = 7+6   = 13 ✓
```

Pairwise sums confirm the lane-`i^1` exchange semantics.

## Validation summary

| harness | result |
|---|:-:|
| Forge proof | 2/2 obligations discharged |
| OpenCUDA emit | clean PTX with `shfl.sync.bfly.b32` |
| OpenPTXas → cubin | 5712 bytes, `SHFL.IMM` (op `0xf89`) emitted |
| GPU run (sequential) | 32/32 correct |
| GPU run (pseudo-random) | 32/32 correct |
| OpenPTXas pytest | **865/865** clean |
| OpenPTXas GPU harness | 127 PASS / 10 FAIL / 7 RUN_EXC (unchanged) |
| OpenPTXas frontier | BYTE_EXACT 66 / STRUCTURAL 78 (unchanged) |
| Backend changes | **ZERO** OpenPTXas / OpenCUDA changes; 1 line added to Forge codegen for u32 alias |

## Capability envelope after FORGE33-36

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
| **warp shuffle (lane exchange)** | **FORGE33** | **✓** |

## Reproduction

```bash
cd /mnt/c/users/kraken/forge
opam exec -- ./_build/default/bin/main.exe cuda demos/1107_forge_warp_shfl.fg
cd /mnt/c/users/kraken/opencuda
python -m opencuda /mnt/c/users/kraken/forge/demos/1107_forge_warp_shfl.cu --emit-ptx
cd /mnt/c/users/kraken/openptxas
python -c "from sass.pipeline import compile_ptx_source
ptx = open('/mnt/c/users/kraken/forge/demos/1107_forge_warp_shfl.ptx').read()
cubin = next(iter(compile_ptx_source(ptx).values()))
open('/mnt/c/users/kraken/forge/demos/1107_forge_warp_shfl.cubin','wb').write(cubin)"
# Run on GPU - see harness in this commit for the cuLaunchKernel test.
```
