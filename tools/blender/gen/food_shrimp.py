"""Креветка: изогнутое тельце из сегментов и хвостик."""
import math

import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	parts = []
	for i in range(5):
		a = math.radians(-40 + i * 45)
		s = lib.sphere(f"food_shrimp" if i == 0 else f"food_shrimp_s{i}", 0.035 - i * 0.004, material="coral", segments=8, rings=5)
		s.location = (0.06 * math.cos(a), 0.06 * math.sin(a), 0.035)
		parts.append(s)
	tail = lib.wedge("food_shrimp_tail", width=0.05, length=0.04, height=0.01, material="cream")
	tail.location = (-0.05, 0.05, 0.03)
	parts.append(tail)
	return lib.group(parts)
