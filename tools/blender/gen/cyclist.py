"""Велосипедист: два колеса, рама, седок с шлемом. Длина 1,8 м, едет по -Y Blender (= -Z Godot)."""
import lib

SPEC = {"max_tris": 1800, "max_dim": 2.0}   # два тора колёс по 256 + две сферы


def build():
	frame = lib.rounded_box("cyclist", (0.08, 0.9, 0.08), bevel=0.02, material="brick")
	frame.location.z = 0.55
	parts = [frame]
	for name, y in (("cyclist_wheel_f", -0.6), ("cyclist_wheel_b", 0.6)):
		wheel = lib.torus(name, major=0.3, minor=0.04, material="ink")
		wheel.rotation_euler = (0, 1.5708, 0)
		wheel.location = (0, y, 0.34)
		parts.append(wheel)
	post = lib.cylinder("cyclist_post", radius=0.03, depth=0.4, material="brick")
	post.location = (0, 0.2, 0.75)
	parts.append(post)
	body = lib.rounded_box("cyclist_body", (0.32, 0.45, 0.5), bevel=0.06, material="sky")
	body.location = (0, 0.05, 1.2)
	body.rotation_euler = (0.5, 0, 0)
	parts.append(body)
	head = lib.sphere("cyclist_head", radius=0.14, material="cream")
	head.location = (0, -0.2, 1.62)
	parts.append(head)
	helmet = lib.sphere("cyclist_helmet", radius=0.155, material="coral")
	helmet.scale = (1, 1, 0.6)
	helmet.location = (0, -0.2, 1.7)
	parts.append(helmet)
	for name, x in (("cyclist_leg_l", 0.12), ("cyclist_leg_r", -0.12)):
		leg = lib.rounded_box(name, (0.1, 0.12, 0.5), bevel=0.03, material="asphalt")
		leg.location = (x, -0.05, 0.75)
		parts.append(leg)
	return lib.group(parts)
