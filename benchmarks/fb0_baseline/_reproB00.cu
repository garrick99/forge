#include <cuda_runtime.h>
#include <stdint.h>
/* B00: NO SHFL, NO EXIT. All threads write immediate. */
extern "C" __global__ void reproB00(uint32_t* out) {
    out[threadIdx.x] = 0x5A5A5A5Au;
}
