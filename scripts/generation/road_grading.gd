class_name RoadGrading
extends RefCounted

## Road grading for GroundTruth: DEM noise and the 9–25 m post grid make
## a street ride every bump and crease of the terrain mesh, so its ribbon
## looks wobbly. Each street and main road gets a smoothed height profile
## along its centreline (a triangular low-pass over SMOOTH_M), and the
## posts around it are pulled onto that profile: fully across the
## carriageway plus a margin, easing out to the surroundings. The ribbon
## RoadBuilder drapes on the graded surface then runs flush and fair.
## Bridges, tunnels, footpaths and carved water posts are left alone.

## Half-window of the profile low-pass, metres of road.
const SMOOTH_M := 40.0
## Centreline sample spacing, metres.
const SAMPLE_M := 4.0
## Largest cut or fill a post takes (source metres), so a real hillside
## road is not bulldozed flat. DEM noise and post-grid creases fit within
## a metre; at 2.5 m a crest on a Turku hill street was cut 2.3 m, and on
## a 9–25 m grid the ground beside the street went down with it.
const MAX_SHIFT_M := 1.0
## On a coarse surface-model DEM (SRTM / EU-DEM class, no bare-earth model
## replacing it: Seoul, Busan, Istanbul ...) the post grid carries 3–8 m
## mounds 30–90 m across where city blocks and canopy were, which the 1 m
## cap leaves under every street. There the profile low-pass spans a block
## and a post may move further; a linear ramp still maps to itself, so
## only crests and dips sharper than the window are trimmed. ArcticDEM
## (2 m, north of 60°N: Turku's hill streets) keeps the defaults.
const COARSE_SMOOTH_M := 70.0
const COARSE_MAX_SHIFT_M := 2.5
## How far along a road from the bridge it leads onto its embankment is
## kept (_keep_embankments), metres.
const EMBANKMENT_M := 40.0
## Test hook: false grades coarse DEMs with the defaults too.
static var coarse_enabled := true

## The per-road profile and stamps run natively (RoadGrader) when the
## library is loaded.
static var _native := ClassDB.class_exists("RoadGrader")

## True when `data`'s heights are a coarse surface model graded harder.
static func coarse(data: LocationData) -> bool:
	return coarse_enabled and BareEarth.applies(data) and not BareEarth.surface_model(data)

## Grades `surface` (size × size posts, `step` units apart, source
## metres in Y) in place. `level` marks carved water posts (-INF = dry).
## `smooth_m` / `max_shift_m`: SMOOTH_M / MAX_SHIFT_M, or the COARSE_ pair.
static func grade(surface: PackedFloat32Array, level: PackedFloat32Array,
		size: int, step: float, roads: Array, m2u: float,
		smooth_m: float = SMOOTH_M, max_shift_m: float = MAX_SHIFT_M) -> void:
	if size < 2 or roads.is_empty():
		return
	var src := surface.duplicate()
	var best_w := PackedFloat32Array()
	best_w.resize(size * size)
	var best_h := PackedFloat32Array()
	best_h.resize(size * size)
	# Distance to the sample a post took its height from: on equal weight
	# the nearest sample wins, so a post on a slope is not handed the
	# height of a sample a few metres up or down the street.
	var best_d := PackedFloat32Array()
	best_d.resize(size * size)
	best_d.fill(INF)
	var heads := _bridge_heads(roads)
	var grader: Object = null
	if _native:
		grader = ClassDB.instantiate("RoadGrader")
		grader.setup(src, level, size, step, max_shift_m)
	for road in roads:
		if not (road is Dictionary):
			continue
		var r: Dictionary = road
		if bool(r.get("bridge", false)) or bool(r.get("tunnel", false)):
			continue
		if RoadBuilder._rank(str(r.get("class", "unclassified"))) < 1:
			continue
		var pts: PackedVector2Array = r.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var half := maxf(float(r.get("width_m", 0.0)), 3.0) * 0.5 * m2u
		var line := GroundTruth._densify(pts, SAMPLE_M * m2u)
		var heights := PackedFloat32Array()
		var valid := PackedByteArray()
		var arc := PackedFloat32Array()
		var s := 0.0
		for i in line.size():
			if i > 0:
				s += line[i].distance_to(line[i - 1])
			arc.append(s)
			var p := line[i]
			heights.append(_sample(src, size, step, p))
			valid.append(1 if _dry(level, size, step, p) else 0)
		var prof := _smooth(heights, valid, arc, smooth_m * m2u)
		_keep_embankments(prof, heights, line, arc, pts, heads, m2u)
		if grader != null:
			grader.stamp_line(line, prof, valid, half)
			continue
		for i in line.size():
			if valid[i] == 1:
				_stamp(line[i], prof[i], half, src, best_w, best_h, best_d, level, size, step, max_shift_m)
	if grader != null:
		# `surface` is the caller's array: refilled in place.
		var graded: PackedFloat32Array = grader.apply(surface)
		surface.resize(0)
		surface.append_array(graded)
		return
	for i in size * size:
		if best_w[i] > 0.0:
			surface[i] = lerpf(surface[i], best_h[i], best_w[i])

## End points of road bridges (not footbridges).
static func _bridge_heads(roads: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for road in roads:
		if not (road is Dictionary) or not bool((road as Dictionary).get("bridge", false)):
			continue
		if RoadBuilder._rank(str((road as Dictionary).get("class", ""))) < 1:
			continue
		var pts: PackedVector2Array = (road as Dictionary).get("points", PackedVector2Array())
		if pts.size() >= 2:
			out.append(pts[0])
			out.append(pts[pts.size() - 1])
	return out

## Within EMBANKMENT_M of a bridge the road leads onto, its profile is never
## cut below the ground: the crest there is the bridge's embankment, and
## smoothed away the motorway met its creek bridge at the water's level.
static func _keep_embankments(prof: PackedFloat32Array, heights: PackedFloat32Array, line: PackedVector2Array,
		arc: PackedFloat32Array, pts: PackedVector2Array, heads: PackedVector2Array, m2u: float) -> void:
	if heads.is_empty() or line.is_empty():
		return
	var touch := 1.0 * m2u
	var reach := EMBANKMENT_M * m2u
	var total := arc[arc.size() - 1]
	for e in heads:
		var from_start := pts[0].distance_to(e) <= touch
		var from_end := pts[pts.size() - 1].distance_to(e) <= touch
		if not from_start and not from_end:
			continue
		for i in line.size():
			var d := arc[i] if from_start else total - arc[i]
			if d <= reach:
				prof[i] = maxf(prof[i], heights[i])

## Largest cut or fill (source metres) a post inside a mapped square takes:
## a surface-model DEM leaves 3–8 m mounds across a plaza, while a real
## hillside square keeps its slope in the fitted plane.
const AREA_MAX_SHIFT_M := 3.0
## Area classes laid flat: squares, plazas and paved forecourts.
const AREA_CLASSES: Array[String] = ["pedestrian", "footway"]

## Lays each mapped square (a pedestrian or footway way with area=yes) on
## the least-squares plane of its own posts, easing out over one post past
## its outline. Larger squares go first, so a forecourt inside a square
## (Gwanghwamun's woldae inside the plaza) takes its own plane.
static func grade_areas(surface: PackedFloat32Array, level: PackedFloat32Array,
		size: int, step: float, roads: Array) -> void:
	if size < 2 or roads.is_empty():
		return
	var areas: Array = []
	for road in roads:
		if not (road is Dictionary):
			continue
		var r: Dictionary = road
		if not bool(r.get("area", false)) or str(r.get("class", "")) not in AREA_CLASSES \
				or bool(r.get("bridge", false)) or bool(r.get("tunnel", false)):
			continue
		var ring: PackedVector2Array = r.get("points", PackedVector2Array())
		if ring.size() >= 3:
			areas.append([_area(ring), ring])
	areas.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	for a in areas:
		_flatten(surface, level, size, step, a[1])

## Fits a plane to the dry posts inside `ring` and pulls them (and a post
## of margin outside) onto it, at most AREA_MAX_SHIFT_M each.
static func _flatten(surface: PackedFloat32Array, level: PackedFloat32Array,
		size: int, step: float, ring: PackedVector2Array) -> void:
	var hs := float(size) * 0.5
	var lo := ring[0]
	var hi := ring[0]
	for p in ring:
		lo = lo.min(p)
		hi = hi.max(p)
	var x0 := clampi(int(floor((lo.x - step) / step + hs)), 0, size - 1)
	var x1 := clampi(int(ceil((hi.x + step) / step + hs)), 0, size - 1)
	var z0 := clampi(int(floor((lo.y - step) / step + hs)), 0, size - 1)
	var z1 := clampi(int(ceil((hi.y + step) / step + hs)), 0, size - 1)
	# Normal equations of h = a + b·x + c·z over the inside posts (x, z in posts).
	var n := 0.0
	var sx := 0.0
	var sz := 0.0
	var sxx := 0.0
	var sxz := 0.0
	var szz := 0.0
	var sh := 0.0
	var sxh := 0.0
	var szh := 0.0
	var inside := {}
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			var i := z * size + x
			if not is_inf(level[i]):
				continue
			var w := Vector2((float(x) - hs) * step, (float(z) - hs) * step)
			if not Geometry2D.is_point_in_polygon(w, ring):
				continue
			inside[i] = true
			var fx := float(x - x0)
			var fz := float(z - z0)
			var h := surface[i]
			n += 1.0
			sx += fx
			sz += fz
			sxx += fx * fx
			sxz += fx * fz
			szz += fz * fz
			sh += h
			sxh += fx * h
			szh += fz * h
	if n < 3.0:
		return
	var m := Basis(Vector3(n, sx, sz), Vector3(sx, sxx, sxz), Vector3(sz, sxz, szz))
	var coef := Vector3(sh / n, 0.0, 0.0)
	if absf(m.determinant()) > 1e-6:
		coef = m.inverse() * Vector3(sh, sxh, szh)
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			var i := z * size + x
			if not is_inf(level[i]):
				continue
			var wgt := 1.0
			if not inside.has(i):
				var w := Vector2((float(x) - hs) * step, (float(z) - hs) * step)
				var d := _ring_distance(w, ring)
				if d >= step:
					continue
				wgt = 1.0 - d / step
			var target := coef.x + coef.y * float(x - x0) + coef.z * float(z - z0)
			var flat := clampf(target, surface[i] - AREA_MAX_SHIFT_M, surface[i] + AREA_MAX_SHIFT_M)
			surface[i] = lerpf(surface[i], flat, wgt)

## Shoelace area of a ring (world units²).
static func _area(ring: PackedVector2Array) -> float:
	var s := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		s += a.x * b.y - b.x * a.y
	return absf(s) * 0.5

## Distance from `p` to the nearest edge of `ring`.
static func _ring_distance(p: Vector2, ring: PackedVector2Array) -> float:
	var best := INF
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)))
	return best

## Triangular low-pass of the dry samples within `radius` of each one.
static func _smooth(h: PackedFloat32Array, valid: PackedByteArray,
		arc: PackedFloat32Array, radius: float) -> PackedFloat32Array:
	if _native:
		return ClassDB.class_call_static("RoadGrader", "smooth", h, valid, arc, radius)
	var out := PackedFloat32Array()
	var n := h.size()
	for i in n:
		var sum := 0.0
		var wsum := 0.0
		var j := i
		while j >= 0 and arc[i] - arc[j] <= radius:
			if valid[j] == 1:
				var w := 1.0 - (arc[i] - arc[j]) / radius
				sum += h[j] * w
				wsum += w
			j -= 1
		j = i + 1
		while j < n and arc[j] - arc[i] <= radius:
			if valid[j] == 1:
				var w2 := 1.0 - (arc[j] - arc[i]) / radius
				sum += h[j] * w2
				wsum += w2
			j += 1
		out.append(sum / wsum if wsum > 0.0 else h[i])
	return out

## Pulls posts near `p` toward `target`: weight 1 across the carriageway
## and a post of margin, easing to 0 by 1.8 posts out.
static func _stamp(p: Vector2, target: float, half: float, src: PackedFloat32Array,
		best_w: PackedFloat32Array, best_h: PackedFloat32Array, best_d: PackedFloat32Array,
		level: PackedFloat32Array, size: int, step: float, max_shift_m: float = MAX_SHIFT_M) -> void:
	var inner := half + step * 0.5
	var reach := half + step * 1.8
	var hs := float(size) * 0.5
	var x0 := clampi(int(floor((p.x - reach) / step + hs)), 0, size - 1)
	var x1 := clampi(int(ceil((p.x + reach) / step + hs)), 0, size - 1)
	var z0 := clampi(int(floor((p.y - reach) / step + hs)), 0, size - 1)
	var z1 := clampi(int(ceil((p.y + reach) / step + hs)), 0, size - 1)
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			var i := z * size + x
			if not is_inf(level[i]):
				continue
			var d := Vector2((float(x) - hs) * step, (float(z) - hs) * step).distance_to(p)
			if d >= reach:
				continue
			var w := 1.0 - smoothstep(inner, reach, d)
			if w > best_w[i] or (w == best_w[i] and d < best_d[i]):
				best_w[i] = w
				best_d[i] = d
				best_h[i] = clampf(target, src[i] - max_shift_m, src[i] + max_shift_m)

## True when the post nearest `p` is inside the surface and not water-carved.
static func _dry(level: PackedFloat32Array, size: int, step: float, p: Vector2) -> bool:
	var hs := float(size) * 0.5
	var x := roundi(p.x / step + hs)
	var z := roundi(p.y / step + hs)
	if x < 0 or z < 0 or x >= size or z >= size:
		return false
	return is_inf(level[z * size + x])

## Bilinear height of the post grid at world XZ (clamped to the edge).
static func _sample(h: PackedFloat32Array, size: int, step: float, p: Vector2) -> float:
	var hs := float(size) * 0.5
	var fx := clampf(p.x / step + hs, 0.0, float(size - 1))
	var fz := clampf(p.y / step + hs, 0.0, float(size - 1))
	var x0 := mini(int(fx), size - 2)
	var z0 := mini(int(fz), size - 2)
	var tx := fx - float(x0)
	var tz := fz - float(z0)
	var a := lerpf(h[z0 * size + x0], h[z0 * size + x0 + 1], tx)
	var b := lerpf(h[(z0 + 1) * size + x0], h[(z0 + 1) * size + x0 + 1], tx)
	return lerpf(a, b, tz)
