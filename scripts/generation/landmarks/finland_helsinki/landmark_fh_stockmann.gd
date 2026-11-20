extends RefCounted

## Stockmann department store (Sigurd Frosterus, 1930), Aleksanterinkatu 52,
## origin at the OSM outline's bounding-box centre, front +Z toward
## Aleksanterinkatu (registry yaw 177 turns +Z onto the north side).
##
## Measured: the outline (way 122595241, simplified to 1 m) with its four
## sides, Keskuskatu on the east, the short south end, the long slanted
## Mannerheimintie front on the west and the diagonal corner front between
## it and Aleksanterinkatu; the right-angled corner carrying the vertical
## STOCKMANN lettering; the overall height 39 m (OSM `height`), the mansard
## part 35.5 m (OSM building:part, brick).
## Estimated from the photos in visual-plan/refs/landmarks/stockmann_helsinki/
## (bay pitch, storey heights, roof inset, dormer spacing, canopy size, the
## Three Smiths group beside the corner): the dark red-brown clinker brick,
## a glazed shop storey, five storeys of full-height brick piers with
## recessed window bays, two bands of small square windows under projecting
## cornices, then a dark zinc mansard with a row of dormers and a glazed
## lantern. The 1989 glass annexe and the interior are not modelled.

const D = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_d_kit.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "stockmann_helsinki", "name": "Stockmann Helsinki", "lat": 60.168233, "lon": 24.941960,
	"radius_m": 5000.0, "wiki_title": "Stockmann, Helsinki centre", "height_m": 39.0, "clear_m": 54.0,
	"yaw_deg": 177.0, "kind": "Department store", "aliases": ["stockmann helsinki", "stockmann department store helsinki", "helsingin keskustan stockmann"]}

const OUTLINE := [-45.2, 54.9, -44.8, -55.0, -11.8, -54.7, 45.2, 30.9, 14.6, 51.1, 3.2, 52.4, -1.3, 55.1]
## Ground shop storey, top of the piers, the two cornices and the roof.
const SHOP := 5.4
const PIERS := 24.6
const BAND1 := 27.0
const BAND2 := 29.8
const EAVE := 30.7
const RIDGE := 36.0
const TOP := 39.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("brick", "#6A392C", 2.4))
	lm.use("Pier", LandmarkMaterials.pbr("brick", "#5C3126", 2.4))
	lm.use("Trim", LandmarkMaterials.pbr("brick", "#7A4A3A", 2.4))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#4F4A46", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2B3236"))
	lm.use("Shop", LandmarkMaterials.glass("#3E4A50"))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#3E4245", 3.0, 0.5, 0.3))
	lm.use("Frame", LandmarkMaterials.paint("#E4E1D6", 0.6, 0.0))
	lm.use("Canopy", LandmarkMaterials.paint("#26282A", 0.5, 0.3))
	lm.use("Statue", LandmarkMaterials.pbr("copper", "#5E7F6A", 2.0, 0.5, 0.3))
	lm.use("Lamp", LandmarkMaterials.lit("#F2F0E6", 0.5))
	var p := D.poly(OUTLINE)
	var cen := Vector2.ZERO
	for q in p:
		cen += q
	cen /= float(p.size())
	# The solid body in three lifts so each cornice can step out.
	lm.poly_prism("Wall", p, 0.0, EAVE, false)
	D.slab(lm, "Stone", p, 0.25, 0.0, 0.5)
	D.slab(lm, "Trim", p, 0.45, PIERS, 0.8)
	D.slab(lm, "Trim", p, 0.5, BAND1, 0.75)
	D.slab(lm, "Trim", p, 0.7, BAND2, 0.9)
	var runs := D.runs(p)
	for run in runs:
		var a: Vector3 = run[0]
		var b: Vector3 = run[1]
		var o: Vector3 = run[2]
		var run_len := a.distance_to(b)
		if run_len < 4.0:
			continue
		# Shop storey: tall dark glazing between brick piers.
		D.pier_run(lm, "Wall", "Pier", "Shop", a, b, o, 0.5, SHOP, 3.6, 0.9, 0.15, Vector2(2.4, 3.9), 0.5, 4.6, 1, 0.3)
		# Five storeys of recessed window bays under full-height piers.
		D.pier_run(lm, "Wall", "Pier", "Glass", a, b, o, SHOP, PIERS, 3.6, 1.5, 0.5, Vector2(1.9, 3.3), 0.3, 3.84, 5, 0.4)
		# Two bands of small square windows, two to a bay.
		D.pier_run(lm, "Wall", "Trim", "Glass", a, b, o, PIERS + 0.8, BAND1, 1.8, 0.0, 0.0, Vector2(0.9, 1.0), 0.45, 1.0, 1, 0.2)
		D.pier_run(lm, "Wall", "Trim", "Glass", a, b, o, BAND1 + 0.75, BAND2, 1.8, 0.0, 0.0, Vector2(0.9, 1.1), 0.5, 1.0, 1, 0.2)
	# Dark zinc mansard over the whole block, dormers along its foot.
	var foot := D.grow(p, 0.7)
	FhP.slope_roof(lm, "Roof", foot, cen, 0.82, EAVE, RIDGE)
	for run in runs:
		var a: Vector3 = run[0]
		var b: Vector3 = run[1]
		if a.distance_to(b) > 8.0:
			D.dormers(lm, "Wall", "Roof", "Glass", a, b, run[2], EAVE, 3.6, 0.7, 1.3, 1.5, 1.2)
	# Glazed lantern on the roof deck.
	FhU.blk(lm, "Glass", cen.x + 4.0, RIDGE, cen.y - 6.0, 9.0, TOP - RIDGE - 0.4, 6.0)
	FhU.blk(lm, "Roof", cen.x + 4.0, TOP - 0.4, cen.y - 6.0, 9.6, 0.4, 6.6)
	_corner(lm)
	_entrance(lm)
	_smiths(lm)
	lm.commit(model)

## The vertical STOCKMANN lettering on both faces of the right-angled corner
## where the Mannerheimintie front meets the diagonal front.
static func _corner(lm: LandmarkMesh) -> void:
	var c := Vector3(45.2, 0, 30.9)
	var f1 := Vector3(-11.8 - 45.2, 0, -54.7 - 30.9).normalized()
	var f2 := Vector3(14.6 - 45.2, 0, 51.1 - 30.9).normalized()
	var o1 := Vector3(f1.z, 0, -f1.x)
	var o2 := Vector3(-f2.z, 0, f2.x)
	if o1.dot(Vector3(f2.x, 0, f2.z)) > 0.0:
		o1 = -o1
	if o2.dot(Vector3(f1.x, 0, f1.z)) > 0.0:
		o2 = -o2
	D.letters(lm, "Lamp", c + f1 * 1.9 + o1 * 0.9, o1, 6.6, 23.0, 9, 1.3, 0.5)
	D.letters(lm, "Lamp", c + f2 * 1.9 + o2 * 0.9, o2, 6.6, 23.0, 9, 1.3, 0.5)

## The Aleksanterinkatu entrance: a black canopy with the lit name over it
## and the pendulum clock on its pillar.
static func _entrance(lm: LandmarkMesh) -> void:
	var z := 55.0
	FhU.blk(lm, "Canopy", -24.0, 5.6, z + 2.2, 15.0, 0.9, 4.6)
	FhU.blk(lm, "Lamp", -24.0, 6.5, z + 1.2, 12.5, 1.4, 0.4)
	for sx in [-1.0, 1.0]:
		FhU.blk(lm, "Stone", -24.0 + sx * 7.0, 0.0, z + 3.6, 1.2, 5.6, 1.2)
	lm.disc("Frame", Vector3(-16.4, 4.0, z + 4.25), Vector3.BACK, 0.45, 24)

## The Three Smiths (Felix Nylund, 1932): three bronze figures round an anvil
## on a granite plinth, outside the diagonal corner front.
static func _smiths(lm: LandmarkMesh) -> void:
	var c := Vector3(37.5, 0.0, 52.5)
	FhU.blk(lm, "Stone", c.x, 0.0, c.z, 3.2, 1.1, 3.2)
	for k in 3:
		var a := TAU * float(k) / 3.0
		var q := c + Vector3(cos(a) * 0.9, 1.1, sin(a) * 0.9)
		lm.frustum("Statue", q, 0.32, 0.2, 1.6, 8)
		lm.frustum("Statue", q + Vector3(0, 1.6, 0), 0.2, 0.0, 0.5, 8)
