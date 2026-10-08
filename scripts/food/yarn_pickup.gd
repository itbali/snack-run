class_name YarnPickup
extends Area3D
## Клубочек: валюта магазина. Лежит в труднодоступном месте, не респавнится (спек 3.4).

@onready var _visual: Node3D = $Visual
var key := ""      # ключ позиции из раскладки; пустой у клубочков вне раскладки
var _t := 0.0


func _ready() -> void:
	add_to_group("yarn")
	collision_layer = Layers.AREA
	collision_mask = Layers.CAT
	monitorable = false
	body_entered.connect(_on_body)
	var model := (load("res://assets/models/yarn.glb") as PackedScene).instantiate()
	_visual.add_child(model)
	Toon.apply(_visual, Toon.OUTLINE_FOOD)


func _process(delta: float) -> void:
	_t += delta
	_visual.rotation.y += 1.5 * delta
	_visual.position.y = 0.03 * (0.5 + 0.5 * sin(_t * 3.0))


func _on_body(body: Node3D) -> void:
	if not body.is_in_group("cat"):
		return
	GameState.take_yarn(key)
	Sfx.play(&"pickup", 0.15)
	if body.has_method("cheer"):
		body.call("cheer")
	Effects.burst(get_parent(), global_position + Vector3(0, 0.1, 0), Effects.YARN_COLOR, 16, 0.04)
	set_deferred("monitoring", false)
	queue_free()
