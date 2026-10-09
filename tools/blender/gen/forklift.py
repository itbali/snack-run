"""Погрузчик причала (план 14): корпус, кабина-рама, мачта, вилы спереди (−Y Blender = +Z Godot — «вперёд» по ходу), ящик."""
import lib

SPEC = {"max_tris": 1500, "max_dim": 2.8}


def build():
	body = lib.rounded_box("forklift", (1.1, 1.8, 0.7), bevel=0.05, material="rarity_legendary")
	body.location = (0, 0.2, 0.55)
	seat = lib.rounded_box("forklift_seat", (0.6, 0.5, 0.3), bevel=0.03, segments=1, material="ink")
	seat.location = (0, 0.4, 1.05)
	parts = [body, seat]
	for i, (x, y) in enumerate(((-0.5, -0.4), (0.5, -0.4), (-0.5, 0.8), (0.5, 0.8))):
		post = lib.rounded_box(f"forklift_post{i}", (0.06, 0.06, 1.1), bevel=0.0, segments=1, material="ink")
		post.location = (x, y, 1.45)
		parts.append(post)
	roof = lib.rounded_box("forklift_roof", (1.1, 1.3, 0.06), bevel=0.01, segments=1, material="ink")
	roof.location = (0, 0.2, 2.0)
	parts.append(roof)
	for i, x in enumerate((-0.35, 0.35)):
		mast = lib.rounded_box(f"forklift_mast{i}", (0.08, 0.08, 1.8), bevel=0.0, segments=1, material="asphalt")
		mast.location = (x, -0.75, 0.9)
		fork = lib.rounded_box(f"forklift_fork{i}", (0.1, 0.9, 0.05), bevel=0.0, segments=1, material="asphalt")
		fork.location = (x, -1.2, 0.25)
		parts += [mast, fork]
	crate = lib.rounded_box("forklift_crate", (0.9, 0.8, 0.6), bevel=0.03, segments=1, material="sand")
	crate.location = (0, -1.2, 0.58)
	parts.append(crate)
	for i, (x, y) in enumerate(((-0.58, -0.3), (0.58, -0.3), (-0.58, 0.75), (0.58, 0.75))):
		w = lib.cylinder(f"forklift_wheel{i}", radius=0.22, depth=0.16, segments=10, material="ink")
		w.rotation_euler = (0, 1.5708, 0)
		w.location = (x, y, 0.22)
		parts.append(w)
	return lib.group(parts)
