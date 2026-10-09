class_name Terrain
extends Node3D
## Пол района по карте высот (спек «Масштаб и рельеф», раздел 3). Данные — data/terrain/<район>.json (tools/terrain).
## Меш тайлами 30×30 м и коллизия HeightMapShape3D строятся из одной сетки — совпадают точно (Ruling плана 10).
## Узел должен стоять в начале координат (сетка задана в мировых x, z).

const TILE := 30
const TEX_DIR := "res://assets/images/textures/"
const DEFAULT_TEXTURES := {"asphalt": "asphalt.png", "paving": "paving.png", "grass": "grass.png", "gravel": "gravel.png",
	"sand": "paving.png", "stone": "stone.png"}
const DEFAULT_TILES := {"asphalt": 4.0, "paving": 1.2, "grass": 2.0, "gravel": 0.8, "sand": 2.0, "stone": 3.0}
const TerrainShader := preload("res://assets/shaders/terrain.gdshader")

@export_file("*.json") var data_path := ""
var nx := 0
var nz := 0
var cell := 1.0
var x0 := 0.0
var z0 := 0.0
var width := 0.0
var depth := 0.0
var channels: Array = []
var heights := PackedFloat32Array()
var splat := PackedByteArray()
var loaded := false
var material: ShaderMaterial


func ensure_loaded() -> void:
	if loaded or data_path == "":
		return
	if not FileAccess.file_exists(data_path):
		push_warning("нет рельефа " + data_path)
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(data_path)) != OK:
		push_error("не разобрать рельеф " + data_path)
		return
	var d: Dictionary = json.data
	nx = int(d["nx"])
	nz = int(d["nz"])
	cell = float(d["cell"])
	x0 = float(d["origin"][0])
	z0 = float(d["origin"][1])
	width = float(d["size"][0])
	depth = float(d["size"][1])
	channels = d.get("channels", ["asphalt", "paving", "grass", "gravel"])
	heights.resize(nx * nz)
	for j in nz:
		var row: Array = d["heights"][j]
		for i in nx:
			heights[j * nx + i] = float(row[i])
	splat = Marshalls.base64_to_raw(d["splat"])
	loaded = true


func _ready() -> void:
	add_to_group("terrain")
	ensure_loaded()
	if not loaded:
		return
	assert(is_equal_approx(cell, 1.0), "HeightMapShape3D — шаг 1 м")
	_build_material()
	_build_tiles()
	_build_collision()


func h(i: int, j: int) -> float:
	return heights[clampi(j, 0, nz - 1) * nx + clampi(i, 0, nx - 1)]


func contains(x: float, z: float) -> bool:
	return x >= x0 and x <= x0 + width and z >= z0 and z <= z0 + depth


func height_at(x: float, z: float) -> float:
	## Высота поверхности по треугольникам сетки — так же, как в меше и HeightMapShape3D.
	ensure_loaded()
	if not loaded:
		return 0.0
	var fx := (x - x0) / cell
	var fz := (z - z0) / cell
	var i := clampi(int(floor(fx)), 0, nx - 2)
	var j := clampi(int(floor(fz)), 0, nz - 2)
	var u := clampf(fx - i, 0.0, 1.0)
	var v := clampf(fz - j, 0.0, 1.0)
	var h00 := h(i, j)
	var h10 := h(i + 1, j)
	var h01 := h(i, j + 1)
	var h11 := h(i + 1, j + 1)
	if u + v <= 1.0:   # треугольник (i,j)-(i+1,j)-(i,j+1)
		return h00 + (h10 - h00) * u + (h01 - h00) * v
	return h11 + (h01 - h11) * (1.0 - u) + (h10 - h11) * (1.0 - v)


static func surface_height(tree: SceneTree, x: float, z: float, fallback := 0.0) -> float:
	## Высота рельефа в точке по всем узлам группы terrain; вне всех — fallback.
	for n in tree.get_nodes_in_group("terrain"):
		var t := n as Terrain
		if t and t.loaded and t.contains(x, z):
			return t.height_at(x, z)
	return fallback


func _texture(name: String) -> Texture2D:
	var path: String = TEX_DIR + DEFAULT_TEXTURES.get(name, "paving.png")
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


func _build_material() -> void:
	var img := Image.create_from_data(nx, nz, false, Image.FORMAT_RGBA8, splat)
	material = ShaderMaterial.new()
	material.shader = TerrainShader
	material.set_shader_parameter("splat", ImageTexture.create_from_image(img))
	var keys := ["tex_r", "tex_g", "tex_b", "tex_a"]
	var tiles := Vector4.ONE
	for c in 4:
		var name: String = channels[c] if c < channels.size() else "paving"
		material.set_shader_parameter(keys[c], _texture(name))
		tiles[c] = DEFAULT_TILES.get(name, 2.0)
	material.set_shader_parameter("tile_sizes", tiles)
	material.set_shader_parameter("tex_cliff", _texture("stone"))
	material.set_shader_parameter("origin", Vector2(x0, z0))
	material.set_shader_parameter("size", Vector2(width, depth))
	material.set_shader_parameter("texels", Vector2(nx, nz))


func _normal(i: int, j: int) -> Vector3:
	return Vector3(h(i - 1, j) - h(i + 1, j), 2.0 * cell, h(i, j - 1) - h(i, j + 1)).normalized()


var _tris := 0


func triangle_count() -> int:
	return _tris


func _tile_flat(ti: int, tj: int, i1: int, j1: int) -> bool:
	var h0 := h(ti, tj)
	for j in range(tj, j1 + 1):
		for i in range(ti, i1 + 1):
			if absf(h(i, j) - h0) > 0.0001:
				return false
	return true


func _build_tiles() -> void:
	var t := 0
	for tj in range(0, nz - 1, TILE):
		for ti in range(0, nx - 1, TILE):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var i1 := mini(ti + TILE, nx - 1)
			var j1 := mini(tj + TILE, nz - 1)
			if _tile_flat(ti, tj, i1, j1):   # плоский тайл — один квад (спек: ≤ 40 000 треугольников на район)
				for q in [[ti, tj], [i1, tj], [ti, j1], [i1, tj], [i1, j1], [ti, j1]]:
					st.set_normal(Vector3.UP)
					st.add_vertex(Vector3(x0 + q[0] * cell, h(q[0], q[1]), z0 + q[1] * cell))
				_tris += 2
			else:
				for j in range(tj, j1):
					for i in range(ti, i1):
						for q in [[i, j], [i + 1, j], [i, j + 1], [i + 1, j], [i + 1, j + 1], [i, j + 1]]:
							st.set_normal(_normal(q[0], q[1]))
							st.add_vertex(Vector3(x0 + q[0] * cell, h(q[0], q[1]), z0 + q[1] * cell))
				_tris += (i1 - ti) * (j1 - tj) * 2
			var mi := MeshInstance3D.new()
			mi.name = "Tile%d" % t
			mi.mesh = st.commit()
			mi.material_override = material
			add_child(mi)
			t += 1


func _build_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "Floor"   # имя пола: инварианты раскладки не считают его пропсом
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var hm := HeightMapShape3D.new()
	hm.map_width = nx
	hm.map_depth = nz
	hm.map_data = heights
	shape.shape = hm
	shape.position = Vector3(x0 + width / 2.0, 0.0, z0 + depth / 2.0)
	body.add_child(shape)
	add_child(body)
