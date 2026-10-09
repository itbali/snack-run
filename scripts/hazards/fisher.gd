class_name Fisher
extends Node3D
## Рыбак на причале (спек порта, раздел 4): смотрит на воду 10–20 с → клюёт (1 с) → вытягивает (2 с) → золотая рыбка в ведре
## → 3 с смотрит в ведро (кот ближе 1 м к ведру в момент поворота — удар) → снова к воде. Ночью рыбака нет.

const BITE := 1.0
const PULL := 2.0
const LOOK := 3.0
const SHOO_DIST := 1.0


static func next_phase(phase: StringName, t: float, watch: float) -> StringName:
	match phase:
		&"watch":
			return &"bite" if t >= watch else &"watch"
		&"bite":
			return &"pull" if t >= BITE else &"bite"
		&"pull":
			return &"look" if t >= PULL else &"pull"
		&"look":
			return &"watch" if t >= LOOK else &"look"
	return phase


static func shoos(dist_to_bucket: float, hidden: bool, safe: bool) -> bool:
	return dist_to_bucket < SHOO_DIST and not hidden and not safe

const PickupScene := preload("res://scenes/food/food_pickup.tscn")
const CAST := 3.5   # поплавок перед рыбаком, м

var phase: StringName = &"watch"
var watch_range := Vector2(10.0, 20.0)
var watch := 15.0
var water_level := -2.3
var fish: FoodPickup
var _t := 0.0
var _rng := RandomNumberGenerator.new()

@onready var _model: Node3D = $Model
@onready var _bucket: Node3D = $Bucket
@onready var _float: Node3D = $Float
@onready var _anim: AnimationPlayer = $Model.find_child("AnimationPlayer", true, false)


func configure(hz: Dictionary, _builder: Node3D) -> void:
	var w: Array = hz.get("watch", [10.0, 20.0])
	watch_range = Vector2(float(w[0]), float(w[1]))
	water_level = float(hz.get("water", water_level))


func _ready() -> void:
	add_to_group("hazards")
	_rng.randomize()
	Toon.apply(_model, Toon.OUTLINE_CHARACTER, true)
	Toon.apply(_bucket, Toon.OUTLINE_FOOD)
	for clip in ["idle", "work"]:
		if _anim and _anim.has_animation(clip):
			_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	watch = _rng.randf_range(watch_range.x, watch_range.y)
	_play(&"idle")


func _play(clip: StringName) -> void:
	if _anim and _anim.has_animation(clip) and _anim.current_animation != clip:
		_anim.play(clip, 0.2)


func _physics_process(delta: float) -> void:
	var present := not DayNight.is_night(get_tree())   # днём и вечером; ночью рыбака нет
	if visible != present:
		visible = present
		if not present and is_instance_valid(fish):
			fish.queue_free()   # рыбка уходит вместе с рыбаком
	if not present:
		return
	_t += delta
	var fl := to_global(Vector3(0, 0, -CAST))
	_float.global_position = Vector3(fl.x, water_level + (sin(_t * 30.0) * 0.06 if phase == &"bite" else sin(_t * 2.0) * 0.015), fl.z)
	var next := next_phase(phase, _t, watch)
	if next == phase:
		return
	phase = next
	_t = 0.0
	match phase:
		&"bite":
			Sfx.play(&"splash")
		&"pull":
			_play(&"work")
		&"look":
			_land_fish()
			_model.rotation.y = PI   # повернулся к ведру
			_play(&"idle")
			_check_cat()
		&"watch":
			_model.rotation.y = 0.0
			watch = _rng.randf_range(watch_range.x, watch_range.y)


func _land_fish() -> void:
	## Рыба падает в ведро — золотая рыбка (только так, спек 5); в ведре не больше одной.
	if is_instance_valid(fish):
		return
	fish = PickupScene.instantiate() as FoodPickup
	fish.setup(FoodCatalog.get_by_id(&"golden_fish"))
	fish.grace = LOOK   # пока рыбак смотрит в ведро, рыбку не взять (ревью плана 15); потом — обычный подбор
	var parent := get_parent() as Node3D
	var at := _bucket.global_position + Vector3(0, 0.12, 0)   # в ведре: зона подбора с земли достаёт
	fish.position = parent.global_transform.affine_inverse() * at if parent else at
	get_parent().add_child(fish)


func _check_cat() -> void:
	## Повернулся к ведру: кот ближе 1 м — шугает (удар, еда рассыпается).
	var c := get_tree().get_first_node_in_group("cat") as Node3D
	if c == null or not c.has_method("take_hit"):
		return
	var d := c.global_position - _bucket.global_position
	if shoos(Vector2(d.x, d.z).length(), bool(c.get("hidden")), bool(c.get("in_safe_zone"))):
		c.call("take_hit", global_position)
