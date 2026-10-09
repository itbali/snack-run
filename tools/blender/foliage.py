"""Листва (план 16): пышный куст из комковатых шапок — общий для bush и bush_flowers."""
import lib

BUSH_LUMPS = ((0.0, 0.0, 0.42, 0.4), (0.38, 0.12, 0.32, 0.3), (-0.34, -0.16, 0.3, 0.3), (0.1, -0.38, 0.3, 0.28),
	(-0.12, 0.36, 0.33, 0.28), (0.18, 0.05, 0.68, 0.24))


def bush(name):
	parts = []
	for i, (x, y, z, r) in enumerate(BUSH_LUMPS):
		c = lib.lumpy(name if i == 0 else f"{name}_{i}", r, material="leaf" if i % 2 == 0 else "olive", seed=31 + i, segments=8, rings=6)
		c.location = (x, y, z)
		parts.append(c)
	return parts
