class_name Crab
extends HazardBase
## Краб (спек порта, раздел 3): сидит в норке; кот ближе 3 м (ночью 4 м) — вылезает и бежит боком 2,4 м/с; прыжок кота над
## ним или 5 с погони — прячется в норку на 6 с. Касание — щипок (удар).

const NOTICE := 3.0
const NOTICE_NIGHT := 4.0
const CHASE_MAX := 5.0
const HIDE_TIME := 6.0


static func decide(state: StringName, dist: float, cat_above: bool, chase_t: float, hide_left: float, night: bool) -> StringName:
	match state:
		&"burrow":
			return &"chase" if dist < (NOTICE_NIGHT if night else NOTICE) else &"burrow"
		&"chase":
			return &"hide" if cat_above or chase_t >= CHASE_MAX else &"chase"
		&"hide":
			return &"hide" if hide_left > 0.0 else &"burrow"
	return state
