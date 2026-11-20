extends RefCounted

## Uunisaari (Pohjoinen Uunisaari), the islet off Kaivopuisto with the
## Uunisaari restaurant and sauna. Frame: origin at the centre of the
## restaurant footprint (OSM way 26936589, 50.4 x 16.1 m), front +Z; the
## registry yaw 153 lays +X along the building's long axis.
##
## What the photographs show (visual-plan/refs/landmarks/uunisaari/): a
## two-storey red-brick hall of 1967 (building:colour #9c2626, gabled roof
## in grey-green standing-seam metal), eight tall white-framed windows in
## the long wall under the name in dark lettering, four arched dormers in
## the roof, a round window and an outside spiral stair with a balcony on
## the west gable end, a low brick annexe at the east end, tall chimneys.
##
## Measured from OSM: the footprint (a 50.4 x 10.8 m hall plus a
## 10.8 x 4.8 m rear annexe), orientation, and the island's real
## location (the old registry point lay 90 m north of it). Estimated: the
## wall height (5.9 m), roof rise (3.6 m), window sizes.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const K = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_g_kit.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "uunisaari", "name": "Uunisaari", "lat": 60.153125, "lon": 24.952625,
	"radius_m": 1500.0, "wiki_title": "Uunisaari", "height_m": 13.1, "clear_m": 34.0,
	"yaw_deg": 153.0, "kind": "Island", "aliases": ["uunisaari", "uunisaari island", "uunisaaren saari", "ugnsholmen"]}

const BASE := 2.0
const HL := 25.2
const HD := 5.4
const Z0 := 1.95
const WALL := 5.9
const RISE := 3.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("brick", "#9B4A38", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F1EEE4", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#6F6A63", 3.0))
	lm.use("Roof", LandmarkMaterials.paint("#7F8C86", 0.5, 0.55))
	lm.use("Window", LandmarkMaterials.glass("#2B3640"))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#8C7E78", 4.0))
	lm.use("Iron", LandmarkMaterials.paint("#26292B", 0.5, 0.5))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#A78A66", 1.2))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A8", 0.8))
	K.ledge(lm, "Rock", 36.0, 17.0, BASE)
	var y0 := BASE
	_hall(lm, y0)
	_annexe(lm, y0)
	_stair(lm, y0)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-12.0, 1.0, 16.0), Vector3(-10.0, 5.0, HD + Z0), 48.0, 0.8, 38.0, Color(1.0, 0.86, 0.66)],
		[Vector3(12.0, 1.0, 16.0), Vector3(10.0, 5.0, HD + Z0), 48.0, 0.8, 38.0, Color(1.0, 0.86, 0.66)]])

static func _hall(lm: LandmarkMesh, y0: float) -> void:
	U.blk(lm, "Granite", 0.0, y0, Z0, 2.0 * HL + 0.4, 0.6, 2.0 * HD + 0.4)
	U.blk(lm, "Wall", 0.0, y0 + 0.6, Z0, 2.0 * HL, WALL - 0.6, 2.0 * HD)
	U.blk(lm, "Trim", 0.0, y0 + WALL - 0.3, Z0, 2.0 * HL + 0.3, 0.3, 2.0 * HD + 0.3)
	# Roof with the name on the front wall below it.
	U.ridge_x(lm, "Roof", "Wall", Vector3(0.0, y0 + WALL, Z0), 2.0 * HL + 0.6, 2.0 * HD + 1.0, RISE, 0.0)
	# Eight tall windows along the front (+Z) and rear, a second row of
	# small ones on the rear.
	for s in [-1.0, 1.0]:
		K.row(lm, "Window", Vector3(-HL + 3.0, y0, Z0 + s * HD), Vector3(HL - 6.0, y0, Z0 + s * HD), Vector3(0, 0, s), 1.1, 8, 1.3, 3.2)
	# Lettering band: dark blocks reading as the name.
	for k in 9:
		U.blk(lm, "Iron", -9.0 + float(k) * 2.1, y0 + 4.6, Z0 + HD + 0.02, 0.9, 0.7, 0.05)
	# Four arched dormers in the front slope.
	for k in 4:
		var x := -11.0 + float(k) * 7.5
		U.blk(lm, "Roof", x, y0 + WALL + 0.9, Z0 + 2.6, 1.7, 1.1, 1.4)
		lm.frustum("Roof", Vector3(x, y0 + WALL + 1.9, Z0 + 2.6), 0.85, 0.85, 1.4, 8, 0.0, 1.0, 1.0)
		lm.disc("Window", Vector3(x, y0 + WALL + 1.2, Z0 + 3.31), Vector3(0, 0, 1), 0.5, 10)
	# End gables: round window west, door east.
	lm.disc("Window", Vector3(-HL - 0.03, y0 + 4.0, Z0), Vector3(-1, 0, 0), 0.45, 10)
	K.row(lm, "Window", Vector3(HL, y0, Z0 - 1.0), Vector3(HL, y0, Z0 + 1.0), Vector3(1, 0, 0), 0.0, 1, 1.4, 2.6, true)
	for x in [-6.0, 14.0]:
		U.blk(lm, "Wall", x, y0 + WALL + RISE - 1.0, Z0 - 1.0, 1.3, 2.4, 1.1)
		U.blk(lm, "Trim", x, y0 + WALL + RISE + 1.4, Z0 - 1.0, 1.6, 0.18, 1.4)

## The low annexe on the rear at the east end.
static func _annexe(lm: LandmarkMesh, y0: float) -> void:
	K.house(lm, "Wall", "Roof", 7.0, Z0 - HD - 2.4, y0, 10.8, 4.8, 4.4, 2.6, 3, 1, 1.0, 1.6, 1.0)

## The outside spiral stair and balcony at the west gable.
static func _stair(lm: LandmarkMesh, y0: float) -> void:
	var cx := -HL - 2.6
	var cz := Z0 + 2.0
	lm.frustum("Iron", Vector3(cx, y0, cz), 0.1, 0.1, 5.4, 6)
	for k in 14:
		var a := float(k) * 0.55
		var y := y0 + 0.3 + float(k) * 0.38
		lm.box("Iron", Vector3(cx + cos(a) * 0.9, y, cz + sin(a) * 0.9), Vector3(1.5, 0.06, 0.5), Basis(Vector3.UP, -a))
	U.blk(lm, "Iron", -HL - 1.4, y0 + 5.2, Z0 - 0.5, 2.2, 0.12, 2.6)
	lm.beam("Iron", Vector3(-HL - 2.5, y0 + 6.2, Z0 - 1.8), Vector3(-HL - 2.5, y0 + 6.2, Z0 + 0.8), 0.06, 0.06)
	lm.beam("Iron", Vector3(-HL - 2.5, y0 + 5.2, Z0 - 1.8), Vector3(-HL - 2.5, y0 + 6.2, Z0 - 1.8), 0.05, 0.05)
	lm.beam("Iron", Vector3(-HL - 2.5, y0 + 5.2, Z0 + 0.8), Vector3(-HL - 2.5, y0 + 6.2, Z0 + 0.8), 0.05, 0.05)
