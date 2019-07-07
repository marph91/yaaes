import random


def random_hex(bw):
    """Generate a random hex string."""
    return "{0:0{1}x}".format(random.randrange(16**bw), bw)
