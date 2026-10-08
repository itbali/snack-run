"""Лужа: плоский диск."""
import lib

SPEC = {"max_tris": 200, "max_dim": 1.6}


def build():
	p = lib.cylinder("puddle", radius=0.75, depth=0.01, material="sea_light", segments=18)
	p.scale = (1.0, 0.7, 1.0)
	p.location.z = 0.005
	return [p]
