class_name LandmarkBrSuspensionLong
extends RefCounted

## The four great suspension bridges of the bridges batch in true metres,
## along +X with y = 0 at the water (LocationData `base: water`), on the
## shared LandmarkBrKit parts: towers on their caissons, round main
## cables over cast saddles down to the anchorage blocks, cable bands
## with their hanger ropes and the stiffened deck (RoadBuilder leaves the
## OSM deck out of the span, so this deck is the road).

## Akashi Kaikyo Bridge: the longest main span (1991 m) between two
## 282.8 m steel towers on 80 m caissons, 960 m side spans, the 14 m
## deep, 35.5 m wide stiffening truss 66 m over the strait with its
## vertical stabiliser under the centre line, and two 1.12 m cables
## 35.5 m apart, a pair of hanger ropes every 14.2 m.
const AK_MAIN := 1991.0
const AK_SIDE := 960.0
const AK_TOWER_M := 282.8
const AK_DECK_M := 66.0
const AK_Z := 17.75
const AK_HALF_W := 17.75
const AK_PANEL := 14.2
const AK_CAISSON_M := 8.0

static func akashi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#C9CDCE")
	var tx := AK_MAIN * 0.5
	var end := tx + AK_SIDE
	for s in [-1.0, 1.0]:
		var x: float = s * tx
		# Caisson (80 m across) with its fender ring, then the tower.
		lm.frustum("Concrete", Vector3(x, 0, 0), 40.0, 39.0, AK_CAISSON_M - 1.0, 40)
		lm.frustum("Concrete", Vector3(x, AK_CAISSON_M - 1.0, 0), 39.0, 37.0, 1.0, 40)
		for z in [-AK_Z, AK_Z]:
			lm.box("Concrete", Vector3(x, AK_CAISSON_M + 1.5, z), Vector3(16.0, 3.0, 14.0))
		LandmarkBrKit.portal_tower(lm, "Steel", x, AK_CAISSON_M, AK_TOWER_M - 2.4, AK_Z, Vector2(4.4, 3.0),
			Vector2(3.0, 2.2), [92.0, 138.0, 184.0, 230.0, 276.0], 5.0, true, 2.2)
		# Cruciform legs: a second, narrower box crossing the first gives the
		# re-entrant corners of the real cross-shaped section.
		for sz in [-1.0, 1.0]:
			LandmarkBrKit.tapered_box(lm, "Steel", Vector3(x, AK_CAISSON_M, sz * AK_Z), 5.6, 1.9, 3.8, 1.4,
				AK_TOWER_M - 2.4 - AK_CAISSON_M)
			LandmarkBrKit.saddle(lm, "Steel", Vector3(x, AK_TOWER_M - 2.4, sz * AK_Z), 1.12 * 0.75)
			# Elevator / stair shaft housing and aviation light on the leg top.
			lm.frustum("Steel", Vector3(x - s * 3.6, AK_TOWER_M - 2.4, sz * AK_Z), 0.5, 0.4, 2.4, 8)
		# Deck-level portal: the truss rests on the tower's lowest strut.
		lm.box("Steel", Vector3(x, AK_DECK_M - 16.0, 0), Vector3(6.0, 4.0, AK_Z * 2.0))
		LandmarkBrKit.anchorage(lm, "Concrete", s * end, s, AK_DECK_M + 14.0, 42.0, 80.0)
	LandmarkBrKit.deck_girder(lm, -end, end, AK_DECK_M, AK_HALF_W, 14.0, AK_PANEL)
	# Vertical stabiliser: a plate under the centre line damping flutter.
	lm.box("Steel", Vector3(0, AK_DECK_M - 15.5, 0), Vector3(end * 2.0, 3.0, 0.3), Basis(), 0.0)
	LandmarkBrKit.suspension(lm, "Steel", {"tx0": -tx, "tx1": tx, "e0": -end, "e1": end,
		"top": AK_TOWER_M - 1.5, "low": AK_DECK_M + 8.0, "end0": AK_DECK_M + 6.0,
		"end1": AK_DECK_M + 6.0, "sag0": 60.0, "sag1": 60.0, "z": AK_Z, "dz": AK_HALF_W - 0.6,
		"deck_y": AK_DECK_M, "w": 1.12, "step": AK_PANEL, "hw": 0.14, "round": true, "pair": 0.6,
		"side": true})
	lm.commit(model)

## Tsing Ma Bridge: 1377 m main span between two 206 m reinforced-
## concrete towers (portal legs joined by four deep cross beams), the
## 355.5 m Ma Wan side span on three piers (no hangers) and the 300 m
## Tsing Yi one hung from the cables, the 41 m wide, 7.6 m deep double-
## deck truss (six-lane road over two rail tracks and two sheltered
## carriageways) with its stainless streamlined edge fairings, 62 m over
## the water, and two 1.1 m cables.
const TM_MAIN := 1377.0
const TM_TOWER_M := 206.0
const TM_DECK_M := 70.0
const TM_Z := 18.0
const TM_HALF_W := 18.0
const TM_PANEL := 18.0

static func tsing_ma(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#D5D8D8", "#CFCCC3")
	var tx := TM_MAIN * 0.5
	var x0 := -tx - 355.5
	var x1 := tx + 300.0
	for s in [-1.0, 1.0]:
		var x: float = s * tx
		lm.box("Concrete", Vector3(x, 3.0, 0), Vector3(30.0, 6.0, 52.0))
		LandmarkBrKit.portal_tower(lm, "Concrete", x, 6.0, TM_TOWER_M - 2.2, TM_Z, Vector2(4.6, 2.8),
			Vector2(3.2, 2.2), [TM_DECK_M - 12.0, 136.0, 170.0, 200.0], 7.0)
		for sz in [-1.0, 1.0]:
			# Vertical recess down each leg face and the saddle housing.
			LandmarkBrKit.tapered_box(lm, "Concrete", Vector3(x, 6.0, sz * TM_Z), 5.0, 1.6, 3.6, 1.2,
				TM_TOWER_M - 8.2)
			LandmarkBrKit.saddle(lm, "Steel", Vector3(x, TM_TOWER_M - 2.2, sz * TM_Z), 0.8)
		# Haunches under each cross beam.
		for by in [136.0, 170.0, 200.0]:
			for sz in [-1.0, 1.0]:
				var bz: float = sz * (TM_Z - 5.0)
				lm.beam("Concrete", Vector3(x, by - 7.0, bz), Vector3(x, by - 3.5, bz - sz * 4.0), 4.0, 2.4)
	_fairing_deck(lm, x0, x1, TM_DECK_M, TM_HALF_W, 7.6, TM_PANEL)
	# Ma Wan side span piers.
	for k in 3:
		var px := lerpf(x0, -tx, float(k + 1) / 4.0)
		for sz in [-1.0, 1.0]:
			LandmarkBrKit.tapered_box(lm, "Concrete", Vector3(px, 0, sz * 12.0), 4.0, 3.0, 2.6, 2.2, TM_DECK_M - 8.0)
		lm.box("Concrete", Vector3(px, TM_DECK_M - 9.0, 0), Vector3(6.0, 3.0, 30.0))
	LandmarkBrKit.suspension(lm, "Steel", {"tx0": -tx, "tx1": tx, "e0": x0, "e1": x1,
		"top": TM_TOWER_M - 1.0, "low": TM_DECK_M + 4.0, "end0": TM_DECK_M + 6.0,
		"end1": TM_DECK_M + 6.0, "sag0": 18.0, "sag1": 14.0, "z": TM_Z, "dz": TM_HALF_W - 0.6,
		"deck_y": TM_DECK_M, "w": 1.1, "step": TM_PANEL, "hw": 0.12, "round": true, "pair": 0.5,
		"side1": true})
	LandmarkBrKit.anchorage(lm, "Concrete", x0, -1.0, TM_DECK_M + 10.0, 24.0, 44.0)
	LandmarkBrKit.anchorage(lm, "Concrete", x1, 1.0, TM_DECK_M + 10.0, 24.0, 44.0)
	lm.commit(model)

## Tsing Ma's deck: the double-deck truss with the lower deck slab inside
## it and the angled edge fairings that streamline the section.
static func _fairing_deck(lm: LandmarkMesh, x0: float, x1: float, y: float, half_w: float, depth: float,
		cell: float) -> void:
	LandmarkBrKit.deck_girder(lm, x0, x1, y, half_w, depth, cell)
	var mid := (x0 + x1) * 0.5
	lm.box("Deck", Vector3(mid, y - depth + 1.2, 0), Vector3(x1 - x0, 0.4, half_w * 2.0 - 3.0))
	for sz in [-1.0, 1.0]:
		var e: float = sz * half_w
		LandmarkBrKit.extrude_yz(lm, "Steel", PackedVector2Array([Vector2(e, y - 0.4),
			Vector2(e + sz * 2.6, y - depth * 0.45), Vector2(e, y - depth + 0.2)]), x0, x1)
		# Rails on the lower deck.
		for rz in [0.75, 2.25]:
			lm.box("Steel", Vector3(mid, y - depth + 1.5, sz * (rz + 3.0)), Vector3(x1 - x0, 0.2, 0.12), Basis(), 0.0)

## Verrazzano-Narrows Bridge: 1298 m main span and 370 m side spans
## between the two 211.5 m steel towers, whose legs are tied only by
## arched struts near the top and below the lower deck (no cross
## bracing), four 0.91 m cables (a pair each side), the double-deck
## truss carrying thirteen lanes 69.5 m over the Narrows.
const VZ_MAIN := 1298.0
const VZ_SIDE := 370.0
const VZ_TOWER_M := 211.5
const VZ_DECK_M := 77.0
const VZ_Z := 18.2
const VZ_HALF_W := 15.5
const VZ_DEPTH := 7.5

static func verrazzano(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#A4ABAE", "#B1ABA0")
	var tx := VZ_MAIN * 0.5
	var end := tx + VZ_SIDE
	for s in [-1.0, 1.0]:
		var x: float = s * tx
		for z in [-VZ_Z, VZ_Z]:
			lm.box("Concrete", Vector3(x, 6.0, z), Vector3(20.0, 12.0, 16.0))
			lm.box("Concrete", Vector3(x, 12.4, z), Vector3(17.0, 0.8, 13.0))
		lm.box("Concrete", Vector3(x, 4.0, 0), Vector3(16.0, 8.0, VZ_Z * 2.0))
		var top := VZ_TOWER_M - 2.0
		for sz in [-1.0, 1.0]:
			# Cellular legs: the main box and the shallower stiffened faces.
			LandmarkBrKit.tapered_box(lm, "Steel", Vector3(x, 12.8, sz * VZ_Z), 5.0, 3.0, 3.4, 2.4, top - 12.8)
			LandmarkBrKit.tapered_box(lm, "Steel", Vector3(x, 12.8, sz * VZ_Z), 3.6, 3.6, 2.4, 2.9, top - 12.8)
			for cz in [-0.8, 0.8]:
				LandmarkBrKit.saddle(lm, "Steel", Vector3(x, top, sz * VZ_Z + cz), 0.65)
		_arched_strut(lm, x, top - 13.0, top, VZ_Z - 2.6, 3.8, 0.6)
		_arched_strut(lm, x, VZ_DECK_M - VZ_DEPTH - 13.0, VZ_DECK_M - VZ_DEPTH - 2.0, VZ_Z - 3.0, 4.0, 0.5)
		LandmarkBrKit.anchorage(lm, "Concrete", s * end, s, VZ_DECK_M + 12.0, 30.0, 70.0)
	LandmarkBrKit.deck_girder(lm, -end, end, VZ_DECK_M, VZ_HALF_W, VZ_DEPTH, 15.4)
	# Lower deck: its road slab inside the truss, and its own barriers.
	lm.box("Deck", Vector3(0, VZ_DECK_M - VZ_DEPTH + 1.0, 0), Vector3(end * 2.0, 0.5, VZ_HALF_W * 2.0 - 2.0))
	for z in [-VZ_HALF_W + 1.2, VZ_HALF_W - 1.2]:
		lm.box("Concrete", Vector3(0, VZ_DECK_M - VZ_DEPTH + 1.7, z), Vector3(end * 2.0, 0.9, 0.35), Basis(), 0.0)
	for cz in [-0.8, 0.8]:
		LandmarkBrKit.suspension(lm, "Steel", {"tx0": -tx, "tx1": tx, "e0": -end, "e1": end,
			"top": VZ_TOWER_M - 1.5, "low": VZ_DECK_M + 10.0, "end0": VZ_DECK_M + 4.0,
			"end1": VZ_DECK_M + 4.0, "sag0": 26.0, "sag1": 26.0, "z": VZ_Z + cz,
			"dz": VZ_HALF_W - 0.6 + cz * 0.5, "deck_y": VZ_DECK_M, "w": 0.91, "step": 15.4, "hw": 0.12,
			"round": true, "side": true})
	lm.commit(model)

## A tower strut across the legs at x from y0 to y1, spanning ±z, t
## thick (along X): a deep girder whose soffit is a shallow arch rising
## `rise_k` of its height at mid-span.
static func _arched_strut(lm: LandmarkMesh, x: float, y0: float, y1: float, z: float, t: float,
		rise_k: float) -> void:
	var poly := PackedVector2Array([Vector2(-z, y1), Vector2(-z, y0)])
	for k in range(1, 12):
		var u := -1.0 + 2.0 * float(k) / 12.0
		poly.append(Vector2(u * z, y0 + (y1 - y0) * rise_k * sqrt(1.0 - u * u)))
	poly.append(Vector2(z, y0))
	poly.append(Vector2(z, y1))
	LandmarkBrKit.extrude_yz(lm, "Steel", poly, x - t * 0.5, x + t * 0.5)
	lm.box("Steel", Vector3(x, y1 - 0.4, 0), Vector3(t + 0.6, 0.8, z * 2.0))

## Bosphorus Bridge (15 July Martyrs Bridge): 1074 m main span between
## 165 m steel towers (three cross beams), the 33.4 m wide, 3 m deep
## aerofoil box deck 64 m over the strait on the inclined hangers that
## set it apart; the side spans (231 m European, 255 m Asian) are not
## hung: their roads run on approach piers under the backstay cables.
const BO_MAIN := 1074.0
const BO_TOWER_M := 165.0
const BO_DECK_M := 66.0
const BO_Z := 16.5
const BO_HALF_W := 16.7

static func bosphorus(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#C4C8CA")
	var tx := BO_MAIN * 0.5
	var x0 := -tx - 231.0
	var x1 := tx + 255.0
	for s in [-1.0, 1.0]:
		var x: float = s * tx
		lm.box("Concrete", Vector3(x, 4.0, 0), Vector3(18.0, 8.0, BO_Z * 2.0 + 12.0))
		LandmarkBrKit.portal_tower(lm, "Steel", x, 8.0, BO_TOWER_M - 1.6, BO_Z, Vector2(3.6, 2.6),
			Vector2(2.4, 1.9), [BO_DECK_M - 6.0, 122.0, 160.0], 4.0)
		for sz in [-1.0, 1.0]:
			LandmarkBrKit.saddle(lm, "Steel", Vector3(x, BO_TOWER_M - 1.6, sz * BO_Z), 0.6)
			# Stiffening ribs down the legs' outer faces.
			LandmarkBrKit.tapered_box(lm, "Steel", Vector3(x, 8.0, sz * BO_Z), 2.6, 3.0, 1.7, 2.2, BO_TOWER_M - 9.6)
	# Aerofoil box: flat top, sloping webs to a narrow soffit.
	var prof := PackedVector2Array([Vector2(-BO_HALF_W, BO_DECK_M - 0.4), Vector2(-BO_HALF_W + 1.0, BO_DECK_M - 1.6),
		Vector2(-11.0, BO_DECK_M - 3.0), Vector2(11.0, BO_DECK_M - 3.0), Vector2(BO_HALF_W - 1.0, BO_DECK_M - 1.6),
		Vector2(BO_HALF_W, BO_DECK_M - 0.4)])
	LandmarkBrKit.extrude_yz(lm, "Steel", prof, x0, x1)
	lm.box("Deck", Vector3((x0 + x1) * 0.5, BO_DECK_M - 0.2, 0), Vector3(x1 - x0, 0.4, BO_HALF_W * 2.0 - 3.0))
	for z in [-0.3, 0.3, -BO_HALF_W + 2.0, BO_HALF_W - 2.0]:
		lm.box("Concrete", Vector3((x0 + x1) * 0.5, BO_DECK_M + 0.45, z), Vector3(x1 - x0, 0.9, 0.35), Basis(), 0.0)
	for z in [-BO_HALF_W + 0.2, BO_HALF_W - 0.2]:
		LandmarkBrKit.railing(lm, "Steel", Vector3(x0, BO_DECK_M, z), Vector3(x1, BO_DECK_M, z), 1.2, 4.0)
	# Approach piers under the unhung side spans.
	for side in [[x0, -tx], [tx, x1]]:
		var a: float = side[0]
		var b: float = side[1]
		var n := int(round((b - a) / 60.0))
		for k in range(1, n):
			var px := lerpf(a, b, float(k) / n)
			for sz in [-1.0, 1.0]:
				LandmarkBrKit.tapered_box(lm, "Concrete", Vector3(px, 0, sz * 8.0), 2.6, 2.6, 1.8, 1.8, BO_DECK_M - 3.0)
			lm.box("Concrete", Vector3(px, BO_DECK_M - 4.0, 0), Vector3(4.0, 2.0, 22.0))
	LandmarkBrKit.suspension(lm, "Steel", {"tx0": -tx, "tx1": tx, "e0": x0, "e1": x1,
		"top": BO_TOWER_M - 1.0, "low": BO_DECK_M + 2.0, "end0": BO_DECK_M + 3.0,
		"end1": BO_DECK_M + 3.0, "sag0": 14.0, "sag1": 16.0, "z": BO_Z, "dz": BO_HALF_W - 0.6,
		"deck_y": BO_DECK_M, "w": 0.6, "step": 18.0, "hw": 0.15, "vee": true, "round": true})
	for ex in [x0 - 20.0, x1 + 20.0]:
		var dir := 1.0 if ex > 0.0 else -1.0
		LandmarkBrKit.anchorage(lm, "Concrete", ex - dir * 20.0, dir, BO_DECK_M + 10.0, 24.0, 40.0)
	lm.commit(model)
