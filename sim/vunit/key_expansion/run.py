#!/usr/bin/env python3

"""Generate test vectors and a test suite for the AES VHDL design."""


def create_test_suite(lib):
    """Create a testsuite for the key expansion module."""
    tb_key_expansion = lib.entity("tb_key_expansion")

    for key_bits in [128, 256]:
        tb_key_expansion.add_config(name=f"reference_vector_aes-{key_bits}",
                                    generics={"C_KEY_WORDS": int(key_bits/32)})
