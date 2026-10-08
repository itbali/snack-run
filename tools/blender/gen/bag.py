"""Мешок мусора: сплюснутая сфера с узлом."""
import lib

SPEC = {"max_tris": 800, "max_dim": 0.8}


def build():
	bag = lib.sphere("bag", radius=0.3, material="ink")
	bag.scale = (1.0, 1.0, 0.8)
	bag.location.z = 0.24
	knot = lib.sphere("bag_knot", radius=0.08, material="ink")
	knot.location.z = 0.52
	return lib.group([bag, knot])
