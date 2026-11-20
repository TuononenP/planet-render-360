class_name StoIslandChurch
extends RefCounted

## Skeppsholmskyrkan (Carl Johans kyrka, 1824-42, Fredrik Blom; since 1994
## the concert hall Eric Ericsonhallen, the name OSM gives the building).
## 36.5 m to the gilt cross. True metres, origin at the footprint centre,
## +X on the 7.9 deg axis; registry yaw -82.1 puts the entrance wing (-X) to
## the south, toward the quay. The footprint is about 37 x 37 m.
##
## From the photos (visual-plan/refs/landmarks/skeppsholmen_church/):
## - Plan: a regular octagon 27 m across the flats in pale cream stucco, with
##   a pedimented wing (11 m wide, projecting 5 m) on each of the four
##   cardinal faces, so the diagonal faces stay plain between them.
## - Octagon walls rise 14 m on a granite plinth; at the corners flat
##   pilasters. Each diagonal face has three tall mullioned windows under a
##   large round-headed window (3.4 m wide) in a moulded surround. A dentilled
##   cornice 1.4 m deep runs round the top, then a plain attic band and a dark
##   lead ledge.
## - Wings: 12.3 m to the eaves, a copper-green gable roof and a stucco
##   pediment with raking trim, a round-headed window in the gable zone and
##   three tall windows below. The entrance wing (-X) instead has a Tuscan
##   portico of four columns with an entablature, a door between the middle
##   two and the arched window above.
## - Dome: a shallow verdigris copper dome (25 m across at the base, 7 m
##   tall) with 24 standing seams, carrying a dark drum with a railed
##   balcony; on it an open lantern of eight slender columns with a bell, a
##   small copper cap, a gilt ball and a gilt cross. Top 36.5 m.
## Night: warm floodlights on the dome and the facades.
## Surfaces (7): Wall, Trim, Copper, CopperDark, Glass, Gilt, Dark.

## Octagon apothem and circumradius, wall height to the cornice, wing size.
const A := 13.5
const R := 14.612
const WALL_H := 14.0
const CORNICE_H := 1.4
const WING_W := 11.0
const WING_PROJ := 5.0
const WING_H := 12.3
const DOME_BASE := 17.3
const DOME_H := 7.0
const DOME_R := 12.4
const TOP := 36.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_octagon(lm)
	_windows(lm)
	for k in 4:
		var wing := _wing(k == 2)
		lm.merge(wing, Transform3D(Basis(Vector3.UP, [PI * 0.5, PI, -PI * 0.5, 0.0][k]), Vector3.ZERO))
	_dome(lm)
	_lantern(lm)
	lm.commit(model)
	StoChurchKit.flood(model, Vector3(0.0, 0.0, 0.0), 30.0, 20.0)

static func _mats() -> Dictionary:
	var mats := StoChurchKit.materials("render", "#E8E1CD", "#E9E3D0", "#6F9C86")
	mats["CopperDark"] = LandmarkMaterials.pbr("concrete", "#3F5A4D", 2.0, 0.5, 0.3)
	mats["Dark"] = LandmarkMaterials.paint("#2A2D2B", 0.6, 0.3)
	return mats

static func _materials(lm: LandmarkMesh) -> void:
	StoChurchKit.use_all(lm, _mats())

static func _polygon(r: float) -> PackedVector2Array:
	var poly := PackedVector2Array()
	for k in 8:
		var a := PI * 0.125 + PI * 0.25 * float(k)
		poly.append(Vector2(cos(a), sin(a)) * r)
	return poly

## The octagon: plinth, walls, corner pilasters, cornice, attic and ledge.
static func _octagon(lm: LandmarkMesh) -> void:
	lm.poly_prism("Trim", _polygon(R * 1.025), 0.0, 1.0)
	lm.poly_prism("Wall", _polygon(R), 0.0, WALL_H + CORNICE_H)
	var poly := _polygon(R)
	for k in 8:
		var p := poly[k]
		var q := poly[(k + 1) % 8]
		var mid := (p + q) * 0.5
		var out := Vector3(mid.x, 0.0, mid.y).normalized()
		LandmarkDetail.cornice(lm, "Trim", Vector3(p.x, WALL_H, p.y), Vector3(q.x, WALL_H, q.y), out, CORNICE_H)
		lm.box("Trim", Vector3(p.x, 7.5, p.y) * 1.0, Vector3(0.9, 13.0, 0.9), Basis(Vector3.UP, -PI * 0.25 * float(k) - PI * 0.125))
	lm.poly_prism("Wall", _polygon(R * 0.97), WALL_H + CORNICE_H, WALL_H + CORNICE_H + 1.5)
	lm.poly_prism("Dark", _polygon(R * 0.985), WALL_H + CORNICE_H + 1.5, DOME_BASE)

## Window units built once facing +Z and placed on the four plain faces.
static func _windows(lm: LandmarkMesh) -> void:
	var mats := _mats()
	var tall := LandmarkMesh.new()
	StoChurchKit.use_all(tall, mats)
	LandmarkDetail.window(tall, "Trim", "Glass", Vector3(0, 2.6, 0), Vector3.BACK, 1.5, 5.2, false, 0.3)
	var round_head := LandmarkMesh.new()
	StoChurchKit.use_all(round_head, mats)
	LandmarkDetail.window(round_head, "Trim", "Glass", Vector3(0, 2.2, 0), Vector3.BACK, 3.4, 4.4, true, 0.3)
	for k in 4:
		var phi := PI * 0.25 + PI * 0.5 * float(k)
		var n := Vector3(cos(phi), 0.0, sin(phi))
		var t := Vector3(-sin(phi), 0.0, cos(phi))
		for dx: float in [-3.5, 0.0, 3.5]:
			StoChurchKit.place(lm, tall, n * (A - 0.05) + t * dx + Vector3(0, 1.0, 0), n)
		StoChurchKit.place(lm, round_head, n * (A - 0.05) + Vector3(0, 7.9, 0), n)

## One wing facing +Z (turned into place by the caller); `portico` gives it
## the entrance porch.
static func _wing(portico: bool) -> LandmarkMesh:
	var w := LandmarkMesh.new()
	_materials(w)
	var z0 := A - 0.3
	var zf := A + WING_PROJ
	var hw := WING_W * 0.5
	w.box("Wall", Vector3(0, WING_H * 0.5, (z0 + zf) * 0.5), Vector3(WING_W, WING_H, zf - z0), Basis(), 0.0)
	w.box("Trim", Vector3(0, 0.5, (z0 + zf) * 0.5 + 0.1), Vector3(WING_W + 0.5, 1.0, zf - z0 + 0.2), Basis(), 0.0)
	LandmarkDetail.cornice(w, "Trim", Vector3(-hw, WING_H, zf), Vector3(hw, WING_H, zf), Vector3.BACK, 0.8)
	# Gable roof (ridge toward the front) with a closed stucco pediment.
	w.gable("Copper", Vector3(0, WING_H + 0.8, (z0 + zf) * 0.5), WING_W, zf - z0, 2.6, Basis(), 0.45, "Wall")
	for s: float in [-1.0, 1.0]:
		w.beam("Trim", Vector3(s * (hw + 0.45), WING_H + 0.8, zf + 0.05), Vector3(0, WING_H + 0.8 + 2.6, zf + 0.05),
			0.4, 0.3, Vector3.BACK)
	if portico:
		for k in 4:
			LandmarkDetail.column(w, "Trim", Vector3(-4.5 + 3.0 * float(k), 0.3, zf + 1.4), 0.4, 6.0, "tuscan", 0, 12)
		w.box("Trim", Vector3(0, 6.5, zf + 1.1), Vector3(WING_W + 0.4, 1.0, 2.8), Basis(), 0.0)
		w.box("Trim", Vector3(0, 0.15, zf + 1.2), Vector3(WING_W - 1.0, 0.3, 3.0), Basis(), 0.0)
		w.box("Dark", Vector3(0, 2.3, zf + 0.03), Vector3(2.2, 4.0, 0.1), Basis(), 0.0)
		LandmarkDetail.window(w, "Trim", "Glass", Vector3(0, 9.6, zf), Vector3.BACK, 2.8, 3.0, true, 0.3)
	else:
		for dx: float in [-3.4, 0.0, 3.4]:
			LandmarkDetail.window(w, "Trim", "Glass", Vector3(dx, 3.1, zf), Vector3.BACK, 1.3, 3.6, false, 0.3)
		LandmarkDetail.window(w, "Trim", "Glass", Vector3(0, 8.7, zf), Vector3.BACK, 3.2, 4.0, true, 0.3)
	return w

## The ribbed verdigris dome.
static func _dome(lm: LandmarkMesh) -> void:
	var prof := PackedVector2Array()
	var top_a := acos(3.0 / DOME_R)
	for j in 15:
		var a := top_a * float(j) / 14.0
		prof.append(Vector2(DOME_R * cos(a), DOME_H * sin(a) / sin(top_a)))
	lm.lathe("Copper", Vector3(0, DOME_BASE, 0), prof, 32)
	for i in 24:
		var a := TAU * float(i) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in prof.size() - 1:
			var p0 := Vector3(0, DOME_BASE, 0) + d * (prof[j].x + 0.04) + Vector3(0, prof[j].y + 0.03, 0)
			var p1 := Vector3(0, DOME_BASE, 0) + d * (prof[j + 1].x + 0.04) + Vector3(0, prof[j + 1].y + 0.03, 0)
			lm.beam("Copper", p0, p1, 0.2, 0.1, d.cross(Vector3.UP))

## Drum, railed balcony, open lantern, cap and cross.
static func _lantern(lm: LandmarkMesh) -> void:
	var y := DOME_BASE + DOME_H
	lm.frustum("CopperDark", Vector3(0, y - 0.1, 0), 3.2, 2.9, 3.3, 16)
	var by := y + 2.2
	lm.frustum("Dark", Vector3(0, by, 0), 3.7, 3.7, 0.25, 16)
	var rail: Array = []
	for i in 17:
		var a := TAU * float(i % 16) / 16.0
		rail.append(Vector3(cos(a) * 3.6, by + 1.1, sin(a) * 3.6))
		if i < 16:
			lm.beam("Dark", Vector3(cos(a) * 3.6, by + 0.25, sin(a) * 3.6), Vector3(cos(a) * 3.6, by + 1.1, sin(a) * 3.6), 0.07, 0.07)
	HullLoft.tube(lm, "Dark", rail, 0.045, 4)
	var ly := y + 3.4
	lm.frustum("Dark", Vector3(0, ly, 0), 2.5, 2.5, 0.3, 16)
	for i in 8:
		var a := TAU * float(i) / 8.0 + PI / 8.0
		LandmarkDetail.column(lm, "CopperDark", Vector3(cos(a) * 2.0, ly + 0.3, sin(a) * 2.0), 0.17, 3.4, "tuscan", 0, 8)
	lm.lathe("Dark", Vector3(0, ly + 0.3, 0), PackedVector2Array([Vector2(0.5, 0), Vector2(0.4, 1.0), Vector2(0.15, 1.4)]), 8)
	var ey := ly + 3.7
	lm.frustum("CopperDark", Vector3(0, ey, 0), 2.55, 2.55, 0.4, 16)
	lm.lathe("Copper", Vector3(0, ey + 0.4, 0), PackedVector2Array([Vector2(2.5, 0), Vector2(2.25, 0.5),
		Vector2(1.6, 0.95), Vector2(0.7, 1.25), Vector2(0.25, 1.4)]), 16)
	var cy := ey + 1.8
	lm.lathe("Gilt", Vector3(0, cy, 0), LandmarkFhUtil.ball(0.28), 10)
	var post := cy + 0.5
	lm.beam("Gilt", Vector3(0, post, 0), Vector3(0, TOP, 0), 0.14, 0.14)
	lm.beam("Gilt", Vector3(-0.7, TOP - 1.0, 0), Vector3(0.7, TOP - 1.0, 0), 0.12, 0.14)
