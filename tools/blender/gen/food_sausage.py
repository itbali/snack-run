"""Сосиска 0,2 м."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	body = lib.cylinder("food_sausage", radius=0.03, depth=0.2, material="brick")
	body.rotation_euler = (1.5708, 0, 0)
	body.location.z = 0.03
	return [body]
