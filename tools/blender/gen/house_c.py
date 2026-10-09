"""Дом (план 16): этажей 2, стены coral, крыша flat, глубина 6.0 м — house_kit.house."""
import house_kit

SPEC = {"max_tris": 3000, "max_dim": 11.0}


def build():
	return house_kit.house(floors=2, wall_mat="coral", roof="flat", depth=6.0, door=True)
