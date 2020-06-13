#!/usr/bin/env python3

"""Generate test vectors and a test suite for the AES VHDL design."""

import itertools


def create_test_suite(lib):
    """Create a testsuite for the input conversion module."""
    tb_input_conversion = lib.entity("tb_input_conversion")

    for bw_if, bw_key, bw_iv in itertools.product((8, 32, 128),
                                                  (128, 256),
                                                  (0, 128)):
        gen = {
            "G_BITWIDTH_IF": bw_if,
            "G_BITWIDTH_KEY": bw_key,
            "G_BITWIDTH_IV": bw_iv,
        }
        tb_input_conversion.add_config(
            name=f"bw_if_{bw_if}_bw_key_{bw_key}_bw_iv_{bw_iv}", generics=gen)
