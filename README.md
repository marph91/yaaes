# YAAES

[![testsuite](https://github.com/marph91/yaaes/workflows/testsuite/badge.svg)](https://github.com/marph91/yaaes/actions?query=workflow%3Atestsuite)
[![codecov](https://codecov.io/gh/marph91/yaaes/branch/master/graph/badge.svg)](https://codecov.io/gh/marph91/yaaes)
[![vhdl_style](https://github.com/marph91/yaaes/workflows/vhdl_style/badge.svg)](https://github.com/marph91/yaaes/actions?query=workflow%3Avhdl_style)
[![synthesis](https://github.com/marph91/yaaes/actions/workflows/synthesis.yml/badge.svg)](https://github.com/marph91/yaaes/actions/workflows/synthesis.yml)

VHDL implementation of the symmetric block cipher AES, as specified in the [NIST FIPS 197](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.197.pdf), respectively [NIST SP 800-38A](https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-38a.pdf).

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

## Example results

The following results are obtained from a synthesis with Xilinx Vivado. For synthesis results with ghdl, yosys and nextpnr, you can check the github actions workflow.

- Device: Xilinx Zynq 7010
- Configuration: AES-256 encryption in ECB mode with an interface bitwidth of 32 bit
- Results:
  - latency: 36 cycles (after initial key transmission)
  - 1353 LUT, 1242 FF
  - 0.171 ns worst negative slack at 200 MHz

## Testsuite

The requirements for running the testsuite are [GHDL](https://github.com/tgingold/ghdl), [VUnit](https://github.com/vunit/vunit) and [Pycryptodome](https://github.com/Legrandin/pycryptodome). To run the testsuite itself, simply execute `cd sim/vunit && ./run.py`.
