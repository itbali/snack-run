"""Сборка всех ассетов: blender -b --python tools/blender/build.py -- [имя ...]"""
import importlib
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(ROOT, "assets", "models")

import bpy  # noqa: E402

import export  # noqa: E402
import lib  # noqa: E402


def wanted():
	if "--" in sys.argv:
		names = [a for a in sys.argv[sys.argv.index("--") + 1:] if a]
		if names:
			return names
	gen_dir = os.path.join(HERE, "gen")
	return sorted(f[:-3] for f in os.listdir(gen_dir) if f.endswith(".py") and not f.startswith("_"))


def main():
	failed = []
	for name in wanted():
		lib.clear_scene()
		mod = importlib.import_module(f"gen.{name}")
		objs = mod.build()
		# Ruling (ledger, pre-flight): в SPEC есть служебный ключ animations, check_asset его не принимает.
		errors = lib.check_asset(objs, max_tris=mod.SPEC["max_tris"], max_dim=mod.SPEC["max_dim"])
		if errors:
			failed.append(name)
			for e in errors:
				print(f"ОШИБКА {name}: {e}")
			continue
		path = os.path.join(OUT, f"{name}.glb")
		export.export_glb(path, objs, animations=mod.SPEC.get("animations", False))
		print(f"ОК {name} -> {os.path.relpath(path, ROOT)} ({sum(lib.tri_count(o) for o in objs)} tri)")
	if failed:
		print("ПРОВАЛ:", ", ".join(failed))
		sys.exit(1)


if __name__ == "__main__":
	main()
