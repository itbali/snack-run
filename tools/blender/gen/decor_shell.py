"""Ракушки на пляже (украшение, план 16): два плоских веера; один меш."""
import lib

SPEC = {"max_tris": 120, "max_dim": 0.3}


def build():
	parts = []
	for i, (x, y) in enumerate(((0, 0), (0.12, 0.07))):
		s = lib.cone(f"s{i}", radius=0.05, depth=0.02, segments=7, material="cream" if i == 0 else "coral", smooth=False)
		s.scale = (1.0, 0.7, 1.0)
		s.location = (x, y, 0.01)
		parts.append(s)
	return [lib.join("decor_shell", parts)]
