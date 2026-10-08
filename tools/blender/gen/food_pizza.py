"""Ломтик пиццы: тесто-клин, корка, две пепперони."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	base = lib.wedge("food_pizza", width=0.18, length=0.25, height=0.02, material="cat_orange")
	base.location.z = 0.01
	crust = lib.cylinder("food_pizza_crust", radius=0.018, depth=0.18, material="sand")
	crust.rotation_euler = (0, 1.5708, 0)
	crust.location = (0, 0.245, 0.02)
	parts = [base, crust]
	for i, (x, y) in enumerate(((0.03, 0.17), (-0.03, 0.12))):
		p = lib.cylinder(f"food_pizza_pep{i}", radius=0.022, depth=0.006, material="brick", segments=10)
		p.location = (x, y, 0.023)
		parts.append(p)
	return lib.group(parts)
