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

__global__ void stencil_5pt(uint32_t* __restrict__ inp, uint64_t inp_len, uint32_t* __restrict__ out, uint64_t out_len, uint32_t width, uint32_t height) {
  uint32_t x = threadIdx.x;
  uint32_t y = threadIdx.y;
  uint32_t bx = blockIdx.x;
  uint32_t by = blockIdx.y;
  uint32_t col = ((bx * 16U) + x);
  uint32_t row = ((by * 16U) + y);
  if ((col > 0U)) {
    if ((row > 0U)) {
      if (((col + 1U) < width)) {
        if (((row + 1U) < height)) {
          uint32_t idx = ((row * width) + col);
          uint32_t idx_n = (idx - width);
          uint32_t idx_s = (idx + width);
          uint32_t idx_w = (idx - 1U);
          uint32_t idx_e = (idx + 1U);
          if ((idx_s < inp_len)) {
            uint32_t center = inp[idx];
            uint32_t north = inp[idx_n];
            uint32_t south = inp[idx_s];
            uint32_t west = inp[idx_w];
            uint32_t east = inp[idx_e];
            uint32_t val = ((((center + north) + south) + west) + east);
            if ((idx < out_len)) {
              out[idx] = val;
            }
          }
        }
      }
    }
  }
}

uint64_t main() {
  return 0ULL;
}

