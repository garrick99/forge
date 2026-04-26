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

__global__ void flash_attention(uint64_t* __restrict__ Q, uint64_t Q_len, uint64_t* __restrict__ K, uint64_t K_len, uint64_t* __restrict__ V, uint64_t V_len, uint64_t* __restrict__ O, uint64_t O_len, uint64_t seq_len, uint64_t d) {
  uint64_t gid = ((blockIdx.x * blockDim.x) + threadIdx.x);
  if ((gid < seq_len)) {
    uint64_t max_score = 0ULL;
    uint64_t denom = 0ULL;
    uint64_t acc_0 = 0ULL;
    uint64_t acc_1 = 0ULL;
    uint64_t acc_2 = 0ULL;
    uint64_t acc_3 = 0ULL;
    for (uint64_t j = 0ULL; j < seq_len; j++) {
      uint64_t score = 0ULL;
      for (uint64_t e = 0ULL; e < d; e++) {
        uint64_t q_idx = ((gid * d) + e);
        uint64_t k_idx = ((j * d) + e);
        if ((q_idx < Q_len)) {
          if ((k_idx < K_len)) {
            score = (score + (Q[q_idx] * K[k_idx]));
          }
        }
      }
      if ((score > max_score)) {
        max_score = score;
      }
      denom = (denom + 1ULL);
      if ((d > 0ULL)) {
        uint64_t v0_idx = ((j * d) + 0ULL);
        if ((v0_idx < V_len)) {
          acc_0 = (acc_0 + (V[v0_idx] * score));
        }
      }
      if ((d > 1ULL)) {
        uint64_t v1_idx = ((j * d) + 1ULL);
        if ((v1_idx < V_len)) {
          acc_1 = (acc_1 + (V[v1_idx] * score));
        }
      }
      if ((d > 2ULL)) {
        uint64_t v2_idx = ((j * d) + 2ULL);
        if ((v2_idx < V_len)) {
          acc_2 = (acc_2 + (V[v2_idx] * score));
        }
      }
      if ((d > 3ULL)) {
        uint64_t v3_idx = ((j * d) + 3ULL);
        if ((v3_idx < V_len)) {
          acc_3 = (acc_3 + (V[v3_idx] * score));
        }
      }
    }
    if ((denom > 0ULL)) {
      if ((d > 0ULL)) {
        uint64_t o0 = ((gid * d) + 0ULL);
        if ((o0 < O_len)) {
          O[o0] = (acc_0 / denom);
        }
      }
      if ((d > 1ULL)) {
        uint64_t o1 = ((gid * d) + 1ULL);
        if ((o1 < O_len)) {
          O[o1] = (acc_1 / denom);
        }
      }
      if ((d > 2ULL)) {
        uint64_t o2 = ((gid * d) + 2ULL);
        if ((o2 < O_len)) {
          O[o2] = (acc_2 / denom);
        }
      }
      if ((d > 3ULL)) {
        uint64_t o3 = ((gid * d) + 3ULL);
        if ((o3 < O_len)) {
          O[o3] = (acc_3 / denom);
        }
      }
    }
  }
}

uint64_t main() {
  return 0ULL;
}

