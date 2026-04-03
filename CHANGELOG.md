# Changelog

All notable changes to Forge are documented here.

## [0.2.0] — 2026-04-03

### VortexSTARK GPU Kernel Suite

**1035 verified demos. 1041 proof obligations. 3 compiler fixes.**

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

All kernels verified: field invariant (`< M31_P`) maintained through every arithmetic
step; all array accesses proven in-bounds via Z3.

### Testing

```
Proof verification:   1041 / 1041 pass   (+ 1 intentional failure)
GCC compilation:      1020 / 1020 pass
Runtime execution:     878 /  878 pass   (0 failures)
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
