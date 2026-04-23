/* PTXAS-R20 reproducer ladder.
   Each kernel adds ONE ingredient of the FB-1 pilot failure.
   All launched as 1 block × 32 threads (single warp). */
#include <cuda_runtime.h>
#include <stdint.h>

/* A — SHFL + unconditional STG (control; all lanes write).
       Known PASS in `_shfl_isolation.cu`. */
extern "C" __global__ void reproA_shfl_all_store(uint32_t* out) {
    uint32_t v = threadIdx.x;
    v += __shfl_xor_sync(0xffffffffu, v, 16, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  8, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  4, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  2, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  1, 32);
    out[threadIdx.x] = v;
}

/* B — SHFL + tid==0 @!P EXIT + STG at fixed offset 0.
       Adds divergent EXIT after SHFL. No ctaid. */
extern "C" __global__ void reproB_shfl_exit_store0(uint32_t* out) {
    uint32_t v = threadIdx.x;
    v += __shfl_xor_sync(0xffffffffu, v, 16, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  8, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  4, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  2, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  1, 32);
    if (threadIdx.x == 0u) {
        out[0] = v;
    }
}

/* C — SHFL + tid==0 @!P EXIT + STG at ctaid offset.
       Adds ctaid-driven address computation after divergent EXIT. */
extern "C" __global__ void reproC_shfl_exit_store_bx(uint32_t* out) {
    uint32_t v = threadIdx.x;
    v += __shfl_xor_sync(0xffffffffu, v, 16, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  8, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  4, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  2, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  1, 32);
    if (threadIdx.x == 0u) {
        out[blockIdx.x] = v;
    }
}

/* D — load + SHFL + tid==0 EXIT + STG at ctaid.
       Adds a global load before the SHFL (same as the pilot). */
extern "C" __global__ void reproD_ldg_shfl_exit_store_bx(
    const uint32_t* __restrict__ in,
    uint32_t* __restrict__ out)
{
    uint32_t gid = blockIdx.x * blockDim.x + threadIdx.x;
    uint32_t v = in[gid];
    v += __shfl_xor_sync(0xffffffffu, v, 16, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  8, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  4, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  2, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  1, 32);
    if (threadIdx.x == 0u) {
        out[blockIdx.x] = v;
    }
}
