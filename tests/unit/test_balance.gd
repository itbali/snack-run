extends GutTest
## Плейтест баланса по спеку 3.3 числами, не ощущениями: жадный маршрут по точкам спавна двора.
## Шаг 2 м/с (без бега — нижняя оценка), 0,6 с на подбор, после каждых трёх подборов — к ближайшему
## укрытию и 2 с на съедание. Сытость точки — матожидание по весам редкостей.

const WALK := CatMotion.WALK_SPEED
const PICK := 0.6
const EAT := 2.0
const GATE_Z := 10.5   # арка; дальше кафе, до открытия недоступно


static func expected_satiety(allowed: Array) -> float:
	var total := 0.0
	var acc := 0.0
	for t in allowed:
		total += Rarity.WEIGHTS[int(t)]
		acc += Rarity.WEIGHTS[int(t)] * Rarity.SATIETY[int(t)]
	return acc / total if total > 0.0 else 0.0


static func estimate_seconds(layout: Dictionary, target: int) -> float:
	var points := []
	for s in layout["spawn_points"]:
		var p: Vector3 = WorldBuilder._v3(s["pos"])
		if p.z < GATE_Z:
			points.append({"pos": p, "sat": expected_satiety(s.get("allowed", [0]))})
	var hideouts := []
	for h in layout["hideouts"]:
		hideouts.append(WorldBuilder._v3(h["pos"]))
	var pos := Vector3.ZERO   # стартовый маркер Spawn
	var time := 0.0
	var satiety := 0.0
	var carried := 0
	var visited := {}
	while satiety < target and visited.size() < points.size():
		var best := -1
		var best_d := INF
		for i in points.size():
			if visited.has(i):
				continue
			var d: float = pos.distance_to(points[i]["pos"])
			if d < best_d:
				best_d = d
				best = i
		visited[best] = true
		pos = points[best]["pos"]
		time += best_d / WALK + PICK
		carried += 1
		satiety += points[best]["sat"]
		if carried >= GameState.MOUTH_CAPACITY:
			var hd := INF
			var hp := pos
			for h in hideouts:
				if pos.distance_to(h) < hd:
					hd = pos.distance_to(h)
					hp = h
			time += hd / WALK + EAT
			pos = hp
			carried = 0
	if carried > 0:
		time += EAT
	return time if satiety >= target else INF


func test_yard_has_enough_food_for_the_gate() -> void:
	var layout := WorldBuilder.load_layout("res://data/layout/yard.json")
	var total := 0.0
	for s in layout["spawn_points"]:
		if WorldBuilder._v3(s["pos"]).z < GATE_Z:
			total += expected_satiety(s.get("allowed", [0]))
	assert_gte(total, float(GameState.SATIETY_GATE), "за один обход двора (без респавна) сытости хватает на арку")


func test_yard_opens_cafe_within_three_minutes() -> void:
	var layout := WorldBuilder.load_layout("res://data/layout/yard.json")
	var t := estimate_seconds(layout, GameState.SATIETY_GATE)
	gut.p("оценка времени до арки: %.0f с при пороге %d" % [t, GameState.SATIETY_GATE])
	assert_lt(t, 180.0, "спек 3.3: 2–3 минуты до арки; если дольше — порог 6")
