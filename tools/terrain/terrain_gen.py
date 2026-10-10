#!/usr/bin/env python3
"""Генератор карт высот районов (спек «Масштаб и рельеф», раздел 3). Только стандартная библиотека.

Вход  data/terrain_src/<район>.json:
  size [W, D] метров, origin [x0, z0] — угол с наименьшими x, z в координатах Godot, cell 1.0, base — высота по умолчанию,
  channels — имена 4 покрытий (R, G, B, A), default — покрытие по умолчанию,
  features — по порядку: hill {center, radius, height}, basin {center, radius, depth},
             terrace {rect [x0, z0, x1, z1], height} (плато с отвесным краем, max с текущей высотой),
             flat {rect, height} (ровно заданная высота), lift {rect, by} (подъём участка — дорожки, план 18).
  paint — по порядку: {rect | circle [x, z, r], type, soft? метры размытия края}.
Выход data/terrain/<район>.json: size, origin, cell, nx, nz, heights (nz строк по nx, см), splat (base64 RGBA, nx*nz*4).
Запуск: make terrain  (все файлы из data/terrain_src)."""
import base64
import json
import math
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]


class Grid:
	def __init__(self, desc):
		self.w, self.d = desc["size"]
		self.x0, self.z0 = desc["origin"]
		self.cell = float(desc.get("cell", 1.0))
		self.nx = int(round(self.w / self.cell)) + 1
		self.nz = int(round(self.d / self.cell)) + 1
		self.h = [[float(desc.get("base", 0.0))] * self.nx for _ in range(self.nz)]
		self.channels = desc.get("channels", ["asphalt", "paving", "grass", "gravel"])
		default = self.channels.index(desc.get("default", self.channels[0]))
		self.splat = [[[255 if c == default else 0 for c in range(4)] for _ in range(self.nx)] for _ in range(self.nz)]

	def pos(self, i, j):
		return self.x0 + i * self.cell, self.z0 + j * self.cell

	def cells(self):
		for j in range(self.nz):
			for i in range(self.nx):
				yield i, j, *self.pos(i, j)


def _in_rect(x, z, r):
	return r[0] <= x <= r[2] and r[1] <= z <= r[3]


def apply_feature(g, f):
	t = f["type"]
	for i, j, x, z in g.cells():
		if t == "hill" or t == "basin":
			cx, cz = f["center"]
			d = math.hypot(x - cx, z - cz) / f["radius"]
			if d < 1.0:
				bump = math.cos(d * math.pi / 2.0) ** 2   # гладкий купол, нулевой наклон на вершине и у подножия
				g.h[j][i] += bump * (f["height"] if t == "hill" else -f["depth"])
		elif t == "terrace":
			if _in_rect(x, z, f["rect"]):
				g.h[j][i] = max(g.h[j][i], f["height"])
		elif t == "flat":
			if _in_rect(x, z, f["rect"]):
				g.h[j][i] = f["height"]
		elif t == "lift":
			if _in_rect(x, z, f["rect"]):
				g.h[j][i] += f["by"]   # дорожка чуть выше газона (план 18)
		else:
			raise ValueError(f"неизвестный рельеф: {t}")


def apply_paint(g, p):
	c = g.channels.index(p["type"])
	soft = float(p.get("soft", 0.0))
	for i, j, x, z in g.cells():
		if "rect" in p:
			r = p["rect"]
			dist = max(r[0] - x, x - r[2], r[1] - z, z - r[3])   # <0 внутри
		else:
			cx, cz, rad = p["circle"]
			dist = math.hypot(x - cx, z - cz) - rad
		if soft > 0.0:
			k = min(1.0, max(0.0, 0.5 - dist / soft))
		else:
			k = 1.0 if dist <= 0.0 else 0.0
		if k <= 0.0:
			continue
		px = g.splat[j][i]
		for ch in range(4):
			target = 255 if ch == c else 0
			px[ch] = int(round(px[ch] * (1.0 - k) + target * k))


def build(desc):
	g = Grid(desc)
	for f in desc.get("features", []):
		apply_feature(g, f)
	for p in desc.get("paint", []):
		apply_paint(g, p)
	return g


def height_at(g, x, z):
	"""Билинейная высота (та же, что Terrain.height_at в Godot)."""
	fx = (x - g.x0) / g.cell
	fz = (z - g.z0) / g.cell
	i = max(0, min(g.nx - 2, int(math.floor(fx))))
	j = max(0, min(g.nz - 2, int(math.floor(fz))))
	u = min(1.0, max(0.0, fx - i))
	v = min(1.0, max(0.0, fz - j))
	h00, h10, h01, h11 = g.h[j][i], g.h[j][i + 1], g.h[j + 1][i], g.h[j + 1][i + 1]
	return (h00 * (1 - u) + h10 * u) * (1 - v) + (h01 * (1 - u) + h11 * u) * v


def max_slope_deg(g, skip_cliffs_above=None):
	"""Наибольший уклон между соседними вершинами, градусы; перепады больше skip_cliffs_above м (обрывы террас) пропускаются."""
	worst = 0.0
	for j in range(g.nz):
		for i in range(g.nx):
			for di, dj in ((1, 0), (0, 1)):
				if i + di < g.nx and j + dj < g.nz:
					dh = abs(g.h[j + dj][i + di] - g.h[j][i])
					if skip_cliffs_above is not None and dh > skip_cliffs_above:
						continue
					worst = max(worst, math.degrees(math.atan2(dh, g.cell)))
	return worst


def to_json(g):
	raw = bytearray()
	for j in range(g.nz):
		for i in range(g.nx):
			raw.extend(g.splat[j][i])
	return {
		"size": [g.w, g.d], "origin": [g.x0, g.z0], "cell": g.cell, "nx": g.nx, "nz": g.nz,
		"channels": g.channels,
		"heights": [[round(v, 3) for v in row] for row in g.h],
		"splat": base64.b64encode(bytes(raw)).decode(),
	}


def main(argv):
	srcs = [pathlib.Path(a) for a in argv] or sorted((ROOT / "data" / "terrain_src").glob("*.json"))
	for src in srcs:
		g = build(json.loads(src.read_text(encoding="utf-8")))
		out = ROOT / "data" / "terrain" / src.name
		out.write_text(json.dumps(to_json(g), separators=(",", ":")), encoding="utf-8")
		print(f"ОК {out.relative_to(ROOT)}: {g.nx}×{g.nz}, уклон ≤ {max_slope_deg(g, 0.6):.1f}° (без обрывов)")
	return 0


if __name__ == "__main__":
	sys.exit(main(sys.argv[1:]))
