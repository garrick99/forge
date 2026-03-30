# Contributing to Forge

Thank you for your interest in Forge. This document explains how to contribute.

## Getting Started

```bash
# Clone
git clone https://github.com/garrick99/forge.git
cd forge

# Install dependencies (OCaml 5.0+, Dune)
opam install dune

# Install Z3 (runtime dependency)
apt install z3  # or brew install z3

# Build
dune build

# Run tests
bash test/run_all.sh
```

## Project Structure

```
lib/
  ast/        — AST node types
  lexer/      — Ocamllex tokenizer
  parser/     — Menhir grammar (pre-generated parser.ml)
  tokens/     — Token type definitions
  types/      — Type checker + proof obligation generation
  proof/      — Z3 bridge + three-tier discharge engine
  codegen/    — C99 emitter + PTX backend
bin/
  main.ml     — CLI driver
demos/        — 1000+ verified demos
  std/        — Standard library modules
  bad/        — Intentional failure examples
apps/         — Real-world verified applications
docs/         — Manual and documentation
test/         — Test scripts
```

## Development Workflow

1. **Make changes** to compiler source in `lib/` or `bin/`
2. **Build**: `dune build`
3. **Test**: Run a specific demo: `./_build/default/bin/main.exe build demos/01_divide.fg`
4. **Regression test**: `bash test/run_all.sh` (runs proof, GCC, and runtime tests)
5. **Commit** with a descriptive message

## Parser Changes

The parser (`lib/parser/parser.ml`) is **pre-generated** from `lib/parser/parser.mly`. To regenerate after grammar changes:

```bash
cd lib/parser
menhir --explain --external-tokens Token parser.mly
```

Then update `lib/parser/token.ml` to match any new tokens, and add keywords to `lib/lexer/lexer.mll`.

## Adding Demos

- Each demo gets a unique number prefix (e.g., `1017_my_feature.fg`)
- Start with `// expected: 0` for runtime testing
- End with `fn main() -> u64 { 0u64 }`
- Every `while` loop must have `invariant` and `decreases`
- Run `forge build` to verify before committing

## Code Style

- OCaml: follow existing style (no auto-formatter)
- Forge demos: 80 columns, descriptive comments
- Commit messages: imperative mood, describe the "what" and "why"

## Reporting Issues

Open an issue with:
1. Forge source file that triggers the problem
2. Full compiler output (including proof obligation details)
3. Expected vs actual behavior
4. Forge compiler version (`forge version`)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
