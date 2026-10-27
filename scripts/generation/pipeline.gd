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
		data.heights.resize(_dem_heights.size())
		for idx in _dem_heights.size():
			data.heights[idx] = (_dem_heights[idx] - centre_m) * vscale + 3.0
		data.water_level = -3.0
	else:
		_build_dem(data)

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
