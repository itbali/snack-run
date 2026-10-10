class_name GameSettings
extends RefCounted
## Настройки картинки (план 18): размытие вдали и атмосферные частицы. Хранятся рядом с клавишами в user://settings.cfg.

const BLUR_DISTANCE := 22.0
const BLUR_TRANSITION := 18.0
const BLUR_AMOUNT := 0.06

static var path := "user://settings.cfg"
static var blur := true
static var particles := true
static var music := 0.7


static func reset() -> void:
	blur = true
	particles = true
	music = 0.7


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(path)   # клавиши лежат в том же файле — не затирать
	cfg.set_value("video", "blur", blur)
	cfg.set_value("video", "particles", particles)
	cfg.set_value("audio", "music", music)
	cfg.save(path)


static func load_saved() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	var b = cfg.get_value("video", "blur", true)
	var p = cfg.get_value("video", "particles", true)
	blur = b if b is bool else true
	particles = p if p is bool else true
	var m = cfg.get_value("audio", "music", 0.7)
	music = clampf(float(m), 0.0, 1.0) if (m is float or m is int) else 0.7


static func apply_camera(cam: Camera3D) -> void:
	var a := cam.attributes as CameraAttributesPractical
	if a == null:
		a = CameraAttributesPractical.new()
		cam.attributes = a
	a.dof_blur_far_enabled = blur
	a.dof_blur_far_distance = BLUR_DISTANCE
	a.dof_blur_far_transition = BLUR_TRANSITION
	a.dof_blur_amount = BLUR_AMOUNT


static func set_blur(on: bool, tree: SceneTree) -> void:
	blur = on
	save()
	for c in tree.get_nodes_in_group("game_camera"):
		apply_camera(c as Camera3D)


static func set_music(v: float, tree: SceneTree) -> void:
	music = clampf(v, 0.0, 1.0)
	save()
	var m := tree.root.get_node_or_null("Music")
	if m:
		m.call("set_volume", music)


static func set_particles(on: bool, tree: SceneTree) -> void:
	particles = on
	save()
	for n in tree.get_nodes_in_group("ambient_fx"):
		n.call("refresh")
