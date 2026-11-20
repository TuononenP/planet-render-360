extends RefCounted

## University of Helsinki Main Building (Engel, 1832), on the west side of
## Senate Square. Model origin at the centroid of the OSM relation outline
## (relation 1320784), front +Z; registry yaw -93 turns the front east onto
## the square.
##
## From the photos (visual-plan/refs/landmarks/helsinki_university_main/):
## - A 83.5 m front range (19 m deep) and a rear range joined by three
##   spines, so two 11 m courtyards open between them; the 3 m central
##   projection and all outer lines are the OSM ring.
## - Pale yellow render over a pinkish granite plinth (3.5 m), then a
##   ground floor of small square windows (to 9.3 m), a piano nobile of tall
##   windows under round hoods (to 14.6 m), a top floor of low windows (to
##   19.4 m) and a white cornice under a plain dark roof. No dome.
## - Paired white pilasters carry the end pavilions and the avant-corps.
##   In front of the avant-corps a ground-floor block with three doors
##   carries a balustraded deck and six Ionic columns (8.1 m) under a
##   plain pediment to 22.4 m; a granite stair rises from the square.
##
## Measured: outline, height (the LoD2 match 28 m away is Tiedekulma, not
## this building; 22.4 m to the pediment apex is read from a front photo
## scaled by the 83.5 m width). Counted from the photo: 9 + 9 side bays,
## three floors, six columns. Estimated: floor heights, courtyard and rear
## window rhythm, roof pitch.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const E = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_empire.gd")

const ENTRY := {"type": "helsinki_university_main", "name": "University of Helsinki Main Building", "lat": 60.169491, "lon": 24.950359,
	"radius_m": 5000.0, "wiki_title": "University of Helsinki Main Building", "height_m": 22.0, "clear_m": 32.0,
	"clear_offsets_m": [[-3.0, 13.0], [-37.0, -15.0], [-3.0, -15.0], [31.0, -15.0], [-3.0, -43.0], [-37.0, 12.0],
		[31.0, 12.0], [-37.0, -43.0], [31.0, -43.0]],
	"yaw_deg": -93.0, "kind": "University", "aliases": ["university of helsinki main building", "helsingin yliopiston paarakennus", "helsingin yliopiston päärakennus"]}

const X0 := -44.5
const X1 := 39.0
const ZF := 22.7
const ZB := -52.6
const CX := -3.15
const PLINTH := 3.5
const F1 := 9.3
const F2 := 14.6
const EAVE := 19.4
const Z_SPINE_N := -33.9
const Z_SPINE_S := 3.3

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E8D084", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F1ECDD", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8B7C77", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#43484B", 3.0, 0.6, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2B3237"))
	lm.use("Pole", LandmarkMaterials.paint("#E8E8E6", 0.5, 0.3))
	_ring(lm)
	_front(lm)
	_portico(lm)
	_sides(lm)
	_roofs(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.86, 0.62)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-24.0, 3.0, ZF + 28.0), Vector3(-16.0, 11.0, ZF), 40.0, 0.9, 55.0, warm],
		[Vector3(22.0, 3.0, ZF + 28.0), Vector3(14.0, 11.0, ZF), 40.0, 0.9, 55.0, warm],
		[Vector3(CX, 3.0, ZF + 30.0), Vector3(CX, 14.0, ZF + 1.0), 30.0, 0.8, 55.0, warm],
	])

static func _ring(lm: LandmarkMesh) -> void:
	# [x0, x1, z0, z1]: front range, rear range and the three spines.
	var ranges := [[X0, X1, Z_SPINE_S, ZF], [X0, X1, ZB, Z_SPINE_N], [X0, -30.2, Z_SPINE_N, Z_SPINE_S],
		[-18.6, 12.9, Z_SPINE_N, Z_SPINE_S], [24.3, X1, Z_SPINE_N, Z_SPINE_S]]
	for r in ranges:
		var x0: float = r[0]
		var x1: float = r[1]
		var z0: float = r[2]
		var z1: float = r[3]
		U.blk(lm, "Stone", (x0 + x1) * 0.5, 0.0, (z0 + z1) * 0.5, x1 - x0 + 0.5, PLINTH, z1 - z0 + 0.5)
		U.blk(lm, "Wall", (x0 + x1) * 0.5, PLINTH, (z0 + z1) * 0.5, x1 - x0, EAVE - PLINTH, z1 - z0)

static func _front(lm: LandmarkMesh) -> void:
	var out := Vector3(0, 0, 1)
	var wings := [[X0 + 1.2, CX - 11.6, 9], [CX + 12.0, X1 - 1.2, 9]]
	for w in wings:
		var a := Vector3(float(w[0]), 0, ZF)
		var b := Vector3(float(w[1]), 0, ZF)
		var n: int = w[2]
		E.row(lm, "Trim", "Glass", a, b, out, 5.0, n, 1.4, 1.9, "rect")
		E.row(lm, "Trim", "Glass", a, b, out, F1 + 1.0, n, 1.4, 3.1, "round")
		E.row(lm, "Trim", "Glass", a, b, out, F2 + 1.0, n, 1.4, 2.5, "rect")
		E.row(lm, "Trim", "Glass", a, b, out, 1.5, n, 0.9, 0.7, "plain")
	for s in [-1.0, 1.0]:
		var x: float = CX + s * 10.0
		E.win(lm, "Trim", "Glass", Vector3(x, 5.0, ZF), out, 1.4, 1.9, "rect")
		E.win(lm, "Trim", "Glass", Vector3(x, F1 + 1.0, ZF), out, 1.4, 3.1, "round")
		E.win(lm, "Trim", "Glass", Vector3(x, F2 + 1.0, ZF), out, 1.4, 2.5, "rect")
	for k in 5:
		var x := CX + (float(k) - 2.0) * 3.0
		E.win(lm, "Trim", "Glass", Vector3(x, F1 + 0.9, ZF), out, 1.3, 3.6, "arch")
		E.win(lm, "Trim", "Glass", Vector3(x, F2 + 1.0, ZF), out, 1.4, 2.5, "rect")
	var a2 := Vector2(X0, ZF)
	var b2 := Vector2(X1, ZF)
	E.course(lm, "Trim", a2, b2, Vector2(0, 1), F1 - 0.3, 0.45, 0.18)
	E.course(lm, "Trim", a2, b2, Vector2(0, 1), F2 - 0.25, 0.4, 0.15)
	E.course(lm, "Trim", a2, b2, Vector2(0, 1), PLINTH - 0.1, 0.35, 0.25)
	LandmarkDetail.cornice(lm, "Trim", Vector3(X0, EAVE - 1.0, ZF), Vector3(X1, EAVE - 1.0, ZF), out, 1.4, true)
	# Paired pilasters on the end pavilions and the avant-corps.
	for x in [X0 + 0.7, X0 + 4.0, X0 + 8.0, X1 - 0.7, X1 - 4.0, X1 - 8.0, CX - 12.0, CX - 9.2, CX + 9.4, CX + 12.2]:
		E.pilaster(lm, "Trim", Vector3(x, 0, ZF), out, PLINTH, EAVE - 1.0 - PLINTH, 0.8, 0.3)
	for k in 3:
		E.course(lm, "Stone", a2, b2, Vector2(0, 1), 0.8 + 0.8 * float(k), 0.08, 0.3)

static func _portico(lm: LandmarkMesh) -> void:
	var out := Vector3(0, 0, 1)
	var pz := ZF + 3.0
	U.blk(lm, "Wall", CX, PLINTH, ZF + 1.5, 19.0, 10.0 - PLINTH, 3.0)
	for k in 3:
		var x := CX + (float(k) - 1.0) * 3.0
		E.win(lm, "Trim", "Glass", Vector3(x, PLINTH + 0.1, pz), out, 1.9, 5.0, "rect")
	for s in [-1.0, 1.0]:
		E.win(lm, "Trim", "Glass", Vector3(CX + s * 6.8, 5.0, pz), out, 1.4, 1.9, "rect")
		E.pilaster(lm, "Stone", Vector3(CX + s * 9.0, 0, pz), out, PLINTH, 10.0 - PLINTH, 1.0, 0.25)
	U.blk(lm, "Trim", CX, 9.4, ZF + 1.65, 19.6, 0.6, 3.5)
	LandmarkDetail.balustrade(lm, "Trim", Vector3(CX - 9.3, 10.0, ZF + 3.15), Vector3(CX + 9.3, 10.0, ZF + 3.15), 1.0, 3.0)
	E.portico(lm, "Trim", CX, ZF, 15.0, 6, 10.0, 8.1, 3.0, 3.0, "ionic", 0.5)
	U.steps(lm, "Stone", Vector3(CX, 0, pz), out, 14.0, 0.45, 0.36, 9)
	lm.frustum("Pole", Vector3(CX, EAVE + 1.0, ZF - 8.0), 0.1, 0.05, 3.0, 6)

static func _sides(lm: LandmarkMesh) -> void:
	var rows := [[4.6, 1.3, 2.0, "plain"], [10.2, 1.4, 3.1, "plain"], [15.6, 1.3, 2.4, "plain"]]
	var runs := [
		[Vector2(X0, ZB), Vector2(X0, ZF), Vector2(-1, 0)],
		[Vector2(X1, ZB), Vector2(X1, ZF), Vector2(1, 0)],
		[Vector2(X1, ZB), Vector2(X0, ZB), Vector2(0, -1)],
		[Vector2(-30.2, Z_SPINE_N), Vector2(-30.2, Z_SPINE_S), Vector2(1, 0)],
		[Vector2(-18.6, Z_SPINE_N), Vector2(-18.6, Z_SPINE_S), Vector2(-1, 0)],
		[Vector2(12.9, Z_SPINE_N), Vector2(12.9, Z_SPINE_S), Vector2(1, 0)],
		[Vector2(24.3, Z_SPINE_N), Vector2(24.3, Z_SPINE_S), Vector2(-1, 0)],
		[Vector2(-30.2, Z_SPINE_S), Vector2(-18.6, Z_SPINE_S), Vector2(0, -1)],
		[Vector2(12.9, Z_SPINE_S), Vector2(24.3, Z_SPINE_S), Vector2(0, -1)],
		[Vector2(-30.2, Z_SPINE_N), Vector2(-18.6, Z_SPINE_N), Vector2(0, 1)],
		[Vector2(12.9, Z_SPINE_N), Vector2(24.3, Z_SPINE_N), Vector2(0, 1)]]
	for r in runs:
		E.run(lm, "Trim", "Glass", r[0], r[1], r[2], 3.4, rows, 1.2)
		E.course(lm, "Trim", r[0], r[1], r[2], EAVE - 0.9, 0.9, 0.45)
		E.course(lm, "Trim", r[0], r[1], r[2], F1 - 0.3, 0.35, 0.12)
		E.course(lm, "Trim", r[0], r[1], r[2], F2 - 0.25, 0.35, 0.12)

static func _roofs(lm: LandmarkMesh) -> void:
	var cx := (X0 + X1) * 0.5
	U.hip(lm, "Roof", Vector3(cx, EAVE, (Z_SPINE_S + ZF) * 0.5), X1 - X0 + 0.8, ZF - Z_SPINE_S + 0.8, 1.7, 0.9)
	U.hip(lm, "Roof", Vector3(cx, EAVE, (ZB + Z_SPINE_N) * 0.5), X1 - X0 + 0.8, Z_SPINE_N - ZB + 0.8, 1.7, 0.9)
	var zc := (Z_SPINE_N + Z_SPINE_S) * 0.5
	for sp in [[X0, -30.2], [-18.6, 12.9], [24.3, X1]]:
		var x0: float = sp[0]
		var x1: float = sp[1]
		U.hip(lm, "Roof", Vector3((x0 + x1) * 0.5, EAVE, zc), x1 - x0 + 0.8, Z_SPINE_S - Z_SPINE_N + 0.8, 1.8, 0.4)
	for p in [Vector2(-34.0, 14.0), Vector2(-14.0, 14.0), Vector2(14.0, 14.0), Vector2(32.0, 14.0),
			Vector2(-30.0, -43.0), Vector2(0.0, -43.0), Vector2(28.0, -43.0), Vector2(-38.0, -15.0),
			Vector2(-3.0, -15.0), Vector2(32.0, -15.0)]:
		U.blk(lm, "Wall", p.x, EAVE + 1.6, p.y, 1.6, 2.0, 1.6)
		U.blk(lm, "Trim", p.x, EAVE + 3.5, p.y, 1.9, 0.25, 1.9)
