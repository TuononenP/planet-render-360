class_name GenerationPipeline
extends Node

## Staged, cancellable location-generation pipeline.
## Stage 0 fetches a real DEM tile (DemFetcher, AWS Terrain Tiles) and
## falls back to a deterministic procedural DEM when offline or on error.
## Both paths normalise into the same LocationData contract.

signal stage_changed(index: int, label: String, state: String)
signal progress_changed(fraction: float, label: String)
signal finished(data: LocationData)
signal cancelled

const STAGES: Array[String] = [
	"Fetching elevation",
	"Mapping land cover",
	"Placing landmarks",
	"Adding vegetation",
	"Finalizing lighting",
]

var _cancelled := false
var used_real_dem := false
var _fetcher: DemFetcher
var _dem_heights: PackedFloat32Array = PackedFloat32Array()
var _dem_done := false
var _far_fetcher: DemFetcher
var _far_heights_m: PackedFloat32Array = PackedFloat32Array()
var _far_done := false
var _dem_centre_m := 0.0
var _dem_vscale := 0.1
var used_osm := false
var _osm: OsmFetcher
var _osm_buildings: Array = []
var _osm_roads: Array = []
var _osm_land: Array = []
var _osm_done := false

func _ready() -> void:
	_fetcher = DemFetcher.new()
	add_child(_fetcher)
	_fetcher.succeeded.connect(func(h: PackedFloat32Array, _g: int) -> void:
		_dem_heights = h
		_dem_done = true)
	_fetcher.failed.connect(func(reason: String) -> void:
		push_warning("DEM fetch failed, using procedural fallback: %s" % reason)
		_dem_done = true)
	_far_fetcher = DemFetcher.new()
	add_child(_far_fetcher)
	_far_fetcher.succeeded.connect(func(h: PackedFloat32Array, _g: int) -> void:
		_far_heights_m = h
		_far_done = true)
	_far_fetcher.failed.connect(func(reason: String) -> void:
		push_warning("Far DEM fetch failed, using procedural backdrop: %s" % reason)
		_far_done = true)
	_osm = OsmFetcher.new()
	add_child(_osm)
	_osm.succeeded.connect(func(b: Array, r: Array, l: Array) -> void:
		_osm_buildings = b
		_osm_roads = r
		_osm_land = l
		_osm_done = true)
	_osm.failed.connect(func(reason: String) -> void:
		push_warning("OSM fetch failed, using procedural dressing: %s" % reason)
		_osm_done = true)

func cancel() -> void:
	_cancelled = true

func run(lat: float, lon: float, place_name_override: String = "") -> void:
	_cancelled = false
	var data := LocationData.new()
	data.latitude = lat
	data.longitude = lon
	data.place_name = place_name_override if place_name_override != "" \
		else LocationData.known_place(lat, lon)
	data.landmark_type = LocationData.landmark_for(lat, lon, data.place_name)
	data.seed_value = int(abs(sin(lat * 12.9898 + lon * 78.233) * 43758.5453)) % 100000
	# Start OSM fetch now so it overlaps the staged timers below.
	used_osm = false
	_osm_done = false
	_osm_buildings = []
	_osm_roads = []
	_osm_land = []
	_osm.fetch(lat, lon)
	# Far backdrop fetch overlaps everything else; converted in stage 0
	# once the detailed centre/scale are known.
	_far_done = false
	_far_heights_m = PackedFloat32Array()
	_far_fetcher.fetch_far(lat, lon, data.far_grid_size)

	for i in STAGES.size():
		if _cancelled:
			cancelled.emit()
			return
		stage_changed.emit(i, STAGES[i], "in_progress")
		progress_changed.emit(float(i) / STAGES.size(), STAGES[i])
		await get_tree().create_timer(0.35).timeout
		if _cancelled:
			cancelled.emit()
			return
		if i == 0:
			await _fetch_dem(data)
			if _cancelled:
				cancelled.emit()
				return
		if i == 2:
			await _await_osm(data)
			if _cancelled:
				cancelled.emit()
				return
		stage_changed.emit(i, STAGES[i], "done")

	progress_changed.emit(1.0, "Done")
	finished.emit(data)

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
		data.attribution = "Elevation: AWS Terrain Tiles — EU-DEM / Copernicus, USGS 3DEP, SRTM and other sources (see docs/data-source-register.md)"
		var centre_m := _dem_heights[(data.grid_size / 2) * data.grid_size + data.grid_size / 2]
		var mn := _dem_heights[0]
		var mx := _dem_heights[0]
		for h in _dem_heights:
			mn = minf(mn, h)
			mx = maxf(mx, h)
		# Adaptive vertical scale: total relief maps to ~30 world units,
		# so flat Paris and alpine Interlaken both stay readable.
		var vscale := clampf(30.0 / maxf(mx - mn, 1.0), 0.02, 0.35)
		_dem_centre_m = centre_m
		_dem_vscale = vscale
		data.heights.resize(_dem_heights.size())
		for idx in _dem_heights.size():
			data.heights[idx] = (_dem_heights[idx] - centre_m) * vscale + 3.0
		data.water_level = -3.0
	else:
		_build_dem(data)
	await _apply_far(data)

func _apply_far(data: LocationData) -> void:
	var waited := 0.0
	while not _far_done and waited < 12.0 and not _cancelled:
		await get_tree().process_frame
		waited += get_process_delta_time()
	var grid := data.far_grid_size
	if used_real_dem and _far_heights_m.size() == grid * grid:
		data.far_centre_frac = _far_fetcher.far_centre_frac
		data.far_heights.resize(_far_heights_m.size())
		for idx in _far_heights_m.size():
			data.far_heights[idx] = (_far_heights_m[idx] - _dem_centre_m) * _dem_vscale + 3.0
	else:
		_build_far_procedural(data)

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
	var cell_world := data.far_extent / float(grid)
	for z in grid:
		for x in grid:
			var dist_world := Vector2(float(x - grid / 2), float(z - grid / 2)).length() * cell_world
			var grow := clampf((dist_world - 260.0) / 900.0, 0.0, 1.0)
			data.far_heights[z * grid + x] = centre_h \
				+ n.get_noise_2d(float(x) * 0.55, float(z) * 0.55) * amp * grow \
				+ amp * 0.55 * grow

func _await_osm(data: LocationData) -> void:
	var waited := 0.0
	while not _osm_done and waited < 32.0 and not _cancelled:
		await get_tree().process_frame
		waited += get_process_delta_time()
	if not _osm_buildings.is_empty():
		used_osm = true
		data.buildings = _osm_buildings
		data.roads = _osm_roads
		data.land_polygons = _osm_land
		var osm_attr := "Map data: © OpenStreetMap contributors"
		data.attribution = osm_attr if data.attribution.is_empty() \
			else data.attribution + " · " + osm_attr

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
