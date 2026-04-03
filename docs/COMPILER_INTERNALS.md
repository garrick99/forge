# Forge Compiler Internals

This guide is for contributors who want to modify the compiler itself — not just write Forge
programs. It assumes you know at least one statically-typed language (Rust, C++, Haskell,
Java) but may not know OCaml. It focuses on the specific patterns used in this codebase,
not OCaml in general.

---

## OCaml Patterns Used in This Codebase

You do not need to master OCaml to contribute. Here are the five patterns that appear
everywhere in the compiler, each mapped to a familiar analogue.

### 1. Algebraic data types (variants)

```ocaml
type expr =
  | EInt of int64
  | EVar of ident
  | EBinop of binop * expr * expr
  | ECall of ident * expr list
```

**Rust analogue:** `enum Expr { Int(i64), Var(Ident), Binop(BinOp, Box<Expr>, Box<Expr>), ... }`

This is the AST. Every expression, statement, type, and predicate in Forge is represented
as a variant. The compiler never uses null/None to represent "no value" — it uses `option`:

```ocaml
type 'a option = None | Some of 'a    (* built-in *)
```

**Rust analogue:** `Option<T>`

### 2. Pattern matching

```ocaml
match expr with
| EInt n         -> Printf.sprintf "%Ld" n
| EVar id        -> id.name
| EBinop (op, l, r) ->
    let ls = emit_expr l in
    let rs = emit_expr r in
    emit_binop op ls rs
| _ -> failwith "unhandled"
```

**Rust analogue:** `match expr { Expr::Int(n) => ..., Expr::Var(id) => ..., _ => ... }`

The `_` arm is a catch-all. If you add a new variant to an `expr` type, the compiler will
give exhaustiveness warnings everywhere the type is pattern-matched. Follow those warnings —
they tell you every function you need to update.

### 3. Records (structs)

```ocaml
type env = {
  vars:    (string * var_info) list;
  fns:     (string * fn_sig) list;
  proof_ctx: proof_ctx;
  is_gpu_fn: bool;
  (* ... *)
}
```

**Rust analogue:** `struct Env { vars: Vec<(String, VarInfo)>, ... }`

Records are immutable by default. To "update" one field, you copy with override:

```ocaml
{ env with is_gpu_fn = true }   (* returns new env with is_gpu_fn changed, all else same *)
```

**Rust analogue:** `Env { is_gpu_fn: true, ..env }`

This immutability is fundamental to how the proof system works. The typechecker threads
an `env` through every node, returning an updated `env`. It never mutates in place.

### 4. Association lists (the "dict" type)

```ocaml
(string * var_info) list   (* list of (key, value) pairs *)
```

This is OCaml's standard "lightweight map". Key operations:

```ocaml
List.assoc "x" env.vars           (* lookup — raises Not_found if missing *)
List.assoc_opt "x" env.vars       (* lookup — returns None if missing *)
("x", info) :: env.vars           (* prepend — O(1), shadowing semantics *)
List.filter (fun (k,_) -> k <> "x") env.vars  (* remove *)
```

**Why association lists and not a hash map?** The typechecker passes `env` by value and
creates new environments for each scope. Association lists support this with O(1) extension
(prepend) and natural shadowing semantics. Performance is fine because Forge scopes are small.

### 5. Recursive functions on trees

```ocaml
let rec check_expr (env: env) (e: expr) : ty * env =
  match e with
  | EInt _ -> (TPrim (TUint U64), env)
  | EBinop (op, l, r) ->
      let (lt, env1) = check_expr env l in
      let (rt, env2) = check_expr env1 r in
      (* ... check types, generate obligations ... *)
      (result_ty, env2)
  | (* ... *)
```

Every expression checker takes `env` and returns `(type, updated_env)`. The `let ... in`
chain threads the env through each subexpression. If you need to add state, add it to `env`
and thread it through.

---

## The Key Data Structures

### `env` (lib/types/typecheck.ml)

The typechecker's state. Contains everything that's in scope at the current point in the
program:

```ocaml
type env = {
  vars:           (string * var_info) list;   (* local variables *)
  fns:            (string * fn_sig) list;     (* functions in scope *)
  types:          (string * ty) list;         (* type aliases *)
  structs:        (string * struct_def) list;
  enums:          (string * enum_def) list;
  current_fn:     fn_sig option;              (* function being checked *)
  proof_ctx:      proof_ctx;                  (* known facts for Z3 *)
  is_gpu_fn:      bool;
  after_barrier:  bool;
  in_varying_branch: bool;
}
```

The `proof_ctx` embedded in `env` is what gets passed to Z3.

### `proof_ctx` (lib/proof/proof_engine.ml)

The set of known-true facts at the current program point:

```ocaml
type proof_ctx = {
  pc_vars:    (string * ty) list;   (* variables Z3 needs to know about *)
  pc_assumes: pred list;            (* facts that are true here *)
  pc_lemmas:  (string * ...) list;  (* proved lemmas, injected as Z3 axioms *)
}
```

When the typechecker enters an `if cond { ... }` branch, it adds `cond` to `pc_assumes`
for the true branch and `!cond` for the false branch. When it adds a loop invariant, the
invariant goes into `pc_assumes`.

### `pred` (lib/ast/ast.ml)

The logical predicate type — Z3's input language, expressed as an OCaml tree:

```ocaml
type pred =
  | PVar of ident           (* variable reference *)
  | PInt of int64           (* integer literal *)
  | PBool of bool
  | PBinop of binop * pred * pred
  | PUnop of unop * pred
  | PForall of ident * ty * pred
  | PExists of ident * ty * pred
  | PIndex of pred * pred   (* array element: s[i] *)
  | PField of pred * string (* struct field: x.f *)
  | POld of pred            (* old(x) — value at function entry *)
  | PResult                 (* return value of current function *)
  (* ... *)
```

Proof obligations are `pred` values. The Z3 bridge translates `pred` → SMT-LIB2 text
in `proof_engine.ml::Z3Bridge.pred_to_smtlib`.

### `obligation` (lib/proof/proof_engine.ml)

```ocaml
type obligation = {
  ob_pred:    pred;             (* the property to prove *)
  ob_kind:    obligation_kind;  (* OBoundsCheck / ONoOverflow / etc. *)
  ob_loc:     loc;              (* source location for error messages *)
  ob_ctx:     (string * ty) list;
  ob_assumes: pred list;        (* facts known true here *)
  ob_status:  proof_status;     (* Discharged / Failed / Pending *)
}
```

---

## How a Function Goes Through the Compiler

Take this Forge function:

```forge
fn clamp(x: u64, lo: u64, hi: u64) -> u64
    requires lo <= hi
    ensures result >= lo && result <= hi
{
    if x < lo { lo } else if x > hi { hi } else { x }
}
```

Here's what each stage does:

### Stage 1: Lexer + Parser

`lib/lexer/lexer.mll` (ocamllex) tokenizes: `FN`, `IDENT("clamp")`, `LPAREN`, ...

`lib/parser/parser.mly` (Menhir) reduces tokens to an AST:
```
SFn {
  name = "clamp",
  params = [("x", TPrim (TUint U64)), ("lo", ...), ("hi", ...)],
  ret = TPrim (TUint U64),
  requires = [PBinop (Le, PVar "lo", PVar "hi")],
  ensures = [PBinop (And, PBinop(Ge, PResult, PVar "lo"), ...)],
  body = EIf (EBinop(Lt, EVar "x", EVar "lo"), EVar "lo",
           Some (EIf (EBinop(Gt, EVar "x", EVar "hi"), EVar "hi",
                   Some (EVar "x"))))
}
```

### Stage 2: Typechecker generates obligations

`check_stmt` in `lib/types/typecheck.ml` walks the AST:

1. Adds `lo <= hi` to `proof_ctx.pc_assumes` (the `requires`)
2. Sets `current_fn.fs_ensures = [result >= lo && result <= hi]`
3. Enters the if-expression body
4. For `if x < lo`:
   - True branch: adds `x < lo` to assumes, checks `lo` → type `u64`, fine
   - False branch: adds `x >= lo` to assumes, checks the nested if...
5. At each return point, generates an `OPostcondition` obligation:
   - On the `lo` branch: prove `lo >= lo && lo <= hi` given `{x < lo, lo <= hi}`
   - On the `hi` branch: prove `hi >= lo && hi <= hi` given `{x >= lo, x > hi, lo <= hi}`
   - On the `x` branch: prove `x >= lo && x <= hi` given `{x >= lo, x <= hi}`

### Stage 3: Z3 discharge

`proof_engine.ml::discharge_obligation` is called for each obligation.

For the `lo` branch postcondition:
```smt2
; Context: lo <= hi, x < lo
; Goal: lo >= lo && lo <= hi
(set-logic QF_LIA)
(declare-const lo Int)
(declare-const hi Int)
(declare-const x Int)
(assert (>= lo 0)) (assert (>= hi 0)) (assert (>= x 0))   ; u64 nonneg
(assert (<= lo hi))   ; requires
(assert (< x lo))     ; branch condition
(assert (not (and (>= lo lo) (<= lo hi))))   ; negation of goal
(check-sat)
; Expected: unsat → proof holds
```

Z3 returns `unsat` → `Discharged Tier1_SMT`.

### Stage 4: Codegen

`codegen_c.ml::emit_expr` walks the AST and emits C:

```c
uint64_t clamp(uint64_t x, uint64_t lo, uint64_t hi) {
    return (x < lo) ? lo : ((x > hi) ? hi : x);
}
```

Note: no runtime bounds checks, no assertions. Every check was proven unnecessary.

---

## Navigating the Source Files

### When you see a proof failure

1. Find the obligation kind in the error output (e.g., `OBoundsCheck "s"`)
2. In `typecheck.ml`, search for where that obligation kind is generated:
   ```
   grep -n "OBoundsCheck" lib/types/typecheck.ml
   ```
3. The obligation is created with `discharge_obligation ctx ob` or similar
4. The `ob_assumes` field shows what Z3 was given to work with
5. If it should have been provable but wasn't, the `pc_assumes` at that point may be
   missing a fact — check which env is threaded to that point

### When you add a new expression form

1. Add the variant to `lib/ast/ast.ml`
2. Add a production to `lib/parser/parser.mly`, then regenerate: `bash scripts/regen_parser.sh`
3. Add a token if needed to `lib/tokens/token.ml` and `lib/lexer/lexer.mll`
4. Handle in `check_expr` in `typecheck.ml` (returns `ty * env`)
5. Handle in `stmt_final_env` in `typecheck.ml` (returns `env`, no obligations — used for postcondition context)
6. Handle in `emit_expr` in `codegen_c.ml` (returns `string`)
7. Handle in `pred_to_string` in `proof_engine.ml` if it can appear in predicates
8. Follow the exhaustiveness warnings from `dune build` to find every other match site

### When Z3 keeps timing out

See `docs/Z3_TROUBLESHOOTING.md`.

### `env_assign_var` — the most important function

When the typechecker sees `x = expr`, it calls `env_assign_var env "x" rhs_pred`. This:
1. Renames all free occurrences of `"x"` in `env.proof_ctx.pc_assumes` to `"__x_pN"`
   (a fresh name)
2. Adds the new fact `x == rhs_pred` to `pc_assumes`

The renaming is necessary because `x` is being reassigned — the old `x` is now `__x_pN`.
Without this, Z3 would see contradictory facts (`x == old_val` and `x == new_val`).

**Do not bypass this function for new assignment forms.** Calling it in the wrong order,
or not calling it at all for a new mutable operation, will silently give the proof engine
wrong facts, causing false proofs or spurious failures.

### `stmt_final_env` — the second traversal

This function mirrors `check_stmt` but does NOT generate proof obligations. Its sole purpose
is to build the `env` that represents the state AFTER a statement, for use in postcondition
checking. If you add a new statement type and only implement it in `check_stmt`, postconditions
on code that follows that statement will see stale facts. Always implement both.

---

## Debugging Tips

**Print the SMT query:** In `proof_engine.ml`, find the `build_query` function and add a
`Printf.eprintf "%s\n" smt_text` before the Z3 call. Recompile and run your failing demo.
Paste the SMT text into https://rise4fun.com/z3 or run locally with `z3 -smt2 /dev/stdin`.

**Print the proof context:** Add `Printf.eprintf "[ctx] %s\n" (pred_to_string p)` inside the
obligation-building path to see what facts are in scope when an obligation is generated.

**Use `forge check` instead of `forge build`:** The `check` subcommand runs proof obligations
without emitting C, which is faster for iteration.

**Narrow down with a minimal demo:** Copy the failing demo to a new file and delete
everything not needed to reproduce the failure. A 5-line demo is much easier to debug
than a 50-line one.

---

## Building and Iterating (Windows)

All build commands run in WSL2:

```bash
# One-shot build and test
wsl.exe -e bash -c "cd /mnt/c/Users/kraken/forge && dune build && ./_build/default/bin/main.exe build demos/01_divide.fg"

# Watch mode (auto-rebuild on file change)
wsl.exe -e bash -c "cd /mnt/c/Users/kraken/forge && dune build --watch"

# Run a specific failing demo
wsl.exe -e bash -c "cd /mnt/c/Users/kraken/forge && ./_build/default/bin/main.exe build demos/INSERT_DEMO.fg 2>&1"

# Full test suite
wsl.exe -e bash -c "cd /mnt/c/Users/kraken/forge && bash test/run_all.sh"
```

The build takes about 3 seconds on first compile, under 1 second on incremental.
