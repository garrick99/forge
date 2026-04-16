# Forge → OpenCUDA → OpenPTXas → GPU — End-to-End Proof Artifact

**Date**: 2026-04-16
**Hardware**: RTX 5090 (SM_120, Blackwell)
**Stack**: zero NVIDIA toolchain dependency at runtime
(only used `ptxas` for ground-truth comparison during dev)

## What this proves

A formally-verified Forge program compiles end-to-end to executable
GPU code through a 100% open-source toolchain (Forge → OpenCUDA →
OpenPTXas → cuLaunchKernel) and produces correct GPU output, with
**zero use of NVIDIA's `ptxas`** in the pipeline that produced the
shipped cubin.

## Pipeline

```
1099_forge_e2e_slice.fg         (Forge source — 36 lines, formally verified)
    │
    │  forge cuda  (OCaml, ~620 lines codegen_ptx.ml)
    │  - parse + typecheck
    │  - 3 proof obligations discharged by Z3
    ▼
1099_forge_e2e_slice.cu         (CUDA C with proven bounds)
    │
    │  python -m opencuda --emit-ptx  (~6k lines of pure Python)
    │  - SSA IR + per-block opt
    │  - linear-scan register allocator
    ▼
1099_forge_e2e_slice.ptx        (PTX 9.0, sm_120, 44 lines)
    │
    │  python: openptxas pipeline (~30k lines of pure Python)
    │  - isel + scoreboard + scheduler + encoder
    │  - SM_120 cubin emitter
    ▼
1099_forge_e2e_slice.cubin      (5144 bytes ELF cubin)
    │
    │  cuLaunchKernel via nvcuda.dll
    ▼
GPU output: out[i] = clamp((i + i*7) ^ 0xDEADBEEF * 3, 0, 1024)
```

## Forge source (36 lines)

```rust
use std::gpu;

fn compute_clamp_u32(a: u32, b: u32) -> u32 {
    let x: u32 = a + b;
    let y: u32 = x ^ 0xDEADBEEFu32;
    let z: u32 = y * 3u32;
    if z > 1024u32 { 1024u32 } else { z }
}

#[kernel]
fn vec_compute_clamp(a: span<u32>, b: span<u32>, out: span<u32>, n: u32)
    requires n <= a.len
    requires n <= b.len
    requires n <= out.len
{
    let tid: u32 = blockIdx_x * blockDim_x + threadIdx_x;
    if tid < n {
        out[tid] = compute_clamp_u32(a[tid], b[tid]);
    };
}
```

## Instruction mapping (high-level → SASS)

| Forge op           | PTX op                    | SASS opcode | SM_120 mnemonic |
|--------------------|---------------------------|------------:|-----------------|
| `tid = bid*bd+tid` | `mad.lo.u32`              |       0xc24 | IMAD.UR         |
| `if tid < n`       | `setp.lt.u32` + `@!p ret` |       0x20c | ISETP.LT.U32    |
| `a[tid]` load      | `ld.global.u32`           |       0x981 | LDG.E           |
| `a + b`            | `add.u32`                 |       0x210 | IADD3           |
| `^ 0xDEADBEEF`     | `xor.b32 ...imm`          |       0x812 | LOP3.IMM        |
| `* 3`              | `mul.lo.u32 ...imm`       |       0x824 | IMAD.IMM        |
| `if z > 1024`      | `setp.gt.u32 ...imm`      |       0x80c | ISETP.IMM.GT.U32|
| `then 1024`        | `@p mov.u32 r, 1024`      |       0x810 | LEA.IMM (@P0)   |
| `else z`           | `@!p mov.u32 r, z`        |       0x210 | IADD3   (@!P0)  |
| `out[tid] = r`     | `st.global.u32`           |       0x986 | STG.E           |
| `ret`              | `ret`                     |       0x94d | EXIT            |

## Proof of correctness

### Static (Z3-discharged at Forge compile time)

3 obligations proved automatically by Z3:
- `tid < a.len` (load bounds)
- `tid < b.len` (load bounds)
- `tid < out.len` (store bounds)

All 3 chain via `tid < n` (from the entry guard) + `n <= X.len` (from
the `requires` clauses).

### Dynamic (GPU runtime, OURS cubin)

- **Test inputs**: `a[i] = i`, `b[i] = i*7` for `i ∈ [0, 256)`.
- **Per-thread expected**: `e = clamp((i + i*7) ^ 0xDEADBEEF * 3, 0, 1024)`.
- **Result**: 256 / 256 outputs match expected.

For `i = 0`: `(0 + 0) ^ 0xDEADBEEF = 0xDEADBEEF`; `* 3 = 0x9C093CCD = 2617851085`;
this is `> 1024` so `e = 1024`. GPU output: `1024` ✓.

## Validation summary

| component        | result |
|------------------|:------:|
| Forge proof      | 3/3 obligations discharged |
| OpenCUDA → PTX   | clean PTX, 1 kernel emitted |
| OpenPTXas → cubin| 5144-byte cubin, 43 active SASS instrs |
| GPU run          | 256/256 threads correct |
| pytest (backend) | **865/865** passing |
| GPU harness      | 127 PASS / 10 FAIL / 7 RUN_EXC (unchanged baseline) |
| Frontier         | BYTE_EXACT 66 / STRUCTURAL 78 (unchanged) |

## What is supported

- u32 arithmetic (add / sub / mul / xor / and / or / shift)
- u32 comparisons (setp.lt/gt/le/ge/eq/ne, signed AND unsigned)
- Predicated mov (`@P mov`, `@!P mov`)
- Predicated branches (`@P ret`, `@P bra`)
- Per-thread index compute (TID / blockIdx / blockDim)
- 64-bit address arithmetic (cvt + shl + add for span addressing)
- Coalesced loads / stores (`ld.global.u32`, `st.global.u32`)

## What is intentionally excluded from this slice

- u64 arithmetic body (avoids the IADD.64 / IMAD.WIDE family — see
  `analysis/ALLOC08_DECISION.md`; that subsystem requires allocator
  rewrite which is out of scope per current operating rules)
- HFMA2 zero-init idiom (PTXAS-specific, not modeled in OURS)
- Loops (avoid back-edge / unrolling complexity)
- Atomics (out-of-scope per operating rules)
- Floating point

## Backend bugs uncovered + fixed by this slice

Both bugs were **latent** — the 865-test corpus never triggered them
because no corpus PTX exercised the specific shapes Forge emits.

1. **`setp.gt.u32` silently emitted as signed comparison.**
   `encode_isetp_imm` defaults to `signed=True`; the dispatcher never
   derived signedness from `instr.types`. For values < 2^31 signed
   and unsigned compare identically — the bug stayed dormant. Forge's
   `clamp((a+b)^0xDEADBEEF*3, 0, 1024)` produced values ≥ 2^31 which
   surfaced the bug.

2. **`_select_mov` ignored `instr.pred`.** Forge emits separate
   `@P mov` / `@!P mov` pairs for clamp selection; OURS lowered both
   as unconditional, so the second always overwrote the first. The
   corpus uses `selp` instead.

Both fixes are in commit `b461321` (openptxas). Plus a Forge-side
fix in `lib/codegen/codegen_cuda.ml` to emit `U` (u32) suffix instead
of `ULL` (u64) for u32-typed integer literals — without this, OpenCUDA
would have promoted the entire u32 chain to u64.

## Reproducing

```bash
# 1. Forge → CUDA C → PTX
cd /mnt/c/users/kraken/forge
opam exec -- ./_build/default/bin/main.exe cuda demos/1099_forge_e2e_slice.fg

# 2. CUDA C → PTX (OpenCUDA, redundant but verifies)
cd /mnt/c/users/kraken/opencuda
python -m opencuda /mnt/c/users/kraken/forge/demos/1099_forge_e2e_slice.cu --emit-ptx

# 3. PTX → cubin (OpenPTXas)
cd /mnt/c/users/kraken/openptxas
python -c "from sass.pipeline import compile_ptx_source
ptx = open('/mnt/c/users/kraken/forge/demos/1099_forge_e2e_slice.ptx').read()
cubin = next(iter(compile_ptx_source(ptx).values()))
open('/mnt/c/users/kraken/forge/demos/1099_forge_e2e_slice.cubin','wb').write(cubin)"

# 4. Run on GPU (Windows: nvcuda.dll, Linux: libcuda.so)
# See harness in commit b461321 for the cuLaunchKernel invocation.
```
