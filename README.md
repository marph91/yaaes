# YAAES

![](https://github.com/marph91/yaaes/workflows/testsuite/badge.svg)
[![codecov](https://codecov.io/gh/marph91/yaaes/branch/master/graph/badge.svg)](https://codecov.io/gh/marph91/yaaes)

VHDL implementation of the symmetric block cipher AES, as specified in the NIST FIPS 197, respectively NIST SP 800-38A.

Currently supported:

| Mode | Encryption | Decryption | Bitwidth (In & Out) |
| :---: | :---: | :---: | :---: |
| ECB | :heavy_check_mark: | :x: | 8, 32 and 128 |
| CBC | :heavy_check_mark: | :x: | 8, 32 and 128 |
| CFB | :heavy_check_mark: | :heavy_check_mark: | 8, 32 and 128 |
| OFB | :heavy_check_mark: | :heavy_check_mark: | 8, 32 and 128 |
| CTR | :x: | :x: | - |

## Example results

128 bit encryption in ECB mode:

- simulation results:
  - latency: 26 cycles (f. e. 260 ns at 100 MHz clock)
- synthesis results for Zynq 7010:
  - 1259 LUT, 964 FF
  - 0.383 ns worst negative slack at 200 MHz

## Requirements for running the testbenches

- GHDL: https://github.com/tgingold/ghdl
- VUnit: https://github.com/vunit/vunit
- Pycryptodome: https://github.com/Legrandin/pycryptodome

To run the testsuite, simply execute `cd sim/vunit/ && ./run.py`.

## TODO

- Add usage and documentation, at least for the interface.
- Implement missing encryption and decryption modes.
- Synthesize with open source toolchain.
