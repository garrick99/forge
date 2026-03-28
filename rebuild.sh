#!/bin/bash
export PATH=/root/.opam/default/bin:/usr/local/bin:/usr/bin:/bin
export OCAMLFIND_CONF=/root/.opam/default/lib/findlib.conf
export OCAMLPATH=/root/.opam/default/lib
export CAML_LD_LIBRARY_PATH=/root/.opam/default/lib/stublibs
cd /mnt/c/Users/kraken/forge
/root/.opam/default/bin/dune build 2>&1
