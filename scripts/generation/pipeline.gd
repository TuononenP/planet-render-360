class_name GenerationPipeline
extends Node

## Staged, cancellable location-generation pipeline.
## Stage 0 fetches a real DEM mosaic (DemFetcher 3x3 z14, z12 fallback)
## and falls back to a deterministic procedural DEM when offline or on
## error; both normalise into the same true-metre LocationData (T1.3).
##
## Fetcher fallbacks log with print (a push_warning backtrace read as an
## engine error) and are recorded in `degraded` -> LocationData.data_notes.

signal stage_changed(index: int, label: String, state: String)
signal progress_changed(fraction: float, label: String)
signal finished(data: LocationData)
signal cancelled
signal degraded_layer(layer: String)
## The data as it stands after a stage, for the loading preview
## (heights + imagery after 0, buildings after 2). Read-only for listeners.
signal stage_data(index: int, data: LocationData)

## One stage per live data source, named as the design system names
## them (the stage the user waits on is the layer that is arriving).
## "Building the scene" follows the pipeline, in the threaded build.
const STAGES: Array[String] = [
	"Elevation",
	"Imagery",
	"Buildings & landmarks",
	"Weather",
]

var _cancelled := false
var used_real_dem := false
## A/B switch (T1.3; the squash path is deleted in T3.1, contract §7 V1):
## while true, _fetch_dem/_apply_far restore the v1 adaptive squash
## (relief remapped to ~30 units around 3.0, water at -3.0) instead of
## true-metre heights. Default OFF: heights are source metres ASL.
var legacy_squash := false
var _fetcher: DemFetcher
var _dem_heights: PackedFloat32Array = PackedFloat32Array()
var _dem_done := false
var _far_fetcher: DemFetcher
var _far_heights_m: PackedFloat32Array = PackedFloat32Array()
var _far_done := false
## T3.7 far-field DEM rings + imagery drapes (FarFieldFetcher), started
## with the other fetches in run() and applied in stage 0 (_apply_far).
var _farfield: FarFieldFetcher
var _farfield_rings: Array = []
var _farfield_drapes: Array = []
var _farfield_done := true
## Budget for the far-field wait; layers still missing degrade to the
## z8 grid / colour ramp (register fallback order), never block.
const FARFIELD_WAIT_S := 45.0
var _dem_centre_m := 0.0
var _dem_vscale := 0.1
var used_osm := false
var degraded: Array[String] = []
var _osm: OsmFetcher
var _osm_buildings: Array = []
## Closure W2: the unfrozen OSM payload — §2.5 attributed road dicts plus
## the §2.6 extras — lands on LocationData in _await_osm. The v1 bare
## centreline arg on the frozen signal is ignored here (RoadBuilder's T4.4
## flip consumes the v2 shape; until then see LocationData.roads).
var _osm_roads_v2: Array = []
var _osm_land: Array = []
var _osm_landmarks: Array = []
var _osm_waterways: Array = []
var _osm_trees: Array = []
var _osm_barriers: Array = []
var _osm_railways: Array = []
var _osm_platforms: Array = []
var _osm_stops: Array = []
var _osm_done := false
## T5.4 far city ring query (FarCityFetcher): one cached Overpass call,
## overlapped with everything, awaited (bounded) after the OSM stage.
var _farcity: FarCityFetcher
var _farcity_landuse: Array = []
var _farcity_towers: Array = []
var _farcity_done := true
const FARCITY_WAIT_S := 30.0
var _climate: ClimateFetcher
var _climate_data: Dictionary = {}
var _climate_done := true
## CHELSA reads are ~3–4 s cold (5 variables × 4 small ranged requests),
## overlapped with the other fetches; cached revisits read one JSON.
const CLIMATE_WAIT_S := 15.0
var _sat: SatelliteFetcher
var _sat_texture: Texture2D
var _sat_image: Image
var _sat_origin := Vector2.ZERO
var _sat_zoom := 16
var _sat_done := false
var used_satellite := false

func _ready() -> void:
	_fetcher = DemFetcher.new()
	add_child(_fetcher)
	_fetcher.succeeded.connect(func(h: PackedFloat32Array, _g: int) -> void:
		_dem_heights = h
		_dem_done = true)
	_fetcher.failed.connect(func(reason: String) -> void:
		print("DEM fetch failed, using procedural fallback: %s" % reason)
		_dem_done = true)
	_far_fetcher = DemFetcher.new()
	add_child(_far_fetcher)
	_far_fetcher.succeeded.connect(func(h: PackedFloat32Array, _g: int) -> void:
		_far_heights_m = h
		_far_done = true)
	_far_fetcher.failed.connect(func(reason: String) -> void:
		print("Far DEM fetch failed, using procedural backdrop: %s" % reason)
		_far_done = true)
	_farfield = FarFieldFetcher.new()
	add_child(_farfield)
	_farfield.finished.connect(func(rings: Array, drapes: Array) -> void:
		_farfield_rings = rings
		_farfield_drapes = drapes
		_farfield_done = true)
	_osm = OsmFetcher.new()
	add_child(_osm)
	_osm.succeeded.connect(func(b: Array, _r: Array, l: Array, lm: Array) -> void:
		_osm_buildings = b
		_osm_land = l
		_osm_landmarks = lm
		_osm_done = true)
	_osm.succeeded_v2.connect(func(r2: Array, w: Array, t: Array, br: Array) -> void:
		_osm_roads_v2 = r2
		_osm_waterways = w
		_osm_trees = t
		_osm_barriers = br)
	_osm.succeeded_rail.connect(func(rw: Array, pf: Array, st: Array) -> void:
		_osm_railways = rw
		_osm_platforms = pf
		_osm_stops = st)
	_osm.failed.connect(func(reason: String) -> void:
		print("OSM fetch failed, using procedural dressing: %s" % reason)
		if DataNotes.osm_outage(reason):
			_note("map")
		_osm_done = true)
	_climate = ClimateFetcher.new()
	add_child(_climate)
	_climate.finished.connect(func(c: Dictionary) -> void:
		_climate_data = c
		_climate_done = true)
	_farcity = FarCityFetcher.new()
	add_child(_farcity)
	_farcity.finished.connect(func(lu: Array, tw: Array) -> void:
		_farcity_landuse = lu
		_farcity_towers = tw
		_farcity_done = true)
	_sat = SatelliteFetcher.new()
	add_child(_sat)
	_sat.succeeded.connect(func(tex: Texture2D, img: Image, origin: Vector2, zoom: int) -> void:
		_sat_texture = tex
		_sat_image = img
		_sat_origin = origin
		_sat_zoom = zoom
		_sat_done = true)
	_sat.failed.connect(func(reason: String) -> void:
		print("Satellite fetch failed, using colour dressing: %s" % reason)
		_sat_done = true)

func _note(layer: String) -> void:
	if not degraded.has(layer):
		degraded.append(layer)
		degraded_layer.emit(layer)

func cancel() -> void:
	_cancelled = true
	if _osm != null:
		_osm.cancel()
	if _farcity != null:
		_farcity.cancel()
	if _climate != null:
		_climate.cancel()

func run(lat: float, lon: float, place_name_override: String = "",
		quality_preset: int = RenderSettings.Preset.HIGH) -> void:
	_cancelled = false
	var data := LocationData.new()
	# The preset sizes the DEM grids before any fetch, so Fast really
	# downloads/builds less and High really samples finer terrain.
	RenderSettings.apply_preset(data, quality_preset)
	data.latitude = lat
	data.longitude = lon
	data.place_name = place_name_override if place_name_override != "" \
		else LocationData.known_place(lat, lon)
	var landmark := LocationData.landmark_entry(lat, lon, data.place_name)
	data.landmark_type = str(landmark.get("type", "none")) if not landmark.is_empty() else "none"
	data.has_landmark_site = not landmark.is_empty()
	if data.has_landmark_site:
		data.landmark_lat = float(landmark["lat"])
		data.landmark_lon = float(landmark["lon"])
	data.seed_value = int(abs(sin(lat * 12.9898 + lon * 78.233) * 43758.5453)) % 100000
	# Start OSM fetch now so it overlaps the staged timers below.
	degraded.clear()
	used_osm = false
	_osm_done = false
	_osm_buildings = []
	_osm_roads_v2 = []
	_osm_land = []
	_osm_landmarks = []
	_osm_waterways = []
	_osm_trees = []
	_osm_barriers = []
	_osm_railways = []
	_osm_platforms = []
	_osm_stops = []
	_osm.fetch(lat, lon)
	_farcity_done = false
	_farcity_landuse = []
	_farcity_towers = []
	_farcity.fetch(lat, lon)
	_climate_done = false
	_climate_data = {}
	_climate.fetch(lat, lon)
	# Satellite drape overlaps the stages too; Fast skips it (the
	# vertex-colour dressing is its whole point: less data, less time).
	# Higher presets fetch finer mosaics (T2.2: z16s3 Balanced, z17s7
	# High, z18s13 Ultra) over the same ground window.
	used_satellite = false
	_sat_done = false
	_sat_texture = null
	_sat_image = null
	if quality_preset > RenderSettings.Preset.FAST:
		_sat.fetch(lat, lon, RenderSettings.satellite_zoom_for(quality_preset),
			RenderSettings.satellite_span_for(quality_preset, lat))
	else:
		_sat_done = true
	# Far backdrop fetch overlaps everything else; converted in stage 0
	# once the detailed centre/scale are known.
	_far_done = false
	_far_heights_m = PackedFloat32Array()
	_far_fetcher.fetch_far(lat, lon, data.far_grid_size)
	# T3.7 far-field rings/drapes (drapes skipped on Fast, like the
	# near drape); also overlapped, applied in stage 0.
	_farfield_done = false
	_farfield_rings = []
	_farfield_drapes = []
	_farfield.fetch(lat, lon, quality_preset > RenderSettings.Preset.FAST)

	for i in STAGES.size():
		if _cancelled:
			cancelled.emit()
			return
		stage_changed.emit(i, STAGES[i], "in_progress")
		progress_changed.emit(float(i) / STAGES.size(), STAGES[i])
		# One frame so the loading screen draws the stage; no fixed pause
		# (T7.5: real work only, no fake timers).
		await get_tree().process_frame
		if _cancelled:
			cancelled.emit()
			return
		match i:
			0:
				await _fetch_dem(data)
			1:
				await _await_satellite(data)
			2:
				await _await_osm(data)
			3:
				await _await_climate(data)
		if _cancelled:
			cancelled.emit()
			return
		stage_data.emit(i, data)
		stage_changed.emit(i, STAGES[i], "done")

	progress_changed.emit(1.0, "Done")
	data.data_notes = DataNotes.describe(degraded, data.quality_preset > RenderSettings.Preset.FAST)
	finished.emit(data)

## Pure vertical conversion (T1.3); see DemConversion.convert_dem_heights.
static func convert_dem_heights(raw_metres: PackedFloat32Array, grid: int,
		use_legacy_squash: bool) -> Dictionary:
	return DemConversion.convert_dem_heights(raw_metres, grid, use_legacy_squash)

func _fetch_dem(data: LocationData) -> void:
	used_real_dem = false
	_dem_done = false
	_dem_heights = PackedFloat32Array()
	_fetcher.fetch(data.latitude, data.longitude, data.grid_size)
	var waited := 0.0
	while not _dem_done and waited < 16.0 and not _cancelled:
		await get_tree().process_frame
		waited += get_process_delta_time()
	if _dem_heights.size() == data.grid_size * data.grid_size:
		used_real_dem = true
		data.dem_source = _fetcher.dem_source
		data.attribution = "Elevation: AWS Terrain Tiles — EU-DEM / Copernicus, USGS 3DEP, SRTM and other sources (see docs/data-source-register.md)"
		var conv := convert_dem_heights(_dem_heights, data.grid_size, legacy_squash)
		data.heights = conv["heights"]
		data.centre_elevation_m = conv["centre_elevation_m"]
		data.relief_metres = conv["relief_metres"]
		data.water_level = conv["water_level"]
		_dem_centre_m = conv["centre_elevation_m"]
		_dem_vscale = conv["legacy_vscale"]
	else:
		data.dem_source = {"source_zoom": 0, "procedural": true}
		_note("elevation")
		_build_dem(data)
	await _apply_far(data)

func _apply_far(data: LocationData) -> void:
	var waited := 0.0
	while not _far_done and waited < 12.0 and not _cancelled:
		await get_tree().process_frame
		waited += get_process_delta_time()
	var grid := data.far_grid_size
	# True metre span of the z8 far tile (contract §2.2), the span the
	# far rings already use (T7.0 metre cutover).
	data.far_extent_m = FarTerrainBuilder.far_span_m(data)
	if used_real_dem and _far_heights_m.size() == grid * grid:
		data.far_centre_frac = _far_fetcher.far_centre_frac
		if legacy_squash:
			data.far_heights.resize(_far_heights_m.size())
			for idx in _far_heights_m.size():
				data.far_heights[idx] = (_far_heights_m[idx] - _dem_centre_m) * _dem_vscale + 3.0
		else:
			data.far_heights = _far_heights_m.duplicate()
	else:
		_build_far_procedural(data)
	await _apply_far_field(data)

## T3.7: waits (bounded, cancellable) for the far-field fetch started in
## run() and lands its layers on LocationData. Real DEM only, and not
## under legacy_squash (rings are true metres): a procedural near grid
## must not meet real far geometry.
func _apply_far_field(data: LocationData) -> void:
	if _farfield.is_busy():
		var waited := 0.0
		while not _farfield_done and waited < FARFIELD_WAIT_S and not _cancelled:
			await get_tree().process_frame
			waited += get_process_delta_time()
	if not _farfield_done:
		print("Far-field fetch over budget, using z8 far grid + colour ramp")
		return
	if not used_real_dem or legacy_squash:
		return
	data.dem_rings = _farfield_rings
	data.far_drapes = _farfield_drapes
	print("FAR-FIELD fetch: %s rings=%d drapes=%d" % [str(_farfield.timings),
		data.dem_rings.size(), data.far_drapes.size()])

func _build_far_procedural(data: LocationData) -> void:
	# Offline backdrop: same noise family as _build_dem, wider and
	# calmer at the centre so it never fights the detailed terrain.
	var n := FastNoiseLite.new()
	n.seed = data.seed_value + 5
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.5
	var grid := data.far_grid_size
	var centre_h := data.height_at(data.grid_size / 2, data.grid_size / 2)
	var amp := 10.0
	if not data.heights.is_empty():
		var r := TerrainBuilder._range_of(data.heights)
		amp = clampf((r.y - r.x) * 1.4, 8.0, 60.0)
	data.far_heights.resize(grid * grid)
	data.far_centre_frac = Vector2(0.5, 0.5)
	# Metres (T7.0): calm inside ~1.3 km (past the detailed extent),
	# full amplitude by ~5 km — the v1 260/900-unit ramp on a 4x world.
	var cell_m := data.far_extent_m / float(grid)
	for z in grid:
		for x in grid:
			var dist_m := Vector2(float(x - grid / 2), float(z - grid / 2)).length() * cell_m
			var grow := clampf((dist_m - 1300.0) / 3600.0, 0.0, 1.0)
			data.far_heights[z * grid + x] = centre_h \
				+ n.get_noise_2d(float(x) * 0.55, float(z) * 0.55) * amp * grow \
				+ amp * 0.55 * grow

func _await_satellite(data: LocationData) -> void:
	# Wait budget scales with mosaic size (9/49/169 tiles); cancel still
	# interrupts. Fits the §3.1 tier budgets (High ≤75 s, Ultra ≤150 s).
	var budget := clampf(12.0 + float(_sat.pending_tile_count()) * 0.6, 20.0, 120.0)
	var waited := 0.0
	while not _sat_done and waited < budget and not _cancelled:
		await get_tree().process_frame
		waited += get_process_delta_time()
	if _sat_texture == null and data.quality_preset > RenderSettings.Preset.FAST:
		_note("imagery")
	if _sat_texture != null:
		used_satellite = true
		data.satellite_texture = _sat_texture
		data.satellite_image = _sat_image
		data.satellite_origin_px = _sat_origin
		data.satellite_zoom = _sat_zoom
		data.satellite_source = _sat.satellite_source
		data.satellite_metres_per_px = float(data.satellite_source.get("metres_per_px", 0.0))
		var sat_attr := "Imagery: Esri, Vantor, Earthstar Geographics"
		data.attribution = sat_attr if data.attribution.is_empty() \
			else data.attribution + " · " + sat_attr
	elif not data.far_drapes.is_empty():
		# T3.7: far drapes are the same Esri source (register row).
		var far_attr := "Imagery: Esri, Vantor, Earthstar Geographics"
		data.attribution = far_attr if data.attribution.is_empty() \
			else data.attribution + " · " + far_attr

func _await_osm(data: LocationData) -> void:
	# OsmFetcher retries across Overpass endpoints; this wait must
	# outlast the whole chain or a rescued fetch is dropped.
	var waited := 0.0
	while not _osm_done and waited < OsmFetcher.retry_budget_seconds() and not _cancelled:
		await get_tree().process_frame
		waited += get_process_delta_time()
	if not _osm_done:
		_note("map")
	if not _osm_buildings.is_empty():
		used_osm = true
		data.buildings = _osm_buildings
		data.roads = _osm_roads_v2
		data.land_polygons = _osm_land
		data.waterways = _osm_waterways
		data.trees = _osm_trees
		data.barriers = _osm_barriers
		data.railways = _osm_railways
		data.rail_platforms = _osm_platforms
		data.transit_stops = _osm_stops
		var cands := _osm_landmarks.duplicate()
		cands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return (float(a["x"]) ** 2 + float(a["z"]) ** 2) \
				< (float(b["x"]) ** 2 + float(b["z"]) ** 2))
		data.landmark_candidates = cands.slice(0, 8)
		var osm_attr := "Map data: © OpenStreetMap contributors"
		data.attribution = osm_attr if data.attribution.is_empty() \
			else data.attribution + " · " + osm_attr
	await _await_far_city(data)

## CHELSA climate normals (bounded wait; absent → latitude fallbacks).
func _await_climate(data: LocationData) -> void:
	var waited := 0.0
	while not _climate_done and waited < CLIMATE_WAIT_S and not _cancelled:
		await get_tree().process_frame
		waited += get_process_delta_time()
	if _climate_data.is_empty():
		print("Climate (CHELSA) unavailable; latitude fallbacks")
		return
	data.climate = _climate_data
	data.attribution += " · Climate: CHELSA V2.1 (Karger et al.)"
	print("CLIMATE: %s %s" % [str(_climate_data), str(_climate.timings)])

## T5.4: far built-up landuse + real towers (bounded wait; absent →
## the far city continues from imagery alone). Over budget, the fetch
## keeps running and caches for the next visit.
func _await_far_city(data: LocationData) -> void:
	var waited := 0.0
	while not _farcity_done and waited < FARCITY_WAIT_S and not _cancelled:
		await get_tree().process_frame
		waited += get_process_delta_time()
	if not _farcity_done:
		print("Far-city fetch over budget; far city from imagery only")
		return
	data.far_landuse = _farcity_landuse
	data.far_towers = _farcity_towers
	print("FAR-CITY fetch: %s" % str(_farcity.timings))

func _build_dem(data: LocationData) -> void:
	var n := FastNoiseLite.new()
	n.seed = data.seed_value
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.035
	n.fractal_octaves = 4
	var size := data.grid_size
	data.heights.resize(size * size)
	# Paris basin is gentle; alpine-like relief elsewhere. Amplitude is a
	# placeholder until real DEM tiles land behind this same contract.
	var amplitude := 6.0 if data.place_name.begins_with("Paris") else 26.0
	data.relief_metres = 60.0 if data.place_name.begins_with("Paris") else 800.0
	for z in size:
		for x in size:
			var nx := (float(x) / size - 0.5) * 8.0
			var nz := (float(z) / size - 0.5) * 8.0
			var ridge: float = 1.0 - absf(n.get_noise_2d(nx * 1.6, nz * 1.6))
			var h: float = n.get_noise_2d(nx, nz) * amplitude \
				+ ridge * ridge * amplitude * 0.7
			# Flatten the viewpoint clearing at the centre.
			var d := Vector2(nx, nz).length()
			h = lerpf(h, amplitude * 0.12, clampf(1.2 - d, 0.0, 1.0) * 0.85)
			# Base lift keeps most land above the water plane.
			data.heights[z * size + x] = h + amplitude * 0.45
	# Water sits below typical ground; only deep lows flood for now.
	data.water_level = -3.0
	# Procedural heights are already metre-scale numbers, read as ASL
	# since T1.3; record the centre so builders/tests see a datum.
	data.centre_elevation_m = data.height_at(size / 2, size / 2)
