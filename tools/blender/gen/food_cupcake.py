"""Капкейк: голубая формочка, розовый крем и вишенка."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	cup = lib.cylinder("food_cupcake", radius=0.06, depth=0.07, segments=10, material="sky")
	cup.location.z = 0.035
	cream = lib.sphere("food_cupcake_cream", 0.065, material="coral", segments=10, rings=6)
	cream.scale = (1, 1, 0.75)
	cream.location.z = 0.095
	cherry = lib.sphere("food_cupcake_cherry", 0.018, material="brick", segments=6, rings=4)
	cherry.location.z = 0.15
	return lib.group([cup, cream, cherry])
