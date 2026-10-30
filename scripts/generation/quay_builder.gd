class_name QuayBuilder
extends RefCounted

## Stone quays where OSM implies built waterfront (T3.8, split out of
## WaterBuilder): shoreline runs whose near bank reads urban get a
## solid limestone embankment from just below the water up to the real
## bank (DEM street level), so the bank never reads as a carved cliff
## or a floating slab. Banks standing ≥ TWO_TIER_M above the water
## (Paris: quays 5–8 m over the Seine) step down to a lower walkway
## (bas-port) LOW_WALK_M above the water with a parapet on the upper
## quay — the PRD §4.3 stone quay #8A8274. Natural banks get no stone:
## WaterBuilder's T3.5 shore aprons blend them by land cover.
## Everything merges into one triplanar-textured mesh (one draw call).

const QUAY_STONE := Color(0.541, 0.510, 0.455)  # PRD §4.3 #8A8274
const MAX_SPAN_M := 12.0     # taller banks are natural slopes, not quays
const MIN_SPAN_M := 1.2
const TWO_TIER_M := 4.5
const LOW_WALK_M := 2.4      # bas-port walkway height above the water
const WALK_WIDTH_M := 9.0
const PARAPET_H_M := 0.9
const PARAPET_T_M := 0.5
const UNDERWATER_M := 0.6

static var _stone_mat: StandardMaterial3D

## Dressed-stone material from the MaterialLibrary "render" set (the
## brightest fine-grained set: the beige limestone/sandstone photos are
## dark brown, and tinting them up to #8A8274 rendered near-black
## walls), calibrated in linear space to the PRD quay colour; world
## triplanar so a 30 m quay run tiles at real texture scale.
static func stone_material() -> StandardMaterial3D:
	if _stone_mat == null:
		var row: Dictionary = MaterialLibrary.PBR_SETS["render"]
		# Set means are already linear (a second decode read the stone
		# ~1.6x too bright: pale, textureless quay slabs).
		var mean: Color = row["mean"]
		var target := QUAY_STONE.srgb_to_linear()
		var tint := Color(target.r / maxf(mean.r, 0.01),
			target.g / maxf(mean.g, 0.01),
			target.b / maxf(mean.b, 0.01))
		# Linear tint: pbr_material sRGB-encodes albedo_color (T4.7).
		_stone_mat = MaterialLibrary.pbr_material("render", tint).duplicate()
		_stone_mat.uv1_triplanar = true
		_stone_mat.uv1_world_triplanar = true
	# ~3 m texture repeat in the current unit scale.
	var s := 1.0 / (3.0 * WorldScale.metres_to_units())
	_stone_mat.uv1_scale = Vector3(s, s, s)
	return _stone_mat

## Quays along every water-polygon rim and channel bank (urban banks).
static func build(root: Node3D, data: LocationData, ground: GroundTruth,
		channels: Array, wl: float, levels: Dictionary = {}) -> void:
	var step := WaterBuilder._post_step(data)
	var bound := WorldScale.detailed_extent_units() * 0.5
	# Plain Arrays (reference types): packed arrays in a Dictionary
	# copy on every append round-trip.
	var st := {"v": [], "n": [], "i": []}
	if levels.is_empty():
		levels = WaterBuilder._poly_levels(data, ground, wl)
	for pi in levels:
		var poly: Dictionary = data.land_polygons[pi]
		var pts: PackedVector2Array = poly.get("points", PackedVector2Array())
		var level := float(levels[pi])
		# Walk the REAL ring, not the clipped parts: clipping invents
		# frame-edge segments at the mesh boundary, and quays along
		# those read as a stone wall encircling the whole city.
		_walk(st, pts, true, true, 0.0, level, ground, step, bound)
		for h in poly.get("holes", []):
			if h is PackedVector2Array \
					and (h as PackedVector2Array).size() >= 3:
				_walk(st, h, true, false, 0.0, level, ground, step, bound)
	for w in channels:
		var cpts: PackedVector2Array = w.get("points", PackedVector2Array())
		var half := float(w.get("width_m", 0.0)) * 0.5 \
			* WorldScale.metres_to_units()
		for run in WaterBuilder._clip_runs(cpts, bound + half + 2.0):
			if run.size() < 2:
				continue
			if WaterBuilder._mostly_in_water_polys(run, ground):
				continue
			var level := WaterBuilder._body_level(ground,
				WaterBuilder._outside_samples(run, maxf(step * 0.75, 1.0),
					half + step * 0.75, false), wl)
			_walk(st, run, false, false, half, level, ground, step, bound)
	var idx := PackedInt32Array(st["i"])
	if idx.is_empty():
		return
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(st["v"])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(st["n"])
	arrays[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := TerrainBuilder._add(root, mesh, stone_material())
	mi.name = "Quays"

## Quay stations along a ring (water inside, or an island hole with
## water outside) or along both banks of a channel centreline,
## skipping segments past the mesh.
static func _walk(st: Dictionary, pts: PackedVector2Array, closed: bool,
		water_inside: bool, half: float, level: float, ground: GroundTruth,
		step: float, bound: float) -> void:
	var stride := maxf(step * 1.5, 4.0)
	var segs := pts.size() if closed else pts.size() - 1
	for i in segs:
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		var mid := (a + b) * 0.5
		if absf(mid.x) > bound or absf(mid.y) > bound:
			continue
		var seg_len := a.distance_to(b)
		if seg_len < 0.001:
			continue
		var dir := (b - a) / seg_len
		var n := Vector2(-dir.y, dir.x)
		# Bank samples sit beyond the carve blend (binary polygon
		# carves bleed one post through bilinear sampling; channel
		# carves reach half + 2.5), or siting reads the carve as bank.
		var off := step * 1.5 if closed else half + 2.5 + step
		var steps := maxi(1, int(seg_len / stride))
		var piece := seg_len / float(steps)
		for s in steps:
			var c := a.lerp(b, (float(s) + 0.5) / float(steps))
			var sides: Array = []
			if closed:
				var in_water := Geometry2D.is_point_in_polygon(c + n * off,
					pts)
				sides.append(-n if in_water == water_inside else n)
			else:
				sides.append(n)
				sides.append(-n)
			for land in sides:
				var shore: Vector2 = c + (land as Vector2) * half
				var bank: Vector2 = c + (land as Vector2) * off
				if ground.land_class_at(bank.x, bank.y) != "urban":
					continue
				_station(st, shore, land, dir, piece + 0.3,
					ground.height_at_world(bank.x, bank.y), level, step)

## One quay station: solid embankment block(s) from the shoreline
## landward across the carve ditch (≈1.1 posts), lower walkway notch
## on tall banks, parapet on the upper quay edge.
static func _station(st: Dictionary, shore: Vector2, land: Vector2,
		along: Vector2, length: float, top: float, level: float,
		step: float) -> void:
	var m := WorldScale.metres_to_units()
	var span := top - level
	# Banks taller than any real quay are slopes (or DEM edge/ridge
	# artefacts): a capped wall there floated as a free-standing slab.
	if span < MIN_SPAN_M * m or span > MAX_SPAN_M * m:
		return
	var base := level - UNDERWATER_M * m
	var depth := maxf(step * 1.1, 6.0 * m)
	if span >= TWO_TIER_M * m:
		var walk_w := minf(WALK_WIDTH_M * m, depth * 0.6)
		var low := level + LOW_WALK_M * m
		_box(st, shore, land, along, length, 0.0, depth, base, low)
		_box(st, shore, land, along, length, walk_w, depth, low, top)
		_box(st, shore, land, along, length, walk_w,
			walk_w + PARAPET_T_M * m, top, top + PARAPET_H_M * m)
	else:
		_box(st, shore, land, along, length, 0.0, depth, base, top)
		_box(st, shore, land, along, length, 0.0, PARAPET_T_M * m, top,
			top + PARAPET_H_M * m)

## Oriented box spanning [d0, d1] landward of `shore`, `length` along
## the bank, y0..y1. Faces wind outward (CCW seen from outside).
static func _box(st: Dictionary, shore: Vector2, land: Vector2,
		along: Vector2, length: float, d0: float, d1: float, y0: float,
		y1: float) -> void:
	var h := along * (length * 0.5)
	var p0 := shore + land * d0
	var p1 := shore + land * d1
	var c: Array = [p0 - h, p0 + h, p1 + h, p1 - h]
	var v: Array = st["v"]
	var nn: Array = st["n"]
	var ii: Array = st["i"]
	var lo: Array = []
	var hi: Array = []
	for q in c:
		lo.append(Vector3((q as Vector2).x, y0, (q as Vector2).y))
		hi.append(Vector3((q as Vector2).x, y1, (q as Vector2).y))
	var faces: Array = [
		[hi[0], hi[1], hi[2], hi[3]],
		[lo[3], lo[2], lo[1], lo[0]],
	]
	for e in 4:
		faces.append([lo[e], lo[(e + 1) % 4], hi[(e + 1) % 4], hi[e]])
	var centre := Vector3((p0.x + p1.x) * 0.5, (y0 + y1) * 0.5,
		(p0.y + p1.y) * 0.5)
	for f in faces:
		var a: Vector3 = f[0]
		var b: Vector3 = f[1]
		var d: Vector3 = f[2]
		var fn := (b - a).cross(d - a).normalized()
		var flip := fn.dot((a + d) * 0.5 - centre) < 0.0
		if flip:
			fn = -fn
		var k := v.size()
		for corner in f:
			v.append(corner)
			nn.append(fn)
		# Godot front faces are clockwise seen from the normal side.
		if flip:
			ii.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
		else:
			ii.append_array([k, k + 2, k + 1, k, k + 3, k + 2])
