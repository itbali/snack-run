extends Node
## Инструменты разработчика. Запуск: godot --path . ++ --screenshot=build/shot.png

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			_set_phase_later(DayCycle.parse_time(arg.trim_prefix("--phase=")))
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
