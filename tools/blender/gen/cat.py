"""Генератор кота: оборачивает cat.py для build.py."""
import cat

SPEC = {"max_tris": 8000, "max_dim": 0.6, "animations": True}   # subdivision ×6 на триангулированном меше, спек 2.8 с отклонением


def build():
	return cat.build()
