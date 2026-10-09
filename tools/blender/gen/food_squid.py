"""Кальмар: сиреневая мантия-конус и щупальца."""
import lib

SPEC = {"max_tris": 500, "max_dim": 0.3}


def build():
	body = lib.cone("food_squid", radius=0.05, depth=0.14, segments=8, material="lilac")
	body.location.z = 0.13
	parts = [body]
	for i, (x, y) in enumerate(((-0.03, 0), (0.03, 0), (0, 0.03), (0, -0.03))):
		t = lib.cylinder(f"food_squid_t{i}", radius=0.01, depth=0.06, segments=6, material="cream")
		t.location = (x, y, 0.03)
		parts.append(t)
	return lib.group(parts)
