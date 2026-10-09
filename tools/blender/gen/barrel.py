"""Бочка (порт): r 0,35, высота 0,7, обручи. На набережной — укрытие, в воде — качающаяся опора (Floater)."""
import lib

SPEC = {"max_tris": 900, "max_dim": 0.8}


def build():
	body = lib.cylinder("barrel", radius=0.35, depth=0.7, segments=12, material="brick")
	body.location.z = 0.35
	parts = [body]
	for i, z in enumerate((0.12, 0.58)):
		h = lib.cylinder(f"barrel_hoop{i}", radius=0.365, depth=0.05, segments=12, material="ink")
		h.location.z = z
		parts.append(h)
	lid = lib.cylinder("barrel_lid", radius=0.3, depth=0.02, segments=12, material="sand")
	lid.location.z = 0.71
	parts.append(lid)
	return lib.group(parts)
