#!/bin/bash
# Spot-check GPU demos after typecheck changes.
cd "$(dirname "$0")/.."
for f in 1017_gpu_warp_reduce 1018_gpu_shared_mem 1024_qm31_kernels 1021_circle_ntt 1022_fri_fold 1134_forge_softmax_warp 1135_forge_rmsnorm_warp; do
    echo "=== $f ==="
    opam exec -- ./_build/default/bin/main.exe build "demos/${f}.fg" 2>&1 | tail -1
done
