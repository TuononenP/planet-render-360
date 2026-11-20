class_name MalarShips
extends RefCounted

## Stockholm's mapped passenger vessels (the hotel ships and old steamers of
## Söder Mälarstrand and Riddarholmen's quay): ShipBuilder gives every mapped
## ship the one coastal-steamer model in a seeded dark hull, a row of copies.
## Here each takes its own livery (hull and funnel) and, now and then, the
## café-boat model, a liner-sized mapped hull becomes a Mälaren steamer, and
## the hull stands a fender's width off the quay edge the footprint reaches.
## A colour mapped on the ship wins. Other cities keep ShipBuilder's look.
const LIVERIES := [
	{"hull": "#e9e6dc", "funnel": "#24415f"},
	{"hull": "#1d2126", "funnel": "#a8352a"},
	{"hull": "#2f4f6f", "funnel": "#e4e0d2"},
	{"hull": "#8a2f2a", "funnel": "#1d2126"},
	{"hull": "#2f4a3c", "funnel": "#c9b98a"},
	{"hull": "#efece4", "funnel": "#9c2f27"},
	{"hull": "#c9c2ae", "funnel": "#1f3a5c"},
]
## Share of mapped passenger ships that take the café-boat model, and the
## longest hull that does (m).
const CAFE_SHARE := 0.25
const CAFE_MAX_M := 42.0
## The tallest mast or funnel of a Mälaren steamer (m).
const HEIGHT_MIN_M := 4.5
const HEIGHT_MAX_M := 18.0
## How far a hull is moved off the quay (m), and the quay edge's distance
## from its side once moved (the mapped footprint reaches the edge).
const OFFSHORE_M := 1.2
const QUAY_EDGE_M := 1.5
## Hulls this near the eye (m) get mooring lines and fenders.
const MOOR_NEAR_M := 350.0

## Whether `model` of a mapped ship in `data` is dressed here.
static func applies(data: LocationData, model: String) -> bool:
	return model in ["passenger", "liner"] \
		and CityStyles.region_at(data.latitude, data.longitude) == "stockholm"

## Hull types of the mapped row, chosen by footprint (`eligible`): "passenger"
## (the classic steamer), "steam_yacht", "archipelago" (MalarVesselModels),
## "houseboat", "restaurant_boat" and "tall_ship" (PassengerVesselModel).
const KINDS := ["passenger", "steam_yacht", "archipelago", "houseboat", "restaurant_boat", "tall_ship"]
## A hull this slim (beam over length) may be a sailing ship; one this broad is a barge.
const SLIM := 0.24
static var _plan_for := 0
static var _plan := {}
static var _lock := Mutex.new()

## The hull types a mapped footprint of `length` x `beam` metres allows.
static func eligible(length: float, beam: float) -> Array:
	var out: Array = []
	if length <= 32.0 or beam / maxf(length, 1.0) > 0.3:
		out.append_array(["houseboat", "restaurant_boat"])
	if length >= 22.0 and length <= 72.0:
		out.append_array(["steam_yacht", "archipelago"])
	if length >= 30.0:
		out.append("passenger")
	if length >= 30.0 and length <= 62.0 and beam / maxf(length, 1.0) < SLIM:
		out.append("tall_ship")
	if out.is_empty():
		out.append("passenger")
	return out

## The hull type of every mapped passenger ship of `data`, by its centre
## (Vector2i, metres): each takes the allowed type used least so far that
## differs from its two neighbours along the quay (ships ordered by x, then z),
## ties broken by a seeded pick, so a row never repeats a silhouette side by side;
## only the first takes a sailing ship.
static func plan(data: LocationData) -> Dictionary:
	if CityStyles.region_at(data.latitude, data.longitude) != "stockholm":
		return {}
	_lock.lock()
	var key := data.get_instance_id() * 31 + data.buildings.size()
	if _plan_for == key:
		var hit := _plan
		_lock.unlock()
		return hit
	var ships: Array = []
	for b in data.buildings:
		if b is Dictionary and ShipBuilder.accepts(b):
			var f := ShipBuilder.frame(b)
			if ShipBuilder.model_for(b, float(f["length"])) in ["passenger", "liner"]:
				ships.append(f)
	ships.sort_custom(func(a: Dictionary, c: Dictionary) -> bool:
		var pa: Vector2 = a["centre"]
		var pc: Vector2 = c["centre"]
		return pa.x < pc.x or (pa.x == pc.x and pa.y < pc.y))
	var used := {}
	var out := {}
	var last: Array = []
	for f: Dictionary in ships:
		var c: Vector2 = f["centre"]
		var allowed := eligible(float(f["length"]), float(f["beam"]))
		var open := allowed.filter(func(k: String) -> bool: return not last.has(k))
		if open.is_empty():
			open = allowed.filter(func(k: String) -> bool: return not last.slice(-1).has(k))
		if open.is_empty():
			open = allowed
		# One sailing ship to a row: a second hull takes the next-least-used type.
		if int(used.get("tall_ship", 0)) >= 1:
			var rest := open.filter(func(k: String) -> bool: return k != "tall_ship")
			if not rest.is_empty():
				open = rest
		var least := 9999
		for k: String in open:
			least = mini(least, int(used.get(k, 0)))
		var tied := open.filter(func(k: String) -> bool: return int(used.get(k, 0)) == least)
		var seed_value := fposmod(sin(c.x * 12.9898 + c.y * 78.233) * 43758.5453, 1.0)
		var pick: String = tied[int(seed_value * float(tied.size())) % tied.size()]
		used[pick] = int(used.get(pick, 0)) + 1
		last.append(pick)
		if last.size() > 2:
			last.pop_front()
		out[Vector2i(roundi(c.x), roundi(c.y))] = pick
	_plan_for = key
	_plan = out
	_lock.unlock()
	return out

## The hull type planned for the ship centred at `centre` ("" when unknown).
static func model_at(data: LocationData, centre: Vector2) -> String:
	return str(plan(data).get(Vector2i(roundi(centre.x), roundi(centre.y)), ""))

## {"model", "hull", "funnel", "height"} for the ship of `length` metres with
## `seed_value` (0..1) berthed at `at` (world XZ); `mapped_hull` "" takes the
## livery, `model` "" a seeded steamer or café boat. The livery steps with the
## berth's position (a 25 m cell, a stride of three), so neighbours along a
## quay never share one; a white archipelago boat and a dark sailing ship keep
## their own hulls.
static func look(length: float, seed_value: float, mapped_hull: String, at: Vector2 = Vector2.ZERO,
		model: String = "") -> Dictionary:
	var cell := int(floorf(at.x / 25.0)) * 3 + int(floorf(at.y / 25.0)) * 5
	var livery: Dictionary = LIVERIES[posmod(cell, LIVERIES.size())]
	if model == "":
		model = "restaurant_boat" if length <= CAFE_MAX_M and fposmod(seed_value * 3.7, 1.0) < CAFE_SHARE else "passenger"
	var tall := 0.85 + 0.55 * fposmod(seed_value * 5.3, 1.0)
	var hull := str(livery["hull"])
	var height := clampf((3.0 + length * 0.12) * tall, HEIGHT_MIN_M, HEIGHT_MAX_M)
	match model:
		"archipelago":
			hull = "#f0eee8"
			height = clampf(4.5 + length * 0.1, HEIGHT_MIN_M, HEIGHT_MAX_M)
		"steam_yacht":
			height = clampf(6.0 + length * 0.17, HEIGHT_MIN_M, HEIGHT_MAX_M)
		"tall_ship":
			hull = "#2a2420" if fposmod(seed_value * 2.9, 1.0) < 0.5 else "#3a2b20"
			height = length * 0.55 + 1.0
		"houseboat":
			height = clampf(3.8 + length * 0.05, 4.0, 5.6)
		"restaurant_boat":
			height = clampf(5.0 + length * 0.04, 5.0, 6.4)
	return {"model": model, "hull": mapped_hull if mapped_hull != "" else hull,
		"funnel": str(livery["funnel"]), "height": height}

## Which side of a hull of `beam` centred on `at` along `axis` the water lies
## (+1 or -1 along Vector2(-axis.y, axis.x)): water beyond the hull and land
## behind it; 0 when no side is so.
static func water_side(ground: GroundTruth, at: Vector2, axis: Vector2, beam: float) -> float:
	var normal := Vector2(-axis.y, axis.x)
	for sign_n in [-1.0, 1.0]:
		var out: Vector2 = at + normal * sign_n * (beam * 0.5 + 4.0)
		var inn: Vector2 = at - normal * sign_n * (beam * 0.5 + 1.5)
		if ground.is_inside(out.x, out.y) and ground.is_inside(inn.x, inn.y) \
				and ground.water_at(out.x, out.y) >= 0.5 and ground.water_at(inn.x, inn.y) < 0.3:
			return sign_n
	return 0.0

## The shift (world XZ) that moves a hull off the quay: OFFSHORE_M toward
## the water side, or zero when no side has water beyond the hull.
static func offshore(ground: GroundTruth, at: Vector2, axis: Vector2, beam: float) -> Vector2:
	return Vector2(-axis.y, axis.x) * water_side(ground, at, axis, beam) * OFFSHORE_M
