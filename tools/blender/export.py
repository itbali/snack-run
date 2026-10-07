"""Экспорт glTF (.glb) по конвенциям проекта: 1 ед = 1 м, +Y вверх."""
import os

import bpy


def export_glb(path: str, objects, animations: bool = False) -> None:
	os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
	bpy.ops.object.select_all(action="DESELECT")
	for o in objects:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objects[0]
	bpy.ops.export_scene.gltf(
		filepath=path,
		export_format="GLB",
		use_selection=True,
		export_apply=True,
		export_yup=True,
		export_materials="EXPORT",
		export_animations=animations,
		export_animation_mode="ACTIONS",
		export_skins=animations,
		export_morph=False,
	)
