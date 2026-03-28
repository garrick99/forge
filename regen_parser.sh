#!/bin/bash
export PATH=/root/.opam/default/bin:/usr/local/bin:/usr/bin:/bin
export OCAMLFIND_CONF=/root/.opam/default/lib/findlib.conf
cd /mnt/c/Users/kraken/forge/lib/parser
/root/.opam/default/bin/menhir --explain --external-tokens Token parser.mly 2>&1
echo "exit: $?"
