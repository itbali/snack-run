"""Гараж 3×5,5 м с плоской крышей 2,2 м: короб, ворота, бортик (крыша — площадка для паркура, спек «Масштаб» 3)."""
import lib

SPEC = {"max_tris": 1500, "max_dim": 5.7}


def build():
	body = lib.rounded_box("garage", (3.0, 5.5, 2.2), bevel=0.03, material="olive")
	body.location.z = 1.1
	door = lib.rounded_box("garage_door", (2.4, 0.06, 1.8), bevel=0.01, material="sky")
	door.location = (0, -2.76, 0.9)   # −Y Blender = +Z Godot: ворота смотрят «вперёд»
	rim = lib.rounded_box("garage_rim", (3.1, 5.6, 0.08), bevel=0.01, material="cream")
	rim.location.z = 2.24
	return lib.group([body, door, rim])
