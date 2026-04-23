/* G3: pre-EXIT LDG, post-EXIT STG at a FIXED offset (not ctaid-derived).
   Exercises whether ctaid-derived post-EXIT address is the issue.
*/
#include <cuda_runtime.h>
#include <stdint.h>
extern "C" __global__ void reproG3(const uint32_t* in, uint32_t* out) {
    uint32_t gid = blockIdx.x * blockDim.x + threadIdx.x;
    uint32_t v = in[gid];
    if (threadIdx.x == 0u) {
        out[0] = v;  /* fixed offset, no address arithmetic */
    }
}
