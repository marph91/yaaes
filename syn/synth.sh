#!/bin/sh

set -e

ROOT="$(pwd)/.."

rm -rf build
mkdir -p build
cd build

ghdl -a --std=08 --work=aes_lib "$ROOT"/src/aes_pkg.vhd
ghdl -a --std=08 --work=aes_lib "$ROOT"/src/input_conversion.vhd
ghdl -a --std=08 --work=aes_lib "$ROOT"/src/output_conversion.vhd
ghdl -a --std=08 --work=aes_lib "$ROOT"/src/key_expansion.vhd
ghdl -a --std=08 --work=aes_lib "$ROOT"/src/cipher.vhd
ghdl -a --std=08 --work=aes_lib "$ROOT"/src/aes.vhd
# ghdl --synth --std=08 --work=aes_lib aes
yosys -m ghdl -p 'ghdl --std=08 --work=aes_lib aes; synth_ice40 -json aes.json'
nextpnr-ice40 --hx1k --package tq144 --json aes.json --asc aes.asc --pcf-allow-unconstrained
# icepack aes.asc aes.bin
# iceprog aes.bin