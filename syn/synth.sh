#!/bin/sh

set -e

ROOT="$1"
SRC="$ROOT/../src"

rm -rf build
mkdir -p build
cd build

ghdl -a --std=08 --work=aes_lib "$SRC/aes_pkg.vhd"
ghdl -a --std=08 --work=aes_lib "$SRC/input_conversion.vhd"
ghdl -a --std=08 --work=aes_lib "$SRC/output_conversion.vhd"
ghdl -a --std=08 --work=aes_lib "$SRC/key_expansion.vhd"
ghdl -a --std=08 --work=aes_lib "$SRC/cipher.vhd"
ghdl -a --std=08 --work=aes_lib "$SRC/aes.vhd"
# ghdl --synth --std=08 --work=aes_lib aes
yosys -m ghdl -p 'ghdl --std=08 --work=aes_lib --no-formal aes; synth_ice40 -json aes.json'
# nextpnr-ice40 --hx1k --package tq144 --json aes.json --asc aes.asc --pcf-allow-unconstrained
# icepack aes.asc aes.bin
# iceprog aes.bin