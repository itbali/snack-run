"""Лестница на балкон: 4 ступени по 0,25 м и площадка 1,2×1,2 на высоте 1,0 м.
Ступени идут по -Y Blender (= +Z Godot), как коллайдеры в data/layout/yard.json."""
import lib

SPEC = {"max_tris": 800, "max_dim": 3.5}


def build():
	parts = []
	for i in range(4):
		step = lib.rounded_box("stairs" if i == 0 else f"stairs_step{i}", (1.2, 0.5, 0.25), bevel=0.02, segments=1, material="sand")
		step.location = (0, -i * 0.5, 0.125 + i * 0.25)
		parts.append(step)
	deck = lib.rounded_box("stairs_deck", (1.2, 1.2, 0.12), bevel=0.02, segments=1, material="sand")
	deck.location = (0, -2.55, 0.94)
	parts.append(deck)
	rail = lib.rounded_box("stairs_rail", (0.06, 1.2, 0.9), bevel=0.0, material="ink")
	rail.location = (0.6, -2.55, 1.45)
	parts.append(rail)
	return lib.group(parts)
