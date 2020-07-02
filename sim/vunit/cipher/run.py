#!/usr/bin/env python3

"""Generate test vectors and a test suite for the AES VHDL design."""


def create_test_suite(lib):
    """Create a testsuite for the cipher helper functions."""
    lib.entity("tb_cipher")
