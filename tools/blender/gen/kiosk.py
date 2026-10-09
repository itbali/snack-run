"""Киоск мороженого 1,6×1,2×2,2 м: корпус, окошко, полосатый навес, рожок-вывеска сверху."""
import lib

SPEC = {"max_tris": 1500, "max_dim": 2.8}


def build():
	body = lib.rounded_box("kiosk", (1.6, 1.2, 2.0), bevel=0.04, material="cream")
	body.location.z = 1.0
	window = lib.rounded_box("kiosk_window", (1.1, 0.06, 0.6), bevel=0.01, material="sky")
	window.location = (0, 0.6, 1.3)
	counter = lib.rounded_box("kiosk_counter", (1.3, 0.3, 0.06), bevel=0.01, material="sand")
	counter.location = (0, 0.72, 0.95)
	parts = [body, window, counter]
	for i in range(4):
		stripe = lib.rounded_box(f"kiosk_awning{i}", (0.42, 0.5, 0.05), bevel=0.0, material="coral" if i % 2 == 0 else "cream")
		stripe.location = (-0.63 + i * 0.42, 0.8, 1.75)
		stripe.rotation_euler = (0.35, 0, 0)
		parts.append(stripe)
	cone = lib.cone("kiosk_cone", radius=0.18, depth=0.4, segments=10, material="sand")
	cone.rotation_euler = (3.14159, 0, 0)
	cone.location.z = 2.25
	scoop = lib.sphere("kiosk_scoop", 0.2, material="coral")
	scoop.location.z = 2.5
	parts += [cone, scoop]
	return lib.group(parts)
