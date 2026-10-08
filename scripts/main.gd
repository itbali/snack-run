extends Node3D
## Собирает мир, кота, камеру и реакции на события GameState.

signal faint_sequence_done

const CatScene := preload("res://scenes/player/cat.tscn")
const RigScene := preload("res://scenes/player/camera_rig.tscn")

var fade_time := 0.6
var autosave := true
var _cat: Cat
var _rig: CameraRig
var _spill: SpillSpawner
var _fade: ColorRect
@onready var hud: Hud = $Hud
@onready var shop_menu: ShopMenu = $ShopMenu
@onready var album_menu: AlbumMenu = $AlbumMenu
@onready var pause_menu: PauseMenu = $PauseMenu


func _ready() -> void:
	SaveGame.load_now()
	Toon.apply($DistrictYard, Toon.OUTLINE_NONE)
	_rig = RigScene.instantiate()
	_rig.name = "CameraRig"
	_cat = CatScene.instantiate()
	_cat.name = "Cat"
	_cat.camera_rig = _rig
	_rig.target = _cat
	add_child(_rig)
	add_child(_cat)
	_cat.global_position = $DistrictYard/Spawn.global_position
	_rig.global_position = _cat.global_position + Vector3(0, CameraRig.HEIGHT, 0)
	(_rig.get_node("SpringArm3D/Camera3D") as Camera3D).make_current()
	_spill = SpillSpawner.new()
	_spill.name = "SpillSpawner"
	add_child(_spill)
	_fade = _make_fade()
	GameState.cat_hit.connect(_on_cat_hit)
	GameState.cat_fainted.connect(_on_cat_fainted)
	for c in get_tree().get_nodes_in_group("hazards"):
		if c.has_signal("bell"):
			c.bell.connect(func() -> void: hud.flash_bell())
	shop_menu.closed.connect(close_shop)
	album_menu.closed.connect(func() -> void: _set_paused(false))
	pause_menu.resumed.connect(func() -> void: _set_paused(false))
	pause_menu.reset_requested.connect(reset_progress)
	for g in get_tree().get_nodes_in_group("gates"):
		g.opened.connect(func() -> void: hud.flash_bell("🎉 Арка в кафе открыта!", 3.0))
	for sig in [GameState.album_changed, GameState.satiety_changed, GameState.yarn_changed, GameState.upgrade_bought, GameState.skin_changed]:
		sig.connect(_on_progress_changed.unbind(1))


func _on_progress_changed() -> void:
	if autosave:
		SaveGame.save_now()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and autosave:
		SaveGame.save_now()


func _make_fade() -> ColorRect:
	var layer := CanvasLayer.new()
	layer.name = "FadeLayer"
	layer.layer = 100
	add_child(layer)
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	return rect


func _on_cat_hit(spilled: Array) -> void:
	if spilled.is_empty():
		return
	_spill.spill_around(_cat.global_position, spilled)


func _on_cat_fainted() -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, fade_time)
	await tween.finished
	respawn_cat()
	var back := create_tween()
	back.tween_property(_fade, "color:a", 0.0, fade_time)
	await back.finished
	faint_sequence_done.emit()


func respawn_position() -> Vector3:
	var shop := get_tree().get_first_node_in_group("yarn_shop")
	if shop:
		return shop.respawn_position()
	return $DistrictYard/Spawn.global_position


func respawn_cat() -> void:
	for h in get_tree().get_nodes_in_group("hazards"):
		if h.has_method("reset_pursuit"):
			h.call("reset_pursuit")
	_cat.teleport(respawn_position())
	_rig.global_position = _cat.global_position + Vector3(0, CameraRig.HEIGHT, 0)
	GameState.revive()


func on_interact_pressed() -> void:
	if _cat and _cat.in_safe_zone and not _cat.hidden and not shop_menu.is_open:
		open_shop()


func open_shop() -> void:
	_cat.input_enabled = false
	var shop := get_tree().get_first_node_in_group("yarn_shop")
	if shop:
		_rig.shop_view_point = shop.view_position()
		_rig.use_shop_point = true
	_rig.shop_view = true
	hud.visible = false
	shop_menu.open()


func close_shop() -> void:
	if shop_menu.is_open:
		shop_menu.close()
		return
	_cat.input_enabled = true
	_rig.shop_view = false
	hud.visible = true


func on_back_pressed() -> void:
	if shop_menu.is_open:
		close_shop()
	elif album_menu.is_open:
		toggle_album()
	else:
		toggle_pause()


func on_album_pressed() -> void:
	if not shop_menu.is_open and not pause_menu.is_open:
		toggle_album()


func _set_paused(on: bool) -> void:
	get_tree().paused = on


func toggle_album() -> void:
	if album_menu.is_open:
		album_menu.close()
	else:
		_set_paused(true)
		album_menu.open()


func toggle_pause() -> void:
	if pause_menu.is_open:
		pause_menu.close()
	else:
		_set_paused(true)
		pause_menu.open()


func reset_progress() -> void:
	SaveGame.clear()
	GameState.reset()
	if pause_menu.is_open:
		pause_menu.close()
	_set_paused(false)
	respawn_cat()
