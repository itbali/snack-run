"""Дождеватель газона: низкая головка на стойке (вода — частицы в Godot)."""
import lib

SPEC = {"max_tris": 300, "max_dim": 0.3}


def build():
	base = lib.cylinder("sprinkler", radius=0.06, depth=0.08, segments=10, material="ink")
	base.location.z = 0.04
	head = lib.cylinder("sprinkler_head", radius=0.035, depth=0.08, segments=8, material="sky")
	head.location.z = 0.12
	return lib.group([base, head])
