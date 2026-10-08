"""Оса 0,3 м: грудь, полосатое брюшко, два крыла."""
import lib

SPEC = {"max_tris": 900, "max_dim": 0.35}


def build():
	thorax = lib.sphere("wasp", radius=0.045, material="ink")
	thorax.location.z = 0.0
	head = lib.sphere("wasp_head", radius=0.032, material="ink")
	head.location = (0, 0.065, 0.005)
	abdomen = lib.sphere("wasp_abdomen", radius=0.05, material="rarity_legendary")
	abdomen.scale = (1.0, 1.6, 0.9)
	abdomen.location = (0, -0.09, -0.005)
	parts = [thorax, head, abdomen]
	for i, y in enumerate((-0.07, -0.11)):
		ring = lib.cylinder(f"wasp_ring{i}", radius=0.047, depth=0.012, material="ink", segments=12)
		ring.rotation_euler = (1.5708, 0, 0)
		ring.location = (0, y, -0.005)
		parts.append(ring)
	for name, x in (("wasp_wing_l", 0.07), ("wasp_wing_r", -0.07)):
		wing = lib.rounded_box(name, (0.12, 0.05, 0.004), bevel=0.0, material="cream")
		wing.location = (x, 0.0, 0.045)
		wing.rotation_euler = (0, 0.25 if x > 0 else -0.25, 0)
		parts.append(wing)
	return lib.group(parts)
