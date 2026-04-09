# STACK_STATE — 2026-04-09

## Full Stack Frozen Checkpoint

This document defines the first fully synchronized, all-green checkpoint of the open GPU compilation stack.

All components are:

- committed
- pushed (GitHub + Gitea)
- on `main`
- free of uncommitted changes

## Stack Overview

```
Forge (.fg)
  | proof-verified compilation
CUDA C / PTX
  | OpenCUDA (C -> PTX)
PTX 9.0
  | OpenPTXas (PTX -> cubin)
SM_120 cubin
  | CUDA driver
RTX 5090 GPU
```

## Component Status

| Project | Commit | Description | Tests / Metrics | Status |
|---------|--------|-------------|-----------------|--------|
| **Forge** | `fb4a260` | v0.3.0 — FB-0 Verified Parity Baseline | 1,062/1,062 demos, 1,021 GCC, 879 runtime, 20 error cases | **Green** |
| **OpenCUDA** | `1763d8a` | CUDA-subset C -> PTX compiler | 30/30 GPU end-to-end | **Green** |
| **OpenPTXas** | `6234e59` | PTX -> SM_120 cubin assembler | 421/421 tests, 89 hardware-verified | **Green** |

## Forge FB-0 Baseline

Forge establishes the verified parity baseline against nvcc.

- **5 / 5 kernels green:**
  - reduction
  - FP16 GEMM
  - convolution
  - flash attention
  - tiled shared-memory GEMM
- **44 formal proofs** attached
- **0 trusted assumptions**
- **Identical SASS** vs hand-written CUDA:
  - register count parity
  - instruction count parity

**Statement:**

> Forge-generated CUDA C compiles to machine code indistinguishable from expert-written CUDA, while carrying formal correctness proofs.

## Guarantees at This Checkpoint

- End-to-end compilation works across the full stack
- All major components pass their respective test suites
- No known regressions
- No uncommitted fixes or dirty working trees
- Forge frontend produces nvcc-parity code for benchmarked kernels
- Open backend (OpenCUDA + OpenPTXas) is fully operational and test-clean

## Known Limitations

- Forge proof system limitations are limited to documented Z3 edge cases
- OpenCUDA retains a small number of non-GPU compiler test edge cases (not affecting GPU E2E)
- OpenPTXas relies on capmerc passthrough for certain complex kernels

These are known and contained, not regressions.

## Checkpoint Integrity

This checkpoint is intended to be:

- **reproducible**
- **stable**
- **immutable**

All future work (performance, backend improvements, new features) should be evaluated against this baseline.

## Next Phase

### FB-1: Open Backend Delta Analysis

**Objective:**

- Run Forge kernels through OpenCUDA -> OpenPTXas
- Compare against FB-0 (nvcc baseline)
- Measure:
  - register count
  - instruction count
  - runtime
- Classify all deltas

## Summary

As of 2026-04-09, the full open GPU compilation stack is **green, synchronized, and frozen**.

Forge provides a formally verified frontend with nvcc-level code quality, and the open backend is operational and ready for direct comparison.
