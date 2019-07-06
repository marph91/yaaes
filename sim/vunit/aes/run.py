#!/usr/bin/env python3

"""Generate test vectors and a test suite for the AES VHDL design."""


from binascii import a2b_hex
import random
import os

from Crypto.Cipher import AES
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


def decrypt(ciphertext, key, iv, mode):
    """Decrypt the given ciphertext."""
    if mode == "ECB":
        return
    elif mode == "CBC":
        return
    elif mode == "CFB":
        cipher = AES.new(a2b_hex(key), AES.MODE_CFB, iv=a2b_hex(iv),
                         segment_size=128)
        plaintext = cipher.decrypt(a2b_hex(ciphertext)).hex()
        next_iv = ciphertext
    elif mode == "OFB":
        cipher = AES.new(a2b_hex(key), AES.MODE_OFB, iv=a2b_hex(iv))
        plaintext = cipher.encrypt(a2b_hex(ciphertext)).hex()
        # calculate next iv manually, since it's not available
        next_iv = xor(plaintext, ciphertext)

    return plaintext, next_iv


def create_test_suite(ui):
    root = os.path.dirname(__file__)

    ui.add_array_util()
    lib = ui.add_library("lib", allow_duplicate=True)
    lib.add_source_files("/home/workspace/vhdl/aes/src/*.vhd")
    lib.add_source_files(os.path.join(root, "src", "*.vhd"))
    lib.add_source_files(os.path.join(root, "..", "vunit_common_pkg.vhd"))

    tb_aes = lib.entity("tb_aes")

    # simulate two rounds of en- and decrypting for each chaining mode
    # TODO: implement counter mode. this would require some more input signals
    for encryption in [0, 1]:
        encr_str = "encrypt" if encryption else "decrypt"
        encr_func = encrypt if encryption else decrypt
        for mode in ["ECB", "CBC", "CFB", "OFB"]:
            if not encryption and mode in ["ECB", "CBC"]:
                continue  # not yet implemented
            # TODO: allow more variability, e. g. varying segment_size for CFB
            gen1 = {
                "input": "same",
                "C_PLAINTEXT1": "3243f6a8885a308d313198a2e0370734",
                "C_PLAINTEXT2": "3243f6a8885a308d313198a2e0370734",
                "C_KEY": "2b7e151628aed2a6abf7158809cf4f3c",
                "C_IV": random_hex(32),
                "C_ENCRYPTION": encryption,
                }
            gen2 = {
                "input": "different",
                "C_PLAINTEXT1": "3243f6a8885a308d313198a2e0370734",
                "C_PLAINTEXT2": "000102030405060708090a0b0c0d0e0f",
                "C_KEY": "2b7e151628aed2a6abf7158809cf4f3c",
                "C_IV": random_hex(32),
                "C_ENCRYPTION": encryption,
                }
            gen3 = {
                "input": "random",
                "C_PLAINTEXT1": random_hex(32),
                "C_PLAINTEXT2": random_hex(32),
                "C_KEY": random_hex(32),
                "C_IV": random_hex(32),
                "C_ENCRYPTION": encryption,
                }

            bw = 128
            for gen in [gen1, gen2, gen3]:
                # TODO: python byteorder is LSB...MSB, VHDL is MSB downto LSB
                ciphertext1, iv2 = encr_func(
                    gen["C_PLAINTEXT1"], gen["C_KEY"], gen["C_IV"], mode)
                ciphertext2, _ = encr_func(
                    gen["C_PLAINTEXT2"], gen["C_KEY"], iv2, mode)
                gen.update({
                    "C_BITWIDTH": bw,
                    "C_MODE": mode,
                    "C_CIPHERTEXT1": ciphertext1,
                    "C_CIPHERTEXT2": ciphertext2,
                    })
                tb_aes.add_config(
                    name="%s,mode=%s,bw=%d,input=%s" % (encr_str, mode, bw,
                                                        gen.pop("input")),
                    generics=gen)

            # Add test for 8 bit bitwidth. Use stimuli and references from gen3.
            bw = 8
            gen3.update({"C_BITWIDTH": bw})
            tb_aes.add_config(name="%s,mode=%s,bw=%d" % (encr_str, mode, bw),
                              generics=gen3)


if __name__ == "__main__":
    os.environ["VUNIT_SIMULATOR"] = "ghdl"
    UI = VUnit.from_argv()
    create_test_suite(UI)
    UI.main()
