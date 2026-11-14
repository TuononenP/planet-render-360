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
const MAX_BY_PRESET: Array[int] = [10, 16, 22, 26]
## Registry icons beside the primary per preset, priority then nearest: a
## historic centre (Rome, Athens) stands a dozen of them together.
const MAX_REGISTRY_EXTRAS_BY_PRESET: Array[int] = [6, 12, 18, 22]
## Capital bridges (secondary `kind: "Bridge"` entries, see BridgeSpec) per
## preset, after the extras: they never take an icon's slot, only room left
## under MAX_BY_PRESET.
const MAX_BRIDGES_BY_PRESET: Array[int] = [2, 4, 6, 8]
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
	var extras := LocationData.registry_extras(data.latitude, data.longitude, data.landmark_type)
	# Give explicitly important skyline landmarks a slot before distance
	# applies. Unmarked entries retain their existing nearest-first order.
	extras.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ap := int(a.get("skyline_priority", 0))
		var bp := int(b.get("skyline_priority", 0))
		if ap != bp:
			return ap > bp
		return LocationData.distance_m(data.latitude, data.longitude, float(a["lat"]), float(a["lon"])) \
			< LocationData.distance_m(data.latitude, data.longitude, float(b["lat"]), float(b["lon"])))
	var preset := clampi(data.quality_preset, 0, MAX_BY_PRESET.size() - 1)
	var registry_limit := MAX_REGISTRY_EXTRAS_BY_PRESET[preset]
	# A dense primary skyline can use more Ultra slots, but never more
	# than the preset's total candidate budget.
	if preset == MAX_BY_PRESET.size() - 1:
		var primary := LocationData.entry_for_type(data.landmark_type)
		registry_limit = clampi(int(primary.get("ultra_registry_limit", registry_limit)), registry_limit, MAX_BY_PRESET[preset])
	var icons: Array = extras.filter(func(e: Dictionary) -> bool: return not _is_capital_bridge(e)).slice(0, registry_limit)
	# Bridges fill only the room the icons leave under the preset's candidate cap.
	var bridges := _nearest_bridges(data, extras,
		mini(MAX_BRIDGES_BY_PRESET[preset], maxi(MAX_BY_PRESET[preset] - icons.size(), 0)))
	for e in icons + bridges:
		var entry := e as Dictionary
		var p := WorldScale.xz_from_latlon(float(entry["lat"]), float(entry["lon"]),
			data.latitude, data.longitude)
		out.append({"x": p.x, "z": p.y, "type": str(entry["type"]),
			"name": str(entry["name"]), "wikipedia": "en:" + str(entry.get("wiki_title", entry["name"])),
			"archetype": str(entry.get("kind", "landmark")), "height": float(entry.get("height_m", 0.0)),
			"clear_m": clear_m(entry), "yaw_deg": float(entry.get("yaw_deg", 0.0)),
			"span_m": float(entry.get("span_m", 0.0)), "base": str(entry.get("base", "ground")),
			"base_drop_m": float(entry.get("base_drop_m", 0.0)),
			"registry": true})
		for key in ["clear_offsets_m", "clear_path_m", "clear_rect_m", "tree_clear_m"]:
			if entry.has(key):
				var candidate: Dictionary = out.back()
				candidate[key] = entry[key]
		clear.append([p, entry])
	var cap: int = MAX_BY_PRESET[preset]
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

## A capital bridge: a secondary bridge entry (BridgeSpec.to_entry).
static func _is_capital_bridge(entry: Dictionary) -> bool:
	return bool(entry.get("secondary", false)) and str(entry.get("kind", "")) == "Bridge"

## The capital bridges among `extras` to build: the most important tier
## first, then those whose span passes nearest the view centre, at most
## `limit`. The viewpoint need not be at a bridge's centre, so the distance
## is to the span itself.
static func _nearest_bridges(data: LocationData, extras: Array, limit: int) -> Array:
	var found: Array = extras.filter(func(e: Dictionary) -> bool: return _is_capital_bridge(e))
	var view := Vector2.ZERO
	var dist := func(e: Dictionary) -> float:
		var at := WorldScale.xz_from_latlon(float(e["lat"]), float(e["lon"]), data.latitude, data.longitude)
		return span_dist(view, at, e)
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var at := int(a.get("tier", 2))
		var bt := int(b.get("tier", 2))
		if at != bt:
			return at < bt
		return dist.call(a) < dist.call(b))
	return found.slice(0, limit)

## A registry entry's clearance (its `clear_m`, else REGISTRY_CLEAR_M).
static func clear_m(entry: Dictionary) -> float:
	return float(entry.get("clear_m", REGISTRY_CLEAR_M))

## Horizontal axis (x, z) of a site's model: its +X turned by yaw_deg.
static func axis(entry: Dictionary) -> Vector2:
	var y := deg_to_rad(float(entry.get("yaw_deg", 0.0)))
	return Vector2(cos(y), sin(y))

## Distance from `p` to a site at `at`: to its `clear_path_m` polyline
## (a curved bridge), to the segment `span_m` long along its axis for a
## straight bridge, else to `at` itself; never farther than its
## `clear_rect_m` precinct (0 inside it).
static func span_dist(p: Vector2, at: Vector2, entry: Dictionary) -> float:
	var d := _shape_dist(p, at, entry)
	if entry.has("clear_rect_m"):
		d = minf(d, rect_dist(p, at, entry))
	return d

## Distance from `p` to a site's `clear_rect_m` precinct, [along, across,
## half_along, half_across] metres in the model frame (yaw_deg turns it):
## 0 inside, INF without one. A walled temple compound clears its whole
## court, not a circle round the sanctuary.
static func rect_dist(p: Vector2, at: Vector2, entry: Dictionary) -> float:
	var r: Array = entry.get("clear_rect_m", [])
	if r.size() < 4:
		return INF
	var a := axis(entry)
	var cross := Vector2(-a.y, a.x)
	var m := WorldScale.metres_to_units()
	var d := p - (at + (a * float(r[0]) + cross * float(r[1])) * m)
	return Vector2(maxf(absf(d.dot(a)) - float(r[2]) * m, 0.0),
		maxf(absf(d.dot(cross)) - float(r[3]) * m, 0.0)).length()

static func _shape_dist(p: Vector2, at: Vector2, entry: Dictionary) -> float:
	if entry.has("clear_path_m"):
		var path := path_points(at, entry)
		var best := INF
		for i in path.size() - 1:
			best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, path[i], path[i + 1])))
		return best
	var half := float(entry.get("span_m", 0.0)) * 0.5
	if half <= 0.0 and not entry.has("clear_offsets_m"):
		return p.distance_to(at)
	var offsets: Array = entry.get("clear_offsets_m", [])
	if half <= 0.0 and offsets.is_empty():
		return p.distance_to(at)
	var a := axis(entry)
	var dist := p.distance_to(at + a * clampf((p - at).dot(a), -half, half))
	# Separate model footprints preserve buildings between the components.
	var cross := Vector2(-a.y, a.x)
	for raw in offsets:
		var offset: Array = raw
		var subsite := at + a * float(offset[0]) + cross * float(offset[1])
		dist = minf(dist, p.distance_to(subsite))
	return dist

## A site's `clear_path_m` ([along, across] metres in the model frame,
## like clear_offsets_m) placed at `at`; empty without one.
static func path_points(at: Vector2, entry: Dictionary) -> PackedVector2Array:
	var out := PackedVector2Array()
	var a := axis(entry)
	var cross := Vector2(-a.y, a.x)
	for raw in entry.get("clear_path_m", []):
		var q: Array = raw
		out.append(at + (a * float(q[0]) + cross * float(q[1])) * WorldScale.metres_to_units())
	return out

## Registry bridges standing in this world, [site xz, entry] each: the
## primary and the registry candidates that carry a span.
static func bridge_spans(data: LocationData) -> Array:
	var out: Array = []
	if data.landmark_type != "none":
		var e := LocationData.entry_for_type(data.landmark_type)
		if str(e.get("kind", "")) == "Bridge" and float(e.get("span_m", 0.0)) > 0.0:
			out.append([TerrainBuilder.landmark_site_xz(data), e])
	for c in data.landmark_candidates:
		var cd := c as Dictionary
		var entry := LocationData.entry_for_type(str(cd.get("type", "")))
		if str(entry.get("kind", cd.get("archetype", ""))) == "Bridge" and float(cd.get("span_m", 0.0)) > 0.0:
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

## Tree keep-outs round the landmarks standing here, [site xz, entry,
## radius m, reach²] each: the primary always (its `tree_clear_m`, else
## DEFAULT_TREE_CLEAR_M round the site), a registry candidate only when it
## declares `tree_clear_m`. Distances run to the site's clearance shape
## (span_dist), so a precinct rect opens its whole court.
const DEFAULT_TREE_CLEAR_M := 48.0

static func tree_clears(data: LocationData) -> Array:
	var out: Array = []
	if data.landmark_type != "none":
		var e := LocationData.entry_for_type(data.landmark_type)
		out.append(_tree_clear(TerrainBuilder.landmark_world_pos(data), e,
			float(e.get("tree_clear_m", DEFAULT_TREE_CLEAR_M))))
	for c in data.landmark_candidates:
		var cd := c as Dictionary
		if cd.has("tree_clear_m"):
			out.append(_tree_clear(Vector2(float(cd.get("x", 0.0)), float(cd.get("z", 0.0))), cd,
				float(cd["tree_clear_m"])))
	return out

static func _tree_clear(at: Vector2, entry: Dictionary, radius: float) -> Array:
	var m := WorldScale.metres_to_units()
	var reach := radius + float(entry.get("span_m", 0.0)) * 0.5
	for raw in entry.get("clear_offsets_m", []):
		reach = maxf(reach, radius + Vector2(float(raw[0]), float(raw[1])).length())
	var r: Array = entry.get("clear_rect_m", [])
	if r.size() >= 4:
		reach = maxf(reach, radius + Vector2(absf(float(r[0])) + float(r[2]), absf(float(r[1])) + float(r[3])).length())
	return [at, entry, radius * m, pow(reach * m, 2.0)]

## True when no tree may stand at `p` (tree_clears).
static func tree_cleared(p: Vector2, clears: Array) -> bool:
	for c in clears:
		var at: Vector2 = c[0]
		if p.distance_squared_to(at) > float(c[3]):
			continue
		if span_dist(p, at, c[1] as Dictionary) < float(c[2]):
			return true
	return false
