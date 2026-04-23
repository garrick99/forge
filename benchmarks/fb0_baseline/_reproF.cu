#include <cuda_runtime.h>
#include <stdint.h>
/* F: EXIT + STG@ctaid. No LDG, no SHFL. */
extern "C" __global__ void reproF(uint32_t* out) {
    if (threadIdx.x == 0u) {
        out[blockIdx.x] = 0xAABBCCDDu;
    }
}
