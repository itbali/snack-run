"""Камыш у пруда (украшение, план 16): высокие стебли с бурыми початками; один меш."""
import math

import lib

SPEC = {"max_tris": 300, "max_dim": 1.1}


def build():
	parts = []
	for i in range(6):
		a = i * 1.05
		x, y = math.cos(a) * 0.1, math.sin(a) * 0.1
		h = 0.7 + 0.12 * (i % 3)
		s = lib.cone(f"st{i}", radius=0.015, depth=h, segments=4, material="olive" if i % 2 else "leaf", smooth=False)
		s.location = (x, y, h / 2)
		parts.append(s)
		if i % 2 == 0:
			c = lib.cylinder(f"c{i}", radius=0.025, depth=0.12, segments=6, material="brick", smooth=False)
			c.location = (x, y, h * 0.85)
			parts.append(c)
	return [lib.join("decor_reeds", parts)]
