"""Дома (план 16): замкнутые объёмы вместо одиночных стен. Фасад — в плоскости фасада прежнего модуля стены
(y −0,2 Blender = +Z Godot), корпус уходит назад на depth. Окна спереди и сзади (wall_frame*/wall_glass* — ночью светятся),
главный меш «wall» (текстура штукатурки SurfaceTextures). Крыша — двускатная или плоская с парапетом."""
import bmesh

import lib

WIDTH = 6.0
CHIMNEY = (1.6, 3.3, 1.1)   # смещение трубы от фасада (x, глубина, над карнизом) — то же в yard_life.gd
FLOOR = 3.1


def gable(name, width, length, height, material):
	"""Двускатная крыша: треугольник в плоскости XZ (конёк вдоль Y), основание на z 0, длина по Y от 0 до length."""
	bm = bmesh.new()
	w = width / 2.0
	v = [bm.verts.new(c) for c in ((-w, 0, 0), (w, 0, 0), (0, 0, height), (-w, length, 0), (w, length, 0), (0, length, height))]
	bm.faces.new((v[0], v[1], v[2]))
	bm.faces.new((v[3], v[5], v[4]))
	bm.faces.new((v[0], v[2], v[5], v[3]))
	bm.faces.new((v[1], v[4], v[5], v[2]))
	bm.faces.new((v[0], v[3], v[4], v[1]))
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	return lib._finish(name, bm, material, smooth=False)


def house(floors=2, wall_mat="sand", roof="pitched", depth=6.0, door=False):
	h = floors * FLOOR
	body = lib.rounded_box("wall", (WIDTH, depth, h), bevel=0.04, segments=1, material=wall_mat)
	body.location = (0, depth / 2.0 - 0.2, h / 2.0)
	parts = [body]
	n = 0
	for f in range(floors):
		z = f * FLOOR + 1.8
		for x in (-1.9, 0.0, 1.9):
			if door and f == 0 and x == 0.0:
				continue
			for side, y in (("", -0.22), ("_b", depth - 0.18)):
				if side and depth < 2.5:
					continue   # у неглубокого дома окна только на фасаде
				frame = lib.rounded_box(f"wall_frame{side}{n}", (1.0, 0.1, 1.2), bevel=0.02, segments=1, material="cream")
				frame.location = (x, y, z)
				glass = lib.rounded_box(f"wall_glass{side}{n}", (0.8, 0.06, 1.0), bevel=0.0, segments=1, material="sky")
				glass.location = (x, y - 0.04 if not side else y + 0.04, z)
				parts += [frame, glass]
			n += 1
	if door:
		d = lib.rounded_box("house_door", (1.1, 0.12, 2.1), bevel=0.02, segments=1, material="brick")
		d.location = (0, -0.24, 1.05)
		parts.append(d)
	if roof == "pitched":
		r = gable("house_roof", WIDTH + 0.4, depth + 0.4, 1.6, "brick")
		r.location = (0, -0.4, h)
		parts.append(r)
		ch = lib.rounded_box("house_chimney", (0.45, 0.45, 1.3), bevel=0.02, segments=1, material="brick")
		ch.location = (CHIMNEY[0], CHIMNEY[1] if depth > 2.5 else depth / 2.0, h + CHIMNEY[2])   # дымок — YardLife (план 20)
		parts.append(ch)
	else:
		cap = lib.rounded_box("house_cap", (WIDTH + 0.1, depth + 0.1, 0.25), bevel=0.02, segments=1, material="cream")
		cap.location = (0, depth / 2.0 - 0.2, h + 0.12)
		parts.append(cap)
	return lib.group(parts)
