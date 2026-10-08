"""Пончик с розовой глазурью: тор + тонкий тор сверху."""
import lib

SPEC = {"max_tris": 600, "max_dim": 0.3}   # два тора по 256 треугольников


def build():
	ring = lib.torus("food_donut", major=0.07, minor=0.03, material="sand")
	ring.location.z = 0.03
	glaze = lib.torus("food_donut_glaze", major=0.07, minor=0.022, material="coral")
	glaze.location.z = 0.045
	return lib.group([ring, glaze])
