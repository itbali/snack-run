"""Генератор собаки: оборачивает dog.py для build.py."""
import dog

SPEC = {"max_tris": 2500, "max_dim": 0.8, "animations": True}


def build():
	return dog.build()
