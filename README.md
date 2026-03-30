<p align="center">
  <h1 align="center">FORGE</h1>
  <p align="center"><strong>A formally-verified systems language that compiles to C99 and CUDA C.</strong></p>
  <p align="center">Every program Forge emits is <em>correct by construction</em>. The compiler proves it.</p>
</p>

---

```forge
fn insertion_sort(s: span<u64>, n: u64)
    requires n <= s.len
    ensures forall i: u64, forall j: u64, i < j && j < n ==> s[i] <= s[j]
{
    let mut k: u64 = 0u64;
    while k < n
        invariant k <= n
        invariant forall p: u64, forall q: u64, p < q && q < k ==> s[p] <= s[q]
        decreases n - k
    {
        let mut j: u64 = k;
        while j > 0u64 {
            if s[j-1u64] > s[j] {
                let t: u64 = s[j-1u64]; s[j-1u64] = s[j]; s[j] = t;
                j = j - 1u64;
            } else { j = 0u64; };
        };
        k = k + 1u64;
    };
}
```

```
  ✓ [SMT]  postcondition of insertion_sort: forall i j, i<j && j<n ==> s[i] <= s[j]
  all 25 obligations discharged → emitting C99
```

**The compiler proves the output is sorted. Not tested. Proven.**

---

## Why Forge?

Forge is a language where **proof obligations are first-class citizens**. Every function specifies what it requires and what it guarantees. The compiler generates proof obligations and sends them to Z3. If any proof fails, compilation stops. There is no flag to suppress this.

The generated C code has **zero** runtime bounds checks because they were **proven unnecessary** at compile time.

| What | How |
|------|-----|
| No buffer overflows | Every array access proven within bounds |
| No null dereferences | Pointer validity proven at use site |
| No infinite loops | Termination proven via decreasing measures |
| No arithmetic overflow | Value ranges tracked by Z3 |
| Sorted output | Universally quantified postconditions |
| Correct state machines | State transitions proven bounded |

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
./_build/default/bin/main.exe build demos/01_divide.fg
```

**Dependencies:** OCaml 5.0+, Dune 3.0+ (build). Z3 4.12+ (runtime, called as subprocess). No third-party OCaml libraries.

---

## Features

### Three-Tier Proof System
- **Tier 1 — Z3 SMT (automatic):** preconditions, postconditions, loop invariants, termination, bounds checks
- **Tier 2 — Guided hints:** `invariant`, `decreases`, `witness()`
- **Tier 3 — Manual proof terms:** `refl`, `symm`, `trans`, `induction`

### Type System
- **Refinement types:** `[x: u64 | x > 0]` — predicates encoded into the type
- **Linear types:** `own<T>` with must-use enforcement
- **`secret<T>`:** constant-time taint tracking for cryptographic code
- **Generics:** monomorphized, with trait bounds and associated types
- **Spans:** `span<T>` fat pointers with compiler-verified bounds

### Systems Programming
- **Union types:** `union Packet { tcp: u64, udp: u64 }` → C `typedef union`
- **Packed structs:** `#[packed] struct Header { ... }` → `__attribute__((packed))`
- **Raw pointers:** `ptr_read`, `ptr_write`, `ptr_offset` with proof obligations
- **Volatile I/O:** `volatile_read`, `volatile_write` for hardware registers
- **Inline assembly:** `asm_volatile("nop")` → `__asm__ volatile("nop")`
- **Memory barriers:** `compiler_fence()`, `memory_barrier()`

### GPU Backend
- `#[kernel]` functions compile to `__global__`
- `shared<T>[N]` shared memory with barrier correctness proofs
- PTX assembly output for NVIDIA GPUs

---

## Standard Library

```forge
use std::sort;      // insertion_sort, selection_sort — PROVEN SORTED
use std::search;    // binary_search — proven: result<n ==> s[result]==target
use std::compress;  // lz_compress, lz_decompress — proven bounds-safe
use std::math;      // min, max, clamp, gcd, saturating arithmetic
use std::mem;       // span_fill, span_copy — proven: forall k<n, dst[k]==val
use std::raw;       // raw pointers, volatile I/O, inline assembly
use std::crypto;    // secret<T> constant-time primitives
use std::collections; // Vec_u64 with proven push/pop
```

---

## Real-World Applications

Six verified applications that compile and run:

| Application | Proofs | What it does |
|------------|--------|-------------|
| **Packet Filter** | 53 | IPv4 parsing + firewall rules |
| **Password Hasher** | 40 | PBKDF-style iterative hashing |
| **Sensor Monitor** | 48 | Threshold/spike detection pipeline |
| **BMP Parser** | 41 | Binary image format validation |
| **Ring Buffer IPC** | 55 | Producer-consumer message queue |
| **LZ77 Compressor** | 55 | File compression with verified roundtrip |

Build and run all: `cd apps && bash build_all.sh`

### Live Packet Sniffer

The verified packet filter runs on **real network traffic**:

```
$ sudo ./forge_sniffer

╔══════════════════════════════════════════════╗
║  Forge Verified Packet Filter (userspace)    ║
║  92 proof obligations — 0 buffer overflow    ║
╚══════════════════════════════════════════════╝

  ICMP 8.8.8.8:0     → 192.168.50.94:6772     84 bytes  ACCEPT
  UDP  10.255.255.254:42700 → 10.255.255.254:53  57 bytes  ACCEPT
  TCP  104.18.26.120:443 → 192.168.50.94:43974  2948 bytes  DROP

  Packets: 29 total, 8 accepted, 21 dropped
  Safety:  PROVEN — zero buffer overflow risk
```

### Linux Kernel Module

A verified netfilter module that compiles to a real `.ko`:

```
$ modinfo forge_netfilter.ko
description: Formally-verified packet filter — 92 proof obligations, 0 assumptions
license:     GPL
```

---

## How Verification Works

```forge
fn divide(n: u64, d: u64) -> u64
    requires d != 0              // ← precondition: caller must prove
    ensures  result * d <= n     // ← postcondition: compiler proves
{
    n / d
}
```

The compiler:
1. **Parses** the source into an AST
2. **Type-checks** and generates proof obligations
3. **Translates** each obligation to SMT-LIB2 format
4. **Sends** to Z3 for verification
5. **Only emits C** if every obligation is discharged
6. **Refuses to compile** if any proof fails

The generated C has no bounds checks, no assertions, no runtime overhead — the proofs guarantee safety statically.

---

## Demo Corpus

**1016 verified demos** covering:

**Algorithms:** sorting (insertion, selection, bubble, merge, quick, radix, bitonic, shellsort), searching (binary, ternary, interpolation, exponential), graphs (BFS, DFS, topological sort, Bellman-Ford, Dijkstra, A*, connected components, PageRank, min-cut, flow augmentation), dynamic programming (knapsack, LCS, edit distance, DTW, coin change, matrix chain, optimal BST)

**Cryptography:** SHA-256 rounds, AES S-box/MixColumns, HMAC, PBKDF2, Merkle trees, GF(256) arithmetic, EC scalar multiplication, Hamming codes, Reed-Solomon, constant-time operations

**Data Structures:** segment tree, Fenwick tree, skip list, sparse set, union-find, treap, B-tree, trie, gap buffer, Bloom filter, HyperLogLog, ring buffer, priority queue, deque

**Signal Processing:** Kalman filter, PID controller, EWMA, FIR filter, Haar wavelet, CORDIC rotation

**Systems:** packet routing, rate limiting, scheduling, cache simulation, arena allocation, SLIP framing, BWT compression

---

## Architecture

```
lib/
  ast/        AST types                           (~340 lines)
  lexer/      Ocamllex tokenizer                  (~225 lines)
  parser/     Menhir LR(1) grammar                (~1125 lines)
  types/      Type checker + proof obligations     (~3700 lines)
  proof/      Z3 bridge + three-tier discharge     (~1225 lines)
  codegen/    C99 + PTX emitter                    (~2800 lines)
bin/
  main.ml     CLI driver                           (~290 lines)
```

**~9700 lines of OCaml.** Pipeline: parse → typecheck → obligations → Z3 → erase proofs → emit C99/CUDA.

---

## Validation Results

```
Proof verification:   1003 / 1003 pass   (+ 1 intentional failure)
GCC compilation:       994 /  997 pass   (3 pre-existing edge cases)
Runtime execution:     864 /  864 pass   (0 failures)
```

---

## Documentation

| Document | What it covers |
|----------|---------------|
| **[Language Reference](LANGUAGE.md)** | Complete syntax, semantics, and examples |
| **[Manual](docs/MANUAL.md)** | Tutorial, reference, and cookbook |
| **[Kernel Roadmap](ROADMAP_KERNEL.md)** | Systems programming features |
| **[Changelog](CHANGELOG.md)** | Version history |
| **[Contributing](CONTRIBUTING.md)** | How to contribute |

---

## CLI Reference

```
forge build <file.fg>    Prove all obligations, emit C/CUDA C
forge check <file.fg>    Proof check only — no codegen
forge audit <file.c>     Dump the assume() log from generated C
forge version            Print version
```

---

## License

[MIT](LICENSE)

---

<p align="center">
  <em>Nothing ships without a proof.</em>
</p>
