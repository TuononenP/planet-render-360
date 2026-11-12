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
var _land_index: Array = []  # PolygonIndex per _land entry, same order
var _index = null  # GroundIndex, untyped to break load cycle
var _land_native: Object = null
var _buildings: Array = []
## Local water surface per post (render units) for posts a water body
## or channel carved; -INF = no carve (water_level_at falls back to the
## global datum). Bodies are levelled from their own banks, the same
## rule WaterBuilder uses (10th-percentile dry bank − freeboard).
var _level: PackedFloat32Array = PackedFloat32Array()
## Finalized before builders start; untyped to avoid a class-load cycle.
var shoreline = null
## The painted ground (GroundSurface), built on first ask; the lock lets
## the terrain and vegetation stages share one build.
var _painted: GroundSurface = null
var _painted_lock := Mutex.new()

## Bank freeboard (mirrors WaterBuilder._FREEBOARD) and carve depth
## below that local surface. v1 carved to the GLOBAL datum
## (centre − relief/5): a ~190 m trench at Interlaken, −164 m at
## Big Sur. Now every carve is a few metres under its own water.
const FREEBOARD_M := 0.4
const CARVE_DEPTH_M := 2.0
## Height step (metres) at which _blur_pass stops averaging across a
## neighbour: DEM noise is well under it, escarpment posts well over.
const EDGE_SIGMA_M := 3.0

## What the terrain shader paints over the extent, built once from `data`
## (the place this ground was made from) and shared by every stage.
func surface(data: LocationData) -> GroundSurface:
	_painted_lock.lock()
	if _painted == null:
		_painted = GroundSurface.new(GroundMaterial.class_map(data))
	_painted_lock.unlock()
	return _painted

## Land polygons plus their edge-banded indices (land_class_at runs per
## tree / building / probe, and a lagoon polygon has tens of thousands
## of vertices). WorldCache calls this on a restored ground too, which
## never runs _init's build.
func set_land(polys: Array) -> void:
	_land = polys
	_land_index.clear()
	for poly in _land:
		_land_index.append(PolygonIndex.new(
			poly.get("points", PackedVector2Array()), poly.get("holes", [])))
	_rebuild_index()

func _rebuild_index() -> void:
	_land_native = null
	if not ShoreGeometry.force_script and not _land_index.is_empty() and ClassDB.class_exists("ShoreDomainIndex"):
		_land_native = ClassDB.instantiate("ShoreDomainIndex")
		if _land_native.has_method("setup_polygons"):
			_land_native.setup_polygons(_land_index, Rect2(Vector2.ONE * -_half_units, Vector2.ONE * _half_units * 2.0))
		else:
			_land_native = null
	if _land.is_empty() and _buildings.is_empty():
		_index = null
		return
	# Only build GroundIndex when we have a size (post-_init or WorldCache restore).
	if _size > 0 or not _land.is_empty():
		var _gi = load("res://scripts/generation/ground_index.gd") as GDScript
		_index = _gi.new(self)

## Builds the surface synchronously (a pipeline stage with real
## progress once the pipeline constructs this in stage 3; until then
## builders construct it from the data they already receive).
## Requires valid data (heights.size() == grid_size²); null leaves an
## empty surface for WorldCache to restore a saved one into.
func _init(data: LocationData, abort: BuildAbort = null) -> void:
	if data == null:
		return
	var size := data.grid_size
	_size = size
	var extent_units := WorldScale.detailed_extent_units()
	_step_units = extent_units / float(maxi(size - 1, 1))
	_half_units = extent_units * 0.5
	extent_m = _half_units / WorldScale.metres_to_units()
	water_level_m = data.water_level
	var has_sea := WaterBuilder._has_coastline(data)
	for poly in data.land_polygons:
		if str(poly.get("class", "")) == "water" and bool(poly.get("tidal", false)):
			has_sea = true
			break
	if not is_equal_approx(data.water_level, -3.0) and has_sea:
		water_level_m = WaterBuilder.SEA_LEVEL_M
	set_land(data.land_polygons)
	_buildings = data.buildings
	_surface.resize(size * size)
	# T3.1 remap: resample the heights window onto the surface posts
	# (bilinear over the central sub-window for real grids, 1:1 for
	# procedural/fixtures), then the v1 3x3 centre-double-weighted blur.
	var frac := _extent_span_frac(data)
	var geo := DemRegistration.applies(data) and frac < 0.9999
	var step_m := _step_units / WorldScale.metres_to_units()
	if geo:
		# Per-axis tables: grid_index x depends only on x (lon), z only on lat.
		var tx := PackedFloat32Array()
		var tz := PackedFloat32Array()
		tx.resize(size)
		tz.resize(size)
		# grid_index is separable (latlon_from_xz: lat from z only, lon from
		# x only, cos of the viewpoint's latitude), so one column/row call
		# yields the exact float32 index the per-post call returns.
		var grid := data.grid_size
		for x in size:
			tx[x] = DemRegistration.grid_index(data, size, step_m, x, 0).x
		for z in size:
			tz[z] = DemRegistration.grid_index(data, size, step_m, 0, z).y
		# Bilinear with 4 direct reads + 3 lerps, same as _grid_bilinear.
		for z in size:
			var fz := clampf(tz[z], 0.0, float(grid - 1))
			var z0 := mini(int(fz), grid - 2)
			var tz_w := fz - float(z0)
			for x in size:
				var fx := clampf(tx[x], 0.0, float(grid - 1))
				var x0 := mini(int(fx), grid - 2)
				var tx_w := fx - float(x0)
				var a := lerpf(data.height_at(x0, z0), data.height_at(x0 + 1, z0), tx_w)
				var b := lerpf(data.height_at(x0, z0 + 1), data.height_at(x0 + 1, z0 + 1), tx_w)
				_surface[z * size + x] = lerpf(a, b, tz_w)
	elif frac >= 0.9999:
		# 1:1 fast path — bit-identical to v1, no remap.
		for z in size:
			for x in size:
				_surface[z * size + x] = data.height_at(x, z)
	else:
		# Central sub-window bilinear via per-axis tables.
		var half := float(size) * 0.5
		var fx_table := PackedFloat32Array()
		var fz_table := PackedFloat32Array()
		fx_table.resize(size)
		fz_table.resize(size)
		for x in size:
			fx_table[x] = clampf((float(x) - half) * frac + half, 0.0, float(size - 1))
		for z in size:
			fz_table[z] = clampf((float(z) - half) * frac + half, 0.0, float(size - 1))
		for z in size:
			var fz2 := fz_table[z]
			var z0 := mini(int(fz2), size - 2)
			var tz2 := fz2 - float(z0)
			for x in size:
				var fx2 := fx_table[x]
				var x0 := mini(int(fx2), size - 2)
				var tx2 := fx2 - float(x0)
				var a := lerpf(data.height_at(x0, z0), data.height_at(x0 + 1, z0), tx2)
				var b := lerpf(data.height_at(x0, z0 + 1), data.height_at(x0 + 1, z0 + 1), tx2)
				_surface[z * size + x] = lerpf(a, b, tz2)
	# ArcticDEM (≥60°N) and SRTM / EU-DEM tiles are surface models: strip
	# roofs and tree crowns.
	if BareEarth.applies(data):
		BareEarth.strip(_surface, size, _step_units, float(size) / 2.0,
			data.buildings, data.land_polygons)
		if not BareEarth.surface_model(data):
			BareEarth.lower_canopy(_surface, size, _step_units, float(size) / 2.0, data.buildings)
	# A coarse surface model keeps block-scale mounds under the city.
	if RoadGrading.coarse(data):
		UrbanSmooth.apply(_surface, size, _step_units, float(size) / 2.0, data.buildings)
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
	SuomenlinnaSite.grade_gate(_surface, size, _step_units, data.buildings, data.latitude, data.longitude)
	# Water polygons carve below their own bank-levelled surface, or
	# the channel terrain covers the water entirely (v1 _heights, which
	# carved to the global datum instead).
	_level.resize(size * size)
	_level.fill(-INF)
	var shore_script = load("res://scripts/generation/shoreline_model.gd") as GDScript
	var sea_level := water_level_m if is_equal_approx(data.water_level, -3.0) else WaterBuilder.SEA_LEVEL_M
	shoreline = shore_script.new(data, self, sea_level, abort)
	if abort == null or not abort.requested:
		shoreline.carve(_surface, _level)
	# Streets and main roads sit on a smoothed profile (RoadGrading).
	var ways := data.roads + data.railways
	var coarse := RoadGrading.coarse(data)
	RoadGrading.grade(_surface, _level, size, _step_units,
		[] if data.buildings.is_empty() else ways, WorldScale.metres_to_units(),
		RoadGrading.COARSE_SMOOTH_M if coarse else RoadGrading.SMOOTH_M,
		RoadGrading.COARSE_MAX_SHIFT_M if coarse else RoadGrading.MAX_SHIFT_M)
	# Mapped squares and plazas lie on their own best-fit plane.
	RoadGrading.grade_areas(_surface, _level, size, _step_units,
		[] if data.buildings.is_empty() else data.roads)
	# Ways under a bridge are cut down to clear its deck.
	Underpasses.carve(_surface, _level, size, _step_units, ways,
		WorldScale.metres_to_units())
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
	# Build eager spatial index now that _surface/_level are final (read-only thereafter).
	_rebuild_index()
	if not shoreline.empty():
		shoreline.finish(self, abort)
		if shoreline.ready:
			if shoreline.sampler != null and shoreline.sampler.has_method("height_range"):
				var span: Vector2 = shoreline.sampler.height_range()
				surface_min = minf(surface_min, span.x)
				surface_max = maxf(surface_max, span.y)
			else:
				for patch in shoreline.patches.values():
					for p in patch["triangles"]:
						surface_min = minf(surface_min, p.y)
						surface_max = maxf(surface_max, p.y)

static func _densify(pts: PackedVector2Array, sp: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in pts.size() - 1:
		var n := maxi(1, int(ceil(pts[i].distance_to(pts[i + 1]) / maxf(sp, 0.01))))
		for k in n:
			out.append(pts[i].lerp(pts[i + 1], float(k) / float(n)))
	out.append(pts[pts.size() - 1])
	return out

## Fraction of the heights grid covered by the detailed surface
## (T3.1 remap): extent ground span / heights-window ground span.
## Real grids report metres_per_px + source_zoom in dem_source (the
## window is DemRegistration.window_px: 576 z14 / 144 z12 px, widened
## past ~63°N so it still covers the extent). Procedural grids
## ({source_zoom: 0}) and fixtures (empty dem_source) already span the
## extent → 1.0. Clamped to ≤1.0.
static func _extent_span_frac(data: LocationData) -> float:
	var mpp := float(data.dem_source.get("metres_per_px", 0.0))
	if mpp <= 0.0:
		return 1.0
	var span_m := DemRegistration.window_px(data) * mpp
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
## Edge-aware: a neighbour's weight falls off with its height step
## from the centre (Gaussian, EDGE_SIGMA_M), so metre-scale DEM noise
## still smooths but escarpments keep their height (Turku: a 12 m drop
## in 20 m was rounded 3.2 m low). Opposite neighbours on a linear ramp
## differ by the same step, so a ramp still maps to itself.
static func _blur_pass(src: PackedFloat32Array, dst: PackedFloat32Array,
		size: int) -> void:
	var inv := 1.0 / (EDGE_SIGMA_M * EDGE_SIGMA_M)
	for z in size:
		for x in size:
			# Interior fast path — no clamp calls, same dz,dx order.
			if x > 0 and x < size - 1 and z > 0 and z < size - 1:
				var c := src[z * size + x]
				var sum := c * 2.0
				var n := 2.0
				# dz=-1: dx=-1,0,1
				var h := src[(z - 1) * size + (x - 1)]
				var w := exp(-(h - c) * (h - c) * inv)
				sum += h * w; n += w
				h = src[(z - 1) * size + x]
				w = exp(-(h - c) * (h - c) * inv)
				sum += h * w; n += w
				h = src[(z - 1) * size + (x + 1)]
				w = exp(-(h - c) * (h - c) * inv)
				sum += h * w; n += w
				# dz=0: dx=-1,1
				h = src[z * size + (x - 1)]
				w = exp(-(h - c) * (h - c) * inv)
				sum += h * w; n += w
				h = src[z * size + (x + 1)]
				w = exp(-(h - c) * (h - c) * inv)
				sum += h * w; n += w
				# dz=1: dx=-1,0,1
				h = src[(z + 1) * size + (x - 1)]
				w = exp(-(h - c) * (h - c) * inv)
				sum += h * w; n += w
				h = src[(z + 1) * size + x]
				w = exp(-(h - c) * (h - c) * inv)
				sum += h * w; n += w
				h = src[(z + 1) * size + (x + 1)]
				w = exp(-(h - c) * (h - c) * inv)
				sum += h * w; n += w
				dst[z * size + x] = sum / n
			else:
				var c := _clamped_post(src, size, x, z)
				var sum := c * 2.0
				var n := 2.0
				for dz in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						if dx == 0 and dz == 0:
							continue
						var h := _clamped_post(src, size, x + dx, z + dz)
						var w := exp(-(h - c) * (h - c) * inv)
						sum += h * w
						n += w
				dst[z * size + x] = sum / n

static func _clamped_post(src: PackedFloat32Array, size: int, x: int,
		z: int) -> float:
	return src[clampi(z, 0, size - 1) * size + clampi(x, 0, size - 1)]

## Final render Y at world XZ: smoothed DEM (slope-preserving
## low-relief smooth, never a global flatten), water-carved channels
## applied. Bilinear between grid posts; outside clamps to the
## nearest edge, never NaN.
func height_at_world(x: float, z: float) -> float:
	if shoreline != null and shoreline.ready:
		return shoreline.height(Vector2(x, z).clamp(shoreline.bounds.position, shoreline.bounds.end))
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

## Dry ground at world XZ, in render units: what a footprint stands on
## before water carving. Inside a water domain this is the pre-carve
## bank height, never the carved bed; elsewhere it is the final surface.
## Builders that seat objects on land (foundations) read this, while
## height_at_world remains the rendered (possibly wet) surface.
func dry_height_at_world(x: float, z: float) -> float:
	if shoreline != null and shoreline.ready:
		return shoreline.land_height(x, z)
	return height_at_world(x, z)

## Exact grid-post read (clamped indices) for mesh construction: the
## terrain mesh and far-apron edge match the built surface bit-for-bit.
func surface_at_post(x: int, z: int) -> float:
	if _surface.is_empty():
		return water_level_m
	var cx := clampi(x, 0, _size - 1)
	var cz := clampi(z, 0, _size - 1)
	if shoreline != null and shoreline.ready:
		return height_at_world((float(cx) - float(_size) * 0.5) * _step_units,
			(float(cz) - float(_size) * 0.5) * _step_units)
	return _surface[cz * _size + cx]

## Water depth in metres at XZ; 0.0 = dry. Covers water-polygon and
## waterway channels (carved under their local bank-levelled surface)
## and DEM sinks below the global datum.
func water_at(x: float, z: float) -> float:
	if shoreline != null and shoreline.empty():
		return 0.0
	if shoreline != null and shoreline.ready and shoreline.bounds.has_point(Vector2(x, z)):
		var body: int = shoreline.domains.at(Vector2(x, z))
		if body < 0:
			return 0.0
		return maxf(0.0, shoreline.domains.level(body, Vector2(x, z)) - height_at_world(x, z))
	return maxf(0.0, water_level_at(x, z) - height_at_world(x, z))

## Local water surface (render Y) at XZ: the weighted level of the
## carved posts around it, else the global datum (water_level_m).
## A caller may supply a local fallback in render units when no mapped
## level exists; observed bank-levelled water always takes precedence.
func water_level_at(x: float, z: float, fallback_level: float = NAN) -> float:
	var fallback := water_level_m if is_nan(fallback_level) else fallback_level
	if shoreline != null and shoreline.ready:
		var body: int = shoreline.domains.at(Vector2(x, z))
		if body >= 0:
			return shoreline.domains.level(body, Vector2(x, z))
		return fallback
	if _size < 2 or _level.size() != _size * _size:
		return fallback
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
		return fallback
	return maxf(water_level_m, sum / wsum)

## Land class at XZ: first containing land polygon wins (same order as
## the terrain colours), "" = unknown/cover-free. Building and road
## exclusion wire in with T2.3 footprints; until then is_built_at
## below carries the v1 building circle test exactly.
func land_class_at(x: float, z: float) -> String:
	var p := Vector2(x, z)
	if _land_native != null and absf(x) < _half_units and absf(z) < _half_units:
		var id: int = _land_native.at(p)
		return str(_land[id].get("class", "")) if id >= 0 else ""
	if _index != null:
		var cands: Array = _index.land_candidates_at(x, z)
		for idx in cands:
			if (_land_index[idx] as PolygonIndex).contains(p):
				return str(_land[idx].get("class", ""))
		return ""
	for k in _land.size():
		if (_land_index[k] as PolygonIndex).contains(p):
			return str(_land[k].get("class", ""))
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
	if _index != null:
		var cands: Array = _index.built_candidates_at(x, z)
		if not cands.is_empty():
			for b in cands:
				if not (b is Dictionary):
					continue
				var dx := x - float(b.get("x", 0.0))
				var dz := z - float(b.get("z", 0.0))
				var reach := maxf(float(b.get("size_x", 0.0)),
					float(b.get("size_z", 0.0))) * 0.5 + 1.6
				if dx * dx + dz * dz < reach * reach:
					return true
			return false
		# Empty cell but inside grid = definitely not built.
		if _index._built_grid_w > 0 and _index._built_grid_h > 0:
			if x >= _index._built_grid_origin.x and x <= _index._built_grid_origin.x + float(_index._built_grid_w) * _index._built_grid_step.x \
					and z >= _index._built_grid_origin.y and z <= _index._built_grid_origin.y + float(_index._built_grid_h) * _index._built_grid_step.y:
				return false
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
