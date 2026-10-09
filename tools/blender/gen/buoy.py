"""Буёк в море: шар с полосой."""
import lib

SPEC = {"max_tris": 500, "max_dim": 0.7}


def build():
	ball = lib.sphere("buoy", radius=0.3, material="coral")
	ball.location.z = 0.1
	band = lib.cylinder("buoy_band", radius=0.31, depth=0.1, segments=12, material="cream")
	band.location.z = 0.1
	return lib.group([ball, band])
