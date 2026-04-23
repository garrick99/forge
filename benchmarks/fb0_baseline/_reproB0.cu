#include <cuda_runtime.h>
#include <stdint.h>
/* B0: NO SHFL. tid==0 EXIT + fixed-offset STG. */
extern "C" __global__ void reproB0(uint32_t* out) {
    uint32_t v = 0x5A5A5A5Au;  /* known sentinel */
    if (threadIdx.x == 0u) {
        out[0] = v;
    }
}
