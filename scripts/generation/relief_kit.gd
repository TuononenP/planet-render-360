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
## Native QuadSink (native/, tools/build_native.sh) when loaded: one per
## material in `surfaces`, same arrays as the script quads.
static var _native := ClassDB.class_exists("QuadSink")

func _sink(mat: Material) -> Object:
	if not surfaces.has(mat):
		surfaces[mat] = ClassDB.instantiate("QuadSink")
	return surfaces[mat]

func _arrays(mat: Material) -> Array:
	if not surfaces.has(mat):
		surfaces[mat] = [PackedVector3Array(), PackedVector3Array(),
			PackedVector2Array(), PackedInt32Array(), PackedFloat32Array()]
	return surfaces[mat]

## One tangent per vertex, `count` times: +u direction `du` made
## perpendicular to `n`, w so cross(n, t) · w points along −v (`dnv`),
## as BuildingWalls writes them — the stone's normal map needs them.
static func _tangents(tangents: PackedFloat32Array, n: Vector3, du: Vector3,
		dnv: Vector3, count: int) -> void:
	var t := du - n * n.dot(du)
	if t.length_squared() < 1e-10:
		t = n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT)
	t = t.normalized()
	var w := 1.0 if n.cross(t).dot(dnv) >= 0.0 else -1.0
	for j in count:
		tangents.push_back(t.x); tangents.push_back(t.y); tangents.push_back(t.z); tangents.push_back(w)

## Quad p0-p1-p2-p3 (counter-clockwise seen from the side `n` points to),
## UVs from `uv0` to `uv1` (u along p0→p1, v down from p3 to p0).
func quad(mat: Material, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
		n: Vector3, uv0: Vector2 = Vector2.ZERO, uv1: Vector2 = Vector2.ONE) -> void:
	if _native:
		_sink(mat).quad(p0, p1, p2, p3, n, uv0, uv1)
		return
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
	var tangents: PackedFloat32Array = a[4]
	_tangents(tangents, n, (p1 - p0) * signf(uv1.x - uv0.x), (p3 - p0) * signf(uv1.y - uv0.y), 4)
	# Godot's front face is clockwise seen from outside: pick the order
	# whose winding faces n.
	if (p2 - p0).cross(p1 - p0).dot(n) >= 0.0:
		indices.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
	else:
		indices.append_array([k, k + 2, k + 1, k, k + 3, k + 2])

## One triangle facing `n` (winding picked like quad).
func tri(mat: Material, p0: Vector3, p1: Vector3, p2: Vector3, n: Vector3) -> void:
	if _native:
		_sink(mat).tri(p0, p1, p2, n)
		return
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
	var tangents: PackedFloat32Array = a[4]
	_tangents(tangents, n, ax, -ay, 3)
	if (p2 - p0).cross(p1 - p0).dot(n) >= 0.0:
		indices.append_array([k, k + 1, k + 2])
	else:
		indices.append_array([k, k + 2, k + 1])

## Axis box: centre `c`, x along `ax` (unit, horizontal), z along `az`
## (unit, horizontal, the wall's outward normal), size (x, y, z).
func box(mat: Material, c: Vector3, ax: Vector3, az: Vector3, size: Vector3) -> void:
	if _native:
		_sink(mat).box(c, ax, az, size)
		return
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
		var s: Array = surfaces[mat].arrays() if _native else surfaces[mat]
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = s[0]
		arrays[Mesh.ARRAY_NORMAL] = s[1]
		arrays[Mesh.ARRAY_TEX_UV] = s[2]
		arrays[Mesh.ARRAY_TANGENT] = s[4]
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
	# Calibrated like the walls (the bare photos are 0.15–0.27 linear, so
	# sills and string courses read as dark bands on pale stone).
	return MaterialLibrary.pbr_material(set_name, MaterialLibrary._calib_tint(
		(MaterialLibrary.PBR_SETS[set_name] as Dictionary)["mean"], STONE_TARGETS[set_name]), 0.5)

## Sign glow at full night, × CityLights.NIGHT_ENERGY (~1.6).
const SIGN_GLOW := 0.6

## Linear relief-stone targets per finish (R-1.4 ranges).
const STONE_TARGETS := {
	"limestone": Color(0.557, 0.462, 0.303),  # PRD limestone × 0.92, as the cornice
	"stone": Color(0.52, 0.45, 0.34),
	"render": Color(0.62, 0.60, 0.56),
	"concrete": Color(0.36, 0.35, 0.33),
}

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

## Window glass for 3D relief (oriels, dormers): a mid blue-grey that
## reads as reflective glass at street distance, glossy with a little
## metal so it picks up the sky probe instead of rendering black.
static func glass() -> Material:
	if _mats.has("glass"):
		return _mats["glass"] as Material
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.html("#4f6170")
	m.roughness = 0.08
	m.metallic = 0.2
	m.metallic_specular = 0.7
	_mats["glass"] = m
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

## Shop sign panel: a saturated colour, lit from dusk (CityLights), unlit
## by day.
static func sign(hex: String) -> Material:
	var key := "sign|" + hex
	if _mats.has(key):
		return _mats[key] as Material
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.html(hex)
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = Color.html(hex)
	CityLights.mark_glow(m, SIGN_GLOW)
	_mats[key] = m
	return m
