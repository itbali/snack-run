"""Клумба: круглый бортик 1,4 м с землёй и цветами (шарики коралловые и золотые на стеблях)."""
import math

import lib

SPEC = {"max_tris": 800, "max_dim": 1.5}


def build():
	rim = lib.cylinder("flowerbed", radius=0.7, depth=0.25, segments=16, material="sand")
	rim.location.z = 0.125
	soil = lib.cylinder("flowerbed_soil", radius=0.62, depth=0.04, segments=16, material="brick")
	soil.location.z = 0.25
	parts = [rim, soil]
	for i in range(8):
		a = i * 2 * math.pi / 8
		r = 0.38 if i % 2 else 0.2
		head = lib.sphere(f"flowerbed_f{i}", 0.07, material="coral" if i % 2 else "rarity_legendary", segments=6, rings=4)
		head.location = (math.cos(a) * r, math.sin(a) * r, 0.42)
		parts.append(head)
	leafy = lib.sphere("flowerbed_leaves", 0.5, material="leaf", segments=8, rings=5)
	leafy.scale = (1, 1, 0.35)
	leafy.location.z = 0.3
	parts.append(leafy)
	return lib.group(parts)
