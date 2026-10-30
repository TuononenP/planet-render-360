class_name GroundTruth
extends RefCounted

## One smoothed/carved height + water + land-cover surface per place
## (contract §3, T1.4). Built once from DEM + OSM polygons + waterways
## (contract §2.6; the synthetic river path died in T3.4, §7 V16);
## every builder and the camera spawn sample this instead of
## recomputing heights.
##
## Transitional units: XZ inputs are current internal world units.
## Y-scale fix (diag-2026-10-28-terrain-scale): true-metre data
## (heights in metres ASL since T1.3) is converted here, once, to
## render units — relief x WorldScale.metres_to_units() about the
## viewpoint datum (centre_elevation_m) — so rendered rise/run matches
## XZ, which is scaled by the same factor. Without this, flat Paris
## rendered with ~4x vertical exaggeration. Legacy-squash and
## procedural data (water_level == -3.0 sentinel, the same marker
## Far/Water use) is already in render units and passes through.
## Since the T7.0 metre cutover metres_to_units() is 1.0, so this is
## the datum rebase only.
##
## T3.1 detailed-extent remap: the surface spans the FULL detailed
## extent (contract §1.2/§2.2). Real z14/z12 grids cover a 576/144 px
## window wider than it, so each post samples its own true position in
## that window (DemRegistration) instead of stretching the window
## across the mesh (the v1 compression that misaligned DEM against
## OSM). Procedural grids and fixtures already span the extent, 1:1.
##
## Construction reads data.heights / data.water_level / data polygons
## once (the single authorized reader — grep gate in scenery_test).
## All samplers are pure reads; outside the extent they clamp to the
## nearest edge value, never NaN.

## Honest metre half-extent of the detailed surface (contract §3):
## DETAILED_EXTENT_M / 2 (1200 m).
var extent_m: float = 0.0
## Water datum copied from data.water_level at construction; builders
## read this instead of the global (contract §7 V3).
var water_level_m: float = 0.0
## Min/max of the built surface (the terrain mesh range without a rescan).
var surface_min: float = 0.0
var surface_max: float = 0.0
## ASL datum (m) that render_y maps to Y=0: the viewpoint elevation.
var datum_m: float = 0.0
var _y_scale: float = 1.0

## Metres ASL -> render Y (see the Y-scale note above).
func render_y(m_asl: float) -> float:
	return (m_asl - datum_m) * _y_scale

## Inverse of render_y, for ASL thresholds (sea level, far water).
func asl_y(render: float) -> float:
	return render / _y_scale + datum_m

var _surface: PackedFloat32Array = PackedFloat32Array()
var _size: int = 0
var _step_units: float = 1.0
var _half_units: float = 0.0
var _land: Array = []
var _buildings: Array = []
## Local water surface per post (render units) for posts a water body
## or channel carved; -INF = no carve (water_level_at falls back to the
## global datum). Bodies are levelled from their own banks, the same
## rule WaterBuilder uses (10th-percentile dry bank − freeboard).
var _level: PackedFloat32Array = PackedFloat32Array()

## Bank freeboard (mirrors WaterBuilder._FREEBOARD) and carve depth
## below that local surface. v1 carved to the GLOBAL datum
## (centre − relief/5): a ~190 m trench at Interlaken, −164 m at
## Big Sur. Now every carve is a few metres under its own water.
const FREEBOARD_M := 0.4
const CARVE_DEPTH_M := 2.0

## Builds the surface synchronously (a pipeline stage with real
## progress once the pipeline constructs this in stage 3; until then
## builders construct it from the data they already receive).
## Requires valid data (heights.size() == grid_size²); null leaves an
## empty surface for WorldCache to restore a saved one into.
func _init(data: LocationData) -> void:
	if data == null:
		return
	var size := data.grid_size
	_size = size
	var extent_units := WorldScale.detailed_extent_units()
	_step_units = extent_units / float(maxi(size - 1, 1))
	_half_units = extent_units * 0.5
	extent_m = _half_units / WorldScale.metres_to_units()
	water_level_m = data.water_level
	_land = data.land_polygons
	_buildings = data.buildings
	_surface.resize(size * size)
	# T3.1 remap: resample the heights window onto the surface posts
	# (bilinear over the central sub-window for real grids, 1:1 for
	# procedural/fixtures), then the v1 3x3 centre-double-weighted blur.
	var frac := _extent_span_frac(data)
	var geo := DemRegistration.applies(data) and frac < 0.9999
	var step_m := _step_units / WorldScale.metres_to_units()
	for z in size:
		for x in size:
			_surface[z * size + x] = _grid_bilinear(data, DemRegistration.grid_index(
				data, size, step_m, x, z)) if geo else _resampled_height(data, size, frac, x, z)
	var tmp := PackedFloat32Array()
	tmp.resize(size * size)
	_blur_pass(_surface, tmp, size)
	_surface = tmp
	# T3.1 slope-preserving low-relief smooth (replaces the v1 dune rule
	# that erased all sub-20 m relief): two extra symmetric 3x3 passes,
	# which map a linear ramp to itself while attenuating metre-scale
	# DEM noise. Triggered on the post-remap surface range (metres).
	var surf_min := INF
	var surf_max := -INF
	for h in _surface:
		surf_min = minf(surf_min, h)
		surf_max = maxf(surf_max, h)
	if surf_max - surf_min < 20.0:
		var buf := PackedFloat32Array()
		buf.resize(size * size)
		for i in 2:
			_blur_pass(_surface, buf, size)
			var swap := _surface
			_surface = buf
			buf = swap
	# Water polygons carve below their own bank-levelled surface, or
	# the channel terrain covers the water entirely (v1 _heights, which
	# carved to the global datum instead).
	_level.resize(size * size)
	_level.fill(-INF)
	_carve_polygons(data)
	# T3.4 waterway carve (contract §3; §7 V16 deleted the synthetic
	# S-curve this replaces): width-aware channels on real centrelines.
	_carve_waterways(data)
	# Y-scale conversion (see header): carving above is in source
	# metres; the stored surface and water datum are render units.
	if not is_equal_approx(data.water_level, -3.0):
		_y_scale = WorldScale.metres_to_units()
		datum_m = data.centre_elevation_m
		if absf(datum_m) < 0.001 and size >= 1:
			datum_m = _surface[(size / 2) * size + size / 2]
		for i in _surface.size():
			_surface[i] = render_y(_surface[i])
			if not is_inf(_level[i]):
				_level[i] = render_y(_level[i])
		water_level_m = render_y(water_level_m)
	surface_min = INF
	surface_max = -INF
	for h2 in _surface:
		surface_min = minf(surface_min, h2)
		surface_max = maxf(surface_max, h2)

## Whether a point falls inside any hole ring (islands stay dry).
static func _in_holes(p: Vector2, holes: Array) -> bool:
	for h in holes:
		if h is PackedVector2Array \
				and WorldScale.point_in_polygon(p, h as PackedVector2Array):
			return true
	return false

## Width-aware channel carve for OSM waterway lines (T3.4, contract
## §2.6/§3): posts near a centreline dip toward water_level_m - 0.7
## with a smoothstep bank profile (the v1 river shape, now on real
## geometry). Coastline (width 0) is a boundary, not a channel — the
## sea plane covers it. Per-segment bboxes keep this cheap: posts
## outside a segment's reach are never visited.
func _carve_waterways(data: LocationData) -> void:
	var size := _size
	if size < 2:
		return
	var m2u := WorldScale.metres_to_units()
	for w in data.waterways:
		if not (w is Dictionary):
			continue
		var half := float((w as Dictionary).get("width_m", 0.0)) * 0.5 * m2u
		if half <= 0.0:
			continue
		var pts: PackedVector2Array = \
			(w as Dictionary).get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var reach := half + 2.5
		# Local surface per vertex from the pre-carve banks, so a
		# channel follows its own valley down instead of the datum.
		var line := _densify(pts, _step_units)
		var levels := PackedFloat32Array()
		for i in line.size():
			levels.append(_channel_level(line, i, half))
		for s in line.size() - 1:
			_carve_segment(line[s], line[s + 1], half, reach, size,
				levels[s], levels[s + 1])

## Polyline with no segment longer than `sp` (vertices kept).
static func _densify(pts: PackedVector2Array, sp: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in pts.size() - 1:
		var n := maxi(1, int(ceil(pts[i].distance_to(pts[i + 1]) / maxf(sp, 0.01))))
		for k in n:
			out.append(pts[i].lerp(pts[i + 1], float(k) / float(n)))
	out.append(pts[pts.size() - 1])
	return out

## Water surface at channel vertex i: the lower pre-carve bank beside
## it, minus freeboard, never below the global datum.
func _channel_level(line: PackedVector2Array, i: int, half: float) -> float:
	var a := line[maxi(i - 1, 0)]
	var b := line[mini(i + 1, line.size() - 1)]
	var dir := (b - a).normalized() if a.distance_to(b) > 0.001 else Vector2.RIGHT
	var off := Vector2(-dir.y, dir.x) * (half + _step_units * 1.5)
	var p := line[i]
	var bank := minf(height_at_world(p.x + off.x, p.y + off.y),
		height_at_world(p.x - off.x, p.y - off.y))
	return maxf(water_level_m, bank - FREEBOARD_M)

## Bank-levelled polygon carve: each OSM water polygon sits at the 10th
## percentile of its dry pre-carve bank samples − freeboard (the
## WaterBuilder rule), and posts inside carve CARVE_DEPTH_M under it.
func _carve_polygons(data: LocationData) -> void:
	var water: Array = []
	for poly in data.land_polygons:
		if str(poly.get("class", "")) != "water":
			continue
		var pts: PackedVector2Array = poly.get("points", PackedVector2Array())
		if pts.size() < 3:
			continue
		var r := Rect2(pts[0], Vector2.ZERO)
		for q in pts:
			r = r.expand(q)
		water.append([pts, poly.get("holes", []), r])
	var size := _size
	var hu := float(size) / 2.0
	var levels: Array = []
	for wpoly in water:
		levels.append(_polygon_level(wpoly, water))
	for k in water.size():
		var pts: PackedVector2Array = water[k][0]
		var r: Rect2 = water[k][2]
		var level: float = levels[k]
		var x0 := clampi(int(floor(r.position.x / _step_units + hu)), 0, size - 1)
		var x1 := clampi(int(ceil(r.end.x / _step_units + hu)), 0, size - 1)
		var z0 := clampi(int(floor(r.position.y / _step_units + hu)), 0, size - 1)
		var z1 := clampi(int(ceil(r.end.y / _step_units + hu)), 0, size - 1)
		for z in range(z0, z1 + 1):
			for x in range(x0, x1 + 1):
				var p := Vector2((float(x) - hu) * _step_units,
					(float(z) - hu) * _step_units)
				if WorldScale.point_in_polygon(p, pts) \
						and not _in_holes(p, water[k][1]):
					var i := z * size + x
					_surface[i] = minf(_surface[i], level - CARVE_DEPTH_M)
					_level[i] = maxf(_level[i], level)

## One polygon's surface from dry bank samples inside the extent (not
## in any water polygon); with <3 such samples (a lake filling the
## extent) the lowest pre-carve post inside it stands in for the DEM
## water surface.
func _polygon_level(wpoly: Array, water: Array) -> float:
	var pts: PackedVector2Array = wpoly[0]
	var off := _step_units * 1.5
	var stride := maxf(_step_units * 0.75, 1.0)
	var dry: Array = []
	var inner := INF
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		var seg := a.distance_to(b)
		if seg < 0.001:
			continue
		var dir := (b - a) / seg
		var n := Vector2(-dir.y, dir.x)
		var steps := maxi(1, int(seg / stride))
		for s in steps:
			var c := a.lerp(b, (float(s) + 0.5) / float(steps))
			for q in [c + n * off, c - n * off]:
				var v := q as Vector2
				if not is_inside(v.x, v.y):
					continue
				var h := height_at_world(v.x, v.y)
				if _in_water(v, water):
					inner = minf(inner, h)
				else:
					dry.append(h)
	if dry.size() >= 3:
		dry.sort()
		return maxf(water_level_m, float(dry[dry.size() / 10]) - FREEBOARD_M)
	if not is_inf(inner):
		return maxf(water_level_m, inner)
	return water_level_m

static func _in_water(p: Vector2, water: Array) -> bool:
	for w in water:
		if (w[2] as Rect2).has_point(p) \
				and WorldScale.point_in_polygon(p, w[0]) \
				and not _in_holes(p, w[1]):
			return true
	return false

func _carve_segment(a: Vector2, b: Vector2, half: float, reach: float,
		size: int, la: float, lb: float) -> void:
	var h := float(size) * 0.5
	var x0 := clampi(int(floor((minf(a.x, b.x) - reach) / _step_units + h)),
		0, size - 1)
	var x1 := clampi(int(ceil((maxf(a.x, b.x) + reach) / _step_units + h)),
		0, size - 1)
	var z0 := clampi(int(floor((minf(a.y, b.y) - reach) / _step_units + h)),
		0, size - 1)
	var z1 := clampi(int(ceil((maxf(a.y, b.y) + reach) / _step_units + h)),
		0, size - 1)
	var inner := maxf(half - 0.5, 0.0)
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			var wx := (float(x) - h) * _step_units
			var wz := (float(z) - h) * _step_units
			var p := Vector2(wx, wz)
			var d := _seg_dist(p, a, b)
			if d < reach:
				var ab := b - a
				var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001),
					0.0, 1.0)
				var level := lerpf(la, lb, t)
				var i := z * size + x
				var depth := lerpf(level - CARVE_DEPTH_M,
					_surface[i], smoothstep(inner, reach, d))
				_surface[i] = minf(_surface[i], depth)
				if _surface[i] < level:
					_level[i] = maxf(_level[i], level)

static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001),
		0.0, 1.0)
	return (a + ab * t - p).length()

## Fraction of the heights grid covered by the detailed surface
## (T3.1 remap): extent ground span / heights-window ground span.
## Real grids report metres_per_px + source_zoom in dem_source (the
## z14 window is DemFetcher.WINDOW_NEAR_PX; the z12 fallback window
## is the 144 px of DemFetcher._emit_from_image — same ground by T2.1
## design). Procedural grids ({source_zoom: 0}) and fixtures (empty
## dem_source) already span the extent → 1.0. Clamped to ≤1.0: the
## mosaic always covers the extent (251 px worst case at the equator).
static func _extent_span_frac(data: LocationData) -> float:
	var mpp := float(data.dem_source.get("metres_per_px", 0.0))
	if mpp <= 0.0:
		return 1.0
	var src_zoom := int(data.dem_source.get("source_zoom", 0))
	var window_px := DemFetcher.WINDOW_NEAR_PX \
		if src_zoom == DemFetcher.ZOOM_NEAR else 144.0
	var span_m := window_px * mpp
	if span_m <= 0.0:
		return 1.0
	var extent_span_m := WorldScale.detailed_extent_units() \
		/ WorldScale.metres_to_units()
	return clampf(extent_span_m / span_m, 0.05, 1.0)

## Heights-grid value for surface post (x, z): central-sub-window
## bilinear resample for real grids (frac < 1), exact 1:1 post read
## otherwise (bit-identical to the v1 smooth input). Clamped, never NaN.
static func _resampled_height(data: LocationData, size: int, frac: float,
		x: int, z: int) -> float:
	if frac >= 0.9999 or size < 2:
		return data.height_at(x, z)
	var half := float(size) / 2.0
	var fx := clampf((float(x) - half) * frac + half, 0.0, float(size - 1))
	var fz := clampf((float(z) - half) * frac + half, 0.0, float(size - 1))
	return _grid_bilinear(data, Vector2(fx, fz))

## Clamped bilinear read of the heights grid at a fractional index.
static func _grid_bilinear(data: LocationData, f: Vector2) -> float:
	var size := data.grid_size
	var fx := clampf(f.x, 0.0, float(size - 1))
	var fz := clampf(f.y, 0.0, float(size - 1))
	var x0 := mini(int(fx), size - 2)
	var z0 := mini(int(fz), size - 2)
	var tx := fx - float(x0)
	var tz := fz - float(z0)
	var a := lerpf(data.height_at(x0, z0), data.height_at(x0 + 1, z0), tx)
	var b := lerpf(data.height_at(x0, z0 + 1), data.height_at(x0 + 1, z0 + 1), tx)
	return lerpf(a, b, tz)

## One 3x3 centre-double-weighted blur pass (the v1 _heights kernel),
## src → dst; edges reuse the nearest post (clamped, like height_at).
static func _blur_pass(src: PackedFloat32Array, dst: PackedFloat32Array,
		size: int) -> void:
	for z in size:
		for x in size:
			var sum := _clamped_post(src, size, x, z) * 2.0
			var n := 2.0
			for dz in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					if dx == 0 and dz == 0:
						continue
					sum += _clamped_post(src, size, x + dx, z + dz)
					n += 1.0
			dst[z * size + x] = sum / n

static func _clamped_post(src: PackedFloat32Array, size: int, x: int,
		z: int) -> float:
	return src[clampi(z, 0, size - 1) * size + clampi(x, 0, size - 1)]

## Final render Y at world XZ: smoothed DEM (slope-preserving
## low-relief smooth, never a global flatten), water-carved channels
## applied. Bilinear between grid posts; outside clamps to the
## nearest edge, never NaN.
func height_at_world(x: float, z: float) -> float:
	if _size < 2 or _surface.size() != _size * _size:
		return water_level_m
	var fx := clampf(x / _step_units + float(_size) * 0.5, 0.0, float(_size - 1))
	var fz := clampf(z / _step_units + float(_size) * 0.5, 0.0, float(_size - 1))
	var x0 := mini(int(fx), _size - 2)
	var z0 := mini(int(fz), _size - 2)
	var tx := fx - float(x0)
	var tz := fz - float(z0)
	var a := lerpf(_surface[z0 * _size + x0],
		_surface[z0 * _size + x0 + 1], tx)
	var b := lerpf(_surface[(z0 + 1) * _size + x0],
		_surface[(z0 + 1) * _size + x0 + 1], tx)
	return lerpf(a, b, tz)

## Exact grid-post read (clamped indices) for mesh construction: the
## terrain mesh and far-apron edge match the built surface bit-for-bit.
func surface_at_post(x: int, z: int) -> float:
	if _surface.is_empty():
		return water_level_m
	var cx := clampi(x, 0, _size - 1)
	var cz := clampi(z, 0, _size - 1)
	return _surface[cz * _size + cx]

## Water depth in metres at XZ; 0.0 = dry. Covers water-polygon and
## waterway channels (carved under their local bank-levelled surface)
## and DEM sinks below the global datum.
func water_at(x: float, z: float) -> float:
	return maxf(0.0, water_level_at(x, z) - height_at_world(x, z))

## Local water surface (render Y) at XZ: the weighted level of the
## carved posts around it, else the global datum (water_level_m).
func water_level_at(x: float, z: float) -> float:
	if _size < 2 or _level.size() != _size * _size:
		return water_level_m
	var fx := clampf(x / _step_units + float(_size) * 0.5, 0.0, float(_size - 1))
	var fz := clampf(z / _step_units + float(_size) * 0.5, 0.0, float(_size - 1))
	var x0 := mini(int(fx), _size - 2)
	var z0 := mini(int(fz), _size - 2)
	var sum := 0.0
	var wsum := 0.0
	for k in 4:
		var px := x0 + (k & 1)
		var pz := z0 + (k >> 1)
		var lv := _level[pz * _size + px]
		if is_inf(lv):
			continue
		var w := maxf((1.0 - absf(fx - float(px))) * (1.0 - absf(fz - float(pz))), 1e-4)
		sum += lv * w
		wsum += w
	if wsum <= 0.0:
		return water_level_m
	return maxf(water_level_m, sum / wsum)

## Land class at XZ: first containing land polygon wins (same order as
## the terrain colours), "" = unknown/cover-free. Building and road
## exclusion wire in with T2.3 footprints; until then is_built_at
## below carries the v1 building circle test exactly.
func land_class_at(x: float, z: float) -> String:
	var p := Vector2(x, z)
	for poly in _land:
		var pts: PackedVector2Array = poly.get("points", PackedVector2Array())
		if WorldScale.point_in_polygon(p, pts) \
				and not _in_holes(p, poly.get("holes", [])):
			return str(poly.get("class", ""))
	return ""

## Slope gradient (rise over run, 0.0 = flat) from central
## differences. Surface Y and XZ share the same scale (render
## units), so rise/run in render units is the true physical slope
## in both vertical modes.
func slope_at(x: float, z: float) -> float:
	var e := _step_units * 0.5
	if _step_units <= 0.0:
		return 0.0
	var dx := height_at_world(x + e, z) - height_at_world(x - e, z)
	var dz := height_at_world(x, z + e) - height_at_world(x, z - e)
	return Vector2(dx, dz).length() / _step_units

## Whether XZ is on the detailed surface (else sample the far ring).
func is_inside(x: float, z: float) -> bool:
	return absf(x) <= _half_units and absf(z) <= _half_units

## Transitional (T2.3): the v1 BuildingBuilder._near_building circle
## test (max footprint half-size + 1.6 margin), so vegetation and
## infill exclusion sample ground instead of cross-calling builders.
func is_built_at(x: float, z: float) -> bool:
	for b in _buildings:
		if not (b is Dictionary):
			continue
		var dx := x - float(b.get("x", 0.0))
		var dz := z - float(b.get("z", 0.0))
		var reach := maxf(float(b.get("size_x", 0.0)),
			float(b.get("size_z", 0.0))) * 0.5 + 1.6
		if dx * dx + dz * dz < reach * reach:
			return true
	return false
