# Forge Compiler — Project Instructions

## Build

```bash
# In WSL (build requires opam environment)
cd /mnt/c/users/kraken/forge
opam exec -- dune build

# Binary location
./_build/default/bin/main.exe
```

The parser (`lib/parser/parser.ml`) is **pre-generated and committed**. Do NOT add a `(menhir ...)` stanza — Dune 3.22 + Menhir has a cycle bug. To regenerate after grammar changes, use the manual `--infer-write-query` / `--infer-read-reply` protocol (see `regen_parser.sh`).

## Test

```bash
# Single demo
opam exec -- ./_build/default/bin/main.exe build demos/01_divide.fg

# All demos (bash loop)
for f in demos/*.fg; do opam exec -- ./_build/default/bin/main.exe build "$f" 2>&1 | tail -1; done

# GCC validation on generated C
bash test_gcc.sh

# Runtime execution tests (demos with // expected: N markers)
bash test_runtime.sh
```

Only `demos/02_bad_divide.fg` is expected to fail (intentional — demonstrates proof rejection).

## Architecture

```
lib/ast/ast.ml              — AST node types (~340 lines)
lib/lexer/lexer.mll         — Ocamllex lexer (~225 lines)
lib/parser/parser.mly       — Menhir grammar (~1125 lines, pre-generated to parser.ml)
lib/types/typecheck.ml      — Type checker + proof obligation generation (~3700 lines)
lib/proof/proof_engine.ml   — Z3 bridge + three-tier discharge (~1225 lines)
lib/codegen/codegen_c.ml    — C99 emitter (~2150 lines)
lib/codegen/codegen_ptx.ml  — PTX/CUDA backend (~620 lines)
bin/main.ml                 — CLI driver (~290 lines)
demos/                      — 780 verified demos
demos/bad/                  — 10 intentional failures
demos/std/                  — Standard library (prelude, math, collections, crypto, etc.)
```

Pipeline: parse → typecheck → generate obligations → discharge (Z3/guided/manual) → erase proofs → emit C99/CUDA C.

## Key Compiler Internals

### Proof obligation types
`OPrecondition`, `OPostcondition`, `OBoundsCheck`, `ONoOverflow`, `OTermination`, `OLinear`, `OInvariant`

### Cross-function postcondition injection
When `let x = f(args)` is bound, `inject_postconds` (in `stmts_final_env | SLet`) substitutes the callee's `ensures` clauses into the caller's proof context. This enables multi-step verified pipelines.

### Recursive induction hypothesis injection
For well-founded recursive functions (`decreases` clause), `inject_rec` walks the body to find recursive `SLet` calls and injects the function's own postconditions as induction hypotheses (sound by strong induction on the decreasing measure).

### Array mutation tracking (SSA)
`env_array_write` renames `s → __s_pN` and adds write facts + frame facts (`forall j != idx, s[j] == __s_prev[j]`). For conditional writes, `SExpr(EIf)` in `stmt_final_env` builds ITE predicates. `expr_final_env` handles top-level EIf bodies (elif chains) similarly.

### `expr_final_env` vs `stmt_final_env`
- `expr_final_env` handles `EBlock` (processes stmts then trailing expr) and `EIf` (ITE-models scalar + array mutations). Returns env unchanged for other expression types.
- `stmt_final_env` handles `SLet`, `SExpr(EAssign)`, `SExpr(EIf)` (with full ITE modeling), `SExpr(ECall)` (void call postcondition injection), `SWhile`, `SFor`.
- Critical: `extract_block_arr_assigns` only sees direct `s[i] = v` writes at the top level of a block — NOT writes nested inside inner `if` statements. For swap patterns, use let-bound temporaries (`let tmp = s[i]; s[i] = s[j]; s[j] = tmp`).

## Z3 / Proof Patterns

### Quantified sorted precondition
Use `&&` format for better MBQI trigger matching:
```forge
requires forall i: u64, forall j: u64, i < j && j < n ==> s[i] <= s[j]
```
NOT nested `==>`: `i < j ==> j < n ==> s[i] <= s[j]`

### Binary search frontier invariants
Guard with `ans == n` to prevent violation in the found branch:
```forge
invariant ans == n ==> forall k: u64, k < lo ==> s[k] < target
invariant ans == n ==> forall k: u64, k >= hi && k < n ==> s[k] > target
```

### Nonlinear arithmetic
Z3 struggles with products like `state * nalpha + input[i] < nstates * nalpha`. Use explicit bounds checks (`if idx < nstates * nalpha`) or restructure to avoid nonlinear terms.

### EIf body postconditions
Functions with top-level `EIf` bodies (no wrapping `EBlock`) now get ITE-modeled mutations via `expr_final_env`. But nested inner `if` blocks within elif branches are NOT extracted. Use ITE-valued direct writes instead:
```forge
// Good: direct ITE writes (extracted by collect_chain_arr_assigns)
let v0: u64 = s[0u64];
let v1: u64 = s[1u64];
s[0u64] = if v0 <= v1 { v0 } else { v1 };
s[1u64] = if v0 <= v1 { v1 } else { v0 };

// Bad: nested if swap (not extracted)
if s[0u64] > s[1u64] { let tmp = s[0u64]; s[0u64] = s[1u64]; s[1u64] = tmp; }
```

### `while !done` flag pattern
Avoid boolean flag loops — they break termination proofs when the flag-set branch doesn't decrease the measure. Use direct loop conditions instead.

## Reserved Keywords
`result`, `trans` — cannot be used as variable names.

## Demo Conventions
- Every demo has `fn main() -> u64 { 0u64 }` (or meaningful return)
- Intentional failures go in `demos/bad/`
- Demo numbers are unique — no two files share a number prefix
- Milestones: 500 (`500_milestone.fg`), 700 (`700_milestone6.fg`), 750 (`750_milestone7.fg`)
