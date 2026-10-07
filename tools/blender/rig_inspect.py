"""Печать костей и поиск головы. Запуск:
blender -b third_party/quaternius_animal_pack_v2/Cat.blend --python tools/blender/rig_inspect.py"""
import bpy


def vertex_count_for_bone(mesh_obj, bone_name: str) -> int:
	vg = mesh_obj.vertex_groups.get(bone_name)
	if vg is None:
		return 0
	idx = vg.index
	return sum(1 for v in mesh_obj.data.vertices for g in v.groups if g.group == idx and g.weight > 0.3)


def find_head_bone(arm, mesh_obj) -> str:
	"""Голова = листовая не-IK кость с наибольшим числом вершин: у головы уши и морда,
	у лап и кончика хвоста вершин в разы меньше."""
	leaves = [b for b in arm.data.bones if not b.children and not b.name.startswith("IK")]
	return max(leaves, key=lambda b: vertex_count_for_bone(mesh_obj, b.name)).name


def print_table(arm, mesh_obj) -> None:
	for b in arm.data.bones:
		print(f"BONE {b.name:14s} parent={b.parent.name if b.parent else '-':14s} "
		      f"head={tuple(round(c, 2) for c in b.head_local)} verts={vertex_count_for_bone(mesh_obj, b.name)}")


if __name__ == "__main__":
	arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
	mesh = next(o for o in bpy.data.objects if o.type == "MESH")
	print_table(arm, mesh)
	print("HEAD", find_head_bone(arm, mesh))
