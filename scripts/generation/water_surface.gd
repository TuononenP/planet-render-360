class_name WaterSurface
extends RefCounted

## Water look v2 (T3.8): the water ShaderMaterial plus the surface
## meshes WaterBuilder places. Split out of WaterBuilder so the look
## (shader, colour, micro-normals) and the surface tessellation evolve
## without growing the builder.
##
## Look (PRD §4.3; GLSL and its wave/foam/flow model in WaterShader):
## a dark green-grey/teal body (#2C5566-class) that shallows toward the
## shore, Fresnel-weighted sky reflection and sun glint from the
## engine's own sky radiance + directional light. SPECULAR is held low
## (F0 ≈ 0.018) so the surface reads dark when looking down and only
## brightens at grazing angles. No screen-space refraction or depth
## reads: water stays opaque on every tier.
##
## Per-vertex COLOR.r carries "openness" (0 at the shoreline → 1 at
## OPEN_RAMP_M from it), COLOR.g the sea flag, COLOR.b the shore
## distance over SHORE_M and UV2 the river flow (WaterShader); meshes
## without COLOR (the datum plane) read as open water.

## Shore → open-water colour ramp (metres from the nearest shoreline).
const OPEN_RAMP_M := 30.0

## Shore distance (m) that COLOR.b spans (0 at the rim → 1): the foam
## band and surf read it (WaterShader).
const SHORE_M := 40.0
## Downstream drift of a river's surface pattern (m/s): rivers, streams.
const RIVER_FLOW := 0.9
const STREAM_FLOW := 0.6

static var _mats: Dictionary = {}

## Shared water material per tier (WaterShader; swell on High/Ultra);
## units_per_metre tracks WorldScale (the legacy 880 m equivalence flag
## may flip between builds/tests).
static func material(preset: int = RenderSettings.Preset.HIGH) -> ShaderMaterial:
	preset = RenderSettings.clamp_preset(preset)
	if not _mats.has(preset):
		var sh := Shader.new()
		sh.code = WaterShader.CODE.replace("// @SNOW", ClimateModel.SNOW_GLSL)
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("water_quality", preset)
		m.set_shader_parameter("shore_m", SHORE_M)
		_mats[preset] = m
	var mat: ShaderMaterial = _mats[preset]
	mat.set_shader_parameter("units_per_metre", WorldScale.metres_to_units())
	return mat

static func _commit(root: Node3D, verts: PackedVector3Array,
		colors: PackedColorArray, indices: PackedInt32Array,
		mat: Material, flow: PackedVector2Array = PackedVector2Array()) -> void:
	if indices.is_empty():
		return
	var normals := PackedVector3Array()
	normals.resize(verts.size())
	normals.fill(Vector3.UP)
	var uvs := PackedVector2Array()
	uvs.resize(verts.size())
	for i in verts.size():
		uvs[i] = Vector2(verts[i].x, verts[i].z) * 0.02
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	if flow.size() == verts.size():
		arrays[Mesh.ARRAY_TEX_UV2] = flow
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	TerrainBuilder._add(root, mesh, mat)

## One clipped water-polygon part as a flat surface at `level`: rim
## samples (exact shoreline + island rims) plus interior posts, Delaunay
## triangulated and kept where the triangle centroid is water. Interior
## vertices carry openness for the shore → open-water colour ramp; this
## also replaces the v1 half-post block grid for holed polygons, so
## islands keep their real outline.
static func add_polygon(root: Node3D, part: PackedVector2Array,
		holes: Array, level: float, step: float, mat: Material) -> void:
	if part.size() < 3:
		return
	var rim_sp := maxf(step * 0.5, 0.5)
	var grid := maxf(step, 1.0)
	var ramp := OPEN_RAMP_M * WorldScale.metres_to_units()
	var bb := _bbox(part)
	var rims := PackedVector2Array(_resample_ring(part, rim_sp))
	for h in holes:
		if not (h is PackedVector2Array):
			continue
		for p in _resample_ring(h as PackedVector2Array, rim_sp):
			if p.x >= bb[0] - grid and p.x <= bb[2] + grid \
					and p.y >= bb[1] - grid and p.y <= bb[3] + grid:
				rims.append(p)
	var buckets := _bucket(rims, grid)
	var pts := PackedVector2Array(rims)
	var openness := PackedFloat32Array()
	openness.resize(rims.size())
	openness.fill(0.0)
	var shore := PackedFloat32Array(openness)
	var shore_u := SHORE_M * WorldScale.metres_to_units()
	var reach := int(ceil(maxf(ramp, shore_u) / grid))
	var z: float = bb[1] + grid * 0.5
	while z < bb[3]:
		var x: float = bb[0] + grid * 0.5
		while x < bb[2]:
			var c := Vector2(x, z)
			if Geometry2D.is_point_in_polygon(c, part) \
					and not _in_any_hole(c, holes):
				var d := _nearest(buckets, c, grid, reach)
				if d > grid * 0.45:
					pts.append(c)
					openness.append(clampf(d / maxf(ramp, 0.001), 0.0, 1.0))
					shore.append(clampf(d / shore_u, 0.0, 1.0))
			x += grid
		z += grid
	var tri := Geometry2D.triangulate_delaunay(pts)
	if tri.is_empty():
		# Degenerate input (duplicate/collinear rim): exact rim only.
		pts = part
		openness.resize(part.size())
		openness.fill(0.0)
		shore = PackedFloat32Array(openness)
		tri = Geometry2D.triangulate_polygon(part)
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	for i in pts.size():
		verts.append(Vector3(pts[i].x, level, pts[i].y))
		colors.append(Color(openness[i], 0.0, shore[i]))
	var indices := PackedInt32Array()
	for t in range(0, tri.size(), 3):
		var cen := (pts[tri[t]] + pts[tri[t + 1]] + pts[tri[t + 2]]) / 3.0
		if Geometry2D.is_point_in_polygon(cen, part) \
				and not _in_any_hole(cen, holes):
			indices.append_array([tri[t], tri[t + 1], tri[t + 2]])
	_commit(root, verts, colors, indices, mat)

## Miter-joint channel ribbon with a centre row (openness 0 at both
## banks, rising toward the centre for wide rivers). Draped ribbons
## hug the ground + 0.06; others sit flat at `level`.
static func add_ribbon(root: Node3D, line: PackedVector2Array,
		half: float, ground: GroundTruth, level: float, draped: bool,
		mat: Material, lift: float = 0.05) -> void:
	var ramp := OPEN_RAMP_M * WorldScale.metres_to_units()
	var mid_open := clampf(half / maxf(ramp, 0.001), 0.0, 1.0)
	var mid_shore := clampf(half / (SHORE_M * WorldScale.metres_to_units()), 0.0, 1.0)
	# OSM draws waterways downstream: the surface drifts along the line.
	var speed := (STREAM_FLOW if draped else RIVER_FLOW) * WorldScale.metres_to_units()
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var flow := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in line.size():
		var prev := line[maxi(i - 1, 0)]
		var next := line[mini(i + 1, line.size() - 1)]
		var dir := next - prev
		if dir.length() < 0.001:
			dir = Vector2(1, 0)
		dir = dir.normalized()
		var n := Vector2(-dir.y, dir.x)
		var row := [line[i] + n * half, line[i], line[i] - n * half]
		# Sloping channels follow GroundTruth's bank-levelled carve
		# surface down the valley; `level` (the run's bank level) only
		# where the centreline has no carved post near it.
		var row_level := level
		var local := ground.water_level_at(line[i].x, line[i].y)
		if local > ground.water_level_m + 0.001:
			row_level = local + lift
		for j in 3:
			var p: Vector2 = row[j]
			var y := ground.height_at_world(p.x, p.y) + 0.06 if draped \
				else row_level
			verts.append(Vector3(p.x, y, p.y))
			colors.append(Color(mid_open if j == 1 else 0.0, 0.0, mid_shore if j == 1 else 0.0))
			flow.append(dir * speed)
		if i > 0:
			var k := i * 3
			var q := k - 3
			indices.append_array([q, q + 1, k, q + 1, k + 1, k,
				q + 1, q + 2, k + 1, q + 2, k + 2, k + 1])
	_commit(root, verts, colors, indices, mat, flow)

## Open sea over the detailed extent as a grid at `level` (replacing the
## flat plane): quads kept wherever a corner is water, each vertex with
## its distance to the nearest land (chamfer distance transform over
## the DEM's dry posts) for the shallow tint, surf and foam, and the sea
## flag for swell. `cells` quads per side.
static func add_sea_grid(root: Node3D, ground: GroundTruth, level: float,
		mat: Material, cells: int = 192) -> void:
	var n := cells + 1
	var e := WorldScale.detailed_extent_units()
	var stp := e / float(cells)
	var dist := PackedFloat32Array()
	dist.resize(n * n)
	for j in n:
		for i in n:
			var x := -e * 0.5 + float(i) * stp
			var z := -e * 0.5 + float(j) * stp
			dist[j * n + i] = 0.0 if ground.height_at_world(x, z) > level + 0.25 else 1e9
	_chamfer(dist, n, stp)
	var ramp := OPEN_RAMP_M * WorldScale.metres_to_units()
	var shore_u := SHORE_M * WorldScale.metres_to_units()
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	for j in n:
		for i in n:
			var d := dist[j * n + i]
			verts.append(Vector3(-e * 0.5 + float(i) * stp, level, -e * 0.5 + float(j) * stp))
			colors.append(Color(clampf(d / ramp, 0.0, 1.0), 1.0, clampf(d / shore_u, 0.0, 1.0)))
	var indices := PackedInt32Array()
	for j in cells:
		for i in cells:
			var a := j * n + i
			if dist[a] <= 0.0 and dist[a + 1] <= 0.0 and dist[a + n] <= 0.0 \
					and dist[a + n + 1] <= 0.0:
				continue
			indices.append_array([a, a + 1, a + n, a + 1, a + n + 1, a + n])
	_commit(root, verts, colors, indices, mat)

## Two-pass chamfer distance (units) to the zero cells, in place.
static func _chamfer(d: PackedFloat32Array, n: int, stp: float) -> void:
	var a := stp
	var b := stp * 1.4142
	for j in n:
		for i in n:
			var k := j * n + i
			var v := d[k]
			if i > 0:
				v = minf(v, d[k - 1] + a)
			if j > 0:
				v = minf(v, d[k - n] + a)
				if i > 0:
					v = minf(v, d[k - n - 1] + b)
				if i < n - 1:
					v = minf(v, d[k - n + 1] + b)
			d[k] = v
	for j in range(n - 1, -1, -1):
		for i in range(n - 1, -1, -1):
			var k := j * n + i
			var v := d[k]
			if i < n - 1:
				v = minf(v, d[k + 1] + a)
			if j < n - 1:
				v = minf(v, d[k + n] + a)
				if i < n - 1:
					v = minf(v, d[k + n + 1] + b)
				if i > 0:
					v = minf(v, d[k + n - 1] + b)
			d[k] = v

## Closed ring resampled ≤ sp apart (vertices kept exactly).
static func _resample_ring(ring: PackedVector2Array, sp: float) -> Array:
	var out: Array = []
	var seen := {}
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var n := maxi(1, int(ceil(a.distance_to(b) / sp)))
		for s in n:
			var p := a.lerp(b, float(s) / float(n))
			# Delaunay rejects coincident points (closed rings repeat
			# their first vertex; OSM rings can double back).
			var key := Vector2i(roundi(p.x * 100.0), roundi(p.y * 100.0))
			if not seen.has(key):
				seen[key] = true
				out.append(p)
	return out

static func _bucket(pts: PackedVector2Array, cell: float) -> Dictionary:
	var out := {}
	for p in pts:
		var key := Vector2i(floori(p.x / cell), floori(p.y / cell))
		if not out.has(key):
			out[key] = PackedVector2Array()
		var arr: PackedVector2Array = out[key]
		arr.append(p)
		out[key] = arr
	return out

## Distance to the nearest rim sample within `reach` buckets (INF-free:
## past the reach the point is open water, returned as reach cells).
static func _nearest(buckets: Dictionary, c: Vector2, cell: float,
		reach: int) -> float:
	var key := Vector2i(floori(c.x / cell), floori(c.y / cell))
	var best := float(reach + 1) * cell
	for dz in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var k := key + Vector2i(dx, dz)
			if not buckets.has(k):
				continue
			for p in buckets[k] as PackedVector2Array:
				best = minf(best, p.distance_to(c))
	return best

static func _in_any_hole(c: Vector2, holes: Array) -> bool:
	for h in holes:
		if h is PackedVector2Array \
				and Geometry2D.is_point_in_polygon(c, h as PackedVector2Array):
			return true
	return false

## [minx, minz, maxx, maxz] bounds of a ring.
static func _bbox(ring: PackedVector2Array) -> Array:
	var bb := [INF, INF, -INF, -INF]
	for p in ring:
		bb[0] = minf(bb[0], p.x)
		bb[1] = minf(bb[1], p.y)
		bb[2] = maxf(bb[2], p.x)
		bb[3] = maxf(bb[3], p.y)
	return bb
