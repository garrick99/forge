# Changelog

All notable changes to Forge are documented here.

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
