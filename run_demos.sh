#!/bin/bash
export PATH=/root/.opam/default/bin:/usr/local/bin:/usr/bin:/bin
export OCAMLFIND_CONF=/root/.opam/default/lib/findlib.conf

FORGE=/mnt/c/Users/kraken/forge/_build/default/bin/main.exe
DEMOS_DIR=/mnt/c/Users/kraken/forge/demos
PASS=0; FAIL=0

for fg in "$DEMOS_DIR"/*.fg; do
    demo=$(basename "$fg")
    out=$("$FORGE" build "$fg" 2>&1)
    if echo "$out" | grep -q "wrote\|check complete"; then
        PASS=$((PASS+1))
        echo "PASS: $demo"
    else
        FAIL=$((FAIL+1))
        echo "FAIL: $demo"
        echo "$out" | tail -8
        echo "---"
    fi
done

echo ""
echo "Results: $PASS passed, $FAIL failed"
