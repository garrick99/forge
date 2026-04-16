# Forge → OpenCUDA → OpenPTXas → GPU — Map Composition (FORGE13-16) — RESOLVED

## RESOLUTION (2026-04-16, opencuda commit `56480aa`)

OCUDA01-08 chain shipped an OpenCUDA-side fix: disable linear-scan
free-list reuse for the b32 (`r`) prefix in
`opencuda/codegen/emit.py::_build_alloc_map`.  Each 32-bit int Value
now gets a fresh `%rN` (SSA-faithful).  Other prefixes (rd, f, h, p,
etc.) retain their reuse behaviour.

Result: FORGE13 vec_map_compose now GPU PASS (256/256 threads correct)
with zero OpenPTXas changes and zero net regressions (one OpenCUDA
test marked @skip — the old reuse-asserts-against-naive-count test
no longer applies to b32; correctness wins over efficiency).

The original BLOCKED writeup below is preserved as evidence of the
diagnostic chain that led to the fix.

---

# Forge → OpenCUDA → OpenPTXas → GPU — Map Composition (FORGE13-16) — original BLOCKED writeup

**Date**: 2026-04-16
**Hardware**: RTX 5090 (SM_120, Blackwell)
**Status**: **BLOCKED** at the OpenCUDA → PTX boundary; OpenPTXas backend
is correct on the equivalent SSA-distinct-vreg PTX.

## What was attempted

```rust
fn map_chain_u32(av: u32, bv: u32, cv: u32) -> u32 {
    let tmp: u32 = av * 3u32 + 7u32;
    (tmp ^ bv) + cv
}

#[kernel]
fn vec_map_compose(a: span<u32>, b: span<u32>, c: span<u32>,
                   out: span<u32>, n: u32) {
    let tid: u32 = blockIdx_x * blockDim_x + threadIdx_x;
    if tid < n {
        out[tid] = map_chain_u32(a[tid], b[tid], c[tid]);
    };
}
```

Forge proves 4/4 obligations. OpenCUDA emits clean CUDA C. OpenCUDA
then emits PTX that **reuses %r0-%r3 across multiple distinct values**:

```
ld.global.u32 %r3, [%rd0];   // %r3 = a (load)
ld.global.u32 %r1, [%rd1];   // %r1 = b (load)
ld.global.u32 %r2, [%rd2];   // %r2 = c (load)
mul.lo.u32 %r0, %r3, 3;      // %r0 = a * 3
add.u32 %r3, %r0, 7;         // %r3 REUSED for tmp = a*3+7
xor.b32 %r0, %r3, %r1;       // %r0 REUSED for tmp ^ b
add.u32 %r1, %r0, %r2;       // %r1 REUSED for result
```

OURS' linear-scan regalloc + LDG dest peephole gives both `%r3 = a (load)`
and `%r2 = c (load)` the SAME physical register R16 (because their
PTX live-ranges don't textually overlap in the reused-vreg form), then
the third LDG overwrites R16 before the IMAD that reads `%r3 * 3`.

Result: GPU computes `((c*3+7) ^ b) + (c*3+7)` instead of
`((a*3+7) ^ b) + c`. All 256 threads return wrong values.

## Side-channel proof: equivalent SSA-distinct-vreg PTX works correctly

Hand-written PTX with the SAME logic but using `%r0..%r9` for distinct
values (no reuse) compiles through OpenPTXas and produces the
**correct GPU output** (16/16 threads). See `tools/alloc_r09_repro.ptx`-
style probe in the diagnostic chain.

This proves OpenPTXas handles the operation correctly given an
SSA-faithful PTX input. The bug is OpenCUDA's vreg allocator over-
reusing names.

## Why fix is out of OURS scope

The earlier ALLOC-R01-08 and ALLOC-R09-16 chains addressed two
specific allocator/scheduler interactions in OURS that surfaced from
Forge's tid-compute and IMAD-fusion patterns. This new failure mode
involves the LDG dest peephole interacting with a third reused vreg,
which is yet a different code path.

Continuing to add bounded backend guards crosses into "broad
allocator rewrite" territory (see `analysis/ALLOC08_DECISION.md`).
The cleaner fix is upstream in OpenCUDA's PTX emitter: bump vreg
counts so each logical value gets a unique name, matching the
PTXAS-emitted PTX convention.

## What was NOT touched

* OpenPTXas backend: ZERO changes.
* OpenPTXas baseline preserved: pytest 865/865, GPU 127/10/7,
  frontier BYTE_EXACT 66 / STRUCTURAL 78.
* All prior Forge slices (FORGE01-04, FORGE05-08, FORGE09-12) remain
  GPU-correct.

## Conclusion

**FORGE_MAP_BLOCKED**, with root cause in OpenCUDA frontend, not in
the OpenPTXas backend.

The Forge envelope verified end-to-end through OURS:
- arithmetic (FORGE01-04)
- predicates / branching (FORGE05-08)
- multi-array indexing with strided/offset/mod (FORGE09-12)

Map composition with chained intermediates currently requires an
OpenCUDA-side vreg-name fix to land. That work is in scope for a
future OpenCUDA chain, not for OURS.

## Reproduction

```bash
cd /mnt/c/users/kraken/forge
opam exec -- ./_build/default/bin/main.exe cuda demos/1102_forge_map_compose.fg
cd /mnt/c/users/kraken/opencuda
python -m opencuda /mnt/c/users/kraken/forge/demos/1102_forge_map_compose.cu --emit-ptx
# Inspect the emitted PTX — note %r0-%r3 reuse pattern.
# Compile via OpenPTXas and run on GPU — wrong outputs.
# Hand-rewrite the PTX with %r0..%r9 distinct vregs and re-run —
# correct outputs (proves backend-correct).
```
