class_name CatFace
extends RefCounted
## Выражения глаз (спек 2.4): оглушён > испуг > довольный > обычные.
## Переключает видимость мешей eyes_* из cat.glb; сам узлов не создаёт.

const SETS: Array[StringName] = [&"normal", &"scared", &"happy", &"dizzy"]
const HAPPY_TIME := 1.0
const THREAT_TIME := 0.4   # собака обновляет угрозу каждый физический кадр; без обновлений испуг гаснет

var expression: StringName = &"normal"
var happy_left := 0.0
var threat_left := 0.0
var _meshes := {}   # StringName -> MeshInstance3D


func bind(model: Node) -> int:
	_meshes.clear()
	for mi in model.find_children("eyes_*", "MeshInstance3D", true, false):
		_meshes[StringName(String(mi.name).trim_prefix("eyes_"))] = mi
	_show(&"normal")
	return _meshes.size()


func threaten() -> void:
	threat_left = THREAT_TIME


func cheer() -> void:
	happy_left = HAPPY_TIME


func update(delta: float, stunned: bool) -> StringName:
	happy_left = maxf(happy_left - delta, 0.0)
	threat_left = maxf(threat_left - delta, 0.0)
	var want: StringName = &"normal"
	if stunned:
		want = &"dizzy"
	elif threat_left > 0.0:
		want = &"scared"
	elif happy_left > 0.0:
		want = &"happy"
	if want != expression:
		_show(want)
	return expression


func _show(which: StringName) -> void:
	expression = which
	for key in _meshes:
		(_meshes[key] as MeshInstance3D).visible = key == which
