# Forge → OpenCUDA → OpenPTXas → GPU — Memory Slice (FORGE09-12) — BLOCKED

**Date**: 2026-04-16
**Hardware**: RTX 5090 (SM_120, Blackwell)
**Status**: **BLOCKED** on deep OpenPTXas regalloc/scheduling bug

## What was attempted

Two variants of a multi-array u32 indexing kernel:

* **4-array variant** (a, b, c, out, n, two_n) — 10 params
* **3-array variant** (a, b, c, n) — 7 params (matching FORGE05-08 layout)

Both variants compile cleanly through Forge (3-4/4 obligations
discharged) and OpenCUDA (clean PTX with proper `setp`, address
arithmetic, `ld.global.u32` / `st.global.u32`). Both fail at GPU
runtime with incorrect outputs.

## Root cause

OpenPTXas register allocator + scheduler interaction:

1. **Regalloc collision**: when PTX reuses a `%rN` vreg for
   semantically-distinct values across `mul.lo` / `add.u32` (e.g.
   `mov %r2, %ntid.x; mul ... ; mov %r2, %tid.x; add ...`), the
   allocator gives both uses the same physical register.
2. **S2R hoist**: the scheduler hoists `S2R R8 = TID` to position 1
   for latency hiding, but a later `LDC R8 = blockDim` (param load)
   overwrites R8 before the IADD3 that needs TID reads it.
3. **mul+add fusion**: when both fusion sources happen to be the same
   vreg (`%r2`), the IMAD fusion combines them assuming consistent
   value, but PTX semantically wrote different values to `%r2`
   between the mul and the add.

Net effect: the global TID compute (`tid_global = blockIdx * blockDim
+ threadIdx`) writes the wrong value, so all threads either early-
exit or write to wrong addresses.

## Bounded fix attempts (all reverted, none successful)

1. **`_has_neg_sub` guard for IMAD fusion** in `sass/isel.py` — added
   check that no source operand is overwritten between mul and add.
   Prevents the bad fusion but the underlying R8-overwrite still
   happens via the standalone IADD3 path.
2. **S2R hoist guard** in `sass/schedule.py` — added check for
   subsequent LDC writing the same dest. Did not fire because the
   conflicting LDC lives in `_preamble_ldcus`, separated from
   `remaining` by the time `schedule.py` runs.
3. **3-array Forge rewrite** — reduced param count to 7. Still fails
   because the same TID-compute pattern triggers the bug.

## Why this is hard to fix bounded

The bug is **structural** in OURS' compilation pipeline:

* PTX-level vreg reuse is correct
* Linear-scan regalloc with live-range coalescing reuses the phys reg
  correctly per liveness
* The scheduler reorders S2R independently of LDC param loads
* The reordering crosses the implicit dependency chain

A correct fix requires coordinated changes across regalloc,
scheduler, and the param-load preamble emitter. This crosses the
"no broad allocator/scheduler rewrite" line of the operating rules
(see `analysis/ALLOC08_DECISION.md`).

## What was NOT touched

Per the bail protocol:
* OpenPTXas backend: ALL changes reverted. State at commit `336600e`
  (post FORGE05-08).
* Validation: pytest 865/865, GPU 127 PASS / 10 FAIL / 7 RUN_EXC,
  frontier BYTE_EXACT 66 / STRUCTURAL 78. **All unchanged.**
* Forge: only the demo `.fg` and emit artifacts added. No Forge
  source change (other demos and the verified pipeline still work).

## Conclusion

**FORGE_MEMORY_BLOCKED.**

Forge's memory-indexing capability is correctly expressed at the
language level and discharged by Z3. The end-to-end execution is
blocked by a backend bug that requires architectural surgery beyond
the bounded-fix scope of this slice.

The successfully-shipped vertical slices (FORGE01-04 vector+clamp,
FORGE05-08 branching) remain valid demonstrations of Forge → OpenCUDA
→ OpenPTXas → GPU end-to-end capability for the **safe envelope**:
arithmetic, predicates, single-array indexing.

Multi-array kernels with 5+ params triggering vreg reuse in the
TID-compute pattern need either:
* Allocator/scheduler subsystem fix (out-of-scope per `ALLOC08`)
* Whole-kernel template (proven mechanism, but defeats the purpose
  of "Forge can express any kernel")
* Manual PTX rewrite to avoid vreg reuse (fragile, not a fix)

## Reproduction

```bash
cd /mnt/c/users/kraken/forge
opam exec -- ./_build/default/bin/main.exe cuda demos/1101_forge_memory_slice.fg
cd /mnt/c/users/kraken/opencuda
python -m opencuda /mnt/c/users/kraken/forge/demos/1101_forge_memory_slice.cu --emit-ptx
# OpenPTXas compile produces a cubin that runs but with wrong outputs
# on RTX 5090.  PTXAS-built equivalent runs correctly, confirming the
# bug is in OURS not in the PTX.
```

## Side-channel evidence: PTXAS works

The same Forge-generated PTX, compiled by PTXAS instead of
OpenPTXas, produces correct GPU output across all test inputs. This
confirms the bug is in OpenPTXas' isel/regalloc/scheduler interaction,
not in Forge or OpenCUDA.
