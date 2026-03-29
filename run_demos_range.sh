#!/bin/bash
export PATH=/root/.opam/default/bin:/usr/bin:/bin
cd /mnt/c/Users/kraken/forge
passed=0
failed=0
for f in demos/3[0-2]*.fg demos/[12][0-9][0-9]*.fg; do
    [ -f "$f" ] || continue
    out=$(./_build/default/bin/main.exe check "$f" 2>&1)
    summary=$(echo "$out" | grep "proof summary")
    last=$(echo "$out" | tail -1)
    if echo "$last" | grep -q "no errors"; then
        passed=$((passed+1))
    else
        echo "FAIL: $f"
        echo "$summary"
        failed=$((failed+1))
    fi
done
echo "--- $passed passed, $failed failed ---"
