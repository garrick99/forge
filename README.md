# FORGE

A formally-verified systems language that compiles to C99 and CUDA C.

Every program FORGE emits is **correct by construction** — proof obligations are discharged by a Z3 SMT backend before any code is generated. If the proof fails, the compiler stops. There is no flag to suppress this.

```forge
fn divide(n: u64, d: u64) -> u64
    requires d != 0
    ensures  result * d <= n
{
    n / d
}
```

```
  ✓ [SMT]    01_divide.fg:4  precondition of '/'
  ✓ [SMT]    01_divide.fg:3  postcondition of 'divide'
  all obligations discharged → emitting C99
```

---

## Features

### Three-tier proof system
- **Tier 1 — Z3 SMT (automatic):** preconditions, postconditions, loop invariants, termination, bounds checks, overflow guards
- **Tier 2 — Guided hints:** `invariant`, `decreases`, `witness()`
- **Tier 3 — Manual proof terms:** `refl`, `symm`, `trans`, `auto`, `by lemma()`, `induction x { base, step }`

### Type system
- **Refinement types:** `[x: u64 | x > 0]` — predicates encoded directly into the type
- **Linear and affine types:** must-use and at-most-once enforcement checked at compile time
- **`secret<T>` — constant-time taint:** marks cryptographic values; the type system enforces no branching on secrets, no secret-indexed memory access, and explicit `declassify()` at the output boundary. Emits `volatile T` in C.
- **Generic types:** `enum Option<T>`, `enum Result<T,E>`, user-defined generics with monomorphization
- **Span fat pointers:** `span<T>` with proven bounds; all indexing is verified against `.len`

### GPU correctness (CUDA C backend)
- `#[kernel]` functions compile to `__global__`
- `shared<T>[N]` shared memory with ownership proofs
- `syncthreads()` placement verified — divergence is a compile error
- `#[coalesced]` attribute checked by static analysis

### Loop and recursion verification
- Loop invariants: `invariant p && forall i: u64, i < k ==> ...`
- Termination: `decreases expr` for single measures, `decreases (a, b)` for lexicographic
- Mutual recursion: Tarjan SCC detects cycles; each SCC gets a shared termination measure

### Module system
- `use std::prelude;` loads `./std/prelude.fg` (extern C/CUDA declarations)
- `ex_link = "<header.h>"` convention: FORGE emits `#include` and skips redeclaration

---

## Building

Requires OCaml 5.0+, Menhir 20231231+, Z3 4.12+, and Dune 3.0+.

```bash
# Install dependencies (Ubuntu/WSL2)
opam install dune menhir z3

# Build
dune build

# Run a demo
./_build/default/bin/main.exe build demos/01_divide.fg
```

The compiler binary is `./_build/default/bin/main.exe`.

**Note:** `lib/parser/parser.ml` is pre-generated and committed. Do not add a `(menhir ...)` stanza to the dune file — there is a known Dune 3.22 + Menhir cycle bug. To regenerate after grammar changes, use the manual `--infer-write-query` / `--infer-read-reply` protocol.

---

## Commands

```
forge build <file.fg>    prove all obligations, emit C/CUDA C
forge check <file.fg>    proof check only — no codegen
forge audit <file.c>     dump the assume log from generated C
forge version
```

---

## Demos

All demos compile clean under `gcc -Wall -Wextra -Werror`.

| # | File | What it demonstrates |
|---|------|----------------------|
| 01 | `01_divide.fg` | Safe division — precondition + postcondition |
| 02 | `02_bad_divide.fg` | **Intentional failure** — shows the compiler refusing to emit |
| 03 | `03_overflow.fg` | Overflow-safe arithmetic |
| 04 | `04_minmax.fg` | Min/max with proven postconditions |
| 05 | `05_abs.fg` | Absolute difference |
| 06 | `06_gcd.fg` | GCD: preconditions on recursive calls + termination |
| 07 | `07_saturating.fg` | Saturating arithmetic |
| 08 | `08_midpoint.fg` | Overflow-safe midpoint (the classic interview bug, proven safe) |
| 09 | `09_packing.fg` | Bit-field packing |
| 10 | `10_search.fg` | Binary search: provably correct index arithmetic |
| 11 | `11_align.fg` | Memory alignment |
| 12 | `12_fixedpoint.fg` | Fixed-point arithmetic |
| 13 | `13_termination.fg` | Termination proofs |
| 14 | `14_loop_inv.fg` | Loop invariants |
| 15 | `15_structs.fg` | Struct invariants + field access in postconditions |
| 16 | `16_lex_term.fg` | Lexicographic termination |
| 17 | `17_span.fg` | `span<T>` fat pointer with proven bounds |
| 18 | `18_mutual_rec.fg` | Mutual recursion with shared termination measure |
| 19 | `19_gpu_kernel.fg` | GPU kernel: barrier correctness + coalescing analysis |
| 20 | `20_enum.fg` | Enum types + exhaustive pattern matching |
| 21 | `21_modules.fg` | Module system: `use std::prelude` |
| 22 | `22_proof_terms.fg` | Tier 3 manual proof terms |
| 23 | `23_bitvec.fg` | Bitvector SMT — Z3 uses `(_ BitVec N)` sorts for bitwise ops |
| 24 | `24_parser_hardening.fg` | Casts, OR-patterns, typed integer literals, nested generics |
| 25 | `25_generics.fg` | User-defined generic types (`Option<T>`, `Result<T,E>`) |
| 26 | `26_quantified_ensures.fg` | Quantified postconditions: `forall i: u64, i < n ==> ...` |
| 27 | `27_induction.fg` | Induction proof terms: `induction x { base, step }` |
| 28 | `28_forall_loop_inv.fg` | Loop invariants with embedded universal quantifiers |
| 29 | `29_as_patterns.fg` | `as` patterns in match expressions |
| 30 | `30_gpu_reduction.fg` | GPU parallel tree reduction with `shared<u64>` and `syncthreads()` |
| 31 | `31_lemma_postcond.fg` | Proved lemma injection — induction results used in postconditions |
| 32 | `32_or_return.fg` | `or_return` / `or_fail` error propagation |
| 33 | `33_impl_methods.fg` | `impl` blocks and struct methods |
| 34 | `34_borrows.fg` | `ref<T>` and `refmut<T>` borrow types |
| 35 | `35_secret_type.fg` | `secret<T>` constant-time taint: `ct_select`, `ct_eq`, `mulmod` |
| 36 | `36_ct_modpow.fg` | Constant-time modular exponentiation (`base^exp mod q`, secret exponent) |
| 37 | `37_fixed_arrays.fg` | `[T; N]` fixed-size arrays — bounds proven by Z3; `[val; N]` repeat syntax |
| 38 | `38_ntt_crypto.fg` | `std::crypto` module: NTT butterfly, Horner poly eval, secret dot product |
| 39 | `39_ptx_vecadd.fg` | PTX backend — SM_89 assembly emitted for `#[kernel]` functions |
| 40 | `40_ind_cpa.fg` | `#[ind_cpa]` compile-time IND-CPA structural verification; `forge audit` log |
| 41 | `41_kyber_poly.fg` | Kyber-512 polynomial ring Zq[X]/(X^256+1): add/sub/mul/inner-product; `for i in n` loops with auto-proved bounds |
| 42 | `42_const_generics.fg` | `<N: usize>` const generic parameters — `fn dot<N: usize>(a: [u64; N], b: [u64; N])` — N passed as leading `uint64_t` in C |
| 43 | `43_kyber_ntt.fg` | Kyber-512 Cooley-Tukey NTT: 3-loop structure, `len/2` termination, bounds from `while start+2*len≤256` + `for j in len`; 31 obligations ✓ |
| 44 | `44_tuple_returns.fg` | Tuple return types `(T1, T2)` — anonymous struct typedef in C; `t.0`/`t.1` field projection; `ensures result.0 * b + result.1 == a`; 10 obligations ✓ |
| 45 | `45_tuple_butterfly.fg` | Pure NTT butterfly `-> (u64, u64)` with callee postcondition injection — `let lo = ntt_add(...)` injects `lo < q`; 23 obligations ✓ |
| 46 | `46_let_destructure.fg` | `let (q, r) = divmod(...)` tuple destructuring — parse-time desugar to temp + projections; callee postconditions propagate to destructured names; 9 obligations ✓ |
| 47 | `47_own_heap.fg` | `own<T>` linear heap — `own_alloc` → `malloc`, `own_into` → destructive read + `free`, `own_free` → discard; linear must-use enforced at compile time; `T*` in C ✓ |
| 48 | `48_own_linked_list.fg` | `own<Node>` struct heap + `own_get` peek (returns value + pointer-back as tuple); composing `node_val`/`node_free` with full linear discipline; 0 obligations (structural) ✓ |
| 49 | `49_insertion_sort.fg` | Insertion sort: quantified postcondition `forall i < j < n ==> s[i] <= s[j]`; nested loop invariants (outer: prefix sorted, inner: suffix sorted); 14 obligations ✓ |
| 50 | `50_own_borrow.fg` | `own_borrow` / `own_borrow_mut` affine borrows — `ref<T>` (Unr, read-many) and `refmut<T>` (Aff, write-once) without consuming the `own<T>`; `const T*` / `T*` in C; 0 obligations ✓ |
| 51 | `51_for_in_span.fg` | `for x in s` element-based span iteration — hidden `__i_x`/`__span_x` in C; no loop obligations; sum, count, contains, or-all, and-all, all-le; 0 obligations ✓ |
| 52 | `52_subspan.fg` | `s[lo..hi]` sub-span slicing — 3 obligations per slice (lo≥0, lo≤hi, hi≤s.len); subspan `.len == hi-lo` fact injected; `span_split`, `slice_sum`, `slice_max`, copy; 21 obligations ✓ |
| 53 | `53_if_let_assert.fg` | `if let Some(q) = expr` (desugars to match) + `assert(pred)` proof stepping-stones — proved by Z3, then added as downstream facts; `safe_div`, `div4`, `clamp`; 5 obligations ✓ |
| 54 | `54_question_mark.fg` | `?` operator — parse-time desugar to `match { Ok(v) => v, Err(e) => return Err(e) }`; chains `safe_div` twice without explicit match arms; 1 obligation ✓ |
| 55 | `55_loop_range.fg` | `loop { break val }` value-returning loops + `lo..=hi` integer range patterns in match arms; Collatz step counter + coefficient classifier; 1 obligation ✓ |
| 56 | `56_traits.fg` | `trait Hashable { fn hash; }` + `impl Hashable for Point` — methods mangle to `TypeName__TraitName__MethodName`; inherent `impl Pair { fn sum }` also works; 0 obligations ✓ |
| 57 | `57_kyber_kem.fg` | Kyber-512 KEM sketch — Barrett reduction, encaps, decaps, round-trip; ties together traits, range patterns, `?` operator, `loop { break }`, structs, proof specs; 12 obligations ✓ |
| 58 | `58_modules.fg` | Module system — `use std::option;` + `use std::result;` imports `Option<T>` and `Result<T,E>` from `std/`; `safe_sqrt` + `?`-chained `div_chain`; 6 obligations ✓ |

Demos 59–99 cover: bounded generics, `str` type, associated types, `for-in` iterators,
`std::math`/`std::iter`/`std::collections` usage, method syntax, type aliases, enum methods,
trait method dispatch, `const` items, builder pattern, signed integers, `where` clauses,
default trait methods, multi-bounds, newtypes, match guards, nested match, `Result<T,E>`,
accumulators, Fibonacci, bit ops, string ops, state machines, strategy pattern,
or-patterns, span algorithms, postcondition libraries, const generics, generic bounds
dispatch, invariant structs, loop invariants, type aliases, refinement types,
generic data structures, multi-return, and enum payloads.

Demos 100–130 cover: language showcase, verified binary search / GCD / sort /
ring buffer / crypto / typestate, Hamming weight, interval arithmetic, priority queue,
fixed-point, verified stack, bit tricks, DFA classifier, checksums, run-length encoding,
sorting networks, window statistics, packet header, matrix2x2, polynomial evaluation,
bitset, integer math, tokenizer, gray code, 2D vector, color math, modular arithmetic,
ring buffer, digit ops, and interval manipulation.

Demos 131–199 cover: while loops with quantified invariants, recursion, spans,
inline call postcondition injection, mutable span writes, array SSA patterns,
old() postconditions, selection/insertion/binary-search/bubble sort,
clamp/saturate array passes, partition, ghost variables (sum, copy proof, running max,
min index, minmax pass), prefix sum, is_sorted, linear/count search, dot product,
array fill/reverse/sum, for-loop patterns (sum, fill, matvec, transpose, stride copy,
tiled copy, Hadamard, two-sum, three-way partition, quicksort partition, array map/scale,
function composition, EMA filter, running mean, NTT butterfly/round, GPU scan upsweep,
power, and full quantified postcondition suites.

Demos 200–297 cover deep verified algorithms: assert facts, GPU reduce, verified
memcpy/memset/memmove/saxpy/iota, for-range patterns (partial fill, slice copy,
SAXPY, bounds check), verified partition/prefix-max/clamp/sliding-sum/max-range/
matrix-fill, old() scalar and preservation, GPU thread safety, assume hints, while with
quantified invariants (binary search, GCD, two-pointer), verified merge/stride/matrix-row/
scan, elif chains (clamp, three-way select, bool flag, partition flag), verified
merge-sort step, bool scan, contains, count-lt/gt, find-first, strong is-sorted,
max-index, insertion/selection sort steps, Dutch national flag, running max, abs-copy,
normalize, Boyer-Moore majority, matrix max, window sum, dot-product range,
two-pointer sum, mismatch, threshold fill, histogram, chained copy, reverse,
count-equal, prefix sum, find-max-min, zero-fill-then-write, sum bounded, rotate-left,
apply-mask, stride copy, all-nonzero, upper bound, clamp/scale array, find-second-max,
stable partition, copy-if, interleave sum, all-equal, saturating-add array,
copy-bounded, elementwise max, zero count, and min-index range.

### Intentional failures (in `demos/bad/`)

These demonstrate what FORGE catches:

| File | What it rejects |
|------|-----------------|
| `01_div_by_zero.fg` | Division without proof that divisor ≠ 0 |
| `02_bad_invariant.fg` | Loop invariant that cannot be preserved |
| `03_no_decreases.fg` | Unbounded recursion with no termination measure |
| `04_struct_invariant.fg` | Struct construction violating a field invariant |
| `05_field_ensures.fg` | Postcondition not provable from the body |
| `06_mutual_no_decreases.fg` | Mutually recursive functions with no shared measure |
| `07_syncthreads_divergent.fg` | `syncthreads()` inside a branch on a per-thread value |
| `06_ind_cpa_violation.fg` | `#[ind_cpa]` function that `declassify(key)` — key leakage caught |
| `08_own_not_freed.fg` | `own<T>` allocated but never freed — linear must-use violation |
| `09_unbound_generic.fg` | Generic type variable used outside its scope |

---

## Language Quick Reference

```forge
// Function with preconditions, postconditions
fn sqrt_floor(n: u64) -> u64
    requires n >= 0
    ensures  result * result <= n
{ ... }

// Refinement type
fn positive(x: [n: u64 | n > 0]) -> u64 { x - 1 }

// Loop invariant + termination
fn sum(s: span<u64>) -> u64 {
    let acc: u64 = 0u64;
    let i: u64   = 0u64;
    while i < s.len
        invariant i <= s.len
        decreases s.len - i
    { acc = acc + s[i]; i = i + 1u64 };
    acc
}

// secret<T> — constant-time cryptographic discipline
fn ct_select(flag: secret<u64>, a: secret<u64>, b: secret<u64>) -> secret<u64> {
    let mask: secret<u64> = 0u64 - flag;
    (mask & a) | (~mask & b)
}

// GPU kernel
#[kernel]
fn vector_add(a: span<f32>, b: span<f32>, c: span<f32>)
    requires a.len == b.len && b.len == c.len
{
    let i: u32 = threadIdx_x + blockIdx_x * blockDim_x;
    if i < a.len { c[i] = a[i] + b[i] }
}

// Manual proof term
lemma double_is_even(n: u64) -> bool
    ensures result == true
{
    proof { auto }
}
```

---

## Architecture

```
lib/
  ast/          AST node types (~220 lines)
  lexer/        Ocamllex lexer (lexer.mll ~290 lines)
  parser/       Menhir LR(1) grammar (parser.mly ~1085 lines; parser.ml pre-generated)
  tokens/       Standalone token type module
  types/        Type checker + proof obligation generation (typecheck.ml ~3200 lines)
  proof/        Z3 bridge + three-tier discharge engine (proof_engine.ml ~1200 lines)
  codegen/      C99 emitter (codegen_c.ml ~2100 lines) + PTX backend (codegen_ptx.ml)
bin/
  main.ml       CLI driver + compiler pipeline (~290 lines)
demos/          296 passing demos (01–297, excluding intentional 02_bad_divide)
  bad/          9 intentional failures
  std/          Standard library modules (prelude, option, result, math, iter,
                collections, crypto)
```

The pipeline: parse → type-check → generate obligations → discharge (Z3 / guided / manual) → erase proofs → emit C99 or CUDA C.

**Proof obligation types generated:**
- `OPrecondition` — `requires` clause satisfied at each call site
- `OPostcondition` — `ensures` clause follows from function body
- `OBoundsCheck` — every span/array index proven within `.len`
- `ONoOverflow` — arithmetic stays within the type's value range
- `OTermination` — recursive calls and loops have a decreasing measure
- `OLinear` — `own<T>` values consumed exactly once
- `OInvariant` — struct field predicates and loop invariants preserved

---

## Roadmap

- **First-class function values** — proper `fn(T) -> U` types, closures, verified higher-order functions (`map`, `filter`, `fold` with postconditions)
- **Full IND-CPA game proof** — adversary model, game-hopping, reduction to LWE
- **Recursive data structures** — verified linked lists, trees, and heaps with `own<T>` linearity
- **Warp-level GPU primitives** — `__shfl_sync`, warp-level reduction, tensor core intrinsics
- **Compiler error spans** — structured diagnostics with source location ranges
- **Verified unsafe C interop** — `extern` blocks with explicit proof obligations at the FFI boundary
