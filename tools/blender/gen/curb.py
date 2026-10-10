"""Бордюр дорожки (план 18): светлый камень 2,0×0,12×0,1 м. Без коллизии (solid: false)."""
import lib

SPEC = {"max_tris": 200, "max_dim": 2.05}


def build():
	c = lib.rounded_box("curb", (2.0, 0.12, 0.1), bevel=0.02, segments=1, material="cream")
	c.location.z = 0.05
	return lib.group([c])
