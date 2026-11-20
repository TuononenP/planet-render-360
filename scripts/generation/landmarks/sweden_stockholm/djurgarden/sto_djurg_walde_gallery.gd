class_name StoDjurgWaldeGallery
extends RefCounted

## The Waldemarsudde gallery (OSM way 34838579, 48.3 x 20.1 m, long axis
## bearing 80), 56 m east and 17 m north of the villa. The outline is the
## OSM polygon turned into the villa's frame (yaw 1.5); its centroid lies at
## (58, -18.3) there.
##
## Spec (visual-plan/refs/landmarks/waldemarsudde/ and the Commons
## "Waldemarsudde Galleri 2012" photos; heights approximate):
## - A long low white-plastered building, eave 5.4 m, under a flat roof with
##   a thin copper edge.
## - An octagonal drum (apothem 5.6 m) rising to 9.4 m with a band of tall
##   framed windows on every face and a shallow patinated-copper dome to
##   11.2 m.
## - A tall square green copper flue (1.6 m, to 12.4 m) at the west end.
## - Glazed pyramid roof lights along the flat roof.

const POLY := [Vector2(42.4, -6.4), Vector2(41.8, -9.1), Vector2(34.5, -7.6), Vector2(33.5, -12.3),
	Vector2(35.7, -12.8), Vector2(33.3, -24.6), Vector2(60.5, -30.0), Vector2(61.6, -24.5),
	Vector2(66.3, -25.5), Vector2(66.1, -26.4), Vector2(73.6, -27.9), Vector2(74.7, -22.3),
	Vector2(80.5, -23.5), Vector2(82.4, -14.4)]
const EAVE := 5.4
const DRUM := Vector3(58.0, 0.0, -19.5)

static func build(lm: LandmarkMesh, mats: Dictionary) -> void:
	var poly := PackedVector2Array(POLY)
	lm.poly_prism("White", poly, 0.0, EAVE)
	lm.poly_prism("Zinc", poly, EAVE, EAVE + 0.25)
	_drum(lm, mats)
	# Green copper flue at the west end.
	lm.box("RoofTop", Vector3(37.5, EAVE + 3.5, -17.5), Vector3(1.6, 7.0, 1.6), Basis(), 0.0)
	lm.box("RoofTop", Vector3(37.5, EAVE + 7.1, -17.5), Vector3(2.0, 0.25, 2.0), Basis(), 0.0)
	# Roof lights.
	for p in [Vector2(70.0, -24.0), Vector2(46.0, -10.5), Vector2(77.0, -20.5)]:
		lm.spire("Glass", Vector3(p.x, EAVE + 0.25, p.y), 1.6, 1.3, 0.2)

static func _drum(lm: LandmarkMesh, mats: Dictionary) -> void:
	var a := 5.6
	var r := a / cos(PI / 8.0)
	var y0 := EAVE + 0.25
	var h := 9.4 - y0
	lm.lathe("White", DRUM + Vector3(0, y0, 0), PackedVector2Array([Vector2(r, 0.0), Vector2(r, h)]),
		8, 1.0, 1.0, PI / 8.0, false)
	var win := StoDjurgKit.unit(mats, 1.5, 2.4, false, 0.25)
	for k in 8:
		var ang := float(k) * PI / 4.0
		var n := Vector3(cos(ang), 0, sin(ang))
		var side := Vector3.UP.cross(n)
		for s in [-1.0, 0.0, 1.0]:
			StoChurchKit.place(lm, win, DRUM + n * a + side * float(s) * 1.7 + Vector3(0, y0 + 0.8, 0), n)
		lm.box("RoofTop", DRUM + n * (a + 0.05) + Vector3(0, y0 + 2.9, 0), Vector3(4.8, 0.3, 0.25),
			Basis(side, Vector3.UP, n), 0.0)
	lm.lathe("RoofTop", DRUM + Vector3(0, 9.4, 0), PackedVector2Array([
		Vector2(r + 0.5, 0.0), Vector2(r * 0.8, 0.9), Vector2(r * 0.45, 1.6), Vector2(0.0, 1.9)]),
		8, 1.0, 1.0, PI / 8.0, false)
