# FB-0: Verified Parity Lane — Baseline Manifest

**Date:** 2026-04-09
**GPU:** RTX 5090 (SM_120, Blackwell)
**CUDA:** 13.2 (nvcc V13.2.51)
**Driver:** 595.79
**Forge:** commit TBD

## Headline

Forge-generated CUDA C matches hand-written CUDA at the SASS level across 5
kernel classes: identical register count, identical instruction count, 44 formal
proofs discharged, 0 trusted assumptions.

## Kernels

| Kernel | Registers | Instructions | SASS Lines | Proofs | Assumes |
|--------|-----------|-------------|------------|--------|---------|
| reduce_sum | 18 | 169 | 436 | 3 | 0 |
| fp16_gemm | 40 | 460 | 680 | 5 | 0 |
| conv2d | 34 | 342 | 564 | 7 | 0 |
| flash_attention | 40 | 895 | 1161 | 18 | 0 |
| tiled_smem_gemm | 48 | 374 | 607 | 11 | 0 |
| **Total** | | | | **44** | **0** |

## Verified Properties (44 proofs)

- Array bounds: all `data[]`, `A[]`, `B[]`, `C[]`, `Q[]`, `K[]`, `V[]`, `O[]` accesses proven in-bounds
- Shared memory bounds: all `smem[]` accesses proven < declared size
- Division safety: all `/` and `%` operands proven non-zero
- Loop termination: all for-loops proven terminating (constant bounds)
- Grid-stride safety: `blockIdx_x < gridDim_x` from requires clauses

## Source Hashes (SHA-256)

```
15cbe7c42111d5a212d7ba9a775f680cffac685577f9e463f867febadc698764  1046_multi_reduction.fg
ca8bc308118107c28689afec0d14d53d8321d55057c3d7c117ddea04a5a612b2  1047_fp16_gemm.fg
60c5c1a1465db77c8fba7d611e8aa5e0575e2d6ab9e799025adef8d055e0f2fd  1048_conv2d.fg
a8537013e07dde85eba5b001bf1615a25054604301350118184b1a5e5a77cfdd  1049_flash_attention.fg
6ab79d3704689fc03522c3b38866f5f429f9348587660490a616c08cb818896f  1050_tiled_smem_gemm.fg
```

## Cubin Hashes (SHA-256, nvcc sm_120)

```
64c713f0592d2ad2d1afc4609388415d04269ec2295e909318aafa19d5470444  1046_multi_reduction.cubin
d6085b7e076986b946610991c0e053fc26f96a9000789a6f66f6573d222b0773  1047_fp16_gemm.cubin
490ab4cdd02869609c464b5f4715ae8ba9b6ce3ad57786b327e172e01a4cc325  1048_conv2d.cubin
eefd6680f75f94b983971a8753c2f863c6e909c421f1115849268626c99e251a  1049_flash_attention.cubin
87e61c33ec572dc6bda8c1372336129a436c60fec2af8a50a0fad8f773c5169f  1050_tiled_smem_gemm.cubin
```

## Files in this baseline

- `*.fg` — Forge source (verified, proof-carrying)
- `*.cu` — Generated CUDA C (from `forge build`)
- `*_clean.cu` — Main-stripped for nvcc compilation
- `*.cubin` — nvcc-compiled cubins (SM_120)
- `*.sass` — nvdisasm SASS disassembly
- `results.json` — ForgeBench structured output
- `report.txt` — Human-readable comparison report
