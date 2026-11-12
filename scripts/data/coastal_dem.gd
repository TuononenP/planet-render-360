class_name CoastalDem
extends RefCounted

## Some northern surface-model tiles carry a coherent positive sea bias.
## Measure it from open water on the right of directed OSM coastlines,
## then correct the near grid and matching fine DEM rings once. This is
## an observed sea-level registration, not a claimed geoid conversion.
const MIN_SAMPLES := 24
const MAX_SPREAD_M := 2.0
const MIN_BIAS_M := 5.0
const MAX_BIAS_M := 60.0

static func correct(data: LocationData) -> float:
	if data.dem_source.has("coast_bias_m"):
		return float(data.dem_source["coast_bias_m"])
	if not BareEarth.surface_model(data) or is_equal_approx(data.water_level, -3.0):
		return 0.0
	var samples := _coast_samples(data)
	var bias := _bias_of(samples)
	var method := "OSM open-sea median; IQR <= 2 m"
	if samples.size() < MIN_SAMPLES:
		# No usable coastline in the detailed square (a recentre inland):
		# the far water mask still knows where the sea is. A coastline whose
		# samples were rejected (spread, range) is not second-guessed.
		bias = estimate_from_mask(data)
		method = "water-mask open-sea median; IQR <= 2 m"
	if bias == 0.0:
		return 0.0
	for i in data.heights.size():
		data.heights[i] -= bias
	data.centre_elevation_m -= bias
	data.water_level = WaterBuilder.SEA_LEVEL_M
	for ring in data.dem_rings:
		# The coarse global fallback may use another source/datum.
		if int(ring.get("zoom", 0)) < 11:
			continue
		var heights: PackedFloat32Array = ring["heights"]
		for i in heights.size():
			heights[i] -= bias
		ring["heights"] = heights
	data.dem_source["coast_bias_m"] = bias
	data.dem_source["coast_bias_method"] = method
	print("COAST DEM registration: bias=%.2f m" % bias)
	return bias

static func estimate(data: LocationData) -> float:
	return _bias_of(_coast_samples(data))

## Heights on the open-water side of the OSM coastlines in reach.
static func _coast_samples(data: LocationData) -> Array[float]:
	var m := WorldScale.metres_to_units()
	var segments: Array = []
	for way in data.waterways:
		if str(way.get("class", "")) != "coastline":
			continue
		var pts: PackedVector2Array = way.get("points", PackedVector2Array())
		for i in pts.size() - 1:
			if pts[i].distance_to(pts[i + 1]) > 1.0 * m:
				segments.append([pts[i], pts[i + 1]])
	var samples: Array[float] = []
	for segment in segments:
		var a: Vector2 = segment[0]
		var b: Vector2 = segment[1]
		var delta := b - a
		var water_normal := Vector2(-delta.y, delta.x).normalized()
		var count := maxi(1, ceili(delta.length() / (100.0 * m)))
		for j in count:
			var origin := a.lerp(b, (float(j) + 0.5) / float(count))
			for distance in [90.0, 150.0, 200.0]:
				var p := origin + water_normal * float(distance) * m
				if not _open_water(p, segments, 60.0 * m):
					continue
				var h := _sample(data, p)
				if is_finite(h):
					samples.append(h)
	return samples

## The coherent bias the samples agree on, or 0 when too few, too spread
## or out of range.
static func _bias_of(samples: Array[float]) -> float:
	if samples.size() < MIN_SAMPLES:
		return 0.0
	samples.sort()
	var spread := samples[samples.size() * 3 / 4] - samples[samples.size() / 4]
	var median := samples[samples.size() / 2]
	if spread > MAX_SPREAD_M or median < MIN_BIAS_M or median > MAX_BIAS_M:
		return 0.0
	return snappedf(median, 0.01)

## Pixels of a fine ring (zoom 11+, the source the bias lives in) at
## least this far inside the mask's open sea count; within this radius.
const MASK_SHORE_M := 150.0
const MASK_RADIUS_M := 4000.0
const MASK_MAX_SAMPLES := 4000

## The same coherent sea bias, measured on the far water mask's open sea
## (FarWaterMask.OCEAN) in the finest DEM ring instead of along OSM
## coastlines in the detailed square.
static func estimate_from_mask(data: LocationData) -> float:
	var mask := data.far_water_mask
	if mask.is_empty():
		return 0.0
	var ring: Dictionary = {}
	for r: Dictionary in data.dem_rings:
		if int(r.get("zoom", 0)) >= 11:
			ring = r
			break
	if ring.is_empty():
		return 0.0
	var zoom := int(ring["zoom"])
	var w := int(ring["width"])
	var h := int(ring["height"])
	var heights: PackedFloat32Array = ring["heights"]
	var origin: Vector2 = ring["origin_px"]
	var world := float(1 << zoom) * 256.0
	var mpp := DemFetcher.metres_per_px(data.latitude, zoom)
	var centre := TileFetcher.global_pixel(data.latitude, data.longitude, zoom)
	var radius_px := MASK_RADIUS_M / mpp
	var shore_uv := MASK_SHORE_M / mpp / world
	var stride := maxi(1, int(ceil(sqrt(float(w * h) / float(MASK_MAX_SAMPLES)))))
	var samples: Array[float] = []
	for y in range(0, h, stride):
		for x in range(0, w, stride):
			var p := origin + Vector2(x + 0.5, y + 0.5)
			if p.distance_to(centre) > radius_px:
				continue
			var u := p.x / world
			var v := p.y / world
			var open := true
			for d: Vector2 in [Vector2.ZERO, Vector2(shore_uv, 0), Vector2(-shore_uv, 0),
					Vector2(0, shore_uv), Vector2(0, -shore_uv)]:
				if FarWaterMask.sample_uv(mask, u + d.x, v + d.y) != FarWaterMask.OCEAN:
					open = false
					break
			if open and is_finite(heights[y * w + x]):
				samples.append(heights[y * w + x])
	return _bias_of(samples)

static func _open_water(p: Vector2, segments: Array, minimum: float) -> bool:
	var best := INF
	var water := false
	for segment in segments:
		var a: Vector2 = segment[0]
		var b: Vector2 = segment[1]
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		var d := p.distance_to(q)
		if d < best:
			best = d
			var dir := b - a
			water = (p - q).dot(Vector2(-dir.y, dir.x)) > 0.0
	return water and best >= minimum

static func _sample(data: LocationData, p: Vector2) -> float:
	var ll := WorldScale.latlon_from_xz(p.x, p.y, data.latitude, data.longitude)
	var zoom := int(data.dem_source.get("source_zoom", 0))
	var step_px := DemRegistration.window_px(data) / float(data.grid_size)
	var delta := DemRegistration._px(ll.x, ll.y, zoom) - DemRegistration._px(data.latitude, data.longitude, zoom)
	var index := Vector2.ONE * float(data.grid_size) * 0.5 + (delta - Vector2.ONE * 0.5) / step_px
	if index.x >= 0.0 and index.y >= 0.0 and index.x < data.grid_size - 1 and index.y < data.grid_size - 1:
		return GroundTruth._grid_bilinear(data, index)
	for ring in data.dem_rings:
		var sample := FarSurface.ring_sample(data, ring, p.x / WorldScale.metres_to_units(), p.y / WorldScale.metres_to_units())
		if sample.y > 0.95:
			return sample.x
	return NAN
