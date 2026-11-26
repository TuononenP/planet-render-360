class_name PipelineData
extends RefCounted

## Pure data-assembly helpers extracted from GenerationPipeline (pipeline.gd)
## so pipeline.gd stays well under the 1000-line class limit.

## Nearest first, except monuments (columns, obelisks) and observation
## wheels in range rank first: they are few, and one cut by the cap
## would be extruded as a windowed tower or slab instead.
static func rank_landmarks(cands: Array) -> Array:
	var ranked := cands.duplicate()
	var reach2: float = TerrainBuilder.LANDMARK_MAX_M ** 2
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var da := float(a["x"]) ** 2 + float(a["z"]) ** 2
		var db := float(b["x"]) ** 2 + float(b["z"]) ** 2
		var ma: bool = (a.get("monument", false) or a.get("archetype", "") == "big_wheel") and da <= reach2
		var mb: bool = (b.get("monument", false) or b.get("archetype", "") == "big_wheel") and db <= reach2
		return da < db if ma == mb else ma)
	return ranked

## Populates `data` with parsed OSM layers and landmark candidates; returns
## true if any OSM map geometry was present.
static func apply_osm_layers(data: LocationData, osm: OsmFetcher, buildings: Array,
		roads_v2: Array, land: Array, waterways: Array, trees: Array, barriers: Array,
		landmarks: Array, warm_only: bool) -> bool:
	data.pois = osm.pois
	if buildings.is_empty() and land.is_empty() and waterways.is_empty() \
			and roads_v2.is_empty() and osm.shore_structures.is_empty():
		# No map data: the registry's other landmarks still stand.
		data.landmark_candidates = LandmarkSites.select(data, [])
		return false
	data.buildings = buildings
	data.roads = roads_v2
	data.land_polygons = OsmGeometry.land_by_priority(land)
	data.waterways = waterways
	data.trees = trees
	data.barriers = barriers
	data.country = osm.country
	data.railways = osm.railways
	StockholmTram.complete(data)
	data.street_furniture = osm.furniture
	data.tram_stops = osm.tram_stops
	data.bus_stops = osm.bus_stops
	data.rail_platforms = osm.rail_platforms
	data.rail_stations = osm.rail_stations
	data.piers = osm.piers
	data.shore_structures = osm.shore_structures
	data.bridge_areas = osm.bridge_areas
	data.aeroways = osm.aeroways
	if not warm_only:
		HeritageZones.apply(data)
		data.landmark_candidates = LandmarkSites.select(data,
			rank_landmarks(HeritageZones.filter_candidates(data, landmarks)))
		HeritageZones.drop_cleared(data)
	return true

## Procedural DEM fallback when real elevation tiles are unavailable.
static func build_dem(data: LocationData) -> void:
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
