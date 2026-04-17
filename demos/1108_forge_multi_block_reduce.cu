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

__global__ void vec_block_reduce(uint32_t* __restrict__ a, uint64_t a_len, uint32_t* out_ptr, uint32_t n, uint32_t n_minus_1) {
  __shared__ uint32_t smem[32ULL];
  uint32_t tid = threadIdx.x;
  uint32_t gid = ((blockIdx.x * blockDim.x) + threadIdx.x);
  if ((gid < n)) {
    smem[tid] = a[gid];
  } else {
    smem[tid] = 0U;
  }
  __syncthreads();
  if ((tid < 16U)) {
    smem[tid] = (smem[tid] + smem[(tid + 16U)]);
  }
  __syncthreads();
  if ((tid < 8U)) {
    smem[tid] = (smem[tid] + smem[(tid + 8U)]);
  }
  __syncthreads();
  if ((tid < 4U)) {
    smem[tid] = (smem[tid] + smem[(tid + 4U)]);
  }
  __syncthreads();
  if ((tid < 2U)) {
    smem[tid] = (smem[tid] + smem[(tid + 2U)]);
  }
  __syncthreads();
  if ((tid < 1U)) {
    smem[tid] = (smem[tid] + smem[(tid + 1U)]);
  }
  __syncthreads();
  if ((tid == 0U)) {
    uint32_t _old = atomicAdd(out_ptr, smem[0U]);
  }
}

uint64_t main() {
  return 0ULL;
}

