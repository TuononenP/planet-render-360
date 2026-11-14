class_name Icicles
extends RefCounted

## Icicles along the eaves near the eye on a freezing snowy day (desktop
## Ultra, like the snowbanks). Eaves are read off the built roofs, not
## re-planned from the data: the boundary edges of roof-material
## triangles (RoofVariety's "roof" meta) that run level with the rest of
## their face above or beside them, i.e. the low edge of a pitched face or
## the rim of a flat roof. One MultiMesh of tapered cones hangs from them,
## a few centimetres out from the wall, lengths mostly short with the odd
## long one. Added to the live world only (no owner, so never packed into
## WorldCache) and hidden again when the snow goes.

## Eaves within this reach of the eye get icicles (metres).
const RADIUS_M := 110.0
## One candidate spot per this many metres of eave; about half take one.
const SPACING_M := 0.2
const MAX_ICICLES := 24000
## Season mean (°C) below which eaves freeze into icicles.
const COLD_C := -1.0

static var _mesh: Mesh
static var _mat: StandardMaterial3D

## Shows icicles on `world` while `on` (climate snow lies), building them
## the first time; hides them otherwise.
static func apply(world: Node, on: bool, data: LocationData) -> int:
	var node := world.get_node_or_null("Icicles") as MultiMeshInstance3D
	if not on or data == null or not cold(data):
		if node != null:
			node.visible = false
		return 0
	if node != null:
		node.visible = true
		return node.multimesh.instance_count
	if not RenderQuality.ultra_desktop(data.quality_preset):
		return 0
	var m := WorldScale.metres_to_units()
	var xf := spots(world, View360.spawn_xz(data), m)
	if xf.is_empty():
		return 0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _cone()
	mm.instance_count = xf.size()
	for i in xf.size():
		mm.set_instance_transform(i, xf[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Icicles"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.material_override = _material()
	world.add_child(mmi)
	return xf.size()

## Whether the season is cold enough at the viewpoint for eaves to freeze.
static func cold(data: LocationData) -> bool:
	if not ClimateModel.has(data):
		return data.season == LocationData.Season.WINTER and ClimateModel.snowy_at_viewpoint(data, data.season)
	return ClimateModel.season_temp_c(data, data.season) < COLD_C

## Icicle transforms (world space) along the eaves of `world`'s roofs
## within RADIUS_M of `eye` (xz, world units).
static func spots(world: Node, eye: Vector2, m: float) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	var r := RADIUS_M * m
	for c in world.get_children():
		if not (c is MeshInstance3D):
			continue
		var layer := str(c.get_meta("lod_layer", ""))
		if layer != "Buildings":
			continue
		var mi := c as MeshInstance3D
		if mi.mesh == null:
			continue
		var box := mi.transform * mi.mesh.get_aabb()
		var near := Vector2(clampf(eye.x, box.position.x, box.end.x), clampf(eye.y, box.position.z, box.end.z))
		if near.distance_to(eye) > r:
			continue
		for s in mi.mesh.get_surface_count():
			var mat: Material = mi.material_override if mi.material_override != null else mi.mesh.surface_get_material(s)
			if mat == null or not mat.has_meta("roof"):
				continue
			_eaves(mi.mesh.surface_get_arrays(s), mi.transform, eye, r, m, out)
			if out.size() >= MAX_ICICLES:
				return out
	return out

## Appends icicles along the level boundary edges of one roof surface.
static func _eaves(arrays: Array, xf: Transform3D, eye: Vector2, r: float, m: float, out: Array[Transform3D]) -> void:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if idx.is_empty():
		idx.resize(verts.size())
		for i in verts.size():
			idx[i] = i
	var q := 0.02 * m
	# Each edge by its quantised ends: count, and the triangle's third corner.
	var edges := {}
	for t in range(0, idx.size() - 2, 3):
		var p0: Vector3 = xf * verts[idx[t]]
		# Merged meshes span whole blocks: skip faces well out of reach.
		if Vector2(p0.x, p0.z).distance_to(eye) > r + 40.0 * m:
			continue
		var p := [p0, xf * verts[idx[t + 1]], xf * verts[idx[t + 2]]]
		for k in 3:
			var a: Vector3 = p[k]
			var b: Vector3 = p[(k + 1) % 3]
			var ka := Vector3i((a / q).round())
			var kb := Vector3i((b / q).round())
			var key := [ka, kb] if str(ka) < str(kb) else [kb, ka]
			if edges.has(key):
				edges[key][0] += 1
			else:
				edges[key] = [1, a, b, p[(k + 2) % 3]]
	for key in edges:
		var e: Array = edges[key]
		if int(e[0]) != 1:
			continue
		var a: Vector3 = e[1]
		var b: Vector3 = e[2]
		var third: Vector3 = e[3]
		var run := Vector2(b.x - a.x, b.z - a.z)
		if run.length() < 0.6 * m or absf(a.y - b.y) > 0.05 * m:
			continue
		# An eave: the face rises (or stays level) away from this edge.
		if third.y < minf(a.y, b.y) - 0.02 * m:
			continue
		var mid := Vector2((a.x + b.x) * 0.5, (a.z + b.z) * 0.5)
		if mid.distance_to(eye) > r:
			continue
		var along := run.normalized()
		var outward := Vector2(along.y, -along.x)
		if outward.dot(Vector2(third.x, third.z) - mid) > 0.0:
			outward = -outward
		var n := int(run.length() / (SPACING_M * m))
		for i in n:
			var f := (float(i) + 0.5) / float(n)
			var p := a.lerp(b, f)
			var h := _hash(p.x, p.z)
			if h > 0.5:
				continue
			# Mostly short, the odd long one (8-60 cm).
			var len_m := 0.08 + 0.52 * pow(_hash(p.z, p.x), 3.0)
			var rad_m := 0.012 + 0.03 * len_m
			var base := Vector3(p.x + outward.x * 0.04 * m, p.y - 0.01 * m, p.z + outward.y * 0.04 * m)
			var basis := Basis.from_scale(Vector3(rad_m, len_m, rad_m) * m)
			out.append(Transform3D(basis, base))
			if out.size() >= MAX_ICICLES:
				return

static func _hash(x: float, z: float) -> float:
	return fposmod(sin(x * 12.9898 + z * 78.233) * 43758.5453, 1.0)

## A unit icicle: radius 1 at the top (origin), tapering to a point 1 below.
static func _cone() -> Mesh:
	if _mesh == null:
		var c := CylinderMesh.new()
		c.top_radius = 1.0
		c.bottom_radius = 0.05
		c.height = 1.0
		c.radial_segments = 6
		c.rings = 2
		c.cap_bottom = false
		var arrays := c.get_mesh_arrays()
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in v.size():
			v[i].y -= 0.5
		arrays[Mesh.ARRAY_VERTEX] = v
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_mesh = am
	return _mesh

## Clear, glossy ice: pale blue-white, smooth, and lit through at the tip.
static func _material() -> StandardMaterial3D:
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.albedo_color = Color(0.80, 0.86, 0.92)
		_mat.roughness = 0.08
		_mat.metallic_specular = 0.7
		_mat.rim_enabled = true
		_mat.rim = 0.4
		_mat.rim_tint = 0.3
		_mat.backlight_enabled = true
		_mat.backlight = Color(0.35, 0.42, 0.5)
	return _mat
