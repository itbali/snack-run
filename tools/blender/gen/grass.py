"""Пучок травы: пять узких конусов, чуть наклонённых в стороны. Без коллизии (solid: false в раскладке)."""
import math

import lib

SPEC = {"max_tris": 120, "max_dim": 0.3}


def build():
	parts = []
	for i in range(5):
		a = i * 2 * math.pi / 5
		c = lib.cone("grass" if i == 0 else f"grass_{i}", radius=0.02, depth=0.22, segments=5, material="leaf" if i % 2 else "olive")
		c.location = (math.cos(a) * 0.04, math.sin(a) * 0.04, 0.11)
		c.rotation_euler = (math.sin(a) * 0.35, -math.cos(a) * 0.35, 0.0)
		parts.append(c)
	return lib.group(parts)
