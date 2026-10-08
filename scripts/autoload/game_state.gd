extends Node
## Состояние игрока: сердечки, еда в зубах, сытость, альбом, цель сессии (спек 3.2–3.6).
## Автозагрузка GameState. В тестах создаётся свежий экземпляр этого скрипта.

signal hearts_changed(hearts: int, max_hearts: int)
signal mouth_changed(items: Array)
signal satiety_changed(value: int)
signal album_changed(album: Dictionary)
signal food_eaten(items: Array)
signal cat_hit(spilled: Array)
signal cat_fainted()
signal goal_changed(done: int, target: int)
signal goal_completed(target: int)
signal yarn_changed(count: int)

const MAX_HEARTS := 3
const MOUTH_CAPACITY := 3
const GOAL_FIRST := 3
const GOAL_STEP := 2
const SATIETY_GATE := 10   # сытость, открывающая арку в кафе (план 3)
const YARN_PER_CARD := 3

var max_hearts := MAX_HEARTS
var hearts := MAX_HEARTS
var mouth_capacity := MOUTH_CAPACITY
var mouth: Array[FoodDef] = []
var satiety := 0
var album := {}          # id -> сколько раз съедено
var goal_target := GOAL_FIRST
var goal_done := 0       # новых карточек с начала текущей цели
var yarn := 0            # клубочки, валюта магазина


func reset() -> void:
	max_hearts = MAX_HEARTS
	hearts = MAX_HEARTS
	mouth_capacity = MOUTH_CAPACITY
	mouth = []
	satiety = 0
	album = {}
	goal_target = GOAL_FIRST
	goal_done = 0
	yarn = 0
	hearts_changed.emit(hearts, max_hearts)
	mouth_changed.emit(mouth)
	satiety_changed.emit(satiety)
	album_changed.emit(album)
	goal_changed.emit(goal_done, goal_target)
	yarn_changed.emit(yarn)


func mouth_full() -> bool:
	return mouth.size() >= mouth_capacity


func pick_up(food: FoodDef) -> bool:
	if mouth_full():
		return false
	mouth.append(food)
	mouth_changed.emit(mouth)
	return true


func eat_all() -> Array[FoodDef]:
	if mouth.is_empty():
		return []
	var eaten: Array[FoodDef] = mouth.duplicate()
	mouth = []
	for f in eaten:
		satiety += f.satiety()
		if not album.has(f.id):
			album[f.id] = 0
			goal_done += 1
			yarn += YARN_PER_CARD
		album[f.id] += 1
	hearts = mini(hearts + 1, max_hearts)
	yarn_changed.emit(yarn)
	mouth_changed.emit(mouth)
	satiety_changed.emit(satiety)
	album_changed.emit(album)
	hearts_changed.emit(hearts, max_hearts)
	food_eaten.emit(eaten)
	if goal_done >= goal_target:
		var finished := goal_target
		goal_target += GOAL_STEP
		goal_done = 0
		goal_completed.emit(finished)
	goal_changed.emit(goal_done, goal_target)
	return eaten


func spill() -> Array[FoodDef]:
	var spilled: Array[FoodDef] = mouth.duplicate()
	mouth = []
	mouth_changed.emit(mouth)
	return spilled


func take_hit() -> bool:
	var spilled := spill()
	hearts = maxi(hearts - 1, 0)
	hearts_changed.emit(hearts, max_hearts)
	cat_hit.emit(spilled)
	if hearts == 0:
		cat_fainted.emit()
		return true
	return false


func revive() -> void:
	hearts = max_hearts
	mouth = []
	hearts_changed.emit(hearts, max_hearts)
	mouth_changed.emit(mouth)


func album_count() -> int:
	return album.size()


func add_yarn(n: int) -> void:
	yarn += n
	yarn_changed.emit(yarn)


func spend_yarn(n: int) -> bool:
	if n > yarn:
		return false
	yarn -= n
	yarn_changed.emit(yarn)
	return true
