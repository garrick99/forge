#include <cuda_runtime.h>
#include <stdint.h>
extern "C" __global__ void reproB(uint32_t* out) {
    uint32_t v = threadIdx.x;
    v += __shfl_xor_sync(0xffffffffu, v, 16, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  8, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  4, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  2, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  1, 32);
    if (threadIdx.x == 0u) {
        out[0] = v;  /* fixed offset; no ctaid */
    }
}
