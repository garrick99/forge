#include <cuda_runtime.h>
#include <stdint.h>
extern "C" __global__ void reproD(const uint32_t* __restrict__ in, uint32_t* __restrict__ out) {
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
