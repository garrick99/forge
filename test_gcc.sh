#!/bin/bash
export PATH=/root/.opam/default/bin:/usr/local/bin:/usr/bin:/bin
export OCAMLFIND_CONF=/root/.opam/default/lib/findlib.conf

FORGE=/mnt/c/Users/kraken/forge/_build/default/bin/main.exe
DEMOS_DIR=/mnt/c/Users/kraken/forge/demos
PASS=0; FAIL=0

# Skip demo 02 (intentional proof failure)
for fg in "$DEMOS_DIR"/*.fg; do
    demo=$(basename "$fg")
    [[ "$demo" == "02_bad_divide.fg" ]] && continue

    out=$("$FORGE" build "$fg" 2>&1)
    if ! echo "$out" | grep -q "wrote"; then
        continue  # check-only demo or proof failure
    fi

    c_file="${fg%.fg}.c"
    cu_file="${fg%.fg}.cu"
    
    if [ -f "$c_file" ]; then
        gcc_out=$(gcc -std=c99 -Wall -Wextra -Werror -c -o /dev/null "$c_file" 2>&1)
        if [ $? -eq 0 ]; then
            PASS=$((PASS+1))
            echo "GCC PASS: $demo"
        else
            FAIL=$((FAIL+1))
            echo "GCC FAIL: $demo"
            echo "$gcc_out"
            echo "---"
        fi
    fi
done

echo ""
echo "GCC Results: $PASS passed, $FAIL failed"
