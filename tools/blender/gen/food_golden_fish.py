"""Золотая рыбка (легендарная, только из ведра рыбака): золотое тельце, хвост, плавник."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	body = lib.sphere("food_golden_fish", radius=0.06, material="rarity_legendary")
	body.scale = (1.0, 1.8, 0.6)
	body.location.z = 0.036
	tail = lib.wedge("food_golden_fish_tail", width=0.09, length=0.06, height=0.015, material="cat_orange")
	tail.rotation_euler = (0, 0, 3.14159)
	tail.location = (0, -0.1, 0.036)
	fin = lib.wedge("food_golden_fish_fin", width=0.015, length=0.05, height=0.03, material="cat_orange")
	fin.location = (0, 0, 0.06)
	return lib.group([body, tail, fin])
