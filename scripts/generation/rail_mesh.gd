class_name RailMesh
extends RefCounted

## Small geometry kit shared by RailBuilder, RailStations and
## SubwayEntrances: vertex-coloured quads and oriented boxes appended to
## a TreeMeshLibrary.Buf, wound to face a given normal, plus the cached
## materials the railway layer draws with. Metres throughout.

static var _mats: Dictionary = {}
static var _infill_tex: Texture2D

## Quad a-b-c-d (a perimeter, any winding) facing `n`, one colour.
static func quad(b: TreeMeshLibrary.Buf, a: Vector3, bb: Vector3, c: Vector3,
		d: Vector3, n: Vector3, col: Color,
		uv: Array = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]) -> void:
	var k := b.verts.size()
	b.verts.append_array([a, bb, c, d])
	for i in 4:
		b.normals.append(n)
		b.colors.append(col)
		b.uvs.append(uv[i])
	# Same front-face rule as RoadBuilder._wall.
	var front := (c - a).cross(bb - a)
	if front.dot(n) >= 0.0:
		b.idx.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
	else:
		b.idx.append_array([k, k + 2, k + 1, k, k + 3, k + 2])

## Oriented box: centre plus half-extent vectors along its three axes
## (need not be unit; must be mutually perpendicular). `skip_bottom`
## drops the face no one sees (sleepers, posts on the ground).
static func box(b: TreeMeshLibrary.Buf, c: Vector3, hx: Vector3, hy: Vector3,
		hz: Vector3, col: Color, skip_bottom: bool = true) -> void:
	var nx := hx.normalized()
	var ny := hy.normalized()
	var nz := hz.normalized()
	# Top and bottom.
	quad(b, c + hy - hx - hz, c + hy + hx - hz, c + hy + hx + hz, c + hy - hx + hz, ny, col)
	if not skip_bottom:
		quad(b, c - hy - hx - hz, c - hy + hx - hz, c - hy + hx + hz, c - hy - hx + hz, -ny, col)
	var side := col.darkened(0.12)
	quad(b, c + hx - hy - hz, c + hx - hy + hz, c + hx + hy + hz, c + hx + hy - hz, nx, side)
	quad(b, c - hx - hy - hz, c - hx - hy + hz, c - hx + hy + hz, c - hx + hy - hz, -nx, side)
	quad(b, c + hz - hx - hy, c + hz + hx - hy, c + hz + hx + hy, c + hz - hx + hy, nz, side)
	quad(b, c - hz - hx - hy, c - hz + hx - hy, c - hz + hx + hy, c - hz - hx + hy, -nz, side)

## Upright box standing on `foot` (axis-aligned to `along`, unit XZ).
static func post(b: TreeMeshLibrary.Buf, foot: Vector3, along: Vector3, w: float,
		d: float, h: float, col: Color) -> void:
	var across := Vector3(-along.z, 0.0, along.x)
	box(b, foot + Vector3(0, h * 0.5, 0), along * (d * 0.5), Vector3(0, h * 0.5, 0),
		across * (w * 0.5), col)

## A MeshInstance3D for a filled buffer, or null when it is empty.
static func instance(b: TreeMeshLibrary.Buf, mat: Material, name: String) -> MeshInstance3D:
	if b.idx.is_empty():
		return null
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, b.arrays())
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.name = name
	return mi

static func add(root: Node3D, b: TreeMeshLibrary.Buf, mat: Material, name: String) -> int:
	var mi := instance(b, mat, name)
	if mi == null:
		return 0
	root.add_child(mi)
	return b.tris()

# --- Materials -------------------------------------------------------------

## Vertex-coloured surface (colour carries the albedo).
static func colour_mat(key: String, metallic: float, roughness: float,
		cull_off: bool = false) -> StandardMaterial3D:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.metallic = metallic
	m.roughness = roughness
	if cull_off:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mats[key] = m
	return m

## Self-lit colour (lamp globes, lit sign boxes); one material per hue
## because emission does not follow vertex colour.
static func glow_mat(col: Color, energy: float = 1.6) -> StandardMaterial3D:
	var key := "glow|%s|%.2f" % [col.to_html(), energy]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	m.roughness = 0.2
	_mats[key] = m
	return m

## Photographic PBR set calibrated to a target albedo (RoadBuilder rule).
static func pbr(set_name: String, hex: String) -> Material:
	var key := "pbr|%s|%s" % [set_name, hex]
	if not _mats.has(key):
		_mats[key] = RoadBuilder._pbr(set_name, hex)
	return _mats[key]

## Alpha-tested baluster infill between a railing's rails: vertical bars
## every ~11 cm on a 1 m tile (UV u in metres, v 0 at top rail → 1 at
## the bottom rail), tinted by vertex colour.
static func infill_mat() -> StandardMaterial3D:
	if _mats.has("infill"):
		return _mats["infill"]
	if _infill_tex == null:
		var img := Image.create(128, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for x in range(4, 128, 14):
			img.fill_rect(Rect2i(x, 0, 3, 64), Color(1, 1, 1, 1))
		img.generate_mipmaps()
		_infill_tex = ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = _infill_tex
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.4
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.metallic = 0.4
	m.roughness = 0.55
	_mats["infill"] = m
	return m
