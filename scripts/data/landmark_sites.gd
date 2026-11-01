class_name LandmarkSites
extends RefCounted

## The landmark candidates a place builds (LocationData.landmark_candidates),
## in one owner: registry landmarks in range besides the primary (a city
## with two or three icons: One WTC, the Empire State Building and the
## Statue of Liberty from one New York view), then the ranked OSM
## candidates. An OSM candidate standing on a registry site is dropped,
## so no generic tower rises inside a hand-built model. Every candidate
## either builds a model or is a mapped landmark drawn from its own parts
## (LandmarkFidelity): nothing is cleared without a replacement.
## A bridge (`span_m`) clears along its whole span, not round its centre.

## Candidates per quality preset (FAST, BALANCED, HIGH, ULTRA).
const MAX_BY_PRESET: Array[int] = [6, 8, 10, 10]
## Clearance around a registry landmark (its own footprint and grounds)
## and around an OSM archetype, metres.
const REGISTRY_CLEAR_M := 68.0
const OSM_CLEAR_M := 36.0

static func select(data: LocationData, ranked_osm: Array) -> Array:
	var out: Array = []
	var clear: Array = []
	if data.landmark_type != "none":
		clear.append([TerrainBuilder.landmark_site_xz(data),
			LocationData.entry_for_type(data.landmark_type)])
	for e in LocationData.registry_extras(data.latitude, data.longitude, data.landmark_type):
		var entry := e as Dictionary
		var p := WorldScale.xz_from_latlon(float(entry["lat"]), float(entry["lon"]),
			data.latitude, data.longitude)
		out.append({"x": p.x, "z": p.y, "type": str(entry["type"]),
			"name": str(entry["name"]), "wikipedia": "en:" + str(entry.get("wiki_title", entry["name"])),
			"archetype": str(entry.get("kind", "landmark")), "height": float(entry.get("height_m", 0.0)),
			"clear_m": clear_m(entry), "yaw_deg": float(entry.get("yaw_deg", 0.0)),
			"span_m": float(entry.get("span_m", 0.0)), "base": str(entry.get("base", "ground")),
			"registry": true})
		clear.append([p, entry])
	var cap: int = MAX_BY_PRESET[clampi(data.quality_preset, 0, MAX_BY_PRESET.size() - 1)]
	for c in ranked_osm:
		if out.size() >= cap:
			break
		var at := Vector2(float(c.get("x", 0.0)), float(c.get("z", 0.0)))
		var taken := false
		for cl in clear:
			if span_dist(at, cl[0] as Vector2, cl[1] as Dictionary) < clear_m(cl[1] as Dictionary):
				taken = true
				break
		if not taken:
			out.append(c)
	return out

## A registry entry's clearance (its `clear_m`, else REGISTRY_CLEAR_M).
static func clear_m(entry: Dictionary) -> float:
	return float(entry.get("clear_m", REGISTRY_CLEAR_M))

## Horizontal axis (x, z) of a site's model: its +X turned by yaw_deg.
static func axis(entry: Dictionary) -> Vector2:
	var y := deg_to_rad(float(entry.get("yaw_deg", 0.0)))
	return Vector2(cos(y), sin(y))

## Distance from `p` to a site at `at`: to the segment `span_m` long along
## its axis for a bridge, else to `at` itself.
static func span_dist(p: Vector2, at: Vector2, entry: Dictionary) -> float:
	var half := float(entry.get("span_m", 0.0)) * 0.5
	if half <= 0.0:
		return p.distance_to(at)
	var a := axis(entry)
	return p.distance_to(at + a * clampf((p - at).dot(a), -half, half))

## Registry bridges standing in this world, [site xz, entry] each: the
## primary and the registry candidates that carry a span.
static func bridge_spans(data: LocationData) -> Array:
	var out: Array = []
	if data.landmark_type != "none":
		var e := LocationData.entry_for_type(data.landmark_type)
		if float(e.get("span_m", 0.0)) > 0.0:
			out.append([TerrainBuilder.landmark_site_xz(data), e])
	for c in data.landmark_candidates:
		var cd := c as Dictionary
		if cd.has("type") and float(cd.get("span_m", 0.0)) > 0.0:
			out.append([Vector2(float(cd["x"]), float(cd["z"])), cd])
	return out

## Runs of a bridge-deck polyline outside every registry bridge's span
## (within its clear_m of the axis the model's own deck is the road):
## the whole line when no bridge stands on it.
static func outside_spans(pts: PackedVector2Array, spans: Array) -> Array:
	if spans.is_empty():
		return [pts]
	var out: Array = []
	var run := PackedVector2Array()
	for p in pts:
		var inside := false
		for sp in spans:
			if span_dist(p, sp[0] as Vector2, sp[1] as Dictionary) < clear_m(sp[1] as Dictionary):
				inside = true
				break
		if inside:
			if run.size() >= 2:
				out.append(run)
			run = PackedVector2Array()
		else:
			run.append(p)
	if run.size() >= 2:
		out.append(run)
	return out
