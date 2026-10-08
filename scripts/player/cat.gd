class_name Cat
extends CharacterBody3D
## Узел кота: ввод, физика через CatMotion, клипы, укрытие, еда, удар.

signal state_changed(state: StringName)
signal hidden_changed(hidden: bool)
signal ate(items: Array)
signal hit_taken(from: Vector3)

const FALLBACK := {&"run": [&"walk", 1.8], &"jump": [&"idle", 1.0], &"hide": [&"idle", 1.0], &"hit": [&"idle", 1.0]}
const LOOPING_CLIPS := ["idle", "walk", "run", "hide"]
const TURN_SPEED := 12.0
const KNOCKBACK_SPEED := 6.5      # √(2·ACCEL·1,5 м) — отброс на 1,5 м при торможении 14 м/с²
const KNOCKBACK_UP := 2.0
const STUN_TIME := 1.0
const INVULNERABLE_TIME := 2.0

var camera_rig: CameraRig
var current_hideout: Area3D
var hidden := false
var stunned_left := 0.0
var invulnerable_left := 0.0
var state: StringName = &"idle":
	set(value):
		if value != state:
			state = value
			play_clip(state)
			state_changed.emit(state)

@onready var _model: Node3D = $Model
@onready var _anim: AnimationPlayer = $Model.find_child("AnimationPlayer", true, false)


func _ready() -> void:
	add_to_group("cat")
	collision_layer = Layers.CAT
	collision_mask = Layers.WORLD | Layers.HAZARD
	Toon.apply(_model, Toon.OUTLINE_CHARACTER)
	_apply_skin(GameState.skin)
	GameState.skin_changed.connect(_apply_skin)
	for clip in LOOPING_CLIPS:
		if _anim and _anim.has_animation(clip):
			_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var skel := _model.find_child("Skeleton3D", true, false)
	if skel and skel.find_child("HeadScaler", false, false) == null:
		var hs := HeadScaler.new()
		hs.name = "HeadScaler"
		skel.add_child(hs)
	if camera_rig:
		(camera_rig.get_node("SpringArm3D") as SpringArm3D).add_excluded_object(get_rid())
	play_clip(&"idle")


func _physics_process(delta: float) -> void:
	stunned_left = maxf(stunned_left - delta, 0.0)
	invulnerable_left = maxf(invulnerable_left - delta, 0.0)
	if stunned_left > 0.0:
		velocity = CatMotion.step(velocity, Vector3.ZERO, false, is_on_floor(), false, delta)
		move_and_slide()
		return
	if Input.is_action_just_pressed("hide"):
		if hidden:
			unhide()
		else:
			try_hide()
	if hidden:
		if Input.is_action_just_pressed("eat"):
			try_eat()
		if Input.get_vector("move_left", "move_right", "move_forward", "move_back").length() > 0.3:
			unhide()
		else:
			velocity = CatMotion.step(velocity, Vector3.ZERO, false, is_on_floor(), false, delta)
			move_and_slide()
			return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var yaw := camera_rig.yaw_basis() if camera_rig else Basis.IDENTITY
	var dir := CatMotion.world_direction(input, yaw)
	var running := Input.is_action_pressed("run")
	var jump := Input.is_action_just_pressed("jump")
	velocity = CatMotion.step(velocity, dir, running, is_on_floor(), jump, delta, GameState.speed_mult)
	move_and_slide()
	if dir.length() > 0.0:
		var target_yaw := atan2(-dir.x, -dir.z)
		_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, TURN_SPEED * delta)
	state = CatMotion.pick_state(velocity, is_on_floor(), running, GameState.speed_mult)


func _apply_skin(id: StringName) -> void:
	var skin := SkinCatalog.get_by_id(id)
	if skin:
		CatSkin.apply(_model, skin)


func try_hide() -> bool:
	if hidden or current_hideout == null:
		return false
	hidden = true
	state = &"hide"
	if camera_rig:
		camera_rig.crouch = true
	hidden_changed.emit(true)
	return true


func unhide() -> void:
	if not hidden:
		return
	hidden = false
	if camera_rig:
		camera_rig.crouch = false
	state = &"idle"
	hidden_changed.emit(false)


func try_eat() -> bool:
	if not hidden or GameState.mouth.is_empty():
		return false
	var items := GameState.eat_all()
	ate.emit(items)
	return true


func take_hit(from: Vector3) -> void:
	if invulnerable_left > 0.0 or stunned_left > 0.0 or hidden:
		return
	var away := global_position - from
	away.y = 0.0
	if away.length() < 0.01:
		away = _model.global_transform.basis.z   # назад относительно взгляда
	velocity = away.normalized() * KNOCKBACK_SPEED + Vector3.UP * KNOCKBACK_UP
	stunned_left = STUN_TIME
	invulnerable_left = INVULNERABLE_TIME
	state = &"hit"
	hit_taken.emit(from)
	GameState.take_hit()


func teleport(pos: Vector3) -> void:
	unhide()
	global_position = pos
	velocity = Vector3.ZERO
	stunned_left = 0.0
	invulnerable_left = INVULNERABLE_TIME   # после возрождения дать прийти в себя
	state = &"idle"


func play_clip(name: StringName) -> void:
	if _anim == null:
		return
	var clip := String(name)
	var speed := 1.0
	if not _anim.has_animation(clip):
		if FALLBACK.has(name):
			clip = String(FALLBACK[name][0])
			speed = FALLBACK[name][1]
		else:
			clip = "idle"
	_anim.speed_scale = speed
	if _anim.current_animation != clip:
		_anim.play(clip, 0.15)
