"""Припаркованная машина 3,6×1,7×1,4 м, клиренс 0,3 м (под ней укрытие)."""
import lib

SPEC = {"max_tris": 1500, "max_dim": 3.7}


def build():
	body = lib.rounded_box("car", (1.7, 3.6, 0.5), bevel=0.08, segments=3, material="brick")
	body.location.z = 0.55
	cabin = lib.rounded_box("car_cabin", (1.5, 1.9, 0.55), bevel=0.12, segments=3, material="brick")
	cabin.location = (0, -0.2, 1.07)
	glass = lib.rounded_box("car_glass", (1.52, 1.5, 0.35), bevel=0.05, material="sky")
	glass.location = (0, -0.2, 1.1)
	parts = [body, cabin, glass]
	for i, (x, y) in enumerate(((-0.8, 1.1), (0.8, 1.1), (-0.8, -1.1), (0.8, -1.1))):
		wheel = lib.cylinder(f"car_wheel{i}", radius=0.32, depth=0.22, material="ink", segments=14)
		wheel.rotation_euler = (0, 1.5708, 0)
		wheel.location = (x, y, 0.32)
		parts.append(wheel)
	return lib.group(parts)
