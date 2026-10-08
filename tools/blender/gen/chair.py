"""Стул кафе: сиденье 0,45 м, спинка, четыре ножки."""
import lib

SPEC = {"max_tris": 800, "max_dim": 0.9}


def build():
	seat = lib.rounded_box("chair", (0.42, 0.42, 0.04), bevel=0.01, segments=1, material="sky")
	seat.location.z = 0.45
	back = lib.rounded_box("chair_back", (0.42, 0.04, 0.4), bevel=0.01, segments=1, material="sky")
	back.location = (0, -0.19, 0.67)
	parts = [seat, back]
	for i, (x, y) in enumerate(((-0.18, -0.18), (0.18, -0.18), (-0.18, 0.18), (0.18, 0.18))):
		leg = lib.cylinder(f"chair_leg{i}", radius=0.02, depth=0.45, material="ink", segments=6)
		leg.location = (x, y, 0.225)
		parts.append(leg)
	return lib.group(parts)
