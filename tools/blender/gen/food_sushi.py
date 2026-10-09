"""Суши: два нигири — рис, лосось, полоска нори."""
import lib

SPEC = {"max_tris": 500, "max_dim": 0.3}


def build():
	parts = []
	for i, x in enumerate((-0.045, 0.045)):
		rice = lib.rounded_box("food_sushi" if i == 0 else f"food_sushi_r{i}", (0.07, 0.12, 0.04), bevel=0.012, segments=2, material="eye_white")
		rice.location = (x, 0, 0.02)
		fish = lib.rounded_box(f"food_sushi_f{i}", (0.075, 0.13, 0.02), bevel=0.008, segments=2, material="coral")
		fish.location = (x, 0, 0.05)
		nori = lib.rounded_box(f"food_sushi_n{i}", (0.08, 0.025, 0.065), bevel=0.0, segments=1, material="ink")
		nori.location = (x, 0, 0.032)
		parts += [rice, fish, nori]
	return lib.group(parts)
