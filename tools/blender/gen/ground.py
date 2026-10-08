"""Земля двора 60×60 м: асфальт с песочной площадкой тротуара."""
import lib

SPEC = {"max_tris": 200, "max_dim": 60.0}


def build():
	asphalt = lib.rounded_box("ground", (60, 60, 0.1), bevel=0.0, material="asphalt")
	asphalt.location.z = -0.05
	walk = lib.rounded_box("sidewalk", (30, 30, 0.12), bevel=0.03, segments=2, material="sand")
	walk.location = (-10, 10, -0.055)   # верх на +5 мм: без z-fighting с асфальтом, кот стоит на коллизии пола y=0
	return [asphalt, walk]
