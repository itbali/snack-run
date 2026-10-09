"""Бублик: тор."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	b = lib.torus("food_bagel", major=0.07, minor=0.035, material="cat_orange")
	b.location.z = 0.035
	return [b]
