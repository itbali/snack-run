"""Швартовая тумба причала."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.5}


def build():
	post = lib.cylinder("bollard", radius=0.15, depth=0.45, segments=10, material="ink")
	post.location.z = 0.225
	cap = lib.cylinder("bollard_cap", radius=0.2, depth=0.08, segments=10, material="ink")
	cap.location.z = 0.47
	return lib.group([post, cap])
