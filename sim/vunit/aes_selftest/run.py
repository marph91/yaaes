#!/usr/bin/env python3

"""Do selftests for the AES VHDL design."""


import os

from vunit import VUnit

import common


def create_test_suite(ui):
    root = os.path.dirname(__file__)

    ui.add_array_util()
    lib = ui.add_library("test_lib", allow_duplicate=True)
    lib.add_source_files(os.path.join(root, "src", "*.vhd"))
    tb_aes = lib.entity("tb_aes_selftest")

    # simulate two rounds of en- and decrypting for each chaining mode
    for mode in ["CFB", "OFB"]:
        # TODO: allow more variability, e. g. varying segment_size for CFB
        gen1 = {
            "input": "same",
            "C_PLAINTEXT1": "3243f6a8885a308d313198a2e0370734",
            "C_PLAINTEXT2": "3243f6a8885a308d313198a2e0370734",
            "C_KEY": "2b7e151628aed2a6abf7158809cf4f3c",
            "C_IV": common.random_hex(32),
            }
        gen2 = {
            "input": "different",
            "C_PLAINTEXT1": "3243f6a8885a308d313198a2e0370734",
            "C_PLAINTEXT2": "000102030405060708090a0b0c0d0e0f",
            "C_KEY": "2b7e151628aed2a6abf7158809cf4f3c",
            "C_IV": common.random_hex(32),
            }
        gen3 = {
            "input": "random",
            "C_PLAINTEXT1": common.random_hex(32),
            "C_PLAINTEXT2": common.random_hex(32),
            "C_KEY": common.random_hex(32),
            "C_IV": common.random_hex(32),
            }

        bw = 128
        for gen in [gen1, gen2, gen3]:
            gen.update({"C_BITWIDTH": bw,
                        "C_MODE": mode})
            tb_aes.add_config(
                name="mode=%s,bw=%d,input=%s" % (mode, bw, gen.pop("input")),
                generics=gen)

        # Add test for 8 and 32 bit bitwidth.
        # Use stimuli and references from gen3.
        for bw in [8, 32]:
            gen3.update({"C_BITWIDTH": bw})
            tb_aes.add_config(name="mode=%s,bw=%d,input=random"
                              % (mode, bw), generics=gen3)


if __name__ == "__main__":
    os.environ["VUNIT_SIMULATOR"] = "ghdl"
    UI = VUnit.from_argv()
    create_test_suite(UI)
    UI.main()
