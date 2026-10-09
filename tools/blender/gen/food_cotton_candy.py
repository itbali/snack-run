"""Сахарная вата: розово-сиреневое облачко на палочке."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	stick = lib.cylinder("food_cotton_candy", radius=0.008, depth=0.12, segments=6, material="cream")
	stick.location.z = 0.06
	parts = [stick]
	for i, (x, y, z, r, m) in enumerate(((0, 0, 0.17, 0.065, "coral"), (0.04, 0.02, 0.2, 0.045, "lilac"), (-0.035, -0.015, 0.19, 0.05, "lilac"))):
		s = lib.sphere(f"food_cotton_candy_c{i}", r, material=m, segments=8, rings=6)
		s.location = (x, y, z)
		parts.append(s)
	return lib.group(parts)
