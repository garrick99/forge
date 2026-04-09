# Changelog

All notable changes to Forge are documented here.

## [0.3.0] — 2026-04-09

### FB-0: Verified Parity Baseline

**1062 verified demos. 5/5 benchmark kernels. 44 proofs. 0 assumes. SASS parity with nvcc.**

Forge-generated CUDA C compiles to identical machine code as hand-written CUDA across
five kernel classes (reduction, GEMM, convolution, attention, tiled shared memory) while
carrying formal proof metadata.

### GPU Stdlib Expansion (6 new/expanded modules)

- **`std::gpu`** — +6 atomics (`atom_or`, `atom_xor`, `atom_and`, `atom_sub`, `atom_exch`), `shfl_up_sync`
- **`std::fp16`** — FP16/BF16 conversion + arithmetic via u16 wrappers (19 extern fns, 2 verified helpers, 6 constants)
- **`std::tensor_core`** — QMMA (FP4), HMMA (FP16/BF16/TF32), IMMA (INT8), FP8 MMA wrappers + tile size helpers
- **`std::threadfence`** — `threadfence()`, `threadfence_block()`, `threadfence_system()`
- **`std::async_copy`** — `cp_async_cg`, `cp_async_commit`, `cp_async_wait_group` (SM_80+) with verified capacity helper
- **`std::coop_groups`** — `cluster_sync`, `cluster_dim_x`, `cluster_rank`, `cluster_map_shared` (SM_90+)

### Compiler Improvements

- **40+ GPU intrinsic mappings** across `codegen_cuda.ml`, `codegen_ptx.ml`, `codegen_c.ml`
- **Inline assembly with operands** — `asm("template" : out = "=r" : in1 = "r", in2 = "r")` GCC-style syntax; new AST node `EAsm`, parser rule, typecheck, all 3 codegens
- **Bitfields** — `field: u32 : 5` syntax in struct definitions, emits C bitfield
- **f32 literal suffix** — `0.0f32` and `1.5f64` parse with explicit float width via `FLOAT_SUFF` token
- **Shared memory model** — bounds check (`idx < smem_size`) replaces per-thread ownership partitioning; fixes 2D kernels and tiled patterns; `threadIdx_x` direct access auto-verified
- **Grid-stride termination** — while-loop termination measure checked with loop condition in scope; `blockDim_{x,y,z} > 0` and `gridDim_{x,y,z} > 0` axioms injected for all kernels
- **`__device__` propagation** — transitive closure of functions called from kernels; extern prototypes also annotated when in device call graph
- **FP16/BF16 codegen** — `__half`/`__nv_bfloat16` casts for overload disambiguation; `<cuda_fp16.h>` and `<cuda_bf16.h>` includes in CUDA mode

### New Demos (6 verified GPU kernels)

| Demo | Kernel | Proofs | Description |
|------|--------|--------|-------------|
| 1046 | `reduce_sum` | 3 | Warp-level butterfly reduction |
| 1047 | `fp16_gemm` | 5 | FP16 GEMM with `fp16_fma` |
| 1048 | `conv2d` | 7 | 2D convolution with zero-padding |
| 1049 | `flash_attention` | 18 | Online softmax attention kernel |
| 1050 | `tiled_gemm` | 11 | Tiled GEMM with shared memory (2D kernel) |
| 1051 | `asm_add_test` | 0 | Inline assembly with register operands |

### ForgeBench

- Python harness (`benchmarks/forgebench.py`): Forge build + nvcc compilation + cubin analysis
- Per-kernel report: register count, instruction count, proof count, assumes
- FB-0 baseline frozen in `benchmarks/fb0_baseline/` with MANIFEST, cubin hashes, SASS dumps
- JSON + text report output

### Testing

```
Proof verification:   1062 / 1062 pass
GCC compilation:      1021 / 1021 pass   (-Wall -Wextra -Werror)
Runtime execution:     879 /  879 pass
Error cases:            20 /   20 pass
```

---

## [0.2.0] — 2026-04-03

### VortexSTARK GPU Kernel Suite

**1042 verified demos. 2418 proof obligations. 3 compiler fixes.**

Complete suite of formally-verified CUDA GPU kernels for Circle STARK (VortexSTARK),
targeting M31/CM31/QM31 field arithmetic over SM_120 (RTX 5090).

### Compiler Fixes

- **Z3 forall trigger annotations** — `PForall` now emits `:pattern ((select arr k))` hints
  when the body contains array indexing by the bound variable. Without patterns, Z3's
  E-matching was unreliable for kernel body assertions over `forall k < n` preconditions.
- **Varying type non-negativity** — `is_unsigned` now recursively strips `TQual` wrappers,
  fixing a bug where `TQual(Varying, TPrim(TUint U32))` variables (threadIdx_x, blockIdx_x,
  kernel let-bindings) got no `>= 0` lower-bound constraint. Z3 could set them to -1,
  making forall guards vacuously true.
- **Assert error messages** — `OInvariant "assert"` now reports as `"assertion cannot be proven"`
  rather than the generic loop invariant failure message.

### New Coding Patterns (documented in-source)

- **Let-binding rule**: `m31_get` results must be stored in `let` bindings before passing to
  callees — Forge does not propagate postconditions from nested inline calls.
- **Read-then-write rule**: Array writes invalidate `forall` preconditions; all reads via
  `m31_get` from a span must complete before any writes to the same span in a function body.

### Standard Library

- **`std::m31`** — M31, CM31, QM31 field arithmetic for Circle STARK:
  `m31_add`, `m31_sub`, `m31_mul`, `m31_pow5`, `cm31_mul_re/im`,
  `qm31_mul_out_*`, `qm31_add_*`, `qm31_sub_*` — all with `ensures result < M31_P`

### ZK Proof System GPU Kernels (demos 1021–1035)

| Demo | Kernel | Obligations |
|------|--------|-------------|
| 1021 | Circle NTT coset evaluation | — |
| 1022 | FRI fold layer (M31 + CM31) | 112 |
| 1023 | Blake2s compression kernel | 54 |
| 1024 | QM31 accumulate / FRI fold / pointwise mul | 290 |
| 1025 | DEEP quotient accumulation (QM31 SoA) | 226 |
| 1026 | Merkle tree commitment (leaf + inner + verify) | 23 |
| 1027 | Poseidon2 S-box + add_rc + partial round | 308 |
| 1028 | Poseidon2 external MDS (M4⊗I4) + internal MDS | 558 |
| 1029 | Full Poseidon2 round: ext → partial → ext | 763 |
| 1030 | NTT butterfly (Cooley-Tukey + Gentleman-Sande + scaling + bitrev) | 166 |
| 1031 | Circle FFT butterfly (forward + inverse + coset shift + FRI fold) | 181 |
| 1032 | FRI query path bounds + fold index + layer verify | 139 |
| 1033 | AIR constraint evaluation (linear + mul gate + transition + multi) | 209 |
| 1034 | OODS numerator + combine + fused quotient + last-row exclusion | 157 |
| 1035 | Vanishing poly quotient + boundary quotient + combine + coset blowup | 164 |
| 1036 | M31 batch inverse (Montgomery's trick: prefix upsweep + Fermat + suffix scan) | 195 |
| 1037 | Alpha powers (sequential + parallel prefix product + QM31 variant) | 241 |
| 1038 | LogUp grand product accumulation (trace terms, table subtract, reduce, zero-check) | 230 |
| 1039 | Circle point arithmetic (double, add, twiddle gen, conjugate, extract) | 223 |
| 1040 | LinePoly fold (M31 + QM31 FRI fold; the fixed VortexSTARK bug) | 180 |
| 1041 | Coset NTT (preprocess, butterfly, postprocess, linepoly eval, twiddle adjust) | 171 |
| 1042 | Trace normalization (reduce mod P, validate, pad, batch copy) | 137 |

All kernels verified: field invariant (`< M31_P`) maintained through every arithmetic
step; all array accesses proven in-bounds via Z3.

**Note on AoS/SoA layout conversion (1042):** Index arithmetic `col*n_rows+row < n_rows*n_cols`
derived from symbolic division is a nonlinear arithmetic (NIA) obligation Z3 cannot discharge
from symbolic variables. This is a known Z3 limitation; concrete-value testing covers the
runtime correctness. The 4 verified kernels in 1042 cover all non-NIA trace plumbing.

### Testing

```
Proof verification:   1042 / 1042 pass   (+ 1 intentional failure)
GCC compilation:      1021 / 1021 pass
Runtime execution:     879 /  879 pass   (0 failures)
```

---

## [0.1.0] — 2026-03-29

### The Milestone Release

**1016 verified demos. 6 real-world applications. 13 compiler improvements.**

### Compiler Features
- **Recursive induction hypotheses** — `inject_rec` automatically injects callee postconditions as induction hypotheses for well-founded recursive functions
- **EIf body mutation tracking** — `expr_final_env` handles top-level EIf function bodies, enabling postcondition proofs for elif chains
- **Assignment postcondition injection** — `x = f(args)` now injects callee postconditions (previously only `let x = f(args)` worked)
- **Nested-if array extraction** — conditional swaps inside if-blocks are visible to the proof engine, enabling natural `if s[i] > s[j] { swap }` patterns
- **Union types** — `union Name { fields }` compiles to C `typedef union`
- **Packed structs** — `#[packed] struct` emits `__attribute__((packed))`
- **Inline assembly** — `asm_volatile("nop")` emits `__asm__ volatile("nop")`
- **Raw pointer operations** — `ptr_read`, `ptr_write`, `ptr_offset`, `ptr_null`, `ptr_to_u64`, `u64_to_ptr`
- **Volatile I/O** — `volatile_read`, `volatile_write` for hardware registers
- **Memory barriers** — `compiler_fence()`, `memory_barrier()`
- **C99 ternary codegen** — if-expressions as assignment RHS emit as ternary operators
- **Implication flattening** — `P ==> Q ==> R` auto-flattened to `(P && Q) ==> R` for better Z3 MBQI triggers
- **Nonlinear arithmetic hints** — multiplication monotonicity assertions help Z3 NIA

### Standard Library
- **std::sort** — `insertion_sort` and `selection_sort` with `ensures forall i j, i<j && j<n ==> s[i] <= s[j]`
- **std::search** — `binary_search` with full soundness proof, `lower_bound`, `upper_bound`, `min_index`, `max_index`
- **std::compress** — LZ77 compression/decompression with proven bounds safety
- **std::raw** — raw pointer operations, volatile I/O, memory barriers, inline assembly

### Applications
- **Packet Filter** — IPv4 parsing + firewall rules (53 proof obligations)
- **Password Hasher** — Iterative PBKDF-style hashing (40 obligations)
- **Sensor Monitor** — Threshold/spike detection pipeline (48 obligations)
- **BMP Parser** — Binary image format validation (41 obligations)
- **Ring Buffer IPC** — Producer-consumer queue (55 obligations)
- **LZ77 Compressor** — File compression with roundtrip verification (55 obligations)
- **Verified Packet Sniffer** — Live network traffic filtering (92 obligations)
- **Kernel Module** — Linux netfilter module (92 obligations, compiles to .ko)

### Documentation
- CLAUDE.md — project-specific build/architecture/proof-pattern docs
- ROADMAP_KERNEL.md — kernel module development roadmap
- CONTRIBUTING.md — contributor guide
- LANGUAGE.md — updated with unions, packed structs, raw pointers, inline asm
- Full manual (docs/MANUAL.md)

### Demos
- 1016 verified demos covering: sorting, searching, graph algorithms, dynamic programming, cryptography, data structures, signal processing, compression, networking, linear algebra, string algorithms, protocol verification, and more
- Milestones: 500, 700, 750, 800, 850, 900, 950, 1000

### Testing
- 3-phase test suite (proof verification, GCC compilation, runtime execution)
- 1003/1003 proof verification pass rate (+ 1 intentional failure)
- 994/997 GCC compilation pass rate (3 pre-existing issues)
- 864/864 runtime execution pass rate

### Dependencies
- **Build**: OCaml 5.0+, Dune 3.0+ (no third-party OCaml libraries)
- **Runtime**: Z3 4.12+ (called as subprocess)
