#!/usr/bin/env python3

"""Generate test vectors and a test suite for the AES VHDL design."""

import os

from vunit import VUnit


def create_test_suite(ui):
    root = os.path.dirname(__file__)

    ui.add_array_util()
    lib = ui.add_library("lib", allow_duplicate=True)
    lib.add_source_files("/home/workspace/vhdl/aes/src/*.vhd")
    lib.add_source_files(os.path.join(root, "src", "*.vhd"))
    lib.add_source_files(os.path.join(root, "..", "vunit_common_pkg.vhd"))

    tb_input_conversion = lib.entity("tb_output_conversion")

    for bw in [8, 128]:
        gen = {"C_BITWIDTH": bw}
        tb_input_conversion.add_config(name="bitwidth=%d" % bw, generics=gen)


if __name__ == "__main__":
    os.environ["VUNIT_SIMULATOR"] = "ghdl"
    UI = VUnit.from_argv()
    create_test_suite(UI)
    UI.main()
