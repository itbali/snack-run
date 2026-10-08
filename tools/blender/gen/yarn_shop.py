"""Будка «Пряжа»: пол, задняя и две боковые стенки, навес, полка с клубочками.
Открытый перёд по +Y Blender (= -Z Godot), задняя стенка на -Y Blender (= +Z Godot)."""
import lib

SPEC = {"max_tris": 1500, "max_dim": 2.6}


def build():
	floor = lib.rounded_box("yarn_shop", (2.2, 2.2, 0.03), bevel=0.01, segments=1, material="sand")
	floor.location.z = 0.015   # тонкая плита без коллайдера: кот и шарики стоят на полу двора
	back = lib.rounded_box("yarn_shop_back", (2.2, 0.12, 2.2), bevel=0.02, segments=1, material="lilac")
	back.location = (0, -1.04, 1.18)
	parts = [floor, back]
	for name, x in (("yarn_shop_side_l", -1.04), ("yarn_shop_side_r", 1.04)):
		side = lib.rounded_box(name, (0.12, 2.2, 2.2), bevel=0.02, segments=1, material="lilac")
		side.location = (x, 0, 1.18)
		parts.append(side)
	roof = lib.rounded_box("yarn_shop_roof", (2.6, 2.6, 0.12), bevel=0.03, segments=1, material="coral")
	roof.location.z = 2.34
	parts.append(roof)
	shelf = lib.rounded_box("yarn_shop_shelf", (1.9, 0.3, 0.06), bevel=0.01, segments=1, material="cream")
	shelf.location = (0, -0.85, 1.3)
	parts.append(shelf)
	for i, (x, mat) in enumerate(((-0.6, "coral"), (-0.2, "sky"), (0.2, "rarity_legendary"), (0.6, "leaf"))):
		ball = lib.sphere(f"yarn_shop_ball{i}", radius=0.1, material=mat, segments=10, rings=6)
		ball.location = (x, -0.85, 1.43)
		parts.append(ball)
	return lib.group(parts)
