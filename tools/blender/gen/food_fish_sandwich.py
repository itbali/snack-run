"""Рыбный сэндвич: булка, золотистое филе, лист салата."""
import lib

SPEC = {"max_tris": 500, "max_dim": 0.3}


def build():
	bottom = lib.cylinder("food_fish_sandwich", radius=0.08, depth=0.03, segments=10, material="sand")
	bottom.location.z = 0.015
	lettuce = lib.cylinder("food_fish_sandwich_leaf", radius=0.085, depth=0.012, segments=10, material="leaf")
	lettuce.location.z = 0.036
	fish = lib.rounded_box("food_fish_sandwich_fish", (0.17, 0.09, 0.025), bevel=0.01, segments=1, material="cat_orange")
	fish.location.z = 0.055
	top = lib.sphere("food_fish_sandwich_top", 0.08, material="sand", segments=10, rings=6)
	top.scale = (1, 1, 0.45)
	top.location.z = 0.07
	return lib.group([bottom, lettuce, fish, top])
