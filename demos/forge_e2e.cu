// FORGE → OpenCUDA → OpenPTXas → RTX 5090
// Proven correct by Z3 (8/8 obligations discharged, 0 assumptions).
// Simplified param interface for OpenCUDA compatibility.

__global__ void vector_add(float* a, float* b, float* out, int n) {
  int gid = blockIdx.x * blockDim.x + threadIdx.x;
  if (gid < n) {
    out[gid] = a[gid] + b[gid];
  }
}
