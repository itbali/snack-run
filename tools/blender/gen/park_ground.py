"""Пол парка 30×32 м: газон (меш lawn) и гравийные дорожки (меш path). Текстуры — SurfaceTextures по именам.
Центр модели — центр парка; в раскладке ставится в (0, 0, 45). +Y Blender = −Z Godot (к кафе)."""
import lib

SPEC = {"max_tris": 400, "max_dim": 32.5}


def build():
	lawn = lib.rounded_box("lawn", (30, 32, 0.1), bevel=0.0, material="leaf")
	lawn.location.z = -0.044   # верх на +6 мм: над асфальтом двора там, где они перекрываются
	# Дорожки: крест через фонтан и отвод к воротам (x 12, южный край). Верх на +12 мм.
	pieces = []
	for name, size, loc in (
		("p_ns", (2.2, 32, 0.1), (0, 0)),
		("p_ew", (30, 2.2, 0.1), (0, 0)),
		("p_gate", (2.2, 9, 0.1), (12, 11.5)),      # от ворот (Godot z 30) на север до z 39
		("p_gate2", (12, 2.2, 0.1), (6, 7)),       # к центральной дорожке (Godot z 38)
		("p_play", (8, 2.2, 0.1), (-8, 3)),        # к площадке (Godot z 42)
	):
		b = lib.rounded_box(name, size, bevel=0.0, material="sand")
		b.location = (loc[0], loc[1], -0.038)
		pieces.append(b)
	path = lib.join("path", pieces)
	return [lawn, path]
