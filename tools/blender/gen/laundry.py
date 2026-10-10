"""Верёвка с бельём (план 20): два столба, провисающая верёвка, пять вещей разных цветов (laundry_cloth* — колышутся)."""
import math

import lib

SPEC = {"max_tris": 1500, "max_dim": 4.2}


def build():
	parts = []
	for i, x in enumerate((-1.9, 1.9)):
		post = lib.cylinder(f"laundry_post{i}" if i else "laundry", radius=0.05, depth=2.1, segments=8, material="ink")
		post.location = (x, 0, 1.05)
		parts.append(post)
	for k in range(8):
		x0 = -1.9 + k * 3.8 / 8
		x1 = x0 + 3.8 / 8
		z0 = 2.0 - 0.18 * (1 - (x0 / 1.9) ** 2)
		z1 = 2.0 - 0.18 * (1 - (x1 / 1.9) ** 2)
		seg = lib.rounded_box(f"laundry_rope{k}", (math.hypot(x1 - x0, z1 - z0), 0.015, 0.015), bevel=0.0, segments=1, material="cream")
		seg.location = ((x0 + x1) / 2, 0, (z0 + z1) / 2)
		seg.rotation_euler.y = -math.atan2(z1 - z0, x1 - x0)
		parts.append(seg)
	for i, (x, w, h, mat) in enumerate(((-1.3, 0.5, 0.6, "sky"), (-0.6, 0.4, 0.45, "coral"), (0.0, 0.6, 0.5, "cream"), (0.7, 0.35, 0.55, "rarity_legendary"), (1.3, 0.45, 0.4, "leaf"))):
		top = 2.0 - 0.18 * (1 - (x / 1.9) ** 2)
		c = lib.rounded_box(f"laundry_cloth{i}", (w, 0.02, h), bevel=0.0, segments=1, material=mat)
		c.location = (x, 0, top - h / 2)
		parts.append(c)
	return lib.group(parts)
