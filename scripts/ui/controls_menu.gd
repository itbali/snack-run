class_name ControlsMenu
extends CanvasLayer
## «Управление и помощь» (план 17): краткие правила и клавиши; кнопка клавиши → «нажмите клавишу…» → новая клавиша
## (Esc — отмена); «Сбросить», «Закрыть». Работает на паузе; настройки сохраняются (KeyBindings).

signal closed

const HELP := "Собирай вкусняшки — до трёх в зубах. Неси их в укрытие (коробка, скамейка, куст, машина) и съешь там: так " + \
	"растёт сытость и открываются карточки альбома. Сытость открывает ворота: кафе — 10, парк — 25, порт — 50. " + \
	"Опасности выбивают еду и снимают сердечки; в будке пряжи безопасно, там магазин за клубочки."
const WAITING := "нажмите клавишу…"

var is_open := false
var standalone := false   # на заставке нет MenuInput: Esc закрывает сам экран
var capturing := ""
var _captured_frame := -1
var _buttons := {}
var _help: Label
var _return_focus: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30   # поверх паузы (22), альбома (21), магазина (20) и обучения
	visible = false
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.theme = load("res://assets/ui/theme.tres")
	var sb := StyleBoxFlat.new()   # непрозрачная: сквозь неё не читается меню паузы (ревью плана 17)
	sb.bg_color = Color("#F4F1E8")
	sb.set_corner_radius_all(18)
	sb.shadow_color = Color(0, 0, 0, 0.25)
	sb.shadow_size = 8
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var title := Label.new()
	title.text = "Управление, помощь и настройки"
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	_help = Label.new()
	_help.name = "Help"
	_help.text = HELP
	_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help.custom_minimum_size = Vector2(620, 0)
	_help.add_theme_font_size_override("font_size", 16)
	box.add_child(_help)
	var grid := GridContainer.new()
	grid.name = "Keys"
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	box.add_child(grid)
	for row in KeyBindings.REBINDABLE:
		var action: String = row[0]
		var label := Label.new()
		label.text = row[1]
		label.add_theme_font_size_override("font_size", 16)
		grid.add_child(label)
		var b := Button.new()
		b.name = "Key_" + action
		b.custom_minimum_size = Vector2(130, 0)
		b.pressed.connect(start_capture.bind(action))
		grid.add_child(b)
		_buttons[action] = b
	var opts := HBoxContainer.new()   # план 18: настройки картинки
	opts.add_theme_constant_override("separation", 24)
	box.add_child(opts)
	for spec in [["Blur", "Размытие вдали", GameSettings.blur, GameSettings.set_blur], ["Particles", "Пылинки и светлячки", GameSettings.particles, GameSettings.set_particles]]:
		var cb := CheckButton.new()
		cb.name = spec[0]
		cb.text = spec[1]
		cb.button_pressed = spec[2]
		var setter: Callable = spec[3]
		cb.toggled.connect(func(on: bool) -> void: setter.call(on, get_tree()))
		opts.add_child(cb)
	var mrow := HBoxContainer.new()   # план 21: громкость музыки
	mrow.add_theme_constant_override("separation", 12)
	box.add_child(mrow)
	var ml := Label.new()
	ml.text = "Музыка"
	ml.add_theme_font_size_override("font_size", 16)
	mrow.add_child(ml)
	var slider := HSlider.new()
	slider.name = "Music"
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = GameSettings.music
	slider.custom_minimum_size = Vector2(260, 0)
	slider.value_changed.connect(func(v: float) -> void: GameSettings.set_music(v, get_tree()))
	mrow.add_child(slider)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	box.add_child(bar)
	var reset := Button.new()
	reset.name = "Reset"
	reset.text = "Сбросить клавиши"
	reset.pressed.connect(reset_bindings)
	bar.add_child(reset)
	var close_b := Button.new()
	close_b.name = "Close"
	close_b.text = "Закрыть"
	close_b.pressed.connect(close)
	bar.add_child(close_b)
	_refresh()


func rows() -> Array:
	return KeyBindings.REBINDABLE


func help_text() -> String:
	return _help.text


func key_button(action: String) -> Button:
	return _buttons[action]


func open() -> void:
	_return_focus = get_viewport().gui_get_focus_owner()
	is_open = true
	visible = true
	capturing = ""
	_refresh()
	(_buttons["move_forward"] as Button).grab_focus()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	capturing = ""
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus()   # геймпад: фокус обратно на кнопку, с которой открыли
	closed.emit()


func back() -> void:
	## Esc/«назад»: отменяет ожидание клавиши, иначе закрывает. Нажатие, уже поймавшее клавишу в этом кадре, не закрывает меню.
	if _captured_frame == Engine.get_process_frames():
		return
	if capturing != "":
		capturing = ""
		_refresh()
	else:
		close()


func start_capture(action: String) -> void:
	capturing = action
	_refresh()


func handle_key(code: int) -> void:
	if capturing == "":
		return
	_captured_frame = Engine.get_process_frames()
	if code != KEY_ESCAPE:
		KeyBindings.rebind(capturing, code)
		KeyBindings.save()
	capturing = ""
	_refresh()


func reset_bindings() -> void:
	KeyBindings.reset()
	KeyBindings.save()
	_refresh()


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if capturing == "":
		if standalone and is_open and event.is_action("pause"):
			close()
			get_viewport().set_input_as_handled()
		return
	handle_key((event as InputEventKey).physical_keycode)
	get_viewport().set_input_as_handled()


func _refresh() -> void:
	for action in _buttons:
		(_buttons[action] as Button).text = WAITING if action == capturing else KeyBindings.key_name(action)
