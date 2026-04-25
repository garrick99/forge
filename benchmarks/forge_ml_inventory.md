# Forge ML kernel inventory

Proof / assume / emission counts for the f32 ML kernel arc (1120-1135), Forge-native demos shipped FORGE70 onward.

| demo | proofs | assumes | CUDA C lines | PTX lines |
|------|-------:|--------:|-------------:|----------:|
| `1120_forge_softmax_rowwise` | 13 | 1 | 254 | 217 |
| `1121_forge_layernorm_rowwise` | 14 | 0 | 248 | 193 |
| `1122_forge_attention_slice` | 30 | 1 | 268 | 218 |
| `1123_forge_tiled_attention` | 26 | 1 | 284 | 328 |
| `1124_forge_fp16_rsqrt` | 2 | 0 | 99 | 53 |
| `1125_forge_hmma_tile` | 3 | 0 | 122 | 50 |
| `1126_forge_bf16_rsqrt` | 2 | 0 | 99 | 53 |
| `1127_forge_fp8_mma` | 3 | 0 | 78 | 50 |
| `1128_forge_rmsnorm` | 8 | 0 | 228 | 124 |
| `1129_forge_gelu` | 2 | 0 | 57 | 62 |
| `1130_forge_silu` | 3 | 0 | 57 | 56 |
| `1131_forge_bf16_rmsnorm` | 8 | 0 | 272 | 127 |
| `1132_forge_bf16_gelu` | 2 | 0 | 101 | 65 |
| `1133_forge_bf16_silu` | 3 | 0 | 101 | 59 |
| `1134_forge_softmax_warp` | 3 | 1 | 221 | 146 |
| `1135_forge_rmsnorm_warp` | 3 | 0 | 217 | 79 |
| **total** | **125** | **4** | | |
