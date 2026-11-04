class_name SuomenlinnaSite
extends RefCounted

## Present-day main islands, excluding Särkkä, Lonna and Vallisaari.
## Shape/finish references: docs/suomenlinna-sources.md. Heights without
## tags are visual estimates, not surveyed dimensions.
const BOUNDARY := [Vector2(60.1370, 24.9870), Vector2(60.1375, 24.9915),
	Vector2(60.1450, 24.9943), Vector2(60.1519, 24.9905), Vector2(60.1540, 24.9780),
	Vector2(60.1512, 24.9720), Vector2(60.1470, 24.9705), Vector2(60.1410, 24.9770)]
const DEFENSES := ["bastion", "demi-bastion", "curtain_wall", "caponier", "counterguard",
	"tenaille", "traverse", "battery", "ravelin"]
## Built-over bastions / occupied halls keep their mapped building fabric.
const OCCUPIED := ["way:170492948", "way:24917011", "way:24907667", "way:1258400719"]
const GATE := "way:1258400732"
const SHORE_DEFENSE := "way:117478918"
const BEACON := "way:149359282"

static func contains(lat: float, lon: float) -> bool:
	return lat >= 60.1370 and lat <= 60.1540 and lon >= 24.9705 and lon <= 24.9943 \
		and Geometry2D.is_point_in_polygon(Vector2(lat, lon), PackedVector2Array(BOUNDARY))

## Extra selectors only when the detailed query overlaps the main islands.
static func query(lat: float, lon: float, radius_m: int) -> String:
	if LocationData.distance_m(lat, lon, 60.1455, 24.9830) > float(radius_m) + 1200.0:
		return ""
	return ('(way["defensive_works"](60.1370,24.9705,60.1540,24.9943)(around:%d,%.6f,%.6f);'
		+ 'relation["defensive_works"]["type"="multipolygon"](60.1370,24.9705,60.1540,24.9943)(around:%d,%.6f,%.6f););out geom 300;') \
		% [radius_m, lat, lon, radius_m, lat, lon]

static func apply(buildings: Array, barriers: Array, lat: float, lon: float, landmarks: Array = []) -> void:
	for b in buildings:
		_mark(b, lat, lon)
		for part in b.get("parts", []):
			_mark(part, lat, lon)
	# The photographed small white beacon is a mapped building, not the
	# generic striped lighthouse archetype. Its own geometry owns the site.
	for i in range(landmarks.size() - 1, -1, -1):
		var candidate: Dictionary = landmarks[i]
		if str(candidate.get("archetype", "")) != "lighthouse":
			continue
		for b in buildings:
			if str(b.get("osm_id", "")) == BEACON and Vector2(float(b["x"]), float(b["z"])).distance_to(
					Vector2(float(candidate["x"]), float(candidate["z"]))) < 3.0:
				landmarks.remove_at(i)
				break
	var defenses := rings(buildings)
	for barrier in barriers:
		var pts: PackedVector2Array = barrier.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var p := WorldScale.latlon_from_xz(pts[0].x, pts[0].y, lat, lon)
		if contains(p.x, p.y):
			barrier["suomenlinna"] = true
			if str(barrier.get("class", "")) not in ["wall", "city_wall", "retaining_wall"]:
				continue
			var length := 0.0
			var near := INF
			for i in pts.size() - 1:
				length += pts[i].distance_to(pts[i + 1])
				near = minf(near, distance((pts[i] + pts[i + 1]) * 0.5, defenses))
			barrier["fortress_wall"] = str(barrier.get("defensive_works", "")) in DEFENSES \
				or (length >= 18.0 and near < 12.0)

static func _mark(b: Dictionary, lat: float, lon: float) -> void:
	var p := WorldScale.latlon_from_xz(float(b["x"]), float(b["z"]), lat, lon)
	if not contains(p.x, p.y):
		return
	b["suomenlinna"] = true
	var id := str(b.get("osm_id", ""))
	if id == BEACON:
		b["fortress_form"] = "beacon"
	elif id == GATE:
		b["fortress_form"] = "gate"
	elif id == SHORE_DEFENSE:
		b["fortress_form"] = "rampart"
	elif not occupied(b) and (str(b.get("defensive_works", "")) in DEFENSES \
			or str(b.get("kind", "")) == "bunker" or str(b.get("casemate", "")) == "yes"):
		b["fortress_form"] = "casemate" if str(b.get("kind", "")) == "bunker" \
			or str(b.get("casemate", "")) == "yes" else "rampart"

static func occupied(b: Dictionary) -> bool:
	return str(b.get("osm_id", "")) in OCCUPIED \
		or str(b.get("kind", "")) in ["apartments", "residential", "house", "school", "office", "public"] \
		or str(b.get("use", "")) in ["restaurant", "cafe", "museum", "hostel", "school", "office"]

static func fortress(b: Dictionary) -> bool:
	return bool(b.get("suomenlinna", false)) and str(b.get("fortress_form", "")) != ""

## Defaults under explicit OSM dimensions/materials; no modern balconies,
## mansards, rooftop plant or guessed apartment towers on the islands.
static func look(b: Dictionary, original: Dictionary, area_m2: float) -> Dictionary:
	if not bool(b.get("suomenlinna", false)) or str(original["kind"]) in ["religious", "outbuilding"]:
		return original
	var out := original.duplicate()
	var levels := 1 if area_m2 < 180.0 else 2
	var brick := str(b.get("material", "")) == "brick" or str(b.get("kind", "")) == "industrial"
	out.merge({"wall_set": "brick" if brick else "render",
		"wall_colour": Color("#986a53" if brick else "#d2c5a4").srgb_to_linear(),
		"pattern": "punched", "window": "casement", "bay_m": 3.2,
		"roof_shape": "gabled", "roof_set": "concrete", "pitch": 0.65,
		"roof_colour": Color("#555952").srgb_to_linear(), "floor_h": 3.3,
		"storeys": levels, "default_h": float(levels) * 3.3 + 2.4,
		"ground": "none", "chimney": 0.15, "dormer": 0.0, "equip": 0.0,
		"tower": "", "rails": 0.0, "relief": {}, "era": "suomenlinna"}, true)
	return out

## Defensive outlines used for ownership only; ordinary buildings and
## courtyard interiors do not claim adjacent walls or shore segments.
static func rings(buildings: Array) -> Array:
	var out: Array = []
	for b in buildings:
		var parts: Array = b.get("parts", [])
		for m in ([b] if parts.is_empty() else parts):
			if fortress(m):
				var ring: PackedVector2Array = m.get("footprint", PackedVector2Array())
				if ring.size() >= 3:
					out.append(ring)
	return out

static func distance(p: Vector2, outlines: Array) -> float:
	var d := INF
	for ring in outlines:
		for i in ring.size():
			var q := Geometry2D.get_closest_point_to_segment(p, ring[i], ring[(i + 1) % ring.size()])
			d = minf(d, p.distance_to(q))
	return d

## The DEM smooths the waterfront gate into the bastion behind it. Lower
## only its mapped terrace and a short passage, before shoreline meshing.
## Heights here are metres ASL, in GroundTruth's pre-rebase surface.
static func grade_gate(surface: PackedFloat32Array, size: int, step: float,
		buildings: Array, lat: float, lon: float) -> void:
	var gate: Dictionary = {}
	for b in buildings:
		for m in [b] + (b.get("parts", []) as Array):
			if str(m.get("fortress_form", "")) == "gate":
				gate = m
	if gate.is_empty():
		return
	var ring: PackedVector2Array = gate["footprint"]
	var at := WorldScale.xz_from_latlon(60.1395806, 24.9899411, lat, lon)
	var n := Vector2(-0.18, 0.984).normalized()
	var u := Vector2(n.y, -n.x)
	var box := RingGeometry.aabb(ring).grow(10.0)
	var half := WorldScale.detailed_extent_units() * 0.5
	var lo := ((box.position + Vector2.ONE * half) / step).floor()
	var hi := ((box.end + Vector2.ONE * half) / step).ceil()
	for z in range(maxi(0, int(lo.y)), mini(size - 1, int(hi.y)) + 1):
		for x in range(maxi(0, int(lo.x)), mini(size - 1, int(hi.x)) + 1):
			var p := Vector2(x, z) * step - Vector2.ONE * half
			var rel := p - at
			var court := Geometry2D.is_point_in_polygon(p, ring)
			var d := 0.0 if court else distance(p, [ring])
			# Includes the facade apron and the doorway behind it. This is
			# ground clearance, not a new road or widened island coastline.
			var passage := Vector2(rel.dot(u), rel.dot(n))
			var corridor := maxf(absf(passage.x) - 10.0, absf(passage.y + 0.5) - 5.0)
			d = minf(d, maxf(corridor, 0.0))
			if d < 5.0:
				var index := z * size + x
				var target := minf(surface[index], 2.2)
				surface[index] = lerpf(target, surface[index], smoothstep(0.0, 5.0, d))
