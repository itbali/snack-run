"""Перевёрнутая лодка на пляже (укрытие «под лодкой»): днище сверху, борта до песка, концы открыты."""
import lib

SPEC = {"max_tris": 1200, "max_dim": 4.4}


def build():
	top = lib.rounded_box("boat_upturned", (1.6, 4.2, 0.12), bevel=0.04, material="brick")
	top.location.z = 0.6
	keel = lib.rounded_box("boat_upturned_keel", (0.12, 4.0, 0.1), bevel=0.01, segments=1, material="cream")
	keel.location.z = 0.7
	parts = [top, keel]
	for side, x in (("l", -0.74), ("r", 0.74)):
		s = lib.rounded_box(f"boat_upturned_side_{side}", (0.12, 4.2, 0.6), bevel=0.02, segments=1, material="brick")
		s.location = (x, 0, 0.3)
		parts.append(s)
	return lib.group(parts)
