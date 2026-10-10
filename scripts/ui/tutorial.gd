class_name Tutorial
extends CanvasLayer
## Обучение (план 17): подсказка вверху экрана по шагам с текущими клавишами; шаг закрывается действием игрока.
## Игра не ставится на паузу. Пройдено или пропущено — GameState.tutorial_done (в сохранении), больше не показывается.

const STEPS := [&"move", &"run", &"jump", &"food", &"hide", &"eat", &"shop"]

var step := 0
var _started := false   # старт отсчёта «ходи» — на первом физическом кадре (после переноса кота)
var _cat: Node3D
var _main: Node
var _start := Vector3.ZERO
var _ate := false
var _label: Label
var _panel: PanelContainer
var _arrow: Node3D
var _t := 0.0


func setup(main: Node, cat: Node3D) -> void:
	_main = main
	_cat = cat


func _ready() -> void:
	layer = 5
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.theme = load("res://assets/ui/theme.tres")
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.position.y = 16
	add_child(_panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	_panel.add_child(margin)
	_label = Label.new()
	_label.name = "Hint"
	_label.add_theme_font_size_override("font_size", 20)
	margin.add_child(_label)
	_arrow = _make_arrow()
	GameState.food_eaten.connect(func(_items: Array) -> void: _ate = true)
	process_mode = Node.PROCESS_MODE_ALWAYS   # видимость — и на паузе; шаги — только в игре (_physics_process)
	visible = not GameState.tutorial_done


func _make_arrow() -> Node3D:
	## Стрелка над ближайшим укрытием на шаге «спрячься» (план 19).
	var a := Node3D.new()
	a.name = "Arrow"
	a.visible = false
	var cone := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.22
	cm.bottom_radius = 0.0
	cm.height = 0.4
	cone.mesh = cm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("#FABE32")
	m.emission_enabled = true
	m.emission = Color("#FABE32")
	m.emission_energy_multiplier = 1.2
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cone.material_override = m
	a.add_child(cone)
	add_child(a)
	return a


func _nearest_hideout() -> Node3D:
	var best: Node3D = null
	for h in get_tree().get_nodes_in_group("hideouts"):
		var n := h as Node3D
		if best == null or n.global_position.distance_to(_cat.global_position) < best.global_position.distance_to(_cat.global_position):
			best = n
	return best


func _update_arrow(delta: float) -> void:
	var show := visible and _cat != null and step_id() == &"hide" and not bool(_cat.get("hidden"))
	var target := _nearest_hideout() if show else null
	_arrow.visible = target != null
	if target:
		_t += delta
		var top := target.global_position.y + 0.6
		var hit := get_viewport().world_3d.direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			target.global_position + Vector3(0, 4, 0), target.global_position, Layers.WORLD))
		if not hit.is_empty():
			top = (hit["position"] as Vector3).y + 0.6   # над машиной и скамейкой, а не внутри
		_arrow.global_position = Vector3(target.global_position.x, top + 0.12 * sin(_t * 4.0), target.global_position.z)


func restart() -> void:
	## «Сбросить прогресс» в паузе: обучение снова с первого шага (ревью плана 17).
	step = 0
	_ate = false
	_started = false


func _process(delta: float) -> void:
	_update_arrow(delta)
	var controls_open: bool = _main != null and _main.get("controls_menu") != null and bool(_main.get("controls_menu").is_open)
	visible = not GameState.tutorial_done and not controls_open


func step_id() -> StringName:
	return STEPS[mini(step, STEPS.size() - 1)]


func text() -> String:
	return _label.text


func skip() -> void:
	GameState.finish_tutorial()
	visible = false


func _hint() -> String:
	var k := KeyBindings.key_name
	match step_id():
		&"move":
			return "Ходи: %s %s %s %s" % [k.call("move_forward"), k.call("move_left"), k.call("move_back"), k.call("move_right")]
		&"run":
			return "Беги: держи %s" % k.call("run")
		&"jump":
			return "Прыгай: %s" % k.call("jump")
		&"food":
			return "Подбери вкусняшку — просто подойди к ней (в зубах до трёх)"
		&"hide":
			return "Спрячься: встань в светящееся кольцо у коробки, скамейки, машины или куста и нажми %s" % k.call("hide")
		&"eat":
			return "Съешь в укрытии: %s — растёт сытость, открываются карточки альбома" % k.call("eat")
		&"shop":
			return "Клубочки — деньги: в будке пряжи (откуда ты начал) нажми %s" % k.call("eat")
	return ""


func _done() -> bool:
	match step_id():
		&"move":
			return _cat.global_position.distance_to(_start) > 2.0
		&"run":
			return _cat.get("state") == &"run"
		&"jump":
			return _cat.get("state") == &"jump"
		&"food":
			return not GameState.mouth.is_empty()
		&"hide":
			return bool(_cat.get("hidden"))
		&"eat":
			return _ate
		&"shop":
			return _main != null and bool(_main.get("shop_menu").is_open)
	return false


func _physics_process(_delta: float) -> void:
	if GameState.tutorial_done or _cat == null or get_tree().paused:
		return
	if not _started:
		_start = _cat.global_position
		_started = true
	if _done():
		step += 1
		_ate = false
		if step >= STEPS.size():
			skip()
			return
	var extra := ""
	if step_id() == &"eat" and GameState.mouth.is_empty():
		extra = " (сначала подбери еду)"   # еду выбили между шагами — подсказка объясняет
	_label.text = "Обучение %d/%d · %s%s · пропустить — в паузе" % [step + 1, STEPS.size(), _hint(), extra]
