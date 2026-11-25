extends RefCounted

## Government Palace (Valtioneuvoston linna), Engel's Empire block on the
## east side of Senate Square (1822), model origin at the centroid of the
## OSM relation outline (relation 1331998), front +Z, registry yaw 87 turns
## the front west onto the square.
##
## From the photos (visual-plan/refs/landmarks/government_palace_helsinki/):
## - A square-built ring: the 83 x 16 m front range, two 15 m wings and a
##   14 m rear range round a 52 x 79 m courtyard. Outline, courtyard and
##   the 2 m central projection are the OSM ring in metres.
## - Pale ochre render over a pinkish granite plinth (2.9 m, rusticated
##   joints), then three storeys: a ground floor of round-headed windows
##   (to 9.4 m), a piano nobile of tall windows, alternate bays under a
##   triangular hood (to 15.2 m), a low top floor (to 19.2 m), and a white
##   dentilled cornice at 19.2-20.4 m under a dark low metal hip roof.
## - White paired pilasters mark the end pavilions and the central
##   avant-corps. In front of the avant-corps a 6.5 m ground-floor block
##   with three arched doors carries a balustraded deck; on it stand six
##   Corinthian columns (8.9 m) under a pediment to 22.9 m. A granite stair
##   rises from the square, the dome stands behind the pediment (drum and
##   low dome to 25.9 m).
##
## Measured: outline and height (LoD2 26.1 m is the dome). Counted from a
## front photo: 8 + 9 side bays, 5 bays behind the portico, floor heights.
## Estimated: courtyard-side and rear window rhythm, roof pitch, bay widths
## in the wings (the photo is oblique).

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const E = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_empire.gd")

const ENTRY := {"type": "government_palace_helsinki", "name": "Government Palace, Helsinki", "lat": 60.169592, "lon": 24.954629,
	"radius_m": 5000.0, "wiki_title": "Government Palace, Helsinki", "height_m": 26.0, "clear_m": 32.0,
	"clear_offsets_m": [[2.0, 41.0], [-31.0, -6.0], [36.0, -6.0], [2.0, -53.0], [-31.0, 40.0], [36.0, 40.0],
		[-31.0, -50.0], [36.0, -50.0]],
	"yaw_deg": 87.0, "kind": "Palace", "aliases": ["government palace, helsinki", "valtioneuvoston linna", "statsradsborgen"]}

const XL := -39.3
const XR := 43.8
const ZF := 49.2
const ZB := -60.4
const CX := 0.2
const PLINTH := 2.9
const F1 := 9.4
const F2 := 15.2
const EAVE := 19.2
const WING_EAVE := 18.0
const COURT_W := -23.5
const COURT_E := 28.8
const COURT_N := -46.3
const COURT_S := 33.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E6CB7A", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F2EEE2", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8E807A", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#3F4448", 3.0, 0.6, 0.3))
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
		[Vector3(-22.0, 3.0, ZF + 28.0), Vector3(-14.0, 11.0, ZF), 40.0, 0.9, 55.0, warm],
		[Vector3(24.0, 3.0, ZF + 28.0), Vector3(16.0, 11.0, ZF), 40.0, 0.9, 55.0, warm],
		[Vector3(0.0, 3.0, ZF + 30.0), Vector3(0.0, 14.0, ZF + 1.0), 30.0, 0.8, 55.0, warm],
	])

## The four ranges on their granite plinth.
static func _ring(lm: LandmarkMesh) -> void:
	# [x0, x1, z0, z1, eave]
	var ranges := [[XL, XR, COURT_S, ZF, EAVE], [XL, COURT_W, ZB, COURT_S, WING_EAVE],
		[COURT_E, 39.5, -41.1, 30.0, WING_EAVE], [COURT_E, XR, -60.4, -41.1, WING_EAVE],
		[COURT_E, XR, 30.0, COURT_S, WING_EAVE], [XL, XR, ZB, COURT_N, WING_EAVE]]
	for r in ranges:
		var x0: float = r[0]
		var x1: float = r[1]
		var z0: float = r[2]
		var z1: float = r[3]
		var eave: float = r[4]
		U.blk(lm, "Stone", (x0 + x1) * 0.5, 0.0, (z0 + z1) * 0.5, x1 - x0 + 0.5, PLINTH, z1 - z0 + 0.5)
		U.blk(lm, "Wall", (x0 + x1) * 0.5, PLINTH, (z0 + z1) * 0.5, x1 - x0, eave - PLINTH, z1 - z0)
	# The east wing's recessed middle meets the end blocks at z = 30 and -41.1.
	U.blk(lm, "Wall", 34.0, PLINTH, 30.0, 11.0, WING_EAVE - PLINTH, 0.2)

## The square front: windows, string courses, cornice, pilasters.
static func _front(lm: LandmarkMesh) -> void:
	var out := Vector3(0, 0, 1)
	var wings := [[XL + 1.2, CX - 13.3, 8], [CX + 13.7, XR - 1.2, 9]]
	for w in wings:
		var a := Vector3(float(w[0]), 0, ZF)
		var b := Vector3(float(w[1]), 0, ZF)
		var n: int = w[2]
		var odd: Array = []
		var even: Array = []
		for i in n:
			(odd if i % 2 == 1 else even).append(i)
		E.row(lm, "Trim", "Glass", a, b, out, PLINTH + 0.9, n, 1.7, 3.3, "arch")
		E.row(lm, "Trim", "Glass", a, b, out, F1 + 1.1, n, 1.5, 3.0, "rect", odd)
		E.row(lm, "Trim", "Glass", a, b, out, F1 + 1.1, n, 1.5, 3.0, "hood", even)
		E.row(lm, "Trim", "Glass", a, b, out, F2 + 1.1, n, 1.4, 2.3, "rect")
		# Small basement lights in the plinth.
		E.row(lm, "Trim", "Glass", a, b, out, 1.3, n, 0.9, 0.7, "plain")
	# The avant-corps either side of the portico: one bay on each flank.
	for s in [-1.0, 1.0]:
		var x: float = CX + s * 11.4
		E.win(lm, "Trim", "Glass", Vector3(x, PLINTH + 0.9, ZF), out, 1.7, 3.3, "arch")
		E.win(lm, "Trim", "Glass", Vector3(x, F1 + 1.1, ZF), out, 1.5, 3.0, "hood")
		E.win(lm, "Trim", "Glass", Vector3(x, F2 + 1.1, ZF), out, 1.4, 2.3, "rect")
	# Behind the columns: five bays, round-headed above the deck.
	for k in 5:
		var x := CX + (float(k) - 2.0) * 3.3
		E.win(lm, "Trim", "Glass", Vector3(x, F1 + 1.1, ZF), out, 1.4, 3.6, "arch")
		E.win(lm, "Trim", "Glass", Vector3(x, F2 + 1.1, ZF), out, 1.4, 2.3, "rect")
	var a2 := Vector2(XL, ZF)
	var b2 := Vector2(XR, ZF)
	E.course(lm, "Trim", a2, b2, Vector2(0, 1), F1 - 0.3, 0.45, 0.18)
	E.course(lm, "Trim", a2, b2, Vector2(0, 1), F2 - 0.25, 0.4, 0.15)
	E.course(lm, "Trim", a2, b2, Vector2(0, 1), PLINTH - 0.1, 0.35, 0.25)
	LandmarkDetail.cornice(lm, "Trim", Vector3(XL, EAVE - 1.0, ZF), Vector3(XR, EAVE - 1.0, ZF), out, 1.4, true)
	# Paired pilasters on the end pavilions and the avant-corps.
	for x in [XL + 0.7, XL + 4.3, XR - 0.7, XR - 4.3, CX - 13.0, CX - 10.4, CX + 10.8, CX + 13.4]:
		E.pilaster(lm, "Trim", Vector3(x, 0, ZF), out, PLINTH, EAVE - 1.0 - PLINTH, 0.8, 0.3)
	# Rusticated joints on the granite plinth.
	for k in 3:
		E.course(lm, "Stone", a2, b2, Vector2(0, 1), 0.7 + 0.7 * float(k), 0.08, 0.3)

## The central block: three arched doors, deck, six columns, pediment, stair.
static func _portico(lm: LandmarkMesh) -> void:
	var out := Vector3(0, 0, 1)
	var pz := ZF + 2.0
	U.blk(lm, "Wall", CX, PLINTH, ZF + 1.0, 20.8, F1 - PLINTH, 2.0)
	for k in 3:
		var x := CX + (float(k) - 1.0) * 3.3
		E.win(lm, "Trim", "Glass", Vector3(x, PLINTH + 0.1, pz), out, 2.2, 5.0, "arch")
	for s in [-1.0, 1.0]:
		E.win(lm, "Trim", "Glass", Vector3(CX + s * 7.9, PLINTH + 0.9, pz), out, 1.7, 3.3, "arch")
		E.pilaster(lm, "Stone", Vector3(CX + s * 10.0, 0, pz), out, PLINTH, F1 - PLINTH, 1.0, 0.25)
	# Deck and its balustrade.
	U.blk(lm, "Trim", CX, F1 - 0.6, ZF + 1.15, 21.4, 0.6, 2.5)
	LandmarkDetail.balustrade(lm, "Trim", Vector3(CX - 10.3, F1, ZF + 2.15), Vector3(CX + 10.3, F1, ZF + 2.15), 1.0, 3.3)
	E.portico(lm, "Trim", CX, ZF, 16.5, 6, F1, 8.9, 2.0, 3.3, "corinthian", 0.5)
	# Clock in the tympanum.
	lm.disc("Stone", Vector3(CX, F1 + 8.9 + 2.3, ZF + 2.28), out, 0.7, 20)
	# Granite stair from the square to the doors.
	U.steps(lm, "Stone", Vector3(CX, 0, pz), out, 15.0, 0.45, 0.36, 8)
	# A flagpole on the roof ridge behind the pediment.
	lm.frustum("Pole", Vector3(CX, EAVE + 1.6, ZF - 6.0), 0.1, 0.05, 5.2, 6)

## Courtyard, outer flanks and rear: plain bays on three floors.
static func _sides(lm: LandmarkMesh) -> void:
	var rows := [[3.9, 1.3, 3.0, "plain"], [9.9, 1.4, 3.0, "plain"], [15.0, 1.3, 2.2, "plain"]]
	# [a, b, out] in XZ.
	var runs := [
		[Vector2(XL, ZB), Vector2(XL, ZF), Vector2(-1, 0)],
		[Vector2(XR, 30.0), Vector2(XR, ZF), Vector2(1, 0)],
		[Vector2(XR, ZB), Vector2(XR, -41.1), Vector2(1, 0)],
		[Vector2(39.5, -41.1), Vector2(39.5, 30.0), Vector2(1, 0)],
		[Vector2(XR, ZB), Vector2(XL, ZB), Vector2(0, -1)],
		[Vector2(COURT_W, COURT_N), Vector2(COURT_W, COURT_S), Vector2(1, 0)],
		[Vector2(COURT_E, COURT_N), Vector2(COURT_E, COURT_S), Vector2(-1, 0)],
		[Vector2(COURT_W, COURT_N), Vector2(COURT_E, COURT_N), Vector2(0, 1)],
		[Vector2(COURT_W, COURT_S), Vector2(COURT_E, COURT_S), Vector2(0, -1)]]
	for r in runs:
		E.run(lm, "Trim", "Glass", r[0], r[1], r[2], 3.6, rows, 1.5)
		E.course(lm, "Trim", r[0], r[1], r[2], WING_EAVE - 0.9, 0.9, 0.45)
		E.course(lm, "Trim", r[0], r[1], r[2], F1 - 0.3, 0.35, 0.12)
		E.course(lm, "Trim", r[0], r[1], r[2], F2 - 0.25, 0.35, 0.12)

## Low dark hip roofs, chimneys and the dome behind the pediment.
static func _roofs(lm: LandmarkMesh) -> void:
	U.hip(lm, "Roof", Vector3((XL + XR) * 0.5, EAVE, (COURT_S + ZF) * 0.5), XR - XL + 0.8, ZF - COURT_S + 0.8, 1.7, 0.9)
	U.hip(lm, "Roof", Vector3((XL + COURT_W) * 0.5, WING_EAVE, (ZB + COURT_S) * 0.5), COURT_W - XL + 0.8, COURT_S - ZB + 0.8, 2.3, 0.25)
	U.hip(lm, "Roof", Vector3((COURT_E + 39.5) * 0.5, WING_EAVE, -5.5), 39.5 - COURT_E + 0.8, 71.1 + 0.8, 2.2, 0.25)
	U.hip(lm, "Roof", Vector3((COURT_E + XR) * 0.5, WING_EAVE, -50.7), XR - COURT_E + 0.8, 19.3 + 0.8, 2.1, 0.35)
	U.hip(lm, "Roof", Vector3((XL + XR) * 0.5, WING_EAVE, (ZB + COURT_N) * 0.5), XR - XL + 0.8, COURT_N - ZB + 0.8, 2.0, 0.5)
	for p in [Vector3(-30.0, 0, 41.0), Vector3(-8.0, 0, 40.0), Vector3(18.0, 0, 41.0), Vector3(34.0, 0, 41.0),
			Vector3(-31.0, 0, -20.0), Vector3(-31.0, 0, 10.0), Vector3(36.0, 0, -10.0), Vector3(10.0, 0, -53.0),
			Vector3(-20.0, 0, -53.0)]:
		var cy := EAVE if p.z > 30.0 else WING_EAVE
		U.blk(lm, "Wall", p.x, cy, p.z, 1.6, 3.8, 1.6)
		U.blk(lm, "Trim", p.x, cy + 3.7, p.z, 1.9, 0.25, 1.9)
	var dc := Vector3(CX, EAVE + 1.4, 39.0)
	lm.frustum("Wall", Vector3(CX, EAVE, 39.0), 5.6, 5.6, 2.6, 28)
	lm.frustum("Trim", dc + Vector3(0, 1.2, 0), 5.9, 5.9, 0.35, 28)
	lm.lathe("Roof", dc + Vector3(0, 1.5, 0), U.dome_prof(5.5, 3.3), 28)
	lm.frustum("Trim", dc + Vector3(0, 4.7, 0), 0.9, 0.9, 0.8, 10)
	lm.lathe("Roof", dc + Vector3(0, 5.5, 0), U.dome_prof(1.0, 0.8), 10)
