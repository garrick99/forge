// FORGE-generated CUDA C — SM_120
// All proofs discharged. Correct by construction.
// No bounds checks. No overflow checks. They were proven away.

#include <stdint.h>
#include <stdbool.h>


__global__ void vec_add(float* __restrict__ src_a, uint64_t src_a_len, float* __restrict__ src_b, uint64_t src_b_len, float* __restrict__ dst, uint64_t dst_len) {
  uint64_t i = ((blockIdx.x * blockDim.x) + threadIdx.x);
  if ((i < dst_len)) {
    dst[i] = (src_a[i] + src_b[i]);
  }
}

__global__ void prefix_sum_step(int32_t* __restrict__ src, uint64_t src_len, int32_t* __restrict__ dst, uint64_t dst_len, uint64_t n) {
  uint64_t i = ((blockIdx.x * blockDim.x) + threadIdx.x);
  if ((i < n)) {
    dst[i] = src[i];
  }
}

__global__ void block_offset_kernel(uint64_t* __restrict__ dst, uint64_t dst_len) {
  uint64_t base = (blockIdx.x * blockDim.x);
  uint64_t tid = threadIdx.x;
  uint64_t i = (base + tid);
  if ((i < dst_len)) {
    dst[i] = i;
  }
}

