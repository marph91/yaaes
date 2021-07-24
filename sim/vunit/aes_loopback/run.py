#!/usr/bin/env python3

"""Do a loopback test for the AES VHDL design. I. e. encrypt and decrypt afterwards."""


import itertools

import common


def create_test_suite(lib):
    """Create a testsuite for the aes loopback test."""
    tb_aes = lib.entity("tb_aes_loopback")

    # simulate two rounds of en- and decrypting for each chaining mode
    test_params = itertools.product(
        ("CFB", "OFB"), common.get_aes_test_configs())
    for mode, gen in test_params:
        bw_if = 32
        bw_key = len(gen["G_KEY"]) * 4  # 2 hex chars -> 8 bits

        gen.update({
            "G_BITWIDTH_IF": bw_if,
            "G_BITWIDTH_KEY": bw_key,
            "G_MODE": mode,
            "G_IV": common.random_hex(32),
        })
        tb_aes.add_config(
            name="aes_%d_mode_%s_bw_%d_input_%s" % (
                bw_key, mode, bw_if, gen["input"]),
            generics={k: v for k, v in gen.items() if k != "input"})
