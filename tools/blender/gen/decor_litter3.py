"""Мусор (украшение, план 18): газета с колонками текста и смятый стаканчик; один меш."""
import lib

SPEC = {"max_tris": 300, "max_dim": 0.45}


def build():
	paper = lib.rounded_box("np", (0.22, 0.3, 0.008), bevel=0.0, segments=1, material="cream")
	paper.location.z = 0.005
	paper.rotation_euler.z = 0.3
	parts = [paper]
	for i in range(3):
		l = lib.rounded_box(f"ln{i}", (0.012, 0.2, 0.002), bevel=0.0, segments=1, material="ink")
		l.rotation_euler.z = 0.3
		l.location = (-0.06 + i * 0.06 - 0.02 * i, 0.01 * i, 0.01)
		parts.append(l)
	cup = lib.cone("cup", radius=0.04, depth=0.09, segments=9, material="coral", smooth=False)
	cup.rotation_euler = (1.4, 0, 1.2)
	cup.location = (0.16, -0.08, 0.04)
	parts.append(cup)
	return [lib.join("decor_litter3", parts)]
