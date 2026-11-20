class_name StoOuterVarta
extends RefCounted

## Värtaterminalen, the Värtahamnen passenger terminal (Tallink Silja and
## Viking Line to Helsinki, Turku and Åland; 2019 rebuild). True metres from
## the OSM outline of way 533755501 (x east, z south from its bounding-box
## centre, no yaw: registry `yaw_deg` 0), a 247 x 48 m strip on the quay.
##
## Spec, from visual-plan/refs/landmarks/varta_terminal/ (front, quarter,
## side). Kept modest: one long low block.
## - A white aluminium-panelled block 11 m high with a deep white fascia
##   band at the top carrying the name in grey capitals, and below it a
##   band of grey fabric-screen panels set between white horizontal bands.
## - A ribbon of windows under the fascia on the long faces, and the
##   fascia lit white at night.
## - A flat grey roof with a rail round the edge and plant boxes.
## - Three glazed passenger bridges (boarding gangways, 3 x 3 m, 11 m out
##   from the quay face) on white steel frames carry passengers out to the
##   ships' side doors at 7 m.
## Panel bands and bridge positions are scaled from the photos.
## Surfaces (6): Panel, Screen, Glass, Frame, Roof, Lamp.

const RING := [Vector2(113.9, 23.7), Vector2(123.7, 24.2), Vector2(120.2, 17.0), Vector2(117.3, 11.3),
	Vector2(115.9, 8.3), Vector2(114.0, 4.6), Vector2(108.9, -5.7), Vector2(107.0, -9.5), Vector2(105.6, -12.4),
	Vector2(105.5, -12.6), Vector2(58.5, -16.0), Vector2(-38.4, -19.9), Vector2(-47.0, -20.4), Vector2(-116.6, -23.9),
	Vector2(-121.9, -24.2), Vector2(-122.8, -5.3), Vector2(-123.7, 11.5), Vector2(-26.1, 16.5), Vector2(-9.2, 17.4),
	Vector2(75.8, 21.7)]
const EAVE := 11.0
const FASCIA := 3.0
## [x along the south edge, edge z there] of the boarding bridges.
const BRIDGES := [[-70.0, 14.2], [10.0, 18.4], [80.0, 21.9]]

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Panel", LandmarkMaterials.pbr("concrete", "#E4E5E2", 4.0, 0.55, 0.2))
	lm.use("Screen", LandmarkMaterials.pbr("concrete", "#8C8D8D", 3.0, 0.8))
	lm.use("Glass", LandmarkMaterials.glass("#6E8E92"))
	lm.use("Frame", LandmarkMaterials.paint("#F0F1EF", 0.45, 0.4))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#6B6D70", 4.0))
	lm.use("Lamp", LandmarkMaterials.lit("#F4F6FF", 0.5))
	var poly := PackedVector2Array(RING)
	lm.poly_prism("Panel", poly, 0.0, EAVE, false)
	lm.poly_prism("Roof", poly, EAVE, EAVE + 0.1, true)
	# White bands and the grey screen panels between them.
	W.ribbons(lm, "Frame", poly, 0.0, 1.2, 1, 1.0, 0.1)
	W.ribbons(lm, "Screen", poly, 1.2, 4.6, 1, 1.0, 0.1)
	W.ribbons(lm, "Frame", poly, 5.8, 1.0, 1, 1.0, 0.1)
	W.ribbons(lm, "Glass", poly, 6.8, 1.4, 1, 1.0, 0.1)
	W.ribbons(lm, "Frame", poly, EAVE - FASCIA, FASCIA, 1, 1.0, 0.25)
	W.ribbons(lm, "Lamp", poly, EAVE - FASCIA + 0.2, 0.2, 1, 1.0, 0.3)
	_screen_posts(lm, poly)
	_roof(lm, poly)
	for b in BRIDGES:
		_bridge(lm, float(b[0]), float(b[1]))
	lm.commit(model, "Varta_terminal_")

## Slim white mullions dividing the screen panels every 6 m.
static func _screen_posts(lm: LandmarkMesh, poly: PackedVector2Array) -> void:
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var n := int(a.distance_to(b) / 6.0)
		if n < 2:
			continue
		var along := (b - a).normalized()
		var out := W.outward(poly, a, b)
		var basis := Basis(Vector3(out.y, 0, -out.x), Vector3.UP, Vector3(out.x, 0, out.y))
		for k in range(1, n):
			var p := a + along * (float(k) * a.distance_to(b) / float(n)) + out * 0.14
			lm.box("Frame", Vector3(p.x, 3.5, p.y), Vector3(0.12, 4.6, 0.12), basis, 0.0)

## Roof edge rail and plant boxes.
static func _roof(lm: LandmarkMesh, poly: PackedVector2Array) -> void:
	lm.poly_prism("Frame", F.offset(poly, -0.2), EAVE, EAVE + 1.0, false)
	for x in [-90.0, -40.0, 20.0, 70.0]:
		lm.box("Frame", Vector3(x, EAVE + 1.1, 0.0), Vector3(9.0, 2.2, 4.5), Basis(), 0.0)
		lm.box("Roof", Vector3(x, EAVE + 2.25, 0.0), Vector3(9.4, 0.1, 4.9), Basis(), 0.0)

## A glazed boarding bridge cantilevered south from the quay face on a
## white steel frame.
static func _bridge(lm: LandmarkMesh, x: float, z: float) -> void:
	lm.box("Glass", Vector3(x, 7.6, z + 5.0), Vector3(3.0, 2.6, 10.0), Basis(), 0.0)
	lm.box("Frame", Vector3(x, 9.0, z + 5.0), Vector3(3.4, 0.25, 10.4), Basis(), 0.0)
	lm.box("Frame", Vector3(x, 6.2, z + 5.0), Vector3(3.4, 0.25, 10.4), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.beam("Frame", Vector3(x + float(s) * 1.4, 0.0, z + 9.5), Vector3(x + float(s) * 1.4, 6.2, z + 9.5), 0.3, 0.3)
		lm.beam("Frame", Vector3(x + float(s) * 1.4, 0.2, z + 9.5), Vector3(x + float(s) * 0.2, 6.2, z + 6.5), 0.15, 0.15)
	lm.box("Frame", Vector3(x, 7.6, z + 10.2), Vector3(3.4, 2.8, 0.3), Basis(), 0.0)
