"""Понтон-ступень у проёма причала (ревью плана 13): дощатая площадка 1,4×1,6 м высотой 0,3 — с лодки на причал в два шага."""
import lib

SPEC = {"max_tris": 600, "max_dim": 1.7}


def build():
	parts = []
	for i in range(4):
		p = lib.rounded_box("pontoon" if i == 0 else f"pontoon_plank{i}", (1.4, 0.36, 0.08), bevel=0.01, segments=1, material="sand" if i % 2 else "brick")
		p.location = (0, -0.6 + i * 0.4, 0.26)
		parts.append(p)
	for i, (x, y) in enumerate(((-0.6, -0.7), (0.6, -0.7), (-0.6, 0.7), (0.6, 0.7))):
		post = lib.cylinder(f"pontoon_post{i}", radius=0.07, depth=0.6, segments=8, material="ink")
		post.location = (x, y, 0.0)
		parts.append(post)
	return lib.group(parts)
