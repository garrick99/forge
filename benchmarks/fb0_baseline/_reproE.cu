#include <cuda_runtime.h>
#include <stdint.h>
/* E: LDG + EXIT + STG@ctaid but NO SHFL. */
extern "C" __global__ void reproE(const uint32_t* in, uint32_t* out) {
    uint32_t gid = blockIdx.x * blockDim.x + threadIdx.x;
    uint32_t v = in[gid];
    if (threadIdx.x == 0u) {
        out[blockIdx.x] = v;
    }
}
