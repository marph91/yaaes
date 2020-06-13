"""Gather all common functionality of the AES scripts."""

import random


def random_hex(bitwidth: int) -> str:
    """Generate a random hex string."""
    return "{0:0{1}x}".format(random.randrange(16 ** bitwidth), bitwidth)


def get_aes_test_configs():
    """Collection of aes test configurations."""
    cfg1 = {  # test vector from: FIPS-197, Appendix B
        "input": "same",
        "G_PLAINTEXT1": "3243f6a8885a308d313198a2e0370734",
        "G_PLAINTEXT2": "3243f6a8885a308d313198a2e0370734",
        "G_KEY": "2b7e151628aed2a6abf7158809cf4f3c",
    }
    cfg2 = {
        "input": "different",
        "G_PLAINTEXT1": "3243f6a8885a308d313198a2e0370734",
        "G_PLAINTEXT2": "000102030405060708090a0b0c0d0e0f",
        "G_KEY": "2b7e151628aed2a6abf7158809cf4f3c",
    }
    cfg3 = {
        "input": "random",
        "G_PLAINTEXT1": random_hex(32),
        "G_PLAINTEXT2": random_hex(32),
        "G_KEY": random_hex(32),
    }
    cfg4 = {  # test vector from: FIPS-197, Appendix C.3
        "input": "same",
        "G_PLAINTEXT1": "00112233445566778899aabbccddeeff",
        "G_PLAINTEXT2": "00112233445566778899aabbccddeeff",
        "G_KEY": "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
    }
    return cfg1, cfg2, cfg3, cfg4
