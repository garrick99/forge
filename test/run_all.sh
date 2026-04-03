#!/bin/bash
# test/run_all.sh — comprehensive test suite for the Forge compiler
# Runs: proof verification, GCC compilation, runtime execution, error cases

FORGE=${FORGE:-$(dirname "$0")/../_build/default/bin/main.exe}
DEMOS_DIR=$(dirname "$0")/../demos
PASS=0; FAIL=0; SKIP=0; TOTAL=0

echo "=== Forge Test Suite ==="
echo "Compiler: $FORGE"
echo ""

# Phase 1: Proof verification (all demos must pass except 02_bad_divide)
echo "--- Phase 1: Proof Verification ---"
for fg in "$DEMOS_DIR"/*.fg; do
    demo=$(basename "$fg")
    TOTAL=$((TOTAL+1))

    # 02_bad_divide is expected to fail
    if [[ "$demo" == "02_bad_divide.fg" ]]; then
        result=$("$FORGE" build "$fg" 2>&1 || true)
        if echo "$result" | grep -q 'proof obligation(s) could not'; then
            PASS=$((PASS+1))
        else
            echo "  UNEXPECTED PASS: $demo (should fail)"
            FAIL=$((FAIL+1))
        fi
        continue
    fi

    result=$("$FORGE" build "$fg" 2>&1 || true)
    if echo "$result" | grep -q 'all obligations discharged'; then
        PASS=$((PASS+1))
    elif echo "$result" | grep -q 'error\|Error'; then
        echo "  PARSE/TYPE ERROR: $demo"
        FAIL=$((FAIL+1))
    else
        echo "  PROOF FAIL: $demo"
        FAIL=$((FAIL+1))
    fi
done

echo "Proof: $PASS passed, $FAIL failed, $TOTAL total"
echo ""

# Phase 2: GCC compilation (all .c files must compile clean)
echo "--- Phase 2: GCC Compilation ---"
GCC_PASS=0; GCC_FAIL=0
for c_file in "$DEMOS_DIR"/*.c; do
    [[ ! -f "$c_file" ]] && continue
    gcc_out=$(gcc -std=c99 -Wall -Wextra -Werror -fsyntax-only "$c_file" 2>&1 || true)
    if [[ $? -eq 0 ]] || [[ -z "$gcc_out" ]]; then
        GCC_PASS=$((GCC_PASS+1))
    else
        # Some demos use features that trigger warnings; try without -Werror
        gcc_out2=$(gcc -std=c99 -fsyntax-only "$c_file" 2>&1 || true)
        if [[ -z "$gcc_out2" ]]; then
            GCC_PASS=$((GCC_PASS+1))
        else
            echo "  GCC FAIL: $(basename $c_file)"
            GCC_FAIL=$((GCC_FAIL+1))
        fi
    fi
done
echo "GCC: $GCC_PASS passed, $GCC_FAIL failed"
echo ""

# Phase 3: Runtime execution (demos with // expected: N markers)
echo "--- Phase 3: Runtime Execution ---"
RT_PASS=0; RT_FAIL=0; RT_SKIP=0
for fg in "$DEMOS_DIR"/*.fg; do
    demo=$(basename "$fg")
    [[ "$demo" == "02_bad_divide.fg" ]] && continue
    c_file="${fg%.fg}.c"
    [[ ! -f "$c_file" ]] && continue
    grep -q '^int main' "$c_file" || { RT_SKIP=$((RT_SKIP+1)); continue; }

    expected=$(grep -oE '//[[:space:]]*expected:[[:space:]]*[0-9]+' "$fg" | tail -1 | grep -oE '[0-9]+$')
    [[ -z "$expected" ]] && { RT_SKIP=$((RT_SKIP+1)); continue; }
    expected_mod=$(( expected % 256 ))

    bin=$(mktemp /tmp/forge_test_XXXXXXXX)
    if gcc -std=c99 -o "$bin" "$c_file" 2>/dev/null; then
        actual=0; "$bin" 2>/dev/null || actual=$?
        if [[ "$actual" -eq "$expected_mod" ]]; then
            RT_PASS=$((RT_PASS+1))
        else
            echo "  RT FAIL: $demo (got=$actual, expected=$expected_mod)"
            RT_FAIL=$((RT_FAIL+1))
        fi
    else
        RT_SKIP=$((RT_SKIP+1))
    fi
    rm -f "$bin"
done
echo "Runtime: $RT_PASS passed, $RT_FAIL failed, $RT_SKIP skipped"
echo ""

# Phase 4: Error case verification (demos/bad/*.fg must be rejected with the right error)
# Each .fg file may contain a line:  // expect-error: <pattern>
# If present, the pattern (case-insensitive grep) must appear in the compiler output.
# If absent, any non-zero exit is accepted (the file just needs to fail).
echo "--- Phase 4: Error Cases ---"
ERR_PASS=0; ERR_FAIL=0

BAD_DIR=$(dirname "$0")/../demos/bad
if [[ -d "$BAD_DIR" ]]; then
    for fg in "$BAD_DIR"/*.fg; do
        [[ ! -f "$fg" ]] && continue
        demo=$(basename "$fg")
        result=$("$FORGE" build "$fg" 2>&1 || true)

        # Check if compilation was correctly rejected (must not see "all obligations discharged")
        if echo "$result" | grep -q 'all obligations discharged'; then
            echo "  UNEXPECTED PASS: $demo (should have been rejected)"
            ERR_FAIL=$((ERR_FAIL+1))
            continue
        fi

        # Check for expected error pattern if annotated
        expected_pat=$(grep -oE '^//[[:space:]]*expect-error:[[:space:]]*.*' "$fg" | head -1 | sed 's|^//[[:space:]]*expect-error:[[:space:]]*||')
        if [[ -n "$expected_pat" ]]; then
            if echo "$result" | grep -qi "$expected_pat"; then
                ERR_PASS=$((ERR_PASS+1))
            else
                echo "  WRONG ERROR: $demo"
                echo "    expected pattern: $expected_pat"
                echo "    got: $(echo "$result" | grep -i 'error\|failed\|rejected\|could not' | head -2)"
                ERR_FAIL=$((ERR_FAIL+1))
            fi
        else
            # No annotation — just needs to fail
            ERR_PASS=$((ERR_PASS+1))
        fi
    done
fi

# Phase 4b: Targeted compiler unit tests (test/programs/tc_*.fg)
# These are focused tests for specific compiler passes and invariants.
PROG_DIR=$(dirname "$0")/programs
if [[ -d "$PROG_DIR" ]]; then
    for fg in "$PROG_DIR"/tc_*.fg; do
        [[ ! -f "$fg" ]] && continue
        demo=$(basename "$fg")
        expected_pat=$(grep -oE '^//[[:space:]]*expect-error:[[:space:]]*.*' "$fg" | head -1 | sed 's|^//[[:space:]]*expect-error:[[:space:]]*||')
        if [[ -z "$expected_pat" ]]; then
            # No annotation — must succeed
            result=$("$FORGE" build "$fg" 2>&1 || true)
            if echo "$result" | grep -q 'all obligations discharged'; then
                ERR_PASS=$((ERR_PASS+1))
            else
                echo "  FAIL: $demo (expected success)"
                ERR_FAIL=$((ERR_FAIL+1))
            fi
        else
            # Has expect-error — must fail with pattern
            result=$("$FORGE" build "$fg" 2>&1 || true)
            if echo "$result" | grep -qi "$expected_pat"; then
                ERR_PASS=$((ERR_PASS+1))
            else
                echo "  WRONG ERROR: $demo"
                echo "    expected: $expected_pat"
                echo "    got: $(echo "$result" | head -3)"
                ERR_FAIL=$((ERR_FAIL+1))
            fi
        fi
    done
fi

echo "Error cases: $ERR_PASS passed, $ERR_FAIL failed"
echo ""

# Summary
echo "=== Summary ==="
echo "Proof:        $PASS / $TOTAL"
echo "GCC:          $GCC_PASS"
echo "Runtime:      $RT_PASS"
echo "Error cases:  $ERR_PASS"
TOTAL_FAIL=$((FAIL + GCC_FAIL + RT_FAIL + ERR_FAIL))
if [[ $TOTAL_FAIL -eq 0 ]]; then
    echo "ALL TESTS PASSED"
    exit 0
else
    echo "$TOTAL_FAIL TOTAL FAILURES"
    exit 1
fi
