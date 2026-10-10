"""Мусор (украшение, план 18): пакет от чипсов и пластиковая бутылка с крышкой; один меш."""
import lib

SPEC = {"max_tris": 300, "max_dim": 0.45}


def build():
	bag = lib.rounded_box("bag", (0.14, 0.2, 0.03), bevel=0.012, segments=2, material="coral")
	bag.rotation_euler.z = 0.4
	bag.location.z = 0.016
	stripe = lib.rounded_box("st", (0.145, 0.05, 0.032), bevel=0.01, segments=1, material="rarity_legendary")
	stripe.rotation_euler.z = 0.4
	stripe.location.z = 0.017
	bottle = lib.cylinder("bt", radius=0.035, depth=0.2, segments=10, material="sea_light", smooth=False)
	bottle.rotation_euler = (1.5708, 0, -0.9)
	bottle.location = (-0.15, 0.08, 0.035)
	cap = lib.cylinder("cp", radius=0.02, depth=0.03, segments=8, material="leaf", smooth=False)
	cap.rotation_euler = (1.5708, 0, -0.9)
	cap.location = (-0.23, 0.15, 0.035)
	return [lib.join("decor_litter2", [bag, stripe, bottle, cap])]
