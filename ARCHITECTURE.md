# Forge — Architecture Guide

Internal reference for contributors. The README covers the language from a user perspective;
LANGUAGE.md covers syntax; this document covers the compiler internals.

---

## What Forge Is

Forge is a proof-carrying compiler. Every function has a `requires` precondition and an
`ensures` postcondition. The compiler generates Z3 SMT proof obligations for every possible
failure mode, discharges them automatically, and only emits code if all proofs pass.

The user never calls a theorem prover explicitly — they write specifications in the function
signature and the compiler handles the rest.

---

## Compiler Stages

```
.fg source
  └─ Lexer (lib/lexer/)         ocamllex tokenizer
      └─ Parser (lib/parser/)   Menhir LR(1) grammar → AST
          └─ Typecheck (lib/types/)
             ├─ Type inference and checking
             ├─ Proof obligation generation
             └─ Z3 discharge (lib/proof/)
                  └─ Codegen (lib/codegen/)
                     ├─ codegen_c.ml   → C99 / CUDA C
                     └─ codegen_ptx.ml → PTX 8.8
```

Entry point: `bin/main.ml` → `main.exe build <file.fg>`

---

## The Proof System

### Three tiers

1. **Automatic (Z3)**: Default. The typechecker generates an obligation and calls Z3. If Z3
   returns UNSAT (proof holds), compilation continues. Most obligations discharge this way.

2. **Guided hints**: When Z3 times out on a nonlinear goal, the user can add `hint(expr)`
   annotations to steer Z3 toward the proof. The hint is added as an `(assert ...)` axiom
   before the main query.

3. **Manual proof terms**: For obligations Z3 cannot discharge at all (e.g., inductive
   arguments), the user writes explicit proof terms: `refl`, `symm(p)`, `trans(p1, p2)`,
   `induction x { base, step }`. The proof engine checks these structurally, not via Z3.

### Proof engine (lib/proof/proof_engine.ml)

Core function: `discharge_obligation(env, goal_pred)`.

Builds a Z3 query from:
- The current environment's facts (function preconditions, loop invariants, assigned variable
  equalities, struct invariants)
- The negation of the goal predicate (UNSAT = goal holds)
- Axioms: proved lemmas, non-negativity axioms for unsigned types

Returns `Proved`, `Failed(counterexample)`, or `Unknown(timeout)`.

### BV mode vs Int mode

Z3 uses two theories depending on the goal:

- **Int mode (default)**: Maps Forge integer types to Z3 `Int`. Handles linear arithmetic,
  quantifiers, array theory. Used for most proofs.

- **BV mode**: Activates when the goal contains bitwise operations (`&`, `|`, `^`, `>>`,
  `<<`). Maps integer types to `(_ BitVec N)`. Does NOT support quantifiers (`QF_BV` is
  quantifier-free). Proved lemmas are not injected in BV mode.

**Switching between modes is automatic** — `proof_engine.ml` detects bitwise ops in the
goal and selects the theory. Do not manually force one mode.

**Free variable sort bug (fixed):** In BV mode, free variables must be declared as
`(_ BitVec N)`, not `Int`. This was a past bug — see demo 36 (ct_modpow). If you add new
expression forms that introduce free variables (e.g., unresolved function call results),
ensure they use the correct sort in BV mode.

---

## Environment and SSA-Lite

Forge uses an SSA-lite approach rather than full SSA form. The central operation is
`env_assign_var(env, x, rhs_expr)`:

1. Renames all free occurrences of `x` in the existing fact set to a fresh name `__x_pN`
2. Adds the fact `x == rhs_expr`

This means every assignment creates a new logical name for the old value, preserving
proof context across mutations. PForall/PExists binders are not renamed (only free
occurrences are renamed).

### Why this matters for loop invariants

The loop invariant checker uses this SSA-lite to reason about the state after one loop
iteration. The "preservation" check renames `i → i` after modeling `i = i + 1` via
`env_assign_var`, then checks that the invariant still holds. Get the ordering wrong and the
wrong equalities end up in the Z3 context.

### Array writes

`s[k] = val` triggers `env_array_write` in **both** `check_stmt` (obligation generation)
AND `stmt_final_env` (postcondition context building). The `stmt_final_env` version is
critical for postconditions — if you add a new array write form, update both sites or
postconditions on the write will silently fail to see the update.

---

## Type System

### Span<T>

Fat pointer: `(ptr, length)`. Array access `s[i]` generates an obligation `i < s.len`.
Bounds are proven, not checked. The C emitter omits runtime bounds checks entirely.

### Secret<T>

Taint type for constant-time code. Taints propagate through all arithmetic and bitwise ops.
Branching on a `secret<T>` value or using it as an array index are compile errors (timing
channels). `declassify(x)` strips the taint explicitly. Emits `volatile T` in C.

### Refinement types

`{x: T | P(x)}` — a type where values must satisfy predicate P. The compiler generates an
obligation at every construction site and records the predicate as a fact at every use site.

### Struct invariants

Structs can declare invariants in their body:
```forge
struct BoundedBuf {
    data: span<u8>,
    len: u64,
    invariant len <= data.len,
}
```
When a function takes `buf: BoundedBuf`, the invariant is automatically injected as a fact
at function entry. When the struct is mutated, an obligation is generated that the invariant
is restored.

---

## Loop Invariants and Termination

### Loop invariant check structure

For `while cond invariant P { body }`:

1. **Entry check**: At the point the loop is entered, prove `P` holds under the current env
   (substituting the initial value of the loop variable)
2. **Body env**: Add `P` as a fact and `cond` as a fact, then typecheck the body
3. **Preservation check**: After modeling one iteration (`env_assign_var` for all modified
   vars), prove `P` still holds
4. **Post-loop env**: Add `P` and `!cond` as facts, substitute the terminal loop variable
   value (e.g., `n` for `i` after `while i < n`)

The post-loop substitution is why `forall k < i, P(k)` invariants become `forall k < n, P(k)`
postconditions — it's not magic, it's the terminal substitution.

### Decreasing measures

`decreases expr` proves termination. The compiler generates an obligation that `expr`
decreases on each iteration and is bounded below by 0. For nested loops, the outer measure
can be any expression that decreases; it doesn't have to be the loop variable.

---

## CUDA C Emission

### #[kernel] annotation

Functions marked `#[kernel]` emit as `__global__ void`. The compiler:
- Injects `__syncthreads()` at `syncthreads()` call sites
- Emits `__shared__` for `shared<T>` declarations
- Verifies that `shared_ownership` predicates are discharged (prevents use of shared memory
  in kernels where blockDim.x isn't provably correct)

### Thread index access

`threadIdx_x`, `blockIdx_x`, etc. are special values in the CUDA C codegen — they emit as
`threadIdx.x`, `blockIdx.x`, etc. and are typed as `u32`.

### Coalescing analysis

`#[coalesced]` on a kernel annotates that the primary memory access pattern is coalesced.
The compiler checks that the access index is `threadIdx_x + blockDim_x * blockIdx_x` (or
equivalent) and issues a warning if not.

---

## Build and Development

### Building (WSL2 on Windows, or native Linux)

```bash
export PATH=/root/.opam/default/bin:/usr/sbin:/usr/bin:/sbin:/bin
cd /mnt/c/Users/kraken/forge   # or wherever forge is
dune build 2>&1
```

**On Windows:** Always build via WSL2. The OCaml toolchain (`opam`, `dune`, `menhir`) is
installed in the WSL2 environment at `/root/.opam/`. Do not attempt to build natively on
Windows.

### Running a demo

```bash
./_build/default/bin/main.exe build demos/01_divide.fg
```

### Running all demos

```bash
bash test/run_all.sh
```

1,018/1,018 currently pass. `demos/02_bad_divide.fg` is an intentional failure — the test
harness counts it as a pass.

### Regenerating the parser

If you modify `lib/parser/parser.mly`, regenerate the parser:
```bash
dune build @lib/parser/parser.ml
```
This reruns Menhir. The generated `parser.ml` is checked in. Do not edit it directly.

---

## Common Pitfalls

**`stmt_final_env` vs `check_stmt`:** These are two separate traversals. `check_stmt`
generates proof obligations. `stmt_final_env` builds the environment for postcondition
checking. If you add a new statement form, you must implement both — they are NOT mirrors
of each other, they serve different purposes. Forgetting `stmt_final_env` for a new
statement type means postconditions on code that follows that statement won't have the
right facts in scope.

**Quantifiers and BV mode:** `QF_BV` (BV mode) does not allow quantifiers. Proved lemmas
(which are injected as `(assert (forall ...))`) are automatically skipped in BV mode. If
you add a new axiom injection mechanism, add the same BV mode skip.

**Non-negativity axioms:** The `nonneg` axiom (`(assert (forall ((k Int)) (>= (select arr k) 0)))`)
is emitted for `span<u64>` variables when the goal contains quantifiers. It is NOT emitted
for QF goals (prevents NIA timeout). If you add a new unsigned array type, extend
`proof_engine.ml`'s `has_array_select` check to cover it.

**`env_assign_var` and binders:** `env_assign_var` renames free occurrences of `x` in facts.
It does NOT rename bound occurrences inside `PForall`/`PExists`. If you extend the predicate
language with new binders, update `rename_free_in_pred` to not enter them.

**The Menhir parser is pre-generated:** `lib/parser/parser.ml` is generated from `parser.mly`
and checked in. If you see grammar shift/reduce conflicts, they must be resolved in the `.mly`
file and the parser regenerated — do not edit `parser.ml` by hand.
