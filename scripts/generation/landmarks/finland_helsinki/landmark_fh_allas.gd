extends RefCounted

## Allas Sea Pool (Katajanokanlaituri, 2016). The registry yaw (90) turns the
## front onto the water: model +Z is west (the harbour), -Z is east (the
## quay and the main building), +X is south. Origin at the middle pool.
##
## From the Commons photos in visual-plan/refs/landmarks/allas_sea_pool/:
## - a floating deck of grey-brown timber on black mooring piles, with
##   three pools sunk into it (a large heated pool, a smaller one and a
##   plunge pool) and a stepped timber amphitheatre rising toward the quay;
## - three black timber sauna cabins with black standing-seam gable roofs and
##   stovepipes in a row on the deck's south end;
## - the main building on the quay: amber vertical-slat timber cladding in two
##   storeys, bands of dark glazing, a roof terrace behind a glass
##   balustrade, a stair running up the south side to the terrace and a
##   cluster of black stovepipe chimneys;
## - steel handrails around the whole deck.
##
## Measured: the three pools, the three saunas and the main building's
## outline come from OSM ways 443717278-280, 1226140611-13 and 443717282,
## put into the model frame about 60.16696, 24.95722 (+/- 0.5 m). Estimated
## from photos: storey heights, the terrace levels, deck thickness, the slat
## pitch and the stair. The deck's outer edge is traced from the photos.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "allas_sea_pool", "name": "Allas Sea Pool", "lat": 60.16696, "lon": 24.95722,
	"radius_m": 2000.0, "wiki_title": "Allas Sea Pool", "height_m": 12.0, "clear_m": 105.0,
	"yaw_deg": 90.0, "base": "sea", "kind": "Sea pool", "aliases": ["allas sea pool", "allas seapool", "allas merikylpyla"]}

## Main building outline (OSM way 443717282) in the model frame.
const BUILDING := [Vector2(-45.5, -46.8), Vector2(-53.2, -35.7), Vector2(-52.2, -31.5), Vector2(0.2, -44.1),
	Vector2(3.1, -32.0), Vector2(18.4, -35.7), Vector2(15.5, -47.7), Vector2(19.9, -48.7), Vector2(16.7, -61.8)]
## Pools as [x0, x1, z0, z1] (OSM ways 443717278, 279, 280).
const POOLS := [[16.5, 32.0, -19.5, 5.2], [-6.3, 11.2, -4.8, 6.6], [-27.2, -18.5, -3.8, 8.0]]
## Sauna cabins as [x centre, z0, z1] (OSM 1226140611-13), 3.7 m wide.
const SAUNAS := [[-29.1, -3.5, 8.2], [-35.6, -3.1, 8.6], [-41.9, -2.9, 8.7]]
const DECK_X0 := -47.0
const DECK_X1 := 36.0
const DECK_Z0 := -31.0
const DECK_Z1 := 10.5
const DECK_Y := 0.7
const EAVE := 5.6
const TERRACE := 8.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Slats", LandmarkMaterials.pbr("wood", "#C9923F", 2.0))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#8C7557", 2.0))
	lm.use("Black", LandmarkMaterials.pbr("wood", "#1F2123", 2.0))
	lm.use("Roof", LandmarkMaterials.paint("#26292B", 0.5, 0.5))
	lm.use("Water", LandmarkMaterials.pool_water("#2F8FA8"))
	lm.use("Glass", LandmarkMaterials.glass("#2B3A40"))
	lm.use("Steel", LandmarkMaterials.paint("#8B9094", 0.45, 0.6))
	_deck(lm)
	_main_building(lm)
	_saunas(lm)
	_piles_and_rails(lm)
	lm.commit(model)

## Deck planks everywhere but over the pools, the pools' water below it, the
## coping and the amphitheatre steps.
static func _deck(lm: LandmarkMesh) -> void:
	var xs: Array[float] = [DECK_X0, DECK_X1]
	var zs: Array[float] = [DECK_Z0, DECK_Z1]
	for p: Array in POOLS:
		xs.append_array([p[0], p[1]])
		zs.append_array([p[2], p[3]])
	xs.sort()
	zs.sort()
	for i in xs.size() - 1:
		for j in zs.size() - 1:
			var cx := (xs[i] + xs[i + 1]) * 0.5
			var cz := (zs[j] + zs[j + 1]) * 0.5
			if xs[i + 1] - xs[i] < 0.05 or zs[j + 1] - zs[j] < 0.05:
				continue
			var in_pool := false
			for p: Array in POOLS:
				if cx > p[0] and cx < p[1] and cz > p[2] and cz < p[3]:
					in_pool = true
			if not in_pool:
				U.blk(lm, "Deck", cx, -0.4, cz, xs[i + 1] - xs[i], DECK_Y + 0.4, zs[j + 1] - zs[j])
	for p: Array in POOLS:
		U.blk(lm, "Water", (p[0] + p[1]) * 0.5, 0.15, (p[2] + p[3]) * 0.5, p[1] - p[0] - 0.2, 0.05, p[3] - p[2] - 0.2)
		U.blk(lm, "Steel", (p[0] + p[1]) * 0.5, DECK_Y, p[2] - 0.1, p[1] - p[0] + 0.4, 0.08, 0.2)
		U.blk(lm, "Steel", (p[0] + p[1]) * 0.5, DECK_Y, p[3] + 0.1, p[1] - p[0] + 0.4, 0.08, 0.2)
	# Amphitheatre: wide timber steps rising from the pools to the quay wall.
	U.steps(lm, "Deck", Vector3(14.0, 0, DECK_Z0), Vector3.BACK, 34.0, 1.1, 0.3, 8)
	U.steps(lm, "Deck", Vector3(-8.0, 0, DECK_Z0), Vector3.BACK, 14.0, 1.1, 0.3, 5)

## The quay building: slatted two-storey block, glazing bands, a roof
## terrace with glass balustrade, the stair and the chimneys.
static func _main_building(lm: LandmarkMesh) -> void:
	var poly := PackedVector2Array(BUILDING)
	lm.poly_prism("Slats", poly, -0.5, EAVE)
	lm.poly_prism("Deck", poly, EAVE, EAVE + 0.15)
	# Upper volume on the northern (-X) half, with its own terrace edge.
	var up := PackedVector2Array([Vector2(-50.0, -33.5), Vector2(-49.0, -57.5), Vector2(-30.0, -57.0), Vector2(-29.5, -37.5)])
	lm.poly_prism("Slats", up, EAVE, TERRACE)
	lm.poly_prism("Deck", up, TERRACE, TERRACE + 0.15)
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var ln := a.distance_to(b)
		if ln < 4.0:
			continue
		var out := P.edge_out(poly, i)
		var a3 := Vector3(a.x, 0, a.y)
		var b3 := Vector3(b.x, 0, b.y)
		P.strips(lm, "Slats", a3, b3, out, 0.0, EAVE, int(ln / 0.55), 0.14, 0.12)
		# Dark glazing bands, ground and upper floor.
		U.window_grid(lm, "Glass", a3 + (b3 - a3) * 0.08, a3 + (b3 - a3) * 0.92, out, 0.7, 2, 2.6,
			maxi(int(ln / 4.5), 1), 2.4, 1.6, 0.18)
	for i in up.size():
		var a := up[i]
		var b := up[(i + 1) % up.size()]
		var ln := a.distance_to(b)
		var out := P.edge_out(up, i)
		var a3 := Vector3(a.x, 0, a.y)
		var b3 := Vector3(b.x, 0, b.y)
		P.strips(lm, "Slats", a3, b3, out, EAVE, TERRACE - EAVE, int(ln / 0.55), 0.14, 0.12)
		U.window_grid(lm, "Glass", a3 + (b3 - a3) * 0.1, a3 + (b3 - a3) * 0.9, out, EAVE + 0.5, 1, 2.6,
			maxi(int(ln / 4.5), 1), 2.4, 1.8, 0.18)
	# Glass balustrade round both terraces.
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		lm.beam("Glass", Vector3(a.x, EAVE + 0.6, a.y), Vector3(b.x, EAVE + 0.6, b.y), 0.05, 1.0, Vector3.UP)
		lm.beam("Steel", Vector3(a.x, EAVE + 1.15, a.y), Vector3(b.x, EAVE + 1.15, b.y), 0.07, 0.07, Vector3.UP)
	# Stair running up the southern end to the terrace.
	U.steps(lm, "Deck", Vector3(-22.0, EAVE, -38.0), Vector3.BACK, 3.0, 0.28, 0.26, 21)
	# Stovepipes in one cluster above the upper volume, and two on the lower roof.
	for k in 6:
		var h := 10.6 + 0.7 * float(k % 3)
		lm.frustum("Steel", Vector3(-45.0 + 1.1 * float(k % 3), TERRACE, -41.0 - 1.1 * float(k / 3)), 0.42, 0.42, h - TERRACE, 12)
	lm.frustum("Steel", Vector3(-5.0, EAVE, -40.0), 0.4, 0.4, 3.2, 12)
	lm.frustum("Steel", Vector3(9.0, EAVE, -42.0), 0.4, 0.4, 3.2, 12)

## Three black timber saunas: gable roofs ridged along Z, a stovepipe each.
static func _saunas(lm: LandmarkMesh) -> void:
	for s: Array in SAUNAS:
		var x: float = s[0]
		var z0: float = s[1]
		var z1: float = s[2]
		var d := z1 - z0
		var cz := (z0 + z1) * 0.5
		U.blk(lm, "Black", x, DECK_Y, cz, 3.7, 2.7, d)
		U.ridge_z(lm, "Roof", "Black", Vector3(x, DECK_Y + 2.7, cz), 3.7, d, 1.1, 0.25)
		lm.frustum("Steel", Vector3(x, DECK_Y + 3.0, cz - d * 0.3), 0.14, 0.14, 1.6, 8)
		U.window_grid(lm, "Glass", Vector3(x - 1.2, 0, z1 + 0.0), Vector3(x + 1.2, 0, z1 + 0.0), Vector3(0, 0, 1), DECK_Y + 0.7, 1, 1.0, 1, 1.0, 1.4, 0.08)
		U.window_grid(lm, "Glass", Vector3(x + 1.85, 0, cz - 2.5), Vector3(x + 1.85, 0, cz + 2.5), Vector3(1, 0, 0), DECK_Y + 0.9, 1, 1.0, 2, 1.0, 1.0, 0.08)

## Black mooring piles round the deck and steel rails on its edge.
static func _piles_and_rails(lm: LandmarkMesh) -> void:
	var corners := [Vector2(DECK_X0, DECK_Z1), Vector2(DECK_X1, DECK_Z1), Vector2(DECK_X1, DECK_Z0)]
	for k in 2:
		var a: Vector2 = corners[k]
		var b: Vector2 = corners[k + 1]
		var n := int(a.distance_to(b) / 9.0)
		for i in n + 1:
			var p := a.lerp(b, float(i) / float(n))
			lm.frustum("Black", Vector3(p.x, -2.0, p.y + (0.5 if k == 0 else 0.0)), 0.34, 0.34, 5.2, 8)
		lm.beam("Steel", Vector3(a.x, DECK_Y + 1.05, a.y), Vector3(b.x, DECK_Y + 1.05, b.y), 0.06, 0.06, Vector3.UP)
		lm.beam("Steel", Vector3(a.x, DECK_Y + 0.55, a.y), Vector3(b.x, DECK_Y + 0.55, b.y), 0.04, 0.04, Vector3.UP)
