"""Печенье: диск с тремя «шоколадными» точками."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	disc = lib.cylinder("food_cookie", radius=0.07, depth=0.02, material="sand")
	disc.location.z = 0.01
	parts = [disc]
	for i, (x, y) in enumerate(((0.02, 0.02), (-0.03, 0.01), (0.0, -0.03))):
		dot = lib.sphere(f"food_cookie_dot{i}", radius=0.012, material="ink", segments=6, rings=4)
		dot.location = (x, y, 0.022)
		parts.append(dot)
	return lib.group(parts)
