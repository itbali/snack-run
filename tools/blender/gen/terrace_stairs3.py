"""Модуль террасы: stairs высотой 3 м (terrace_kit.py)."""
import terrace_kit

SPEC = {"max_tris": 1500, "max_dim": 7.5}


def build():
	return terrace_kit.stairs(3)
