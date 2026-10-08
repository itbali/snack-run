class_name SkinCatalog
extends RefCounted

const DIR := "res://data/skins"
static var _cache: Array[CatSkin] = []


static func all() -> Array[CatSkin]:
	if _cache.is_empty():
		for n in DirAccess.get_files_at(DIR):
			if n.ends_with(".tres"):
				var res := load(DIR + "/" + n)
				if res is CatSkin:
					_cache.append(res)
		_cache.sort_custom(func(a: CatSkin, b: CatSkin) -> bool: return a.id < b.id)
	return _cache


static func get_by_id(id: StringName) -> CatSkin:
	for s in all():
		if s.id == id:
			return s
	return null
