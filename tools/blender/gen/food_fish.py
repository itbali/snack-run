"""Рыба: сплющенная сфера и хвост-клин."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	body = lib.sphere("food_fish", radius=0.06, material="sky")
	body.scale = (1.0, 1.8, 0.6)
	body.location.z = 0.036
	tail = lib.wedge("food_fish_tail", width=0.08, length=0.06, height=0.015, material="sea_deep")
	tail.rotation_euler = (0, 0, 3.14159)
	tail.location = (0, -0.1, 0.036)
	return lib.group([body, tail])
