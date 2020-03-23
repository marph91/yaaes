"""Gather all common functionality of the AES scripts."""

import random


def random_hex(bitwidth: int) -> str:
    """Generate a random hex string."""
    return "{0:0{1}x}".format(random.randrange(16 ** bitwidth), bitwidth)
