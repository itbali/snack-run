"""Камешки (украшение, план 16): три приплюснутых комка; один меш."""
import lib

SPEC = {"max_tris": 300, "max_dim": 0.5}


def build():
	parts = []
	for i, (x, y, r) in enumerate(((0, 0, 0.12), (0.15, 0.08, 0.08), (-0.1, 0.12, 0.06))):
		s = lib.lumpy(f"s{i}", r, material="asphalt" if i == 0 else "sand", seed=50 + i, segments=7, rings=5)
		s.scale = (1.0, 0.8, 0.55)
		s.location = (x, y, r * 0.35)
		parts.append(s)
	return [lib.join("decor_stones", parts)]
