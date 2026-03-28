#!/bin/bash
export PATH=/root/.opam/default/bin:/usr/local/bin:/usr/bin:/bin
export OCAMLFIND_CONF=/root/.opam/default/lib/findlib.conf
FORGE=/mnt/c/Users/kraken/forge/_build/default/bin/main.exe
"$FORGE" build "$1" 2>&1
