extends GutTest
## Review Focus 5: манифест покрывает всю еду, файлы на месте; без ключа игра собирается.

func _manifest() -> Array:
	var json := JSON.new()
	assert_eq(json.parse(FileAccess.get_file_as_string("res://tools/images/manifest.json")), OK)
	return json.data["images"]

func test_manifest_covers_all_food_and_files_exist() -> void:
	var files := {}
	for e in _manifest():
		files[e["file"]] = true
		assert_true(ResourceLoader.exists("res://" + e["file"]), "нет файла %s (make images)" % e["file"])
	for f in FoodCatalog.all():
		assert_true(files.has("assets/images/ui/food_%s.png" % f.id), "в манифесте нет иконки %s" % f.id)
		assert_not_null(f.icon(), "иконка %s загружается" % f.id)
	for extra in ["assets/images/ui/heart.png", "assets/images/title/title_bg.png", "assets/images/world/clouds.png"]:
		assert_true(files.has(extra), "в манифесте нет %s" % extra)

func test_icon_of_unknown_food_is_null_not_error() -> void:
	var f := FoodDef.new()
	f.id = &"nothing"
	assert_null(f.icon())
