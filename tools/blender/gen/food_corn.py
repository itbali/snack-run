"""Кукуруза: золотой початок и два листа."""
import math

import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	cob = lib.cylinder("food_corn", radius=0.04, depth=0.2, segments=10, material="rarity_legendary")
	cob.rotation_euler = (0, math.pi / 2, 0)
	cob.location.z = 0.04
	parts = [cob]
	for i, s in enumerate((-1, 1)):
		leaf = lib.cone(f"food_corn_leaf{i}", radius=0.03, depth=0.16, segments=5, material="leaf")
		leaf.rotation_euler = (0, math.pi / 2 + 0.3 * s, 0.4 * s)
		leaf.location = (-0.11, 0.02 * s, 0.05)
		parts.append(leaf)
	return lib.group(parts)
