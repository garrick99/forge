/* Isolation probe for FB-1 Phase A pilot debug.
   Minimal warp-reduce kernel — NO guards, NO partial-block loads.
   Every lane writes its final reduced value.
*/
#include <cuda_runtime.h>
#include <stdint.h>

extern "C" __global__ void test_shfl_only(uint32_t* out) {
    uint32_t v = threadIdx.x;
    v += __shfl_xor_sync(0xffffffffu, v, 16, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  8, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  4, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  2, 32);
    v += __shfl_xor_sync(0xffffffffu, v,  1, 32);
    out[threadIdx.x] = v;
}
