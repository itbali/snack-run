extends GutTest

const HideoutScene := preload("res://scenes/hideouts/hideout.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")
const RigScene := preload("res://scenes/player/camera_rig.tscn")

var world: Node3D
var cat
var rig

func before_each() -> void:
	GameState.reset()
	world = Node3D.new()
	add_child_autofree(world)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 0.2, 20)
	shape.shape = box
	shape.position.y = -0.1
	floor_body.add_child(shape)
	world.add_child(floor_body)
	rig = RigScene.instantiate()
	cat = CatScene.instantiate()
	cat.camera_rig = rig
	rig.target = cat
	world.add_child(rig)
	world.add_child(cat)
	cat.global_position = Vector3(0, 0.05, 0)

func _hideout_at(pos: Vector3) -> Node:
	var h = HideoutScene.instantiate()
	h.kind = &"box"
	world.add_child(h)
	h.global_position = pos
	return h

func test_cannot_hide_outside_hideout() -> void:
	_hideout_at(Vector3(5, 0, 5))
	await wait_physics_frames(3)
	assert_false(cat.try_hide())
	assert_false(cat.hidden)

func test_hide_inside_sets_state_and_lowers_camera() -> void:
	var h = _hideout_at(Vector3(0, 0.2, 0))
	await wait_physics_frames(3)
	assert_true(h.cat_inside)
	assert_true(cat.try_hide())
	assert_true(cat.hidden)
	assert_eq(cat.state, &"hide")
	assert_true(rig.crouch)
	cat.unhide()
	assert_false(cat.hidden)
	assert_false(rig.crouch)

func test_eat_only_when_hidden_with_food() -> void:
	_hideout_at(Vector3(0, 0.2, 0))
	await wait_physics_frames(3)
	GameState.pick_up(FoodCatalog.get_by_id(&"sausage"))
	assert_false(cat.try_eat(), "не спрятан — не ест")
	cat.try_hide()
	watch_signals(cat)
	assert_true(cat.try_eat())
	assert_eq(GameState.mouth.size(), 0)
	assert_eq(GameState.satiety, 1)
	assert_signal_emitted(cat, "ate")
	assert_false(cat.try_eat(), "рот пуст — нечего есть")

func test_movement_input_leaves_hideout() -> void:
	_hideout_at(Vector3(0, 0.2, 0))
	await wait_physics_frames(3)
	cat.try_hide()
	Input.action_press("move_forward")
	await wait_physics_frames(3)
	Input.action_release("move_forward")
	assert_false(cat.hidden)

# --- План 19: укрытия понятнее (просьба владельца: «кот исчезает, а у укрытия появляются глаза») ---

func test_zone_is_a_bit_larger_than_data_size() -> void:
	var h = _hideout_at(Vector3(0, 0.2, 0))
	cat.global_position = Vector3(0.5, 0.05, 0)   # раньше зона 0,6 м — до края 0,3 м
	await wait_physics_frames(4)
	assert_true(cat.try_hide(), "в 0,5 м от центра уже укрытие")

func test_hidden_cat_vanishes_and_hideout_shows_eyes() -> void:
	var h = _hideout_at(Vector3(0, 0.2, 0))
	await wait_physics_frames(3)
	assert_true(cat.try_hide())
	await wait_process_frames(2)
	assert_false(cat.get_node("Model").visible, "кот исчез")
	var eyes := h.get_node("Eyes") as Node3D
	assert_true(eyes.visible, "в укрытии глаза")
	cat.unhide()
	await wait_process_frames(2)
	assert_true(cat.get_node("Model").visible)
	assert_false(eyes.visible)

func test_eyes_squint_happily_when_eating() -> void:
	var h = _hideout_at(Vector3(0, 0.2, 0))
	await wait_physics_frames(3)
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	cat.try_hide()
	cat.try_eat()
	await wait_process_frames(2)
	assert_lt((h.get_node("Eyes") as Node3D).scale.y, 0.6, "довольно жмурится")

func test_ring_glows_only_with_food_in_mouth() -> void:
	var h = _hideout_at(Vector3(3, 0.2, 0))
	await wait_process_frames(3)
	var ring := h.get_node("Ring") as Node3D
	assert_false(ring.visible, "без еды рамки нет")
	GameState.pick_up(FoodCatalog.get_by_id(&"cookie"))
	await wait_process_frames(3)
	assert_true(ring.visible, "с едой укрытие подсвечено")

func test_prompts() -> void:
	assert_eq(Hud.prompt_for(true, false, 0, false), "%s — спрятаться" % KeyBindings.key_name("hide"))
	assert_eq(Hud.prompt_for(true, true, 2, false), "%s — съесть" % KeyBindings.key_name("eat"))
	assert_eq(Hud.prompt_for(true, true, 0, false), "%s — выйти" % KeyBindings.key_name("hide"))
	assert_eq(Hud.prompt_for(false, false, 0, true), "%s — магазин" % KeyBindings.key_name("eat"))
	assert_eq(Hud.prompt_for(false, false, 3, false), "", "вне укрытия подсказки нет")

func test_eyes_not_hidden_behind_prop_from_camera() -> void:
	# План 19, кадр: камера по другую сторону коробки — коробка закрывала глаза. Глаза — перед препятствием, к камере.
	var h = _hideout_at(Vector3(0, 0.2, 0))
	var wall := StaticBody3D.new()
	wall.collision_layer = Layers.WORLD
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 0.6, 0.1)
	cs.shape = box
	wall.add_child(cs)
	wall.position = Vector3(0, 0.3, -0.3)
	world.add_child(wall)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.global_position = Vector3(0, 1.0, -2.0)
	cam.current = true
	await wait_physics_frames(3)
	cat.try_hide()
	await wait_process_frames(3)
	var eyes := h.get_node("Eyes") as Node3D
	var space := world.get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(eyes.global_position, cam.global_position, Layers.WORLD))
	assert_true(hit.is_empty(), "между глазами и камерой ничего: %s" % [eyes.global_position])

func test_eyes_peek_over_low_box_seen_from_above() -> void:
	# Кадр плана 19: камера сверху-сзади, луч упирался в верх коробки — глаза оказывались внутри неё.
	var h = _hideout_at(Vector3(0, 0.2, 0))
	var b := StaticBody3D.new()
	b.collision_layer = Layers.WORLD
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.45, 0.3, 0.35)
	cs.shape = box
	cs.position.y = 0.15
	b.add_child(cs)
	b.position = Vector3(0, 0, -0.65)
	world.add_child(b)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.global_position = Vector3(0, 0.75, -1.75)
	cam.current = true
	await wait_physics_frames(3)
	cat.try_hide()
	await wait_process_frames(3)
	var eyes := h.get_node("Eyes") as Node3D
	var q := PhysicsPointQueryParameters3D.new()
	q.position = eyes.global_position
	q.collision_mask = Layers.WORLD
	assert_eq(world.get_world_3d().direct_space_state.intersect_point(q).size(), 0, "глаза не внутри коробки: %s" % [eyes.global_position])
	var hit := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(cam.global_position, eyes.global_position, Layers.WORLD))
	assert_true(hit.is_empty(), "камера видит глаза")

# --- Ревью плана 19 ---

func _car_with_hideout() -> Node:
	var b := WorldBuilder.new()
	world.add_child(b)
	b.build({"props": [{"model": "car", "pos": [4, 0, 0], "rot": 0, "colliders": [{"size": [1.7, 1.2, 3.6], "offset": [0, 0.9, 0]}]}],
		"hideouts": [{"kind": "car", "pos": [4, 0.15, 0], "size": [1.4, 0.3, 3.2]}]})
	return b.find_children("*", "Hideout", true, false)[0]

func test_eyes_visible_from_rig_when_hiding_under_car() -> void:
	var h = _car_with_hideout()
	cat.global_position = Vector3(4, 0.05, 1.2)
	rig.global_position = cat.global_position + Vector3(0, 0.6, 0)
	await wait_physics_frames(5)
	assert_true(cat.try_hide())
	await wait_physics_frames(40)
	var cam := rig.get_node("SpringArm3D/Camera3D") as Camera3D
	var eyes := h.get_node("Eyes") as Node3D
	var space := world.get_world_3d().direct_space_state
	var q := PhysicsPointQueryParameters3D.new()
	q.position = cam.global_position
	q.collision_mask = Layers.WORLD
	assert_eq(space.intersect_point(q).size(), 0, "камера не внутри машины: %s" % [cam.global_position])
	assert_true(cam.is_position_in_frustum(eyes.global_position), "глаза в кадре")
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(cam.global_position, eyes.global_position, Layers.WORLD))
	assert_true(hit.is_empty(), "камера видит глаза под машиной")

func test_cannot_hide_standing_on_box_top() -> void:
	_hideout_at(Vector3(0, 0.2, 0))
	cat.global_position = Vector3(0, 0.62, 0)   # верх коробки ~0,3–0,5 над землёй
	var top := StaticBody3D.new()
	top.collision_layer = Layers.WORLD
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1, 0.1, 1)
	cs.shape = box
	top.add_child(cs)
	top.position = Vector3(0, 0.5, 0)
	world.add_child(top)
	await wait_physics_frames(5)
	assert_false(cat.try_hide(), "на крышке не прячутся")

func test_outline_matches_zone() -> void:
	var h = _hideout_at(Vector3(0, 0.2, 0))
	h.rotation_degrees.y = 90
	await wait_process_frames(2)
	var zone := (h.get_node("Collision") as CollisionShape3D).shape as BoxShape3D
	var outline: Vector2 = h.call("outline_size")
	assert_almost_eq(outline.x, zone.size.x, 0.01)
	assert_almost_eq(outline.y, zone.size.z, 0.01)
	assert_true((h.get_node("Ring") as Node3D).rotation == Vector3.ZERO, "рамка поворачивается вместе с укрытием (локально)")

func test_eyes_cast_no_shadow() -> void:
	var h = _hideout_at(Vector3(0, 0.2, 0))
	for mi in h.get_node("Eyes").get_children():
		assert_eq((mi as GeometryInstance3D).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
