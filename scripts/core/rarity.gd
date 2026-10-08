class_name Rarity
extends RefCounted
## Редкости еды: веса спавна, сытость, цвета (спек 2.2, 3.3, 3.4).

enum Tier { COMMON, RARE, VERY_RARE, LEGENDARY }

const WEIGHTS := {Tier.COMMON: 60, Tier.RARE: 25, Tier.VERY_RARE: 12, Tier.LEGENDARY: 3}
const SATIETY := {Tier.COMMON: 1, Tier.RARE: 3, Tier.VERY_RARE: 6, Tier.LEGENDARY: 15}
const COLORS := {
	Tier.COMMON: Color("#4D945B"),
	Tier.RARE: Color("#6491E4"),
	Tier.VERY_RARE: Color("#C473D4"),
	Tier.LEGENDARY: Color("#FABE32"),
}
const NAMES := {Tier.COMMON: "Обычная", Tier.RARE: "Редкая", Tier.VERY_RARE: "Очень редкая", Tier.LEGENDARY: "Легендарная"}


static func pick_weighted(allowed: Array, rng: RandomNumberGenerator) -> int:
	if allowed.is_empty():
		return Tier.COMMON
	var total := 0
	for t in allowed:
		total += WEIGHTS[t]
	var roll := rng.randi_range(1, total)
	for t in allowed:
		roll -= WEIGHTS[t]
		if roll <= 0:
			return t
	return allowed[-1]
