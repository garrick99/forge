#!/bin/bash
# test_runtime.sh — compile each demo to C, run those with main(), verify exit code.
# Expected values extracted from comments: // ... = N  (last occurrence, N%256)
export PATH=/root/.opam/default/bin:/usr/local/bin:/usr/bin:/bin
export OCAMLFIND_CONF=/root/.opam/default/lib/findlib.conf

FORGE=/mnt/c/Users/kraken/forge/_build/default/bin/main.exe
DEMOS_DIR=/mnt/c/Users/kraken/forge/demos
PASS=0; FAIL=0; SKIP=0

for fg in "$DEMOS_DIR"/*.fg; do
    demo=$(basename "$fg")
    [[ "$demo" == "02_bad_divide.fg" ]] && continue   # intentional proof failure

    # Build forge → C
    out=$("$FORGE" build "$fg" 2>&1)
    c_file="${fg%.fg}.c"
    [[ ! -f "$c_file" ]] && continue   # proof-only demos produce no C

    # Must have a main function to run
    grep -q '^int main' "$c_file" || { SKIP=$((SKIP+1)); continue; }

    # Extract expected exit code. Look for (in order):
    #   // expected: N   — explicit override (highest priority)
    #   // ... = N       — sum/total in a comment (last occurrence)
    #   // N             — bare number at end of comment line (last occurrence)
    expected=$(grep -oE '//[[:space:]]*expected:[[:space:]]*[0-9]+' "$fg" | tail -1 | grep -oE '[0-9]+$')
    if [[ -z "$expected" ]]; then
        expected=$(grep -oE '//.*=[[:space:]]*[0-9]+' "$fg" | tail -1 | grep -oE '[0-9]+$')
    fi
    if [[ -z "$expected" ]]; then
        expected=$(grep -oE '//[[:space:]]*[0-9]+[[:space:]]*$' "$fg" | tail -1 | grep -oE '[0-9]+')
    fi
    if [[ -z "$expected" ]]; then
        SKIP=$((SKIP+1)); continue
    fi
    expected_mod=$(( expected % 256 ))

    # Compile with gcc (no -Werror here — just need a runnable binary)
    bin=$(mktemp /tmp/forge_XXXXXXXX)
    gcc_out=$(gcc -std=c99 -o "$bin" "$c_file" 2>&1)
    if [[ $? -ne 0 ]]; then
        FAIL=$((FAIL+1))
        echo "GCC FAIL: $demo"
        echo "$gcc_out" | head -3
        rm -f "$bin"
        continue
    fi

    # Run and check exit code
    "$bin"
    actual=$?
    rm -f "$bin"

    if [[ "$actual" -eq "$expected_mod" ]]; then
        PASS=$((PASS+1))
        echo "PASS: $demo  (exit=$actual)"
    else
        FAIL=$((FAIL+1))
        echo "FAIL: $demo  (exit=$actual, expected=$expected_mod from $expected)"
    fi
done

echo ""
echo "Runtime Results: $PASS passed, $FAIL failed, $SKIP skipped (no main or no expected)"
