class_name FoodPickup
extends Area3D
## Еда на земле: модель из FoodDef, подложка цвета редкости, покачивание, подбор котом.

signal picked(food: FoodDef, pickup: FoodPickup)

const SPILL_GRACE := 0.5
const BOB_HEIGHT := 0.04
const SPIN_SPEED := 1.2

@export var food: FoodDef
var spilled := false
var lifetime := 0.0
var grace := 0.0
var _t := 0.0
var _built := false

@onready var _visual: Node3D = $Visual
@onready var _ring: MeshInstance3D = $Ring


func setup(def: FoodDef, is_spilled := false, life := 0.0) -> void:
	food = def
	spilled = is_spilled
	lifetime = life
	grace = SPILL_GRACE if is_spilled else 0.0


func _ready() -> void:
	collision_layer = Layers.AREA
	collision_mask = Layers.CAT
	monitorable = false
	body_entered.connect(_on_body_entered)
	_build_visual()


func _build_visual() -> void:
	if _built or food == null:
		return
	_built = true
	var model: Node3D = null
	if food.model_path != "" and ResourceLoader.exists(food.model_path):
		model = (load(food.model_path) as PackedScene).instantiate()
	else:
		var mi := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.06
		sphere.height = 0.12
		mi.mesh = sphere
		mi.position.y = 0.06
		model = mi
	_visual.add_child(model)
	Toon.apply(_visual, Toon.OUTLINE_FOOD)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.albedo_color = Rarity.COLORS[food.tier]
	_ring.set_surface_override_material(0, ring_mat)
	if food.tier >= Rarity.Tier.RARE:
		Effects.sparkles(self, Rarity.COLORS[food.tier])


func _process(delta: float) -> void:
	_t += delta
	if grace > 0.0:
		grace -= delta
		if grace <= 0.0:
			# Пауза кончилась: кот мог всё это время стоять на еде, body_entered уже не придёт.
			for body in get_overlapping_bodies():
				_on_body_entered(body)
	if lifetime > 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()
			return
	_visual.position.y = BOB_HEIGHT * (0.5 + 0.5 * sin(_t * 3.0))
	_visual.rotation.y += SPIN_SPEED * delta


func _on_body_entered(body: Node3D) -> void:
	if grace > 0.0 or not body.is_in_group("cat"):
		return
	if GameState.pick_up(food):
		Sfx.play(&"pickup")
		picked.emit(food, self)
		set_deferred("monitoring", false)
		queue_free()
