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
	"wall": (6.0, 0.4, 3.2), "garage": (3.1, 5.6, 2.28), "bin": (0.74, 0.84, 1.12), "box": (0.6, 0.6, 0.3),
	"car": (1.7, 3.6, 1.5), "bench": (1.5, 0.45, 0.5), "fence": (2.0, 0.12, 1.0), "kiosk": (2.4, 2.0, 2.6),
	"shed": (2.0, 2.0, 2.3), "cafe_table": (0.9, 0.9, 0.75), "sandbox": (2.0, 2.0, 0.3), "slide": (1.0, 3.0, 1.6),
	"swings": (2.5, 1.2, 2.2), "tree": (0.3, 0.3, 1.6), "lamp": (0.3, 0.3, 3.0), "fountain": (3.0, 3.0, 1.0),
	"retaining_wall1": (4.0, WALL_THICK, 1.0), "retaining_wall2": (4.0, WALL_THICK, 2.0), "retaining_wall3": (4.0, WALL_THICK, 3.0),
	"stairs": (1.2, 3.2, 1.0), "arch": (3.4, 0.6, 2.6), "chair": (0.5, 0.5, 0.9), "umbrella": (0.2, 0.2, 2.2),
	"bush": (1.0, 1.0, 0.8), "flowerbed": (2.0, 1.0, 0.4), "door": (1.0, 0.2, 2.0),
	# дома (план 16): фасад в плоскости прежней стены, корпус уходит назад — 4-е число — сдвиг центра по локальной Z
	"house_a": (6.0, 6.0, 7.8, -2.8), "house_b": (6.0, 6.0, 9.55, -2.8), "house_c": (6.0, 6.0, 6.45, -2.8),
	"house_shallow": (6.0, 1.8, 4.7, -0.7),
}


def kit_run(kind, h):
	return round(h / KIT_RISE) * KIT_TREAD if kind == "stairs" else h / math.tan(math.radians(KIT_RAMP_DEG))


def footprint(p):
	"""(x0, z0, x1, z1, top) пропса; None — неизвестная или несплошная модель. Повороты не по 90° — описанный квадрат."""
	fp = FOOTPRINTS.get(p["model"])
	if fp is None or p.get("solid", True) is False:
		return None
	sx, sz, top = fp[:3]
	x, y, z = p["pos"]
	if len(fp) > 3:
		x, z = _local((x, z), float(p.get("rot", 0)), 0, fp[3])   # центр корпуса позади фасада
	rot = float(p.get("rot", 0)) % 180
	if abs(rot - 90) < 1:
		sx, sz = sz, sx
	elif rot > 1:
		sx = sz = max(sx, sz)
	base = y if p.get("snap", True) else 0.0   # у стен со snap false y — абсолютная высота подножия
	return (x - sx / 2, z - sz / 2, x + sx / 2, z + sz / 2, base + top)


def footprints(p):
	"""Пятна пропса: по явным коллайдерам (как их строит WorldBuilder), иначе по таблице; несплошной — []."""
	if p.get("solid", True) is False:
		return []
	if "colliders" not in p:
		f = footprint(p)
		return [f] if f else []
	x, y, z = p["pos"]
	base = y if p.get("snap", True) else 0.0
	rot = float(p.get("rot", 0)) % 360
	out = []
	for c in p["colliders"]:
		sx, sy, sz = c["size"]
		ox, oy, oz = c.get("offset", [0, 0, 0])
		cx, cz = _local((x, z), rot, ox, oz)
		if abs(rot % 180 - 90) < 1:
			sx, sz = sz, sx
		elif rot % 180 > 1:
			sx = sz = max(sx, sz)
		out.append((cx - sx / 2, cz - sz / 2, cx + sx / 2, cz + sz / 2, base + oy + sy / 2))
	return out


def _local(origin, rot, dx, dz):
	"""Смещение (dx, dz) в осях объекта с поворотом rot (как Basis(UP, rot) в Godot) → мировые x, z."""
	a = math.radians(rot)
	return (round(origin[0] + dx * math.cos(a) + dz * math.sin(a), 3), round(origin[1] - dx * math.sin(a) + dz * math.cos(a), 3))


SIDES = {"n": 0, "s": 180, "w": 90, "e": -90}   # стена дома лицом внутрь прямоугольника


def perimeter(rect, model="wall", length=6.0, sides="nswe", gaps=(), extra=None, models=None):
	"""Модули стен по сторонам rect; gaps — [(сторона, центр вдоль стороны, ширина)] — проходы без стен."""
	x0, z0, x1, z1 = rect
	out = []
	for side in sides:
		horiz = side in "ns"
		a, b = (x0, x1) if horiz else (z0, z1)
		span = b - a
		whole = abs(span / length - round(span / length)) < 1e-6
		n = max(1, round(span / length)) if whole else math.ceil(span / length)
		step = length if not whole else span / n
		inward = {"n": 1, "s": -1, "w": 1, "e": -1}[side] * 0.05
		for k in range(n):
			c = round(a + step * (k + 0.5), 3)
			shift = 0.0
			if not whole and k == n - 1:   # сторона не кратна модулю: последний прижат к концу, чуть внутрь (без мерцания)
				c, shift = round(b - length / 2, 3), inward
			if any(g[0] == side and abs(c - g[1]) < (g[2] + step) / 2 for g in gaps):
				continue
			line = (z0 if side == "n" else z1) if horiz else (x0 if side == "w" else x1)
			line = round(line + shift, 3)
			pos = [c, 0, line] if horiz else [line, 0, c]
			m = models[len(out) % len(models)] if models else model   # ряд разных домов (план 16)
			out.append({"model": m, "pos": pos, "rot": SIDES[side], **(extra or {})})
	return out


def terrace(rect, height, access=(), sides="nswe", gaps=(), ground=0.0, wall_h=None, level=None):
	"""Терраса: элемент рельефа, подпорные стены на ячейке обрыва (снаружи rect), лестницы и пандусы.
	access — [(сторона, центр вдоль стороны, "stairs" | "ramp")]. Возвращает (feature, props, blocked)."""
	h = int(height)
	assert h in (1, 2, 3) and all(float(v).is_integer() for v in rect), "терраса: высота 1–3 м, углы в целых метрах"
	x0, z0, x1, z1 = rect
	# height — подъём над окружением (стены, лестницы); level — абсолютная высота плато в terrain_gen (по умолчанию = height).
	feature = {"type": "terrace", "rect": list(rect), "height": float(h if level is None else level)}
	gaps = [(s, c, KIT_WIDTH + 0.8) for s, c, _ in access] + [tuple(g) for g in gaps]
	props = []
	half = WALL_THICK / 2
	for w in perimeter([x0 - half, z0 - half, x1 + half, z1 + half], f"retaining_wall{int(wall_h or h)}", 4.0, sides, gaps):
		w["pos"][1] = ground   # подножие стены — абсолютная высота (у порта база рельефа −2)
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
			ax, az = _local((x, z), p["rot"], 0, 3.0)   # свободный подход 3 м к подножию
			blocked.append((min(ax, ex) - 1.2, min(az, ez) - 1.2, max(ax, ex) + 1.2, max(az, ez) + 1.2, h))
	return feature, props, blocked


def garage_row(origin, count, rot=0, step=3.2, foods=None):
	"""Ряд гаражей вдоль локальной X; у первого — цепочка прыжков на крышу:
	стопка ящиков 0,6 → бак 1,12 → бак с двумя ящиками 1,72 → крыша 2,28. На каждой крыше клубочек, на крайних — редкая еда."""
	props, yarn, spawns = [], [], []
	for k in range(count):
		gx, gz = _local(origin, rot, k * step, 0)
		props.append({"model": "garage", "pos": [gx, 0, gz], "rot": rot})
		yarn.append({"pos": [gx, 2.28, round(gz, 3)]})
		if k in (0, count - 1):
			sx, sz = _local(origin, rot, k * step, 1.6)
			sp = {"pos": [sx, 2.28, sz], "allowed": [2, 3]}
			if foods:
				sp["foods"] = foods   # без списка точка берёт еду любого района (парк во дворе)
			spawns.append(sp)
	edge = -1.55 - 0.05
	b2 = edge - 0.37
	b1 = b2 - 0.74 - 0.1
	bx = b1 - 0.37 - 0.3 - 0.1
	# ящик 0,3 м: стопка из двух — 0,6; бак 1,12; бак с двумя ящиками — 1,72; крыша 2,28 (шаги ≤ 0,6 м)
	for dx, model, y in ((b2, "bin", 0), (b2, "box", 1.12), (b2, "box", 1.42), (b1, "bin", 0), (bx, "box", 0), (bx, "box", 0.3)):
		x, z = _local(origin, rot, dx, 1.8)
		props.append({"model": model, "pos": [x, y, z], "rot": rot})
	return {"props": props, "yarn": yarn, "spawn_points": spawns}


def decor(rng, model, rect, count, blocked, min_dist=0.35, margin=0.15, scale=(0.7, 1.3)):
	"""Мелкие украшения (трава, цветы, камешки) — сколько поместится из count, без исключения; отдельный список decor."""
	out = []
	x0, z0, x1, z1 = rect
	cell = {}
	for _ in range(count * 6):
		if len(out) >= count:
			break
		x, z = round(rng.uniform(x0, x1), 2), round(rng.uniform(z0, z1), 2)
		if any(f[0] - margin < x < f[2] + margin and f[1] - margin < z < f[3] + margin for f in blocked):
			continue
		key = (int(x // min_dist), int(z // min_dist))
		if any((x - a) ** 2 + (z - b) ** 2 < min_dist ** 2 for dx in (-1, 0, 1) for dz in (-1, 0, 1) for a, b in cell.get((key[0] + dx, key[1] + dz), [])):
			continue
		cell.setdefault(key, []).append((x, z))
		out.append({"model": model, "pos": [x, 0, z], "rot": rng.randrange(0, 360, 10), "scale": round(rng.uniform(*scale), 2)})
	return out


def pond(center, radius, depth, level):
	"""Пруд: котловина рельефа, зона воды (поверхность level, абсолютная), 8 маркеров берега на radius + 1,5,
	прямоугольник, закрытый для россыпи. Возвращает (feature, water, shore, blocked)."""
	cx, cz = center
	feature = {"type": "basin", "center": [cx, cz], "radius": radius, "depth": depth}
	water = {"pos": [cx, level, cz], "size": [2 * radius, 2.0, 2 * radius]}
	shore = []
	for k in range(8):
		a = k * math.pi / 4
		shore.append({"pos": [round(cx + (radius + 1.5) * math.cos(a), 2), 0, round(cz + (radius + 1.5) * math.sin(a), 2)]})
	blocked = (cx - radius - 1, cz - radius - 1, cx + radius + 1, cz + radius + 1, 0.0)
	return feature, water, shore, blocked


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


LISTS = ("props", "hideouts", "spawn_points", "yarn", "hazards", "decals", "gates", "water_zones", "shore", "floaters", "decor")


def generate(desc):
	rng = random.Random(desc.get("seed", 1))
	core = json.loads((ROOT / desc["core"]).read_text()) if "core" in desc else {}
	out = {k: [dict(it) for it in core.get(k, [])] for k in LISTS}
	if "shop" in core:
		out["shop"] = core["shop"]
	if desc.get("road") or core.get("road"):
		out["road"] = desc.get("road") or core["road"]
	terrain = json.loads(json.dumps(desc["terrain"]))
	terrain.setdefault("features", [])
	terrain.setdefault("paint", [])
	sample = list(core.get("props", []))
	for path in desc.get("defaults", []):   # районы без ядра берут флаги моделей из ядер других районов
		sample += json.loads((ROOT / path).read_text()).get("props", [])
	defaults = model_defaults(sample)
	gen = {k: [] for k in LISTS}
	blocked = [f for p in out["props"] for f in footprints(p)]
	wet = []

	def add(kind, items):
		for it in items:
			if kind == "props":
				it = {**defaults.get(it["model"], {}), **it}
				blocked.extend(footprints(it))
			out[kind].append(it)
			gen[kind].append(it)

	taken = [(s["pos"][0], s["pos"][2]) for k in ("spawn_points", "yarn", "hideouts") for s in out[k]]
	# Два прохода: сначала структура всех зон (стены, террасы, гаражи, ручные места), потом россыпь —
	# иначе россыпь ранней зоны не знает о лестницах и стенах поздней.
	ops = [op for z in desc.get("zones", []) for op in z["ops"]]
	# украшения — третьим проходом: после россыпи, чтобы не попадать в кусты, урны и коробки (ревью плана 16)
	order = [o for o in ops if o["type"] not in ("scatter", "decor")] + [o for o in ops if o["type"] == "scatter"] + [o for o in ops if o["type"] == "decor"]
	for op in order:
		t = op["type"]
		if t == "perimeter":
			add("props", perimeter(op["rect"], op.get("model", "wall"), op.get("length", 6.0), op.get("sides", "nswe"), [tuple(g) for g in op.get("gaps", [])], op.get("extra"), op.get("models")))
		elif t == "terrace":
			feature, props, bl = terrace(op["rect"], op["height"], [tuple(a) for a in op.get("access", [])],
				op.get("sides", "nswe"), [tuple(g) for g in op.get("gaps", [])], op.get("ground", 0.0), op.get("wall_h"), op.get("level"))
			terrain["features"].append(feature)
			add("props", props)
			blocked.extend(bl)
		elif t == "garage_row":
			row = garage_row(tuple(op["origin"]), op["count"], op.get("rot", 0), op.get("step", 3.2), op.get("foods"))
			for k, v in row.items():
				add(k, v)
		elif t == "pond":
			feature, water, shore, bl = pond(tuple(op["center"]), op["radius"], op["depth"], op["level"])
			terrain["features"].append(feature)
			add("water_zones", [water])
			add("shore", shore)
			blocked.append(bl)
		elif t == "decor":
			solid = blocked + wet
			add("decor", decor(rng, op["model"], op["rect"], op["count"], solid, op.get("min_dist", 0.35)))
		elif t == "path":
			# дорожка (план 18): покрытие, подъём над газоном, несплошные бордюры по длинным краям
			x0, z0, x1, z1 = op["rect"]
			terrain["paint"].append({"rect": op["rect"], "type": op.get("surface", "gravel")})
			terrain["features"].append({"type": "lift", "rect": op["rect"], "by": op.get("lift", 0.06)})
			along_z = (z1 - z0) >= (x1 - x0)
			sides = "we" if along_z else "ns"
			gaps = []
			others = [o["rect"] for o in ops if o["type"] == "path" and o is not op] + [f[:4] for f in blocked]
			for side in sides:
				line = {"w": x0, "e": x1, "n": z0, "s": z1}[side]
				for r in others:   # перекрёсток с другой дорожкой или сплошной пропс на кромке — проём
					if side in "we" and r[0] - 0.1 <= line <= r[2] + 0.1:
						a, b = max(z0, r[1]), min(z1, r[3])
					elif side in "ns" and r[1] - 0.1 <= line <= r[3] + 0.1:
						a, b = max(x0, r[0]), min(x1, r[2])
					else:
						continue
					if b > a:
						gaps.append((side, (a + b) / 2, b - a + 0.4))
			add("props", perimeter(op["rect"], "curb", 2.0, sides, gaps, extra={"solid": False}))
		elif t == "block":
			blocked.append(tuple(op["rect"]) + (0.0,))   # полоса без россыпи (маршрут погрузчика)
		elif t == "flat":
			terrain["features"].append({"type": "flat", "rect": op["rect"], "height": op["height"]})
		elif t == "water":
			x0, z0, x1, z1 = op["rect"]
			add("water_zones", [{"pos": [(x0 + x1) / 2, op["level"], (z0 + z1) / 2], "size": [x1 - x0, op.get("depth", 2.0), z1 - z0]}])
			add("shore", [dict(m) if isinstance(m, dict) else {"pos": list(m)} for m in op.get("shore", [])])   # словарь — с флагами (snap)
			wet.append((x0, z0, x1, z1, 0.0))   # украшения в воду не кладутся
			# Прямоугольник воды не закрывается для россыпи: над ним бывает суша (причал); россыпи задаются по суше.
		elif t == "hill":
			terrain["features"].append({"type": "hill", "center": op["center"], "radius": op["radius"], "height": op["height"]})
		elif t == "paint":
			pt = {k: v for k, v in op.items() if k not in ("type", "surface")}
			pt["type"] = op["surface"]   # ключ type занят самой операцией
			terrain["paint"].append(pt)
		elif t == "place":
			for k in LISTS:
				add(k, [dict(it) for it in op.get(k, [])])
		elif t == "scatter":
			pts = scatter(rng, op["rect"], op["count"], blocked, op.get("min_dist", 2.0), op.get("margin", 0.4), taken)
			taken.extend(pts)
			for x, z in pts:
				w = op["what"]
				if w == "spawn":
					s = {"pos": [x, 0, z], "allowed": op.get("allowed", [0])}
					if "foods" in op:
						s["foods"] = op["foods"]
					add("spawn_points", [s])
				elif w == "yarn":
					add("yarn", [{"pos": [x, 0, z]}])
				elif w == "hideout" and op.get("kind", "box") == "box":
					add("props", [{"model": "box", "pos": [x, 0, z], "rot": rng.randrange(0, 360, 15), "outline": True}])
					add("hideouts", [{"kind": "box", "pos": [x, 0.2, round(z + 0.65, 2)], "size": [0.6, 0.4, 0.6]}])
				elif w == "hideout" and op.get("kind") == "bush":
					add("props", [{"model": "bush", "pos": [x, 0, z], "rot": rng.randrange(0, 360, 15)}])
					add("hideouts", [{"kind": "bush", "pos": [x, 0.25, z], "size": [0.9, 0.5, 0.9]}])
				elif w == "hideout":
					r = rng.choice((0, 90, 180, 270))
					add("props", [{"model": "bench", "pos": [x, 0, z], "rot": r}])
					add("hideouts", [{"kind": "bench", "pos": [x, 0.2, z], "rot": r, "size": [1.3, 0.4, 0.4]}])
				elif w == "prop":
					rot = rng.randrange(0, 360, 15) if op.get("rot") == "random" else op.get("rot", 0)
					add("props", [{"model": op["model"], "pos": [x, 0, z], "rot": rot, **op.get("extra", {})}])
		else:
			raise ValueError(f"неизвестная операция {t}")
	# Несплошное (трава, плющ, лужи) внутри зданий — убрать: после замены стен домами оно оказалось в корпусе (план 16).
	buildings = [f for p in out["props"] for f in footprints(p) if f[4] > 2.5]
	def inside_building(p):
		x, _, z = p["pos"]
		return p.get("solid", True) is False and any(f[0] < x < f[2] and f[1] < z < f[3] for f in buildings)
	out["props"] = [p for p in out["props"] if not inside_building(p)]
	out["decals"] = [d for d in out["decals"] if not any(f[0] < d["pos"][0] < f[2] and f[1] < d["pos"][2] < f[3] for f in buildings)
		or d.get("wall", False)]
	for k, n in desc.get("counts", {}).items():
		if len(out[k]) < n:
			raise ValueError(f"{k}: {len(out[k])} < {n}")
	errs = check(out, gen, terrain)
	if errs:
		raise ValueError("инварианты раскладки:\n" + "\n".join(errs))
	return out, terrain


def check(layout, generated, terrain=None):
	"""Нарушения для созданных генератором точек: еда и клубочки не внутри пропсов, приподнятые — на достижимой опоре."""
	fps = [f for p in layout["props"] for f in footprints(p)]
	reach = reachable(fps)
	errs = []
	for kind in ("spawn_points", "yarn"):
		for it in generated.get(kind, []):
			x, y, z = it["pos"]
			under = [(i, f) for i, f in enumerate(fps) if f[0] < x < f[2] and f[1] < z < f[3]]
			if terrain:
				ox, oz = terrain["origin"]
				sx, sz = terrain["size"]
				if not (ox + 1 <= x <= ox + sx - 1 and oz + 1 <= z <= oz + sz - 1):
					errs.append(f"{kind} {it['pos']}: за краем района")
			if y < 0.3:
				if any(f[4] > y + 0.1 for _, f in under):
					errs.append(f"{kind} {it['pos']}: внутри пропса")
			elif not any(abs(f[4] - y) <= 0.15 and i in reach for i, f in under):
				errs.append(f"{kind} {it['pos']}: нет достижимой опоры на высоте {y}")
	keys = [tuple(y["pos"]) for y in layout["yarn"]]
	if len(keys) != len(set(keys)):
		errs.append("клубочки с одинаковыми позициями (ключи сохранений)")
	return errs


def dump_layout(d):
	"""JSON по элементу в строке: дифф раскладки читается."""
	lines = ["{"]
	keys = list(d)
	for n, k in enumerate(keys):
		comma = "," if n < len(keys) - 1 else ""
		v = d[k]
		if isinstance(v, list):
			lines.append(f'  "{k}": [')
			lines += ["    " + json.dumps(it, ensure_ascii=False) + ("," if i < len(v) - 1 else "") for i, it in enumerate(v)]
			lines.append("  ]" + comma)
		else:
			lines.append(f'  "{k}": ' + json.dumps(v, ensure_ascii=False) + comma)
	lines.append("}")
	return "\n".join(lines) + "\n"


def main(argv):
	src = Path(argv[1])
	desc = json.loads(src.read_text())
	layout, terrain = generate(desc)
	name = desc.get("name", src.stem)
	(ROOT / f"data/layout/{name}.json").write_text(dump_layout(layout))
	(ROOT / f"data/terrain_src/{name}.json").write_text(json.dumps(terrain, ensure_ascii=False, indent=2) + "\n")
	print(f"{name}: пропсов {len(layout['props'])}, еды {len(layout['spawn_points'])}, клубочков {len(layout['yarn'])}, укрытий {len(layout['hideouts'])}")


if __name__ == "__main__":
	main(sys.argv)
