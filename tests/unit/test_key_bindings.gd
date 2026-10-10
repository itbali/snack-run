extends GutTest
## План 17: переназначение клавиш (просьба владельца 2026-10-10).

func before_each() -> void:
	KeyBindings.path = "user://test_settings.cfg"
	if FileAccess.file_exists(KeyBindings.path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(KeyBindings.path))
	KeyBindings.reset()

func after_each() -> void:
	KeyBindings.reset()
	KeyBindings.path = "user://settings.cfg"

func test_every_action_has_a_russian_name_and_key() -> void:
	for row in KeyBindings.REBINDABLE:
		assert_ne(String(row[1]), "", "название %s" % row[0])
		assert_ne(KeyBindings.key_name(row[0]), "", "клавиша %s" % row[0])
	assert_eq(KeyBindings.key_name("jump"), "Пробел")
	assert_eq(KeyBindings.key_name("move_forward"), "W")

func test_rebind_replaces_key_and_swaps_conflict() -> void:
	var swapped := KeyBindings.rebind("jump", KEY_E)
	assert_eq(KeyBindings.keys_of("jump"), [KEY_E])
	assert_eq(swapped, "eat", "E была у «съесть» — поменялись местами")
	assert_eq(KeyBindings.keys_of("eat"), [KEY_SPACE])

func test_rebind_keeps_gamepad_events() -> void:
	KeyBindings.rebind("jump", KEY_J)
	var pads := InputMap.action_get_events("jump").filter(func(e): return e is InputEventJoypadButton)
	assert_eq(pads.size(), 1, "кнопка геймпада осталась")

func test_bindings_persist_and_reset() -> void:
	KeyBindings.rebind("run", KEY_Z)
	KeyBindings.save()
	KeyBindings.reset()
	assert_eq(KeyBindings.keys_of("run"), [KEY_SHIFT])
	KeyBindings.load_saved()
	assert_eq(KeyBindings.keys_of("run"), [KEY_Z], "из файла настроек")
	KeyBindings.reset()
	assert_eq(KeyBindings.keys_of("move_left"), [KEY_A, KEY_LEFT], "сброс — как было")

func test_moving_keeps_arrow_as_second_key() -> void:
	# Ревью плана 17: «Вперёд» → I молча убирал стрелку ↑.
	KeyBindings.rebind("move_forward", KEY_I)
	assert_eq(KeyBindings.keys_of("move_forward"), [KEY_I, KEY_UP])

func test_zero_keycode_is_ignored() -> void:
	KeyBindings.rebind("jump", 0)
	assert_eq(KeyBindings.keys_of("jump"), [KEY_SPACE])
