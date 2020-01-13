#!/usr/bin/env python3

"""Generate test vectors and a test suite for the AES VHDL design."""

import os

from vunit import VUnit


def create_test_suite(ui):
    root = os.path.dirname(__file__)

    ui.add_array_util()
    lib = ui.add_library("test_lib", allow_duplicate=True)
    lib.add_source_files(os.path.join(root, "src", "*.vhd"))

    tb_key_expansion = lib.entity("tb_key_expansion")
    tb_key_expansion.add_config(name="reference_vector")


if __name__ == "__main__":
    os.environ["VUNIT_SIMULATOR"] = "ghdl"
    UI = VUnit.from_argv()
    create_test_suite(UI)
    UI.main()
