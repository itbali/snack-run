extends Node3D
## Собирает мир, кота, камеру и реакции на события GameState.

signal faint_sequence_done

const CatScene := preload("res://scenes/player/cat.tscn")
const RigScene := preload("res://scenes/player/camera_rig.tscn")

var fade_time := 0.6
var _cat: Cat
var _rig: CameraRig
var _spill: SpillSpawner
var _fade: ColorRect


func _ready() -> void:
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


func respawn_cat() -> void:
	_cat.teleport($DistrictYard/Spawn.global_position)
	_rig.global_position = _cat.global_position + Vector3(0, CameraRig.HEIGHT, 0)
	GameState.revive()
