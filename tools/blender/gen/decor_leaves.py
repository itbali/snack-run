"""Опавшие листья (украшение, план 16): плоские ромбики оливковых и рыжих оттенков; один меш."""
import math

import lib

SPEC = {"max_tris": 200, "max_dim": 0.5}


def build():
	parts = []
	for i in range(6):
		a = i * 1.1
		l = lib.rounded_box(f"l{i}", (0.07, 0.11, 0.01), bevel=0.0, segments=1, material=("olive", "cat_orange", "brick")[i % 3])
		l.location = (math.cos(a) * 0.15, math.sin(a) * 0.12, 0.006)
		l.rotation_euler.z = a * 2.0
		parts.append(l)
	return [lib.join("decor_leaves", parts)]
