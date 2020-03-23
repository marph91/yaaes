#!/usr/bin/env python3

"""Generate test vectors and a test suite for the AES VHDL design."""


def create_test_suite(lib):
    """Create a testsuite for the key expansion module."""
    tb_key_expansion = lib.entity("tb_key_expansion")
    tb_key_expansion.add_config(name="reference_vector")
