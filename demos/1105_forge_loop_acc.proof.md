# Forge → OpenCUDA → OpenPTXas → GPU — Per-Thread Loop (FORGE25-28)

**Date**: 2026-04-16
**Hardware**: RTX 5090 (SM_120, Blackwell)
**Status**: **PASS** (254/254 computing threads correct)

## What this proves

Forge can express a **verified per-thread loop** (with `invariant`
+ `decreases` clauses) and the full toolchain compiles + executes
it correctly on GPU.  The loop is a 3-iteration accumulator
`sum += a[tid + i]` for `i ∈ {0,1,2}`.

OpenCUDA emits PTX with **real loop control flow** (labels +
branches + loop-carried movs).  OpenPTXas detects the bounded
trip count and **unrolls the loop** in SASS — 3 explicit LDGs,
no back-edge.  Both representations land at the same correct
GPU output.

## Forge source

```rust
fn vec_loop_acc(a: span<u32>, out: span<u32>, n: u32, n_minus_2: u32)
    requires n <= a.len
    requires n <= out.len
    requires n_minus_2 + 2u32 == n
    requires n > 2u32
{
    let tid: u32 = blockIdx_x * blockDim_x + threadIdx_x;
    if tid < n_minus_2 {
        let mut sum: u32 = 0u32;
        let mut i: u32 = 0u32;
        while i < 3u32
            invariant i <= 3u32
            decreases 3u32 - i
        {
            sum = sum + a[tid + i];
            i = i + 1u32;
        };
        out[tid] = sum;
    };
}
```

5/5 Z3 obligations discharged:
- `while_entry`: invariant holds when entering the loop
- `while_preserved`: invariant preserved across iterations
- `termination`: `decreases 3 - i` reduces each iteration
- 2× `bounds check: span` for `a[tid+i]` and `out[tid]`

## Lowering breakdown

**OpenCUDA emits real loop** (PTX with labels + branches):
```ptx
mov.u32 %r7, 0;            // sum = 0
mov.u32 %r8, 0;            // i = 0
bra while_cond_5;
while_cond_5:
    setp.lt.u32 %p0, %r8, 3;
    @%p0 bra while_body_6;
    bra while_exit_7;
while_body_6:
    add.u32 %r9, %r6, %r8;       // tid + i
    shl.b32 %r10, %r9, 2;
    cvt.u64.u32 %rd3, %r10;
    add.u64 %rd2, %rd0, %rd3;
    ld.global.u32 %r11, [%rd2];   // a[tid+i]
    add.u32 %r12, %r7, %r11;       // sum += loaded
    add.u32 %r13, %r8, 1;          // i += 1
    mov.u32 %r7, %r12;             // loop-carried sum
    mov.u32 %r8, %r13;             // loop-carried i
    bra while_cond_5;
while_exit_7:
    ...
    st.global.u32 [%rd2], %r7;
```

**OpenPTXas unrolls in SASS** (28 active instrs, no back-edge):
```
LDC + S2R + S2UR + LDCUs + IMAD.UR    # preamble + tid
ISETP.UR + EXIT @P0                   # bounds guard
3× (UIADD + IADD.64-UR)               # 3 distinct addresses (tid+0/+1/+2)
3× LDG.E.32                           # 3 loads (one per unrolled iter)
IADD.64-UR + IADD3                    # accumulate sums + build out addr
STG                                   # store result
EXIT + BRA
```

The unrolling is the OpenPTXas backend recognizing the bounded
trip count — this is per-block optimization, not unsafe loop
elimination.

## Value flow

```
i=0 iteration:  load a[tid+0],  sum = 0      + a[tid+0]
i=1 iteration:  load a[tid+1],  sum = sum    + a[tid+1]
i=2 iteration:  load a[tid+2],  sum = sum    + a[tid+2]
exit:           out[tid] = sum
```

Each iteration writes a fresh sum value (loop-carried via PTX `mov`
in non-unrolled form, or via SSA-distinct vregs in unrolled form).
No vreg-reuse corruption (OCUDA01-08 SSA invariant preserved).

## GPU execution

Test inputs: `a[i] = i*5 + 3` for `i ∈ [0, 256)`.
Computing threads: 254 (last 2 threads exit because `tid < n-2 = 254`).

| metric | value |
|---|:-:|
| Threads launched | 256 |
| Threads computing | 254 |
| Correct outputs | **254 / 254** |
| GPU error rate | **0%** |

Sample (first 6 threads):
```
tid=0: a[0]+a[1]+a[2] =  3 +  8 + 13 = 24 ✓
tid=1: a[1]+a[2]+a[3] =  8 + 13 + 18 = 39 ✓
tid=2: a[2]+a[3]+a[4] = 13 + 18 + 23 = 54 ✓
tid=3: a[3]+a[4]+a[5] = 18 + 23 + 28 = 69 ✓
tid=4: a[4]+a[5]+a[6] = 23 + 28 + 33 = 84 ✓
tid=5: a[5]+a[6]+a[7] = 28 + 33 + 38 = 99 ✓
```

## Validation summary

| harness | result |
|---|:-:|
| Forge proof | 5/5 obligations (incl. invariant + termination + bounds) |
| OpenCUDA emit | real loop with branches + loop-carried movs |
| OpenPTXas → cubin | 5880 bytes, 28 active SASS instrs (loop unrolled to 3-LDG straight-line) |
| GPU run | 254/254 correct |
| OpenPTXas pytest | **865/865** clean |
| OpenPTXas GPU harness | 127 PASS / 10 FAIL / 7 RUN_EXC (unchanged) |
| OpenPTXas frontier | BYTE_EXACT 66 / STRUCTURAL 78 (unchanged) |
| Backend changes | **ZERO** (no OpenPTXas/OpenCUDA code touched) |

## What was preserved

The 10 GPU-FAIL kernels in OURS' baseline include several loop-family
tests (k200_xor_reduce, w1_loop_*, etc.). This Forge slice does NOT
regress those — they remain in their pre-existing failure state from
the corpus, untouched by this slice.

## Capability envelope after FORGE25-28

Verified end-to-end through Forge → OpenCUDA → OpenPTXas → GPU:

| family | example slice | status |
|---|---|:-:|
| arithmetic + clamp | FORGE01 | ✓ |
| predicates / branching | FORGE05 | ✓ |
| multi-array memory | FORGE09 | ✓ |
| chained map composition | FORGE13 | ✓ |
| pairwise reduction step | FORGE17 | ✓ |
| shared-mem stage + barrier | FORGE21 | ✓ |
| **bounded per-thread loop** | **FORGE25** | **✓** |

## Reproduction

```bash
cd /mnt/c/users/kraken/forge
opam exec -- ./_build/default/bin/main.exe cuda demos/1105_forge_loop_acc.fg
cd /mnt/c/users/kraken/opencuda
python -m opencuda /mnt/c/users/kraken/forge/demos/1105_forge_loop_acc.cu --emit-ptx
cd /mnt/c/users/kraken/openptxas
python -c "from sass.pipeline import compile_ptx_source
ptx = open('/mnt/c/users/kraken/forge/demos/1105_forge_loop_acc.ptx').read()
cubin = next(iter(compile_ptx_source(ptx).values()))
open('/mnt/c/users/kraken/forge/demos/1105_forge_loop_acc.cubin','wb').write(cubin)"
# Run on GPU - see harness in this commit for the cuLaunchKernel test.
```
