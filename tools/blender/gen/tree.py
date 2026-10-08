"""Дерево 3,2 м: ствол и две сферы кроны."""
import lib

SPEC = {"max_tris": 800, "max_dim": 3.3}


def build():
	trunk = lib.cylinder("tree", radius=0.15, depth=1.6, material="brick", segments=10)
	trunk.location.z = 0.8
	crown = lib.sphere("tree_crown", radius=0.9, material="leaf")
	crown.location.z = 2.2
	crown2 = lib.sphere("tree_crown2", radius=0.6, material="olive")
	crown2.location = (0.5, 0.3, 2.6)
	return lib.group([trunk, crown, crown2])
