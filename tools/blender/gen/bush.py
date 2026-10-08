"""Куст: три сферы."""
import lib

SPEC = {"max_tris": 800, "max_dim": 1.2}


def build():
	a = lib.sphere("bush", radius=0.4, material="leaf")
	a.location.z = 0.38
	b = lib.sphere("bush_b", radius=0.3, material="olive")
	b.location = (0.35, 0.1, 0.3)
	c = lib.sphere("bush_c", radius=0.28, material="leaf")
	c.location = (-0.3, -0.15, 0.28)
	return lib.group([a, b, c])
