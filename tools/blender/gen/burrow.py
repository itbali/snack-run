"""Норка краба (план 14): песчаное кольцо с тёмной серединой."""
import lib

SPEC = {"max_tris": 300, "max_dim": 0.6}


def build():
	ring = lib.torus("burrow", major=0.22, minor=0.06, material="sand")
	ring.location.z = 0.02
	hole = lib.cylinder("burrow_hole", radius=0.18, depth=0.02, segments=10, material="ink")
	hole.location.z = 0.005
	return lib.group([ring, hole])
