/* G8: reproE but with LDG REMOVED — just @!P EXIT + post-EXIT STG@bx */
#include <cuda_runtime.h>
#include <stdint.h>
extern "C" __global__ void reproG8(const uint32_t* in, uint32_t* out) {
    (void)in;
    if (threadIdx.x == 0u) {
        out[blockIdx.x] = 0x12345678u;
    }
}
