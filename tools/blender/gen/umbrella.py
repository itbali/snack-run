"""Зонт кафе: стойка и конус купола r 1,2 на высоте 2,2 м."""
import lib

SPEC = {"max_tris": 800, "max_dim": 2.6}


def build():
	pole = lib.cylinder("umbrella", radius=0.03, depth=2.2, material="ink", segments=8)
	pole.location.z = 1.1
	canopy = lib.cone("umbrella_canopy", radius=1.2, depth=0.45, material="coral", segments=12)
	canopy.location.z = 2.35
	return lib.group([pole, canopy])
