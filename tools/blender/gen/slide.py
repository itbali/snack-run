"""Детская горка с домиком: домик 1,2×1,2 м (стенки 0,7, открыт спереди — укрытие), крыша-площадка, скат и лесенка."""
import math

import lib

SPEC = {"max_tris": 1500, "max_dim": 3.2}


def build():
	roof = lib.rounded_box("slide", (1.3, 1.3, 0.06), bevel=0.02, material="coral")
	roof.location.z = 0.72
	back = lib.rounded_box("slide_back", (1.2, 0.08, 0.7), bevel=0.01, material="sky")
	back.location = (0, -0.56, 0.35)
	parts = [roof, back]
	for i, x in enumerate((-0.56, 0.56)):
		side = lib.rounded_box(f"slide_side{i}", (0.08, 1.2, 0.7), bevel=0.01, material="sky")
		side.location = (x, 0, 0.35)
		parts.append(side)
	ramp = lib.rounded_box("slide_ramp", (0.5, 1.6, 0.05), bevel=0.01, material="rarity_legendary")
	ramp.location = (-1.25, 0, 0.38)
	ramp.rotation_euler = (0.0, math.radians(-27.0), math.radians(90.0))
	parts.append(ramp)
	for i in range(4):
		rung = lib.rounded_box(f"slide_rung{i}", (0.06, 0.5, 0.04), bevel=0.0, material="cream")
		rung.location = (0.75, 0, 0.15 + i * 0.17)
		parts.append(rung)
	return lib.group(parts)
