class_name WaterBuilder
extends RefCounted

## Real water surfaces from OSM data (contract §4, T3.4): triangulated
## water polygons (holes read as islands), width-aware waterway
## ribbons, and a sea plane past coastline ways — all DEM-carved in
## GroundTruth and shaded by one PBR water material (PRD §4.3). No OSM
## water at all → empty node + a logged note (contract §8,
## no-faked-fidelity). Split out of TerrainBuilder in T1.1b.
## The synthetic S-curve (§7 V16) is deleted; _river_path survives only
## as a deprecated empty stub for the C-owned BuildingBuilder call
## until T4.1 migrates it to GroundTruth.water_at (procedural siting
## already double-guards on water_level_m, so nothing floats meanwhile).
## T4.4 owns bridges and decks bridge_ways_over_water below; T5.1 owns
## quay tree rows from real tree nodes; per-water-body levels beyond
## the bank rule are a future refinement. T3.5 adds shore-blend aprons
## (_shore_aprons): every shoreline carries a wet-to-dry land-cover
## band so the water edge blends by cover (sand/rock/wetland). T3.8
## moved the water look + surface tessellation to WaterSurface and the
## stone embankments to QuayBuilder.

## DEPRECATED (§7 V16): the synthetic river half-width, kept only for
## the BuildingBuilder exclusion call until T4.1 removes it. Real
## channel widths come from each waterway's width_m.
const RIVER_HALF := 10.0
## Open-sea datum in true-metre mode (Terrarium sea ≈ 0 m); mirrors
## FarTerrainBuilder.SEA_LEVEL_M. Legacy-squash runs reuse the -3.0
## datum (same sentinel rule as _far_water).
const SEA_LEVEL_M := 0.5
## Surface lifts above their level: polygon, ribbon (stacked so
## overlapping water never z-fights the datum plane under it).
const _POLY_LIFT := 0.03
const _RIBBON_LIFT := 0.05
## Freeboard: a body sits this far below its lowest bank.
const _FREEBOARD := 0.4
## T3.5 shore aprons: a wet-to-dry land-cover band along every
## shoreline, so the water edge blends by cover (sand stays sand into
## the sea, rock stays rock — no grass-into-sea, no pavement-into-lake).
const _APRON_LIFT := 0.09
const _WET_DARKEN := 0.70
const _UNKNOWN_SHORE := Color(0.60, 0.56, 0.46)

## Water subtree: real surfaces, or an empty node when the place has
## no OSM water (polygons, waterways, coastline) at all.
static func build_water(data: LocationData, ground: GroundTruth = null) -> Node3D:
	if ground == null:
		ground = GroundTruth.new(data)
	var root := Node3D.new()
	root.name = "Water"
	var channels := _channels(data)
	var coast := _has_coastline(data)
	var poly_count := _water_poly_count(data)
	if poly_count == 0 and channels.is_empty() and not coast:
		# Expected whenever the place has no mapped water or Overpass was
		# unreachable (already reported by the pipeline); not a defect.
		print("WaterBuilder: no OSM water for %s — rendering dry."
			% data.place_name)
		return root
	var mat := real_water_material()
	var wl := ground.water_level_m
	var levels := _poly_levels(data, ground, wl)
	for i in data.land_polygons.size():
		if levels.has(i):
			_add_polygon_surface(root, data, data.land_polygons[i], mat,
				float(levels[i]))
	for w in channels:
		_add_channel_ribbon(root, data, w, ground, mat, wl)
	if coast:
		_add_sea_plane(root, mat, wl, ground)
	else:
		_add_datum_plane(root, mat, wl)
	QuayBuilder.build(root, data, ground, channels, wl, levels)
	_shore_aprons(root, data, ground, channels)
	return root

## DEPRECATED (§7 V16, T3.4): the synthetic S-curve is deleted — this
## always returns empty so the C-owned BuildingBuilder exclusion
## compiles and passes through until T4.1 migrates it. Do not call.
static func _river_path(_data: LocationData) -> PackedVector2Array:
	return PackedVector2Array()

static func _path_dist(p: Vector2, path: PackedVector2Array) -> float:
	var best := INF
	for i in path.size() - 1:
		var a := path[i]
		var ab := path[i + 1] - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
		best = minf(best, (a + ab * t - p).length())
	return best

## Shared water material (T3.8 look v2 lives in WaterSurface).
static func real_water_material() -> ShaderMaterial:
	return WaterSurface.material()

## Waterways that read as channels (width > 0 with a centreline);
## coastline (width 0) is a boundary and only triggers the sea plane.
static func _channels(data: LocationData) -> Array:
	var out: Array = []
	for w in data.waterways:
		if not (w is Dictionary):
			continue
		var pts: PackedVector2Array = w.get("points", PackedVector2Array())
		if float(w.get("width_m", 0.0)) > 0.0 and pts.size() >= 2:
			out.append(w)
	return out

static func _has_coastline(data: LocationData) -> bool:
	for w in data.waterways:
		if w is Dictionary and str(w.get("class", "")) == "coastline":
			return true
	return false

static func _water_poly_count(data: LocationData) -> int:
	var n := 0
	for poly in data.land_polygons:
		if str(poly.get("class", "")) == "water":
			n += 1
	return n

## Detailed surface post size in internal units (rim/ribbon sampling).
static func _post_step(data: LocationData) -> float:
	return WorldScale.detailed_extent_units() / float(maxi(data.grid_size - 1, 1))

## Water level for one body: a low bank (10th percentile of the DRY
## bank samples) minus freeboard, never below the global datum. Bank
## samples that land in carved ground (an adjacent water polygon, a
## waterway channel's carve reach) are skipped: v1 took the plain
## minimum, which for the Seine read the carve floor and dropped the
## river ~16 m below its quays (a cliff, not an embankment). The
## percentile keeps one misaligned DEM sample from sinking the body.
static func _body_level(ground: GroundTruth, banks: Array, wl: float) -> float:
	return float(_body_estimate(ground, banks, wl)[0])

## [level, from_dry_banks]: the flag is false when fewer than three bank
## samples are dry (the body sits inside other water's carve), so a
## caller can adopt a neighbour's level instead (_poly_levels).
static func _body_estimate(ground: GroundTruth, banks: Array, wl: float) -> Array:
	var dry: Array = []
	var lowest := INF
	for p in banks:
		var v := p as Vector2
		var h := ground.height_at_world(v.x, v.y)
		lowest = minf(lowest, h)
		if ground.water_at(v.x, v.y) <= 0.0:
			dry.append(h)
	if dry.size() < 3:
		return [wl if is_inf(lowest) else maxf(wl, lowest - _FREEBOARD), false]
	dry.sort()
	var bank: float = dry[dry.size() / 10]
	return [maxf(wl, bank - _FREEBOARD), true]

## Level per water polygon (keyed by land_polygons index). One river is
## often several OSM polygons (the Seine around its islands); pieces
## whose banks all fall in a neighbour's carve adopt the highest level
## among the dry-estimated bodies their clipped bounds touch, so the
## pieces meet flush instead of stepping down to the datum.
static func _poly_levels(data: LocationData, ground: GroundTruth,
		wl: float) -> Dictionary:
	var step := _post_step(data)
	var est := {}
	var boxes := {}
	for i in data.land_polygons.size():
		var poly: Dictionary = data.land_polygons[i]
		if str(poly.get("class", "")) != "water":
			continue
		var pts: PackedVector2Array = poly.get("points", PackedVector2Array())
		if pts.size() < 3:
			continue
		var parts := _clip_water_poly(pts)
		if parts.is_empty():
			continue
		var banks: Array = []
		var r := Rect2()
		for k in parts.size():
			var part: PackedVector2Array = parts[k]
			banks.append_array(_outside_samples(part,
				maxf(step * 0.75, 1.0), step * 1.5))
			var pr := _ring_rect(part)
			r = pr if k == 0 else r.merge(pr)
		est[i] = _body_estimate(ground, banks, wl)
		boxes[i] = r.grow(step * 2.0)
	var out := {}
	for i in est:
		out[i] = float(est[i][0])
	for i in est:
		if bool(est[i][1]):
			continue
		for j in est:
			if j != i and bool(est[j][1]) \
					and (boxes[i] as Rect2).intersects(boxes[j] as Rect2):
				out[i] = maxf(float(out[i]), float(est[j][0]))
	return out

static func _ring_rect(ring: PackedVector2Array) -> Rect2:
	var r := Rect2(ring[0], Vector2.ZERO)
	for p in ring:
		r = r.expand(p)
	return r

## Bank samples beside a ring or centreline (rings: the offset that
## falls outside wins, winding-agnostic; open lines: both sides), for
## bank-level sampling.
static func _outside_samples(ring: PackedVector2Array, stride: float,
		offset: float, closed: bool = true) -> Array:
	var out: Array = []
	var segs := ring.size() if closed else ring.size() - 1
	for i in segs:
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
			if not closed:
				# Open centreline: both sides are bank (a point-in-ring
				# test is meaningless on an unclosed line).
				out.append(c + n * offset)
				out.append(c - n * offset)
			elif not TerrainBuilder.point_in_polygon(c + n * offset, ring):
				out.append(c + n * offset)
			elif not TerrainBuilder.point_in_polygon(c - n * offset, ring):
				out.append(c - n * offset)
	return out

## One OSM water polygon as a clipped, holed surface at its body
## level. Clipped to the detailed extent (past the mesh the far field
## owns the water); holes subtract (islands stay land).
static func _add_polygon_surface(root: Node3D, data: LocationData,
		poly: Dictionary, mat: Material, body_level: float) -> void:
	var pts: PackedVector2Array = poly.get("points", PackedVector2Array())
	if pts.size() < 3:
		return
	var step := _post_step(data)
	var holes: Array = poly.get("holes", [])
	var level := body_level + _POLY_LIFT
	for part in _clip_water_poly(pts):
		WaterSurface.add_polygon(root, part, holes, level, step, mat)

## Water polygon intersected with the detailed extent (past the mesh
## the far field owns the water).
static func _clip_water_poly(pts: PackedVector2Array) -> Array:
	var half := WorldScale.detailed_extent_units() * 0.5
	var frame := PackedVector2Array([Vector2(-half, -half),
		Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	var out: Array = []
	for part in Geometry2D.intersect_polygons(pts, frame):
		if (part as PackedVector2Array).size() >= 3:
			out.append(part)
	return out

## One waterway as a width-aware ribbon at its body level. Channels
## narrower than a quarter post drape on the ground instead (their
## honest carve is sub-post, so a flat ribbon would bury).
static func _add_channel_ribbon(root: Node3D, data: LocationData,
		w: Dictionary, ground: GroundTruth, mat: Material,
		wl: float) -> void:
	var pts: PackedVector2Array = w.get("points", PackedVector2Array())
	var half := float(w.get("width_m", 0.0)) * 0.5 \
		* WorldScale.metres_to_units()
	if half <= 0.0 or pts.size() < 2:
		return
	var step := _post_step(data)
	var bound := WorldScale.detailed_extent_units() * 0.5 + half + 2.0
	var draped := half < step * 0.25
	for run in _clip_runs(pts, bound):
		var line := _resample(run, maxf(step * 0.5, 1.0))
		if line.size() < 2:
			continue
		# A centreline running inside a mapped riverbank polygon (the
		# Seine's waterway=river over its water area) is already
		# surfaced by that polygon; a second ribbon at its own level
		# would step or z-fight against it.
		if _mostly_in_water_polys(line, ground):
			continue
		# Level per run from its own banks: ring-query lines span
		# kilometres, and far banks would skew it.
		var level := wl + _RIBBON_LIFT
		if not draped:
			level = _body_level(ground,
				_outside_samples(line, maxf(step * 0.75, 1.0),
					half + step * 0.75, false), wl) + _RIBBON_LIFT
		WaterSurface.add_ribbon(root, line, half, ground, level, draped, mat)

static func _mostly_in_water_polys(line: PackedVector2Array,
		ground: GroundTruth) -> bool:
	var inside := 0
	for p in line:
		if ground.land_class_at(p.x, p.y) == "water":
			inside += 1
	return inside >= int(ceil(line.size() * 0.8))

## Centreline runs inside ±bound (Liang-Barsky per segment). Past the
## mesh the far field owns the water; a ribbon run ends at the edge.
static func _clip_runs(pts: PackedVector2Array, bound: float) -> Array:
	var runs: Array = []
	var run := PackedVector2Array()
	for i in pts.size() - 1:
		var seg := _clip_seg(pts[i], pts[i + 1], bound)
		if seg.is_empty():
			if run.size() >= 2:
				runs.append(run)
			run = PackedVector2Array()
			continue
		if run.is_empty():
			run.append(seg[0])
		elif run[run.size() - 1].distance_to(seg[0]) > 0.001:
			if run.size() >= 2:
				runs.append(run)
			run = PackedVector2Array([seg[0]])
		run.append(seg[1])
	if run.size() >= 2:
		runs.append(run)
	return runs

static func _clip_seg(a: Vector2, b: Vector2, bound: float) -> PackedVector2Array:
	var t0 := 0.0
	var t1 := 1.0
	var d := b - a
	for e in 4:
		var p := 0.0
		var q := 0.0
		match e:
			0:
				p = -d.x
				q = a.x + bound
			1:
				p = d.x
				q = bound - a.x
			2:
				p = -d.y
				q = a.y + bound
			_:
				p = d.y
				q = bound - a.y
		if absf(p) < 0.000001:
			if q < 0.0:
				return PackedVector2Array()
		elif p < 0.0:
			t0 = maxf(t0, q / p)
		else:
			t1 = minf(t1, q / p)
		if t0 > t1:
			return PackedVector2Array()
	return PackedVector2Array([a.lerp(b, t0), a.lerp(b, t1)])

## Evenly spaced points along a line (≤ step apart) for ribbon meshes
## and water-crossing probes.
static func _resample(pts: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if pts.is_empty():
		return out
	out.append(pts[0])
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var seg_len := a.distance_to(b)
		var n := maxi(1, int(ceil(seg_len / maxf(step, 0.05))))
		for s in range(1, n + 1):
			out.append(a.lerp(b, float(s) / float(n)))
	return out

## Open sea past coastline ways: a plane at sea datum (the -3.0
## legacy sentinel reuses the datum, like FarTerrainBuilder._far_water).
static func _add_sea_plane(root: Node3D, mat: Material, wl: float,
		ground: GroundTruth) -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(WorldScale.detailed_extent_units(),
		WorldScale.detailed_extent_units())
	var mi := TerrainBuilder._add(root, plane, mat)
	mi.position.y = wl if is_equal_approx(wl, -3.0) else ground.render_y(0.0)

## Inland DEM sinks below the datum flood (v1 rule, now gated on OSM
## water existing somewhere in the place — never on dry land).
static func _add_datum_plane(root: Node3D, mat: Material, wl: float) -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(WorldScale.detailed_extent_units(),
		WorldScale.detailed_extent_units())
	var mi := TerrainBuilder._add(root, plane, mat)
	mi.position.y = wl

## Coastline ways (width 0): boundaries that trigger the sea plane
## and get a one-sided (land-side) shore apron below.
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
	var step := _post_step(data)
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
		for part in _clip_water_poly(pts):
			_apron_ring(verts, normals, colors, uvs, indices, part,
				true, ground, width, stride, bound)
		for h in poly.get("holes", []):
			if h is PackedVector2Array \
					and (h as PackedVector2Array).size() >= 3:
				for hpart in _clip_water_poly(h):
					_apron_ring(verts, normals, colors, uvs, indices,
						hpart, false, ground, width, stride, bound)
	for w in channels:
		var cpts: PackedVector2Array = \
			w.get("points", PackedVector2Array())
		var half := float(w.get("width_m", 0.0)) * 0.5 \
			* WorldScale.metres_to_units()
		for run in _clip_runs(cpts, bound + half + 2.0):
			_apron_line(verts, normals, colors, uvs, indices, run,
				half, ground, width, stride, bound)
	for w in _coastlines(data):
		var kpts: PackedVector2Array = \
			(w as Dictionary).get("points", PackedVector2Array())
		for run in _clip_runs(kpts, bound + width):
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
	var c := _UNKNOWN_SHORE
	if MaterialLibrary.has_ground_class(cls):
		c = MaterialLibrary.ground_color(cls)
	var wet := Color(c.r * _WET_DARKEN, c.g * _WET_DARKEN,
		c.b * _WET_DARKEN)
	var k := verts.size()
	verts.append(Vector3(inner.x,
		ground.height_at_world(inner.x, inner.y) + _APRON_LIFT,
		inner.y))
	verts.append(Vector3(outer.x,
		ground.height_at_world(outer.x, outer.y) + _APRON_LIFT,
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
	var coast := _has_coastline(data)
	var sea_y := ground.water_level_m \
		if is_equal_approx(ground.water_level_m, -3.0) else ground.render_y(SEA_LEVEL_M)
	for r in data.roads:
		if not (r is Dictionary) or not bool(r.get("bridge", false)):
			continue
		var pts: PackedVector2Array = r.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		for p in _resample(pts, 4.0):
			if ground.water_at(p.x, p.y) > 0.0:
				out.append(r)
				break
			if coast and ground.height_at_world(p.x, p.y) < sea_y:
				out.append(r)
				break
	return out
