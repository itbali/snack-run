"""Песочница 2×2 м: четыре доски бортика 0,2 м и песок внутри, ведёрко."""
import lib

SPEC = {"max_tris": 800, "max_dim": 2.1}


def build():
	sand = lib.rounded_box("sandbox", (1.84, 1.84, 0.12), bevel=0.02, material="cream")
	sand.location.z = 0.06
	parts = [sand]
	for i, (x, y, sx, sy) in enumerate(((0, 0.96, 2.0, 0.12), (0, -0.96, 2.0, 0.12), (0.96, 0, 0.12, 1.8), (-0.96, 0, 0.12, 1.8))):
		b = lib.rounded_box(f"sandbox_board{i}", (sx, sy, 0.2), bevel=0.02, segments=1, material="brick")
		b.location = (x, y, 0.1)
		parts.append(b)
	bucket = lib.cylinder("sandbox_bucket", radius=0.08, depth=0.12, segments=10, material="sky")
	bucket.location = (0.4, 0.3, 0.18)
	parts.append(bucket)
	return lib.group(parts)
