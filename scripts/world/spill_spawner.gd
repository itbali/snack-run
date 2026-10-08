class_name SpillSpawner
extends Node3D
## Раскладывает выбитую из зубов еду вокруг кота (спек 3.2: 1–2 м, 5 с). Каждая порция кладётся
## на поверхность под своей точкой (луч вниз по слою WORLD): со стола и балкона падает на землю рядом.

const PickupScene := preload("res://scenes/food/food_pickup.tscn")
const SPILL_LIFETIME := 5.0
const MIN_R := 1.0
const MAX_R := 2.0
const RAY_UP := 0.5     # луч стартует чуть выше точки кота: он может стоять на краю стола
const RAY_DOWN := 10.0

var rng := RandomNumberGenerator.new()


func spill_around(pos: Vector3, foods: Array) -> Array:
	var out := []
	var space := get_world_3d().direct_space_state
	for f in foods:
		var p := PickupScene.instantiate() as FoodPickup
		p.setup(f, true, SPILL_LIFETIME)
		p.add_to_group("spilled_food")
		add_child(p)
		var ang := rng.randf_range(0.0, TAU)
		var r := rng.randf_range(MIN_R, MAX_R)
		var x := pos.x + cos(ang) * r
		var z := pos.z + sin(ang) * r
		p.global_position = Vector3(x, surface_y(space, Vector3(x, pos.y + RAY_UP, z)), z)
		out.append(p)
	return out


static func surface_y(space: PhysicsDirectSpaceState3D, from: Vector3) -> float:
	## Высота первой поверхности мира под точкой; без попадания — уровень земли.
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3(0, -RAY_DOWN, 0), Layers.WORLD)
	var hit := space.intersect_ray(q)
	return (hit["position"] as Vector3).y if not hit.is_empty() else 0.0
