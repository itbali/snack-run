"""Попкорн: полосатый стакан и горка зёрен."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	cup = lib.cylinder("food_popcorn", radius=0.07, depth=0.14, segments=8, material="brick")
	cup.location.z = 0.07
	parts = [cup]
	for i, (x, y, z) in enumerate(((0, 0, 0.16), (0.04, 0.02, 0.15), (-0.04, 0.01, 0.15), (0.01, -0.04, 0.15), (0, 0.04, 0.19))):
		k = lib.sphere(f"food_popcorn_k{i}", 0.035, material="cream", segments=6, rings=4)
		k.location = (x, y, z)
		parts.append(k)
	return lib.group(parts)
