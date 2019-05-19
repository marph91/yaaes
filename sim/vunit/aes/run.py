#!/usr/bin/env python3

"""Generate test vectors and a test suite for the AES VHDL design."""

from Crypto.Cipher import AES
from binascii import a2b_hex, b2a_hex
import random

import os

from vunit import VUnit


def random_hex(bw):
    """Generate a random hex string."""
    return "{0:0{1}x}".format(random.randrange(16**bw), bw)


def xor(str1, str2):
    """xor two hexadecimal strings."""
    assert len(str1) == len(str2), "bitwidth should be equal"
    return format(int(str1, 16) ^ int(str2, 16), "0%dx" % len(str1))


def encrypt(plaintext, key, iv, mode):
    """Encrypt the given plaintext."""
    if mode == "ECB":
        cipher = AES.new(a2b_hex(key), AES.MODE_ECB)
        ciphertext = cipher.encrypt(a2b_hex(plaintext)).hex()
        next_iv = iv
    elif mode == "CBC":
        cipher = AES.new(a2b_hex(key), AES.MODE_CBC, iv=a2b_hex(iv))
        ciphertext = cipher.encrypt(a2b_hex(plaintext)).hex()
        next_iv = ciphertext
    elif mode == "CFB":
        cipher = AES.new(a2b_hex(key), AES.MODE_CFB, iv=a2b_hex(iv),
                         segment_size=128)
        ciphertext = cipher.encrypt(a2b_hex(plaintext)).hex()
        next_iv = ciphertext
    elif mode == "OFB":
        cipher = AES.new(a2b_hex(key), AES.MODE_OFB, iv=a2b_hex(iv))
        ciphertext = cipher.encrypt(a2b_hex(plaintext)).hex()
        # calculate next iv manually, since it's not available
        next_iv = xor(plaintext, ciphertext)

    return ciphertext, next_iv


def create_test_suite(ui):
    root = os.path.dirname(__file__)

    ui.add_array_util()
    lib = ui.add_library("lib", allow_duplicate=True)
    lib.add_source_files("/home/workspace/vhdl/aes/src/*.vhd")
    lib.add_source_files(os.path.join(root, "src", "*.vhd"))
    lib.add_source_files(os.path.join(root, "..", "vunit_common_pkg.vhd"))

    tb_aes = lib.entity("tb_aes")

    # simulate two rounds of encrypting for each chaining mode
    # TODO: implement counter mode. this would require some more input signals
    for mode in ["ECB", "CBC", "CFB", "OFB"]:
        # TODO: allow more variability, e. g. varying segment_size for CFB
        gen1 = {"input": "same",
                "C_PLAINTEXT1": "3243f6a8885a308d313198a2e0370734",
                "C_KEY1": "2b7e151628aed2a6abf7158809cf4f3c",
                "C_IV1": random_hex(32),
                "C_PLAINTEXT2": "3243f6a8885a308d313198a2e0370734",
                "C_KEY2": "2b7e151628aed2a6abf7158809cf4f3c"}
        gen2 = {"input": "different",
                "C_PLAINTEXT1": "3243f6a8885a308d313198a2e0370734",
                "C_KEY1": "2b7e151628aed2a6abf7158809cf4f3c",
                "C_IV1": random_hex(32),
                "C_PLAINTEXT2": "000102030405060708090a0b0c0d0e0f",
                "C_KEY2": "69c4e0d86a7b0430d8cdb78070b4c55a"}
        gen3 = {"input": "random",
                "C_PLAINTEXT1": random_hex(32),
                "C_KEY1": random_hex(32),
                "C_IV1": random_hex(32),
                "C_PLAINTEXT2": random_hex(32),
                "C_KEY2": random_hex(32)}
        
        for gen in [gen1, gen2, gen3]:
            # TODO: python byteorder is LSB...MSB, VHDL is MSB downto LSB
            ciphertext1, iv2 = encrypt(gen["C_PLAINTEXT1"], gen["C_KEY1"], gen["C_IV1"], mode)
            ciphertext2, _ = encrypt(gen["C_PLAINTEXT2"], gen["C_KEY2"], iv2, mode)
            gen.update({"C_BITWIDTH": 128,
                        "C_MODE": mode,
                        "C_CIPHERTEXT1": ciphertext1,
                        "C_IV2": iv2,
                        "C_CIPHERTEXT2": ciphertext2})
            tb_aes.add_config(name="mode=%s,input=%s" % (mode, gen.pop("input")), generics=gen)
    
        # add one test for 8 bit bitwidth
        bw = 8
        ciphertext1, iv2 = encrypt(gen["C_PLAINTEXT1"], gen["C_KEY1"], gen["C_IV1"], mode)
        ciphertext2, _ = encrypt(gen["C_PLAINTEXT2"], gen["C_KEY2"], iv2, mode)
        gen.update({"C_BITWIDTH": bw,
                    "C_MODE": mode,
                    "C_CIPHERTEXT1": ciphertext1,
                    "C_IV2": iv2,
                    "C_CIPHERTEXT2": ciphertext2})
        tb_aes.add_config(name="mode=%s,bitwidth=%d" % (mode, bw), generics=gen)


if __name__ == "__main__":
    os.environ["VUNIT_SIMULATOR"] = "ghdl"
    UI = VUnit.from_argv()
    create_test_suite(UI)
    UI.main()
