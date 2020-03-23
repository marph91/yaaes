#!/usr/bin/env python3

"""Generate test vectors and a test suite for the AES VHDL design."""


def create_test_suite(lib):
    """Create a testsuite for the input conversion module."""
    tb_input_conversion = lib.entity("tb_input_conversion")

    for bw in [8, 32, 128]:
        gen = {"C_BITWIDTH": bw}
        tb_input_conversion.add_config(name="bw=%d" % bw, generics=gen)
