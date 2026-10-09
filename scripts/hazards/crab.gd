class_name Crab
extends HazardBase
## Краб (спек порта, раздел 3): сидит в норке; кот ближе 3 м (ночью 4 м) — вылезает и бежит боком 2,4 м/с; прыжок кота над
## ним или 5 с погони — прячется в норку на 6 с. Касание — щипок (удар).

const NOTICE := 3.0
const NOTICE_NIGHT := 4.0
const CHASE_MAX := 5.0
const HIDE_TIME := 6.0


static func decide(state: StringName, dist: float, cat_above: bool, chase_t: float, hide_left: float, night: bool) -> StringName:
	match state:
		&"burrow":
			return &"chase" if dist < (NOTICE_NIGHT if night else NOTICE) else &"burrow"
		&"chase":
			return &"hide" if cat_above or chase_t >= CHASE_MAX else &"chase"
		&"hide":
			return &"hide" if hide_left > 0.0 else &"burrow"
	return state

const SPEED := 2.4
const ABOVE := 0.25

var state: StringName = &"burrow"
var night_only := false
var _chase_t := 0.0
var _hide_left := 0.0

@onready var _model: Node3D = $Model
@onready var _burrow: Node3D = $Burrow
@onready var _anim: AnimationPlayer = $Model.find_child("AnimationPlayer", true, false)


func configure(hz: Dictionary, _builder: Node3D) -> void:
	night_only = bool(hz.get("night_only", false))


func _ready() -> void:
	super()
	walk_speed = SPEED
	Toon.apply(_model, Toon.OUTLINE_CHARACTER, true)
	for clip in ["idle", "walk"]:
		if _anim and _anim.has_animation(clip):
			_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	_set_out(false)


func _set_out(out: bool) -> void:
	## В норке краба не видно и он не мешает и не щиплет.
	_model.visible = out
	collision_layer = 0   # маленький краб не твёрдый: иначе он толкает кота телом (щипок — через HitZone)
	hit_zone.monitoring = out


func _physics_process(delta: float) -> void:
	_ensure_home()
	_burrow.global_position = home
	var night := DayNight.is_night(get_tree())
	var c := _find_cat()
	var dist := 99.0
	var above := false
	if c and not bool(c.get("hidden")) and not bool(c.get("in_safe_zone")):
		var d := c.global_position - global_position
		dist = Vector2(d.x, d.z).length()
		above = d.y > ABOVE and dist < 0.5
	if night_only and not night and state == &"burrow":
		return   # ночной краб днём сидит в норке
	var sees: bool = c != null and not bool(c.get("hidden")) and not bool(c.get("in_safe_zone"))
	var watch := dist   # из норки краб сторожит округу норки, в погоне — меряет до кота
	if state == &"burrow":
		watch = Vector2(c.global_position.x - home.x, c.global_position.z - home.z).length() if sees else 99.0
	var next := decide(state, watch, above, _chase_t, _hide_left, night)
	if state == &"chase" and not sees:
		next = &"hide"   # кот спрятался или ушёл в будку — краб уходит (ревью плана 14)
	if next != state:
		if next == &"chase":
			_chase_t = 0.0
			_set_out(true)
		elif next == &"hide":
			_hide_left = HIDE_TIME
		elif next == &"burrow":
			global_position = home
			_set_out(false)
		state = next
	match state:
		&"burrow":
			velocity = Vector3.ZERO
		&"chase":
			_chase_t += delta
			if c:
				_run_to(c.global_position, delta)
			for b in hit_zone.get_overlapping_bodies():
				_on_hit_body(b)
		&"hide":
			_hide_left = maxf(_hide_left - delta, 0.0)
			if _run_to(home, delta) < 0.15 and _model.visible:
				_set_out(false)   # забрался в норку; ждёт, пока выйдет время


func _run_to(target: Vector3, delta: float) -> float:
	var left := move_towards_point(target, SPEED, delta)
	_model.rotation.y = PI / 2.0   # бежит боком: клешни смотрят в сторону, ход — вдоль корпуса
	if _anim and _anim.has_animation("walk") and _anim.current_animation != "walk":
		_anim.play("walk", 0.15)
	return left


func _on_hit_body(body: Node3D) -> void:
	if state == &"chase" and body.is_in_group("cat"):
		super(body)
		state = &"hide"   # ущипнул — уходит: один краб — одно сердечко за погоню
		_hide_left = HIDE_TIME
