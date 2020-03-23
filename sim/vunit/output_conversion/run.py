#!/usr/bin/env python3

"""Generate test vectors and a test suite for the AES VHDL design."""

import os

from vunit import VUnit


def create_test_suite(ui):
    root = os.path.dirname(__file__)

    ui.add_array_util()
    lib = ui.add_library("test_lib", allow_duplicate=True)
    lib.add_source_files(os.path.join(root, "src", "*.vhd"))
    tb_output_conversion = lib.entity("tb_output_conversion")

    for bw in [8, 32, 128]:
        gen = {"C_BITWIDTH": bw}
        tb_output_conversion.add_config(name="bw=%d" % bw, generics=gen)
