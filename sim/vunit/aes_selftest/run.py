#!/usr/bin/env python3

"""Do selftests for the AES VHDL design."""


import itertools

import common


def create_test_suite(lib):
    """Create a testsuite for the aes selftests."""
    tb_aes = lib.entity("tb_aes_selftest")

    # simulate two rounds of en- and decrypting for each chaining mode
    test_params = itertools.product(
        ("CFB", "OFB"), common.get_aes_test_configs())
    for mode, gen in test_params:
        bw = 128
        bw_key = len(gen["C_KEY"]) * 4  # 2 hex chars -> 8 bits

        gen.update({
            "C_BITWIDTH_IF": bw,
            "C_BITWIDTH_KEY": bw_key,
            "C_MODE": mode,
            "C_IV": common.random_hex(32),
        })
        tb_aes.add_config(
            name="aes_%d_mode_%s_bw_%d_input_%s" % (
                bw_key, mode, bw, gen["input"]),
            generics={k: v for k, v in gen.items() if k != "input"})
