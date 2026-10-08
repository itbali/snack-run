"""Модуль стены дома 6×3,2 м с тремя окнами (ставить вдоль края двора)."""
import lib

SPEC = {"max_tris": 1500, "max_dim": 6.1}


def build():
	wall = lib.rounded_box("wall", (6.0, 0.4, 3.2), bevel=0.03, material="sand")
	wall.location.z = 1.6
	parts = [wall]
	for i, x in enumerate((-1.9, 0.0, 1.9)):
		frame = lib.rounded_box(f"wall_frame{i}", (1.0, 0.1, 1.2), bevel=0.02, material="cream")
		frame.location = (x, -0.22, 1.8)
		glass = lib.rounded_box(f"wall_glass{i}", (0.8, 0.06, 1.0), bevel=0.0, material="sky")
		glass.location = (x, -0.26, 1.8)
		parts += [frame, glass]
	return lib.group(parts)
