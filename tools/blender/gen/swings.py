"""Качели: А-образные стойки, перекладина 2,4 м, два сиденья на тросах."""
import math

import lib

SPEC = {"max_tris": 800, "max_dim": 2.6}


def build():
	bar = lib.cylinder("swings", radius=0.05, depth=2.4, segments=8, material="coral")
	bar.rotation_euler = (0, math.pi / 2, 0)
	bar.location.z = 1.8
	parts = [bar]
	for i, x in enumerate((-1.15, 1.15)):
		for j, s in enumerate((-1, 1)):
			leg = lib.cylinder(f"swings_leg{i}{j}", radius=0.04, depth=1.95, segments=8, material="coral")
			leg.rotation_euler = (math.radians(18 * s), 0, 0)
			leg.location = (x, 0.3 * s, 0.9)
			parts.append(leg)
	for i, x in enumerate((-0.5, 0.5)):
		seat = lib.rounded_box(f"swings_seat{i}", (0.4, 0.2, 0.04), bevel=0.01, material="rarity_legendary")
		seat.location = (x, 0, 0.45)
		parts.append(seat)
		for k, dx in enumerate((-0.17, 0.17)):
			rope = lib.cylinder(f"swings_rope{i}{k}", radius=0.01, depth=1.33, segments=4, material="ink")
			rope.location = (x + dx, 0, 1.12)
			parts.append(rope)
	return lib.group(parts)
