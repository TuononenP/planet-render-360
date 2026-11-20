class_name QuayFleet
extends RefCounted

## Individual vessels along a named quay row (QuayMoorings QUAY_ROWS "fleet"):
## where a row is known for its mixed moored craft (Söder Mälarstrand's hotel
## ships, old steamers, a wooden sailing ship, houseboats and a restaurant
## boat) each berth takes the next vessel of the fleet, of its own model,
## livery and length, with a jittered gap, and lies either way round. Hulls
## keep a fender's width off the quay edge. Harbour dressing, not a claim
## about real vessels. Entries are LargeShips rows
##   [centre Vector3, yaw, length m, beam m, height m, seed, "fleet:<model>", info]
## with info {"hull", "funnel"} colours.
const FLEETS := {
	"soder_malarstrand": [
		{"model": "archipelago", "length": 46.0, "beam": 8.0, "height": 9.5, "hull": "#f0eee8", "funnel": "#24415f"},
		{"model": "tall_ship", "length": 31.0, "beam": 7.6, "height": 18.0, "hull": "#2a2420", "funnel": ""},
		{"model": "houseboat", "length": 21.0, "beam": 6.0, "height": 5.4, "hull": "#7d3a2c", "funnel": ""},
		{"model": "steam_yacht", "length": 38.0, "beam": 6.0, "height": 12.5, "hull": "#1d2126", "funnel": "#a8352a"},
		{"model": "restaurant_boat", "length": 26.0, "beam": 6.2, "height": 6.0, "hull": "#2c3e36", "funnel": ""},
		{"model": "passenger", "length": 46.0, "beam": 8.0, "height": 14.0, "hull": "#8a2f2a", "funnel": "#e4e0d2"},
		{"model": "houseboat", "length": 18.0, "beam": 5.4, "height": 5.0, "hull": "#3d5a64", "funnel": ""},
		{"model": "archipelago", "length": 30.0, "beam": 6.4, "height": 8.0, "hull": "#f0eee8", "funnel": "#b53a2c"},
	],
}
## Fleet vessels dressed per row, and the open water kept between a hull
## and the quay edge (m).
const ROW_MAX := 8
const QUAY_OFFSET_M := 2.6
## How far before the point nearest the eye the walk starts (m).
const LEAD_M := 250.0
## Hulls this near the eye (m) carry mooring lines, fenders and a gangway.
const MOOR_NEAR_M := 350.0
## The quay top over the water (m) the lines are made fast to.
const QUAY_TOP_M := 1.2
## How far from the street line the water's edge is looked for (m).
const SEARCH_M := 90.0
## Gap between neighbours (m): the least, and the most added by a hash.
const GAP_MIN_M := 5.0
const GAP_SPREAD_M := 70.0
const FIRST_M := 14.0
## Riddarfjärden's quays (the Riddarholmen and Stadshuset banks) berth a
## Mälaren steamer or hotel ship in place of a cruise liner.
const HOTEL_ANCHOR := Vector2(59.3250, 18.0560)
const HOTEL_RADIUS_M := 900.0
const HOTEL_LENGTH_M := 62.0
const HOTEL_BEAM_SHARE := 0.15
const HOTEL_HEIGHT_M := 17.0
const HOTEL_LIVERIES := [
	{"hull": "#efece4", "funnel": "#9c2f27"},
	{"hull": "#1d2126", "funnel": "#a8352a"},
	{"hull": "#e9e6dc", "funnel": "#24415f"},
]

## True when `at` (world XZ) lies on Riddarfjärden's shore.
static func hotel_water(data: LocationData, at: Vector2, m: float) -> bool:
	var anchor := WorldScale.xz_from_latlon(HOTEL_ANCHOR.x, HOTEL_ANCHOR.y, data.latitude, data.longitude) * m
	return at.distance_to(anchor) <= HOTEL_RADIUS_M * m

## A Riddarfjärden hotel ship as a LargeShips row.
static func hotel_ship(centre: Vector3, yaw: float, length: float, beam: float, seed_value: float) -> Array:
	var livery: Dictionary = HOTEL_LIVERIES[int(seed_value * 10.0) % HOTEL_LIVERIES.size()]
	return [centre, yaw, length, beam, HOTEL_HEIGHT_M, seed_value, "fleet:passenger", livery.duplicate()]

## The fleet vessels of `data`'s named rows: along each row's street line the
## water's edge is found on the side the water lies and the next vessel of the
## fleet berthed there (the street is where the row is known, the quay edge
## comes from the ground).
static func plan(data: LocationData, ground: GroundTruth, taken: Dictionary, m: float,
		mask: VegetationMask = null) -> Array:
	var out: Array = []
	var rows: Array = QuayMoorings.quay_rows(data, m).filter(func(r: Dictionary) -> bool: return FLEETS.has(r["id"]))
	if rows.is_empty():
		return out
	var eye := View360.spawn_xz(data)
	var stairs := QuayMoorings._stairs(data)
	var bridge_list := QuayMoorings.bridges(data, m)
	for row: Dictionary in rows:
		var pts: PackedVector2Array = row["pts"]
		var fleet: Array = FLEETS[row["id"]]
		var total := MarinaBuilder._length(pts)
		# The walk starts a little before the point nearest the eye, so the fleet
		# fills the quay in view first.
		var t := maxf(FIRST_M, _arc_at(pts, eye) / m - LEAD_M) * m
		var placed := 0
		var cursor: Array = [0, 0.0]
		while t < total - FIRST_M * m and placed < ROW_MAX:
			var probe := MarinaBuilder._at(pts, t, cursor)
			if (probe[0] as Vector2).distance_to(eye) > float(row["reach_m"]) * m:
				t += 12.0 * m
				continue
			var spec: Dictionary = fleet[placed % fleet.size()]
			var h := MarinaBuilder._hash((probe[0] as Vector2).x, (probe[0] as Vector2).y, 71.0)
			var len_m := float(spec["length"]) * (0.9 + 0.2 * h)
			var beam_m := float(spec["beam"]) * (0.95 + 0.1 * h)
			var sample := MarinaBuilder._at(pts, t + len_m * 0.5 * m, cursor)
			var dir: Vector2 = sample[1]
			var berth := _berth(ground, mask, stairs, bridge_list, taken, eye, sample[0], dir, len_m, beam_m, m)
			if berth.is_empty():
				t += 10.0 * m
				continue
			var c: Vector2 = berth["centre"]
			var flip := MarinaBuilder._hash(c.x, c.y, 83.0) < 0.5
			out.append([Vector3(c.x, ground.water_level_at(c.x, c.y), c.y), atan2(-dir.y, dir.x) + (PI if flip else 0.0),
				len_m, beam_m, float(spec["height"]), h, "fleet:" + str(spec["model"]),
				_info(spec, berth, flip, c, eye, m)])
			placed += 1
			var gap := GAP_MIN_M + GAP_SPREAD_M * MarinaBuilder._hash(c.x, c.y, 97.0) \
				* MarinaBuilder._hash(c.y, c.x, 101.0)
			t += (len_m + gap) * m
	return out

## Arc length along `pts` of the point nearest `q`.
static func _arc_at(pts: PackedVector2Array, q: Vector2) -> float:
	var best := INF
	var at := 0.0
	var run := 0.0
	for i in pts.size() - 1:
		var c := Geometry2D.get_closest_point_to_segment(q, pts[i], pts[i + 1])
		if c.distance_to(q) < best:
			best = c.distance_to(q)
			at = run + pts[i].distance_to(c)
		run += pts[i].distance_to(pts[i + 1])
	return at

## The colours of fleet vessel `spec`, and within MOOR_NEAR_M of the eye the
## side its quay lies on in the hull's own frame (-1 or +1 of local z, which
## flips with a hull turned round) and how far off the centre it is, for the
## mooring lines and fenders (ShipMooring).
static func _info(spec: Dictionary, berth: Dictionary, flip: bool, c: Vector2, eye: Vector2, m: float) -> Dictionary:
	var info := {"hull": str(spec["hull"]), "funnel": str(spec["funnel"])}
	if c.distance_to(eye) <= MOOR_NEAR_M * m:
		info["quay_sign"] = -float(berth["side"]) * (-1.0 if flip else 1.0)
		info["quay_gap"] = float(berth["quay_gap"])
	return info

## The berth of a `len_m` x `beam_m` hull alongside the water's edge found
## from the street point `at` heading `dir` (world XZ), claimed in `taken`;
## {} when no water lies within SEARCH_M, or a stair, a bridge, the eye, land
## or another hull is in the way. {"centre"} is the hull's middle.
static func _berth(ground: GroundTruth, mask: VegetationMask, stairs: Array, bridge_list: Dictionary,
		taken: Dictionary, eye: Vector2, at: Vector2, dir: Vector2, len_m: float, beam_m: float,
		m: float) -> Dictionary:
	var length := len_m * m
	var beam := beam_m * m
	var normal := Vector2(-dir.y, dir.x)
	var shore := Vector2.INF
	var side := 0.0
	var d := 0.0
	while d <= SEARCH_M and shore == Vector2.INF:
		for sign_n in [-1.0, 1.0]:
			var p: Vector2 = at + normal * sign_n * d * m
			if shore == Vector2.INF and ground.is_inside(p.x, p.y) and ground.water_at(p.x, p.y) >= MarinaBuilder.MIN_DEPTH_M:
				shore = p
				side = sign_n
		d += 1.5
	if shore == Vector2.INF:
		return {}
	var c := shore + normal * side * (beam * 0.5 + QUAY_OFFSET_M * m)
	var stern := c - dir * length * 0.5
	var bow := c + dir * length * 0.5
	if QuayMoorings._near_stairs(stairs, c, dir, length, beam, m) \
			or QuayMoorings.near_bridge(bridge_list, stern, bow, beam * 0.5 + 3.0 * m) \
			or QuayMoorings._near_eye(c, dir, len_m, beam_m, eye, m):
		return {}
	for along in [-0.5, 0.0, 0.5]:
		for across in [-0.5, 0.5]:
			if not QuayMoorings._wet(ground, c + dir * length * along + normal * (beam + 2.0 * m) * across, mask):
				return {}
	if not MarinaBuilder._claim(taken, stern, dir, len_m, beam_m, m):
		return {}
	return {"centre": c, "side": side, "quay_gap": beam_m * 0.5 + QUAY_OFFSET_M}

## The vessel of `model` (a PassengerVesselModel variant, or one of
## MalarVesselModels; "passenger" is the classic coastal steamer) at true
## size, +X bow, in `berth`'s colours, with mooring lines where it knows its quay.
static func vessel(model: String, length: float, beam: float, h: float, berth: Dictionary,
		detail: bool, maps: bool) -> LandmarkMesh:
	var lm := LandmarkMesh.new()
	var p := {"variant": "classic" if model == "passenger" else model, "length": length, "beam": beam,
		"height": h, "hull": VesselMaterials.paint(str(berth.get("hull", "#2d3b4a")), maps, 0.42, 0.05),
		"detail": detail, "maps": maps, "ultra": detail and MaterialLibrary.hi_res}
	if str(berth.get("funnel", "")) != "":
		p["funnel"] = str(berth["funnel"])
	if model in MalarVesselModels.MODELS:
		MalarVesselModels.build(lm, p, model)
	else:
		PassengerVesselModel.build(lm, p)
	if detail and berth.has("quay_sign"):
		var quay := {"quay_z": float(berth["quay_sign"]) * float(berth["quay_gap"]), "quay_top": QUAY_TOP_M,
			"along": Vector2(-length, length)}
		ShipMooring.add(lm, MalarVesselModels.spec(model, length, beam, h, detail), quay, true, maps)
	return lm
