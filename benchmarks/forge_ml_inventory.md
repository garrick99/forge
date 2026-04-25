# Forge ML kernel inventory

Proof / assume / emission counts for the f32 ML kernel arc (1120-1135), Forge-native demos shipped FORGE70 onward.

| demo | proofs | assumes | CUDA C lines | PTX lines |
|------|-------:|--------:|-------------:|----------:|
| `1120_forge_softmax_rowwise` | 13 | 1 | 255 | 217 |
| `1121_forge_layernorm_rowwise` | 14 | 0 | 249 | 193 |
| `1122_forge_attention_slice` | 30 | 1 | 269 | 218 |
| `1123_forge_tiled_attention` | 26 | 1 | 285 | 328 |
| `1124_forge_fp16_rsqrt` | 2 | 0 | 100 | 53 |
| `1125_forge_hmma_tile` | 3 | 0 | 119 | 50 |
| `1126_forge_bf16_rsqrt` | 2 | 0 | 100 | 53 |
| `1127_forge_fp8_mma` | 3 | 0 | 79 | 50 |
| `1128_forge_rmsnorm` | 8 | 0 | 229 | 124 |
| `1129_forge_gelu` | 2 | 0 | 62 | 62 |
| `1130_forge_silu` | 3 | 0 | 62 | 56 |
| `1131_forge_bf16_rmsnorm` | 8 | 0 | 269 | 127 |
| `1132_forge_bf16_gelu` | 2 | 0 | 102 | 65 |
| `1133_forge_bf16_silu` | 3 | 0 | 102 | 59 |
| `1134_forge_softmax_warp` | 3 | 1 | 222 | 146 |
| `1135_forge_rmsnorm_warp` | 3 | 1 | 228 | 91 |
| `1136_forge_flash_attention` | 14 | 6 | 263 | 233 |
| `1137_forge_rope` | 4 | 4 | 82 | 74 |
| `1138_forge_causal_softmax` | 3 | 3 | 231 | 168 |
| `1139_forge_softmax_dropout` | 4 | 4 | 238 | 173 |
| `1140_forge_layernorm_affine` | 16 | 0 | 248 | 211 |
| `1141_forge_embedding_gather` | 3 | 4 | 73 | 57 |
| `1142_forge_sinusoidal_pe` | 2 | 2 | 74 | 54 |
| `1143_forge_argmax_row` | 2 | 2 | 231 | 190 |
| `1144_forge_masked_softmax` | 4 | 4 | 236 | 182 |
| `1145_forge_swiglu` | 4 | 0 | 63 | 67 |
| `1146_forge_log_softmax` | 2 | 3 | 228 | 151 |
| `1147_forge_scaled_add` | 3 | 0 | 58 | 64 |
| **total** | **186** | **37** | | |
