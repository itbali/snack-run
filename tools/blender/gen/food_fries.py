"""Картошка фри: красный стаканчик и палочки."""
import lib

SPEC = {"max_tris": 500, "max_dim": 0.3}


def build():
	cup = lib.rounded_box("food_fries", (0.11, 0.07, 0.11), bevel=0.01, segments=1, material="brick")
	cup.location.z = 0.055
	parts = [cup]
	for i, (x, y, h) in enumerate(((-0.03, 0, 0.17), (0, 0.01, 0.19), (0.03, -0.01, 0.16), (-0.015, -0.015, 0.18), (0.02, 0.02, 0.175))):
		f = lib.rounded_box(f"food_fries_f{i}", (0.016, 0.016, h - 0.06), bevel=0.0, segments=1, material="rarity_legendary")
		f.location = (x, y, 0.06 + (h - 0.06) / 2)
		parts.append(f)
	return lib.group(parts)
