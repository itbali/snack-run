class_name DayNight
extends Node
## Ведёт время суток и применяет свет к узлам Lighting (спек этапа 2, раздел 2).
## Остальные спрашивают DayNight.is_night(tree): без узла (тесты, отдельные сцены) всегда день.

signal phase_changed(phase: StringName)

@export var time_scale := 1.0
var time := 0.0
var phase: StringName = &"day"
const WINDOW_GLOW := Color("#FFD9A0")


func _ready() -> void:
	add_to_group("day_night")
	set_time(time)


func _process(delta: float) -> void:
	time = DayCycle.wrap_time(time + delta * time_scale)
	_apply()


func set_time(t: float) -> void:
	time = DayCycle.wrap_time(t)
	_apply()


func _apply() -> void:
	var s := DayCycle.light_at(time)
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
	var lamps := DayCycle.lamps_on(time)
	if is_inside_tree():
		for n in get_tree().get_nodes_in_group("night_lights"):
			(n as Node3D).visible = lamps
		for n in get_tree().get_nodes_in_group("night_windows"):
			var mi := n as MeshInstance3D
			for i in mi.mesh.get_surface_count():
				var m := mi.get_surface_override_material(i) as StandardMaterial3D
				if m:
					m.emission_enabled = lamps
					m.emission = WINDOW_GLOW
					m.emission_energy_multiplier = 0.9
	var p := DayCycle.phase_at(time)
	if p != phase:
		phase = p
		phase_changed.emit(phase)


static func current_phase(tree: SceneTree) -> StringName:
	var n := tree.get_first_node_in_group("day_night") as DayNight
	return n.phase if n else &"day"


static func is_night(tree: SceneTree) -> bool:
	return current_phase(tree) == &"night"
