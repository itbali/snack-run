"""blender -b --python tools/blender/tests/list_glb.py -- assets/models/cat.glb"""
import sys

import bpy

path = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_homefile(use_empty=True)
bpy.ops.import_scene.gltf(filepath=path)
for o in bpy.data.objects:
	print("OBJ", o.type, o.name, tuple(round(d, 3) for d in o.dimensions), "parent", o.parent.name if o.parent else "-")
	if o.type == "MESH":
		print("   MATS", [m.name for m in o.data.materials if m])
for a in bpy.data.actions:
	print("ANIM", a.name, "кадры", tuple(a.frame_range))
