"""Мусорный бак 0,7×0,8×1,1 м: корпус + крышка + 2 колеса."""
import lib

SPEC = {"max_tris": 800, "max_dim": 1.2}


def build():
	body = lib.rounded_box("bin", (0.7, 0.8, 0.95), bevel=0.04, segments=3, material="leaf")
	body.location.z = 0.55
	lid = lib.rounded_box("bin_lid", (0.74, 0.84, 0.12), bevel=0.04, segments=3, material="olive")
	lid.location.z = 1.06
	parts = [body, lid]
	for x in (-0.25, 0.25):
		wheel = lib.rounded_box(f"bin_wheel_{'l' if x < 0 else 'r'}", (0.12, 0.12, 0.12), bevel=0.05, segments=3, material="ink")
		wheel.location = (x, -0.35, 0.06)
		parts.append(wheel)
	for p in parts[1:]:
		p.parent = body
		p.matrix_parent_inverse = body.matrix_world.inverted()
	return parts
