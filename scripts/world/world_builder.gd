class_name WorldBuilder
extends Node3D
## Строит район из data/layout/*.json: пропсы (с коллизией или без — solid), укрытия, точки спавна,
## опасности, дорога, декали (квады с текстурами из сгенерированных картинок).

const MODELS_DIR := "res://assets/models"
const HAZARD_SCENES := {
	"dog": "res://scenes/hazards/dog.tscn",
	"wasp": "res://scenes/hazards/wasp.tscn",
	"cyclist": "res://scenes/hazards/cyclist.tscn",
	"sprinkler": "res://scenes/hazards/sprinkler.tscn",
	"pigeons": "res://scenes/hazards/pigeon_flock.tscn",
	"gardener": "res://scenes/hazards/gardener.tscn",
	"kid": "res://scenes/hazards/kid.tscn",
	"guard": "res://scenes/hazards/guard.tscn",
}
const HideoutScene := preload("res://scenes/hideouts/hideout.tscn")
const SpawnScene := preload("res://scenes/food/food_spawn_point.tscn")
const YarnScene := preload("res://scenes/food/yarn_pickup.tscn")
const GateScene := preload("res://scenes/world/gate.tscn")
const YarnShopScene := preload("res://scenes/world/yarn_shop.tscn")

@export var layout_path := ""
@export var terrain_path: NodePath   # пусто — плоский мир, y раскладки абсолютные
var terrain: Terrain
var props_built := 0
var hideouts_built := 0
var spawns_built := 0
var hazards_built := 0
var yarn_built := 0
var gates_built := 0
var shop_built := 0
var water_built := 0
var decals_built := 0


func _ready() -> void:
	if terrain == null and not terrain_path.is_empty():
		terrain = get_node_or_null(terrain_path) as Terrain
	if terrain:
		terrain.ensure_loaded()   # рельеф мог ещё не пройти _ready (порядок соседей)
	if layout_path != "":
		build(load_layout(layout_path))


static func load_layout(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	assert(parsed is Dictionary, "не удалось разобрать " + path)
	return parsed


## Модули террас (tools/blender/terrace_kit.py): подъём по −Z модели от начала координат.
const KIT_STEP_RISE := 0.2
const KIT_STEP_TREAD := 0.3
const KIT_RAMP_DEG := 25.0
const KIT_WIDTH := 1.6
## Мелкие пропсы гаснут дальше SMALL_RANGE (спек «Масштаб ×3», раздел 5).
const SMALL_PROPS := ["grass", "bush", "box", "bag", "chair", "bin", "puddle", "flowerbed", "ivy"]
const SMALL_RANGE := 40.0


static func kit_colliders(model: String) -> Array:
	## Наклонный коллайдер лестницы террасы или пандуса по имени модели (terrace_stairsN, rampN); иначе [].
	var h := 0.0
	var run := 0.0
	if model.begins_with("terrace_stairs") and model.trim_prefix("terrace_stairs").is_valid_int():
		h = float(model.trim_prefix("terrace_stairs"))
		run = roundf(h / KIT_STEP_RISE) * KIT_STEP_TREAD
	elif model.begins_with("ramp") and model.trim_prefix("ramp").is_valid_int():
		h = float(model.trim_prefix("ramp"))
		run = h / tan(deg_to_rad(KIT_RAMP_DEG))
	else:
		return []
	var ang := rad_to_deg(atan2(h, run))
	var length := sqrt(h * h + run * run)
	# Тонкая плита по линии подъёма; верх плиты — поверхность пандуса, у лестницы — линия через середины
	# проступей (сдвиг на полступени к началу): кот не тонет в ступенях и не висит над ними больше чем на полподступенка.
	var th := 0.1
	var shift := KIT_STEP_TREAD / 2.0 if model.begins_with("terrace_stairs") else 0.0
	var n := Vector3(0, cos(deg_to_rad(ang)), sin(deg_to_rad(ang)))
	var center := Vector3(0, h / 2.0, -run / 2.0 + shift) - n * (th / 2.0)
	return [{"size": [KIT_WIDTH, th, length], "offset": [center.x, center.y, center.z], "rot": [ang, 0, 0]}]


func _add_at(parent: Node3D, node: Node3D, pos: Vector3, rot_y_deg: float) -> void:
	## Ставит узел в мировую позицию ДО add_child: тела не появляются на кадр в начале координат.
	node.transform = parent.global_transform.affine_inverse() * Transform3D(Basis(Vector3.UP, deg_to_rad(rot_y_deg)), pos)
	parent.add_child(node)


func _place(item: Dictionary) -> Vector3:
	## Позиция из раскладки: на рельефе y — смещение над поверхностью; "snap": false — абсолютная высота.
	var v := _v3(item["pos"])
	if terrain and bool(item.get("snap", true)):
		v.y += terrain.height_at(v.x, v.z)
	return v


static func _v3(arr: Array) -> Vector3:
	return Vector3(arr[0], arr[1], arr[2])


func _container(name: String) -> Node3D:
	var n := get_node_or_null(name) as Node3D
	if n == null:
		n = Node3D.new()
		n.name = name
		add_child(n)
	return n


func build(data: Dictionary) -> void:
	for p in data.get("props", []):
		_build_prop(p)
	for d in data.get("decals", []):
		_build_decal(d)
	for h in data.get("hideouts", []):
		_build_hideout(h)
	for s in data.get("spawn_points", []):
		_build_spawn(s)
	for y in data.get("yarn", []):
		_build_yarn(y)
	_build_road(data.get("road", {}))
	for g in data.get("gates", []):
		_build_gate(g)
	if data.has("shop"):
		_build_shop(data["shop"])
	for hz in data.get("hazards", []):
		_build_hazard(hz)
	for w in data.get("water_zones", []):
		_build_water(w)
	for m in data.get("shore", []):
		_build_shore(m)


func _build_water(w: Dictionary) -> void:
	## Зона воды (план 12): pos — абсолютный, y — уровень поверхности; size — ширина, глубина зоны, длина.
	var node := Water.new()
	node.size = _v3(w.get("size", [10, 3, 10]))
	_add_at(_container("Water"), node, _v3(w["pos"]), float(w.get("rot", 0)))


func _build_shore(m: Dictionary) -> void:
	## Маркер берега: сюда возвращается утонувший кот (ближайший).
	var node := Marker3D.new()
	node.add_to_group("shore")
	_add_at(_container("Shore"), node, _place(m) + Vector3(0, 0.1, 0), 0.0)


func _build_prop(p: Dictionary) -> void:
	var model_path := "%s/%s.glb" % [MODELS_DIR, p["model"]]
	if not ResourceLoader.exists(model_path):
		push_warning("нет модели " + model_path)
		return
	var body := StaticBody3D.new()
	body.name = "%s_%d" % [p["model"], props_built]
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	var model := (load(model_path) as PackedScene).instantiate() as Node3D
	model.name = "Model"
	body.add_child(model)
	var solid := bool(p.get("solid", true))
	var colliders: Array = p.get("colliders", kit_colliders(String(p["model"]))) if solid else []
	if colliders.is_empty() and solid:
		var aabb := _model_aabb(model)
		colliders = [{"size": [aabb.size.x, aabb.size.y, aabb.size.z],
			"offset": [aabb.position.x + aabb.size.x / 2, aabb.position.y + aabb.size.y / 2, aabb.position.z + aabb.size.z / 2]}]
	for i in colliders.size():
		var c: Dictionary = colliders[i]
		var shape := CollisionShape3D.new()
		shape.name = "Shape%d" % i
		var box := BoxShape3D.new()
		box.size = _v3(c["size"])
		shape.shape = box
		shape.position = _v3(c.get("offset", [0, 0, 0]))
		shape.rotation_degrees = _v3(c.get("rot", [0, 0, 0]))   # наклонные коллайдеры лестниц и пандусов
		body.add_child(shape)
	# Позиция до add_child: иначе первый физический кадр тело стоит в начале координат и выталкивает
	# кота, появившегося там, сквозь тонкую карту высот (план 10).
	var props := _container("Props")
	body.transform = props.global_transform.affine_inverse() * Transform3D(Basis(Vector3.UP, deg_to_rad(float(p.get("rot", 0)))), _place(p))
	props.add_child(body)
	Toon.apply(model, Toon.OUTLINE_FOOD if p.get("outline", false) else Toon.OUTLINE_NONE)
	if String(p["model"]) in SMALL_PROPS:
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).visibility_range_end = SMALL_RANGE
			(mi as MeshInstance3D).visibility_range_end_margin = 4.0
			(mi as MeshInstance3D).visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	if p["model"] == "lamp":
		body.add_child(_night_light())
	for mi in model.find_children("wall_glass*", "MeshInstance3D", true, false):
		mi.add_to_group("night_windows")   # ночью окна светятся тёплым (DayNight)
	for mi in model.find_children("lamp_head", "MeshInstance3D", true, false):
		mi.add_to_group("night_windows")   # и плафоны фонарей
	if not solid:
		for mi in model.find_children("*", "MeshInstance3D", true, false):   # листья и трава видны с обеих сторон
			if (mi as MeshInstance3D).mesh == null:
				continue
			for i in (mi as MeshInstance3D).mesh.get_surface_count():
				var m := (mi as MeshInstance3D).get_surface_override_material(i) as StandardMaterial3D
				if m:
					m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if bool(p.get("water", false)):
		_make_water(model)
		water_built += 1
	props_built += 1


func _night_light() -> SpotLight3D:
	## Свет фонаря: горит с заката до рассвета, переключает DayNight по группе night_lights.
	var l := SpotLight3D.new()
	l.name = "NightLight"
	l.add_to_group("night_lights")
	l.position = Vector3(0, 2.45, 0)
	l.rotation_degrees = Vector3(-90, 0, 0)
	l.spot_angle = 50.0
	l.spot_range = 7.0
	l.light_color = Color("#FFD9A0")
	l.light_energy = 4.0
	l.shadow_enabled = false
	l.distance_fade_enabled = true   # на большом дворе дальние фонари гаснут (спек «Масштаб», раздел 5)
	l.distance_fade_begin = 35.0
	l.distance_fade_length = 5.0
	l.visible = false
	return l


func _make_water(model: Node3D) -> void:
	## Лужа/вода фонтана: зеркальный материал, отражает небо через SSR окружения (спек 2.8).
	## Если у модели есть меши с «water» в имени — зеркальными становятся только они (чаша фонтана остаётся тун).
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	var water := meshes.filter(func(m): return String(m.name).contains("water"))
	for mi in (water if not water.is_empty() else meshes):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null:
			continue
		for i in m3.mesh.get_surface_count():
			var m := m3.get_surface_override_material(i) as StandardMaterial3D
			if m == null:
				continue
			m.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
			m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
			m.roughness = 0.05
			m.metallic = 0.0
			m.metallic_specular = 1.0


func _build_decal(d: Dictionary) -> void:
	## Декаль: квад с текстурой из сгенерированной картинки; на асфальте плашмя, на стене вертикально.
	var path := "res://" + String(d["texture"])
	if not ResourceLoader.exists(path):
		push_warning("нет текстуры декали " + path)
		return
	var mi := MeshInstance3D.new()
	mi.name = "decal_%d" % decals_built
	var quad := QuadMesh.new()
	var size: Array = d.get("size", [1.0, 1.0])
	quad.size = Vector2(size[0], size[1])
	mi.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(path)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.9
	mi.set_surface_override_material(0, mat)
	_container("Decals").add_child(mi)
	var pos := _place(d)
	var wall := bool(d.get("wall", false))
	mi.global_position = pos + (Vector3.ZERO if wall else Vector3(0, 0.01, 0))
	mi.rotation_degrees = Vector3(0.0, float(d.get("rot", 0)), 0.0) if wall else Vector3(-90.0, float(d.get("rot", 0)), 0.0)
	decals_built += 1


func _model_aabb(model: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = (mi as MeshInstance3D).get_aabb()
		var xf: Transform3D = _local_xf(mi, model)
		box = xf * box
		result = box if first else result.merge(box)
		first = false
	return result


func _local_xf(node: Node3D, root: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var n := node
	while n != null and n != root:
		xf = n.transform * xf
		n = n.get_parent() as Node3D
	return xf


func _build_hideout(h: Dictionary) -> void:
	var node := HideoutScene.instantiate() as Hideout
	node.kind = StringName(h.get("kind", "box"))
	node.size = _v3(h.get("size", [0.6, 0.4, 0.5]))
	_add_at(_container("Hideouts"), node, _place(h), float(h.get("rot", 0)))
	hideouts_built += 1


func _build_spawn(s: Dictionary) -> void:
	var node := SpawnScene.instantiate() as FoodSpawnPoint
	var allowed: Array = []
	for t in s.get("allowed", [0]):
		allowed.append(int(t))   # JSON даёт float, ключи словарей Rarity — int
	node.allowed = allowed
	node.foods = s.get("foods", [])
	_add_at(_container("Spawns"), node, _place(s), 0.0)
	spawns_built += 1


func _build_road(road: Dictionary) -> void:
	var path := Path3D.new()
	path.name = "Road"
	var curve := Curve3D.new()
	for pt in road.get("points", []):
		var v := _v3(pt)
		if terrain:
			v.y += terrain.height_at(v.x, v.z)
		curve.add_point(v)
	path.curve = curve
	add_child(path)


func _build_hazard(hz: Dictionary) -> void:
	var type_name: String = hz.get("type", "")
	var scene_path: String = HAZARD_SCENES.get(type_name, "")
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		push_warning("опасность пропущена: " + type_name)
		return
	var node := (load(scene_path) as PackedScene).instantiate() as Node3D
	node.name = "%s_%d" % [type_name, hazards_built]
	if node.has_method("configure"):
		node.call("configure", hz, self)
	_add_at(_container("Hazards"), node, _place(hz), float(hz.get("rot", 0)))
	hazards_built += 1


func _build_yarn(y: Dictionary) -> void:
	var node := YarnScene.instantiate() as YarnPickup
	var raw := _v3(y["pos"])   # ключ — по раскладке, а не по высоте рельефа: сохранения не ломаются при правке рельефа
	node.key = "%.1f,%.1f,%.1f" % [raw.x, raw.y, raw.z]
	_add_at(_container("Yarn"), node, _place(y), 0.0)
	yarn_built += 1


func _build_gate(g: Dictionary) -> void:
	var node := GateScene.instantiate() as Gate
	node.name = "gate_%d" % gates_built
	node.satiety_required = int(g.get("satiety", GameState.SATIETY_GATE))
	node.label = String(g.get("label", node.label))
	node.size = _v3(g.get("size", [2.4, 2.6, 0.3]))
	_add_at(_container("Gates"), node, _place(g), float(g.get("rot", 0)))
	gates_built += 1


func _build_shop(s: Dictionary) -> void:
	var node := YarnShopScene.instantiate() as YarnShop
	node.name = "YarnShop"
	_add_at(self, node, _place(s), float(s.get("rot", 0)))
	shop_built += 1
