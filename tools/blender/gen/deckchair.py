"""Шезлонг на пляже: рама и полосатая ткань под наклоном."""
import math

import lib

SPEC = {"max_tris": 600, "max_dim": 1.7}


def build():
	seat = lib.rounded_box("deckchair", (0.6, 1.0, 0.05), bevel=0.01, segments=1, material="sea_light")
	seat.location = (0, -0.3, 0.3)
	back = lib.rounded_box("deckchair_back", (0.6, 0.8, 0.05), bevel=0.01, segments=1, material="cream")
	back.rotation_euler = (math.radians(-55), 0, 0)
	back.location = (0, 0.45, 0.55)
	parts = [seat, back]
	for i, (x, y) in enumerate(((-0.28, -0.75), (0.28, -0.75), (-0.28, 0.15), (0.28, 0.15))):
		leg = lib.rounded_box(f"deckchair_leg{i}", (0.04, 0.04, 0.3), bevel=0.0, segments=1, material="sand")
		leg.location = (x, y, 0.15)
		parts.append(leg)
	return lib.group(parts)
