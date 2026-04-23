/* G5: pre-EXIT LDG of FIXED address in[0] (all lanes load same), post-EXIT
   STG at ctaid offset. Reduces the pre-EXIT address-compute dependency. */
#include <cuda_runtime.h>
#include <stdint.h>
extern "C" __global__ void reproG5(const uint32_t* in, uint32_t* out) {
    uint32_t v = in[0];                  /* pre-EXIT LDG at fixed offset */
    if (threadIdx.x == 0u) {
        out[blockIdx.x] = v;
    }
}
