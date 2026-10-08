class_name SpillSpawner
extends Node3D
## Раскладывает выбитую из зубов еду вокруг кота (спек 3.2: 1–2 м, 5 с).

const PickupScene := preload("res://scenes/food/food_pickup.tscn")
const SPILL_LIFETIME := 5.0
const MIN_R := 1.0
const MAX_R := 2.0

var rng := RandomNumberGenerator.new()


func spill_around(pos: Vector3, foods: Array) -> Array:
	var out := []
	for f in foods:
		var p := PickupScene.instantiate() as FoodPickup
		p.setup(f, true, SPILL_LIFETIME)
		p.add_to_group("spilled_food")
		add_child(p)
		var ang := rng.randf_range(0.0, TAU)
		var r := rng.randf_range(MIN_R, MAX_R)
		p.global_position = Vector3(pos.x + cos(ang) * r, 0.0, pos.z + sin(ang) * r)
		out.append(p)
	return out
