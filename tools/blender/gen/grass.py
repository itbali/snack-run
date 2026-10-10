"""Пучок травы (пропс, план 18): те же травинки, что у украшения, чуть выше. Без коллизии (solid: false в раскладке)."""
import foliage

SPEC = {"max_tris": 200, "max_dim": 0.7}


def build():
	return [foliage.grass_blades("grass", count=13, seed=3, height=0.34)]
