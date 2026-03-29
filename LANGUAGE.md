# Forge Language Reference

Forge is a formally-verified systems programming language that compiles to C99 and CUDA C.
Every program Forge emits is **correct by construction**: proof obligations are discharged by
a Z3 SMT backend before any code is generated. If the proof fails, the compiler stops.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Types](#types)
3. [Literals and Operators](#literals-and-operators)
4. [Expressions](#expressions)
5. [Statements](#statements)
6. [Functions](#functions)
7. [Proof System](#proof-system)
8. [Structs](#structs)
9. [Enums and Pattern Matching](#enums-and-pattern-matching)
10. [Generics](#generics)
11. [Traits](#traits)
12. [Ownership and Borrows](#ownership-and-borrows)
13. [Spans and Arrays](#spans-and-arrays)
14. [GPU Backend](#gpu-backend)
15. [Constant-Time Cryptography](#constant-time-cryptography)
16. [Module System](#module-system)
17. [Standard Library](#standard-library)
18. [Error Handling](#error-handling)
19. [Proof Terms (Tier 3)](#proof-terms-tier-3)
20. [CLI Reference](#cli-reference)

---

## Quick Start

```bash
# Install dependencies (Ubuntu / WSL2)
opam install dune menhir z3

# Build the compiler
dune build

# Compile and verify a program
./_build/default/bin/main.exe build myfile.fg

# Check proofs without emitting code
./_build/default/bin/main.exe check myfile.fg
```

The simplest complete program:

```forge
fn main() -> u64 { 0u64 }
```

A verified function:

```forge
fn add(a: u64, b: u64) -> u64
    requires a <= 100u64
    requires b <= 100u64
    ensures  result <= 200u64
{
    a + b
}

fn main() -> u64 { 0u64 }
```

---

## Types

### Primitive types

| Type  | Width  | Notes                              |
|-------|--------|------------------------------------|
| `u8`  | 8-bit  | Unsigned integer                   |
| `u32` | 32-bit | Unsigned integer                   |
| `u64` | 64-bit | Unsigned integer (default int)     |
| `i32` | 32-bit | Signed integer                     |
| `i64` | 64-bit | Signed integer                     |
| `f32` | 32-bit | IEEE 754 single-precision float    |
| `f64` | 64-bit | IEEE 754 double-precision float    |
| `bool`| 1-bit  | Boolean (`true` / `false`)         |
| `usize` | platform | Array length / index type       |

### Compound types

| Syntax          | Meaning                                         |
|-----------------|-------------------------------------------------|
| `span<T>`       | Fat pointer `(ptr, len)` — all indexing proven  |
| `[T; N]`        | Fixed-size array of N elements                  |
| `(T1, T2)`      | Tuple (anonymous struct in C output)            |
| `own<T>`        | Linearly-owned heap value (`malloc`/`free`)     |
| `ref<T>`        | Shared borrow (read-only, unrestricted)         |
| `refmut<T>`     | Mutable borrow (write, affine — use at most once per call) |
| `secret<T>`     | Constant-time taint type for cryptographic values |
| `Option<T>`     | `Some(v)` or `None` — from `std::option`        |
| `Result<T,E>`   | `Ok(v)` or `Err(e)` — from `std::result`        |

### Refinement types

```forge
fn positive(x: [n: u64 | n > 0]) -> u64 { x }

// The predicate is encoded as a precondition at every call site.
fn caller() -> u64 {
    positive(5u64)   // Z3 checks 5 > 0
}
```

Syntax: `[var: type | predicate]`. The variable name is in scope within the predicate.

### Type aliases

```forge
type Index = u64;
type Matrix = [u64; 256];
```

---

## Literals and Operators

### Integer literals

Suffixes fix the type explicitly. Without a suffix, the type is inferred from context (defaults to `u64`).

```forge
42u64     // u64
42u32     // u32
42u8      // u8
42i32     // i32
42i64     // i64
0u64      // zero (u64)
```

### Boolean literals

```forge
true    false
```

### Arithmetic operators

| Op | Meaning    | Notes                          |
|----|------------|--------------------------------|
| `+` | add       | Overflow checked by Z3         |
| `-` | subtract  | Underflow checked by Z3        |
| `*` | multiply  | Overflow checked by Z3         |
| `/` | divide    | Requires divisor ≠ 0 (Z3)      |
| `%` | remainder | Requires divisor ≠ 0 (Z3)      |

### Comparison operators

`==`  `!=`  `<`  `<=`  `>`  `>=`

### Logical operators

| Op    | Meaning              |
|-------|----------------------|
| `&&`  | logical AND          |
| `\|\|`  | logical OR           |
| `!`   | logical NOT          |

### Bitwise operators

| Op   | Meaning      |
|------|--------------|
| `&`  | bitwise AND  |
| `\|`  | bitwise OR   |
| `^`  | bitwise XOR  |
| `~`  | bitwise NOT  |
| `<<` | left shift   |
| `>>` | right shift  |

When any bitwise operator is present in a function, the Z3 backend switches from unbounded
integer arithmetic to bitvector mode (`(_ BitVec N)` sorts), giving exact wrap-around
semantics.

### Operator precedence (highest → lowest)

| Level | Operators                    | Associativity |
|-------|------------------------------|---------------|
| 9     | unary `!`, unary `-`, `~`    | right         |
| 8     | `*`, `/`, `%`                | left          |
| 7     | `+`, `-`                     | left          |
| 6     | `<<`, `>>`                   | left          |
| 5     | `&`                          | left          |
| 4     | `^`                          | left          |
| 3     | `\|`                           | left          |
| 2     | `==`, `!=`, `<`, `<=`, `>`, `>=` | left     |
| 1     | `&&`                         | left          |
| 0     | `\|\|`                         | left          |

---

## Expressions

### `if` / `else if` / `else`

```forge
let x: u64 = if a > b { a } else { b };

// Chains
let clamped: u64 = if v < lo { lo } else if v > hi { hi } else { v };
```

`if` without `else` returns `()`. `if` with `else` is an expression; both branches must
have the same type.

### `match`

```forge
match x {
    0u64 => "zero",
    1u64 => "one",
    _    => "other",
}

// Pattern guards
match n {
    k if k < 10u64 => small(k),
    k               => large(k),
}

// OR patterns
match c {
    'a' | 'e' | 'i' | 'o' | 'u' => true,
    _                            => false,
}

// Range patterns
match n {
    0u64..=9u64   => "single digit",
    10u64..=99u64 => "two digits",
    _             => "large",
}

// `as` patterns
match opt {
    Some(v) as s => use_both(s, v),
    None         => 0u64,
}

// Nested match
match pair {
    (Some(a), Some(b)) => a + b,
    _                  => 0u64,
}
```

### `loop` / `break`

```forge
let result: u64 = loop {
    // ... compute ...
    break value;
};
```

### `while`

```forge
while i < n
    invariant i <= n
    decreases n - i
{
    // body
};   // ← semicolon required when followed by another expression
```

### `for`

```forge
// Index-based: i = 0, 1, ..., n-1
for i in n {
    s[i] = 0u64;
};

// Element-based span iteration
for x in s {
    total = total + x;
};

// Sub-range
for i in lo..hi {
    process(s[i]);
};
```

### `let` / `let mut`

```forge
let x: u64 = 42u64;
let mut count: u64 = 0u64;

// Tuple destructuring
let (q, r): (u64, u64) = divmod(a, b);
```

### Function calls

```forge
let y = f(x);
let z = obj.method(arg);  // method call desugars to TypeName__method(obj, arg)
```

### Struct construction

```forge
struct Point { x: u64, y: u64 }

let p = struct Point { x: 3u64, y: 7u64 };
```

### Field access

```forge
let v = p.x;
let n = span_val.len;   // span length field
```

### Span indexing

```forge
s[i]           // read (bounds checked by Z3)
s[i] = v;      // write (bounds checked by Z3)
s[lo..hi]      // sub-span slice (3 obligations: lo >= 0, lo <= hi, hi <= s.len)
```

### Casts

```forge
let b: u8 = (wide_value as u8);
```

### `assert`

```forge
assert(x < n);   // proved by Z3, then added as a downstream fact in context
```

### `assume`

```forge
assume(x < n);   // taken as true without proof; emits assume() log entry for audit
```

---

## Statements

```forge
// Expression-as-statement (side effect)
foo();

// Assignment
x = x + 1u64;
s[i] = value;

// Let binding
let y: u64 = expr;

// Return
return expr;

// `or_return` / `or_fail` error propagation
let v = risky_fn() or_return default;
let v = risky_fn() or_fail;

// `?` operator (in functions returning Result)
let v = may_fail()?;
```

---

## Functions

```forge
fn name(param: Type, ...) -> ReturnType
    requires precond1
    requires precond2
    ensures  postcond1
    ensures  postcond2
    decreases measure
{
    body
}
```

- `requires` — precondition (checked by Z3 at every call site)
- `ensures` — postcondition (the special name `result` refers to the return value)
- `decreases` — termination measure for recursive functions

### Lemmas

```forge
lemma name(params) -> bool
    ensures result == true
{
    proof { auto }
}
```

Lemmas are proof-only functions whose return value is a proof term.

### `extern` functions

```forge
extern fn malloc(size: u64) -> u64 = "<stdlib.h>";
```

Generates `#include <stdlib.h>` and declares the function without a body.

### Attributes

```forge
#[kernel]         // CUDA __global__ kernel
#[coalesced]      // assert coalesced memory access (checked statically)
#[ind_cpa]        // IND-CPA security annotation
```

---

## Proof System

### The three tiers

| Tier | Mechanism | Usage |
|------|-----------|-------|
| 1 | Z3 SMT (automatic) | All preconditions, postconditions, invariants, bounds, overflow |
| 2 | Guided hints | `invariant`, `decreases`, `witness()`, `assert`, `assume` |
| 3 | Manual proof terms | `refl`, `symm`, `trans`, `auto`, `by lemma()`, `induction x { base, step }` |

### Proof clause syntax

```forge
fn f(s: span<u64>, n: u64) -> u64
    requires n > 0u64              // precondition
    requires n <= s.len            // multiple requires allowed
    ensures  result <= s[0u64]     // postcondition
    ensures  result >= 0u64        // multiple ensures allowed
    decreases n                    // termination measure
{
    ...
}
```

### Quantifiers in specifications

```forge
// Universal: all elements in prefix are sorted
ensures forall k: u64, k + 1u64 < n ==> s[k] <= s[k + 1u64]

// Existential: some element equals target
ensures result == true ==> exists k: u64, k < n && s[k] == target

// Quantifiers in loop invariants
while i < n
    invariant forall k: u64, k < i ==> s[k] == 0u64
{
    s[i] = 0u64;
    i = i + 1u64;
};
```

### `old()` — pre-state references

```forge
fn push(s: refmut<Stack>)
    ensures (*s).size == old((*s).size) + 1u64
{
    ...
}
```

`old(expr)` evaluates `expr` at function entry. Useful for specifying state changes in
functions with mutable parameters.

### Loop invariants

```forge
while i < n
    invariant i <= n              // safety invariant
    invariant cnt <= i            // progress invariant
    invariant forall k: u64, k < i ==> s[k] == 0u64   // quantified invariant
    decreases n - i               // termination measure
{
    ...
};
```

### `assert` as a proof stepping-stone

```forge
assert(x < n);   // Z3 proves this, then adds it to the proof context
// subsequent obligations can now use x < n
```

### `assume` for external facts

```forge
assume(external_invariant());   // admitted without proof; logged to the audit file
```

Running `forge audit file.c` dumps all `assume()` entries from the emitted C so you know
exactly what was not proved.

### `ghost` variables

Ghost variables exist only in proofs and are erased before codegen:

```forge
ghost let sum: u64 = 0u64;
while i < n
    invariant ghost_sum == actual_prefix_sum(s, i)
{
    ghost sum = sum + s[i];
    i = i + 1u64;
};
```

### Conditional postconditions

A common pattern for functions with branching:

```forge
fn clamp(v: u64, lo: u64, hi: u64) -> u64
    requires lo <= hi
    ensures  result >= lo
    ensures  result <= hi
    ensures  v < lo  ==> result == lo
    ensures  v > hi  ==> result == hi
    ensures  !(v < lo) && !(v > hi) ==> result == v
{
    if v < lo { lo } else if v > hi { hi } else { v }
}
```

The `!(cond) ==> rhs` pattern correctly parses as `(!(cond)) ==> rhs` — the `!` binds
tighter than `==>`.

---

## Structs

```forge
struct Point {
    x: u64,
    y: u64,
}

// Construction
let p = struct Point { x: 3u64, y: 7u64 };

// Field access
let v = p.x;

// Invariant structs (constructor verifies field predicates)
struct Positive {
    value: [n: u64 | n > 0],
}
```

### `impl` blocks

```forge
impl Point {
    fn distance(self: ref<Point>, other: ref<Point>) -> u64 {
        let dx = if (*self).x >= (*other).x {
            (*self).x - (*other).x
        } else {
            (*other).x - (*self).x
        };
        dx  // simplified
    }
}

// Call with dot syntax
let d = p.distance(&q);
```

Methods mangle to `TypeName__method_name` in C output.

---

## Enums and Pattern Matching

```forge
enum Color { Red, Green, Blue }

enum Shape {
    Circle(u64),          // variant with payload
    Rect(u64, u64),
}

// Match on enum
match shape {
    Shape::Circle(r) => r * r,
    Shape::Rect(w, h) => w * h,
}

// if let
if let Some(v) = maybe_value {
    use_v(v)
} else {
    default()
}
```

All match expressions must be exhaustive (checked at compile time).

---

## Generics

### Generic functions

```forge
fn identity<T>(x: T) -> T { x }

fn swap<T>(a: T, b: T) -> (T, T) { (b, a) }
```

### Generic types

```forge
enum Option<T> { Some(T), None }
enum Result<T, E> { Ok(T), Err(E) }

struct Pair<T> { first: T, second: T }
```

### Const generics

```forge
fn dot<N: usize>(a: [u64; N], b: [u64; N]) -> u64
    ensures result >= 0u64
{
    let mut acc: u64 = 0u64;
    for i in N {
        acc = acc + a[i] * b[i];
    };
    acc
}

// Call site
let v = dot::<4>(arr_a, arr_b);
```

In C output, `N` is passed as a leading `uint64_t` parameter.

### Bounded generics

```forge
fn hash_all<T: Hashable>(items: span<T>, n: u64) -> u64
    requires n <= items.len
{
    ...
}
```

### `where` clauses

```forge
fn compare<T>(a: T, b: T) -> bool
    where T: Ord + Eq
{
    a < b
}
```

---

## Traits

```forge
trait Printable {
    fn print(self: ref<Self>);
}

trait Hashable {
    fn hash(self: ref<Self>) -> u64;
}

// Default method
trait Describable {
    fn describe(self: ref<Self>) -> u64 {
        0u64   // default implementation
    }
}

// Implementation
impl Hashable for Point {
    fn hash(self: ref<Point>) -> u64 {
        (*self).x * 31u64 + (*self).y
    }
}
```

Method dispatch is static (monomorphized). Method call `p.hash()` desugars to
`Point__Hashable__hash(&p)` in C output.

### Associated types

```forge
trait Container {
    type Item;
    fn get(self: ref<Self>, i: u64) -> Self::Item;
}
```

---

## Ownership and Borrows

Forge has three ownership kinds, enforced at compile time:

| Kind | Type      | Semantics |
|------|-----------|-----------|
| Linear | `own<T>` | Must be consumed exactly once |
| Affine | `refmut<T>` | May be used at most once per call |
| Unrestricted | `ref<T>` | May be used arbitrarily |

### `own<T>` — linear heap ownership

```forge
use std::prelude;

// Allocate
let p: own<u64> = own_alloc(42u64);   // calls malloc

// Read + free (consumes the own<T>)
let v: u64 = own_into(p);

// Free without reading
own_free(p);

// Borrow without consuming
let r: ref<u64>    = own_borrow(&p);      // read-only
let rm: refmut<u64> = own_borrow_mut(&mut p);   // mutable
```

Failing to consume an `own<T>` is a compile error (`OLinear` obligation fails).

### `ref<T>` and `refmut<T>`

```forge
fn read_value(x: ref<u64>) -> u64 {
    *x
}

fn increment(x: refmut<u64>) {
    *x = *x + 1u64;
}
```

In C output, `ref<T>` becomes `const T*` and `refmut<T>` becomes `T*`.

---

## Spans and Arrays

### `span<T>`

A `span<T>` is a fat pointer `(ptr, len)`. All indexing is bounds-checked by Z3.

```forge
fn sum(s: span<u64>, n: u64) -> u64
    requires n <= s.len
{
    let mut acc: u64 = 0u64;
    let mut i: u64 = 0u64;
    while i < n
        invariant i <= n
        decreases n - i
    {
        acc = acc + s[i];
        i = i + 1u64;
    };
    acc
}
```

Special field: `s.len` — the proven length of the span.

### Sub-span slicing

```forge
let sub = s[lo..hi];
// Generates 3 obligations:  lo >= 0,  lo <= hi,  hi <= s.len
// Injects fact:  sub.len == hi - lo
```

### Fixed-size arrays `[T; N]`

```forge
let arr: [u64; 4] = [0u64; 4];   // repeat syntax: all zeros
let arr2: [u64; 3] = [1u64, 2u64, 3u64];

// Access
let v = arr[2u64];   // bounds checked by Z3 (2 < 4)
```

### `for` iteration over spans

```forge
// Element-based (no index needed)
for x in s {
    total = total + x;
};

// Index-based (use explicit while or for i in n)
for i in s.len {
    process(s[i]);
};
```

---

## GPU Backend

### Kernel functions

```forge
#[kernel]
fn vector_add(a: span<f32>, b: span<f32>, c: span<f32>)
    requires a.len == b.len
    requires b.len == c.len
{
    let i: u32 = threadIdx_x + blockIdx_x * blockDim_x;
    if i < a.len {
        c[i] = a[i] + b[i];
    }
}
```

`#[kernel]` functions compile to `__global__` in CUDA C output.

### GPU built-in variables

| Forge name      | CUDA equivalent   |
|-----------------|-------------------|
| `threadIdx_x`   | `threadIdx.x`     |
| `threadIdx_y`   | `threadIdx.y`     |
| `blockIdx_x`    | `blockIdx.x`      |
| `blockIdx_y`    | `blockIdx.y`      |
| `blockDim_x`    | `blockDim.x`      |
| `gridDim_x`     | `gridDim.x`       |

### Shared memory

```forge
let smem: shared<u64>[256] = shared_alloc();
syncthreads();
```

`syncthreads()` placement is verified — calling it inside a branch on a per-thread value
is a compile error.

### PTX output

Forge also has a PTX backend. Use `#[kernel]` as above; the compiler emits SM_89 assembly
directly when targeting PTX.

---

## Constant-Time Cryptography

The `secret<T>` type enforces constant-time discipline:
- No branching on `secret<T>` values
- No `secret<T>`-indexed memory access
- Must call `declassify()` at the output boundary
- Emits `volatile T` in C to prevent compiler optimization

```forge
// Constant-time conditional select
fn ct_select(flag: secret<u64>, a: secret<u64>, b: secret<u64>) -> secret<u64> {
    let mask: secret<u64> = 0u64 - flag;
    (mask & a) | (~mask & b)
}

// Constant-time equality
fn ct_eq(a: secret<u64>, b: secret<u64>) -> secret<u64> {
    let diff = a ^ b;
    let neg = 0u64 - diff;
    (~(diff | neg)) >> 63u64
}

// Declassify at output boundary
fn verify(secret_key: secret<u64>, candidate: u64) -> bool {
    let eq: secret<u64> = ct_eq(secret_key, candidate as secret<u64>);
    declassify(eq) != 0u64
}
```

The `#[ind_cpa]` attribute annotates functions for IND-CPA structural verification —
any direct `declassify(key)` inside an `#[ind_cpa]` function is a compile error.

---

## Module System

```forge
// Import a standard library module
use std::math;
use std::mem;
use std::str;
use std::collections;
use std::prelude;
use std::option;
use std::result;
use std::crypto;

// After import, all public functions from the module are in scope
let m = min64(a, b);   // from std::math
```

Modules are resolved relative to the source file. `use std::math` loads `./std/math.fg`
(or the Forge standard library path).

The `ex_link` convention: `extern fn name(...) = "<header.h>"` causes Forge to emit
`#include <header.h>` instead of redeclaring the function.

---

## Standard Library

### `std::prelude`

Low-level C bindings — memory, I/O, and math. Import with `use std::prelude;`.

**Memory:** `malloc`, `free`, `realloc`, `memcpy`, `memmove`, `memset`, `memcmp`

**C strings:** `strlen`, `strcmp`, `strcpy`

**I/O:** `putchar`, `getchar`, `puts`, `fputs`, `fflush`, `fwrite`

**Process:** `abort`, `exit`

**Math (f64):** `sqrt`, `fabs`, `floor`, `ceil`, `pow`, `sin`, `cos`, `tan`, `exp`, `log`, `log2`, `log10`, `atan2`

**Math (f32):** `sqrtf`, `fabsf`, `floorf`, `ceilf`, `powf`, `sinf`, `cosf`, `expf`, `logf`

### `std::math`

Verified integer math with Z3 postconditions.

| Function | Signature | Description |
|----------|-----------|-------------|
| `min64` | `(a: u64, b: u64) -> u64` | Minimum of two u64 values |
| `max64` | `(a: u64, b: u64) -> u64` | Maximum of two u64 values |
| `clamp64` | `(v: u64, lo: u64, hi: u64) -> u64` | Clamp v to [lo, hi] |
| `abs_diff` | `(a: u64, b: u64) -> u64` | Absolute difference |
| `pow64` | `(base: u64, exp: u64) -> u64` | Integer exponentiation |
| `ceil_div` | `(a: u64, b: u64) -> u64` | Ceiling division, requires b > 0 |
| `round_up` | `(a: u64, b: u64) -> u64` | Round a up to next multiple of b |
| `gcd64` | `(a: u64, b: u64) -> u64` | Euclidean GCD, requires a > 0 |
| `sat_add` | `(a: u64, b: u64) -> u64` | Saturating addition |
| `sat_sub` | `(a: u64, b: u64) -> u64` | Saturating subtraction |
| `sat_mul` | `(a: u64, b: u64) -> u64` | Saturating multiplication |
| `is_pow2` | `(n: u64) -> bool` | True iff n is a power of two |
| `popcount64` | `(n: u64) -> u64` | Count set bits (Kernighan's method) |
| `floor_log2` | `(n: u64) -> u64` | Floor(log2(n)), requires n > 0 |

### `std::mem`

Span-level memory operations with verified bounds.

| Function | Signature | Description |
|----------|-----------|-------------|
| `span_fill_u8` | `(dst: span<u8>, v: u8, n: u64)` | Fill n bytes with v |
| `span_zero_u8` | `(dst: span<u8>, n: u64)` | Zero n bytes |
| `span_copy_u8` | `(dst: span<u8>, src: span<u8>, n: u64)` | Copy n bytes |
| `span_eq_u8` | `(a: span<u8>, b: span<u8>, n: u64) -> bool` | Compare n bytes |
| `span_fill_u64` | `(dst: span<u64>, v: u64, n: u64)` | Fill n u64 values |
| `span_copy_u64` | `(dst: span<u64>, src: span<u64>, n: u64)` | Copy n u64 values |
| `span_sum` | `(s: span<u64>, n: u64) -> u64` | Sum of first n elements |
| `span_max` | `(s: span<u64>, n: u64) -> u64` | Max of first n elements (n >= 1) |
| `span_min` | `(s: span<u64>, n: u64) -> u64` | Min of first n elements (n >= 1) |

### `std::str`

Byte-string type built on `span<u8>`.

```forge
struct Str { data: span<u8>, len: u64 }
```

| Function | Description |
|----------|-------------|
| `str_new(data)` | Create empty string over backing span |
| `str_len(s)` | Logical length |
| `str_capacity(s)` | Capacity (backing span length) |
| `str_is_empty(s)` | True if len == 0 |
| `str_at(s, i)` | Read byte at index i |
| `str_push(s, b)` | Append byte (requires room) |
| `str_clear(s)` | Reset length to 0 |
| `byte_eq(a, b)` | Byte equality |
| `str_starts_with_byte(s, b)` | Check first byte |
| `is_ascii_digit(b)` | b in '0'..'9' |
| `is_ascii_lower(b)` | b in 'a'..'z' |
| `is_ascii_upper(b)` | b in 'A'..'Z' |
| `to_ascii_lower(b)` | Convert uppercase byte to lowercase |
| `to_ascii_upper(b)` | Convert lowercase byte to uppercase |

### `std::option`

```forge
enum Option<T> { Some(T), None }
```

Use `match` or `if let` to unwrap:

```forge
match maybe {
    Some(v) => process(v),
    None    => default_value,
}

if let Some(v) = maybe { use_v(v) } else { 0u64 }
```

### `std::result`

```forge
enum Result<T, E> { Ok(T), Err(E) }
```

Use the `?` operator to propagate errors:

```forge
fn process() -> Result<u64, u64> {
    let v = may_fail()?;   // returns Err early if may_fail() returns Err
    Ok(v + 1u64)
}
```

### `std::collections`

Queue, stack, and deque implementations backed by fixed-size spans.

### `std::crypto`

Cryptographic primitives: NTT butterfly, Barrett reduction, Horner evaluation, secret dot product.

---

## Error Handling

### `Result<T, E>` and `?`

```forge
use std::result;

fn safe_div(a: u64, b: u64) -> Result<u64, u64>
    ensures b == 0u64 ==> result == Err(1u64)
    ensures b != 0u64 ==> result == Ok(a / b)
{
    if b == 0u64 { Err(1u64) } else { Ok(a / b) }
}

fn chain(a: u64, b: u64, c: u64) -> Result<u64, u64> {
    let x = safe_div(a, b)?;   // propagates Err if b == 0
    safe_div(x, c)
}
```

### `or_return` / `or_fail`

```forge
// Return a default value on failure
let v = risky() or_return 0u64;

// Abort on failure
let v = risky() or_fail;
```

---

## Proof Terms (Tier 3)

For obligations that Z3 cannot discharge automatically, Forge provides a calculus of
construction (CoC) subset for manual proof terms.

```forge
lemma add_comm(a: u64, b: u64) -> bool
    ensures result == true
{
    proof { auto }                           // try Z3 first
}

lemma nat_sum_nonneg(n: u64) -> bool
    ensures result == true
{
    proof {
        induction n {
            base => refl,                    // base case: n = 0
            step => auto,                    // inductive step: Z3
        }
    }
}

// Use a proved lemma
fn caller(a: u64, b: u64) -> bool
    ensures result == true
{
    by add_comm(a, b)
}
```

### Proof term constructors

| Term | Meaning |
|------|---------|
| `refl` | Reflexivity: `a == a` |
| `symm(p)` | Symmetry: from `a == b`, derive `b == a` |
| `trans(p, q)` | Transitivity: from `a == b` and `b == c`, derive `a == c` |
| `auto` | Discharge by Z3 (Tier 1) |
| `by lemma(args)` | Invoke a proved lemma |
| `induction x { base => p, step => q }` | Structural induction on `x` |

---

## CLI Reference

```
forge build <file.fg>    Prove all obligations, emit C99 (or CUDA C for GPU code)
forge check <file.fg>    Proof check only — no codegen output
forge audit <file.c>     Dump the assume() log from a generated C file
forge version            Print version
```

### Output files

- `.c` — C99 output (for non-GPU programs)
- `.cu` — CUDA C output (for programs with `#[kernel]` functions)
- `.ptx` — PTX assembly (when using the PTX backend)

### Debug: dump failing SMT queries

```bash
FORGE_DUMP_SMT=1 forge build myfile.fg
# Dumps failing queries to /tmp/forge_smt*.smt2
```

### Exit codes

| Code | Meaning |
|------|---------|
| 0 | All obligations proved, C emitted |
| 1 | Proof failure — compiler output shows which obligation failed |
| 2 | Parse or type error |

---

## Complete Example: Verified Binary Search

```forge
fn binary_search(s: span<u64>, n: u64, target: u64) -> u64
    requires n <= s.len
    requires forall k: u64, k + 1u64 < n ==> s[k] <= s[k + 1u64]
    ensures  result <= n
{
    let mut lo: u64 = 0u64;
    let mut hi: u64 = n;
    while lo < hi
        invariant lo <= hi
        invariant hi <= n
        decreases hi - lo
    {
        let mid: u64 = lo + (hi - lo) / 2u64;
        if s[mid] < target {
            lo = mid + 1u64;
        } else {
            hi = mid;
        };
    };
    lo
}

fn main() -> u64 { 0u64 }
```

Forge proves:
- `mid` is in bounds (`mid < n <= s.len`)
- `hi - lo` strictly decreases each iteration
- `result <= n` at function exit

---

## Compiler Architecture

```
source.fg
  └─ Lex (lexer.mll)
  └─ Parse (parser.mly, Menhir LR(1))
  └─ resolve_uses
  └─ Typecheck + obligation generation (typecheck.ml ~3200 lines)
  └─ Prove obligations (proof_engine.ml ~1200 lines)
       ├─ Tier 1: Z3 SMT (Int or BitVec mode)
       ├─ Tier 2: guided hints
       └─ Tier 3: CoC proof terms
  └─ Erase proofs
  └─ Codegen
       ├─ C99 (codegen_c.ml ~2100 lines)
       └─ PTX (codegen_ptx.ml)
  └─ output.c / output.cu / output.ptx
```

**Proof obligation types:**

| Obligation | Generated when |
|------------|----------------|
| `OPrecondition` | Function called — requires clause must hold |
| `OPostcondition` | Function exits — ensures clause must hold |
| `OBoundsCheck` | Span/array indexed — index < length |
| `ONoOverflow` | Arithmetic — result stays in type range |
| `OTermination` | Recursive call / loop — measure strictly decreases |
| `OLinear` | `own<T>` value — consumed exactly once |
| `OInvariant` | Loop body / struct construction — invariant preserved |

**Z3 modes:**
- Integer mode (default): unbounded integers, cheaper queries
- Bitvector mode: used when `&`, `|`, `^`, `~`, `<<`, `>>` appear in scope; exact modular wrap-around

**Parser note:** `lib/parser/parser.ml` is pre-generated and committed. Dune 3.22 has a
cycle bug with Menhir. To regenerate after grammar changes, use `regen_parser.sh`.
