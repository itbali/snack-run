"""Мусор (украшение, план 18): смятая бумажка и банка с полосой на боку; один меш."""
import lib

SPEC = {"max_tris": 300, "max_dim": 0.3}


def build():
	paper = lib.lumpy("p", 0.045, material="cream", seed=71, segments=7, rings=5)
	paper.location.z = 0.04
	can = lib.cylinder("c", radius=0.032, depth=0.11, segments=10, material="sky", smooth=False)
	can.rotation_euler = (1.5708, 0, 0.6)
	can.location = (0.13, 0.04, 0.032)
	band = lib.cylinder("b", radius=0.034, depth=0.04, segments=10, material="brick", smooth=False)
	band.rotation_euler = (1.5708, 0, 0.6)
	band.location = (0.13, 0.04, 0.032)
	return [lib.join("decor_litter", [paper, can, band])]
