extends RefCounted

## Bock House (Bockin talo, Engel, 1836-39), Aleksanterinkatu 20 on the
## south side of Senate Square's approach. Model origin at the centre of
## the OSM outline (way 17426424), front +Z; registry yaw 180 turns the
## front north onto Aleksanterinkatu.
##
## The plan is the OSM outline: a 32.7 m front range, a long west and east
## bar and a slot open to the south, with the 11.5 m x 2.4 m central
## projection on the front. Three storeys in orange ochre render (a
## rusticated ground floor to 5.4 m, a piano nobile with round-hooded
## windows to 10.4 m, a plain top floor to 15 m), white string courses and
## cornice, a low dark hip roof. On the front: a ground-floor block with
## the door and two windows carries a balustraded deck and four Ionic
## columns (8.3 m) under a pediment to 16.9 m, the big arched window
## between the middle columns (ref: visual-plan/refs/landmarks/bock_house/).
##
## Measured: outline and orientation (OSM). Counted from the photos: three
## storeys, nine front bays, four columns. Estimated: storey heights, roof
## pitch, rear and courtyard window rhythm.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const E = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_empire.gd")

const ENTRY := {"type": "bock_house", "name": "Bock House", "lat": 60.168780, "lon": 24.953192,
	"radius_m": 1500.0, "wiki_title": "Bock House", "height_m": 17.0, "clear_m": 24.0,
	"clear_offsets_m": [[0.0, 15.0], [0.0, -15.0], [0.0, 0.0]],
	"yaw_deg": 180.0, "kind": "House", "aliases": ["bock house", "bockin talo", "bockska huset"]}

const ZF := 25.5
const CX := 0.6
const PLINTH := 0.9
const F1 := 5.4
const F2 := 10.4
const EAVE := 15.0

static func _outline() -> PackedVector2Array:
	return PackedVector2Array([Vector2(-16.2, ZF), Vector2(-16.4, -26.8), Vector2(-6.2, -27.2), Vector2(-5.2, -22.2),
		Vector2(-4.6, -3.9), Vector2(-5.6, 13.2), Vector2(7.4, 13.0), Vector2(6.8, -3.1), Vector2(7.9, -3.2),
		Vector2(7.8, -9.4), Vector2(15.0, -9.9), Vector2(16.3, ZF)])

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#DDA64C", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F1ECDD", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8E8780", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#454A4D", 3.0, 0.6, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2B3237"))
	lm.use("Iron", LandmarkMaterials.paint("#2A2C2E", 0.5, 0.5))
	var poly := _outline()
	lm.poly_prism("Stone", _grow(poly, 0.2), 0.0, PLINTH)
	lm.poly_prism("Wall", poly, PLINTH, EAVE)
	var rows := [[2.0, 1.4, 2.3, "plain"], [6.6, 1.5, 3.0, "plain"], [11.6, 1.4, 2.4, "plain"]]
	E.poly_walls(lm, "Trim", "Glass", poly, 3.5, rows, 1.2, 4.0, Vector2(0, 1), 0.9)
	_front(lm)
	_roofs(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.86, 0.62)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-12.0, 3.0, ZF + 18.0), Vector3(-6.0, 8.0, ZF), 40.0, 0.8, 40.0, warm],
		[Vector3(14.0, 3.0, ZF + 18.0), Vector3(7.0, 8.0, ZF), 40.0, 0.8, 40.0, warm],
	])

static func _grow(poly: PackedVector2Array, d: float) -> PackedVector2Array:
	var c := LandmarkFhParts.centre(poly)
	var out := PackedVector2Array()
	for p in poly:
		out.append(p + (p - c).normalized() * d)
	return out

static func _front(lm: LandmarkMesh) -> void:
	var out := Vector3(0, 0, 1)
	var a := Vector3(-16.2 + 1.2, 0, ZF)
	var b := Vector3(16.3 - 1.2, 0, ZF)
	var skip := [3, 4, 5]
	E.row(lm, "Trim", "Glass", a, b, out, 2.0, 9, 1.4, 2.3, "plain", skip)
	E.row(lm, "Trim", "Glass", a, b, out, 6.6, 9, 1.5, 3.0, "round", skip)
	E.row(lm, "Trim", "Glass", a, b, out, 11.6, 9, 1.4, 2.4, "rect", skip)
	var a2 := Vector2(-16.2, ZF)
	var b2 := Vector2(16.3, ZF)
	E.course(lm, "Trim", a2, b2, Vector2(0, 1), F1 - 0.25, 0.4, 0.15)
	E.course(lm, "Trim", a2, b2, Vector2(0, 1), F2 - 0.2, 0.35, 0.12)
	E.course(lm, "Trim", a2, b2, Vector2(0, 1), PLINTH - 0.1, 0.3, 0.2)
	LandmarkDetail.cornice(lm, "Trim", Vector3(-16.2, EAVE - 0.9, ZF), Vector3(16.3, EAVE - 0.9, ZF), out, 1.2, true)
	for k in 3:
		E.course(lm, "Stone", a2, b2, Vector2(0, 1), 1.2 + 1.2 * float(k), 0.07, 0.15)
	for x in [-16.0, -14.0, 14.2, 16.1]:
		E.pilaster(lm, "Trim", Vector3(x, 0, ZF), out, PLINTH, EAVE - 0.9 - PLINTH, 0.7, 0.25)
	# Entrance block, deck and the four Ionic columns.
	var pz := ZF + 1.6
	U.blk(lm, "Wall", CX, PLINTH, ZF + 0.8, 11.6, F1 - PLINTH, 1.6)
	E.win(lm, "Trim", "Glass", Vector3(CX, PLINTH + 0.1, pz), out, 1.6, 3.6, "arch")
	for s in [-1.0, 1.0]:
		E.win(lm, "Trim", "Glass", Vector3(CX + s * 3.9, 2.0, pz), out, 1.4, 2.3, "plain")
		E.pilaster(lm, "Stone", Vector3(CX + s * 5.6, 0, pz), out, PLINTH, F1 - PLINTH, 0.8, 0.2)
	U.blk(lm, "Trim", CX, F1 - 0.5, ZF + 1.4, 11.8, 0.5, 3.0)
	LandmarkDetail.balustrade(lm, "Iron", Vector3(CX - 5.7, F1, ZF + 2.7), Vector3(CX + 5.7, F1, ZF + 2.7), 0.9, 2.8)
	E.portico(lm, "Trim", CX, ZF, 8.4, 4, F1, 8.3, 2.4, 1.9, "ionic", 0.45)
	# Behind the columns: tall arched window in the middle, windows beside.
	E.win(lm, "Trim", "Glass", Vector3(CX, F1 + 0.8, ZF), out, 1.9, 4.4, "arch")
	for s in [-1.0, 1.0]:
		E.win(lm, "Trim", "Glass", Vector3(CX + s * 2.8, F1 + 1.0, ZF), out, 1.4, 3.0, "plain")
		E.win(lm, "Trim", "Glass", Vector3(CX + s * 2.8, F2 + 1.2, ZF), out, 1.3, 2.4, "plain")
	E.win(lm, "Trim", "Glass", Vector3(CX, F2 + 1.2, ZF), out, 1.3, 2.4, "plain")

static func _roofs(lm: LandmarkMesh) -> void:
	# [x0, x1, z0, z1, rise, top]: the front range, the east and west bars.
	for r in [[-16.4, 16.3, 13.0, ZF, 2.6, 0.82], [-16.4, -5.0, -27.2, 13.0, 2.8, 0.2], [7.4, 15.4, -9.9, 13.0, 2.6, 0.2]]:
		var x0: float = r[0]
		var x1: float = r[1]
		var z0: float = r[2]
		var z1: float = r[3]
		U.hip(lm, "Roof", Vector3((x0 + x1) * 0.5, EAVE, (z0 + z1) * 0.5), x1 - x0 + 0.8, z1 - z0 + 0.8,
			float(r[4]), float(r[5]))
	for p in [Vector2(-10.0, 18.0), Vector2(10.0, 18.0), Vector2(-11.0, -10.0), Vector2(11.5, 4.0)]:
		U.blk(lm, "Wall", p.x, EAVE + 1.6, p.y, 1.5, 2.0, 1.5)
		U.blk(lm, "Trim", p.x, EAVE + 3.5, p.y, 1.8, 0.25, 1.8)
