"""Круглый стол кафе: столешница r 0,45 на высоте 0,75, ножка, основание."""
import lib

SPEC = {"max_tris": 800, "max_dim": 1.0}


def build():
	top = lib.cylinder("cafe_table", radius=0.45, depth=0.04, material="cream", segments=18)
	top.location.z = 0.73
	pole = lib.cylinder("cafe_table_pole", radius=0.04, depth=0.7, material="ink", segments=8)
	pole.location.z = 0.36
	base = lib.cylinder("cafe_table_base", radius=0.25, depth=0.03, material="ink", segments=12)
	base.location.z = 0.015
	return lib.group([top, pole, base])
