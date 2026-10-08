"""Лавочка: сиденье 1,5 м на высоте 0,45, спинка, две ножки. Под лавкой — укрытие."""
import lib

SPEC = {"max_tris": 800, "max_dim": 1.6}


def build():
	seat = lib.rounded_box("bench", (1.5, 0.45, 0.06), bevel=0.02, material="brick")
	seat.location.z = 0.45
	back = lib.rounded_box("bench_back", (1.5, 0.06, 0.4), bevel=0.02, material="brick")
	back.location = (0, -0.22, 0.72)
	parts = [seat, back]
	for i, x in enumerate((-0.6, 0.6)):
		leg = lib.rounded_box(f"bench_leg{i}", (0.06, 0.4, 0.45), bevel=0.01, material="ink")
		leg.location = (x, 0, 0.225)
		parts.append(leg)
	return lib.group(parts)
