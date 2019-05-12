#!/bin/sh

set -e

ROOT="$(pwd)"/..
GHDL_ARGS=--std=08

rm -rf "$ROOT"/build
mkdir -p "$ROOT"/build
cd "$ROOT"/build

ghdl -a "$GHDL_ARGS" "$ROOT"/src/aes_pkg.vhd
ghdl -a "$GHDL_ARGS" "$ROOT"/src/input_conversion.vhd
ghdl -a "$GHDL_ARGS" "$ROOT"/src/output_conversion.vhd
ghdl -a "$GHDL_ARGS" "$ROOT"/src/key_expansion.vhd
ghdl -a "$GHDL_ARGS" "$ROOT"/src/cipher.vhd
ghdl -a "$GHDL_ARGS" "$ROOT"/src/aes.vhd
ghdl -e "$GHDL_ARGS" aes

ghdl -a "$GHDL_ARGS" "$ROOT"/sim/tb_aes.vhd
ghdl -e "$GHDL_ARGS" tb_aes
ghdl -r tb_aes --wave=tb_aes.ghw
gtkwave tb_aes.ghw "$ROOT"/sim/tb_aes.gtkw
