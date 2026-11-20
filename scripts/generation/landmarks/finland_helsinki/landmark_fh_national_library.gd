extends RefCounted

## National Library of Finland (the old University Library, Engel, 1845),
## Unioninkatu 36. Model origin at the centre of the OSM outline (way
## 122595247, 47 x 46 m), front +Z; registry yaw -93 turns the front east
## onto Unioninkatu.
##
## From the photos (visual-plan/refs/landmarks/national_library_of_finland/):
## - A 47 x 30 m block of pale yellow render on a granite plinth, its whole
##   front a giant Corinthian order: 18 supports at 2.6 m (ten free columns
##   across the centre, four engaged pilasters at each end), two rows of
##   framed windows between them, the wooden door in the middle bay and a
##   flight of granite steps; a plain entablature and cornice at 10.3-11.7 m,
##   a plain attic with a white Greek-key band at the top and two relief
##   groups over the cornice, then a flat dark roof with small pyramid lights.
## - The Dome Hall: a cream drum with arched windows in pairs under a pale
##   zinc dome with a yellow lantern (top at 23.4 m).
## - The Rotunda (Nyström, 1906): a semicircular book stack of radius 15 m
##   behind the block, tall arched windows, a lean-to roof and skylight.
##
## Measured: outline and bearing (OSM). Height: the photo, scaled by the 47 m
## front, gives 23.4 m; LoD2 reports 27.9 m 5 m from the centre, which this
## model does not reproduce (flagged in the sources doc). Counted: 18
## supports, two window rows, 17 bays. Estimated: heights of the attic and
## drum, Rotunda window count.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const E = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_empire.gd")

const ENTRY := {"type": "national_library_of_finland", "name": "National Library of Finland", "lat": 60.170336, "lon": 24.950266,
	"radius_m": 5000.0, "wiki_title": "National Library of Finland", "height_m": 24.0, "clear_m": 42.0,
	"clear_offsets_m": [[0.0, 6.0], [0.0, -14.0]],
	"yaw_deg": -93.0, "kind": "Library", "aliases": ["national library of finland", "kansalliskirjasto",
		"nationalbiblioteket helsingfors"]}

const X := 23.5
const ZF := 21.4
const ZB := -8.4
const PLINTH := 1.5
const ENT0 := 10.3
const CORNICE := 11.7
const ATTIC := 15.2
const COLS := 18

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E9D589", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F4F0E2", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8C8780", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#44494C", 3.0, 0.6, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2B3237"))
	lm.use("Zinc", LandmarkMaterials.pbr("sheet_metal", "#C9CDCB", 3.0, 0.45, 0.5))
	lm.use("Lantern", LandmarkMaterials.pbr("render", "#D9C477", 3.0))
	lm.use("Door", LandmarkMaterials.paint("#8A5A33", 0.6))
	_block(lm)
	_front(lm)
	_flanks(lm)
	_rotunda(lm)
	_dome(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-14.0, 3.0, ZF + 20.0), Vector3(-7.0, 9.0, ZF), 40.0, 0.8, 40.0, warm],
		[Vector3(14.0, 3.0, ZF + 20.0), Vector3(7.0, 9.0, ZF), 40.0, 0.8, 40.0, warm],
	])

static func _block(lm: LandmarkMesh) -> void:
	var zc := (ZF + ZB) * 0.5
	var d := ZF - ZB
	U.blk(lm, "Stone", 0.0, 0.0, zc, X * 2.0 + 0.5, PLINTH, d + 0.5)
	U.blk(lm, "Wall", 0.0, PLINTH, zc, X * 2.0, ATTIC - PLINTH, d)
	U.blk(lm, "Roof", 0.0, ATTIC, zc, X * 2.0 - 0.8, 0.4, d - 0.8)
	# Attic frieze band and the cornice round the block.
	for s in [-1.0, 1.0]:
		E.course(lm, "Trim", Vector2(-X, s * 0.0 + (ZF if s > 0.0 else ZB)), Vector2(X, (ZF if s > 0.0 else ZB)),
			Vector2(0, s), ATTIC - 0.7, 0.5, 0.12)
		E.course(lm, "Trim", Vector2(s * X, ZB), Vector2(s * X, ZF), Vector2(s, 0), ATTIC - 0.7, 0.5, 0.12)
		E.course(lm, "Trim", Vector2(s * X, ZB), Vector2(s * X, ZF), Vector2(s, 0), ENT0, 1.4, 0.5)
	E.course(lm, "Trim", Vector2(-X, ZB), Vector2(X, ZB), Vector2(0, -1), ENT0, 1.4, 0.5)
	# Four pyramid roof lights on the flat roof.
	for p in [Vector2(-8.0, 12.0), Vector2(8.0, 12.0), Vector2(-14.0, 0.0), Vector2(14.0, 0.0)]:
		U.blk(lm, "Roof", p.x, ATTIC + 0.4, p.y, 2.0, 0.5, 2.0)
		U.hip(lm, "Roof", Vector3(p.x, ATTIC + 0.9, p.y), 2.2, 2.2, 0.9, 0.2)

## The giant order, windows, door, steps, entablature and reliefs.
static func _front(lm: LandmarkMesh) -> void:
	var out := Vector3(0, 0, 1)
	var pitch := 2.59
	var x0 := -float(COLS - 1) * 0.5 * pitch
	var a := Vector3(x0, 0, ZF)
	var b := Vector3(-x0, 0, ZF)
	# Two rows of framed windows in the 17 bays; the middle bay holds the door.
	E.row(lm, "Trim", "Glass", a, b, out, PLINTH + 1.2, COLS - 1, 1.3, 2.0, "plain", [8])
	E.row(lm, "Trim", "Glass", a, b, out, PLINTH + 4.5, COLS - 1, 1.3, 2.7, "plain")
	var dx := (a.x + b.x) * 0.5 + pitch * 0.0
	U.blk(lm, "Trim", dx, PLINTH, ZF + 0.1, 1.9, 3.4, 0.2)
	U.blk(lm, "Door", dx, PLINTH, ZF + 0.22, 1.4, 2.9, 0.06)
	for i in COLS:
		var x := x0 + float(i) * pitch
		var free := i >= 4 and i < COLS - 4
		if free:
			LandmarkDetail.column(lm, "Trim", Vector3(x, PLINTH, ZF + 1.0), 0.5, ENT0 - PLINTH, "corinthian", 0, 12)
		else:
			E.pilaster(lm, "Trim", Vector3(x, 0, ZF), out, PLINTH, ENT0 - PLINTH, 1.0, 0.45)
	# Entablature across the whole front, projecting over the free columns.
	U.blk(lm, "Trim", 0.0, ENT0, ZF + 0.55, X * 2.0 + 1.0, CORNICE - ENT0, 1.1)
	U.blk(lm, "Trim", 0.0, ENT0, ZF + 1.0, float(COLS - 8) * pitch + 1.6, CORNICE - ENT0, 1.0)
	LandmarkDetail.cornice(lm, "Trim", Vector3(-X - 0.4, CORNICE - 0.1, ZF + 1.1), Vector3(X + 0.4, CORNICE - 0.1, ZF + 1.1),
		out, 0.7, true)
	U.steps(lm, "Stone", Vector3(0, 0, ZF + 1.6), out, float(COLS - 8) * pitch, 0.42, 0.15, 5)
	# Relief groups on the attic over the cornice and the Greek-key band.
	for sx in [-1.0, 1.0]:
		U.blk(lm, "Trim", sx * 15.0, CORNICE, ZF + 0.15, 4.0, 0.5, 0.5)
		U.blk(lm, "Trim", sx * 15.0, CORNICE + 0.5, ZF + 0.12, 3.2, 1.5, 0.3)
		lm.lathe("Trim", Vector3(sx * 15.0, CORNICE + 0.5, ZF + 0.3), U.ball(0.4), 10, 1.0, 1.4)
	E.course(lm, "Trim", Vector2(-X, ZF), Vector2(X, ZF), Vector2(0, 1), CORNICE + 0.3, 0.25, 0.08)

static func _flanks(lm: LandmarkMesh) -> void:
	var rows := [[PLINTH + 1.2, 1.3, 2.0, "plain"], [PLINTH + 4.5, 1.3, 2.7, "plain"]]
	for s in [-1.0, 1.0]:
		E.run(lm, "Trim", "Glass", Vector2(s * X, ZB), Vector2(s * X, ZF), Vector2(s, 0), 3.4, rows, 1.5)
	for s in [-1.0, 1.0]:
		E.run(lm, "Trim", "Glass", Vector2(s * X, ZB), Vector2(s * 15.4, ZB), Vector2(0, -1), 3.4, rows, 1.0)

## The semicircular Rotunda behind the block.
static func _rotunda(lm: LandmarkMesh) -> void:
	var rc := Vector3(0.0, 0.0, ZB)
	var r := 15.0
	lm.frustum("Stone", rc, r, r, PLINTH, 28)
	lm.frustum("Wall", rc + Vector3(0, PLINTH, 0), r - 0.3, r - 0.3, 10.4, 28)
	lm.frustum("Trim", rc + Vector3(0, 11.4, 0), r + 0.1, r + 0.1, 0.6, 28)
	lm.lathe("Roof", rc + Vector3(0, 12.0, 0), PackedVector2Array([Vector2(r + 0.2, 0), Vector2(8.0, 1.8)]), 28)
	lm.lathe("Glass", rc + Vector3(0, 13.8, 0), PackedVector2Array([Vector2(8.0, 0), Vector2(2.0, 0.9), Vector2(0.0, 1.0)]), 28)
	for i in 11:
		var an := PI * (1.07 + 0.86 * float(i) / 10.0)
		var o := Vector3(cos(an), 0, sin(an))
		LandmarkDetail.window(lm, "Trim", "Glass", rc + o * (r - 0.28) + Vector3(0, 6.6, 0), o, 1.4, 6.4, true, 0.2)
		var pa := an + PI * 0.045
		lm.box("Trim", rc + Vector3(cos(pa), 0, sin(pa)) * (r - 0.2) + Vector3(0, 6.6, 0), Vector3(0.6, 9.4, 0.3),
			Basis.looking_at(Vector3(cos(pa), 0, sin(pa))))

## The Dome Hall over the block's centre.
static func _dome(lm: LandmarkMesh) -> void:
	var dc := Vector3(0.0, ATTIC + 0.4, 5.0)
	lm.frustum("Wall", dc, 5.8, 5.8, 3.0, 32)
	lm.frustum("Trim", dc + Vector3(0, 3.0, 0), 6.1, 6.1, 0.4, 32)
	for i in 6:
		var an := PI * (0.2 + 0.6 * float(i) / 5.0) * 1.0
		var o := Vector3(cos(an), 0, sin(an))
		LandmarkDetail.window(lm, "Trim", "Glass", dc + o * 5.8 + Vector3(0, 1.5, 0), o, 1.2, 1.8, true, 0.15)
	lm.lathe("Zinc", dc + Vector3(0, 3.4, 0), U.dome_prof(5.9, 2.5), 32)
	lm.frustum("Lantern", dc + Vector3(0, 5.9, 0), 1.1, 1.1, 1.8, 12)
	lm.frustum("Trim", dc + Vector3(0, 7.7, 0), 1.3, 1.3, 0.25, 12)
