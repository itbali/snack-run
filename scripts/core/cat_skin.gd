class_name CatSkin
extends Resource
## Скин кота: три цвета для трёх материалов модели (спек 2.4).

const ROLE_BY_MATERIAL := {"sr_cat_orange": "body", "sr_cream": "belly", "sr_coral": "accent"}

@export var id: StringName = &"orange"
@export var display_name := "Рыжий"
@export var body := Color("#FAAE45")
@export var belly := Color("#FCD3A1")
@export var accent := Color("#F57485")


static func apply(model: Node, skin: CatSkin) -> int:
	var count := 0
	var meshes: Array = model.find_children("*", "MeshInstance3D", true, false)
	if model is MeshInstance3D:
		meshes.append(model)
	for mi in meshes:
		var m3 := mi as MeshInstance3D
		if m3.mesh == null:
			continue
		for i in m3.mesh.get_surface_count():
			var mat := m3.get_surface_override_material(i) as StandardMaterial3D
			if mat == null or not ROLE_BY_MATERIAL.has(mat.resource_name):
				continue
			match ROLE_BY_MATERIAL[mat.resource_name]:
				"body":
					mat.albedo_color = skin.body
				"belly":
					mat.albedo_color = skin.belly
				"accent":
					mat.albedo_color = skin.accent
			count += 1
	return count
