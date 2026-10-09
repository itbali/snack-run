class_name Wave
extends Node3D
## Волна на пляже (спек порта, раздел 3): каждые 14 с накат на 5 м за 3 с и откат за 3 с; за 1,5 с — пена и шум.

const PERIOD := 14.0
const RUN := 3.0
const REACH := 5.0
const FOAM_LEAD := 1.5


static func front_at(t: float) -> float:
	## Насколько вглубь пляжа дошла вода (метры от линии воды).
	var u := fposmod(t, PERIOD)
	if u <= RUN:
		return REACH * u / RUN   # линейно: игроку легко прочитать, докуда дойдёт вода
	if u <= 2.0 * RUN:
		return REACH * (1.0 - (u - RUN) / RUN)
	return 0.0


static func foam(t: float) -> bool:
	return fposmod(t, PERIOD) >= PERIOD - FOAM_LEAD
