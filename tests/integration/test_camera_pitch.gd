extends GutTest
## План 18: камера вверх-вниз (мышь, клавиши, правый стик) с ограничениями; голова кота следует за взглядом.

const CatScene := preload("res://scenes/player/cat.tscn")
const RigScene := preload("res://scenes/player/camera_rig.tscn")

var cat
var rig

func before_each() -> void:
	cat = CatScene.instantiate()
	add_child_autofree(cat)
	rig = RigScene.instantiate()
	rig.target = cat
	add_child_autofree(rig)
	cat.camera_rig = rig
	await wait_physics_frames(2)

func test_pitch_is_clamped() -> void:
	assert_eq(CameraRig.clamp_pitch(-90.0), CameraRig.PITCH_MIN, "не выше, чем сверху вниз")
	assert_eq(CameraRig.clamp_pitch(60.0), CameraRig.PITCH_MAX, "не ниже, чем снизу вверх")
	assert_lt(CameraRig.PITCH_MIN, CameraRig.PITCH_DEG)
	assert_gt(CameraRig.PITCH_MAX, CameraRig.PITCH_DEG)

func test_mouse_and_keys_tilt_camera() -> void:
	var p0: float = rig.pitch
	rig.tilt_by_pixels(-100.0)   # мышь вверх — смотреть выше
	assert_gt(rig.pitch, p0)
	rig.tilt_by_pixels(10000.0)
	assert_eq(rig.pitch, CameraRig.PITCH_MIN, "мышь не перекручивает")
	Input.action_press("cam_up")
	await wait_physics_frames(20)
	Input.action_release("cam_up")
	assert_gt(rig.pitch, CameraRig.PITCH_MIN, "клавиша поднимает взгляд")
	assert_almost_eq((rig.get_node("SpringArm3D") as SpringArm3D).rotation_degrees.x, rig.pitch, 0.01)

func test_cat_head_follows_camera_pitch() -> void:
	rig.pitch = CameraRig.PITCH_MAX
	await wait_physics_frames(30)
	assert_gt(cat.head_look.pitch, 0.1, "камера смотрит вверх — кот поднимает голову")
	rig.pitch = CameraRig.PITCH_MIN
	await wait_physics_frames(30)
	assert_lt(cat.head_look.pitch, -0.1, "камера смотрит вниз — кот опускает голову")

var _head_up := {}

func test_head_look_actually_turns_head_bone() -> void:
	var skel := cat.find_child("Skeleton3D", true, false) as Skeleton3D
	var idx := skel.find_bone("head")
	var hl = cat.head_look
	skel.skeleton_updated.connect(func() -> void:
		var b := skel.global_transform.basis * skel.get_bone_global_pose(idx).basis
		_head_up[hl.pitch] = b.y.normalized().y)
	hl.smooth = 0.0
	hl.target_pitch = 0.0
	hl.pitch = 0.0
	await wait_process_frames(3)
	hl.target_pitch = 0.4
	hl.pitch = 0.4
	await wait_process_frames(3)
	assert_true(_head_up.has(0.0) and _head_up.has(0.4))
	if _head_up.has(0.0) and _head_up.has(0.4):
		assert_gt(_head_up[0.4], _head_up[0.0] + 0.05, "голова смотрит выше")

var _head_dir := {}

func test_head_yaw_turns_toward_camera_look() -> void:
	# Камера смотрит левее морды — голова поворачивается туда же (угол в мире растёт вместе с yaw).
	var skel := cat.find_child("Skeleton3D", true, false) as Skeleton3D
	var idx := skel.find_bone("head")
	var hl = cat.head_look
	skel.skeleton_updated.connect(func() -> void:
		var b := skel.global_transform.basis * skel.get_bone_global_pose(idx).basis
		var d := b.y
		_head_dir[hl.yaw] = atan2(-d.x, -d.z))
	hl.smooth = 0.0
	hl.target_yaw = 0.0
	await wait_process_frames(3)
	hl.target_yaw = 0.4
	await wait_process_frames(3)
	assert_true(_head_dir.has(0.0) and _head_dir.has(0.4))
	if _head_dir.has(0.0) and _head_dir.has(0.4):
		assert_gt(wrapf(_head_dir[0.4] - _head_dir[0.0], -PI, PI), 0.1, "голова повернулась в сторону взгляда")

func test_shop_view_ignores_pitch() -> void:
	# Ревью плана 18: наклон вниз перед будкой уводил кадр витрины ниже кота.
	rig.pitch = CameraRig.PITCH_MIN
	rig.shop_view = true
	Input.action_press("cam_down")
	await wait_physics_frames(10)
	Input.action_release("cam_down")
	assert_almost_eq((rig.get_node("SpringArm3D") as SpringArm3D).rotation_degrees.x, CameraRig.PITCH_DEG, 0.01, "витрина — прежний ракурс")
	assert_eq(rig.pitch, CameraRig.PITCH_MIN, "в витрине клавиши наклон не меняют")
	rig.shop_view = false

func test_head_resets_when_hiding() -> void:
	# Ревью плана 18: в укрытии, при ударе и в воде голова оставалась повёрнутой.
	rig.pitch = CameraRig.PITCH_MIN
	await wait_physics_frames(30)
	assert_lt(cat.head_look.target_pitch, -0.1)
	cat.hidden = true
	cat.state = &"hide"
	await wait_physics_frames(5)
	assert_almost_eq(cat.head_look.target_pitch, 0.0, 0.001, "в укрытии голова прямо")
	assert_almost_eq(cat.head_look.target_yaw, 0.0, 0.001)

func test_crouching_camera_does_not_lie_on_ground() -> void:
	rig.crouch = true
	rig.pitch = CameraRig.PITCH_MAX
	await wait_physics_frames(3)
	assert_lte((rig.get_node("SpringArm3D") as SpringArm3D).rotation_degrees.x, CameraRig.CROUCH_PITCH_MAX + 0.01, "в укрытии камера не ложится на траву")
	rig.crouch = false
