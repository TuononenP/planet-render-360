extends RefCounted

## Klippan, the 1898 timber villa-restaurant on the islet Luoto in front
## of Kaivopuisto. Frame: origin at the centre of the footprint (OSM way
## 115475359, 39 x 28 m), the south-facing veranda front on +Z; registry
## yaw -15 lays +Z toward the south.
##
## What the photographs show (visual-plan/refs/landmarks/klippan_villa/):
## a white-painted timber villa on a stone plinth, steep roofs of red
## sheet metal with dormers, a tall round tower in the middle with a red
## bulbous cap and a long spire, a slim spire turret on the gabled west
## wing, a small onion turret on the east end, a long glazed veranda along
## the front and a cantilevered balcony on the gable.
##
## Measured from OSM: the footprint's size and orientation, and the
## island location (old registry point lay 60 m from the villa). Estimated
## from the photographs: floor heights (3.6 m + 3.2 m), roof rise,
## tower and spire heights, window counts, and the wing layout, which is
## simplified from the 31-vertex outline.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const K = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_g_kit.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "klippan_villa", "name": "Klippan", "lat": 60.159324, "lon": 24.965566,
	"radius_m": 1500.0, "wiki_title": "Luoto (island)", "height_m": 23.0, "clear_m": 24.0,
	"yaw_deg": -15.0, "kind": "Villa",
	"aliases": ["klippan", "klippan villa", "luodon huvila", "klippan helsinki"]}

const BASE := 2.5
const PLINTH := 1.1
const F1 := 3.7
const EAVE := 6.9

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("wood", "#F2EEE2", 2.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#FAF8F0", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#857D74", 3.0))
	lm.use("Roof", LandmarkMaterials.paint("#B04A3A", 0.55, 0.45))
	lm.use("Window", LandmarkMaterials.glass("#2B3640"))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#8C7E78", 4.0))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#A78A66", 1.2))
	K.ledge(lm, "Rock", 26.0, 20.0, BASE)
	var y0 := BASE
	_main(lm, y0)
	_west(lm, y0)
	_veranda(lm, y0)
	_east(lm, y0)
	_tower(lm, y0)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.0, 22.0), Vector3(0.0, 6.0, 8.0), 50.0, 0.9, 42.0, Color(1.0, 0.88, 0.7)],
		[Vector3(-16.0, 1.0, 20.0), Vector3(-12.0, 10.0, 5.0), 35.0, 0.7, 42.0, Color(1.0, 0.88, 0.7)]])

static func _box(lm: LandmarkMesh, y0: float, cx: float, cz: float, w: float, d: float, h: float) -> void:
	U.blk(lm, "Granite", cx, y0, cz, w + 0.5, PLINTH, d + 0.5)
	U.blk(lm, "Wall", cx, y0 + PLINTH, cz, w, h - PLINTH, d)

static func _faces(lm: LandmarkMesh, y0: float, cx: float, cz: float, w: float, d: float, y: float, rows: int,
		nx: int, nz: int) -> void:
	for s in [-1.0, 1.0]:
		for r in rows:
			K.row(lm, "Window", Vector3(cx - w * 0.5 + 1.5, y0, cz + s * d * 0.5), Vector3(cx + w * 0.5 - 1.5, y0, cz + s * d * 0.5),
				Vector3(0, 0, s), y + float(r) * 3.3, nx, 1.2, 1.9)
			K.row(lm, "Window", Vector3(cx + s * w * 0.5, y0, cz - d * 0.5 + 1.5), Vector3(cx + s * w * 0.5, y0, cz + d * 0.5 - 1.5),
				Vector3(s, 0, 0), y + float(r) * 3.3, nz, 1.2, 1.9)

## Main two-storey block with red hip roof and dormers.
static func _main(lm: LandmarkMesh, y0: float) -> void:
	_box(lm, y0, -2.0, -2.0, 21.0, 11.0, EAVE)
	U.blk(lm, "Trim", -2.0, y0 + EAVE - 0.35, -2.0, 21.4, 0.35, 11.4)
	U.blk(lm, "Trim", -2.0, y0 + F1, -2.0, 21.3, 0.18, 11.3)
	_faces(lm, y0, -2.0, -2.0, 21.0, 11.0, PLINTH + 0.9, 2, 6, 3)
	K.hip(lm, "Roof", -2.0, -2.0, y0 + EAVE, 21.0, 11.0, 4.8, 9.0, 0.7)
	for k in 3:
		var x := -8.0 + float(k) * 6.0
		U.blk(lm, "Wall", x, y0 + EAVE + 0.5, 3.2, 2.2, 1.9, 1.2)
		K.row(lm, "Window", Vector3(x, y0, 3.8), Vector3(x, y0, 3.8), Vector3(0, 0, 1), EAVE + 0.8, 1, 0.9, 1.3, false)
		K.hip(lm, "Roof", x, 3.2, y0 + EAVE + 2.4, 2.2, 1.2, 1.0, 0.0, 0.5)

## West wing: a gable facing the front, a balcony, a slim spire turret.
static func _west(lm: LandmarkMesh, y0: float) -> void:
	_box(lm, y0, -14.0, 1.0, 8.0, 15.0, EAVE)
	U.blk(lm, "Trim", -14.0, y0 + EAVE - 0.35, 1.0, 8.4, 0.35, 15.4)
	lm.gable("Roof", Vector3(-14.0, y0 + EAVE, 1.0), 8.0, 15.0, 5.2, Basis(), 0.5, "Wall")
	_faces(lm, y0, -14.0, 1.0, 8.0, 15.0, PLINTH + 0.9, 2, 2, 4)
	# Balcony on the gable.
	U.blk(lm, "Deck", -14.0, y0 + F1, 9.2, 6.0, 0.2, 1.4)
	lm.beam("Trim", Vector3(-17.0, y0 + F1 + 1.0, 9.9), Vector3(-11.0, y0 + F1 + 1.0, 9.9), 0.07, 0.07)
	for k in 9:
		var x := -17.0 + float(k) * 0.75
		lm.beam("Trim", Vector3(x, y0 + F1, 9.9), Vector3(x, y0 + F1 + 1.0, 9.9), 0.05, 0.05)
	# Slim spire turret on the front-left corner.
	K.turret(lm, "Wall", "Roof", -17.6, 8.2, y0 + F1, 1.1, EAVE - F1 + 1.0, 1.6, 5.5, 10)

## Long glazed veranda along the front of the main block.
static func _veranda(lm: LandmarkMesh, y0: float) -> void:
	U.blk(lm, "Granite", 3.0, y0, 5.3, 26.0, PLINTH, 3.6)
	U.blk(lm, "Wall", 3.0, y0 + PLINTH, 5.3, 25.4, 2.5, 3.2)
	K.row(lm, "Window", Vector3(-8.0, y0, 7.0), Vector3(14.0, y0, 7.0), Vector3(0, 0, 1), PLINTH + 0.2, 10, 1.7, 2.1, false)
	K.hip(lm, "Roof", 3.0, 5.3, y0 + PLINTH + 2.6, 26.0, 3.6, 1.0, 20.0, 0.6)

## East end: a lower hipped wing and a small onion turret.
static func _east(lm: LandmarkMesh, y0: float) -> void:
	_box(lm, y0, 15.0, 0.0, 8.0, 9.0, F1 + 1.2)
	K.hip(lm, "Roof", 15.0, 0.0, y0 + F1 + 1.2, 8.0, 9.0, 3.0, 2.0, 0.6)
	_faces(lm, y0, 15.0, 0.0, 8.0, 9.0, PLINTH + 0.8, 1, 2, 2)
	K.turret(lm, "Wall", "Roof", 18.6, 4.2, y0 + F1 + 0.6, 1.3, 2.0, 2.6, 2.6, 10)

## The tall round tower with the red bulbous cap.
static func _tower(lm: LandmarkMesh, y0: float) -> void:
	var cx := -1.0
	var cz := -3.0
	lm.frustum("Wall", Vector3(cx, y0 + EAVE - 0.5, cz), 2.3, 2.3, 5.0, 14)
	for f in 8:
		var a := TAU * float(f) / 8.0
		var out := Vector3(cos(a), 0, sin(a))
		FhP.win_row(lm, "Trim", "Window", Vector3(cx, y0, cz) + out * 2.3, Vector3(cx, y0, cz) + out * 2.3, out, y0 + EAVE + 1.2, 1, 0.7, 1.6, true, 0.08)
	lm.frustum("Trim", Vector3(cx, y0 + EAVE + 4.5, cz), 2.7, 2.7, 0.3, 14)
	var prof := PackedVector2Array([Vector2(2.9, 0), Vector2(2.4, 0.5), Vector2(2.7, 1.4), Vector2(2.3, 2.4), Vector2(1.4, 3.2),
		Vector2(0.9, 3.9), Vector2(1.2, 4.4), Vector2(0.9, 5.0), Vector2(0.35, 5.6), Vector2(0.1, 6.0)])
	lm.lathe("Roof", Vector3(cx, y0 + EAVE + 4.8, cz), prof, 14)
	lm.beam("Roof", Vector3(cx, y0 + EAVE + 10.8, cz), Vector3(cx, y0 + EAVE + 13.6, cz), 0.07, 0.07)
