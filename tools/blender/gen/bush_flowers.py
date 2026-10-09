"""Цветущий куст (план 16): пышный куст и россыпь цветков палитры."""
import math

import foliage
import lib

SPEC = {"max_tris": 1500, "max_dim": 1.3}


def build():
	parts = foliage.bush("bush_flowers")
	for i in range(9):
		a = i * 2.4
		f = lib.sphere(f"bush_flowers_f{i}", 0.05, material=("coral", "lilac", "rarity_legendary")[i % 3], segments=6, rings=4)
		f.location = (math.cos(a) * 0.35, math.sin(a) * 0.3, 0.45 + 0.2 * math.sin(a * 1.7))
		parts.append(f)
	return lib.group(parts)
