class_name LandmarkFhOtaniemi
extends RefCounted

## Otaniemi, true metres, extruded from OpenStreetMap outlines
## (LandmarkFhWestFootprints): Väre (Verstas, 2018), red-brown brick
## volumes of vertical piers and slot windows over the glazed metro-centre
## street level, glass pavilions on the roof; and Alvar Aalto's former
## university library (1970), now the Harald Herlin Learning Centre, red
## brick with long window bands under copper-clad roof lights. Aalto's
## other campus works: the water tower (1971), a twelve-sided board-marked
## concrete tank on twelve blade columns round a central shaft over a
## free-form office, and Otahalli (1952), the white sports hall with its
## clerestory band over lower office wings. Also the Otaniemi power plant,
## brick, with its 75 m steel chimney. Sources and estimates:
## docs/espoo-landmark-sources.md.

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

const VARE_M := 21.5
const HERLIN_M := 11.5
const WATER_TOWER_M := 58.0
## Bottom and rim of the tank (OSM building:part min_height and height).
const TANK_Y0 := 34.0
const TANK_Y1 := 57.0
const OTAHALLI_M := 16.5
const PLANT_M := 75.0

static func vare(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#2F3E46"))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8A4433", 3.0))
	lm.use("Roof", LandmarkMaterials.paint("#4F5253", 0.8))
	lm.use("Metal", LandmarkMaterials.paint("#7E8487", 0.5, 0.4))
	var poly := W.outline("vare")
	var street := 5.0
	var eave := 19.0
	lm.poly_prism("Glass", F.offset(poly, -0.6), 0.0, street)
	W.ribs(lm, "Brick", F.offset(poly, -0.6), 0.0, street, 7.0, 0.9, 0.6)
	lm.poly_prism("Brick", poly, street, eave)
	W.edge_windows(lm, "Glass", poly, street + 1.0, 3, 4.4, 1.3, 0.55, 3.4)
	W.ribs(lm, "Brick", poly, street, eave, 2.6, 0.4, 0.25)
	lm.poly_prism("Roof", F.offset(poly, -0.3), eave, eave + 0.1)
	var pavilion := F.offset(poly, -16.0)
	if pavilion.size() < 3:
		pavilion = F.offset(poly, -10.0)
	lm.poly_prism("Glass", pavilion, eave, VARE_M - 0.2)
	W.ribs(lm, "Metal", pavilion, eave, VARE_M - 0.2, 1.8, 0.1, 0.12)
	lm.poly_prism("Metal", F.offset(pavilion, 0.3), VARE_M - 0.2, VARE_M)
	lm.commit(model, "Vare_")

static func herlin(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#94442F", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E383C"))
	lm.use("Copper", LandmarkMaterials.paint("#5C8A77", 0.55, 0.5))
	lm.use("Roof", LandmarkMaterials.paint("#4F5253", 0.8))
	var poly := W.outline("harald_herlin_learning_centre")
	var eave := 9.5
	lm.poly_prism("Brick", poly, 0.0, eave)
	W.ribbons(lm, "Glass", poly, 1.0, 1.6, 2, 4.2)
	W.ribs(lm, "Brick", poly, 0.0, eave, 3.0, 0.45, 0.2)
	lm.poly_prism("Brick", F.offset(poly, 0.15), eave - 0.4, eave, false)
	lm.poly_prism("Roof", F.offset(poly, -0.2), eave, eave + 0.1)
	var lights := F.offset(poly, -8.0)
	lm.poly_prism("Copper", lights, eave, HERLIN_M)
	W.ribbons(lm, "Glass", lights, eave + 0.5, 1.0, 1, 1.0)
	lm.commit(model, "Harald_herlin_")

static func water_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#8C857A", 2.5))
	lm.use("Soffit", LandmarkMaterials.pbr("concrete", "#6E6961", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2E383C"))
	lm.use("Roof", LandmarkMaterials.paint("#55524F", 0.8))
	var tank := W.outline("otaniemi_water_tower")
	# Office under the tank: seven storeys with window bands.
	var office := W._poly(W.WATER_TOWER_OFFICE)
	lm.poly_prism("Concrete", office, 0.0, 28.0)
	W.ribbons(lm, "Glass", office, 2.0, 1.3, 7, 3.7)
	W.ribs(lm, "Concrete", office, 0.0, 28.0, 2.4, 0.18, 0.1)
	lm.frustum("Concrete", Vector3(0.0, 0.0, 0.0), 4.8, 4.8, TANK_Y0, 24)
	# Twelve blade columns from the ground run on up the tank as ribs.
	for k in 12:
		var dir := Vector2.from_angle(TAU * float(k) / 12.0)
		var c := dir * 16.8
		lm.box("Concrete", Vector3(c.x, TANK_Y1 * 0.5, c.y), Vector3(3.1, TANK_Y1, 0.7),
			Basis(Vector3.UP, -dir.angle()), 0.0)
	# The twelve-sided tank, board-marked, its dark soffit and a low roof.
	lm.poly_prism("Concrete", tank, TANK_Y0, TANK_Y1)
	W.ribbons(lm, "Concrete", tank, TANK_Y0 + 0.9, 0.12, 15, 1.5, 0.05)
	_underside(lm, "Soffit", F.offset(tank, -0.1), TANK_Y0)
	# Radial beams under the tank from the shaft out to each column.
	for k in 12:
		var dir := Vector2.from_angle(TAU * float(k) / 12.0)
		var a := Vector3(dir.x * 4.8, TANK_Y0 - 0.5, dir.y * 4.8)
		var b := Vector3(dir.x * 16.0, TANK_Y0 - 0.5, dir.y * 16.0)
		lm.beam("Soffit", a, b, 0.5, 0.9)
	lm.poly_prism("Roof", F.offset(tank, -1.0), TANK_Y1, WATER_TOWER_M)
	lm.commit(model, "Otaniemi_water_tower_")

## Downward-facing cap of `poly` at height y (seen from below).
static func _underside(lm: LandmarkMesh, key: String, poly: PackedVector2Array, y: float) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	for t in range(0, idx.size(), 3):
		var a := poly[idx[t]]
		var b := poly[idx[t + 1]]
		var c := poly[idx[t + 2]]
		lm.tri(key, Vector3(a.x, y, a.y), Vector3(c.x, y, c.y), Vector3(b.x, y, b.y),
			Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, a, c, b)

## White three-storey wings round the tall hall, its dark clerestory band
## under a low hipped roof.
static func otahalli(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#E6E4DD", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2C363A"))
	lm.use("Roof", LandmarkMaterials.paint("#5A5D5E", 0.8))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#6E6A64", 3.0))
	var poly := W.outline("otahalli")
	var wing := 10.5
	lm.poly_prism("Granite", F.offset(poly, 0.1), 0.0, 0.5)
	lm.poly_prism("White", poly, 0.5, wing)
	W.edge_windows(lm, "Glass", poly, 1.2, 3, 3.2, 2.6, 1.6, 1.6)
	lm.poly_prism("Roof", F.offset(poly, -0.2), wing, wing + 0.1)
	var hall := PackedVector2Array([Vector2(-37.0, -38.5), Vector2(-2.5, -38.5), Vector2(-2.5, 38.5),
		Vector2(-37.0, 38.5)])
	var eave := OTAHALLI_M - 1.8
	lm.poly_prism("White", hall, wing, eave)
	lm.poly_prism("Glass", F.offset(hall, 0.05), wing + 1.0, eave - 0.6, false)
	W.ribs(lm, "White", hall, wing + 1.0, eave - 0.6, 1.8, 0.25, 0.12)
	W.hip_rect(lm, "Roof", hall[0], hall[1], hall[2], hall[3], eave, OTAHALLI_M - eave)
	lm.commit(model, "Otahalli_")

## Brick plant hall with tall windows and its steel chimney.
static func power_plant(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8C4A36", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E383C"))
	lm.use("Steel", LandmarkMaterials.paint("#9A9EA0", 0.45, 0.6))
	lm.use("Roof", LandmarkMaterials.paint("#4F5253", 0.8))
	var poly := W.outlines("otaniemi_power_plant")[0]
	var eave := 14.0
	lm.poly_prism("Brick", poly, 0.0, eave)
	W.ribs(lm, "Brick", poly, 0.0, eave, 3.5, 0.6, 0.25)
	W.edge_windows(lm, "Glass", poly, 2.0, 1, 0.0, 3.5, 1.4, 9.0)
	lm.poly_prism("Roof", F.offset(poly, -0.2), eave, eave + 0.1)
	# Ventilated roof lantern along the hall.
	var lantern := F.offset(poly, -6.0)
	if lantern.size() >= 3:
		lm.poly_prism("Glass", lantern, eave + 0.1, eave + 1.6, false)
		W.ribs(lm, "Steel", lantern, eave + 0.1, eave + 1.6, 1.2, 0.1, 0.1)
		lm.poly_prism("Roof", F.offset(lantern, 0.3), eave + 1.6, eave + 1.8)
	var c := W.PLANT_CHIMNEY
	lm.frustum("Steel", Vector3(c.x, 0.0, c.y), W.PLANT_CHIMNEY_R, 1.8, PLANT_M - 2.0, 18)
	lm.frustum("Roof", Vector3(c.x, PLANT_M - 2.0, c.y), 1.9, 1.9, 2.0, 18)
	# Stiffening rings up the steel stack.
	for k in range(1, 9):
		var y := 8.0 * float(k)
		var r := lerpf(W.PLANT_CHIMNEY_R, 1.8, y / (PLANT_M - 2.0)) + 0.12
		lm.frustum("Roof", Vector3(c.x, y, c.y), r, r, 0.35, 18)
	lm.commit(model, "Otaniemi_power_plant_")
