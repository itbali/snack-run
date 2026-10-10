class_name Hideout
extends Area3D
## Объём укрытия (коробка, под машиной, под лавкой, куст). Кот прячется только внутри.
## План 19 (просьба владельца): зона чуть больше данных; с едой в зубах укрытие подсвечено кольцом;
## спрятавшийся кот исчезает, а в укрытии видны его глаза — моргают, смотрят на камеру, жмурятся, когда он ест.

const MARGIN := 0.3          # к размеру из раскладки с каждой стороны — проще попасть
const RING_RANGE := 14.0     # кольцо видно в этом радиусе от кота
const EYE_GAP := 0.085

@export var kind: StringName = &"box"
@export var size := Vector3(0.6, 0.4, 0.5)
var cat_inside := false
var _eyes: Node3D
var _ring: Node3D
var _t := 0.0
var _next_blink := 2.5
var _squint_left := 0.0

@onready var _shape: CollisionShape3D = $Collision


func _ready() -> void:
	add_to_group("hideouts")
	collision_layer = Layers.AREA
	collision_mask = Layers.CAT
	monitorable = false
	var box := BoxShape3D.new()
	box.size = size + Vector3(MARGIN * 2.0, 0.0, MARGIN * 2.0)   # шире только по земле: на крышке и сиденье не прячутся
	_shape.shape = box
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	_ring = _make_ring()
	_eyes = _make_eyes()


func outline_size() -> Vector2:
	## Рамка подсветки — ровно по зоне укрытия (ревью плана 19: круг обещал больше, чем зона).
	return Vector2(size.x + MARGIN * 2.0, size.z + MARGIN * 2.0)


func _make_ring() -> Node3D:
	var root := Node3D.new()
	root.name = "Ring"
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.98, 0.75, 0.2, 0.8)
	m.emission_enabled = true
	m.emission = Color("#FABE32")
	m.emission_energy_multiplier = 1.5
	var o := outline_size()
	var w := 0.06
	for spec in [[Vector3(o.x, 0.02, w), Vector3(0, 0, -o.y / 2)], [Vector3(o.x, 0.02, w), Vector3(0, 0, o.y / 2)],
			[Vector3(w, 0.02, o.y), Vector3(-o.x / 2, 0, 0)], [Vector3(w, 0.02, o.y), Vector3(o.x / 2, 0, 0)]]:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = spec[0]
		mi.mesh = bm
		mi.position = spec[1]
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	root.position.y = -size.y * 0.5 + 0.03
	root.visible = false
	add_child(root)
	return root


func _make_eyes() -> Node3D:
	var root := Node3D.new()
	root.name = "Eyes"
	root.top_level = true
	root.visible = false
	var white := StandardMaterial3D.new()
	white.albedo_color = Color("#F4F1E8")
	white.emission_enabled = true   # видно и в тени под машиной, ночью светятся
	white.emission = Color("#FFF6D8")
	white.emission_energy_multiplier = 0.8
	var iris := StandardMaterial3D.new()
	iris.albedo_color = Color("#6FA04A")   # радужка как у кота (палитра eye_green)
	iris.emission_enabled = true
	iris.emission = Color("#6FA04A")
	iris.emission_energy_multiplier = 0.6
	var pupil := StandardMaterial3D.new()
	pupil.albedo_color = Color("#394151")
	pupil.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for side in [-1.0, 1.0]:
		var e := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.06
		s.height = 0.09
		e.mesh = s
		e.material_override = white
		e.position = Vector3(side * EYE_GAP, 0, 0)
		e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(e)
		var ir := MeshInstance3D.new()
		var irs := SphereMesh.new()
		irs.radius = 0.036
		irs.height = 0.05
		ir.mesh = irs
		ir.material_override = iris
		ir.position = Vector3(side * EYE_GAP, 0, -0.042)
		ir.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(ir)
		var p := MeshInstance3D.new()
		var ps := SphereMesh.new()
		ps.radius = 0.02
		ps.height = 0.05
		p.mesh = ps
		p.material_override = pupil
		p.scale = Vector3(0.5, 1.2, 0.5)   # вертикальный кошачий зрачок
		p.position = Vector3(side * EYE_GAP, 0, -0.062)
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(p)
	add_child(root)
	return root


func show_eyes(on: bool) -> void:
	_eyes.visible = on
	_eyes.scale = Vector3.ONE
	if on:
		_place_eyes()


func squint(seconds := 0.9) -> void:
	_squint_left = seconds   # довольно жмурится, пока ест


func _place_eyes() -> void:
	## Глаза выглядывают из укрытия со стороны камеры и смотрят на неё.
	var cam := get_viewport().get_camera_3d()
	var center := global_position + Vector3(0, -size.y * 0.5 + 0.18, 0)
	if cam == null:
		_eyes.global_position = center
		return
	var to := cam.global_position - center
	to.y = 0.0
	if to.length() > 0.01:
		to = to.normalized()
		# Глаза выглядывают сбоку на уровне земли: горизонтальный луч снаружи (со стороны камеры) к укрытию —
		# перед первой гранью (коробка, ножка скамейки, борт машины); нет препятствия — у края укрытия (ревью плана 19).
		var outside := center + to * (maxf(size.x, size.z) + 1.0)
		var space := get_world_3d().direct_space_state
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(outside, center, Layers.WORLD))
		if not hit.is_empty() and (hit["position"] as Vector3).distance_to(center) > 0.05:
			center = Vector3(hit["position"].x, center.y, hit["position"].z) + to * 0.1
		else:
			# препятствия на уровне глаз нет (под машиной, куст) — глаза на границе зоны со стороны камеры
			var local := global_transform.basis.inverse() * to
			var half := outline_size() * 0.5
			var k := minf(half.x / maxf(absf(local.x), 0.001), half.y / maxf(absf(local.z), 0.001))
			center += to * (k + 0.05)
	_eyes.global_position = center
	var look := cam.global_position   # смотрят прямо в камеру — и по высоте
	if look.distance_to(center) > 0.01:
		_eyes.look_at(look, Vector3.UP)   # −Z (радужка и зрачок) — к камере


func _process(delta: float) -> void:
	var cat := get_tree().get_first_node_in_group("cat") as Node3D
	var carrying := not GameState.mouth.is_empty()
	var near := cat != null and cat.global_position.distance_to(global_position) < RING_RANGE
	var cat_hidden := cat != null and bool(cat.get("hidden"))
	_ring.visible = carrying and near and not (cat_hidden and cat_inside)
	if _ring.visible:
		_t += delta
		_ring.scale = Vector3.ONE * (1.0 + 0.06 * sin(_t * 4.0))
	if not _eyes.visible:
		return
	_place_eyes()
	_next_blink -= delta
	var sy := 1.0
	if _squint_left > 0.0:
		_squint_left -= delta
		sy = 0.3
	elif _next_blink <= 0.0:
		sy = 0.1
		if _next_blink < -0.12:
			_next_blink = randf_range(2.0, 4.5)
	_eyes.scale = Vector3(1, sy, 1)


# Доступ к полям кота через set/get/call: у типизированного Node3D GDScript не даст
# обратиться к несуществующему у Node3D свойству напрямую.
func _on_enter(body: Node3D) -> void:
	if body.is_in_group("cat"):
		cat_inside = true
		body.set("current_hideout", self)


func _on_exit(body: Node3D) -> void:
	if body.is_in_group("cat"):
		cat_inside = false
		if body.get("current_hideout") == self:
			body.set("current_hideout", null)
			if body.get("hidden"):
				body.call("unhide")
