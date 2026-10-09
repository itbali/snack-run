"""Дерево 3,2 м (план 16): сужающийся ствол с двумя ветками и крона из шести комковатых шапок двух оттенков — не шар."""
import math

import lib

SPEC = {"max_tris": 1500, "max_dim": 3.4}
LUMPS = ((0.0, 0.0, 2.3, 0.75), (0.55, 0.2, 2.15, 0.5), (-0.5, 0.25, 2.2, 0.5), (0.1, -0.55, 2.2, 0.5),
	(0.25, 0.3, 2.85, 0.48), (-0.25, -0.2, 2.75, 0.45))


def build():
	trunk = lib.cone("tree", radius=0.18, depth=2.0, segments=8, material="brick", smooth=False)
	trunk.location.z = 1.0
	parts = [trunk]
	for i, (a, tilt) in enumerate(((0.6, 0.7), (3.8, 0.6))):
		br = lib.cylinder(f"tree_branch{i}", radius=0.05, depth=0.8, segments=6, material="brick", smooth=False)
		br.rotation_euler = (tilt, 0, a)
		br.location = (math.cos(a) * 0.2, math.sin(a) * 0.2, 1.7)
		parts.append(br)
	for i, (x, y, z, r) in enumerate(LUMPS):
		c = lib.lumpy(f"tree_crown{i}", r, material="leaf" if i % 3 else "olive", seed=11 + i, segments=9, rings=6)
		c.location = (x, y, z)
		parts.append(c)
	return lib.group(parts)
