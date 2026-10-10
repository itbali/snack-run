class_name SurfaceTextures
extends RefCounted
## Текстуры крупных поверхностей (спек 2.9, «гибрид»): асфальт, плитка тротуара, штукатурка стен.
## План 18: и пропсы (скамейки, коробки, гаражи, крыши, настилы). Трипланарная проекция по мировым координатам — UV у мешей из Blender-скриптов нет, а плитка должна
## идти непрерывно через стыки модулей стены. Пропсы, еда и персонажи остаются плоскоцветными.

const DIR := "res://assets/images/textures/"
## имя меша -> [файл текстуры, размер тайла в метрах]
const TABLE := {
	"wall": ["stucco.png", 4.5],   # пол районов — рельеф (план 10): ground/sidewalk/lawn/path убраны (план 18)
	"retaining_wall": ["stone.png", 3.0],
	# план 18: пропсы — дерево, картон, профнастил, черепица, доски
	"bench": ["wood.png", 1.0], "bench_back": ["wood.png", 1.0], "cafe_table": ["wood.png", 0.8], "shed": ["wood.png", 1.5],
	"box": ["cardboard.png", 0.6], "garage": ["metal.png", 1.6], "house_roof": ["roof_tiles.png", 1.6],
	"boat_deck": ["planks.png", 1.5], "pontoon": ["planks.png", 1.2], "pontoon_plank1": ["planks.png", 1.2],
	"pontoon_plank2": ["planks.png", 1.2], "pontoon_plank3": ["planks.png", 1.2],
}


static func texture_or_null(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


static func apply(root: Node) -> int:
	## Звать после Toon.apply: правит его пер-инстансные материалы. Возвращает число затекстурированных мешей.
	var count := 0
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh == null or not TABLE.has(String(m3.name)):
			continue
		var entry: Array = TABLE[String(m3.name)]
		var tex := texture_or_null(DIR + entry[0])
		if tex == null:
			continue   # без картинки поверхность остаётся плоского цвета
		for i in m3.mesh.get_surface_count():
			var m := m3.get_surface_override_material(i) as StandardMaterial3D
			if m == null:
				continue
			m.albedo_texture = tex
			m.albedo_color = Color.WHITE
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3.ONE / float(entry[1])
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		count += 1
	return count
