"""Цветы (украшение, план 16): пять стеблей с головками палитры; один меш для MultiMesh."""
import math

import lib

SPEC = {"max_tris": 300, "max_dim": 0.35}


def build():
	parts = []
	for i in range(5):
		a = i * 1.3
		x, y = math.cos(a) * 0.08, math.sin(a) * 0.08
		h = 0.18 + 0.05 * (i % 3)
		s = lib.cylinder(f"st{i}", radius=0.008, depth=h, segments=4, material="leaf", smooth=False)
		s.location = (x, y, h / 2)
		f = lib.sphere(f"fl{i}", 0.035, material=("coral", "lilac", "rarity_legendary", "cream", "coral")[i], segments=6, rings=4, smooth=False)
		f.location = (x, y, h)
		parts += [s, f]
	return [lib.join("decor_flowers", parts)]
