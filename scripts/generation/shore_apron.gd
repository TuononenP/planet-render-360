class_name ShoreApron
extends RefCounted

## Shoreline geometry for WaterBuilder: coastlines, shore aprons
## sloping into the water, and bridge ways over water. Level and
## clipping helpers stay in WaterBuilder.
static func _coastlines(data: LocationData) -> Array:
	var out: Array = []
	for w in data.waterways:
		if not (w is Dictionary):
			continue
		if str((w as Dictionary).get("class", "")) != "coastline":
			continue
		var pts: PackedVector2Array = \
			(w as Dictionary).get("points", PackedVector2Array())
		if pts.size() >= 2:
			out.append(w)
	return out

## T3.5 shore-blend aprons: one draped band mesh along every
## shoreline (water-polygon rims, island holes, both channel banks,
## the land side of coastlines), vertex-coloured by the adjacent
## land-cover class — wet-darkened at the waterline, full cover
## colour landward. Covers the ~1-post seam where the terrain mesh
## would otherwise read its cover-free fallback into the water. The
## band tucks slightly under the water surface at its inner edge and
## ducks below it where the ground drops, so it never z-fights or
## floats; stations over open water or past the mesh are skipped.
static func _shore_aprons(root: Node3D, data: LocationData,
		ground: GroundTruth, channels: Array) -> void:
	var step := WaterBuilder._post_step(data)
	var width := maxf(step * 1.25, 2.0)
	var stride := maxf(step * 0.75, 1.0)
	var bound := WorldScale.detailed_extent_units() * 0.5
	var verts: Array = []
	var normals: Array = []
	var colors: Array = []
	var uvs: Array = []
	var indices: Array = []
	for poly in data.land_polygons:
		if str(poly.get("class", "")) != "water":
			continue
		var pts: PackedVector2Array = \
			poly.get("points", PackedVector2Array())
		if pts.size() < 3:
			continue
		for part in WaterBuilder._clip_water_poly(pts):
			_apron_ring(verts, normals, colors, uvs, indices, part,
				true, ground, width, stride, bound)
		for h in poly.get("holes", []):
			if h is PackedVector2Array \
					and (h as PackedVector2Array).size() >= 3:
				for hpart in WaterBuilder._clip_water_poly(h):
					_apron_ring(verts, normals, colors, uvs, indices,
						hpart, false, ground, width, stride, bound)
	for w in channels:
		var cpts: PackedVector2Array = \
			w.get("points", PackedVector2Array())
		var half := float(w.get("width_m", 0.0)) * 0.5 \
			* WorldScale.metres_to_units()
		for run in WaterBuilder._clip_runs(cpts, bound + half + 2.0):
			_apron_line(verts, normals, colors, uvs, indices, run,
				half, ground, width, stride, bound)
	for w in _coastlines(data):
		var kpts: PackedVector2Array = \
			(w as Dictionary).get("points", PackedVector2Array())
		for run in WaterBuilder._clip_runs(kpts, bound + width):
			_apron_coast(verts, normals, colors, uvs, indices, run,
				ground, width, stride, bound)
	if indices.is_empty():
		return
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(verts)
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(normals)
	arrays[Mesh.ARRAY_COLOR] = PackedColorArray(colors)
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(uvs)
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(indices)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	TerrainBuilder._add(root, mesh, MaterialLibrary.shore_material())

## One apron station: inner (waterline, wet-darkened) + outer (cover
## colour) verts draped on the ground. Returns the base vertex index,
## or -1 when the station is skipped (outer point past the mesh, over
## open water, or on an adjacent water body).
static func _apron_append(verts: Array, normals: Array, colors: Array,
		uvs: Array, inner: Vector2, outer: Vector2, ground: GroundTruth,
		bound: float) -> int:
	if absf(outer.x) > bound or absf(outer.y) > bound:
		return -1
	var cls := ground.land_class_at(outer.x, outer.y)
	if cls == "water":
		return -1
	if ground.water_at(outer.x, outer.y) > 0.01:
		return -1
	var c := WaterBuilder._UNKNOWN_SHORE
	if MaterialLibrary.has_ground_class(cls):
		c = MaterialLibrary.ground_color(cls)
	var wet := Color(c.r * WaterBuilder._WET_DARKEN, c.g * WaterBuilder._WET_DARKEN,
		c.b * WaterBuilder._WET_DARKEN)
	var k := verts.size()
	verts.append(Vector3(inner.x,
		ground.height_at_world(inner.x, inner.y) + WaterBuilder._APRON_LIFT,
		inner.y))
	verts.append(Vector3(outer.x,
		ground.height_at_world(outer.x, outer.y) + WaterBuilder._APRON_LIFT,
		outer.y))
	normals.append(Vector3.UP)
	normals.append(Vector3.UP)
	colors.append(wet)
	colors.append(c)
	uvs.append(inner * 0.22)
	uvs.append(outer * 0.22)
	return k

static func _apron_quad(indices: Array, k0: int, k1: int) -> void:
	if k0 < 0 or k1 < 0:
		return
	indices.append_array([k0, k0 + 1, k1, k1, k0 + 1, k1 + 1])

## Apron band around one ring: water_inside rings blend outward
## (lake shores), island holes blend inward (their land is inside).
static func _apron_ring(verts: Array, normals: Array, colors: Array,
		uvs: Array, indices: Array, ring: PackedVector2Array,
		water_inside: bool, ground: GroundTruth, width: float,
		stride: float, bound: float) -> void:
	var inset := width * 0.15
	var first := -1
	var prev := -1
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var seg_len := a.distance_to(b)
		if seg_len < 0.001:
			continue
		var dir := (b - a) / seg_len
		var n := Vector2(-dir.y, dir.x)
		var steps := maxi(1, int(seg_len / stride))
		for s in steps:
			var c := a.lerp(b, (float(s) + 0.5) / float(steps))
			var probe := c + n * width * 0.5
			var landward := n
			if TerrainBuilder.point_in_polygon(probe, ring) \
					== water_inside:
				landward = -n
			var k := _apron_append(verts, normals, colors, uvs,
				c - landward * inset, c + landward * width,
				ground, bound)
			if first < 0 and k >= 0:
				first = k
			_apron_quad(indices, prev, k)
			if k >= 0:
				prev = k
	_apron_quad(indices, prev, first)

## Apron bands along both banks of a channel run, tucked slightly
## under the ribbon edge at the waterline.
static func _apron_line(verts: Array, normals: Array, colors: Array,
		uvs: Array, indices: Array, line: PackedVector2Array,
		half: float, ground: GroundTruth, width: float, stride: float,
		bound: float) -> void:
	for side in [1.0, -1.0]:
		var prev := -1
		for i in line.size() - 1:
			var a := line[i]
			var b := line[i + 1]
			var seg_len := a.distance_to(b)
			if seg_len < 0.001:
				continue
			var dir := (b - a) / seg_len
			var n: Vector2 = Vector2(-dir.y, dir.x) * side
			var steps := maxi(1, int(seg_len / stride))
			for s in steps:
				var c := a.lerp(b, (float(s) + 0.5) / float(steps))
				var k := _apron_append(verts, normals, colors, uvs,
					c + n * half * 0.9, c + n * (half + width),
					ground, bound)
				_apron_quad(indices, prev, k)
				if k >= 0:
					prev = k

## Apron band on the land side of a coastline run: the side with a
## mapped non-water cover wins, else the higher ground (real data
## first; the sea side has neither cover nor height).
static func _apron_coast(verts: Array, normals: Array, colors: Array,
		uvs: Array, indices: Array, line: PackedVector2Array,
		ground: GroundTruth, width: float, stride: float,
		bound: float) -> void:
	var inset := width * 0.15
	var prev := -1
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var seg_len := a.distance_to(b)
		if seg_len < 0.001:
			continue
		var dir := (b - a) / seg_len
		var n := Vector2(-dir.y, dir.x)
		var steps := maxi(1, int(seg_len / stride))
		for s in steps:
			var c := a.lerp(b, (float(s) + 0.5) / float(steps))
			var landward := _coast_land_side(c, n, ground, width)
			var k := _apron_append(verts, normals, colors, uvs,
				c - landward * inset, c + landward * width,
				ground, bound)
			_apron_quad(indices, prev, k)
			if k >= 0:
				prev = k

static func _coast_land_side(c: Vector2, n: Vector2, ground: GroundTruth,
		width: float) -> Vector2:
	var p := c + n * width
	var m := c - n * width
	var cls_p := ground.land_class_at(p.x, p.y)
	var cls_m := ground.land_class_at(m.x, m.y)
	var mapped_p := cls_p != "" and cls_p != "water"
	var mapped_m := cls_m != "" and cls_m != "water"
	if mapped_p != mapped_m:
		return n if mapped_p else -n
	if ground.height_at_world(p.x, p.y) \
			>= ground.height_at_world(m.x, m.y):
		return n
	return -n

## T4.4 handoff: v2 road dicts with bridge=true whose centreline
## crosses rendered water (a sample inside a carved channel, or below
## sea datum past coastline). v1 bare centrelines carry no bridge flag
## and are skipped. T4.4 decks these; WaterBuilder builds no bridges.
static func bridge_ways_over_water(data: LocationData,
		ground: GroundTruth = null) -> Array:
	if ground == null:
		ground = GroundTruth.new(data)
	var out: Array = []
	var coast := WaterBuilder._has_coastline(data)
	var sea_y := ground.water_level_m \
		if is_equal_approx(ground.water_level_m, -3.0) else ground.render_y(WaterBuilder.SEA_LEVEL_M)
	for r in data.roads:
		if not (r is Dictionary) or not bool(r.get("bridge", false)):
			continue
		var pts: PackedVector2Array = r.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		for p in WaterBuilder._resample(pts, 4.0):
			if ground.water_at(p.x, p.y) > 0.0:
				out.append(r)
				break
			if coast and ground.height_at_world(p.x, p.y) < sea_y:
				out.append(r)
				break
	return out
