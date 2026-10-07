"""Генератор кота: оборачивает cat.py для build.py."""
import cat

SPEC = {"max_tris": 2500, "max_dim": 0.6, "animations": True}


def build():
	return cat.build()
