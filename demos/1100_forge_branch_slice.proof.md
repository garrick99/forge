# Forge → OpenCUDA → OpenPTXas → GPU — Branching Vertical Slice (FORGE05-08)

**Date**: 2026-04-16
**Hardware**: RTX 5090 (SM_120, Blackwell)
**Stack**: zero NVIDIA toolchain dependency at runtime

## What this proves

Forge can express conditional logic that compiles end-to-end through
the open-source toolchain (Forge → OpenCUDA → OpenPTXas → cuLaunchKernel)
and produces correct GPU output for both branch arms.  Direct extension
of FORGE01-04: same pipeline, now with predicate-driven branching.

## Forge source (33 lines)

```rust
fn diff_scaled_u32(a: u32, b: u32) -> u32 {
    if a > b {
        (a - b) * 2u32
    } else {
        (b - a) * 3u32
    }
}

#[kernel]
fn vec_diff_branch(a: span<u32>, b: span<u32>, out: span<u32>, n: u32)
    requires n <= a.len
    requires n <= b.len
    requires n <= out.len
{
    let tid: u32 = blockIdx_x * blockDim_x + threadIdx_x;
    if tid < n {
        out[tid] = diff_scaled_u32(a[tid], b[tid]);
    };
}
```

3/3 proof obligations discharged by Z3 (a/b/out span bounds chain).

## Predicate mapping (PTX → SASS)

| PTX op                 | SASS opcode | predicate guard | role |
|------------------------|------------:|-----------------|------|
| `setp.lt.u32 %p0, tid, n` | 0xc0c | (writes P0) | entry guard |
| `@!%p0 ret`            |       0x94d | @P0 EXIT       | early exit for OOB threads |
| `setp.gt.u32 %p0, a, b`|       0x20c | (writes P0)    | branch decision |
| `@%p0 sub.u32`         |       0x235 (IADD.64+neg) | @P0 | TRUE: a-b |
| `@!%p0 sub.u32`        |       0x235 (IADD.64+neg) | @!P0 | FALSE: b-a |
| `@%p0 mul.lo.u32 r,r,2`|       0x824 (IMAD.IMM) | @P0 | TRUE: *2 |
| `@!%p0 mul.lo.u32 r,r,3`|      0x824 (IMAD.IMM) | @!P0 | FALSE: *3 |
| `st.global.u32`        |       0x986 | (unconditional)| store result |

## SASS summary

27 active instructions (down from 47 in the broken initial attempt).
Both branches use predicated execution; the if-conversion is preserved
where hardware-safe.

```
[19] ISETP.GT.U32 P0, R4, R7        // P0 = (a > b)
[20] @P0  IADD.64 R0:R1 = R4 - R7   // TRUE: a - b
[21] @!P0 IADD.64 R8:R9 = R4 - R7   // FALSE: b - a (operand order)
[22] @P0  IMAD.IMM R9 = R0 * 2      // TRUE: (a-b) * 2
[23] @!P0 IMAD.IMM R9 = R8 * 3      // FALSE: (b-a) * 3
[24] STG.E [R2:R3] = R9
```

## GPU execution

Test inputs covering both branches:
```
i even: a = 2i, b = i+5         (a > b for i > 5)
i odd:  a = i,  b = 2i           (b > a always)
```

Branch coverage: **125 TRUE / 131 FALSE** of 256 threads.

| metric | value |
|---|:-:|
| Threads launched | 256 |
| TRUE-branch correct | 125 / 125 |
| FALSE-branch correct | 131 / 131 |
| Total correct | **256 / 256** |
| GPU error rate | **0%** |

## Validation summary

| harness | result |
|---|:-:|
| Forge proof | 3/3 obligations discharged |
| OpenCUDA emit | clean PTX, 1 kernel |
| OpenPTXas → cubin | 5944 bytes, 27 active SASS instrs |
| GPU run | 256/256 correct |
| pytest (OpenPTXas) | **865/865** |
| GPU harness (OpenPTXas) | 127 PASS / 10 FAIL / 7 RUN_EXC (unchanged) |
| Frontier (OpenPTXas) | BYTE_EXACT 66 / STRUCTURAL 78 (unchanged) |

## Backend bug uncovered + fixed

Initial run produced wrong output: 125/256 errors (all on TRUE-branch
threads).  Root cause: OURS' if-conversion lowered `sub.u32` in the
false branch as `@!P0 IADD3 + negation` (byte 1 = 0x82, byte 7 = 0x80),
a pattern that:

* Zero kernels in OURS' 144-kernel workbench corpus emit
* Zero kernels in PTXAS' equivalent corpus emit
* Hardware-untested — empirically the `@!P` guard was ignored on
  SM_120, so the negated branch always fired regardless of P0

PTXAS works around the same pattern by emitting `IADD.64` (op 0x235)
register-pair subtraction or SEL-based mux instead.  OURS already had
an `IADD.64` codegen path that handles `@!P` correctly; the fix is a
simple `_has_neg_sub` guard in `_if_convert` that skips the broken
Pattern-C conversion when the body contains `sub.{u32,s32,u64,s64}`.
The kernel then either keeps real BRA branches or falls back to the
working IADD.64 path.

Fix shipped in openptxas commit `336600e`.

## Reproduction

```bash
# 1. Forge → CUDA C → PTX
cd /mnt/c/users/kraken/forge
opam exec -- ./_build/default/bin/main.exe cuda demos/1100_forge_branch_slice.fg

# 2. CUDA C → PTX (OpenCUDA)
cd /mnt/c/users/kraken/opencuda
python -m opencuda /mnt/c/users/kraken/forge/demos/1100_forge_branch_slice.cu --emit-ptx

# 3. PTX → cubin (OpenPTXas)
cd /mnt/c/users/kraken/openptxas
python -c "from sass.pipeline import compile_ptx_source
ptx = open('/mnt/c/users/kraken/forge/demos/1100_forge_branch_slice.ptx').read()
cubin = next(iter(compile_ptx_source(ptx).values()))
open('/mnt/c/users/kraken/forge/demos/1100_forge_branch_slice.cubin','wb').write(cubin)"

# 4. Run on GPU - see harness in commit 336600e for the cuLaunchKernel test
```
