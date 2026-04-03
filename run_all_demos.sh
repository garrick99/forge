#!/bin/bash
export PATH=/root/.opam/default/bin:/usr/bin:/bin
cd /mnt/c/Users/kraken/forge
passed=0
failed=0
# Demos in demos/bad/ are expected to be rejected by the proof engine.
# The main demos/ directory has 02_bad_divide.fg as an intentional failure.
expected_reject="demos/02_bad_divide.fg"
for f in demos/[0-9]*.fg; do
    [ -f "$f" ] || continue
    out=$(./_build/default/bin/main.exe check "$f" 2>&1)
    last=$(echo "$out" | tail -1)
    summary=$(echo "$out" | grep "proof summary")
    if echo "$last" | grep -q "no errors"; then
        passed=$((passed+1))
    elif [ "$f" = "$expected_reject" ] && echo "$out" | grep -q "REJECTED\|failed"; then
        passed=$((passed+1))
    else
        echo "FAIL: $f"
        echo "  $summary"
        failed=$((failed+1))
    fi
done
echo "=== $passed passed, $failed failed ==="
