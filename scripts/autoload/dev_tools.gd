extends Node
## Инструменты разработчика. Запуск: godot --path . ++ --screenshot=build/shot.png

const DEV_ARGS := ["--screenshot=", "--at=", "--phase=", "--album", "--controls"]


static func is_dev_run(args: PackedStringArray) -> bool:
	## Отладочный запуск: кадры и перенос кота не должны собирать клубочки в настоящее сохранение владельца.
	for a in args:
		for d in DEV_ARGS:
			if a.begins_with(d):
				return true
	return false


func _ready() -> void:
	if is_dev_run(OS.get_cmdline_user_args()):
		SaveGame.read_only = true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			_set_phase_later(DayCycle.parse_time(arg.trim_prefix("--phase=")))
		if arg.begins_with("--at="):
			var v := arg.trim_prefix("--at=").split_floats(",")
			if v.size() >= 3:
				_teleport_later(Vector3(v[0], v[1], v[2]), deg_to_rad(v[3]) if v.size() > 3 else 0.0)
		if arg == "--album":
			_open_album_later()
		if arg == "--controls":
			_open_controls_later()
		if arg.begins_with("--screenshot="):
			_screenshot_and_quit(arg.trim_prefix("--screenshot="))


func _set_phase_later(t: float) -> void:
	## Для кадров ночью/на закате: ++ --phase=220 ставит время суток после загрузки сцены.
	for i in 3:
		await get_tree().process_frame
	var dn := get_tree().get_first_node_in_group("day_night")
	if dn:
		dn.call("set_time", t)
		dn.set("time_scale", 0.0)


func _teleport_later(pos: Vector3, yaw := 0.0) -> void:
	## Для кадров других районов: ++ --at=x,y,z[,yaw°] ставит кота в точку и поворачивает камеру.
	for i in 4:
		await get_tree().process_frame
	var cat := get_tree().get_first_node_in_group("cat")
	if cat:
		cat.call("teleport", pos)
		var rig := cat.get("camera_rig") as Node3D
		if rig:
			rig.global_position = pos + Vector3(0, 0.6, 0)
			rig.set("_yaw", yaw)


func _open_controls_later() -> void:
	## Кадр экрана «Управление и помощь» (план 17).
	for i in 6:
		await get_tree().process_frame
	var main := get_tree().current_scene
	if main and main.get("controls_menu"):
		main.call("toggle_pause")
		main.get("controls_menu").call("open")


func _open_album_later() -> void:
	## Кадр альбома: ++ --album открывает альбом со всеми карточками (план 13: 20 вкусняшек).
	for i in 6:
		await get_tree().process_frame
	var main := get_tree().get_first_node_in_group("main")
	if main == null:
		main = get_tree().current_scene
	fill_album(main)
	if main and main.has_method("toggle_album"):
		main.call("toggle_album")


func fill_album(main: Node) -> void:
	## Все карточки — только для кадра: автосохранение выключается, настоящий save.json не меняется (ревью плана 13).
	if main and "autosave" in main:
		main.set("autosave", false)
	for f in FoodCatalog.all():
		GameState.album[f.id] = maxi(int(GameState.album.get(f.id, 0)), 1)
	GameState.album_changed.emit(GameState.album)


func _screenshot_and_quit(path: String) -> void:
	# Ждём, пока сцена загрузится, кот приземлится и анимация перейдёт в idle.
	for i in 40:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var abs_path := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	var err := img.save_png(abs_path)
	print("СКРИНШОТ ", abs_path, " ", error_string(err))
	get_tree().quit(0 if err == OK else 1)
