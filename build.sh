#!/bin/bash
eval $(/root/.opam/default/bin/opam env --root=/root/.opam --switch=default)
cd /mnt/c/Users/kraken/forge
/root/.opam/default/bin/dune build 2>&1
