"""Беседка на вершине холма парка (план 12): восьмигранный пол 0,3 м, 6 столбов, конусная крыша."""
import math

import lib

SPEC = {"max_tris": 1500, "max_dim": 5.3}


def build():
	floor = lib.cylinder("gazebo", radius=2.0, depth=0.3, segments=8, material="sand", smooth=False)
	floor.location.z = 0.15
	parts = [floor]
	for k in range(6):
		a = k * math.pi / 3
		post = lib.cylinder(f"gazebo_post{k}", radius=0.08, depth=2.2, segments=8, material="cream")
		post.location = (1.85 * math.cos(a), 1.85 * math.sin(a), 0.3 + 1.1)
		parts.append(post)
	roof = lib.cone("gazebo_roof", radius=2.6, depth=1.1, segments=8, material="brick", smooth=False)
	roof.location.z = 2.5 + 0.55
	parts.append(roof)
	return lib.group(parts)
