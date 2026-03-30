/*
 * Forge GPU Benchmark — RTX 5090 Performance Test
 *
 * Compiles the Forge-verified kernels and benchmarks them.
 * Measures: throughput (GB/s), latency, GFLOPS.
 */

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

/* Include the Forge-verified kernels */
#define main forge_main_unused
#include "kernels.cu"
#undef main

#define CHECK_CUDA(call) do { \
    cudaError_t err = call; \
    if (err != cudaSuccess) { \
        fprintf(stderr, "CUDA error at %s:%d: %s\n", __FILE__, __LINE__, \
                cudaGetErrorString(err)); \
        exit(1); \
    } \
} while(0)

/* Timer */
typedef struct {
    cudaEvent_t start, stop;
} gpu_timer_t;

void timer_create(gpu_timer_t *t) {
    cudaEventCreate(&t->start);
    cudaEventCreate(&t->stop);
}

void timer_start(gpu_timer_t *t) {
    cudaEventRecord(t->start, 0);
}

float timer_stop(gpu_timer_t *t) {
    float ms;
    cudaEventRecord(t->stop, 0);
    cudaEventSynchronize(t->stop);
    cudaEventElapsedTime(&ms, t->start, t->stop);
    return ms;
}

void timer_destroy(gpu_timer_t *t) {
    cudaEventDestroy(t->start);
    cudaEventDestroy(t->stop);
}

/* Benchmark runner */
void run_bench(const char *name, int n_elements, int block_size,
               int n_warmup, int n_iter, float bytes_per_elem,
               void (*launch)(int, int, int)) {
    gpu_timer_t timer;
    timer_create(&timer);

    /* Warmup */
    for (int i = 0; i < n_warmup; i++)
        launch(n_elements, block_size, 0);
    CHECK_CUDA(cudaDeviceSynchronize());

    /* Benchmark */
    timer_start(&timer);
    for (int i = 0; i < n_iter; i++)
        launch(n_elements, block_size, 0);
    float ms = timer_stop(&timer);
    float avg_ms = ms / n_iter;

    float gb = (float)n_elements * bytes_per_elem / 1e9f;
    float gbps = gb / (avg_ms / 1000.0f);

    printf("  %-20s  %8.3f ms  %8.2f GB/s  (%d M elements)\n",
           name, avg_ms, gbps, n_elements / 1000000);

    timer_destroy(&timer);
}

/* Global device pointers */
static uint64_t *d_a, *d_b, *d_c;
static uint64_t *d_result;
static int N;

/* Launch wrappers */
void launch_vec_add(int n, int bs, int dummy) {
    int grid = (n + bs - 1) / bs;
    forge_span_u64_t sa = { d_a, (size_t)n };
    forge_span_u64_t sb = { d_b, (size_t)n };
    forge_span_u64_t sc = { d_c, (size_t)n };
    bench_vec_add<<<grid, bs>>>(sa, sb, sc, (uint64_t)n);
}

void launch_saxpy(int n, int bs, int dummy) {
    int grid = (n + bs - 1) / bs;
    forge_span_u64_t sx = { d_a, (size_t)n };
    forge_span_u64_t sy = { d_b, (size_t)n };
    bench_saxpy<<<grid, bs>>>(sx, sy, 42, (uint64_t)n);
}

void launch_vec_mul(int n, int bs, int dummy) {
    int grid = (n + bs - 1) / bs;
    forge_span_u64_t sa = { d_a, (size_t)n };
    forge_span_u64_t sb = { d_b, (size_t)n };
    forge_span_u64_t sc = { d_c, (size_t)n };
    bench_vec_mul<<<grid, bs>>>(sa, sb, sc, (uint64_t)n);
}

void launch_memcpy(int n, int bs, int dummy) {
    int grid = (n + bs - 1) / bs;
    forge_span_u64_t ss = { d_a, (size_t)n };
    forge_span_u64_t sd = { d_b, (size_t)n };
    bench_memcpy<<<grid, bs>>>(ss, sd, (uint64_t)n);
}

void launch_reduce(int n, int bs, int dummy) {
    int grid = (n + bs - 1) / bs;
    forge_span_u64_t sd = { d_a, (size_t)n };
    CHECK_CUDA(cudaMemset(d_result, 0, sizeof(uint64_t)));
    bench_reduce_sum<<<grid, bs>>>(sd, (uint64_t)n, (uint64_t)d_result);
}

void launch_mod_mul(int n, int bs, int dummy) {
    int grid = (n + bs - 1) / bs;
    forge_span_u64_t sa = { d_a, (size_t)n };
    forge_span_u64_t sb = { d_b, (size_t)n };
    forge_span_u64_t sc = { d_c, (size_t)n };
    bench_mod_mul<<<grid, bs>>>(sa, sb, sc, 2147483647ULL, (uint64_t)n);
}

int main(int argc, char **argv) {
    /* Get device info */
    cudaDeviceProp prop;
    CHECK_CUDA(cudaGetDeviceProperties(&prop, 0));

    N = 64 * 1024 * 1024;  /* 64M elements = 512 MB per array */
    if (argc > 1) N = atoi(argv[1]) * 1024 * 1024;

    int block_size = 256;
    int warmup = 5;
    int iterations = 20;

    printf("\n");
    printf("  +----------------------------------------------------------+\n");
    printf("  |       Forge GPU Benchmark — Verified Kernels             |\n");
    printf("  |       All kernels proven memory-safe by Z3               |\n");
    printf("  +----------------------------------------------------------+\n");
    printf("  Device:     %s\n", prop.name);
    printf("  SMs:        %d\n", prop.multiProcessorCount);
    printf("  VRAM:       %lu MB\n", (unsigned long)(prop.totalGlobalMem / (1024*1024)));
    printf("  Compute:    %d.%d\n", prop.major, prop.minor);
    printf("  Elements:   %d M  (%lu MB per array)\n",
           N / 1000000, (unsigned long)((uint64_t)N * 8 / (1024*1024)));
    printf("  Block size: %d\n", block_size);
    printf("  Iterations: %d (+ %d warmup)\n\n", iterations, warmup);

    /* Allocate device memory */
    CHECK_CUDA(cudaMalloc(&d_a, (size_t)N * sizeof(uint64_t)));
    CHECK_CUDA(cudaMalloc(&d_b, (size_t)N * sizeof(uint64_t)));
    CHECK_CUDA(cudaMalloc(&d_c, (size_t)N * sizeof(uint64_t)));
    CHECK_CUDA(cudaMalloc(&d_result, sizeof(uint64_t)));

    /* Initialize with test data */
    uint64_t *h_data = (uint64_t*)malloc((size_t)N * sizeof(uint64_t));
    for (int i = 0; i < N; i++) h_data[i] = (uint64_t)(i % 1000);
    CHECK_CUDA(cudaMemcpy(d_a, h_data, (size_t)N * sizeof(uint64_t), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(d_b, h_data, (size_t)N * sizeof(uint64_t), cudaMemcpyHostToDevice));

    /* Run benchmarks */
    printf("  %-20s  %8s  %10s  %s\n", "Kernel", "Latency", "Throughput", "Size");
    printf("  %-20s  %8s  %10s  %s\n", "------", "-------", "----------", "----");

    run_bench("vec_add",     N, block_size, warmup, iterations, 24.0f, launch_vec_add);
    run_bench("saxpy",       N, block_size, warmup, iterations, 16.0f, launch_saxpy);
    run_bench("vec_mul",     N, block_size, warmup, iterations, 24.0f, launch_vec_mul);
    run_bench("memcpy",      N, block_size, warmup, iterations, 16.0f, launch_memcpy);
    run_bench("reduce_sum",  N, block_size, warmup, iterations, 8.0f,  launch_reduce);
    run_bench("mod_mul",     N, block_size, warmup, iterations, 24.0f, launch_mod_mul);

    printf("\n  ----------------------------------------------------------\n");
    printf("  All kernels: Z3-verified, zero buffer overflow risk\n");
    printf("  Generated by Forge compiler from proven .fg source\n");
    printf("  ----------------------------------------------------------\n\n");

    /* Cleanup */
    free(h_data);
    CHECK_CUDA(cudaFree(d_a));
    CHECK_CUDA(cudaFree(d_b));
    CHECK_CUDA(cudaFree(d_c));
    CHECK_CUDA(cudaFree(d_result));

    return 0;
}
