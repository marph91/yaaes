# YAAES

[![testsuite](https://github.com/marph91/yaaes/workflows/testsuite/badge.svg)](https://github.com/marph91/yaaes/actions?query=workflow%3Atestsuite)
[![codecov](https://codecov.io/gh/marph91/yaaes/branch/master/graph/badge.svg)](https://codecov.io/gh/marph91/yaaes)

VHDL implementation of the symmetric block cipher AES, as specified in the NIST FIPS 197, respectively NIST SP 800-38A.

Currently supported:

- Interface bitwidth of 8, 32 and 128.
- Key bitwidth of 128 and 256, i. e. AES-128 and AES-256.
- The following modes:

| Mode | Encryption | Decryption |
| :---: | :---: | :---: |
| ECB | :heavy_check_mark: | :x: |
| CBC | :heavy_check_mark: | :x: |
| CFB | :heavy_check_mark: | :heavy_check_mark: |
| OFB | :heavy_check_mark: | :heavy_check_mark: |
| CTR | :x: | :x: |

## Example results (deprecated)

128 bit encryption in ECB mode:

- simulation results:
  - latency: 26 cycles (f. e. 260 ns at 100 MHz clock)
- synthesis results for Zynq 7010:
  - 1259 LUT, 964 FF
  - 0.383 ns worst negative slack at 200 MHz

## Requirements for running the testbenches

- GHDL: <https://github.com/tgingold/ghdl>
- VUnit: <https://github.com/vunit/vunit>
- Pycryptodome: <https://github.com/Legrandin/pycryptodome>

To run the testsuite, simply execute `cd sim/vunit && ./run.py`.
