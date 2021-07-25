# YAAES

[![testsuite](https://github.com/marph91/yaaes/workflows/testsuite/badge.svg)](https://github.com/marph91/yaaes/actions?query=workflow%3Atestsuite)
[![codecov](https://codecov.io/gh/marph91/yaaes/branch/master/graph/badge.svg)](https://codecov.io/gh/marph91/yaaes)
[![vhdl_style](https://github.com/marph91/yaaes/workflows/vhdl_style/badge.svg)](https://github.com/marph91/yaaes/actions?query=workflow%3Avhdl_style)
[![synthesis](https://github.com/marph91/yaaes/actions/workflows/synthesis.yml/badge.svg)](https://github.com/marph91/yaaes/actions/workflows/synthesis.yml)

VHDL implementation of the symmetric block cipher AES, as specified in the [NIST FIPS 197](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.197.pdf), respectively [NIST SP 800-38A](https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-38a.pdf).

Features:

- Interface width of 8, 32 and 128 bit.
- Key width of 128 and 256 bit, i. e. AES-128 and AES-256.
- The following modes:

| Mode | Encryption | Decryption |
| :---: | :---: | :---: |
| ECB | :heavy_check_mark: | :x: |
| CBC | :heavy_check_mark: | :x: |
| CFB | :heavy_check_mark: | :heavy_check_mark: |
| OFB | :heavy_check_mark: | :heavy_check_mark: |
| CTR | :x: | :x: |

Development status:

- [x] VHDL design
- [x] Functional simulation
- [x] Implementation
- [ ] Test on FPGA (it was reported that the design was successfully ran on an Altera Max 10 Board at 50 MHz)

## Usage

The core expects key, iv (optional) and plaintext/ciphertext (depending if encrypting or decrypting) through `islv_data`. A new set of key and iv should be signalised by assigning `isl_new_key_iv` for one cycle. Valid inputs should be marked by assigning the `isl_valid` signal. Accordingly, the output `oslv_data` is valid when the signal `osl_valid` is assigned. New input data can be transmitted only when the output is fully done.

Example for AES-256 encryption in CFB mode with an interface bitwidth of 32 bit:

![AES toplevel waveform](https://svg.wavedrom.com/github/marph91/yaaes/trunk/doc/aes_toplevel_waveform.json)

## Resource usage

The following results are obtained from a local synthesis for Lattice ECP5, using the open source toolchain (ghdl, yosys and nextpnr). For more details, see the synthesis workflow.

- Device: ULX3S
- Configuration: as in the example above
- Results:
  - Resources:
    - TRELLIS_SLICE:  3109/41820     7%
    - DCCA:              1/   56     1%
  - Target frequency: 100 MHz
  - Maximum frequency: 121 MHz

## Performance

From the testsuite runs, the following metrics can be derived (configuration as above):

- Latency: 37 cycles (after initial key and iv transmission)
- Throughput: One input of 128 bit each 42 cycles &rarr; 3 bit per clock cycle &rarr; 300 Mbps at 100 MHz
