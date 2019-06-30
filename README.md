Currently supported:
- 8, 32 or 128 bit inputs and outputs.
- In the algorithm always 128 bits are used.
- AES-Encryption in the modes ECB, CBC, CFB and OFB.

# Requirements for running the testbenches

- GHDL: https://github.com/tgingold/ghdl
- VUnit: https://github.com/vunit/vunit
- Pycryptodome: https://github.com/Legrandin/pycryptodome

To run the testbenches, simply execute `sim/vunit/run_all.py`.

# TODO

[ ] Add usage and documentation at least for the interface.
[ ] Add utilization and timing on some FPGA.
[ ] Implement missing encryption modes.
[ ] Implement decryption.