extends RefCounted

## The Old Church (Vanha kirkko, C. L. Engel, 1826), Lönnrotinkatu and the Old
## Church Park. Origin at the OSM outline's bounding-box centre, front +Z toward
## the south door (registry yaw -35 turns the grid onto the streets).
##
## Measured: the outline (way 123525345, simplified to 1 m): a 35.7 x 19.7 m
## body with a 5.4 m gabled arm at each end and a 3.7 m pedimented porch on
## the +Z side; the body height 16.4 m (OSM part) and the LoD2 top 23.4 m
## (lantern and cross). The registry point lay 135 m from the church.
## Estimated from visual-plan/refs/landmarks/old_church_helsinki/: the pale
## grey painted timber (horizontal board walls), white pilasters and
## cornices, the pink-grey granite plinth, tall many-paned windows between the
## pilasters, the brown double doors with five granite steps, the low
## dark sheet roof, and above the crossing the square white lantern base, the
## open drum of eight columns, the green copper dome, gilt ball and cross.
## Eaves, pilaster spacing and window sizes are approximate.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "old_church_helsinki", "name": "Old Church, Helsinki", "lat": 60.166398, "lon": 24.939304,
	"radius_m": 1500.0, "wiki_title": "Old Church, Helsinki", "height_m": 24.0, "clear_m": 24.0,
	"yaw_deg": -35.0, "kind": "Church", "aliases": ["old church, helsinki", "vanha kirkko", "gamla kyrkan helsingfors"]}

const X0 := -17.8
const X1 := 17.9
const Z0 := -11.7
const Z1 := 8.0
const ARM := 23.2
const PORCH_Z := 11.7
const EAVE := 10.5
const PLINTH := 1.7

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D3D5CE", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#EEF0EA", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9E9690", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#4A4F52", 3.0, 0.55, 0.3))
	lm.use("Dome", LandmarkMaterials.pbr("copper", "#7FA592", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2B3236"))
	lm.use("Door", LandmarkMaterials.pbr("wood", "#6B4527", 1.5))
	lm.use("Gold", LandmarkMaterials.gold())
	var cx := 0.5 * (X0 + X1)
	var cz := 0.5 * (Z0 + Z1)
	# Body, the two end arms and the south porch: plinth, board walls, cornice.
	_mass(lm, X0, X1, Z0, Z1)
	_mass(lm, -ARM, X0 + 0.01, -7.5, 4.2)
	_mass(lm, X1 - 0.01, ARM, -7.5, 4.2)
	_mass(lm, -8.0, 8.3, Z1 - 0.01, PORCH_Z)
	# Low hipped roof over the body, pedimented gables on the arms and porch.
	U.hip(lm, "Roof", Vector3(cx, EAVE + 0.4, cz), X1 - X0 + 1.0, Z1 - Z0 + 1.0, 4.4, 0.30)
	for s in [-1.0, 1.0]:
		var ax: float = s * 0.5 * (X1 + ARM)
		U.ridge_x(lm, "Roof", "Wall", Vector3(ax, EAVE + 0.4, -1.65), 5.4 + 0.6, 11.7 + 0.6, 2.3, 0.3)
	U.ridge_z(lm, "Roof", "Wall", Vector3(0.15, EAVE + 0.4, 0.5 * (Z1 + PORCH_Z)), 16.3 + 0.6, 3.7 + 0.6, 2.8, 0.3)
	# Pilasters and tall many-paned windows between them on every face.
	var south := Vector3(0, 0, 1)
	var north := Vector3(0, 0, -1)
	P.strips(lm, "Trim", Vector3(X0, 0, Z0), Vector3(X1, 0, Z0), north, PLINTH, EAVE - PLINTH, 8, 0.8, 0.3)
	P.win_row(lm, "Trim", "Glass", Vector3(X1, 0, Z0), Vector3(X0, 0, Z0), north, 2.2, 7, 2.1, 5.8)
	P.strips(lm, "Trim", Vector3(X0, 0, Z1), Vector3(-8.0, 0, Z1), south, PLINTH, EAVE - PLINTH, 3, 0.8, 0.3)
	P.strips(lm, "Trim", Vector3(8.3, 0, Z1), Vector3(X1, 0, Z1), south, PLINTH, EAVE - PLINTH, 3, 0.8, 0.3)
	P.win_row(lm, "Trim", "Glass", Vector3(X0, 0, Z1), Vector3(-8.0, 0, Z1), south, 2.2, 2, 2.1, 5.8)
	P.win_row(lm, "Trim", "Glass", Vector3(8.3, 0, Z1), Vector3(X1, 0, Z1), south, 2.2, 2, 2.1, 5.8)
	for s in [-1.0, 1.0]:
		var wx: float = s * X1
		var out := Vector3(s, 0, 0)
		P.win_row(lm, "Trim", "Glass", Vector3(wx, 0, Z0 + 0.8), Vector3(wx, 0, -8.0), out, 2.2, 1, 2.1, 5.8)
		P.win_row(lm, "Trim", "Glass", Vector3(wx, 0, 4.7), Vector3(wx, 0, Z1 - 0.5), out, 2.2, 1, 2.1, 5.8)
		var ex: float = ARM * s
		P.win_row(lm, "Trim", "Glass", Vector3(ex, 0, -6.0), Vector3(ex, 0, 2.7), out, 2.2, 2, 2.1, 5.8)
		P.strips(lm, "Trim", Vector3(ex, 0, -7.2), Vector3(ex, 0, 3.9), out, PLINTH, EAVE - PLINTH, 3, 0.8, 0.3)
	# The south door: tall window over brown double doors, five granite steps.
	P.win_row(lm, "Trim", "Glass", Vector3(-3.0, 0, PORCH_Z), Vector3(3.0, 0, PORCH_Z), Vector3(0, 0, 1), 5.6, 1, 4.6, 3.8)
	lm.box("Door", Vector3(0.15, PLINTH + 2.0, PORCH_Z + 0.08), Vector3(3.4, 4.0, 0.2), Basis(), 0.0)
	U.steps(lm, "Stone", Vector3(0.15, 0, PORCH_Z), Vector3(0, 0, 1), 7.0, 0.5, 0.3, 5)
	# Crossing lantern: white square base with small pediments, eight-column
	# open drum, green dome, gilt ball and cross.
	var lc := Vector3(cx, 0, cz)
	var h0 := EAVE + 4.4
	U.blk(lm, "Trim", lc.x, h0 - 0.4, lc.z, 7.6, 2.8, 7.6)
	for k in 4:
		var d := Basis(Vector3.UP, PI * 0.5 * float(k)) * Vector3(0, 0, 1)
		lm.gable("Trim", lc + d * 3.9 + Vector3(0, h0 + 2.4, 0), 5.2, 0.5, 1.3, Basis(Vector3.UP, PI * 0.5 * float(k)), 0.1, "Trim")
	var dh := h0 + 2.4
	lm.frustum("Trim", lc + Vector3(0, dh, 0), 3.4, 3.4, 0.4, 16)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.frustum("Trim", lc + Vector3(cos(a) * 2.8, dh + 0.4, sin(a) * 2.8), 0.26, 0.22, 2.9, 8)
	lm.frustum("Glass", lc + Vector3(0, dh + 0.4, 0), 2.5, 2.5, 2.9, 12)
	lm.frustum("Trim", lc + Vector3(0, dh + 3.3, 0), 3.4, 3.2, 0.5, 16)
	lm.lathe("Dome", lc + Vector3(0, dh + 3.8, 0), U.dome_prof(3.1, 2.3, 8), 16)
	lm.lathe("Gold", lc + Vector3(0, dh + 6.1, 0), U.ball(0.25), 8)
	U.cross(lm, "Gold", lc + Vector3(0, dh + 6.55, 0), 1.8)
	lm.commit(model)

## One walled volume between the given x and z bounds: granite plinth, board
## walls to the eave and a white cornice.
static func _mass(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float) -> void:
	var cx := 0.5 * (x0 + x1)
	var cz := 0.5 * (z0 + z1)
	U.blk(lm, "Stone", cx, 0.0, cz, x1 - x0 + 0.3, PLINTH, z1 - z0 + 0.3)
	U.blk(lm, "Wall", cx, PLINTH, cz, x1 - x0, EAVE - PLINTH, z1 - z0)
	U.blk(lm, "Trim", cx, EAVE - 0.55, cz, x1 - x0 + 0.6, 0.55, z1 - z0 + 0.6)
