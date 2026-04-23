/* G2: pre-EXIT LDG, STG BEFORE the EXIT (no EXIT between load & store).
   If PASS: crash requires EXIT BETWEEN load and store.
*/
#include <cuda_runtime.h>
#include <stdint.h>
extern "C" __global__ void reproG2(const uint32_t* in, uint32_t* out) {
    uint32_t gid = blockIdx.x * blockDim.x + threadIdx.x;
    uint32_t v = in[gid];
    if (threadIdx.x == 0u) {
        out[blockIdx.x] = v;
    }
    /* no EXIT before STG */
}
