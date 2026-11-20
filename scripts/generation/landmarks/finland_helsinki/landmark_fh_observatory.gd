extends RefCounted

## Helsinki University Observatory (Tahtitorni, Carl Ludvig Engel, 1834), on
## Tahtitorninvuori. Front +Z is the north, the open court side; the
## registry yaw (-179.7) turns the model onto OSM way 123812229 (67 x 42 m,
## two levels). The old registry point sat 190 m east of the building.
##
## From the Commons photos in visual-plan/refs/landmarks/helsinki_observatory/:
## - pale yellow render with white pilasters, cornices and window surrounds;
##   dark low-pitched sheet-metal roofs with black chimney stacks;
## - a two-storey main block with a shallow central projection, flanked by
##   two lower wings that run forward and end in pedimented fronts, making a
##   court open to the north (the U in the OSM outline);
## - over the middle of the main block a round white tower: a low round
##   base with a white balustrade round the roof terrace, a drum with eight
##   pilasters and four windows, a plain entablature, a low flat cap and
##   a mast;
## - a rear annex and, on the north side, a yellow wall with a rusticated
##   gate pavilion (two flanking blocks with doors and a big brown timber
##   gate between them under a dentil cornice).
##
## Measured: outline and position (OSM). Estimated from photographs: storey
## heights (eaves 9 m on the main block, 8 m on the wings), the drum
## (r 3.7 m, top 16.8 m), the mast to 21.0 m, the wall (2.6 m, 3 m forward of
## the wings) and window rhythm. LoD2 could not be read in this run, so
## the registry height_m of 21 m (to the mast tip) is an estimate.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "helsinki_observatory", "name": "Helsinki Observatory", "lat": 60.161955, "lon": 24.951683,
	"radius_m": 1500.0, "wiki_title": "Helsinki University Observatory", "height_m": 21.0, "clear_m": 45.0,
	"yaw_deg": -179.7, "kind": "Observatory", "aliases": ["helsinki observatory", "tähtitorni", "observatoriet helsingfors", "kaivopuisto observatory"]}

const EAVE := 9.0
const WING_EAVE := 8.0
const ZF := 5.8
const ZB := -9.4
const TOWER_Z := -2.0
const WALL_Z := 24.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E9DDA6", 3.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#F2F0E8", 2.0))
	lm.use("Roof", LandmarkMaterials.paint("#3F4347", 0.6, 0.5))
	lm.use("Glass", LandmarkMaterials.glass("#2B3338"))
	lm.use("Gate", LandmarkMaterials.pbr("wood", "#5A4632", 1.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#6A6862", 2.5))
	_main_block(lm)
	_wings(lm)
	_tower(lm)
	_gate(lm)
	lm.commit(model)
	# Night: the court front and the tower are lit from the forecourt.
	var warm := Color(1.0, 0.94, 0.82)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-10.0, 1.0, 26.0), Vector3(0.0, 8.0, 2.0), 40.0, 1.0, 80.0, warm],
		[Vector3(10.0, 1.0, 26.0), Vector3(0.0, 8.0, 2.0), 40.0, 1.0, 80.0, warm],
	])

## The two-storey main block, its projection and pilasters, windows, roof.
static func _main_block(lm: LandmarkMesh) -> void:
	var x0 := -25.2
	var x1 := 25.0
	U.blk(lm, "Stone", (x0 + x1) * 0.5, 0.0, (ZB + ZF) * 0.5, x1 - x0 + 0.4, 1.0, ZF - ZB + 0.4)
	U.blk(lm, "Wall", (x0 + x1) * 0.5, 1.0, (ZB + ZF) * 0.5, x1 - x0, EAVE - 1.0, ZF - ZB)
	# Central projection, 22.6 m wide, 1 m proud, with pilasters.
	U.blk(lm, "Wall", -0.7, 1.0, ZF + 0.5, 22.6, EAVE - 1.0, 1.0)
	for k in 7:
		var x := -12.0 + 22.6 * float(k) / 6.0
		U.blk(lm, "White", x, 1.0, ZF + 1.1, 0.9, EAVE - 2.4, 0.3)
		U.blk(lm, "White", x, EAVE - 1.4, ZF + 1.15, 1.3, 0.4, 0.4)
	lm.box("White", Vector3(-0.7, EAVE - 0.5, ZF + 0.9), Vector3(23.2, 1.0, 1.7))
	lm.box("White", Vector3(0.0, EAVE - 0.5, (ZB + ZF) * 0.5), Vector3(x1 - x0 + 0.8, 1.0, ZF - ZB + 0.8))
	U.hip(lm, "Roof", Vector3(0.0, EAVE, (ZB + ZF) * 0.5), x1 - x0 + 1.4, ZF - ZB + 1.4, 1.6, 0.6)
	# Two rows of framed windows between the pilasters and on the side walls.
	var out := Vector3(0, 0, 1)
	P.win_row(lm, "White", "Glass", Vector3(-10.5, 0, ZF + 1.0), Vector3(9.1, 0, ZF + 1.0), out, 1.8, 6, 1.2, 2.1, false, 0.2)
	P.win_row(lm, "White", "Glass", Vector3(-10.5, 0, ZF + 1.0), Vector3(9.1, 0, ZF + 1.0), out, 5.2, 6, 1.2, 2.3, false, 0.2)
	for run in [[-24.0, -13.5], [12.8, 24.0]]:
		P.win_row(lm, "White", "Glass", Vector3(run[0], 0, ZF), Vector3(run[1], 0, ZF), out, 1.8, 3, 1.2, 2.1, false, 0.2)
		P.win_row(lm, "White", "Glass", Vector3(run[0], 0, ZF), Vector3(run[1], 0, ZF), out, 5.2, 3, 1.2, 2.3, false, 0.2)
	P.win_row(lm, "White", "Glass", Vector3(-24.0, 0, ZB), Vector3(24.0, 0, ZB), Vector3(0, 0, -1), 1.8, 14, 1.2, 2.1, false, 0.2)
	P.win_row(lm, "White", "Glass", Vector3(-24.0, 0, ZB), Vector3(24.0, 0, ZB), Vector3(0, 0, -1), 5.2, 14, 1.2, 2.3, false, 0.2)
	# Chimney stacks on the ridge, and the rear annex.
	for x: float in [-20.0, -9.0, 9.0, 20.0]:
		U.blk(lm, "Roof", x, EAVE + 1.0, -1.0, 1.4, 2.4, 1.4)
	U.blk(lm, "Wall", 0.0, 0.0, -16.0, 22.6, 6.4, 6.6)
	U.hip(lm, "Roof", Vector3(0.0, 6.4, -16.0), 23.4, 7.4, 1.3, 0.5)
	U.blk(lm, "Wall", -0.3, 0.0, -18.6, 9.5, 7.0, 5.0)
	U.hip(lm, "Roof", Vector3(-0.3, 7.0, -18.6), 10.3, 5.8, 1.4, 0.4)

## The wings, each ending in a pedimented front with pilasters.
static func _wings(lm: LandmarkMesh) -> void:
	for s: float in [-1.0, 1.0]:
		var cx := s * 29.4
		var z0 := -10.0
		var z1 := 21.0
		U.blk(lm, "Stone", cx, 0.0, (z0 + z1) * 0.5, 8.8, 1.0, z1 - z0 + 0.4)
		U.blk(lm, "Wall", cx, 1.0, (z0 + z1) * 0.5, 8.4, WING_EAVE - 1.0, z1 - z0)
		U.blk(lm, "White", cx, WING_EAVE - 0.5, (z0 + z1) * 0.5, 9.0, 0.8, z1 - z0 + 0.6)
		# The gabled roof ends in a pediment on the north front.
		U.ridge_z(lm, "Roof", "White", Vector3(cx, WING_EAVE, (z0 + z1) * 0.5), 8.6, z1 - z0 + 0.6, 1.9, 0.2)
		for x: float in [-3.6, 3.6]:
			U.blk(lm, "White", cx + x, 1.0, z1 + 0.15, 0.8, WING_EAVE - 1.6, 0.3)
		P.win_row(lm, "White", "Glass", Vector3(cx - 2.0, 0, z1 + 0.15), Vector3(cx + 2.0, 0, z1 + 0.15), Vector3(0, 0, 1), 1.8, 2, 1.2, 2.1, false, 0.15)
		P.win_row(lm, "White", "Glass", Vector3(cx - 2.0, 0, z1 + 0.15), Vector3(cx + 2.0, 0, z1 + 0.15), Vector3(0, 0, 1), 5.0, 2, 1.2, 2.0, false, 0.15)
		# Inner court side and outer side: a row of windows.
		P.win_row(lm, "White", "Glass", Vector3(cx - s * 4.2, 0, 7.5), Vector3(cx - s * 4.2, 0, 19.0), Vector3(-s, 0, 0), 1.8, 4, 1.2, 2.1, false, 0.15)
		P.win_row(lm, "White", "Glass", Vector3(cx + s * 4.2, 0, 7.5), Vector3(cx + s * 4.2, 0, 19.0), Vector3(s, 0, 0), 1.8, 4, 1.2, 2.1, false, 0.15)

## The round tower: base, balustrade, drum with pilasters, cap and mast.
static func _tower(lm: LandmarkMesh) -> void:
	var c := Vector3(0, EAVE, TOWER_Z)
	lm.frustum("Wall", c, 5.8, 5.8, 1.7, 20)
	lm.frustum("White", c + Vector3(0, 1.7, 0), 6.0, 6.0, 0.25, 20)
	# Balustrade: a rail and posts round the terrace.
	var posts := 48
	for i in posts:
		var a := TAU * float(i) / float(posts)
		var p := c + Vector3(cos(a), 0, sin(a)) * 5.7 + Vector3(0, 1.95, 0)
		lm.box("White", p + Vector3(0, 0.45, 0), Vector3(0.16, 0.9, 0.16))
	for i in 32:
		var a := TAU * float(i) / 32.0
		var b := TAU * float(i + 1) / 32.0
		lm.beam("White", c + Vector3(cos(a), 0, sin(a)) * 5.7 + Vector3(0, 2.9, 0), c + Vector3(cos(b), 0, sin(b)) * 5.7 + Vector3(0, 2.9, 0), 0.22, 0.2, Vector3.UP)
	var d0 := c + Vector3(0, 1.95, 0)
	lm.frustum("Wall", d0, 3.7, 3.7, 5.0, 24)
	lm.frustum("White", d0, 3.9, 3.9, 0.35, 24)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		var dir := Vector3(sin(a), 0, cos(a))
		lm.box("White", d0 + dir * 3.75 + Vector3(0, 2.6, 0), Vector3(0.6, 4.6, 0.3), Basis(Vector3.UP, a), 0.0)
	for k in 4:
		var a := TAU * float(k) / 4.0
		var dir := Vector3(sin(a), 0, cos(a))
		P.win_row(lm, "White", "Glass", d0 + dir * 3.72 + Vector3(0, 0, 0), d0 + dir * 3.72, dir, 1.4, 1, 1.0, 2.0, false, 0.14)
	var top := d0 + Vector3(0, 5.0, 0)
	lm.frustum("White", top, 4.1, 4.1, 0.8, 24)
	lm.frustum("White", top + Vector3(0, 0.8, 0), 3.9, 3.4, 0.25, 24)
	lm.beam("White", top + Vector3(0, 1.0, 0), top + Vector3(0, 5.0, 0), 0.1)

## The yellow forecourt wall with its rusticated gate pavilion.
static func _gate(lm: LandmarkMesh) -> void:
	var z := WALL_Z
	for run in [[-34.0, -6.4], [6.4, 34.0]]:
		var a: float = run[0]
		var b: float = run[1]
		U.blk(lm, "Wall", (a + b) * 0.5, 0.0, z, b - a, 2.6, 0.5)
		U.blk(lm, "White", (a + b) * 0.5, 2.6, z, b - a + 0.1, 0.2, 0.7)
	for s: float in [-1.0, 1.0]:
		var x := s * 4.6
		U.blk(lm, "Wall", x, 0.0, z, 3.4, 4.0, 1.4)
		for y: float in [0.9, 1.8, 2.7, 3.5]:
			lm.box("White", Vector3(x, y, z + 0.72), Vector3(3.3, 0.04, 0.04))
		U.blk(lm, "White", x, 4.0, z, 4.0, 0.7, 1.8)
		lm.box("Gate", Vector3(x, 1.1, z + 0.72), Vector3(1.0, 2.2, 0.06))
		for k in 4:
			lm.box("White", Vector3(x - 1.2 + 0.8 * float(k), 3.75, z + 0.76), Vector3(0.2, 0.22, 0.06))
	lm.box("Gate", Vector3(0, 1.6, z), Vector3(5.8, 3.2, 0.15))
	lm.box("White", Vector3(0, 3.35, z), Vector3(5.9, 0.25, 0.9))
