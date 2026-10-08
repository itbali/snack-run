"""Арка во двор: два пилона и перекладина, проём 2,4×2,6 м."""
import lib

SPEC = {"max_tris": 800, "max_dim": 3.6}


def build():
	left = lib.rounded_box("arch", (0.5, 0.6, 2.6), bevel=0.04, material="sand")
	left.location = (-1.45, 0, 1.3)
	right = lib.rounded_box("arch_right", (0.5, 0.6, 2.6), bevel=0.04, material="sand")
	right.location = (1.45, 0, 1.3)
	top = lib.rounded_box("arch_top", (3.4, 0.6, 0.6), bevel=0.06, material="brick")
	top.location.z = 2.9
	return lib.group([left, right, top])
