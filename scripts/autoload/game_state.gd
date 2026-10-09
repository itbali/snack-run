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
signal upgrade_bought(id: StringName)
signal skin_changed(id: StringName)

const MAX_HEARTS := 3
const MOUTH_CAPACITY := 3
const GOAL_FIRST := 3
const GOAL_STEP := 2
const SATIETY_GATE := 10   # сытость, открывающая арку в кафе (план 3)
const PARK_GATE := 25      # сытость, открывающая ворота в парк (этап 2)
const YARN_PER_CARD := 3
const SPEED_BONUS := 1.15
const STEALTH_BONUS := 0.7
const DEFAULT_SKIN := &"orange"

var max_hearts := MAX_HEARTS
var hearts := MAX_HEARTS
var mouth_capacity := MOUTH_CAPACITY
var mouth: Array[FoodDef] = []
var satiety := 0
var album := {}          # id -> сколько раз съедено
var goal_target := GOAL_FIRST
var goal_done := 0       # новых карточек с начала текущей цели
var yarn := 0            # клубочки, валюта магазина
var yarn_taken := {}     # ключ позиции собранного клубочка -> true (они не возвращаются после перезапуска)
var upgrades := {}       # id товара -> true
var skin: StringName = DEFAULT_SKIN
var speed_mult := 1.0
var stealth_mult := 1.0


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
	yarn_taken = {}
	upgrades = {}
	skin = DEFAULT_SKIN
	_apply_upgrades()
	hearts_changed.emit(hearts, max_hearts)
	mouth_changed.emit(mouth)
	satiety_changed.emit(satiety)
	album_changed.emit(album)
	goal_changed.emit(goal_done, goal_target)
	yarn_changed.emit(yarn)
	skin_changed.emit(skin)


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


func take_yarn(key: String) -> void:
	## Клубочек из раскладки: запоминаем ключ, чтобы он не вернулся после перезапуска.
	if key != "":
		yarn_taken[key] = true
	add_yarn(1)


func is_yarn_taken(key: String) -> bool:
	return yarn_taken.has(key)


func spend_yarn(n: int) -> bool:
	if n > yarn:
		return false
	yarn -= n
	yarn_changed.emit(yarn)
	return true


func owns(id: StringName) -> bool:
	return upgrades.has(id)


func can_buy(item: ShopItem) -> bool:
	if item == null or yarn < item.price:
		return false
	if item.requires != &"" and not owns(item.requires):
		return false
	if item.kind == "refill":
		return hearts < max_hearts
	return not owns(item.id)


func buy(item: ShopItem) -> bool:
	if not can_buy(item):
		return false
	spend_yarn(item.price)
	if item.kind == "refill":
		hearts = max_hearts
		hearts_changed.emit(hearts, max_hearts)
		return true
	upgrades[item.id] = true
	_apply_upgrades()
	if item.kind == "max_heart":
		hearts = max_hearts
		hearts_changed.emit(hearts, max_hearts)
	if item.kind == "skin":
		select_skin(item.skin_id)
	upgrade_bought.emit(item.id)
	return true


func _apply_upgrades() -> void:
	max_hearts = MAX_HEARTS
	mouth_capacity = MOUTH_CAPACITY
	speed_mult = 1.0
	stealth_mult = 1.0
	for it in ShopCatalog.all():
		if not owns(it.id):
			continue
		match it.kind:
			"max_heart":
				max_hearts = maxi(max_hearts, it.value)
			"mouth":
				mouth_capacity = maxi(mouth_capacity, it.value)
			"speed":
				speed_mult = SPEED_BONUS
			"quiet":
				stealth_mult = STEALTH_BONUS
	hearts = mini(hearts, max_hearts)


func owned_skins() -> Array[StringName]:
	var out: Array[StringName] = [DEFAULT_SKIN]
	for it in ShopCatalog.all():
		if it.kind == "skin" and owns(it.id):
			out.append(it.skin_id)
	return out


func select_skin(id: StringName) -> bool:
	if not owned_skins().has(id):
		return false
	skin = id
	skin_changed.emit(skin)
	return true


func to_dict() -> Dictionary:
	var album_out := {}
	for k in album:
		album_out[String(k)] = album[k]
	var upgrades_out := {}
	for k in upgrades:
		upgrades_out[String(k)] = true
	return {
		"version": 1,
		"album": album_out,
		"satiety": satiety,
		"yarn": yarn,
		"yarn_taken": yarn_taken.keys(),
		"upgrades": upgrades_out,
		"skin": String(skin),
		"goal_target": goal_target,
		"goal_done": goal_done,
	}


func from_dict(d: Dictionary) -> void:
	reset()
	if d.get("album") is Dictionary:
		for k in d["album"]:
			if d["album"][k] is float or d["album"][k] is int:
				album[StringName(k)] = int(d["album"][k])
	if d.get("satiety") is float or d.get("satiety") is int:
		satiety = int(d["satiety"])
	if d.get("yarn") is float or d.get("yarn") is int:
		yarn = int(d["yarn"])
	if d.get("yarn_taken") is Array:
		for k in d["yarn_taken"]:
			if k is String:
				yarn_taken[k] = true
	if d.get("upgrades") is Dictionary:
		for k in d["upgrades"]:
			if ShopCatalog.get_by_id(StringName(k)) != null:
				upgrades[StringName(k)] = true
	_apply_upgrades()
	hearts = max_hearts
	if d.get("skin") is String and owned_skins().has(StringName(d["skin"])):
		skin = StringName(d["skin"])
	if d.get("goal_target") is float or d.get("goal_target") is int:
		goal_target = maxi(int(d["goal_target"]), GOAL_FIRST)
	if d.get("goal_done") is float or d.get("goal_done") is int:
		goal_done = maxi(int(d["goal_done"]), 0)
	hearts_changed.emit(hearts, max_hearts)
	mouth_changed.emit(mouth)
	satiety_changed.emit(satiety)
	album_changed.emit(album)
	yarn_changed.emit(yarn)
	skin_changed.emit(skin)
	goal_changed.emit(goal_done, goal_target)
