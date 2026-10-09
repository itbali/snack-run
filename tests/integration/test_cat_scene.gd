extends GutTest

const CAT_SCENE := "res://scenes/player/cat.tscn"
const RIG_SCENE := "res://scenes/player/camera_rig.tscn"

func _spawn() -> Node:
	var scene := load(CAT_SCENE) as PackedScene
	assert_not_null(scene, "нет сцены cat.tscn")
	var cat := scene.instantiate()
	add_child_autofree(cat)
	return cat

func test_cat_starts_idle_with_toon_materials() -> void:
	var cat = _spawn()
	assert_eq(cat.state, &"idle")
	var mesh := cat.find_child("cat", true, false) as MeshInstance3D   # первым ребёнком скелета может быть набор глаз без обводки
	assert_not_null(mesh.material_overlay, "обводка должна быть установлена")
	assert_eq((mesh.get_surface_override_material(0) as StandardMaterial3D).diffuse_mode, BaseMaterial3D.DIFFUSE_TOON)

func test_play_clip_uses_generated_run_and_falls_back_for_unknown() -> void:
	var cat = _spawn()
	var ap := cat.find_child("AnimationPlayer", true, false) as AnimationPlayer
	cat.play_clip(&"run")
	assert_eq(ap.current_animation, "run")
	assert_almost_eq(ap.speed_scale, 1.0, 0.001)
	cat.play_clip(&"somersault")
	assert_eq(ap.current_animation, "idle", "неизвестный клип уходит в idle")
	cat.play_clip(&"idle")
	assert_eq(ap.current_animation, "idle")

var _captured_head_scale := Vector3.ZERO

func test_head_is_scaled() -> void:
	var cat = _spawn()
	var skel := cat.find_child("Skeleton3D", true, false) as Skeleton3D
	var idx := skel.find_bone("head")
	# Skeleton3D восстанавливает базовую позу после модификаторов, поэтому итог
	# читается только в skeleton_updated (сразу после применения модификаторов).
	skel.skeleton_updated.connect(func() -> void:
		_captured_head_scale = skel.get_bone_global_pose(idx).basis.get_scale())
	await wait_process_frames(3)
	assert_almost_eq(_captured_head_scale.x, 1.4, 0.01)

func _body_outline(cat) -> ShaderMaterial:
	return (cat.find_child("cat", true, false) as MeshInstance3D).material_overlay as ShaderMaterial

func _body_material(cat) -> StandardMaterial3D:
	for mi in cat.find_children("*", "MeshInstance3D", true, false):
		for i in (mi as MeshInstance3D).mesh.get_surface_count():
			var m := (mi as MeshInstance3D).get_surface_override_material(i) as StandardMaterial3D
			if m and m.resource_name == "sr_cat_orange":
				return m
	return null

func test_camera_rig_fades_target_instead_of_hiding() -> void:
	# Отложенное замечание ревью плана 1: у стены кот исчезал целиком.
	var cat = _spawn()
	var rig = (load(RIG_SCENE) as PackedScene).instantiate()
	rig.target = cat
	add_child_autofree(rig)
	rig.apply_arm_length(0.5)   # упор в стену
	assert_true(cat.visible, "кот не исчезает")
	assert_lt(cat.fade, 0.5)
	var body := _body_material(cat)
	assert_eq(body.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA)
	assert_almost_eq(body.albedo_color.a, cat.fade, 0.01)
	var outline := _body_outline(cat)
	assert_almost_eq(float(outline.get_shader_parameter("alpha")), cat.fade, 0.01, "обводка тоже полупрозрачна (Review Focus 2)")
	rig.apply_arm_length(3.5)
	assert_almost_eq(cat.fade, 1.0, 0.001, "отошли от стены — непрозрачен")
	assert_eq(_body_material(cat).transparency, BaseMaterial3D.TRANSPARENCY_DISABLED)
	assert_almost_eq(float(_body_outline(cat).get_shader_parameter("alpha")), 1.0, 0.001)

func test_skin_change_keeps_fade() -> void:
	# Review Focus 4
	GameState.reset()
	GameState.add_yarn(12)
	var cat = _spawn()
	cat.set_fade(0.4)
	GameState.buy(ShopCatalog.get_by_id(&"skin_black"))
	await wait_process_frames(1)
	assert_almost_eq(_body_material(cat).albedo_color.a, 0.4, 0.01, "скин не возвращает непрозрачность")
	assert_almost_eq(float(_body_outline(cat).get_shader_parameter("alpha")), 0.4, 0.01, "и обводка остаётся полупрозрачной")
	GameState.reset()

func test_mouse_turns_camera() -> void:
	var rig = (load(RIG_SCENE) as PackedScene).instantiate()
	add_child_autofree(rig)
	var before: Basis = rig.yaw_basis()
	rig.turn_by_pixels(100.0)
	assert_false(rig.yaw_basis().is_equal_approx(before), "100 px мыши поворачивают камеру")

func test_locomotion_clips_loop() -> void:
	# Ревью: idle/walk/run без зацикливания останавливаются через 1,7 с.
	var cat = _spawn()
	var ap := cat.find_child("AnimationPlayer", true, false) as AnimationPlayer
	for clip in ["idle", "walk", "run", "hide"]:
		assert_eq(ap.get_animation(clip).loop_mode, Animation.LOOP_LINEAR, "клип %s должен зацикливаться" % clip)

func test_cat_recolors_on_skin_change() -> void:
	GameState.reset()
	GameState.add_yarn(12)
	var cat = _spawn()
	GameState.buy(ShopCatalog.get_by_id(&"skin_black"))
	await wait_process_frames(1)
	var found := false
	for mi in cat.find_children("*", "MeshInstance3D", true, false):
		for i in (mi as MeshInstance3D).mesh.get_surface_count():
			var m := (mi as MeshInstance3D).get_surface_override_material(i) as StandardMaterial3D
			if m and m.resource_name == "sr_cat_orange":
				found = true
				assert_eq(m.albedo_color.to_html(false), "394151", "тело перекрашено в чёрный")
	assert_true(found, "у кота есть поверхность тела")
	GameState.reset()

func test_eye_sets_exist_and_only_normal_is_visible() -> void:
	var cat = _spawn()
	var names := []
	for mi in cat.find_children("eyes_*", "MeshInstance3D", true, false):
		names.append(String(mi.name))
		assert_null((mi as MeshInstance3D).material_overlay, "у глаз нет обводки: 6 мм на 3-см глазу — рамка")
	names.sort()
	assert_eq(names, ["eyes_blink", "eyes_dizzy", "eyes_happy", "eyes_normal", "eyes_scared"])
	assert_eq(cat.face.expression, &"normal")
	assert_true(cat.find_child("eyes_normal", true, false).visible)
	assert_false(cat.find_child("eyes_scared", true, false).visible)

func test_expression_priority_and_timers() -> void:
	# Review Focus 2
	GameState.reset()
	var cat = _spawn()
	await wait_physics_frames(2)
	cat.cheer()
	await wait_physics_frames(2)
	assert_eq(cat.face.expression, &"happy")
	assert_true(cat.find_child("eyes_happy", true, false).visible)
	cat.threaten()
	await wait_physics_frames(2)
	assert_eq(cat.face.expression, &"scared", "испуг важнее довольного")
	cat.take_hit(cat.global_position + Vector3(1, 0, 0))
	await wait_physics_frames(2)
	assert_eq(cat.face.expression, &"dizzy", "оглушение важнее всего")
	await wait_seconds(1.3)   # STUN_TIME 1,0; испуг (0,4) и довольство (1,0) к этому времени погасли
	assert_eq(cat.face.expression, &"normal", "все выражения снимаются сами")
	assert_true(cat.find_child("eyes_normal", true, false).visible)

func test_black_skin_keeps_eye_colors() -> void:
	# Review Focus 1
	GameState.reset()
	GameState.add_yarn(12)
	var cat = _spawn()
	GameState.buy(ShopCatalog.get_by_id(&"skin_black"))
	await wait_process_frames(1)
	var eyes := cat.find_child("eyes_normal", true, false) as MeshInstance3D
	var white := false
	var ink := false
	for i in eyes.mesh.get_surface_count():
		var c := (eyes.get_surface_override_material(i) as StandardMaterial3D).albedo_color
		if c.r > 0.9 and c.g > 0.9 and c.b > 0.85:
			white = true
		if c.r < 0.3 and c.g < 0.3 and c.b < 0.4:
			ink = true
	assert_true(white, "белок остался светлым при чёрном скине")
	assert_true(ink, "зрачок графитовый")
	GameState.reset()

func test_blink_only_over_normal_and_releases() -> void:
	# Review Focus 4
	GameState.reset()
	var cat = _spawn()
	await wait_physics_frames(2)
	cat.face.blink_in = 0.0
	await wait_physics_frames(2)
	assert_eq(cat.face.expression, &"blink", "пора моргнуть")
	assert_true(cat.find_child("eyes_blink", true, false).visible)
	await wait_seconds(0.3)
	assert_eq(cat.face.expression, &"normal", "глаза открылись через 0,12 с")
	cat.threaten()
	cat.face.blink_in = 0.0
	await wait_physics_frames(2)
	assert_eq(cat.face.expression, &"scared", "испуг не перебивается морганием")

const FEET := ["Bone.016", "Bone.019", "Bone.010", "Bone.013"]
var _world := {}   # ключ -> {кость: мировая позиция}

func _capture_world(skel: Skeleton3D, key: String) -> void:
	skel.skeleton_updated.connect(func() -> void:
		var d := {}
		for b in FEET + ["Bone"]:
			d[b] = skel.global_transform * skel.get_bone_global_pose(skel.find_bone(b)).origin
		_world[key] = d)

func test_short_legs_keep_feet_on_the_ground() -> void:
	# Review Focus 3 (ревью плана 5): мерить в мировых координатах — ось Y скелета кота идёт вдоль тела, верх — +Z скелета.
	var plain := (load("res://assets/models/cat.glb") as PackedScene).instantiate()
	var short := (load("res://assets/models/cat.glb") as PackedScene).instantiate()
	add_child_autofree(plain)
	add_child_autofree(short)
	var ls := LegScaler.new()
	short.find_child("Skeleton3D", true, false).add_child(ls)
	_capture_world(plain.find_child("Skeleton3D", true, false), "plain")
	_capture_world(short.find_child("Skeleton3D", true, false), "short")
	var scale: float = (short.find_child("Skeleton3D", true, false) as Skeleton3D).global_transform.basis.get_scale().y
	for clip in ["idle", "walk", "run"]:
		for n in [plain, short]:
			(n.find_child("AnimationPlayer", true, false) as AnimationPlayer).play(clip)
			(n.find_child("AnimationPlayer", true, false) as AnimationPlayer).seek(0.3, true)
		await wait_process_frames(3)
		assert_gt(ls.drop, 0.0, "просадка корня посчитана из rest-позы")
		for b in FEET:
			var dy: float = (_world["short"][b] as Vector3).y - (_world["plain"][b] as Vector3).y
			assert_almost_eq(dy, 0.0, 0.012, "%s: стопа %s на той же высоте (м)" % [clip, b])
		var root_d: Vector3 = (_world["short"]["Bone"] as Vector3) - (_world["plain"]["Bone"] as Vector3)
		assert_almost_eq(root_d.y, -ls.drop * scale, 0.006, "%s: корень опустился вниз на drop в метрах" % clip)
		assert_lt(Vector2(root_d.x, root_d.z).length(), 0.006, "%s: корень не уехал по горизонтали" % clip)

var _tail_basis := {}

func test_tail_wiggle_adds_motion_on_top_of_the_clip() -> void:
	# Два экземпляра на одном кадре idle: с TailWiggle и без; итог модификатора виден только в skeleton_updated.
	var plain := (load("res://assets/models/cat.glb") as PackedScene).instantiate()
	var wig := (load("res://assets/models/cat.glb") as PackedScene).instantiate()
	add_child_autofree(plain)
	add_child_autofree(wig)
	wig.find_child("Skeleton3D", true, false).add_child(TailWiggle.new())
	var pair := {"plain": plain, "wig": wig}
	for key in pair:
		var n: Node = pair[key]
		(n.find_child("AnimationPlayer", true, false) as AnimationPlayer).play("idle")
		var skel := n.find_child("Skeleton3D", true, false) as Skeleton3D
		var idx := skel.find_bone("Bone.006")
		skel.skeleton_updated.connect(func() -> void: _tail_basis[key] = skel.get_bone_global_pose(idx).basis)
	await wait_seconds(0.15)
	assert_false((_tail_basis["wig"] as Basis).is_equal_approx(_tail_basis["plain"]), "хвост с модификатором отличается от клипа на том же кадре")

func _spawn_on_floor() -> Node:
	var world := Node3D.new()
	add_child_autofree(world)
	var body := StaticBody3D.new()
	body.collision_layer = Layers.WORLD
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 0.2, 20)
	shape.shape = box
	shape.position.y = -0.1
	body.add_child(shape)
	world.add_child(body)
	var cat = (load(CAT_SCENE) as PackedScene).instantiate()
	cat.position = Vector3(0, 0.05, 0)
	world.add_child(cat)
	return cat

func test_landing_squashes_and_puffs_dust() -> void:
	var cat = _spawn_on_floor()
	await wait_physics_frames(10)
	Input.action_press("jump")   # velocity.y снаружи гасится шагом на полу: прыгаем по-настоящему
	await wait_physics_frames(3)
	Input.action_release("jump")
	assert_false(cat.is_on_floor())
	var before := get_tree().get_nodes_in_group("dust")
	var frames := 0
	while not cat.is_on_floor() and frames < 90:   # ждём сам момент приземления: твин сквоша живёт 0,24 с
		await wait_physics_frames(1)
		frames += 1
	assert_true(cat.is_on_floor(), "приземлился")
	var fresh := get_tree().get_nodes_in_group("dust").filter(func(n): return not before.has(n))
	assert_gt(fresh.size(), 0, "пыль при приземлении (новый узел, не стартовый)")
	var model := cat.get_node("Model") as Node3D
	assert_lt(model.scale.y, 0.95, "сплющен сразу после приземления")
	await wait_seconds(0.4)
	assert_almost_eq(model.scale.y, 1.0, 0.02, "форма вернулась")

func test_flash_turns_white_then_restores_skin() -> void:
	# Review Focus 1
	GameState.reset()
	GameState.add_yarn(12)
	var cat = _spawn()
	GameState.buy(ShopCatalog.get_by_id(&"skin_black"))
	await wait_process_frames(1)
	cat.flash(0.1)
	assert_true(cat.flashing)
	assert_eq(_body_material(cat).albedo_color.to_html(false), "ffffff", "вспышка белым")
	await wait_seconds(0.25)
	assert_false(cat.flashing)
	assert_eq(_body_material(cat).albedo_color.to_html(false), "394151", "после вспышки — цвет надетого скина, не базовый рыжий")
	GameState.reset()

func test_hit_flashes_and_shakes_camera() -> void:
	var cat = _spawn()
	var rig = (load(RIG_SCENE) as PackedScene).instantiate()
	rig.target = cat
	cat.camera_rig = rig
	add_child_autofree(rig)
	await wait_physics_frames(2)
	cat.take_hit(cat.global_position + Vector3(1, 0, 0))
	assert_true(cat.flashing)
	assert_gt(rig.shake_left, 0.0, "камера трясётся")
	await wait_physics_frames(2)
	assert_gt((rig.get_node("SpringArm3D") as SpringArm3D).position.length(), 0.001, "пружина смещена шумом")
