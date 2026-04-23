/* G1: pre-EXIT LDG, post-EXIT STG of a CONSTANT (not the loaded value).
   If this PASSES, the cross-EXIT R10 (loaded data) is implicated.
   If this CRASHES, R10 is NOT the crash cause — something else crosses EXIT.
*/
#include <cuda_runtime.h>
#include <stdint.h>
extern "C" __global__ void reproG1(const uint32_t* in, uint32_t* out) {
    uint32_t gid = blockIdx.x * blockDim.x + threadIdx.x;
    uint32_t v = in[gid];               /* pre-EXIT LDG */
    (void)v;                             /* discard v — don't cross EXIT */
    if (threadIdx.x == 0u) {
        out[blockIdx.x] = 0xAABBCCDDu;  /* store constant, not LDG result */
    }
}
