#!/usr/bin/env python3

"""Do selftests for the AES VHDL design."""


import random
import os

from vunit import VUnit


def random_hex(bw):
    """Generate a random hex string."""
    return "{0:0{1}x}".format(random.randrange(16**bw), bw)


def create_test_suite(ui):
    root = os.path.dirname(__file__)

    ui.add_array_util()
    lib = ui.add_library("lib", allow_duplicate=True)
    lib.add_source_files("/home/workspace/vhdl/aes/src/*.vhd")
    lib.add_source_files(os.path.join(root, "src", "*.vhd"))
    lib.add_source_files(os.path.join(root, "..", "vunit_common_pkg.vhd"))

    tb_aes = lib.entity("tb_aes_selftest")

    # simulate two rounds of en- and decrypting for each chaining mode
    for mode in ["CFB", "OFB"]:
        # TODO: allow more variability, e. g. varying segment_size for CFB
        gen1 = {"input": "same",
                "C_PLAINTEXT1": "3243f6a8885a308d313198a2e0370734",
                "C_KEY1": "2b7e151628aed2a6abf7158809cf4f3c",
                "C_IV": random_hex(32),
                "C_PLAINTEXT2": "3243f6a8885a308d313198a2e0370734",
                "C_KEY2": "2b7e151628aed2a6abf7158809cf4f3c"}
        gen2 = {"input": "different",
                "C_PLAINTEXT1": "3243f6a8885a308d313198a2e0370734",
                "C_KEY1": "2b7e151628aed2a6abf7158809cf4f3c",
                "C_IV": random_hex(32),
                "C_PLAINTEXT2": "000102030405060708090a0b0c0d0e0f",
                "C_KEY2": "69c4e0d86a7b0430d8cdb78070b4c55a"}
        gen3 = {"input": "random",
                "C_PLAINTEXT1": random_hex(32),
                "C_KEY1": random_hex(32),
                "C_IV": random_hex(32),
                "C_PLAINTEXT2": random_hex(32),
                "C_KEY2": random_hex(32)}

        bw = 128
        for gen in [gen1, gen2, gen3]:
            gen.update({"C_BITWIDTH": bw,
                        "C_MODE": mode})
            tb_aes.add_config(
                name="mode=%s,bw=%d,input=%s" % (mode, bw, gen.pop("input")),
                generics=gen)

        # Add test for 8 bit bitwidth. Use stimuli and references from gen3.
        bw = 8
        gen3.update({"C_BITWIDTH": bw})
        tb_aes.add_config(name="mode=%s,bw=%d" % (mode, bw), generics=gen3)


if __name__ == "__main__":
    os.environ["VUNIT_SIMULATOR"] = "ghdl"
    UI = VUnit.from_argv()
    create_test_suite(UI)
    UI.main()
