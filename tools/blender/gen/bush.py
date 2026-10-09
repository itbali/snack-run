"""Куст (план 16): шесть комковатых шапок разного размера и оттенка — пышный, не три шара (foliage.bush)."""
import foliage
import lib

SPEC = {"max_tris": 1200, "max_dim": 1.3}


def build():
	return lib.group(foliage.bush("bush"))
