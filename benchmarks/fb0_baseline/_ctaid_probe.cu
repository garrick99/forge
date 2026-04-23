/* Isolation probe — emit only S2R ctaid + STG to measure if PTXAS-R19
   fallback path is correct in isolation. No SHFL, no guards. */
#include <cuda_runtime.h>
#include <stdint.h>
extern "C" __global__ void ctaid_probe(uint32_t* out) {
    uint32_t bx = blockIdx.x;
    out[bx] = bx;
}
