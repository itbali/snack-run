"""Модули террас (спек «Масштаб и рельеф», раздел 3): подпорная стена, лестница, пандус высотой 1/2/3 м.
Подъём идёт по +Y Blender (= −Z Godot) от начала координат: низ у origin, верх на расстоянии run(h).
Коллайдеры лестниц и пандусов — наклонный параллелепипед (WorldBuilder.kit_colliders)."""
import math

import lib

STEP_RISE = 0.2
STEP_TREAD = 0.3
RAMP_DEG = 25.0
WIDTH = 1.6
WALL_LEN = 4.0
WALL_THICK = 1.0   # стена закрывает всю ячейку обрыва 1 м (ревью плана 10)


def stairs_run(h):
	return round(h / STEP_RISE) * STEP_TREAD


def ramp_run(h):
	return h / math.tan(math.radians(RAMP_DEG))


def wall(h):
	w = lib.rounded_box("retaining_wall", (WALL_LEN, WALL_THICK, h), bevel=0.03, segments=1, material="sand")
	w.location.z = h / 2.0
	cap = lib.rounded_box("retaining_wall_cap", (WALL_LEN + 0.06, WALL_THICK + 0.08, 0.08), bevel=0.02, segments=1, material="cream")
	cap.location.z = h + 0.04
	return lib.group([w, cap])


def stairs(h):
	n = round(h / STEP_RISE)
	parts = []
	for k in range(n):
		top = (k + 1) * STEP_RISE
		s = lib.rounded_box("terrace_stairs" if k == 0 else f"terrace_stairs_s{k}", (WIDTH, STEP_TREAD, top), bevel=0.015, segments=1, material="sand")
		s.location = (0, k * STEP_TREAD + STEP_TREAD / 2.0, top / 2.0)
		parts.append(s)
	for side, x in (("l", -WIDTH / 2 - 0.05), ("r", WIDTH / 2 + 0.05)):
		rail = lib.rounded_box(f"terrace_stairs_side_{side}", (0.1, n * STEP_TREAD, 0.12), bevel=0.0, material="ink")
		rail.location = (x, n * STEP_TREAD / 2.0, h / 2.0 + 0.3)
		rail.rotation_euler = (math.atan2(h, n * STEP_TREAD), 0, 0)
		parts.append(rail)
	return lib.group(parts)


def ramp(h):
	L = ramp_run(h)
	slab = lib.rounded_box("ramp", (WIDTH, math.hypot(L, h), 0.1), bevel=0.0, material="asphalt")
	slab.rotation_euler = (math.atan2(h, L), 0, 0)
	slab.location = (0, L / 2.0, h / 2.0)
	curb_parts = [slab]
	for side, x in (("l", -WIDTH / 2 - 0.05), ("r", WIDTH / 2 + 0.05)):
		c = lib.rounded_box(f"ramp_curb_{side}", (0.1, math.hypot(L, h), 0.18), bevel=0.0, material="cream")
		c.rotation_euler = (math.atan2(h, L), 0, 0)
		c.location = (x, L / 2.0, h / 2.0 + 0.06)
		curb_parts.append(c)
	return lib.group(curb_parts)
