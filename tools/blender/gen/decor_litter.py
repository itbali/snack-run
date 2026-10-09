"""Мусор двора (украшение, план 16): смятая бумажка и банка на боку; один меш."""
import lib

SPEC = {"max_tris": 200, "max_dim": 0.3}


def build():
	paper = lib.lumpy("p", 0.04, material="cream", seed=71, segments=6, rings=4)
	paper.location.z = 0.035
	can = lib.cylinder("c", radius=0.03, depth=0.11, segments=8, material="sky", smooth=False)
	can.rotation_euler.x = 1.5708
	can.location = (0.12, 0.03, 0.03)
	return [lib.join("decor_litter", [paper, can])]
