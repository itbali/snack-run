"""Хот-дог: булка и сосиска."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	bun = lib.rounded_box("food_hotdog", (0.22, 0.08, 0.06), bevel=0.02, segments=3, material="sand")
	bun.location.z = 0.03
	sausage = lib.cylinder("food_hotdog_sausage", radius=0.022, depth=0.24, material="brick")
	sausage.rotation_euler = (0, 1.5708, 0)
	sausage.location.z = 0.065
	return lib.group([bun, sausage])
