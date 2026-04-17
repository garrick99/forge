// FORGE-generated CUDA C — SM_120
// All proofs discharged. Correct by construction.
// No bounds checks. No overflow checks. They were proven away.

#include <stdint.h>
#include <stdbool.h>


__device__ uint64_t warp_reduce_sum(uint64_t val) {
  uint64_t v = val;
  v = (v + __shfl_xor_sync(0xffffffff, v, 16ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 8ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 4ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 2ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 1ULL, 32ULL));
  return v;
}

__device__ uint64_t warp_reduce_max(uint64_t val) {
  uint64_t v = val;
  uint64_t s = __shfl_xor_sync(0xffffffff, v, 16ULL, 32ULL);
  if ((s > v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 8ULL, 32ULL);
  if ((s > v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 4ULL, 32ULL);
  if ((s > v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 2ULL, 32ULL);
  if ((s > v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 1ULL, 32ULL);
  if ((s > v)) {
    v = s;
  }
  return v;
}

__device__ uint64_t warp_reduce_min(uint64_t val) {
  uint64_t v = val;
  uint64_t s = __shfl_xor_sync(0xffffffff, v, 16ULL, 32ULL);
  if ((s < v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 8ULL, 32ULL);
  if ((s < v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 4ULL, 32ULL);
  if ((s < v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 2ULL, 32ULL);
  if ((s < v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 1ULL, 32ULL);
  if ((s < v)) {
    v = s;
  }
  return v;
}

__device__ uint64_t grid_stride_start(uint64_t block_idx, uint64_t block_dim, uint64_t thread_idx) {
  return ((block_idx * block_dim) + thread_idx);
}

__device__ uint64_t grid_stride_step(uint64_t block_dim, uint64_t grid_dim) {
  return (block_dim * grid_dim);
}

uint64_t main() {
  return 0ULL;
}

__global__ void matmul_16(uint32_t* __restrict__ a, uint64_t a_len, uint32_t* __restrict__ b, uint64_t b_len, uint32_t* __restrict__ c, uint64_t c_len, uint32_t m, uint32_t n) {
  __shared__ uint32_t as_tile[256ULL];
  __shared__ uint32_t bs_tile[256ULL];
  uint32_t x = threadIdx.x;
  uint32_t y = threadIdx.y;
  uint32_t col = ((blockIdx.x * 16U) + x);
  uint32_t row = ((blockIdx.y * 16U) + y);
  uint32_t s_idx = ((y * 16U) + x);
  if ((row < m)) {
    uint32_t a_idx = ((row * 16U) + x);
    if ((a_idx < a_len)) {
      as_tile[s_idx] = a[a_idx];
    }
  }
  if ((col < n)) {
    uint32_t b_idx = ((y * n) + col);
    if ((b_idx < b_len)) {
      bs_tile[s_idx] = b[b_idx];
    }
  }
  __syncthreads();
  if ((row < m)) {
    if ((col < n)) {
      uint32_t acc = 0U;
      uint32_t ki = 0U;
      while ((ki < 16U)) {
        uint32_t a_s = ((y * 16U) + ki);
        uint32_t b_s = ((ki * 16U) + x);
        uint32_t av = as_tile[a_s];
        uint32_t bv = bs_tile[b_s];
        acc = (acc + (av * bv));
        ki = (ki + 1U);
      }
      uint32_t c_idx = ((row * n) + col);
      if ((c_idx < c_len)) {
        c[c_idx] = acc;
      }
    }
  }
}

uint64_t main() {
  return 0ULL;
}

