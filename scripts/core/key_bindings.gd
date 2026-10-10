class_name KeyBindings
extends RefCounted
## Переназначение клавиш (план 17): клавиатурные события действий InputMap меняются, геймпад остаётся;
## конфликт — обмен клавишами; сохранение в user://settings.cfg.

const REBINDABLE := [
	["move_forward", "Вперёд"], ["move_back", "Назад"], ["move_left", "Влево"], ["move_right", "Вправо"],
	["run", "Бежать"], ["jump", "Прыжок"], ["hide", "Спрятаться / выйти"], ["eat", "Съесть, магазин"],
	["cam_left", "Камера влево"], ["cam_right", "Камера вправо"], ["album", "Альбом"], ["pause", "Пауза"],
]
const NAMES := {KEY_SPACE: "Пробел", KEY_SHIFT: "Shift", KEY_CTRL: "Ctrl", KEY_TAB: "Tab", KEY_ESCAPE: "Esc",
	KEY_LEFT: "←", KEY_RIGHT: "→", KEY_UP: "↑", KEY_DOWN: "↓", KEY_ENTER: "Enter", KEY_ALT: "Alt"}

static var path := "user://settings.cfg"


static func keys_of(action: String) -> Array:
	var out := []
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			out.append((e as InputEventKey).physical_keycode)
	return out


static func key_label(code: int) -> String:
	return NAMES.get(code, OS.get_keycode_string(code))


static func key_name(action: String) -> String:
	var k := keys_of(action)
	return key_label(k[0]) if not k.is_empty() else ""


static func _set_keys(action: String, codes: Array) -> void:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			InputMap.action_erase_event(action, e)
	for c in codes:
		var ev := InputEventKey.new()
		ev.physical_keycode = c
		InputMap.action_add_event(action, ev)


static func rebind(action: String, code: int) -> String:
	## Новая клавиша действия; если она была у другого действия — тому достаётся прежняя клавиша. Возвращает это действие.
	var old := keys_of(action)
	var swapped := ""
	for row in REBINDABLE:
		var other: String = row[0]
		if other != action and code in keys_of(other):
			var rest := keys_of(other).filter(func(k): return k != code)
			if rest.is_empty() and not old.is_empty():
				rest = [old[0]]
			_set_keys(other, rest)
			swapped = other
	_set_keys(action, [code])
	return swapped


static func reset() -> void:
	for action in InputSetup.ACTIONS:
		_set_keys(action, InputSetup.ACTIONS[action])


static func save() -> void:
	var cfg := ConfigFile.new()
	for row in REBINDABLE:
		cfg.set_value("keys", row[0], keys_of(row[0]))
	cfg.save(path)


static func load_saved() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	for row in REBINDABLE:
		var codes = cfg.get_value("keys", row[0], null)
		if codes is Array and not (codes as Array).is_empty():
			_set_keys(row[0], codes)
