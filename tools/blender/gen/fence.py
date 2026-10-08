"""Забор 2 м: две перекладины и 5 столбиков."""
import lib

SPEC = {"max_tris": 800, "max_dim": 2.1}


def build():
	rail = lib.rounded_box("fence", (2.0, 0.05, 0.08), bevel=0.01, segments=1, material="leaf")
	rail.location.z = 0.9
	rail2 = lib.rounded_box("fence_rail2", (2.0, 0.05, 0.08), bevel=0.01, segments=1, material="leaf")
	rail2.location.z = 0.45
	parts = [rail, rail2]
	for i in range(5):
		post = lib.rounded_box(f"fence_post{i}", (0.08, 0.08, 1.1), bevel=0.0, material="leaf")
		post.location = (-1.0 + i * 0.5, 0, 0.55)
		parts.append(post)
	return lib.group(parts)
