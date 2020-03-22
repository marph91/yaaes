#!/usr/bin/env python3

"""Do selftests for the AES VHDL design."""


import itertools
import os

from vunit import VUnit

import common


def create_test_suite(ui):
    root = os.path.dirname(__file__)

    ui.add_array_util()
    lib = ui.add_library("test_lib", allow_duplicate=True)
    lib.add_source_files(os.path.join(root, "src", "*.vhd"))
    tb_aes = lib.entity("tb_aes_selftest")

    # test configs
    cfg1 = {
        "input": "same",
        "C_PLAINTEXT1": "3243f6a8885a308d313198a2e0370734",
        "C_PLAINTEXT2": "3243f6a8885a308d313198a2e0370734",
        "C_KEY": "2b7e151628aed2a6abf7158809cf4f3c",
    }
    cfg2 = {
        "input": "different",
        "C_PLAINTEXT1": "3243f6a8885a308d313198a2e0370734",
        "C_PLAINTEXT2": "000102030405060708090a0b0c0d0e0f",
        "C_KEY": "2b7e151628aed2a6abf7158809cf4f3c",
    }
    cfg3 = {
        "input": "random",
        "C_PLAINTEXT1": common.random_hex(32),
        "C_PLAINTEXT2": common.random_hex(32),
        "C_KEY": common.random_hex(32),
    }
    cfg4 = {
        "input": "same",
        "C_PLAINTEXT1": "00112233445566778899aabbccddeeff",
        "C_PLAINTEXT2": "00112233445566778899aabbccddeeff",
        "C_KEY": "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
    }

    # simulate two rounds of en- and decrypting for each chaining mode
    test_params = itertools.product(("CFB", "OFB"), (cfg1, cfg2, cfg3, cfg4))
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


if __name__ == "__main__":
    os.environ["VUNIT_SIMULATOR"] = "ghdl"
    UI = VUnit.from_argv()
    create_test_suite(UI)
    UI.main()
