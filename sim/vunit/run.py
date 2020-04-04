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

    # add code coverage if supported
    if prj.simulator_supports_coverage():
        prj.set_sim_option("enable_coverage", True)
        prj.set_compile_option("enable_coverage", True)


def post_run(results):
    results.merge_coverage(file_name="coverage_data")
    subprocess.call(["gcovr", "coverage_data"])


def main():
    """Run all collected testsuites of the modules."""
    os.environ["VUNIT_SIMULATOR"] = "ghdl"
    prj = VUnit.from_argv()
    collect_test_suites(prj)
    prj.main(post_run=post_run)


if __name__ == "__main__":
    main()
