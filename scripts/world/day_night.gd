class_name DayNight
extends Node
## Ведёт время суток и применяет свет к узлам Lighting (спек этапа 2, раздел 2).
## Остальные спрашивают DayNight.is_night(tree): без узла (тесты, отдельные сцены) всегда день.
## Пишет в свет/небо только при изменении состояния, фонари и окна — только при переключении.

signal phase_changed(phase: StringName)

const WINDOW_GLOW := Color("#FFD9A0")

@export var time_scale := 1.0
var time := 0.0
var phase: StringName = &"day"
var light_writes := 0          # счётчик применений света (для тестов «не пишет каждый кадр»)
var _last_light: Dictionary = {}
var _lamps := false
var _lamp_count := -1


func _ready() -> void:
	add_to_group("day_night")
	_own_sky()
	set_time(time)


func _own_sky() -> void:
	## Свой экземпляр окружения и неба: подресурсы PackedScene общие для всех инстансов сцены.
	var we := get_parent().get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		we.environment = we.environment.duplicate(true)


func _process(delta: float) -> void:
	time = DayCycle.wrap_time(time + delta * time_scale)
	_apply()


func set_time(t: float) -> void:
	time = DayCycle.wrap_time(t)
	_apply()


func _apply() -> void:
	var s := DayCycle.light_at(time)
	if s != _last_light:
		_last_light = s
		light_writes += 1
		_write_light(s)
	var lamps := DayCycle.lamps_on(time)
	var count := get_tree().get_node_count_in_group("night_lights") + get_tree().get_node_count_in_group("night_windows") if is_inside_tree() else 0
	if lamps != _lamps or count != _lamp_count:   # новые фонари/окна (построены позже) тоже получают текущее состояние
		_lamps = lamps
		_lamp_count = count
		_write_lamps(lamps)
	var p := DayCycle.phase_at(time)
	if p != phase:
		phase = p
		phase_changed.emit(phase)


func _write_light(s: Dictionary) -> void:
	var lighting := get_parent()
	var sun := lighting.get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		sun.rotation_degrees = Vector3(s["sun_pitch"], 30.0, 0.0)
		sun.light_color = s["sun_color"]
		sun.light_energy = s["sun_energy"]
	var fill := lighting.get_node_or_null("Fill") as DirectionalLight3D
	if fill:
		fill.light_energy = s["fill"]
	var we := lighting.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		we.environment.ambient_light_energy = s["ambient"]
		var sky := we.environment.sky.sky_material as ProceduralSkyMaterial if we.environment.sky else null
		if sky:
			sky.sky_top_color = s["sky_top"]
			sky.sky_horizon_color = s["sky_horizon"]
			sky.ground_horizon_color = s["sky_horizon"]
			sky.sky_cover_modulate = s["clouds"]


func _write_lamps(on: bool) -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group("night_lights"):
		(n as Node3D).visible = on
	for n in get_tree().get_nodes_in_group("night_windows"):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var m := mi.get_surface_override_material(i) as StandardMaterial3D
			if m:
				m.emission_enabled = on
				m.emission = WINDOW_GLOW
				m.emission_energy_multiplier = 0.9


static func current_phase(tree: SceneTree) -> StringName:
	var n := tree.get_first_node_in_group("day_night") as DayNight
	return n.phase if n else &"day"


static func is_night(tree: SceneTree) -> bool:
	return current_phase(tree) == &"night"
