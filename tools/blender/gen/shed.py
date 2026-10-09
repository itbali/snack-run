"""Сторожка садовника 2×2 м: стены, двускатная крыша (клин), дверь, лейка у входа."""
import math

import lib

SPEC = {"max_tris": 1500, "max_dim": 2.6}


def build():
	walls = lib.rounded_box("shed", (2.0, 2.0, 1.9), bevel=0.03, material="olive")
	walls.location.z = 0.95
	roof = lib.wedge("shed_roof", width=2.4, length=1.2, height=2.3, material="brick")
	roof.rotation_euler = (0, math.pi / 2, math.pi / 2)
	roof.location = (0, 1.15, 1.9)
	door = lib.rounded_box("shed_door", (0.7, 0.06, 1.4), bevel=0.01, material="sand")
	door.location = (0, 1.01, 0.7)
	can = lib.cylinder("shed_can", radius=0.12, depth=0.25, segments=10, material="sky")
	can.location = (0.7, 1.25, 0.125)
	return lib.group([walls, roof, door, can])
