# VortexSTARK NTT Analysis — Forge Optimization Opportunity

## Current Architecture

VortexSTARK's Circle NTT has 4 components:

### 1. CUDA Butterfly Kernel (`circle_ntt.cu:8-19`)
```cuda
__device__ __forceinline__ void butterfly(uint32_t& v0, uint32_t& v1, uint32_t t) {
    uint32_t tmp = m31_mul(v1, t);
    v1 = m31_sub(v0, tmp);
    v0 = m31_add(v0, tmp);
}
```
- M31 field (Mersenne-31, p = 2^31 - 1)
- 32-bit arithmetic (not 64-bit like Goldilocks)
- Single butterfly: 1 mul + 2 add/sub = 3 field ops
- Inlined via `__forceinline__`

### 2. Layer Kernel (`circle_ntt.cu:22-50`)
```cuda
__global__ void circle_ntt_layer_kernel(data, twiddles, layer_idx, half_n, forward)
```
- One thread per butterfly pair
- Index computation: `h = tid >> layer_idx; l = tid & (stride-1); idx0 = (h << (layer_idx+1)) + l`
- Reads twiddle from `twiddles[h]`
- **No warp shuffles** — all communication via global memory
- **No shared memory** — no intra-block cooperation
- **Launched once per layer** — log2(n) kernel launches per NTT

### 3. Batched Layer Kernel (`circle_ntt.cu:53-87`)
```cuda
__global__ void circle_ntt_batch_layer_kernel(columns, twiddles, layer_idx, half_n, n_cols, forward)
```
- Multi-column: `col_idx = tid / half_n; pair_idx = tid % half_n`
- Division/modulo for column demux (expensive on GPU)
- Same per-layer launch pattern

### 4. Rust FFI Orchestration (`ntt.rs:145-161`)
```rust
pub fn evaluate(d_data, cache) {
    for layer in (0..n_line_layers).rev() {
        cuda_circle_ntt_evaluate(...)  // one kernel launch per layer
    }
    // circle layer
    // cudaDeviceSynchronize()
}
```
- log_n kernel launches + 1 sync
- Twiddle factors pre-computed and cached in GPU memory

## Performance Bottlenecks

### 1. One kernel launch per layer
At log_n=24, that's **24 kernel launches** with implicit synchronization between each.
Kernel launch overhead on RTX 5090: ~5-10µs each = 120-240µs just in launch overhead.
The actual butterfly work at this scale takes ~0.3ms, so launch overhead is 40-80%.

### 2. No warp-level butterflies
Layers with stride < 32 (the innermost ~5 layers) could be done entirely via
`__shfl_xor_sync` without touching global memory. VortexSTARK does them via
global memory reads/writes — **10x slower** for these layers.

### 3. No fused multi-layer kernel
Multiple consecutive layers could be fused into a single kernel launch,
keeping data in registers/shared memory. The current approach writes to
global memory after every layer, then reads it back for the next.

### 4. Integer division in batch kernel
`col_idx = tid / half_n; pair_idx = tid % half_n` — division is 20+ cycles
on GPU. Could be replaced with bitwise ops if half_n is power of 2 (it always is).

## What Forge Could Improve

### Phase 1: Verified drop-in butterfly (immediate)
Replace `butterfly()` and `ibutterfly()` with Forge-verified versions.
Forge proves `result < p` for every output — eliminates the need for
any defensive modular reduction. The M31 field has `p = 2^31 - 1`,
so overflow detection is trivial for Z3.

### Phase 2: Warp-level inner layers (2-3x on inner stages)
For layers where stride ≤ 16, use `shfl_xor_sync` to exchange values
between lanes. This eliminates global memory traffic for the ~5 innermost
layers, which are currently memory-bound.

```forge
#[kernel]
fn ntt_warp_layer(data: span<u32>, n: u32, stride: u32, twiddles: span<u32>)
    requires stride >= 1
    requires stride <= 16
{
    let val = data[tid];
    let partner = shfl_xor_sync(val, stride, 32);
    // butterfly in registers — no global memory
}
```

### Phase 3: Fused multi-layer kernel (2x on full NTT)
Fuse layers into groups that fit in shared memory. For n=2^24 with
block_size=256, the last 8 layers can be fused into a single kernel
using 256 × 4 bytes = 1KB of shared memory.

### Phase 4: Bitwise column demux (batch kernel, 10-20% improvement)
Replace `tid / half_n` and `tid % half_n` with:
```cuda
uint32_t col_idx = tid >> log_half_n;
uint32_t pair_idx = tid & (half_n - 1);
```

## Estimated Impact

| Optimization | NTT Speedup | Prove Speedup | Effort |
|-------------|-------------|---------------|--------|
| Verified butterfly | 0% (same perf) | 0% | Low — proves correctness |
| Warp inner layers | 2-3x on layers 0-4 | 10-15% | Medium |
| Fused multi-layer | 2x overall NTT | 30-40% | High |
| Bitwise batch demux | 10-20% batch NTT | 5-10% | Low |
| **Combined** | **3-4x NTT** | **40-60% prove** | |

At log_n=28, current NTT takes ~1.2s per 8 columns. With all optimizations,
estimated: ~0.3-0.4s. Since NTT is ~65% of total prove time at this scale,
that's a **30-40% reduction in total prove time**.

## Concrete Next Step

Write a Forge-verified M31 butterfly that generates CUDA C matching
VortexSTARK's `butterfly()` signature exactly. Benchmark it as a
drop-in replacement. If performance matches (it should — the generated
code is identical), the value is pure correctness: every butterfly
output is mathematically guaranteed to be a valid M31 field element.
