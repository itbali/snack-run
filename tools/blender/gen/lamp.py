"""Уличный фонарь 2,6 м."""
import lib

SPEC = {"max_tris": 800, "max_dim": 2.7}


def build():
	post = lib.cylinder("lamp", radius=0.05, depth=2.4, material="ink", segments=10)
	post.location.z = 1.2
	base = lib.cylinder("lamp_base", radius=0.14, depth=0.1, material="ink", segments=10)
	base.location.z = 0.05
	head = lib.rounded_box("lamp_head", (0.3, 0.3, 0.2), bevel=0.04, material="rarity_legendary")
	head.location.z = 2.5
	return lib.group([post, base, head])
