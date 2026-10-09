class_name DayCycle
extends RefCounted
## Чистая логика смены суток (спек этапа 2, раздел 2): фазы по времени, ключевые кадры света, фонари.
## Цикл 300 с: день [0,150), вечер [150,180), ночь [180,270), утро [270,300).

const CYCLE := 300.0
const PHASES := [[0.0, &"day"], [150.0, &"evening"], [180.0, &"night"], [270.0, &"morning"]]
const LAMPS_FROM := 165.0
const LAMPS_TO := 285.0

const DAY := {"sun_pitch": -65.0, "sun_color": Color("#FFF1D6"), "sun_energy": 1.2, "fill": 0.25, "ambient": 0.6,
	"sky_top": Color("#4A9BE0"), "sky_horizon": Color("#CFE6F8"), "clouds": Color("#FFFFFF")}
const DUSK := {"sun_pitch": -10.0, "sun_color": Color("#FFB36B"), "sun_energy": 0.8, "fill": 0.2, "ambient": 0.45,
	"sky_top": Color("#5A6FB0"), "sky_horizon": Color("#FFB98A"), "clouds": Color("#FFD2B0")}
const NIGHT := {"sun_pitch": -50.0, "sun_color": Color("#9FB8FF"), "sun_energy": 0.22, "fill": 0.08, "ambient": 0.18,
	"sky_top": Color("#0B1633"), "sky_horizon": Color("#1E2F5C"), "clouds": Color("#3A4670")}
## (время, состояние); рассвет повторяет закат
const KEYS := [[0.0, DAY], [150.0, DAY], [165.0, DUSK], [185.0, NIGHT], [270.0, NIGHT], [285.0, DUSK], [300.0, DAY]]


static func wrap_time(t: float) -> float:
	return fposmod(t, CYCLE)


static func phase_at(t: float) -> StringName:
	var w := wrap_time(t)
	var out: StringName = &"day"
	for p in PHASES:
		if w >= p[0]:
			out = p[1]
	return out


static func phase_progress(t: float) -> float:
	## Доля прошедшей фазы, 0..1 (для полоски «до следующей фазы» в HUD).
	var w := wrap_time(t)
	for i in PHASES.size():
		var start: float = PHASES[i][0]
		var end: float = PHASES[i + 1][0] if i + 1 < PHASES.size() else CYCLE
		if w >= start and w < end:
			return (w - start) / (end - start)
	return 0.0


static func light_at(t: float) -> Dictionary:
	var w := wrap_time(t)
	for i in KEYS.size() - 1:
		var a: Array = KEYS[i]
		var b: Array = KEYS[i + 1]
		if w >= a[0] and w <= b[0]:
			var k: float = 0.0 if b[0] == a[0] else (w - a[0]) / (b[0] - a[0])
			k = smoothstep(0.0, 1.0, k)
			var out := {}
			for key in (a[1] as Dictionary):
				var va = a[1][key]
				var vb = b[1][key]
				out[key] = (va as Color).lerp(vb, k) if va is Color else lerpf(va, vb, k)
			return out
	return DAY.duplicate()


static func lamps_on(t: float) -> bool:
	var w := wrap_time(t)
	return w >= LAMPS_FROM and w < LAMPS_TO
