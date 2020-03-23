#!/usr/bin/env python3

"""Run all unit tests contained by the subfolders."""

from glob import glob
import importlib.util
import os
import subprocess

from vunit import VUnit


def collect_test_suites(prj):
    """Collect the testsuites of all modules and set parameters."""
    root = os.path.dirname(__file__)
    run_scripts = glob(os.path.join(root, "*", "run.py"))
    testbenches = glob(os.path.join(root, "*", "src", "*.vhd"))

    aes_lib = prj.add_library("aes_lib")
    aes_lib.add_source_files("../../src/*.vhd")

    test_lib = prj.add_library("test_lib")
    test_lib.add_source_files(os.path.join(root, "vunit_common_pkg.vhd"))
    test_lib.add_source_files(testbenches)

    for run_script in run_scripts:
        spec = importlib.util.spec_from_file_location("run", run_script)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        mod.create_test_suite(test_lib)

    # avoid error "type of a shared variable must be a protected type"
    ghdl_flags = ["-frelaxed"]
    ghdl_elab_flags = ["-frelaxed"]

    # add code coverage if gcc is available
    ghdl_version = subprocess.check_output(["ghdl", "--version"]).decode()
    if "GCC" in ghdl_version:
        prj.set_sim_option("enable_coverage", True)
        ghdl_flags.extend(["-g", "-fprofile-arcs", "-ftest-coverage"])
        ghdl_elab_flags.extend(["-Wl,-lgcov", "-Wl,--coverage"])

    prj.set_compile_option("ghdl.flags", ghdl_flags)
    prj.set_sim_option("ghdl.elab_flags", ghdl_elab_flags)


def main():
    """Run all collected testsuites of the modules."""
    os.environ["VUNIT_SIMULATOR"] = "ghdl"
    prj = VUnit.from_argv()
    collect_test_suites(prj)
    prj.main()


if __name__ == "__main__":
    main()
