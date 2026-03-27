// Host driver for demo 30: GPU parallel tree reduction
// Compiles and links against the FORGE-generated reduce_sum kernel.
// Validates that the reduction produces the correct sum.

#include <cuda_runtime.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

// Forward-declare the FORGE-generated kernels (from 30_gpu_reduction.cu)
// We include the generated file directly.
#include "30_gpu_reduction.cu"

#define BLOCK_SIZE 256
#define NUM_BLOCKS 64
#define N (NUM_BLOCKS * BLOCK_SIZE)   // 16384 elements

int main(void) {
    printf("FORGE GPU Reduction Demo — RTX 5090\n");
    printf("  Elements: %d (%d blocks x %d threads)\n", N, NUM_BLOCKS, BLOCK_SIZE);

    // Allocate host buffers
    uint64_t *h_src = (uint64_t*)malloc(N * sizeof(uint64_t));
    uint64_t *h_dst = (uint64_t*)malloc(NUM_BLOCKS * sizeof(uint64_t));
    if (!h_src || !h_dst) { fprintf(stderr, "malloc failed\n"); return 1; }

    // Fill source: h_src[i] = i + 1, so each block sums (block*BLOCK_SIZE+1)..(block+1)*BLOCK_SIZE
    uint64_t expected_total = 0;
    for (int i = 0; i < N; i++) {
        h_src[i] = (uint64_t)(i + 1);
        expected_total += h_src[i];
    }
    printf("  Expected total sum: %llu\n", (unsigned long long)expected_total);

    // Allocate device buffers
    uint64_t *d_src, *d_dst;
    cudaMalloc(&d_src, N * sizeof(uint64_t));
    cudaMalloc(&d_dst, NUM_BLOCKS * sizeof(uint64_t));
    cudaMemcpy(d_src, h_src, N * sizeof(uint64_t), cudaMemcpyHostToDevice);

    // Build FORGE span<u64> fat pointers
    forge_span_u64_t src_span = { d_src, (uintptr_t)N };
    forge_span_u64_t dst_span = { d_dst, (uintptr_t)NUM_BLOCKS };

    // Launch kernel — FORGE preconditions are met:
    //   src.len == num_blocks * block_size  ✓
    //   dst.len >= num_blocks               ✓
    //   num_blocks > 0                      ✓
    //   block_size > 0                      ✓
    //   block_size == blockDim_x            ✓ (we launch with BLOCK_SIZE threads)
    reduce_sum<<<NUM_BLOCKS, BLOCK_SIZE>>>(src_span, dst_span,
        (uint64_t)NUM_BLOCKS, (uint64_t)BLOCK_SIZE);
    cudaDeviceSynchronize();

    // Copy results back
    cudaMemcpy(h_dst, d_dst, NUM_BLOCKS * sizeof(uint64_t), cudaMemcpyDeviceToHost);

    // Verify: sum block results
    uint64_t actual_total = 0;
    for (int b = 0; b < NUM_BLOCKS; b++) {
        actual_total += h_dst[b];
    }
    printf("  Actual total sum:   %llu\n", (unsigned long long)actual_total);

    if (actual_total == expected_total) {
        printf("  PASS: sums match!\n");
    } else {
        printf("  FAIL: expected %llu, got %llu\n",
               (unsigned long long)expected_total,
               (unsigned long long)actual_total);
        return 1;
    }

    // Spot-check a few blocks
    printf("  Block 0 sum: %llu (expected %llu)\n",
           (unsigned long long)h_dst[0],
           (unsigned long long)(1 + 2 + 3 + /* ... */ (uint64_t)BLOCK_SIZE * (BLOCK_SIZE + 1) / 2));

    // CUDA error check
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        fprintf(stderr, "CUDA error: %s\n", cudaGetErrorString(err));
        return 1;
    }

    cudaFree(d_src); cudaFree(d_dst);
    free(h_src); free(h_dst);
    printf("  Done.\n");
    return 0;
}
