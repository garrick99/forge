/* G4: NO pre-EXIT LDG. Just ctaid-derived STG post-EXIT.
   If PASS: the pre-EXIT LDG is required to trigger.
   (Already tested as reproF-shape — this one writes per-bx to match reproE.)
*/
#include <cuda_runtime.h>
#include <stdint.h>
extern "C" __global__ void reproG4(uint32_t* out) {
    if (threadIdx.x == 0u) {
        out[blockIdx.x] = 0xAABBCCDDu;
    }
}
