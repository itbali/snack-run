"""Удочка рыбака (план 15): тонкое удилище под наклоном вперёд (−Y Blender = +Z Godot), катушка."""
import math

import lib

SPEC = {"max_tris": 400, "max_dim": 2.6}


def build():
	rod = lib.cylinder("rod", radius=0.02, depth=2.4, segments=6, material="ink")
	rod.rotation_euler = (math.radians(-60), 0, 0)
	rod.location = (0, -1.0, 1.5)
	reel = lib.cylinder("rod_reel", radius=0.05, depth=0.04, segments=8, material="sky")
	reel.rotation_euler = (0, math.radians(90), 0)
	reel.location = (0.04, -0.15, 0.95)
	return lib.group([rod, reel])
