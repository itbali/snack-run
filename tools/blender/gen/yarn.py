"""Клубочек пряжи 0,16 м: сфера с двумя лентами-торами."""
import lib

SPEC = {"max_tris": 800, "max_dim": 0.25}


def build():
	ball = lib.sphere("yarn", radius=0.08, material="lilac")
	ball.location.z = 0.08
	band = lib.torus("yarn_band", major=0.075, minor=0.012, material="coral")
	band.location.z = 0.08
	band.rotation_euler = (0.6, 0.3, 0)
	band2 = lib.torus("yarn_band2", major=0.075, minor=0.012, material="coral")
	band2.location.z = 0.08
	band2.rotation_euler = (-0.5, 0.9, 0)
	return lib.group([ball, band, band2])
