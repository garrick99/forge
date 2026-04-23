/* G7: single u64 param — `out` at c[0][0x380] (16-byte aligned).
   Removes the R22-trigger (non-16-aligned 2nd u64 param). */
#include <cuda_runtime.h>
#include <stdint.h>
extern "C" __global__ void reproG7(uint32_t* out) {
    uint32_t v = out[blockIdx.x * blockDim.x + threadIdx.x];  /* LDG */
    if (threadIdx.x == 0u) {
        out[blockIdx.x] = v;
    }
}
