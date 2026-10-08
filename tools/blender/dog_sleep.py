"""Поза «спит» для собаки: процедурный клип. UniMate не дал позу лёжа
(docs/superpowers/notes/2026-10-07-unimate-attempt.md), поэтому поза задана числами:
корпус опущен на землю, лапы укорочены и их цели IK подняты, голова опущена к лапам;
дыхание — лёгкий подъём корпуса в середине клипа. Всё считается в пространстве арматуры (Z вверх)."""
import bpy
from mathutils import Quaternion, Vector

ROOT_BONE = "Bone"
HEAD_BONE = "head"
LEG_CHAINS = (("Bone.014", "Bone.015", "Bone.016"), ("Bone.017", "Bone.018", "Bone.019"),
              ("Bone.008", "Bone.009", "Bone.010"), ("Bone.011", "Bone.012", "Bone.013"))
IK_TARGETS = ("IKFrontRight", "IKFrontLeft", "IKBackLeft", "IKBackRight")
FRAMES = 48            # 2 с при 24 к/с
DROP_FRACTION = 0.62   # какую долю высоты корпуса над лапами убрать
LEG_SCALE = 0.45       # лапы вдоль своей оси
HEAD_TILT = 0.75       # рад, голова к лапам
BREATH = 0.10          # доля drop, на которую корпус приподнимается на вдохе


def reset_pose(arm):
	for pb in arm.pose.bones:
		pb.location = (0.0, 0.0, 0.0)
		pb.rotation_quaternion = (1.0, 0.0, 0.0, 0.0)
		pb.scale = (1.0, 1.0, 1.0)
	bpy.context.view_layer.update()


def _local_offset(pb, armature_vec):
	"""Вектор из пространства арматуры в локальные оси кости (location позы задаётся в них)."""
	return pb.bone.matrix_local.to_3x3().inverted() @ armature_vec


def apply_pose(arm, breath=0.0):
	"""Ставит позу «лежит». breath 0..1 — доля вдоха (корпус чуть выше)."""
	reset_pose(arm)
	root = arm.pose.bones[ROOT_BONE]
	feet_z = min(arm.pose.bones[chain[-1]].head.z for chain in LEG_CHAINS)
	drop = (root.head.z - feet_z) * DROP_FRACTION * (1.0 - BREATH * breath)
	root.location = _local_offset(root, Vector((0.0, 0.0, -drop)))
	for chain in LEG_CHAINS:
		for name in chain:
			arm.pose.bones[name].scale = (1.0, LEG_SCALE, 1.0)
	for name in IK_TARGETS:
		if name in arm.pose.bones:
			pb = arm.pose.bones[name]
			pb.location = _local_offset(pb, Vector((0.0, 0.0, drop * 0.25)))   # иначе IK тянет укороченную лапу к земле
	head = arm.pose.bones[HEAD_BONE]
	head.rotation_mode = "QUATERNION"
	best = None
	for sign in (1.0, -1.0):   # знак выбираем по результату: морда должна уйти вниз
		head.rotation_quaternion = Quaternion((1.0, 0.0, 0.0), sign * HEAD_TILT)
		bpy.context.view_layer.update()
		if best is None or head.tail.z < best[0]:
			best = (head.tail.z, sign)
	head.rotation_quaternion = Quaternion((1.0, 0.0, 0.0), best[1] * HEAD_TILT)
	bpy.context.view_layer.update()


def make_sleep_action(arm, name="sleep"):
	"""Клип sleep: кадры 1 и FRAMES — поза лёжа, середина — вдох. После записи поза сбрасывается,
	иначе незаписанные в idle/walk каналы унесут эту позу в другие клипы при экспорте."""
	action = bpy.data.actions.new(name)
	action.use_fake_user = True
	arm.animation_data_create()
	keyed = [ROOT_BONE, HEAD_BONE] + [b for chain in LEG_CHAINS for b in chain] + [t for t in IK_TARGETS if t in arm.pose.bones]
	for frame, breath in ((1, 0.0), (FRAMES // 2, 1.0), (FRAMES, 0.0)):
		# Поза ставится при снятом action: иначе каждый view_layer.update() внутри apply_pose
		# перезаписывает кости значениями уже записанных кадров, и клип выходит статичным.
		arm.animation_data.action = None
		apply_pose(arm, breath)
		arm.animation_data.action = action
		for bname in keyed:   # между назначением action и вставкой ключей — никаких update()
			pb = arm.pose.bones[bname]
			pb.keyframe_insert("location", frame=frame)
			pb.keyframe_insert("rotation_quaternion", frame=frame)
			pb.keyframe_insert("scale", frame=frame)
	arm.animation_data.action = None
	reset_pose(arm)
	return action
