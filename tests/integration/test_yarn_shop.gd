extends GutTest

const ShopScene := preload("res://scenes/world/yarn_shop.tscn")
const CatScene := preload("res://scenes/player/cat.tscn")
const RigScene := preload("res://scenes/player/camera_rig.tscn")

var world: Node3D
var cat
var rig
var shop

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
	shop = ShopScene.instantiate()
	world.add_child(shop)
	shop.global_position = Vector3(0, 0, -5)
	rig = RigScene.instantiate()
	cat = CatScene.instantiate()
	cat.camera_rig = rig
	rig.target = cat
	world.add_child(rig)
	world.add_child(cat)

func test_zone_flags_cat_and_blocks_hits() -> void:
	cat.global_position = Vector3(0, 0.05, -5)
	await wait_physics_frames(3)
	assert_true(shop.cat_inside)
	assert_true(cat.in_safe_zone)
	cat.take_hit(Vector3(1, 0, -5))
	assert_eq(GameState.hearts, 3, "в будке не бьют")
	cat.global_position = Vector3(0, 0.05, 0)
	await wait_physics_frames(3)
	assert_false(cat.in_safe_zone)

func test_respawn_position_is_inside_zone() -> void:
	var p: Vector3 = shop.respawn_position()
	assert_lt(p.distance_to(Vector3(0, 0, -5)), 1.0)

func test_input_disabled_keeps_cat_still() -> void:
	cat.global_position = Vector3(0, 0.05, 0)
	await wait_physics_frames(3)
	cat.input_enabled = false
	Input.action_press("move_forward")
	await wait_physics_frames(30)
	Input.action_release("move_forward")
	assert_lt(cat.global_position.distance_to(Vector3(0, 0.05, 0)), 0.1)
	assert_eq(cat.state, &"idle")

func test_shop_view_moves_camera_near_cat() -> void:
	cat.global_position = Vector3(0, 0.05, -5)
	rig.global_position = Vector3(0, 0.6, -3)
	rig.shop_view = true
	await wait_seconds(0.8)
	var expected: Vector3 = cat.global_position + CameraRig.SHOP_OFFSET
	assert_lt(rig.global_position.distance_to(expected), 0.3)
	rig.shop_view = false

func test_yarn_play_balls_move() -> void:
	var play := shop.get_node("YarnPlay") as Node3D
	assert_eq(play.get_child_count(), 3)
	var p0: Vector3 = (play.get_child(0) as Node3D).position
	await wait_seconds(0.3)
	assert_gt((play.get_child(0) as Node3D).position.distance_to(p0), 0.05, "клубочки катаются")

func test_shop_view_makes_cat_visible_even_if_camera_was_pinned() -> void:
	cat.global_position = Vector3(0, 0.05, -5)
	cat.visible = false   # камера упиралась в стенку и спрятала кота
	rig.shop_view = true
	await wait_physics_frames(2)
	assert_true(cat.visible, "в витрине кот всегда виден")
	rig.shop_view = false

func test_floor_plate_is_solid() -> void:
	await wait_physics_frames(2)
	var space := world.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(Vector3(0, 1, -5), Vector3(0, -1, -5), Layers.WORLD)
	var hit := space.intersect_ray(q)
	assert_false(hit.is_empty(), "луч вниз в будке во что-то упирается")
	if not hit.is_empty():
		assert_almost_eq((hit["position"] as Vector3).y, 0.03, 0.005, "упирается в плиту будки, а не в землю")
