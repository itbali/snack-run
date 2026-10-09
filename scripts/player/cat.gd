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
const RUN_DUST_EVERY := 0.25
const FLASH_COLOR := Color.WHITE
const WET_SLOW := 0.6   # мокрый кот (дождеватель парка)

var camera_rig: CameraRig
var current_hideout: Area3D
var hidden := false
var in_safe_zone := false   # внутри будки пряжи: удары не проходят, собака не видит
var input_enabled := true   # false, пока открыт экран магазина
var stunned_left := 0.0
var invulnerable_left := 0.0
var drowning_left := 0.0   # кот тонет: потом возврат на берег (вода, план 12)
var _shore := Vector3.ZERO
var face := CatFace.new()   # выражения глаз, переключает меши eyes_* модели
var fade := 1.0   # 1 = непрозрачен; значением владеет камера (set_fade), скин его не трогает
var was_on_floor := true
var wet_left := 0.0
var petted_left := 0.0   # ребёнок гладит: кот стоит, не ранен
var _drips: CPUParticles3D
var flashing := false
var _run_dust_t := 0.0
var _squash: Tween
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
	Toon.apply(_model, Toon.OUTLINE_CHARACTER, true)
	for mi in _model.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name).begins_with("eyes_") or mi.name == "whiskers" or mi.name == "eyelids":
			(mi as MeshInstance3D).material_overlay = null   # обводка на глазах — рамка, на усах и веках — клякса
	face.bind(_model)
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
		var ls := LegScaler.new()
		ls.name = "LegScaler"
		skel.add_child(ls)
		var tw := TailWiggle.new()
		tw.name = "TailWiggle"
		skel.add_child(tw)
	if camera_rig:
		(camera_rig.get_node("SpringArm3D") as SpringArm3D).add_excluded_object(get_rid())
	play_clip(&"idle")


func _physics_process(delta: float) -> void:
	face.update(delta, stunned_left > 0.0)
	if wet_left > 0.0:
		wet_left = maxf(wet_left - delta, 0.0)
		if _drips:
			_drips.emitting = wet_left > 0.0
	stunned_left = maxf(stunned_left - delta, 0.0)
	invulnerable_left = maxf(invulnerable_left - delta, 0.0)
	petted_left = maxf(petted_left - delta, 0.0)
	if drowning_left > 0.0:
		drowning_left = maxf(drowning_left - delta, 0.0)
		velocity = Vector3(0, -0.4, 0)   # медленно уходит под воду
		global_position += velocity * delta
		if drowning_left == 0.0:
			teleport(_shore)
			if camera_rig:
				camera_rig.global_position = global_position + Vector3(0, CameraRig.HEIGHT, 0)   # камера не летит через воду
		return
	if stunned_left > 0.0 or petted_left > 0.0:
		velocity = CatMotion.step(velocity, Vector3.ZERO, false, is_on_floor(), false, delta)
		move_and_slide()
		return
	if not input_enabled:
		velocity = CatMotion.step(velocity, Vector3.ZERO, false, is_on_floor(), false, delta)
		move_and_slide()
		state = CatMotion.pick_state(velocity, is_on_floor(), false)
		_after_move(delta)
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
	velocity = CatMotion.step(velocity, dir, running, is_on_floor(), jump, delta, GameState.speed_mult * speed_factor())
	move_and_slide()
	if dir.length() > 0.0:
		var target_yaw := atan2(-dir.x, -dir.z)
		_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, TURN_SPEED * delta)
	state = CatMotion.pick_state(velocity, is_on_floor(), running, GameState.speed_mult * speed_factor())
	_after_move(delta)


func _after_move(delta: float) -> void:
	## Приземление: сплющить и пыль; прыжок: вытянуться; бег: пыль каждые 0,25 с.
	var on_floor := is_on_floor()
	if on_floor and not was_on_floor:
		squash(0.8, 0.12)
		Effects.dust(get_parent(), global_position)
	elif not on_floor and was_on_floor and velocity.y > 1.0:
		squash(1.15, 0.1)
	was_on_floor = on_floor
	if state == &"run" and on_floor:
		_run_dust_t += delta
		if _run_dust_t >= RUN_DUST_EVERY:
			_run_dust_t = 0.0
			Effects.dust(get_parent(), global_position, 6)
	else:
		_run_dust_t = 0.0


func squash(scale_y: float, duration := 0.12) -> void:
	## Сквош-стретч модели твином, объём сохраняется (спек 2.8).
	if _squash:
		_squash.kill()
	_model.scale = Vector3(1.0 / sqrt(scale_y), scale_y, 1.0 / sqrt(scale_y))
	_squash = create_tween()
	_squash.tween_property(_model, "scale", Vector3.ONE, duration * 2.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func flash(seconds := 0.1) -> void:
	## Вспышка белым при ударе: только три материала скина; после — цвета надетого скина и текущая прозрачность.
	flashing = true
	for mi in _model.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null:
			continue
		for i in m3.mesh.get_surface_count():
			var m := m3.get_surface_override_material(i) as StandardMaterial3D
			if m and CatSkin.ROLE_BY_MATERIAL.has(m.resource_name):
				m.albedo_color = Color(FLASH_COLOR, m.albedo_color.a)
	get_tree().create_timer(seconds, false).timeout.connect(func() -> void:
		flashing = false
		_apply_skin(GameState.skin))


func _apply_skin(id: StringName) -> void:
	var skin := SkinCatalog.get_by_id(id)
	if skin == null:
		skin = SkinCatalog.get_by_id(GameState.DEFAULT_SKIN)   # битый сейв: не оставлять кота белым после вспышки
	if skin and not flashing:   # во время вспышки скин перекрасится по её концу
		CatSkin.apply(_model, skin)
		if fade < 1.0:
			_apply_fade()   # перекраска сбрасывает альфу, прозрачность у стены должна остаться


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
	face.cheer()
	ate.emit(items)
	return true


func take_hit(from: Vector3) -> void:
	if drowning_left > 0.0:
		return   # в воде сердечко не снимается (спек порта, раздел 2)
	if not _hit_reaction(from):
		return
	GameState.take_hit()


func take_peck(from: Vector3) -> void:
	## Чайка (спек порта, раздел 3): удар, последняя еда унесена, остальное остаётся в зубах.
	if drowning_left > 0.0:
		return
	if not _hit_reaction(from):
		return
	GameState.peck()


func _hit_reaction(from: Vector3) -> bool:
	## Общая реакция на удар; false — удар не прошёл (неуязвим, оглушён, спрятан, в будке).
	if invulnerable_left > 0.0 or stunned_left > 0.0 or hidden or in_safe_zone:
		return false
	Sfx.play(&"hit")   # один вызов на реальный удар: повторные касания блокирует неуязвимость
	Sfx.play(&"meow", 0.12)
	flash()
	if camera_rig:
		camera_rig.shake()
	var away := global_position - from
	away.y = 0.0
	if away.length() < 0.01:
		away = _model.global_transform.basis.z   # назад относительно взгляда
	velocity = away.normalized() * KNOCKBACK_SPEED + Vector3.UP * KNOCKBACK_UP
	stunned_left = STUN_TIME
	invulnerable_left = INVULNERABLE_TIME
	state = &"hit"
	hit_taken.emit(from)
	return true


func set_fade(alpha: float) -> void:
	if is_equal_approx(alpha, fade):
		return
	fade = alpha
	_apply_fade()


func _apply_fade() -> void:
	for mi in _model.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null:
			continue
		for i in m3.mesh.get_surface_count():
			_fade_material(m3.get_surface_override_material(i) as StandardMaterial3D)
		var outline := m3.material_overlay as ShaderMaterial
		if outline:
			outline.set_shader_parameter("alpha", fade)


func _fade_material(mat: StandardMaterial3D) -> void:
	if mat == null:
		return
	mat.albedo_color.a = fade
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED if fade >= 0.999 else BaseMaterial3D.TRANSPARENCY_ALPHA
	# Полупрозрачное тело всё равно пишет глубину: иначе дальняя сторона hull-обводки рисуется поверх кота («рентген»).
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY if fade >= 0.999 else BaseMaterial3D.DEPTH_DRAW_ALWAYS


func pet(seconds: float) -> bool:
	if drowning_left > 0.0:
		return false
	## Поймал ребёнок: 2 с стоим довольные, еда выпала, сердечко цело; потом неуязвимость, как после удара.
	if petted_left > 0.0 or invulnerable_left > 0.0 or hidden or in_safe_zone:
		return false
	petted_left = seconds
	invulnerable_left = seconds + INVULNERABLE_TIME
	velocity = Vector3.ZERO
	face.cheer()
	face.happy_left = seconds
	state = &"idle"
	Sfx.play(&"meow", 0.2)
	GameState.pet()
	return true


func wet(seconds: float) -> void:
	## Намок под дождевателем: замедление ×0,6; повторное намокание продлевает до большего срока, не складывается.
	wet_left = maxf(wet_left, seconds)
	if _drips == null:
		_drips = Effects.trail(self, Color("#9FD3F0"), 8)
		_drips.name = "Drips"
		_drips.position = Vector3(0, 0.2, 0)
	_drips.emitting = true


func speed_factor() -> float:
	return WET_SLOW if wet_left > 0.0 else 1.0


func threaten() -> void:
	## Собака насторожилась или гонится рядом: зовётся каждый физический кадр, пока угроза есть.
	face.threaten()


func cheer() -> void:
	face.cheer()


func drown(shore: Vector3) -> bool:
	## Упал в воду (спек порта, раздел 2): 1 с тонет, еда из зубов потеряна, сердечко цело; затем ближайший берег.
	if drowning_left > 0.0:
		return false
	drowning_left = 1.0
	_shore = shore
	unhide()
	GameState.spill()   # не рассыпается — уходит на дно
	Sfx.play(&"splash")
	Effects.burst(get_parent(), global_position + Vector3(0, 0.2, 0), Color("#2F9CCF"), 28, 0.06, 2.5)
	squash(0.6, 0.2)
	state = &"idle"   # не продолжать клип бега под водой
	return true


func teleport(pos: Vector3) -> void:
	unhide()
	global_position = pos
	velocity = Vector3.ZERO
	stunned_left = 0.0
	invulnerable_left = INVULNERABLE_TIME   # после возрождения дать прийти в себя
	wet_left = 0.0
	petted_left = 0.0
	drowning_left = 0.0
	if _drips:
		_drips.emitting = false
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
