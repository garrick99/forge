/* G6: compute `out[bx]` ADDRESS pre-EXIT (via pointer arithmetic),
   store it post-EXIT. Isolates post-EXIT address ARITHMETIC from the
   pre-computed cross-EXIT pointer. */
#include <cuda_runtime.h>
#include <stdint.h>
extern "C" __global__ void reproG6(const uint32_t* in, uint32_t* out) {
    uint32_t gid = blockIdx.x * blockDim.x + threadIdx.x;
    uint32_t v = in[gid];
    uint32_t* dst = &out[blockIdx.x];   /* address arithmetic PRE-EXIT */
    if (threadIdx.x == 0u) {
        *dst = v;                        /* use pre-computed address */
    }
}
