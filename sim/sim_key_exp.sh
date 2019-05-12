#!/bin/sh

set -e

ROOT="$(pwd)"/..
GHDL_ARGS=--std=08

rm -rf "$ROOT"/build
mkdir -p "$ROOT"/build
cd "$ROOT"/build

ghdl -a "$GHDL_ARGS" "$ROOT"/src/aes_pkg.vhd
ghdl -a "$GHDL_ARGS" "$ROOT"/src/key_expansion.vhd
ghdl -e "$GHDL_ARGS" key_exp

ghdl -a "$GHDL_ARGS" "$ROOT"/sim/tb_key_expansion.vhd
ghdl -e "$GHDL_ARGS" tb_key_exp
ghdl -r tb_key_exp --wave=tb_key_exp.ghw --stop-time=1us
gtkwave tb_key_exp.ghw "$ROOT"/sim/tb_key_exp.gtkw
