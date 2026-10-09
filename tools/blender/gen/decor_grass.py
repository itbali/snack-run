"""Густой пучок травы (украшение, план 16): восемь наклонённых травинок двух оттенков; один меш."""
import math

import lib

SPEC = {"max_tris": 200, "max_dim": 0.35}


def build():
	parts = []
	for i in range(8):
		a = i * 2 * math.pi / 8
		c = lib.cone(f"g{i}", radius=0.018, depth=0.18 + 0.06 * (i % 3), segments=4, material="leaf" if i % 2 else "olive", smooth=False)
		c.location = (math.cos(a) * 0.05, math.sin(a) * 0.05, 0.1)
		c.rotation_euler = (math.sin(a) * 0.4, -math.cos(a) * 0.4, 0.0)
		parts.append(c)
	return [lib.join("decor_grass", parts)]
