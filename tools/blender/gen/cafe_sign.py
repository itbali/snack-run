"""Вывеска кафе: две стойки и коралловая доска с кремовой рамкой."""
import lib

SPEC = {"max_tris": 800, "max_dim": 3.0}


def build():
	board = lib.rounded_box("cafe_sign", (2.6, 0.12, 0.8), bevel=0.03, segments=1, material="coral")
	board.location.z = 2.2
	frame = lib.rounded_box("cafe_sign_frame", (2.8, 0.08, 1.0), bevel=0.03, segments=1, material="cream")
	frame.location = (0, 0.04, 2.2)
	parts = [board, frame]
	for i, x in enumerate((-1.2, 1.2)):
		post = lib.cylinder(f"cafe_sign_post{i}", radius=0.05, depth=1.8, material="ink", segments=8)
		post.location = (x, 0, 0.9)
		parts.append(post)
	return lib.group(parts)
