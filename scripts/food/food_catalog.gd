class_name FoodCatalog
extends RefCounted
## Загружает все FoodDef из data/food.

const DIR := "res://data/food"
static var _cache: Array[FoodDef] = []


static func all() -> Array[FoodDef]:
	if _cache.is_empty():
		var names := DirAccess.get_files_at(DIR)
		for n in names:
			if n.ends_with(".tres"):
				var res := load(DIR + "/" + n)
				if res is FoodDef:
					_cache.append(res)
		_cache.sort_custom(func(a: FoodDef, b: FoodDef) -> bool: return a.id < b.id)
	return _cache


static func by_tier(tier: int) -> Array[FoodDef]:
	var out: Array[FoodDef] = []
	for f in all():
		if f.tier == tier:
			out.append(f)
	return out


static func get_by_id(id: StringName) -> FoodDef:
	for f in all():
		if f.id == id:
			return f
	return null
