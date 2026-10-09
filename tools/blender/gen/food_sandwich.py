"""Сэндвич: два треугольных ломтика хлеба, салат и сыр между ними."""
import lib

SPEC = {"max_tris": 400, "max_dim": 0.3}


def build():
	bottom = lib.wedge("food_sandwich", width=0.2, length=0.18, height=0.03, material="cream")
	bottom.location.z = 0.015
	leaf = lib.wedge("food_sandwich_leaf", width=0.21, length=0.19, height=0.012, material="leaf")
	leaf.location.z = 0.036
	cheese = lib.wedge("food_sandwich_cheese", width=0.19, length=0.17, height=0.012, material="rarity_legendary")
	cheese.location.z = 0.048
	top = lib.wedge("food_sandwich_top", width=0.2, length=0.18, height=0.03, material="cream")
	top.location.z = 0.069
	return lib.group([bottom, leaf, cheese, top])
