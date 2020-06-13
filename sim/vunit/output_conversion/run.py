#!/usr/bin/env python3

"""Generate test vectors and a test suite for the AES VHDL design."""


def create_test_suite(lib):
    """Create a testsuite for the output conversion module."""
    tb_output_conversion = lib.entity("tb_output_conversion")

    for bw_if in [8, 32, 128]:
        gen = {"G_BITWIDTH": bw_if}
        tb_output_conversion.add_config(name="bw=%d" % bw_if, generics=gen)
