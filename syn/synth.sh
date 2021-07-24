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
yosys -m ghdl -p 'ghdl --std=08 --work=aes_lib --no-formal aes; synth_ecp5 -abc9 -json aes.json'
nextpnr-ecp5 --85k --package CABGA381 --json aes.json --lpf ../constraints/ulx3s_v20.lpf --textcfg aes.config --lpf-allow-unconstrained --freq 100
