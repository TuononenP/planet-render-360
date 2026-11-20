extends RefCounted

## Olympia Terminal (Olympiaterminaali, Jarl Eklund and Hilding Ekelund, 1952
## for the Helsinki Olympics), Laivasillankatu, South Harbour. The registry
## yaw (53.3) turns the model's +Z, the front, onto the south-west, the plaza
## and the Tahtitorninvuori side; +X runs south-east.
##
## From the Commons photos in visual-plan/refs/landmarks/olympia_terminal/:
## - the walls are clad in small ochre-orange glazed brick tiles, not yellow
##   render; windows are white-framed, small and horizontal, in two rows;
## - the tall south-east block carries a mono-pitch roof, high at the
##   north-west and falling to the south-east, in grey sheet metal with a
##   deep eave; the sign OLYMPIA / TERMINAALI / TERMINALEN is black letters
##   on the brick;
## - in front of it a grey concrete canopy slab at first-floor level on
##   thin white columns, with a white steel railing along its edge, over a
##   recessed ground-floor entrance;
## - the lower north-west wing has a flat roof, a glazed first-floor bistro
##   and a broad flight of granite steps, with white steel handrails, rising
##   from the plaza to the first floor;
## - a small annex at the south-east end.
##
## Measured: the outline (OSM way 327321393, 84.2 x 32.8 m, 4 levels) and the
## position, which the old registry point missed by 220 m. Estimated from the
## photos: the roof heights (14.0 m high edge, 11.2 m low edge, 8.0 m wing),
## the split between the tall block and the wing at x = -5, window sizes, the
## canopy depth and the stair size. The glazed skybridge to the ships and
## the rear wings seen in the aerial photo are not modelled.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "olympia_terminal", "name": "Olympia Terminal", "lat": 60.160771, "lon": 24.958833,
	"radius_m": 1500.0, "wiki_title": "Olympia Terminal", "height_m": 14.0, "clear_m": 46.0,
	"yaw_deg": 53.3, "kind": "Ferry terminal", "aliases": ["olympia terminal", "olympiaterminaali", "olympiaterminalen"]}

const X0 := -42.1
const X1 := 42.1
const XS := -5.0
const XE := 39.2
const Z0 := -16.3
const Z1 := 16.4
const ZT := 10.0
const WING_TOP := 8.0
const HIGH := 14.0
const LOW := 11.2
const CANOPY_Y := 4.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#C28A47", 2.5))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A9A59E", 3.0))
	lm.use("Roof", LandmarkMaterials.paint("#7D8185", 0.55, 0.5))
	lm.use("Glass", LandmarkMaterials.glass("#2E3C44"))
	lm.use("White", LandmarkMaterials.paint("#EEEEEA", 0.5, 0.3))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9A9288", 2.5))
	lm.use("Sign", LandmarkMaterials.paint("#1E2022", 0.6, 0.2))
	lm.use("Lamp", LandmarkMaterials.lit("#E4ECFF", 0.9))
	_blocks(lm)
	_front(lm)
	_stairs(lm)
	_rear(lm)
	lm.commit(model)

## Walls and roofs: the tall mono-pitch block, the flat wing, the annex.
static func _blocks(lm: LandmarkMesh) -> void:
	# Tall block, ground to roof, sloping along X.
	_mono(lm, XS, XE, Z0, ZT, 0.0, HIGH, LOW)
	# Lower north-west wing with a flat roof and a deep eave.
	U.blk(lm, "Brick", (X0 + XS) * 0.5, 0.0, (Z0 + 6.0) * 0.5, XS - X0, WING_TOP, 6.0 - Z0)
	U.blk(lm, "Concrete", (X0 + XS) * 0.5, WING_TOP, (Z0 + 6.0) * 0.5 + 0.2, XS - X0 + 0.8, 0.35, 6.0 - Z0 + 1.2)
	U.blk(lm, "Roof", (X0 + XS) * 0.5, WING_TOP + 0.35, (Z0 + 6.0) * 0.5 + 0.2, XS - X0 + 0.4, 0.12, 6.0 - Z0 + 0.8)
	# South-east annex.
	U.blk(lm, "Brick", (XE + X1) * 0.5, 0.0, (4.7 + Z1) * 0.5, X1 - XE, 6.0, Z1 - 4.7)
	U.blk(lm, "Concrete", (XE + X1) * 0.5, 6.0, (4.7 + Z1) * 0.5, X1 - XE + 0.4, 0.3, Z1 - 4.7 + 0.4)
	# Front part of the tall block, a ground floor stepping out under the canopy.
	U.blk(lm, "Brick", (XS + XE) * 0.5, 0.0, (ZT + Z1 - 3.4) * 0.5, XE - XS, CANOPY_Y, Z1 - 3.4 - ZT)

## Mono-pitch block: walls and a roof plane falling from h0 at x0 to h1 at x1.
static func _mono(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float, yb: float, h0: float, h1: float) -> void:
	var a := Vector3(x0, yb, z0)
	var b := Vector3(x1, yb, z0)
	var c := Vector3(x1, yb, z1)
	var d := Vector3(x0, yb, z1)
	var up0 := Vector3(0, h0, 0)
	var up1 := Vector3(0, h1, 0)
	lm.quad("Brick", b, a, a + up0, b + up1, Vector3(0, 0, -1))
	lm.quad("Brick", d, c, c + up1, d + up0, Vector3(0, 0, 1))
	lm.quad("Brick", a, d, d + up0, a + up0, Vector3(-1, 0, 0))
	lm.quad("Brick", c, b, b + up1, c + up1, Vector3(1, 0, 0))
	var n := Vector3(h0 - h1, x1 - x0, 0).normalized()
	var eave := 0.6
	lm.quad("Roof", a + up0 + Vector3(-eave, 0.0, -eave), d + up0 + Vector3(-eave, 0.0, eave),
		c + up1 + Vector3(eave, 0.0, eave), b + up1 + Vector3(eave, 0.0, -eave), n)
	# Fascia under the roof's edge.
	lm.box("Concrete", Vector3((x0 + x1) * 0.5, 0, (z0 + z1) * 0.5) + Vector3(0, (h0 + h1) * 0.5 - 0.15, 0), Vector3(x1 - x0 + 0.3, 0.3, z1 - z0 + 0.3), Basis(Vector3.BACK, atan2(h0 - h1, x1 - x0)), 0.0)

## The canopy, its columns and railing, the windows, the sign and the glazed
## bistro of the wing.
static func _front(lm: LandmarkMesh) -> void:
	var cz := ZT + (Z1 - ZT) * 0.5
	lm.box("Concrete", Vector3((XS + 30.0) * 0.5, CANOPY_Y + 0.15, cz + 1.5), Vector3(30.0 - XS, 0.3, Z1 - ZT + 3.0))
	for x: float in [-1.0, 8.0, 17.0, 26.0]:
		lm.beam("White", Vector3(x, 0.0, Z1 + 1.2), Vector3(x, CANOPY_Y, Z1 + 1.2), 0.3, 0.3, Vector3.BACK)
	var rail_n := int((30.0 - XS) / 2.2)
	for k in rail_n + 1:
		var x := XS + (30.0 - XS) * float(k) / float(rail_n)
		lm.beam("White", Vector3(x, CANOPY_Y + 0.3, Z1 + 1.55), Vector3(x, CANOPY_Y + 1.2, Z1 + 1.55), 0.05, 0.05, Vector3.BACK)
	lm.beam("White", Vector3(XS, CANOPY_Y + 1.2, Z1 + 1.55), Vector3(30.0, CANOPY_Y + 1.2, Z1 + 1.55), 0.06, 0.06, Vector3.UP)
	lm.beam("White", Vector3(XS, CANOPY_Y + 0.7, Z1 + 1.55), Vector3(30.0, CANOPY_Y + 0.7, Z1 + 1.55), 0.04, 0.04, Vector3.UP)
	# Ground-floor entrance glazing under the canopy.
	U.blk(lm, "Glass", 14.0, 0.2, Z1 - 3.4 + 0.02, 22.0, 3.0, 0.1)
	P.win_row(lm, "White", "Glass", Vector3(4.0, 0, Z1 - 3.4), Vector3(26.0, 0, Z1 - 3.4), Vector3(0, 0, 1), 0.5, 4, 3.0, 2.6, false, 0.15)
	# Two rows of small white-framed windows on the tall block, the sign above.
	P.win_row(lm, "White", "Glass", Vector3(4.0, 0, ZT), Vector3(30.0, 0, ZT), Vector3(0, 0, 1), 6.0, 5, 1.8, 1.2, false, 0.15)
	P.win_row(lm, "White", "Glass", Vector3(6.0, 0, ZT), Vector3(26.0, 0, ZT), Vector3(0, 0, 1), 8.6, 4, 1.8, 1.2, false, 0.15)
	lm.box("Sign", Vector3(10.0, 10.9, ZT + 0.1), Vector3(12.0, 0.8, 0.12))
	lm.box("Lamp", Vector3(23.0, 10.9, ZT + 0.1), Vector3(6.0, 0.35, 0.1))
	# Glazed first-floor bistro of the wing, and its brick return.
	lm.box("Glass", Vector3(-26.0, CANOPY_Y + 1.7, 6.05), Vector3(30.0, 3.4, 0.12))
	P.ribs(lm, "White", Vector3(-41.0, 0, 6.1), Vector3(-11.0, 0, 6.1), Vector3(0, 0, 1), CANOPY_Y, CANOPY_Y + 3.4, 2.4, 0.1, 0.1)

## The broad granite flight to the first floor, handrails either side.
static func _stairs(lm: LandmarkMesh) -> void:
	U.steps(lm, "Granite", Vector3(-26.0, 0, 6.0), Vector3.BACK, 26.0, 0.9, 0.35, 12)
	for x: float in [-39.2, -12.8]:
		lm.beam("White", Vector3(x, 1.0, 17.0), Vector3(x, 5.2, 6.0), 0.07, 0.07, Vector3.RIGHT)
		lm.beam("White", Vector3(x, 0.4, 17.0), Vector3(x, 4.6, 6.0), 0.05, 0.05, Vector3.RIGHT)
		lm.beam("White", Vector3(x, 0.0, 17.0), Vector3(x, 1.0, 17.0), 0.06, 0.06, Vector3.RIGHT)

## Window rows on the long north-east side and the north-west end.
static func _rear(lm: LandmarkMesh) -> void:
	P.win_row(lm, "White", "Glass", Vector3(-39.0, 0, Z0), Vector3(36.0, 0, Z0), Vector3(0, 0, -1), 2.2, 22, 1.8, 1.4, false, 0.15)
	P.win_row(lm, "White", "Glass", Vector3(-39.0, 0, Z0), Vector3(-6.0, 0, Z0), Vector3(0, 0, -1), 5.2, 14, 1.8, 1.4, false, 0.15)
	P.win_row(lm, "White", "Glass", Vector3(-6.0, 0, Z0), Vector3(36.0, 0, Z0), Vector3(0, 0, -1), 8.0, 16, 1.8, 1.4, false, 0.15)
	P.win_row(lm, "White", "Glass", Vector3(X0, 0, -12.0), Vector3(X0, 0, 12.0), Vector3(-1, 0, 0), 2.2, 6, 1.8, 1.4, false, 0.15)
	P.win_row(lm, "White", "Glass", Vector3(X0, 0, -12.0), Vector3(X0, 0, 12.0), Vector3(-1, 0, 0), 5.2, 6, 1.8, 1.4, false, 0.15)
