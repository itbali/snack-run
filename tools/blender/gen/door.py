"""Дверь подъезда с рамой и ступенькой."""
import lib

SPEC = {"max_tris": 800, "max_dim": 2.4}


def build():
	frame = lib.rounded_box("door", (1.3, 0.2, 2.3), bevel=0.03, material="cream")
	frame.location.z = 1.15
	leaf = lib.rounded_box("door_leaf", (1.0, 0.1, 2.1), bevel=0.02, material="sea_deep")
	leaf.location = (0, -0.08, 1.05)
	step = lib.rounded_box("door_step", (1.6, 0.5, 0.15), bevel=0.02, material="sand")
	step.location = (0, -0.35, 0.075)
	return lib.group([frame, leaf, step])
