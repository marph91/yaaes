#!/usr/bin/env python3

"""Run all unit tests contained by the subfolders."""

from glob import glob
import importlib.util
import os
import subprocess

from vunit import VUnit


def create_test_suites(prj):
    root = os.path.dirname(__file__)
    run_scripts = glob(os.path.join(root, "*", "run.py"))

    lib = prj.add_library("aes_lib")
    lib.add_source_files(os.path.join(root, "vunit_common_pkg.vhd"))
    lib.add_source_files("../../src/*.vhd")

    for run_script in run_scripts:
        spec = importlib.util.spec_from_file_location("run", run_script)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        mod.create_test_suite(prj)

    # add code coverage if gcc is available
    ghdl_version = subprocess.check_output(["ghdl", "--version"]).decode()
    if "GCC" in ghdl_version:
        prj.set_sim_option("enable_coverage", True)
        prj.set_compile_option(
            "ghdl.flags", ["-g", "-fprofile-arcs", "-ftest-coverage"])
        prj.set_sim_option("ghdl.elab_flags", ["-Wl,-lgcov", "-Wl,--coverage"])


if __name__ == "__main__":
    os.environ["VUNIT_SIMULATOR"] = "ghdl"
    PRJ = VUnit.from_argv()
    create_test_suites(PRJ)
    PRJ.main()
