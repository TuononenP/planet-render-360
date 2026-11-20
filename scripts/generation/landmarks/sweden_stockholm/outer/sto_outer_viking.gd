class_name StoOuterViking
extends RefCounted

## Viking Line terminal at Stadsgården (Stadsgårdskajen), the ferry berths
## to Helsinki and Turku. True metres from the OSM outline of way 24967536
## (x east, z south from its bounding-box centre, no yaw: registry
## `yaw_deg` 0), a hall of two levels with a thin boarding walkway running
## out along the quay. Kept modest.
##
## Spec, from visual-plan/refs/landmarks/viking_line_terminal/ (front,
## quarter, side; photographed from the water):
## - A low white-and-glass terminal: an open dark ground storey for cars
##   and a first floor (4.5-9 m) wrapped in a glazed ribbon between white
##   steel members, a flat dark roof with a white fascia and plant boxes.
## - Three white steel boarding towers (13 m, four posts, X bracing) stand
##   at the quay face; each carries a glazed passenger bridge back to the
##   first floor and a glazed cabin on top.
## - A glazed boarding walkway on a white steel truss (the mapped tail of
##   the outline) at 6.5-9 m runs east along the quay to the next berth.
## - The quay edge is a steel-faced concrete apron.
## Window bays and tower positions are scaled from the photos.
## Surfaces (6): Base, Panel, Glass, Frame, Roof, Lamp.

const BODY := [Vector2(-56.6, -5.9), Vector2(-54.1, -10.3), Vector2(-62.0, -13.7), Vector2(-60.6, -16.5),
	Vector2(-55.2, -27.8), Vector2(-42.9, -22.6), Vector2(-39.8, -28.4), Vector2(-4.3, -13.2), Vector2(10.2, -1.9),
	Vector2(8.5, 2.1), Vector2(23.0, 8.8), Vector2(21.5, 13.3), Vector2(18.6, 20.5), Vector2(14.9, 26.1),
	Vector2(8.8, 28.4), Vector2(-31.8, 6.9)]
const TAIL := [Vector2(-4.3, -13.2), Vector2(28.3, -0.3), Vector2(42.0, 5.1), Vector2(62.0, 13.0),
	Vector2(60.5, 17.0), Vector2(10.2, -1.9)]
const GROUND := 4.5
const EAVE := 9.0
## Tower foot positions along the quay (south-west) face, as lerps of the
## body edge (-31.8, 6.9) to (8.8, 28.4), pushed 3.5 m out.
const TOWER_T := [0.22, 0.52, 0.82]

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Base", LandmarkMaterials.pbr("concrete", "#55595C", 4.0))
	lm.use("Panel", LandmarkMaterials.pbr("concrete", "#DADCDA", 4.0, 0.55, 0.2))
	lm.use("Glass", LandmarkMaterials.glass("#4B6670"))
	lm.use("Frame", LandmarkMaterials.paint("#EEF0EE", 0.45, 0.4))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#4A4C4E", 4.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FFEBC0", 0.45))
	var body := PackedVector2Array(BODY)
	# Open car deck: dark core behind a ring of white piers.
	lm.poly_prism("Base", F.offset(body, -2.0), 0.0, GROUND, false)
	_piers(lm, body)
	lm.poly_prism("Panel", body, GROUND, EAVE, false)
	W.ribbons(lm, "Glass", body, GROUND + 1.0, 2.4, 1, 1.0, 0.08)
	W.ribbons(lm, "Frame", body, EAVE - 0.8, 0.8, 1, 1.0, 0.2)
	W.ribbons(lm, "Lamp", body, GROUND + 0.5, 0.15, 1, 1.0, 0.1)
	lm.poly_prism("Roof", body, EAVE, EAVE + 0.1, true)
	lm.box("Frame", Vector3(-25.0, EAVE + 1.0, -8.0), Vector3(10.0, 2.0, 5.0), Basis(), 0.0)
	lm.box("Frame", Vector3(-5.0, EAVE + 0.8, 8.0), Vector3(7.0, 1.6, 4.0), Basis(), 0.0)
	_walkway(lm)
	var a := Vector2(-31.8, 6.9)
	var b := Vector2(8.8, 28.4)
	var out := W.outward(body, a, b)
	for t in TOWER_T:
		_tower(lm, a.lerp(b, float(t)) + out * 3.5, out)
	lm.commit(model, "Viking_terminal_")

## White round piers every 6 m under the first floor.
static func _piers(lm: LandmarkMesh, body: PackedVector2Array) -> void:
	for i in body.size():
		var a := body[i]
		var b := body[(i + 1) % body.size()]
		var n := int(a.distance_to(b) / 6.0)
		for k in n + 1:
			var p := a.lerp(b, float(k) / float(maxi(n, 1)))
			lm.frustum("Frame", Vector3(p.x, 0.0, p.y), 0.3, 0.3, GROUND, 8)

## The glazed boarding walkway on a truss, on legs every 8 m.
static func _walkway(lm: LandmarkMesh) -> void:
	var tail := PackedVector2Array(TAIL)
	lm.poly_prism("Glass", F.offset(tail, -0.4), 6.5, 8.6, false)
	lm.poly_prism("Frame", tail, 8.6, 8.9, true)
	lm.poly_prism("Frame", tail, 6.2, 6.5, true)
	var a := Vector2(10.2, -1.9)
	var b := Vector2(60.5, 17.0)
	var n := int(a.distance_to(b) / 8.0)
	for k in n + 1:
		var p := a.lerp(b, float(k) / float(n)) + Vector2(1.0, -1.6)
		lm.beam("Frame", Vector3(p.x, 0.0, p.y), Vector3(p.x, 6.2, p.y), 0.4, 0.4)

## A white steel boarding tower: four posts, X braces, a glazed bridge to
## the first floor and a glazed cabin on top.
static func _tower(lm: LandmarkMesh, c: Vector2, out: Vector2) -> void:
	var h := 13.0
	var r := 1.5
	var corners := [Vector2(-r, -r), Vector2(r, -r), Vector2(r, r), Vector2(-r, r)]
	for p in corners:
		lm.beam("Frame", Vector3(c.x + p.x, 0.0, c.y + p.y), Vector3(c.x + p.x, h - 2.5, c.y + p.y), 0.3, 0.3)
	for lv in 3:
		var y0 := 1.0 + 3.5 * float(lv)
		for i in 4:
			var p: Vector2 = corners[i]
			var q: Vector2 = corners[(i + 1) % 4]
			lm.beam("Frame", Vector3(c.x + p.x, y0, c.y + p.y), Vector3(c.x + q.x, y0 + 3.5, c.y + q.y), 0.12, 0.12)
			lm.beam("Frame", Vector3(c.x + q.x, y0, c.y + q.y), Vector3(c.x + p.x, y0 + 3.5, c.y + p.y), 0.12, 0.12)
	lm.box("Glass", Vector3(c.x, h - 1.25, c.y), Vector3(3.6, 2.2, 3.6), Basis(), 0.0)
	lm.box("Frame", Vector3(c.x, h, c.y), Vector3(3.9, 0.3, 3.9), Basis(), 0.0)
	# Glazed bridge back to the building's first floor.
	var bridge := c - out * 3.0
	var basis := Basis(Vector3(out.y, 0, -out.x), Vector3.UP, Vector3(out.x, 0, out.y))
	lm.box("Glass", Vector3(bridge.x, 7.5, bridge.y), Vector3(2.4, 2.4, 6.0), basis, 0.0)
	lm.box("Frame", Vector3(bridge.x, 8.8, bridge.y), Vector3(2.8, 0.2, 6.2), basis, 0.0)
