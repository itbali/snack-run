#!/usr/bin/env python3
"""Генератор раскладки района (спек «Масштаб ×3 и рельеф», раздел 4).

Описание data/layout_src/<район>.json → data/layout/<район>.json (для WorldBuilder)
и data/terrain_src/<район>.json (для tools/terrain/terrain_gen.py). Детерминирован (seed);
перед записью проверяет инварианты (check) и падает с перечнем нарушений.
"""
import json
import math
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

KIT_RISE, KIT_TREAD, KIT_RAMP_DEG, KIT_WIDTH = 0.2, 0.3, 25.0, 1.6   # = WorldBuilder.KIT_* (тест сверяет)
WALL_THICK = 1.0   # подпорная стена закрывает ячейку обрыва 1 м (terrace_kit.WALL_THICK)

# Пятна моделей при rot 0: ширина по X, глубина по Z, высота верха над землёй.
FOOTPRINTS = {
	"wall": (6.0, 0.4, 3.2), "garage": (3.1, 5.6, 2.28), "bin": (0.74, 0.84, 1.12), "box": (0.6, 0.6, 0.6),
	"car": (1.7, 3.6, 1.5), "bench": (1.5, 0.45, 0.5), "fence": (2.0, 0.12, 1.0), "kiosk": (2.4, 2.0, 2.6),
	"shed": (2.0, 2.0, 2.3), "cafe_table": (0.9, 0.9, 0.75), "sandbox": (2.0, 2.0, 0.3), "slide": (1.0, 3.0, 1.6),
	"swings": (2.5, 1.2, 2.2), "tree": (0.3, 0.3, 1.6), "lamp": (0.3, 0.3, 3.0), "fountain": (3.0, 3.0, 1.0),
	"retaining_wall1": (4.0, WALL_THICK, 1.0), "retaining_wall2": (4.0, WALL_THICK, 2.0), "retaining_wall3": (4.0, WALL_THICK, 3.0),
	"stairs": (1.2, 3.2, 1.0), "arch": (3.4, 0.6, 2.6), "chair": (0.5, 0.5, 0.9), "umbrella": (0.2, 0.2, 2.2),
}


def kit_run(kind, h):
	return round(h / KIT_RISE) * KIT_TREAD if kind == "stairs" else h / math.tan(math.radians(KIT_RAMP_DEG))


def footprint(p):
	"""(x0, z0, x1, z1, top) пропса; None — неизвестная или несплошная модель. Повороты не по 90° — описанный квадрат."""
	fp = FOOTPRINTS.get(p["model"])
	if fp is None or p.get("solid", True) is False:
		return None
	sx, sz, top = fp
	rot = float(p.get("rot", 0)) % 180
	if abs(rot - 90) < 1:
		sx, sz = sz, sx
	elif rot > 1:
		sx = sz = max(sx, sz)
	x, y, z = p["pos"]
	base = y if p.get("snap", True) else 0.0   # у стен со snap false y — абсолютная высота подножия
	return (x - sx / 2, z - sz / 2, x + sx / 2, z + sz / 2, base + top)


def _local(origin, rot, dx, dz):
	"""Смещение (dx, dz) в осях объекта с поворотом rot (как Basis(UP, rot) в Godot) → мировые x, z."""
	a = math.radians(rot)
	return (round(origin[0] + dx * math.cos(a) + dz * math.sin(a), 3), round(origin[1] - dx * math.sin(a) + dz * math.cos(a), 3))


SIDES = {"n": 0, "s": 180, "w": 90, "e": -90}   # стена дома лицом внутрь прямоугольника


def perimeter(rect, model="wall", length=6.0, sides="nswe", gaps=()):
	"""Модули стен по сторонам rect; gaps — [(сторона, центр вдоль стороны, ширина)] — проходы без стен."""
	x0, z0, x1, z1 = rect
	out = []
	for side in sides:
		horiz = side in "ns"
		a, b = (x0, x1) if horiz else (z0, z1)
		n = max(1, round((b - a) / length))
		step = (b - a) / n
		for k in range(n):
			c = round(a + step * (k + 0.5), 3)
			if any(g[0] == side and abs(c - g[1]) < (g[2] + step) / 2 for g in gaps):
				continue
			pos = [c, 0, z0 if side == "n" else z1] if horiz else [x0 if side == "w" else x1, 0, c]
			out.append({"model": model, "pos": pos, "rot": SIDES[side]})
	return out


def terrace(rect, height, access=()):
	"""Терраса: элемент рельефа, подпорные стены на ячейке обрыва (снаружи rect), лестницы и пандусы.
	access — [(сторона, центр вдоль стороны, "stairs" | "ramp")]. Возвращает (feature, props, blocked)."""
	h = int(height)
	assert h in (1, 2, 3) and all(float(v).is_integer() for v in rect), "терраса: высота 1–3 м, углы в целых метрах"
	x0, z0, x1, z1 = rect
	feature = {"type": "terrace", "rect": list(rect), "height": float(h)}
	gaps = [(s, c, KIT_WIDTH + 0.8) for s, c, _ in access]
	props = []
	half = WALL_THICK / 2
	for w in perimeter([x0 - half, z0 - half, x1 + half, z1 + half], f"retaining_wall{h}", 4.0, "nswe", gaps):
		w["rot"] = 0 if w["rot"] in (0, 180) else 90   # подпорная стена симметрична
		w["snap"] = False
		props.append(w)
	for side, c, kind in access:
		run = kit_run(kind, h)   # верх подъёма — на кромке плато; ход проходит над ячейкой обрыва в проёме стены
		model = f"terrace_stairs{h}" if kind == "stairs" else f"ramp{h}"
		if side == "s":
			pos, rot = [c, 0, z1 + run], 0
		elif side == "n":
			pos, rot = [c, 0, z0 - run], 180
		elif side == "e":
			pos, rot = [x1 + run, 0, c], 90
		else:
			pos, rot = [x0 - run, 0, c], -90
		props.append({"model": model, "pos": [round(v, 3) for v in pos], "rot": rot})
	b = 1.0   # полоса обрыва ±1 м от края — без россыпи
	blocked = [(x0 - b, z0 - b, x1 + b, z0 + b, h), (x0 - b, z1 - b, x1 + b, z1 + b, h),
		(x0 - b, z0 - b, x0 + b, z1 + b, h), (x1 - b, z0 - b, x1 + b, z1 + b, h)]
	for p in props:
		if p["model"].startswith(("terrace_stairs", "ramp")):
			run = kit_run("stairs" if "stairs" in p["model"] else "ramp", h)
			x, _, z = p["pos"]
			ex, ez = _local((x, z), p["rot"], 0, -run)
			blocked.append((min(x, ex) - 1.2, min(z, ez) - 1.2, max(x, ex) + 1.2, max(z, ez) + 1.2, h))
	return feature, props, blocked


def garage_row(origin, count, rot=0, step=3.2):
	"""Ряд гаражей вдоль локальной X; у первого — цепочка прыжков на крышу:
	ящик 0,6 → бак 1,12 → бак с ящиком 1,72 → крыша 2,28. На каждой крыше клубочек, на крайних — редкая еда."""
	props, yarn, spawns = [], [], []
	for k in range(count):
		gx, gz = _local(origin, rot, k * step, 0)
		props.append({"model": "garage", "pos": [gx, 0, gz], "rot": rot})
		yarn.append({"pos": [gx, 2.28, round(gz, 3)]})
		if k in (0, count - 1):
			sx, sz = _local(origin, rot, k * step, 1.6)
			spawns.append({"pos": [sx, 2.28, sz], "allowed": [2, 3]})
	edge = -1.55 - 0.05
	b2 = edge - 0.37
	b1 = b2 - 0.74 - 0.1
	bx = b1 - 0.37 - 0.3 - 0.1
	for dx, model, y in ((b2, "bin", 0), (b2, "box", 1.12), (b1, "bin", 0), (bx, "box", 0)):
		x, z = _local(origin, rot, dx, 1.8)
		props.append({"model": model, "pos": [x, y, z], "rot": rot})
	return {"props": props, "yarn": yarn, "spawn_points": spawns}


def scatter(rng, rect, count, blocked, min_dist=2.0, margin=0.4, taken=None, tries=6000):
	"""count точек в rect не ближе min_dist друг к другу и к taken, вне blocked (+margin)."""
	pts = []
	taken = list(taken or [])
	x0, z0, x1, z1 = rect
	for _ in range(tries):
		if len(pts) >= count:
			break
		x, z = round(rng.uniform(x0, x1), 1), round(rng.uniform(z0, z1), 1)
		if any(f[0] - margin < x < f[2] + margin and f[1] - margin < z < f[3] + margin for f in blocked):
			continue
		if any((x - a) ** 2 + (z - b) ** 2 < min_dist ** 2 for a, b in taken + pts):
			continue
		pts.append((x, z))
	if len(pts) < count:
		raise ValueError(f"scatter: в {rect} поместилось {len(pts)} из {count}")
	return pts


def reachable(fps, jump=0.8, gap=1.0):
	"""Индексы пятен, на которые кот забирается с земли цепочкой прыжков (вверх ≤ jump, зазор ≤ gap)."""
	def near(a, b):
		dx = max(a[0] - b[2], b[0] - a[2], 0.0)
		dz = max(a[1] - b[3], b[1] - a[3], 0.0)
		return math.hypot(dx, dz) <= gap
	seen = {i for i, f in enumerate(fps) if f[4] <= jump}
	queue = list(seen)
	while queue:
		i = queue.pop()
		for j, f in enumerate(fps):
			if j not in seen and f[4] - fps[i][4] <= jump and near(fps[i], f):
				seen.add(j)
				queue.append(j)
	return seen


def model_defaults(props):
	"""Флаги модели (colliders, solid, outline, water) — из первого пропса ядра с той же моделью."""
	d = {}
	for p in props:
		d.setdefault(p["model"], {k: v for k, v in p.items() if k not in ("model", "pos", "rot")})
	return d
