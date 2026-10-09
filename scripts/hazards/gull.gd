class_name Gull
extends Node3D
## Чайка (спек порта, раздел 3): кружит на 4 м радиусом 3–4 м; кот с едой ближе 6 м по горизонтали — 1 с тень и крик,
## затем бросок в точку, где был кот: удар и последняя еда унесена; перерыв 8 с; ночью спит на насесте.

const DIVE_DIST := 6.0
const COOLDOWN := 8.0


static func decide(dist_h: float, has_food: bool, hidden: bool, safe: bool, cooldown: float, night: bool) -> bool:
	return not night and not hidden and not safe and has_food and cooldown <= 0.0 and dist_h < DIVE_DIST
