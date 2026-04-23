#include <cuda_runtime.h>
#include <stdint.h>
/* B01: NO SHFL, NO EXIT, unconditional, store from a local */
extern "C" __global__ void reproB01(uint32_t* out, uint32_t val) {
    out[threadIdx.x] = val;
}
