class_name ShopCatalog
extends RefCounted
## Загружает товары из data/shop.

const DIR := "res://data/shop"
static var _cache: Array[ShopItem] = []


static func all() -> Array[ShopItem]:
	if _cache.is_empty():
		for n in DirAccess.get_files_at(DIR):
			if n.ends_with(".tres"):
				var res := load(DIR + "/" + n)
				if res is ShopItem:
					_cache.append(res)
		_cache.sort_custom(func(a: ShopItem, b: ShopItem) -> bool: return a.order < b.order)
	return _cache


static func get_by_id(id: StringName) -> ShopItem:
	for it in all():
		if it.id == id:
			return it
	return null
