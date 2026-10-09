"""Поплавок (план 15): красно-белый, на воде перед рыбаком."""
import lib

SPEC = {"max_tris": 300, "max_dim": 0.2}


def build():
	top = lib.sphere("fishing_float", radius=0.05, material="brick", segments=8, rings=6)
	top.location.z = 0.04
	bottom = lib.sphere("fishing_float_b", radius=0.05, material="cream", segments=8, rings=6)
	bottom.location.z = -0.02
	return lib.group([top, bottom])
