"""Дом (план 16): этажей 1, стены sand, крыша pitched, глубина 1.8 м — house_kit.house."""
import house_kit

SPEC = {"max_tris": 3000, "max_dim": 11.0}


def build():
	return house_kit.house(floors=1, wall_mat="sand", roof="pitched", depth=1.8, door=True)
