<p align="center">
  <h1 align="center">FORGE</h1>
  <p align="center"><strong>A formally-verified GPU systems language that compiles to C99, CUDA C, and PTX.</strong></p>
  <p align="center">Every program Forge emits is <em>correct by construction</em>. The compiler proves it.</p>
</p>

---

```forge
#[kernel]
fn reduce_sum(data: span<u64>, output: span<u64>, n: u64)
    requires n <= data.len
    requires gridDim_x <= output.len
    requires blockIdx_x < gridDim_x
{
    let tid: u64 = threadIdx_x;
    let gid: u64 = blockIdx_x * blockDim_x + tid;
    let mut val: u64 = 0u64;
    if gid < n { val = data[gid]; };
    val = warp_reduce_sum(val);
    if tid % 32u64 == 0u64 {
        if tid / 32u64 == 0u64 { output[blockIdx_x] = val; };
    };
}
```

```
  [ok] bounds check: span (data[gid])
  [ok] bounds check: span (output[blockIdx_x])
  [ok] precondition of __div__
  all 3 obligations discharged -> emitting CUDA C + PTX
```

**The compiler proves every array access is safe. Not tested. Proven.**

---

## FB-0: Verified Parity Baseline

Forge-generated CUDA C matches hand-written CUDA at the SASS level across 5 kernel classes: **identical register count, identical instruction count, 44 formal proofs discharged, 0 trusted assumptions.**

| Kernel | Registers | Instructions | Proofs | Assumes |
|--------|-----------|-------------|--------|---------|
| `reduce_sum` | 18 | 169 | 3 | 0 |
| `fp16_gemm` | 40 | 460 | 5 | 0 |
| `conv2d` | 34 | 342 | 7 | 0 |
| `flash_attention` | 40 | 895 | 18 | 0 |
| `tiled_smem_gemm` | 48 | 374 | 11 | 0 |

Run it yourself: `python benchmarks/forgebench.py`

---

## Why Forge?

Forge is a language where **proof obligations are first-class citizens**. Every function specifies what it requires and what it guarantees. The compiler generates proof obligations and sends them to Z3. If any proof fails, compilation stops.

The generated code has **zero** runtime bounds checks because they were **proven unnecessary** at compile time.

| What | How |
|------|-----|
| No buffer overflows | Every array access proven within bounds |
| No null dereferences | Pointer validity proven at use site |
| No infinite loops | Termination proven via decreasing measures |
| No arithmetic overflow | Value ranges tracked by Z3 |
| No divergent barriers | `syncthreads()` verified not in thread-divergent branches |
| Sorted output | Universally quantified postconditions |

---

## Quick Start

```bash
# Install (Ubuntu/WSL2/macOS)
opam install dune    # build system
apt install z3       # SMT solver (or: brew install z3)

# Build
git clone https://github.com/garrick99/forge.git
cd forge && dune build

# Verify your first program
./_build/default/bin/main.exe build demos/1046_multi_reduction.fg
```

**Dependencies:** OCaml 5.0+, Dune 3.0+ (build). Z3 4.12+ (runtime, called as subprocess). No third-party OCaml libraries.

---

## Features

### Three-Tier Proof System
- **Tier 1 -- Z3 SMT (automatic):** preconditions, postconditions, loop invariants, termination, bounds checks
- **Tier 2 -- Guided hints:** `invariant`, `decreases`, `assert()`, `assume()` (audited)
- **Tier 3 -- Manual proof terms:** `refl`, `symm`, `trans`, `induction`, `by lemma()`

### Type System
- **Refinement types:** `[x: u64 | x > 0]` -- predicates encoded into the type
- **Linear types:** `own<T>` with must-use enforcement
- **`secret<T>`:** constant-time taint tracking for cryptographic code
- **Generics:** monomorphized, with trait bounds and associated types
- **Spans:** `span<T>` fat pointers with compiler-verified bounds
- **f32 literals:** `0.0f32` suffix for explicit float precision

### GPU Backend (SM_120 / Blackwell)
- `#[kernel]` functions compile to `__global__` with automatic `__device__` propagation
- `shared<T>[N]` shared memory with bounds-checked access
- Warp primitives: `shfl_down_sync`, `shfl_xor_sync`, `shfl_up_sync`, `ballot_sync`
- Atomics: `atom_add`, `atom_cas`, `atom_max`, `atom_min`, `atom_or`, `atom_xor`, `atom_and`, `atom_sub`, `atom_exch`
- Memory fences: `threadfence()`, `threadfence_block()`, `threadfence_system()`
- Async copy: `cp_async_cg`, `cp_async_commit`, `cp_async_wait_group` (SM_80+)
- TMA: `tma_load_2d`, `tma_store_2d`, mbarrier phase-flipped synchronization (SM_90+)
- Cooperative groups: `cluster_sync`, `cluster_dim_x`, `cluster_rank` (SM_90+)
- FP16/BF16: conversion + arithmetic via u16 wrappers (`fp16_fma`, `bf16_mul`, etc.)
- Tensor cores: QMMA (FP4), HMMA (FP16/BF16/TF32), FP8 MMA wrappers
- MXFP4: E2M1 quantization with E8M0 scales (full verified GPU kernel)
- Inline assembly: `asm("template" : out = "=r" : in = "r")` with GCC-style operands
- PTX assembly output for direct OpenPTXas consumption
- Grid-stride loop termination proven automatically (blockDim/gridDim > 0 axioms)

### Systems Programming
- **Union types:** `union Packet { tcp: u64, udp: u64 }`
- **Packed structs:** `#[packed] struct Header { ... }`
- **Bitfields:** `field: u32 : 5` -- C bitfield emission
- **Raw pointers:** `ptr_read`, `ptr_write`, `ptr_offset` with proof obligations
- **Volatile I/O:** `volatile_read`, `volatile_write` for hardware registers
- **Memory barriers:** `compiler_fence()`, `memory_barrier()`

---

## Standard Library (31 modules)

```forge
use std::gpu;           // Warp shuffles, atomics, reductions, grid-stride helpers
use std::fp16;          // FP16/BF16 conversion + arithmetic via u16 wrappers
use std::tensor_core;   // QMMA/HMMA/IMMA/FP8 MMA wrappers + tile helpers
use std::tma;           // TMA async copy + mbarrier (SM_90+)
use std::async_copy;    // cp_async SM_80+ with verified capacity helper
use std::mxfp4;         // E2M1 FP4 quantization with E8M0 scales
use std::m31;           // M31/CM31/QM31 field arithmetic (Circle STARK)
use std::threadfence;   // Device/block/system memory fences
use std::coop_groups;   // Cluster sync, DSMEM (SM_90+)
use std::sort;          // insertion_sort -- PROVEN SORTED
use std::search;        // binary_search -- proven correct
use std::compress;      // lz_compress/decompress -- proven bounds-safe
use std::math;          // min, max, clamp, gcd, saturating arithmetic
use std::mem;           // span_fill, span_copy -- proven
use std::crypto;        // secret<T> constant-time primitives
use std::collections;   // Queue, Stack, Deque
use std::matrix;        // 2D matrix transpose, multiply
use std::raw;           // Raw pointers, volatile I/O
```

---

## Demo Corpus

**1062 verified demos** covering:

**GPU Kernels (ML/HPC):**
- `1046` Warp-level reduction (3 proofs)
- `1047` FP16 GEMM with fp16_fma (5 proofs)
- `1048` 2D convolution with zero-padding (7 proofs)
- `1049` Flash Attention with online softmax (18 proofs)
- `1050` Tiled GEMM with shared memory (11 proofs)
- `1051` Inline assembly with register operands
- `1043` QMMA GEMM + TMA (SM_120 FP4xFP4->BF16, 14 proofs)

**ZK Proof Systems (GPU):** Full Circle STARK kernel suite (demos 1021-1042):
FRI fold, Poseidon2, NTT butterfly, Blake2s, DEEP quotient, Merkle trees, constraint evaluation, OODS, vanishing polynomial, batch inverse, alpha powers, LogUp, circle point arithmetic, coset NTT, trace normalization

**Algorithms:** sorting (insertion through radix/bitonic), searching, graphs (BFS/DFS/Dijkstra/A*/PageRank), dynamic programming (knapsack/LCS/edit distance)

**Cryptography:** SHA-256, AES, HMAC, PBKDF2, Merkle trees, EC scalar mul, Hamming codes, Reed-Solomon, constant-time ops

**Data Structures:** segment tree, Fenwick tree, skip list, union-find, B-tree, trie, Bloom filter, HyperLogLog, ring buffer

**Systems:** packet routing, rate limiting, cache simulation, arena allocation, BWT compression

---

## Real-World Applications

| Application | Proofs | What it does |
|------------|--------|-------------|
| **Packet Filter** | 53 | IPv4 parsing + firewall rules |
| **Password Hasher** | 40 | PBKDF-style iterative hashing |
| **Sensor Monitor** | 48 | Threshold/spike detection pipeline |
| **BMP Parser** | 41 | Binary image format validation |
| **Ring Buffer IPC** | 55 | Producer-consumer message queue |
| **LZ77 Compressor** | 55 | File compression with verified roundtrip |

---

## Architecture

```
lib/
  ast/        AST types + asm_block              (~350 lines)
  lexer/      Ocamllex tokenizer                 (~230 lines)
  parser/     Menhir LR(1) grammar               (~1200 lines)
  types/      Type checker + proof obligations    (~3900 lines)
  proof/      Z3 bridge + three-tier discharge    (~1225 lines)
  codegen/    C99 + CUDA C + PTX emitter          (~3600 lines)
bin/
  main.ml     CLI driver                          (~390 lines)
benchmarks/
  forgebench.py    Proof-to-performance comparison harness
  fb0_baseline/    Frozen baseline: cubins, SASS, manifest
```

**~11,000 lines of OCaml.** Pipeline: parse -> typecheck -> obligations -> Z3 -> erase proofs -> emit C99/CUDA C/PTX.

---

## Validation Results

```
Proof verification:   1062 / 1062 pass
GCC compilation:      1021 / 1021 pass   (-Wall -Wextra -Werror)
Runtime execution:     879 /  879 pass
Error cases:            20 /   20 pass
ForgeBench FB-0:       5/5 kernels, SASS parity with nvcc
```

---

## Documentation

| Document | What it covers |
|----------|---------------|
| **[Language Reference](LANGUAGE.md)** | Complete syntax, semantics, and examples |
| **[Architecture](ARCHITECTURE.md)** | Compiler internals, proof system, common pitfalls |
| **[Kernel Roadmap](ROADMAP_KERNEL.md)** | Systems programming features |
| **[Changelog](CHANGELOG.md)** | Version history |
| **[FB-0 Manifest](benchmarks/fb0_baseline/MANIFEST.md)** | Benchmark baseline with cubin hashes |

---

## CLI Reference

```
forge build <file.fg>    Prove all obligations, emit C99/CUDA C/PTX
forge cuda <file.fg>     Optimized CUDA C emission
forge check <file.fg>    Proof check only -- no codegen
forge audit <file.c>     Dump the assume() log from generated C
forge version            Print version
```

---

## License

Dual-licensed:

- **[Apache 2.0](LICENSE)** — free for research, education, evaluation, and open-source projects
- **[Commercial License](LICENSE-COMMERCIAL.md)** — required for production deployment of Forge-compiled code in commercial products

See [LICENSE-COMMERCIAL.md](LICENSE-COMMERCIAL.md) for details.

---

<p align="center">
  <em>Nothing ships without a proof.</em>
</p>
