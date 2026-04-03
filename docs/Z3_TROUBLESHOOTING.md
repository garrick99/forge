# Z3 Troubleshooting Guide

This guide covers the most common Z3 failure modes in the Forge compiler: timeouts, unknown
results, spurious failures, and how to fix them.

---

## How Forge Uses Z3

For each proof obligation, `proof_engine.ml::discharge_obligation` builds an SMT-LIB2 query:

```smt2
(set-logic ...)
(declare-const x Int)
...
(assert fact1)           ; known-true facts (requires, loop invariants, branch conditions)
(assert fact2)
(assert (not goal))      ; NEGATION of what we want to prove
(check-sat)
```

If Z3 returns `unsat` (the negation is unsatisfiable), the goal is proved.
If Z3 returns `sat`, it found a counterexample — proof fails with a model.
If Z3 returns `unknown` or times out — escalates to Tier 2 (guided proof).

The logic selected depends on the goal content:

| Goal contains | Logic | Notes |
|---------------|-------|-------|
| Only linear arithmetic | `QF_LIA` | Fast, almost never times out |
| Quantifiers (`forall`/`exists`) | `AUFLIA` | Slower; MBQI trigger-based |
| Bitwise ops (`&`, `\|`, `^`, `<<`, `>>`) | `QF_BV` | BV mode; quantifiers not allowed |
| Nonlinear (`var * var`) | `QF_NIA` with nlsat tactic | Can timeout on complex products |
| Div or mod | Default Z3 (no tactic override) | nlsat cannot handle div/mod |
| Array selects + quantifiers | `AUFLIA` + nonneg axioms | u64 array element non-negativity injected |

---

## Timeout Patterns and Fixes

### Pattern 1: Nonlinear multiplication

**Symptom:** Obligation involves `a * b` where both `a` and `b` are variables.
Z3 returns `unknown` after a few seconds.

**Example:**
```forge
fn area(w: u64, h: u64) -> u64
    requires w <= 1000u64 && h <= 1000u64
    ensures result <= 1000000u64  // w * h <= 10^6
{ w * h }
```

**Why it times out:** Z3's NIA (nonlinear integer arithmetic) solver uses nlsat, which
works by algebraic decomposition. For `w * h <= 10^6` given `w <= 1000 && h <= 1000`, the
connection is obvious to a human but requires a product decomposition that nlsat can be
slow on.

**Fix: add a multiplication hint**

```forge
fn area(w: u64, h: u64) -> u64
    requires w <= 1000u64 && h <= 1000u64
    ensures result <= 1000000u64
{
    hint(w * h <= w * 1000u64);  // monotonicity in second arg
    hint(w * 1000u64 <= 1000u64 * 1000u64);  // monotonicity in first arg
    w * h
}
```

Each `hint(P)` adds `(assert P)` before the main query. Z3 accepts the hints without
re-proving them (they are trusted). Supply the smallest hints that bridge the gap.

**Alternative fix: bound the product directly**

```forge
requires w * h <= 1000000u64   (* push the bound into requires *)
```

If the caller can establish the bound, don't make the function prove it from parts.

---

### Pattern 2: Quantified postcondition without invariant

**Symptom:** `ensures forall i < n, s[i] == val` fails even though the loop clearly
establishes this.

**Why:** The postcondition checker needs the loop invariant to have propagated the quantified
fact to the post-loop environment. Without a matching invariant, the post-loop env has no
quantified fact about `s`.

**Fix: carry the invariant**

```forge
while k < n
    invariant k <= n
    invariant forall j: u64, j < k ==> s[j] == val  // ← this is required
    decreases n - k
{
    s[k] = val;
    k = k + 1u64;
}
```

After the loop exits (`k == n`), the invariant becomes `forall j < n, s[j] == val`, which
directly matches the postcondition. Without the invariant, Z3 has no `forall` fact to work
with.

---

### Pattern 3: Quantifiers + nonlinear in the same goal

**Symptom:** A goal with both `forall` and multiplication. Z3 times out or returns unknown.

**Why:** `AUFLIA` (the logic for quantified integer arithmetic) uses MBQI (model-based
quantifier instantiation), which instantiates the quantifier and then checks the resulting
ground formula. If the ground formula is nonlinear, MBQI gets stuck.

**Fix option A: separate the concerns**

Split into two obligations: first prove the nonlinear bound (no quantifier), then use it as
a fact in the quantified proof.

```forge
let bound: u64 = n * stride;
hint(bound == n * stride);
// ... now the quantified goal doesn't need to multiply vars
```

**Fix option B: use a proved lemma**

```forge
lemma mul_monotone(a: u64, b: u64, c: u64)
    requires a <= b
    ensures a * c <= b * c
{ /* manual proof term or Z3 */ }
```

Once proved, `mul_monotone` is injected as an axiom into all subsequent queries.

---

### Pattern 4: BV mode + quantifiers

**Symptom:** A bitwise operation in the goal AND a `forall` in the ensures. The compiler
raises `cannot use quantifiers in QF_BV mode`.

**Why:** `QF_BV` is quantifier-free. This is a hard Z3 limitation, not a Forge bug.

**Fix: avoid mixing bitwise and quantified postconditions**

Restructure to separate the bitwise computation from the quantified property:

```forge
// Instead of: ensures forall i < n, out[i] == in[i] & mask
// Use:
fn mask_val(x: u64, mask: u64) -> u64
    ensures result == x & mask  // BV goal, no quantifier
{ x & mask }

// Then the caller proves the forall separately in the linear/array domain
```

---

### Pattern 5: Too many facts in context

**Symptom:** A function with many `requires` clauses or a deeply nested loop. Proofs that
should be trivial (e.g., `x >= 0` for a u64) time out because Z3 has hundreds of facts to
sift through.

**Fix:** Most common in deeply nested loops. Use `hint` to give Z3 the specific fact it
needs without requiring it to search the full context:

```forge
hint(inner_var < outer_bound);   // tell Z3 exactly what to use
```

Also check whether some `requires` clauses are overly specific and can be simplified.

---

## Reading the Failure Diagnostic

When a proof fails, Forge outputs:

```
proof obligation failed: OPostcondition "my_fn"
  goal: result >= lo && result <= hi
  counterexample:
    lo = 5, hi = 3, x = 4
    (this violates the goal because lo > hi)
```

The counterexample is Z3's satisfying assignment for `not goal`. It shows a specific input
that would violate the property. If the counterexample is valid (the inputs are actually
reachable), your specification or implementation is wrong. If the counterexample is
impossible (it violates a `requires` clause you forgot to add), add the missing precondition.

**Common mistake:** The counterexample shows `lo = 5, hi = 3` but you know your callers
always pass `lo <= hi`. This means the `requires` clause is missing or misspelled. Add
`requires lo <= hi` and rerun.

---

## Printing the Raw SMT Query

When none of the above fixes work, inspect the raw Z3 input.

In `lib/proof/proof_engine.ml`, find the `build_query` function and temporarily add:

```ocaml
Printf.eprintf "=== SMT QUERY ===\n%s\n=================\n%!" smt_text;
```

Rebuild (`dune build`) and run the failing demo. Copy the printed query and run it manually:

```bash
echo "PASTE QUERY HERE" | z3 -smt2 /dev/stdin
```

You can add extra `(assert ...)` lines to the query to test potential hints before adding
them to the Forge source.

---

## Timeout Threshold

The Z3 timeout is currently hardcoded in `proof_engine.ml`. Search for `timeout` or
`rlimit` to find it. The default is conservative; for complex quantified proofs you may
need to increase it temporarily while developing, then add hints to bring the proof time
back down.

---

## Escalating to Manual Proof

If Z3 cannot handle an obligation at all (returns unknown consistently even with hints),
escalate to Tier 3 (manual proof terms):

```forge
fn my_lemma(n: u64) -> u64
    ensures result == n * (n + 1u64) / 2u64
{
    proof {
        induction n {
            base: refl,      // P(0) by reflexivity
            step: auto       // P(n+1) given P(n) — try Z3 on the inductive step
        }
    };
    // ... implementation
}
```

See `LANGUAGE.md` section on Proof Terms for the full proof term language.
