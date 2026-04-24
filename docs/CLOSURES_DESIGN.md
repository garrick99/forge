# Closures in Forge — Design Sketch

**Status:** design only; implementation deferred.  FORGE71 currently
rejects capturing lambdas at typecheck with a clear error message; the
manual struct + fn-pointer pattern in `demos/303_closure_simulation.fg`
is the recommended workaround and is formally verified today.

## Current behaviour (post-FORGE71)

Non-capturing lambdas (`\(x: i32) -> x + 1`) work: they lift to plain
C functions `__forge_lambda_N`, and the existing fn-pointer typedef
machinery (FORGE69) handles them as first-class values.

Capturing lambdas (`\(x: i32) -> x + k` where `k` is an enclosing
local) trigger a compile-time error pointing users at the manual
workaround.

## Why not just implement them?

The obstacle is uniform representation.  A Forge type `fn(i32) -> i32`
is one thing, whether it came from a bare function or a closure.  To
support captures, every `TFn` C value must carry environment state:

```c
typedef struct {
    void *env;
    RET (*fn)(void *, ARGS);
} forge_fn_ARGS_ret_RET_t;
```

That's straightforward, but it cascades through:

- **Every call site** that goes through a TFn-typed value — rewriting
  `f(x, y)` to `f.fn(f.env, x, y)` and distinguishing it from direct
  calls `foo(x, y)` where `foo` is a top-level fn.
- **Named functions used as values** — `let f = add;` needs a wrapper
  thunk `__forge_thunk_add(void *env, ...) { return add(...); }` so it
  presents as the fat struct.
- **Every existing fn-pointer demo** — the generated C changes
  throughout.  About a dozen demos use TFn values today.
- **All three codegen backends** — `codegen_c.ml`, `codegen_cuda.ml`,
  `codegen_ptx.ml` each need the rewriting.

## Staged plan

### Phase 1 — representation flip, no new features

1. `emit_ty` on `TFn` emits the struct type name.
2. Typedef emission switches to the fat struct.
3. Every `IFn` gets a synthesized thunk `__forge_thunk_<name>` that
   ignores env and tail-calls the real function.
4. `ECall(EVar id, args)` where `id` resolves to an `IFn` stays as
   a direct call; any other callee shape dispatches through
   `closure.fn(closure.env, args...)`.
5. Complex callees (e.g. `(pick(0))(x)`) bind to a fresh local first
   to avoid double-evaluation — emit via GCC statement expression or
   lift to an SLet.
6. Regression pass: all existing fn-pointer demos produce identical
   observable behaviour.

### Phase 2 — capture

1. Lift capture detection (already in `find_lambda_captures`) to
   record the captured `(name, type, loc)` list on the lambda's AST
   node.
2. Synthesize an env struct per unique capture-type-set:
   `struct __forge_env_N { TYPE1 c1; TYPE2 c2; ... };`.
3. Emit the thunk `__forge_thunk_N(void *env, ARGS) {
       struct __forge_env_N *e = env; ... body-with-captures-rewritten; }`
   where capture references become `e->cN`.
4. At the lambda expression site, emit:
   ```c
   struct __forge_env_N __env_N = { captured_vals };
   (forge_fn_ARGS_ret_RET_t){ .env = &__env_N, .fn = __forge_thunk_N }
   ```

### Phase 3 — escape analysis and heap option

The Phase 2 design captures on the stack; the env pointer becomes
dangling if the closure escapes its declaring scope (return the
closure up, store it in a heap struct, etc.).  Two options:

- **Affine-lifetime closures**: type-system-enforce that capturing
  closures cannot escape their creation scope (Rust's `Fn` without
  `'static`).  Matches Forge's proof discipline; most uses (map,
  reduce, foreach) work.
- **Heap-allocated env**: explicit `move` capture that mallocs the
  env, with lifetime tracked linearly.  More flexible but adds GC
  pressure and fights Forge's no-implicit-malloc ethos.

Lean toward affine-lifetime first.

### Phase 4 — GPU backends

The `codegen_cuda.ml` and `codegen_ptx.ml` paths need the same
rewriting, but GPU kernels rarely materialise fn-pointers as values.
Likely just a mechanical copy of the Phase 1/2 logic, plus ensuring
the env struct fits in a `.const` or `.local` slot.

## Tests to add when implementing

- `mapping closure`: `apply(span<i32>, \(x) -> x * scale)` with `scale`
  captured.
- `reduce closure`: `fold(span<i32>, init, \(acc, x) -> acc + x + bias)`.
- `returned closure` (phase 3): `fn make_adder(k: i32) -> fn(i32) -> i32`
  — must either heap-allocate or be rejected by affine lifetime.
- Interaction with the existing vtable demos (1045, 303) — closures as
  struct fields, closures in vtables.

## References

- FORGE69 (24bc321): fn-pointer typedef for locals
- FORGE71 (0096496): capture-detection error + narrowed collector
- FORGE71 note in `demos/303_closure_simulation.fg` shows the manual
  struct + fn-pointer pattern that works today.
