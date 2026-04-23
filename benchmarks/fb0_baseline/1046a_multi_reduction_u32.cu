/* FB-1 Phase A pilot — u32-narrowed derivative of 1046_multi_reduction.
 *
 * Purpose: smallest kernel that exercises the same reduction/shuffle
 * topology as 1046 but in u32 only, so the FB-1 open lane (OpenCUDA ->
 * OpenPTXas -> cubin -> GPU) can be proven without hitting the known
 * ALLOC01-08 IADD.64-UR-pairing boundary in OpenPTXas.
 *
 * Topology mirrors 1046 exactly:
 *   - one u32 load per thread (or 0 if out of range)
 *   - 5-step warp butterfly reduction via __shfl_xor_sync
 *   - lane 0 of warp 0 writes the per-block result
 *
 * This is a pilot / derivative, not a new benchmark concept.
 */

#include <cuda_runtime.h>
#include <stdint.h>

extern "C" __global__ void reduce_sum_u32(
    const uint32_t* __restrict__ data,
    uint32_t n,
    uint32_t* __restrict__ output)
{
    uint32_t tid = threadIdx.x;
    uint32_t bx  = blockIdx.x;
    uint32_t gid = bx * blockDim.x + tid;

    uint32_t val = 0u;
    if (gid < n) {
        val = data[gid];
    }

    val = val + __shfl_xor_sync(0xffffffffu, val, 16, 32);
    val = val + __shfl_xor_sync(0xffffffffu, val,  8, 32);
    val = val + __shfl_xor_sync(0xffffffffu, val,  4, 32);
    val = val + __shfl_xor_sync(0xffffffffu, val,  2, 32);
    val = val + __shfl_xor_sync(0xffffffffu, val,  1, 32);

    /* Pilot caller sizes `output` to gridDim.x exactly, so no explicit
       `bx < output_len` guard is needed. Dropping the output_len
       param also keeps the backend preamble free of a param-LDC that
       collided with S2R R_tid in the three-u32-param layout. */
    if (tid == 0u) {
        output[bx] = val;
    }
}
