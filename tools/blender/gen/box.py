"""Картонная коробка 0,45×0,35×0,3 м (укрытие и пропс двора)."""
import lib

SPEC = {"max_tris": 800, "max_dim": 0.6}


def build():
	body = lib.rounded_box("box", (0.45, 0.35, 0.30), bevel=0.015, segments=2, material="sand")
	body.location.z = 0.15
	return [body]
