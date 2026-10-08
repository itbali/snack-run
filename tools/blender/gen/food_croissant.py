"""Круассан: три сегмента дугой."""
import math

import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	parts = []
	for i, (ang, size) in enumerate(((-0.6, 0.05), (0.0, 0.07), (0.6, 0.05))):
		seg = lib.rounded_box("food_croissant" if i == 1 else f"food_croissant_{i}",
		                      (0.07, size, size), bevel=0.02, segments=2, material="cat_orange")
		seg.location = (math.sin(ang) * 0.07, math.cos(ang) * 0.02 - 0.02, size / 2)
		seg.rotation_euler = (0, 0, -ang)
		parts.append(seg)
	return lib.group([parts[1], parts[0], parts[2]])
