"""Фонтан: круглая чаша 3,2 м (бортик 0,45), вода (меш fountain_water — зеркальный), колонна и верхняя чаша."""
import lib

SPEC = {"max_tris": 1500, "max_dim": 3.3}


def build():
	basin = lib.cylinder("fountain", radius=1.6, depth=0.45, segments=24, material="cream")
	basin.location.z = 0.225
	water = lib.cylinder("fountain_water", radius=1.42, depth=0.02, segments=24, material="sea_light")
	water.location.z = 0.4
	column = lib.cylinder("fountain_column", radius=0.22, depth=1.1, segments=12, material="sand")
	column.location.z = 0.95
	bowl = lib.cylinder("fountain_bowl", radius=0.6, depth=0.14, segments=16, material="cream")
	bowl.location.z = 1.45
	top_water = lib.cylinder("fountain_water_top", radius=0.5, depth=0.02, segments=16, material="sea_light")
	top_water.location.z = 1.53
	knob = lib.sphere("fountain_knob", 0.12, material="sky")
	knob.location.z = 1.62
	return lib.group([basin, water, column, bowl, top_water, knob])
