#!/usr/bin/env python3

"""Generate test vectors and a test suite for the AES VHDL design."""


from binascii import a2b_hex
import itertools

from Cryptodome.Cipher import AES

import common


def xor(str1, str2):
    """xor two hexadecimal strings."""
    assert len(str1) == len(str2), "bitwidth should be equal"
    return format(int(str1, 16) ^ int(str2, 16), "0%dx" % len(str1))


def encrypt(plaintext, key, curr_iv, mode):
    """Encrypt the given plaintext."""
    if mode == "ECB":
        cipher = AES.new(a2b_hex(key), AES.MODE_ECB)
        ciphertext = cipher.encrypt(a2b_hex(plaintext)).hex()
        next_iv = curr_iv
    elif mode == "CBC":
        cipher = AES.new(a2b_hex(key), AES.MODE_CBC, iv=a2b_hex(curr_iv))
        ciphertext = cipher.encrypt(a2b_hex(plaintext)).hex()
        next_iv = ciphertext
    elif mode == "CFB":
        cipher = AES.new(a2b_hex(key), AES.MODE_CFB, iv=a2b_hex(curr_iv),
                         segment_size=128)
        ciphertext = cipher.encrypt(a2b_hex(plaintext)).hex()
        next_iv = ciphertext
    elif mode == "OFB":
        cipher = AES.new(a2b_hex(key), AES.MODE_OFB, iv=a2b_hex(curr_iv))
        ciphertext = cipher.encrypt(a2b_hex(plaintext)).hex()
        # calculate next iv manually, since it's not available
        next_iv = xor(plaintext, ciphertext)

    return ciphertext, next_iv


def decrypt(ciphertext, key, curr_iv, mode):
    """Decrypt the given ciphertext."""
    if mode == "ECB":
        return None
    elif mode == "CBC":
        return None
    elif mode == "CFB":
        cipher = AES.new(a2b_hex(key), AES.MODE_CFB, iv=a2b_hex(curr_iv),
                         segment_size=128)
        plaintext = cipher.decrypt(a2b_hex(ciphertext)).hex()
        next_iv = ciphertext
    elif mode == "OFB":
        cipher = AES.new(a2b_hex(key), AES.MODE_OFB, iv=a2b_hex(curr_iv))
        plaintext = cipher.encrypt(a2b_hex(ciphertext)).hex()
        # calculate next iv manually, since it's not available
        next_iv = xor(plaintext, ciphertext)

    return plaintext, next_iv


def create_test_suite(lib):
    """Create a testsuite for the aes module."""
    tb_aes = lib.entity("tb_aes")

    # simulate two rounds of en- and decrypting for each chaining mode
    # TODO: implement counter mode. this would require some more input signals
    # TODO: allow more variability, e. g. varying segment_size for CFB
    test_params = itertools.product((0, 1), ("ECB", "CBC", "CFB", "OFB"),
                                    common.get_aes_test_configs())
    for encryption, mode, gen in test_params:
        if not encryption and mode in ["ECB", "CBC"]:
            continue  # not yet implemented

        # TODO: python byteorder is LSB...MSB, VHDL is MSB downto LSB
        encr_str = "encrypt" if encryption else "decrypt"
        encr_func = encrypt if encryption else decrypt
        bw_if = 32
        bw_key = len(gen["C_KEY"]) * 4  # 2 hex chars -> 8 bits
        init_vector = common.random_hex(32)

        ciphertext1, iv2 = encr_func(
            gen["C_PLAINTEXT1"], gen["C_KEY"], init_vector, mode)
        ciphertext2, _ = encr_func(
            gen["C_PLAINTEXT2"], gen["C_KEY"], iv2, mode)
        gen.update({
            "C_ENCRYPTION": encryption,
            "C_BITWIDTH_IF": bw_if,
            "C_BITWIDTH_KEY": bw_key,
            "C_MODE": mode,
            "C_CIPHERTEXT1": ciphertext1,
            "C_CIPHERTEXT2": ciphertext2,
            "C_IV": init_vector,
        })
        generics = {k: v for k, v in gen.items() if k != "input"}
        tb_aes.add_config(
            name="aes_%d_%s_mode_%s_bw_%d_input_%s" % (
                bw_key, encr_str, mode, bw_if, gen["input"]),
            generics=generics)

        if gen["input"] == "random":
            # Add test for 8 and 32 bit bitwidth.
            # Use stimuli and references from updated gen3.
            for bw_if in (8, 128):
                tb_aes.add_config(name="aes_%d_%s_mode=%s_bw=%d_input=random"
                                  % (bw_key, encr_str, mode, bw_if),
                                  generics=generics)
