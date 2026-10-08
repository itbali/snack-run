"""Мороженое: рожок и шарик."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	cone = lib.cone("food_ice_cream", radius=0.04, depth=0.13, material="sand")
	cone.rotation_euler = (3.14159, 0, 0)
	cone.location.z = 0.065
	scoop = lib.sphere("food_ice_cream_scoop", radius=0.045, material="lilac")
	scoop.location.z = 0.15
	return lib.group([cone, scoop])
