class_name LandmarkBrSuspensionMid
extends RefCounted

## Three more suspension bridges of the bridges batch in true metres,
## along +X with y = 0 at the water (LocationData `base: water`), on the
## shared LandmarkBrKit parts: the two orange-and-green steel crossings
## of Lisbon and Vancouver and Budapest's stone-towered Chain Bridge.

## Ponte 25 de Abril, Lisbon: 1013 m main span and two 483.6 m side
## spans between the 190 m International Orange towers (four struts over
## the road, an X-braced portal under it), the 24.5 m wide road deck 70 m
## over the Tagus on its 10.6 m Warren truss with the 1999 railway inside
## it, and on each side the 1966 cable with the second 0.586 m cable added
## over it for the railway; the Lisbon (-X) approach viaduct.
const PA_MAIN := 1013.0
const PA_SIDE := 483.6
const PA_TOWER_M := 190.0
const PA_DECK_M := 76.0
const PA_Z := 17.0
const PA_HALF_W := 12.25

static func ponte_25_abril(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#B8452B", "#BDB8AC")
	var tx := PA_MAIN * 0.5
	var end := tx + PA_SIDE
	var top := PA_TOWER_M - 2.6
	for s in [-1.0, 1.0]:
		var x: float = s * tx
		for z in [-PA_Z, PA_Z]:
			lm.box("Concrete", Vector3(x, 4.0, z), Vector3(18.0, 8.0, 14.0))
			lm.frustum("Concrete", Vector3(x, 0, z), 9.5, 8.5, 1.5, 20)
		LandmarkBrKit.portal_tower(lm, "Steel", x, 8.0, top, PA_Z, Vector2(4.6, 3.6),
			Vector2(3.3, 2.7), [PA_DECK_M - 12.0, 112.0, 136.0, 160.0, 184.0], 5.0, false)
		# X-braced portal between the pier and the deck strut.
		var iz := PA_Z - 4.0
		for d in [-1.0, 1.0]:
			lm.beam("Steel", Vector3(x, 10.0, d * iz), Vector3(x, PA_DECK_M - 14.5, -d * iz), 1.8, 1.4)
		lm.box("Steel", Vector3(x, 36.0, 0), Vector3(3.0, 3.0, iz * 2.0))
		for sz in [-1.0, 1.0]:
			# Plated leg cells with their stiffened outer faces.
			LandmarkBrKit.tapered_box(lm, "Steel", Vector3(x, 8.0, sz * PA_Z), 3.4, 4.2, 2.4, 3.1, top - 8.0)
			LandmarkBrKit.saddle(lm, "Steel", Vector3(x, top, sz * PA_Z), 0.95)
		LandmarkBrKit.anchorage(lm, "Concrete", s * end, s, PA_DECK_M + 12.0, 22.0, 40.0)
		LandmarkBrKit.viaduct(lm, s * (end + 40.0), PA_DECK_M, s * (end + (300.0 if s < 0.0 else 120.0)),
			PA_DECK_M - (26.0 if s < 0.0 else 12.0), PA_HALF_W, 4.0, 52.0)
	LandmarkBrKit.deck_girder(lm, -end, end, PA_DECK_M, PA_HALF_W, 10.6, 26.0)
	# Railway in the truss: track bed and rails on the lower chord level.
	lm.box("Concrete", Vector3(0, PA_DECK_M - 9.6, 0), Vector3(end * 2.0, 0.6, 10.0))
	for rz in [-3.6, -2.1, 2.1, 3.6]:
		lm.box("Steel", Vector3(0, PA_DECK_M - 9.2, rz), Vector3(end * 2.0, 0.2, 0.12), Basis(), 0.0)
	LandmarkBrKit.suspension(lm, "Steel", {"tx0": -tx, "tx1": tx, "e0": -end, "e1": end,
		"top": PA_TOWER_M - 2.0 - 1.6, "low": PA_DECK_M + 8.0, "end0": PA_DECK_M + 6.0,
		"end1": PA_DECK_M + 6.0, "sag0": 34.0, "sag1": 34.0, "z": PA_Z, "dz": PA_HALF_W - 0.6,
		"deck_y": PA_DECK_M, "w": 0.586, "step": 26.0, "hw": 0.12, "round": true, "pair": 0.5,
		"stack": 1.4, "side": true})
	lm.commit(model)

## Lions Gate Bridge, Vancouver: 473 m main span between the 111 m
## steel towers (X-braced over the road), 187 m side spans, the pale-
## green truss deck 61 m over the First Narrows carrying three 3.6 m
## lanes with the footways cantilevered outside the cables, the
## Stanley Park (-X, south) cliff end with Charles Marega's two couchant
## concrete lions (1939), and the 670 m North Shore viaduct on steel
## trestle bents.
const LG_MAIN := 473.0
const LG_SIDE := 187.0
const LG_TOWER_M := 111.0
const LG_DECK_M := 62.0
const LG_Z := 6.4
const LG_HALF_W := 6.4
const LG_NORTH := 670.0

static func lions_gate(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#8DB093", "#B5B0A4")
	var tx := LG_MAIN * 0.5
	var end := tx + LG_SIDE
	var top := LG_TOWER_M - 1.3
	for s in [-1.0, 1.0]:
		var x: float = s * tx
		for z in [-LG_Z, LG_Z]:
			lm.box("Concrete", Vector3(x, 5.0, z), Vector3(10.0, 10.0, 7.0))
			lm.box("Concrete", Vector3(x, 10.4, z), Vector3(8.0, 0.8, 5.6))
		lm.box("Concrete", Vector3(x, 3.0, 0), Vector3(8.0, 6.0, LG_Z * 2.0))
		LandmarkBrKit.portal_tower(lm, "Steel", x, 10.8, top, LG_Z, Vector2(2.6, 1.5),
			Vector2(1.7, 1.2), [LG_DECK_M - 5.0, 76.0, 88.0, 98.0, 106.0], 2.4, true, 1.0)
		for sz in [-1.0, 1.0]:
			LandmarkBrKit.saddle(lm, "Steel", Vector3(x, top, sz * LG_Z), 0.55)
			# Stepped art-deco setbacks on the leg tops.
			LandmarkBrKit.tapered_box(lm, "Steel", Vector3(x, top - 8.0, sz * LG_Z), 2.0, 1.5, 1.6, 1.25, 8.0)
	_lg_deck(lm, -end, end)
	# South: the Stanley Park cliff abutment with the lions at the road.
	var sx := -end - 10.0
	lm.box("Concrete", Vector3(sx, (LG_DECK_M - 0.5) * 0.5, 0), Vector3(20.0, LG_DECK_M - 0.5, 24.0))
	lm.box("Deck", Vector3(sx - 10.0, LG_DECK_M - 0.25, 0), Vector3(40.0, 0.5, LG_HALF_W * 2.0))
	for z in [-11.0, 11.0]:
		lm.box("Concrete", Vector3(sx - 14.0, LG_DECK_M + 1.0, z), Vector3(7.0, 2.0, 3.6))
		lm.box("Concrete", Vector3(sx - 14.0, LG_DECK_M + 2.1, z), Vector3(7.4, 0.3, 4.0))
		LandmarkBrKit.lion(lm, "Concrete", Vector3(sx - 14.0, LG_DECK_M + 2.25, z), Vector3(1, 0, 0), 5.6)
	# North: anchorage and the trestle viaduct falling to the shore.
	LandmarkBrKit.anchorage(lm, "Concrete", end, 1.0, LG_DECK_M + 6.0, 12.0, 24.0)
	_trestle(lm, end + 24.0, LG_DECK_M, end + 24.0 + LG_NORTH, 22.0)
	LandmarkBrKit.suspension(lm, "Steel", {"tx0": -tx, "tx1": tx, "e0": -end, "e1": end,
		"top": LG_TOWER_M - 0.8, "low": LG_DECK_M + 3.0, "end0": LG_DECK_M + 3.0,
		"end1": LG_DECK_M + 3.0, "sag0": 10.0, "sag1": 10.0, "z": LG_Z, "dz": LG_HALF_W - 0.3,
		"deck_y": LG_DECK_M, "w": 0.6, "step": 12.0, "hw": 0.1, "round": true, "pair": 0.4,
		"side": true})
	lm.commit(model)

## Lions Gate deck: the road between the stiffening trusses and the
## footways on brackets outside them.
static func _lg_deck(lm: LandmarkMesh, x0: float, x1: float) -> void:
	LandmarkBrKit.deck_girder(lm, x0, x1, LG_DECK_M, LG_HALF_W, 4.4, 12.0)
	var mid := (x0 + x1) * 0.5
	var n := int((x1 - x0) / 12.0)
	for sz in [-1.0, 1.0]:
		var zc: float = sz * (LG_HALF_W + 1.6)
		lm.box("Concrete", Vector3(mid, LG_DECK_M - 0.6, zc), Vector3(x1 - x0, 0.3, 2.8))
		LandmarkBrKit.railing(lm, "Steel", Vector3(x0, LG_DECK_M - 0.45, sz * (LG_HALF_W + 2.9)),
			Vector3(x1, LG_DECK_M - 0.45, sz * (LG_HALF_W + 2.9)), 1.3, 3.0)
		for k in n + 1:
			var bx := lerpf(x0, x1, float(k) / n)
			lm.beam("Steel", Vector3(bx, LG_DECK_M - 3.4, sz * (LG_HALF_W - 0.6)),
				Vector3(bx, LG_DECK_M - 0.75, sz * (LG_HALF_W + 2.8)), 0.3, 0.3)

## Steel trestle viaduct from (xa, ya) to (xb, yb): plate girders on
## two-column bents every 30 m, X-braced, on concrete footings.
static func _trestle(lm: LandmarkMesh, xa: float, ya: float, xb: float, yb: float) -> void:
	var n := maxi(int(round((xb - xa) / 30.0)), 1)
	for k in n:
		var x0 := lerpf(xa, xb, float(k) / n)
		var x1 := lerpf(xa, xb, float(k + 1) / n)
		var y0 := lerpf(ya, yb, float(k) / n)
		var y1 := lerpf(ya, yb, float(k + 1) / n)
		var r := Basis(Vector3.BACK, atan2(y1 - y0, x1 - x0))
		var c := Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, 0)
		var l := Vector2(x1 - x0, y1 - y0).length()
		lm.box("Deck", c + Vector3(0, -0.25, 0), Vector3(l + 0.1, 0.5, LG_HALF_W * 2.0), r)
		for z in [-4.5, 4.5]:
			lm.box("Steel", c + Vector3(0, -1.6, z), Vector3(l + 0.1, 2.2, 0.5), r)
		for z in [-LG_HALF_W, LG_HALF_W]:
			lm.box("Concrete", c + Vector3(0, 0.45, z), Vector3(l, 0.9, 0.35), r, 0.0)
		var bt := y1 - 2.8
		for z in [-4.5, 4.5]:
			lm.box("Concrete", Vector3(x1, 1.0, z), Vector3(3.0, 2.0, 3.0))
			lm.beam("Steel", Vector3(x1, 2.0, z * 1.1), Vector3(x1, bt, z), 1.0, 0.8)
		lm.box("Steel", Vector3(x1, bt, 0), Vector3(1.2, 1.0, 10.4))
		var mid := (2.0 + bt) * 0.5
		for yy in [[2.0, mid], [mid, bt]]:
			lm.beam("Steel", Vector3(x1, yy[0], -4.5), Vector3(x1, yy[1], 4.5), 0.4, 0.4)
			lm.beam("Steel", Vector3(x1, yy[0], 4.5), Vector3(x1, yy[1], -4.5), 0.4, 0.4)

## Szechenyi Chain Bridge, Budapest: 202 m main span between the two
## classicist limestone towers (48 m: a triumphal arch with the
## carriageway through its great round arch, a footway arch through each
## leg, paired pilasters, entablature and an attic bearing the Hungarian
## arms), 87 m side spans, two wrought-iron eyebar chains a side (one over
## the other) with a hanger every 3.6 m, the 6.5 m carriageway between
## them 14.5 m over the Danube, the footways outside on brackets, the
## cast-iron railings, and the abutments with Marschalko's stone lions
## (1852).
const SZ_MAIN := 202.0
const SZ_SIDE := 87.0
const SZ_DECK_M := 14.5
const SZ_CHAIN_Z := 5.0
const SZ_TOWER_X := 12.0
const SZ_TOWER_Z := 22.0

static func chain_bridge(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#48504A")
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#C9C1AE", 3.0))
	var tx := SZ_MAIN * 0.5
	var end := tx + SZ_SIDE
	for s in [-1.0, 1.0]:
		_sz_tower(lm, s * tx)
		_sz_abutment(lm, s, end)
	LandmarkBrKit.deck_girder(lm, -end, end, SZ_DECK_M, SZ_CHAIN_Z - 0.5, 1.8)
	# Footways outside the chains on cantilever brackets, with railings.
	for sz in [-1.0, 1.0]:
		var fz: float = sz * (SZ_CHAIN_Z + 1.6)
		lm.box("Deck", Vector3(0, SZ_DECK_M - 0.1, fz), Vector3(end * 2.0, 0.3, 2.6))
		lm.box("Steel", Vector3(0, SZ_DECK_M - 0.6, fz), Vector3(end * 2.0, 0.7, 2.4))
		var rz: float = sz * (SZ_CHAIN_Z + 2.85)
		for span in [[-end, -tx - SZ_TOWER_X * 0.5], [-tx + SZ_TOWER_X * 0.5, tx - SZ_TOWER_X * 0.5],
				[tx + SZ_TOWER_X * 0.5, end]]:
			var a: float = span[0]
			var b: float = span[1]
			LandmarkBrKit.railing(lm, "Steel", Vector3(a, SZ_DECK_M, rz), Vector3(b, SZ_DECK_M, rz), 1.1, 1.8)
			LandmarkBrKit.railing(lm, "Steel", Vector3(a, SZ_DECK_M, sz * (SZ_CHAIN_Z - 0.4)),
				Vector3(b, SZ_DECK_M, sz * (SZ_CHAIN_Z - 0.4)), 1.0, 3.6)
			# Lamp standards on the outer railing.
			var nl := int((b - a) / 18.0)
			for k in range(1, nl):
				var lx := lerpf(a, b, float(k) / nl)
				lm.frustum("Steel", Vector3(lx, SZ_DECK_M, rz), 0.18, 0.08, 4.2, 8)
				lm.lathe("Steel", Vector3(lx, SZ_DECK_M + 4.2, rz), PackedVector2Array([Vector2(0.12, 0),
					Vector2(0.3, 0.25), Vector2(0.26, 0.7), Vector2(0.08, 0.9), Vector2(0.0, 1.0)]), 8)
		for k in int(end * 2.0 / 3.6):
			var bx := -end + 3.6 * (float(k) + 0.5)
			lm.beam("Steel", Vector3(bx, SZ_DECK_M - 1.6, sz * (SZ_CHAIN_Z - 0.6)),
				Vector3(bx, SZ_DECK_M - 0.4, sz * (SZ_CHAIN_Z + 2.8)), 0.2, 0.2)
	LandmarkBrKit.suspension(lm, "Steel", {"tx0": -tx, "tx1": tx, "e0": -end, "e1": end,
		"top": 36.0, "low": SZ_DECK_M + 2.4, "end0": SZ_DECK_M + 1.0, "end1": SZ_DECK_M + 1.0,
		"sag0": 4.0, "sag1": 4.0, "z": SZ_CHAIN_Z, "dz": SZ_CHAIN_Z, "deck_y": SZ_DECK_M, "w": 0.9,
		"step": 3.6, "hw": 0.12, "side": true, "stack": 1.5})
	# Eyebar joints: a pin boss at every link on both chains.
	for sz in [-1.0, 1.0]:
		var p := {"tx0": -tx, "tx1": tx, "e0": -end, "e1": end, "top": 36.0, "low": SZ_DECK_M + 2.4,
			"end0": SZ_DECK_M + 1.0, "end1": SZ_DECK_M + 1.0, "sag0": 4.0, "sag1": 4.0}
		var x := -end + 3.6
		while x < end - 1.0:
			var cy := LandmarkBrKit.cable_y(p, x)
			if absf(absf(x) - tx) > SZ_TOWER_X * 0.5:
				for lift in [0.0, 1.5]:
					lm.box("Steel", Vector3(x, cy + lift, sz * SZ_CHAIN_Z), Vector3(0.5, 1.3, 1.3), Basis(), 0.0)
			x += 3.6
	lm.commit(model)

## One Chain Bridge tower at x: the river pier with its cutwaters, the
## arch legs, footway passages, pilasters, entablature and attic.
static func _sz_tower(lm: LandmarkMesh, x: float) -> void:
	var hx := SZ_TOWER_X * 0.5
	var hz := SZ_TOWER_Z * 0.5
	# River pier with pointed cutwaters up- and downstream.
	lm.box("Stone", Vector3(x, SZ_DECK_M * 0.5 - 0.5, 0), Vector3(SZ_TOWER_X + 1.0, SZ_DECK_M - 1.0, SZ_TOWER_Z))
	for sz in [-1.0, 1.0]:
		lm.poly_prism("Stone", PackedVector2Array([Vector2(x - hx - 0.5, sz * hz), Vector2(x, sz * (hz + 5.5)),
			Vector2(x + hx + 0.5, sz * hz)]), 0.0, SZ_DECK_M - 3.0)
		lm.spire("Stone", Vector3(x, SZ_DECK_M - 3.0, sz * (hz + 1.2)), 3.0, 2.5, 0.5, 4)
	lm.box("Stone", Vector3(x, SZ_DECK_M - 0.6, 0), Vector3(SZ_TOWER_X + 1.6, 1.2, SZ_TOWER_Z + 1.0))
	# Legs: inner pier, footway passage, outer pier, then the solid block.
	var arch_top := 30.0
	for sz in [-1.0, 1.0]:
		for zr in [[3.8, 5.9], [7.9, hz]]:
			var z0: float = zr[0]
			var z1: float = zr[1]
			lm.box("Stone", Vector3(x, (SZ_DECK_M + arch_top) * 0.5, sz * (z0 + z1) * 0.5),
				Vector3(SZ_TOWER_X, arch_top - SZ_DECK_M, z1 - z0))
		lm.box("Stone", Vector3(x, (SZ_DECK_M + 6.0 + arch_top) * 0.5, sz * 6.9),
			Vector3(SZ_TOWER_X, arch_top - SZ_DECK_M - 6.0, 2.0))
		for fx in [-1.0, 1.0]:
			LandmarkDetail.arch(lm, "Stone", Vector3(x + fx * hx, SZ_DECK_M + 5.0, sz * 6.9),
				Vector3(fx, 0, 0), 2.0, 0.35, 0.25)
			# Paired pilasters on the outer pier face.
			for pz in [8.6, 10.4]:
				lm.box("Stone", Vector3(x + fx * (hx + 0.2), (SZ_DECK_M + arch_top) * 0.5, sz * pz),
					Vector3(0.4, arch_top - SZ_DECK_M, 1.0))
				lm.box("Stone", Vector3(x + fx * (hx + 0.35), arch_top - 0.4, sz * pz), Vector3(0.7, 0.8, 1.3))
				lm.box("Stone", Vector3(x + fx * (hx + 0.35), SZ_DECK_M + 0.5, sz * pz), Vector3(0.7, 1.0, 1.3))
	# Great round arch over the carriageway (7.6 m), its archivolt, and the
	# block above it.
	var poly := PackedVector2Array([Vector2(-3.8, arch_top + 0.01), Vector2(-3.8, 26.2)])
	for k in range(1, 12):
		var a := PI * (1.0 - float(k) / 12.0)
		poly.append(Vector2(3.8 * cos(a), 26.2 + 3.8 * sin(a)))
	poly.append(Vector2(3.8, 26.2))
	poly.append(Vector2(3.8, arch_top + 0.01))
	LandmarkBrKit.extrude_yz(lm, "Stone", poly, x - hx, x + hx)
	for fx in [-1.0, 1.0]:
		LandmarkDetail.arch(lm, "Stone", Vector3(x + fx * hx, 26.2, 0), Vector3(fx, 0, 0), 7.6, 0.6, 0.3)
		LandmarkDetail.cornice(lm, "Stone", Vector3(x + fx * hx, 33.6, -hz), Vector3(x + fx * hx, 33.6, hz),
			Vector3(fx, 0, 0), 1.2, true)
		# Hungarian arms under a wreath on the attic.
		var ac := Vector3(x + fx * (hx - 0.5 + 0.35), 39.0, 0)
		lm.box("Stone", ac, Vector3(0.6, 3.2, 2.6))
		lm.lathe("Stone", ac + Vector3(fx * 0.3, 1.6, 0), PackedVector2Array([Vector2(1.2, 0), Vector2(1.0, 0.7),
			Vector2(0.5, 1.2), Vector2(0.0, 1.4)]), 10, 0.4, 1.0)
	lm.box("Stone", Vector3(x, 32.0, 0), Vector3(SZ_TOWER_X, 4.0, SZ_TOWER_Z))
	lm.box("Stone", Vector3(x, 34.4, 0), Vector3(SZ_TOWER_X + 1.0, 0.8, SZ_TOWER_Z + 1.0))
	# Attic: chain saddles pass through it; a stepped crowning block.
	lm.box("Stone", Vector3(x, 38.3, 0), Vector3(SZ_TOWER_X - 1.0, 7.0, SZ_TOWER_Z - 3.0))
	lm.box("Stone", Vector3(x, 42.2, 0), Vector3(SZ_TOWER_X - 0.4, 0.8, SZ_TOWER_Z - 2.4))
	lm.box("Stone", Vector3(x, 44.0, 0), Vector3(SZ_TOWER_X - 2.6, 2.8, SZ_TOWER_Z - 6.0))
	lm.gable("Stone", Vector3(x, 45.4, 0), SZ_TOWER_X - 2.6, SZ_TOWER_Z - 6.0, 2.6, Basis(), 0.3, "Stone")

## Abutment at the end (side s) with the anchorage house the chains run
## into and the two lions on their pedestals by the roadway.
static func _sz_abutment(lm: LandmarkMesh, s: float, end: float) -> void:
	var ax: float = s * (end + 9.0)
	lm.box("Stone", Vector3(ax, (SZ_DECK_M - 0.4) * 0.5, 0), Vector3(18.0, SZ_DECK_M - 0.4, 22.0))
	lm.box("Stone", Vector3(ax, SZ_DECK_M - 0.2, 0), Vector3(19.0, 0.8, 23.0))
	lm.box("Stone", Vector3(ax, 1.0, 0), Vector3(19.0, 2.0, 23.0))
	lm.box("Deck", Vector3(ax, SZ_DECK_M + 0.25, 0), Vector3(18.0, 0.5, 9.0))
	for z in [-9.0, 9.0]:
		var lx: float = s * (end + 4.0)
		lm.box("Stone", Vector3(lx, SZ_DECK_M + 0.6, z), Vector3(6.0, 1.2, 3.2))
		lm.box("Stone", Vector3(lx, SZ_DECK_M + 1.6, z), Vector3(5.6, 0.8, 2.8))
		LandmarkBrKit.lion(lm, "Stone", Vector3(lx, SZ_DECK_M + 2.0, z), Vector3(-s, 0, 0), 4.4)
