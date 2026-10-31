class_name ReliefKit
extends RefCounted

## Geometry sink and materials for FacadeRelief / StreetFront: quads and
## boxes accumulated per material into one multi-surface mesh per
## building (kept arrays, so LodRing merges them per cell without a
## read-back), plus the few materials facade relief needs — stone in the
## wall's own finish, wrought iron as an alpha-cut railing texture, canvas
## awnings in a city's colours, and lit shop signs. All drawn here, no
## third-party pixels.

var surfaces: Dictionary = {}

static var _mats: Dictionary = {}

func _arrays(mat: Material) -> Array:
	if not surfaces.has(mat):
		surfaces[mat] = [PackedVector3Array(), PackedVector3Array(),
			PackedVector2Array(), PackedInt32Array()]
	return surfaces[mat]

## Quad p0-p1-p2-p3 (counter-clockwise seen from the side `n` points to),
## UVs from `uv0` to `uv1` (u along p0→p1, v down from p3 to p0).
func quad(mat: Material, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
		n: Vector3, uv0: Vector2 = Vector2.ZERO, uv1: Vector2 = Vector2.ONE) -> void:
	var a := _arrays(mat)
	var verts: PackedVector3Array = a[0]
	var normals: PackedVector3Array = a[1]
	var uvs: PackedVector2Array = a[2]
	var indices: PackedInt32Array = a[3]
	var k := verts.size()
	verts.append_array([p0, p1, p2, p3])
	for j in 4:
		normals.append(n)
	uvs.append_array([Vector2(uv0.x, uv1.y), Vector2(uv1.x, uv1.y),
		Vector2(uv1.x, uv0.y), Vector2(uv0.x, uv0.y)])
	# Godot's front face is clockwise seen from outside: pick the order
	# whose winding faces n.
	if (p2 - p0).cross(p1 - p0).dot(n) >= 0.0:
		indices.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
	else:
		indices.append_array([k, k + 2, k + 1, k, k + 3, k + 2])

## One triangle facing `n` (winding picked like quad).
func tri(mat: Material, p0: Vector3, p1: Vector3, p2: Vector3, n: Vector3) -> void:
	var a := _arrays(mat)
	var verts: PackedVector3Array = a[0]
	var normals: PackedVector3Array = a[1]
	var uvs: PackedVector2Array = a[2]
	var indices: PackedInt32Array = a[3]
	var k := verts.size()
	verts.append_array([p0, p1, p2])
	var ax := (p1 - p0).normalized()
	var ay := n.cross(ax)
	for p in [p0, p1, p2]:
		normals.append(n)
		uvs.append(Vector2((p - p0).dot(ax), (p - p0).dot(ay)) * 0.5)
	if (p2 - p0).cross(p1 - p0).dot(n) >= 0.0:
		indices.append_array([k, k + 1, k + 2])
	else:
		indices.append_array([k, k + 2, k + 1])

## Axis box: centre `c`, x along `ax` (unit, horizontal), z along `az`
## (unit, horizontal, the wall's outward normal), size (x, y, z).
func box(mat: Material, c: Vector3, ax: Vector3, az: Vector3, size: Vector3) -> void:
	var hx := ax * size.x * 0.5
	var hy := Vector3.UP * size.y * 0.5
	var hz := az * size.z * 0.5
	var uvx := Vector2(size.x, size.y) * 0.5
	quad(mat, c - hx - hy + hz, c + hx - hy + hz, c + hx + hy + hz, c - hx + hy + hz, az, Vector2.ZERO, uvx)
	quad(mat, c + hx - hy - hz, c - hx - hy - hz, c - hx + hy - hz, c + hx + hy - hz, -az, Vector2.ZERO, uvx)
	var uvz := Vector2(size.z, size.y) * 0.5
	quad(mat, c + hx - hy + hz, c + hx - hy - hz, c + hx + hy - hz, c + hx + hy + hz, ax, Vector2.ZERO, uvz)
	quad(mat, c - hx - hy - hz, c - hx - hy + hz, c - hx + hy + hz, c - hx + hy - hz, -ax, Vector2.ZERO, uvz)
	var uvt := Vector2(size.x, size.z) * 0.5
	quad(mat, c - hx + hy + hz, c + hx + hy + hz, c + hx + hy - hz, c - hx + hy - hz, Vector3.UP, Vector2.ZERO, uvt)
	quad(mat, c - hx - hy - hz, c + hx - hy - hz, c + hx - hy + hz, c - hx - hy + hz, Vector3.DOWN, Vector2.ZERO, uvt)

## Upright railing panel from a to b (feet), `h` tall, facing `n`; the
## iron texture repeats every metre along it.
func rail(a: Vector3, b: Vector3, h: float, n: Vector3) -> void:
	var len_m := a.distance_to(b) / WorldScale.metres_to_units()
	quad(iron(), a, b, b + Vector3.UP * h, a + Vector3.UP * h, n,
		Vector2.ZERO, Vector2(maxf(len_m, 0.3), 1.0))

func is_empty() -> bool:
	return surfaces.is_empty()

## One MeshInstance3D named `name` under root, tagged as near detail.
func flush(root: Node3D, name: String) -> void:
	if surfaces.is_empty():
		return
	var mesh := ArrayMesh.new()
	for mat in surfaces:
		var s: Array = surfaces[mat]
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = s[0]
		arrays[Mesh.ARRAY_NORMAL] = s[1]
		arrays[Mesh.ARRAY_TEX_UV] = s[2]
		arrays[Mesh.ARRAY_INDEX] = s[3]
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, mat as Material)
		MeshArrays.keep_surface(mesh, arrays)
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.set_meta("lod_detail", true)
	root.add_child(mi)

## Stone for slabs, string courses and sills: the wall's own finish (brick
## and timber fronts dress in stone), one material per finish so relief
## never multiplies the city's materials; `tint` is accepted for callers
## but only picks a warm or cool stone.
static func stone(set_name: String, tint: Color) -> Material:
	if not set_name in ["limestone", "stone", "render", "concrete"]:
		set_name = "limestone" if tint.a <= 0.0 or tint.r >= tint.b else "stone"
	return MaterialLibrary.pbr_material(set_name, Color(0.96, 0.95, 0.92), 0.5)

## Wrought iron: vertical bars between rails with a scroll band, alpha-cut.
static func iron() -> Material:
	if _mats.has("iron"):
		return _mats["iron"] as Material
	var img := Image.create(64, 64, true, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Color(0.09, 0.09, 0.10, 1.0)
	img.fill_rect(Rect2i(0, 0, 64, 5), c)
	img.fill_rect(Rect2i(0, 58, 64, 4), c)
	img.fill_rect(Rect2i(0, 44, 64, 2), c)
	for x in range(2, 64, 8):
		img.fill_rect(Rect2i(x, 0, 2, 64), c)
	for x in range(6, 64, 16):
		for k in 12:
			var ang := float(k) / 12.0 * TAU
			img.set_pixel(clampi(x + int(cos(ang) * 4.0), 0, 63), clampi(51 + int(sin(ang) * 4.0), 0, 63), c)
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.4
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.metallic = 0.6
	m.roughness = 0.5
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_mats["iron"] = m
	return m

## Plain coloured surface (sRGB hex), cached.
static func flat(hex: String, rough: float = 0.8, metal: float = 0.0) -> Material:
	var key := "flat|%s|%.2f|%.2f" % [hex, rough, metal]
	if _mats.has(key):
		return _mats[key] as Material
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.html(hex)
	m.roughness = rough
	m.metallic = metal
	_mats[key] = m
	return m

## Canvas in an sRGB hex, striped with cream or plain; both faces drawn.
static func canvas(hex: String, striped: bool) -> Material:
	var key := "canvas|%s|%s" % [hex, striped]
	if _mats.has(key):
		return _mats[key] as Material
	var img := Image.create(64, 8, true, Image.FORMAT_RGBA8)
	var a := Color.html(hex)
	var b := Color(0.93, 0.90, 0.82)
	for x in 64:
		img.fill_rect(Rect2i(x, 0, 1, 8), a if not striped or (x / 8) % 2 == 0 else b)
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.9
	_mats[key] = m
	return m

## Shop sign panel: a saturated colour that glows faintly at night.
static func sign(hex: String) -> Material:
	var key := "sign|" + hex
	if _mats.has(key):
		return _mats[key] as Material
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.html(hex)
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = Color.html(hex)
	m.emission_energy_multiplier = 0.6
	_mats[key] = m
	return m
