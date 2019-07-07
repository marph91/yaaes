VHDL implementation of the symmetric block cipher AES, as specified in the NIST FIPS 197, respectively NIST SP 800-38A.

Currently supported:

| Mode | Encryption | Decryption | Bitwidth (In & Out) |
| :---: | :---: | :---: | :---: |
| ECB | &#x2611; | &#x274E; | 8, 32 and 128 |
| CBC | &#x2611; | &#x274E; | 8, 32 and 128 |
| CFB | &#x2611; | &#x2611; | 8, 32 and 128 |
| OFB | &#x2611; | &#x2611; | 8, 32 and 128 |
| CTR | &#x274E; | &#x274E; | - |

# Example results

128 bit encryption in ECB mode:

- simulation results:
  - latency: 94 cycles (f. e. 940 ns at 100 MHz clock)
- synthesis results for Zynq 7010:
  - 1252 LUT, 1291 FF
  - 0.392 ns worst negative slack at 250 MHz (not fully sure if the constraints are correct)

# Requirements for running the testbenches

- GHDL: https://github.com/tgingold/ghdl
- VUnit: https://github.com/vunit/vunit
- Pycryptodome: https://github.com/Legrandin/pycryptodome

To run the testbenches, simply execute `sim/vunit/run.py`.

# TODO

- Add usage and documentation at least for the interface.
- Add utilization and timing on some FPGA.
- Implement missing encryption modes.
- Implement missing decryption modes.