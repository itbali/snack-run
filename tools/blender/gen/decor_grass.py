"""Пучок травы (украшение, план 18): плоские изогнутые травинки, расходятся наружу; один меш (foliage.grass_blades)."""
import foliage

SPEC = {"max_tris": 200, "max_dim": 0.6}


def build():
	return [foliage.grass_blades("decor_grass")]
