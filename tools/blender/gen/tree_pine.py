"""Ель 3,4 м (план 16): ствол и четыре яруса чуть повёрнутых конусов двух оттенков."""
import lib

SPEC = {"max_tris": 800, "max_dim": 3.5}


def build():
	trunk = lib.cylinder("tree_pine", radius=0.12, depth=1.0, segments=8, material="brick", smooth=False)
	trunk.location.z = 0.5
	parts = [trunk]
	for i, (z, r, h) in enumerate(((1.1, 1.0, 1.1), (1.7, 0.8, 1.0), (2.3, 0.6, 0.9), (2.85, 0.38, 0.8))):
		c = lib.cone(f"tree_pine_t{i}", radius=r, depth=h, segments=9, material="leaf" if i % 2 == 0 else "olive", smooth=False)
		c.location.z = z
		c.rotation_euler.z = i * 0.35
		parts.append(c)
	return lib.group(parts)
