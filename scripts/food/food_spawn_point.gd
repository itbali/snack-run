class_name FoodSpawnPoint
extends Node3D
## Точка спавна еды: допустимые редкости, взвешенный выбор, респавн 30–90 с.

signal spawned(pickup: FoodPickup)

const PickupScene := preload("res://scenes/food/food_pickup.tscn")

@export var allowed: Array = [Rarity.Tier.COMMON]
@export var respawn_min := 30.0
@export var respawn_max := 90.0
var rng := RandomNumberGenerator.new()
var current: FoodPickup


func _ready() -> void:
	rng.randomize()
	spawn_now()


func pick_def() -> FoodDef:
	var tier := Rarity.pick_weighted(allowed, rng)
	var pool := FoodCatalog.by_tier(tier)
	if pool.is_empty():
		pool = FoodCatalog.all()
	return pool[rng.randi_range(0, pool.size() - 1)]


func spawn_now() -> FoodPickup:
	var p := PickupScene.instantiate() as FoodPickup
	p.setup(pick_def())
	add_child(p)
	p.picked.connect(_on_picked)
	current = p
	spawned.emit(p)
	return p


func _on_picked(_food: FoodDef, _pickup: FoodPickup) -> void:
	current = null
	var delay := rng.randf_range(respawn_min, respawn_max)
	get_tree().create_timer(delay).timeout.connect(spawn_now)
