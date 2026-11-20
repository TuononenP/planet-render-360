extends RefCounted

## Bolt Arena (Töölön jalkapallostadion, 1951, rebuilt 2000), Urheilukatu 5,
## Töölö. Origin at the centre of the OSM pitch (way 4252926, 60.187725 N
## 24.922724 E), yaw -54.7 so the pitch's long axis runs along X.
##
## From the photographs (visual-plan/refs/landmarks/bolt_arena/):
## - A four-sided football ground: continuous raked stands round the pitch,
##   the main stand (-Z) the tallest under a long cantilever roof of pale
##   grey sheet on exposed steel trusses; the two ends have curved roofs
##   that join the main roof, the far side a lower stand under a thin roof.
## - The back of the stands is closed by dark red-brown timber louvres in
##   horizontal slats, with glazed concourse bands.
## - Floodlight masts stand at the four corners.
##
## Measured: the pitch rectangle (OSM, 111 x 73 m with run-off; the markings
## are 105 x 68 m) and its orientation. Estimated: the stand depths and
## heights, the roof heights, the mast height (28 m); the OSM way 138368253
## for the whole ground (20294 m2) was not traced. The registry point was
## 15 m from the pitch centre.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "bolt_arena", "name": "Bolt Arena", "lat": 60.187725, "lon": 24.922724,
	"radius_m": 1500.0, "wiki_title": "Bolt Arena", "height_m": 28.0, "clear_m": 20.0,
	"yaw_deg": -54.7, "kind": "Stadium", "aliases": ["bolt arena", "töölön jalkapallostadion", "sonera stadium", "telia 5g -areena"]}

const HX := 52.5
const HZ := 34.0
const RUN := 4.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Turf", LandmarkMaterials.pbr("grass", "#3F7A3A", 5.0))
	lm.use("Seat", LandmarkMaterials.pbr("concrete", "#46525F", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A9ABA8", 3.0))
	lm.use("Roof", LandmarkMaterials.paint("#B9BEC1", 0.5, 0.5))
	lm.use("Dark", LandmarkMaterials.paint("#3A3C3E", 0.6, 0.5))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#5E3A2C", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E3A40"))
	lm.use("Steel", LandmarkMaterials.paint("#8E9396", 0.5, 0.6))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF4D8", 1.8))
	U.blk(lm, "Turf", 0.0, 0.0, 0.0, 2.0 * (HX + RUN), 0.2, 2.0 * (HZ + RUN))
	# Long sides: main stand on -Z (tall, deep), the far side lower.
	_stand_z(lm, -1.0, 24, 0.5, 0.9, 16.0, true)
	_stand_z(lm, 1.0, 17, 0.45, 0.9, 12.0, false)
	# Ends.
	_stand_x(lm, -1.0)
	_stand_x(lm, 1.0)
	# Floodlight masts at the four corners with lamp heads.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * (HX + 14.0), 0.0, sz * (HZ + 14.0))
			lm.frustum("Steel", p, 0.45, 0.25, 28.0, 8)
			lm.box("Lamp", p + Vector3(-sx * 0.8, 27.2, -sz * 0.4), Vector3(2.4, 1.6, 0.4), Basis(Vector3.UP, atan2(sx, sz)))
	lm.commit(model)

## A long-side stand on the side `sd` (-1 = -Z): rows rise away from the
## pitch; louvred rear wall, sloping roof on trusses.
static func _stand_z(lm: LandmarkMesh, sd: float, rows: int, rise: float, tread: float, roof_h: float, main: bool) -> void:
	var z0 := sd * (HZ + RUN)
	var ln := 2.0 * (HX + RUN) + (24.0 if main else 8.0)
	for k in rows:
		var h := rise * float(k + 1) + 0.4
		var zc := z0 + sd * tread * (float(k) + 0.5)
		lm.box("Seat", Vector3(0.0, h * 0.5, zc), Vector3(ln, h, tread), Basis(), 0.0)
	var zb := z0 + sd * tread * float(rows)
	var top := rise * float(rows) + 0.4
	# Rear wall: louvred timber over glazed concourse bands.
	lm.box("Wood", Vector3(0.0, roof_h * 0.5 - 0.5, zb + sd * 0.3), Vector3(ln, roof_h - 1.0, 0.5), Basis(), 0.0)
	for k in int(roof_h / 2.0):
		lm.box("Dark", Vector3(0.0, 1.8 + 2.0 * float(k), zb + sd * 0.62), Vector3(ln, 0.12, 0.16), Basis(), 0.0)
	lm.box("Glass", Vector3(0.0, 3.0, zb + sd * 0.6), Vector3(ln * 0.9, 1.8, 0.1), Basis(), 0.0)
	# Roof: a sloping plate from the rear down to just before the pitch edge.
	var zf := z0 + sd * 3.0
	var y_rear := roof_h
	var y_front := roof_h - (5.5 if main else 3.0)
	var hl := ln * 0.5
	lm.quad("Roof", Vector3(-hl, y_rear, zb + sd * 1.0), Vector3(hl, y_rear, zb + sd * 1.0), Vector3(hl, y_front, zf),
		Vector3(-hl, y_front, zf), Vector3.UP)
	lm.quad("Dark", Vector3(-hl, y_rear - 0.3, zb + sd * 1.0), Vector3(-hl, y_front - 0.3, zf), Vector3(hl, y_front - 0.3, zf),
		Vector3(hl, y_rear - 0.3, zb + sd * 1.0), Vector3.DOWN)
	lm.box("Roof", Vector3(0.0, y_front - 0.25, zf), Vector3(ln, 0.6, 0.3), Basis(), 0.0)
	# Truss struts every 9 m from the rear column down to the roof tip.
	var n := int(ln / 9.0)
	for i in n + 1:
		var x := -hl + ln * float(i) / float(n)
		lm.beam("Steel", Vector3(x, 0.4, zb + sd * 0.6), Vector3(x, y_rear - 0.3, zb + sd * 0.6), 0.5)
		lm.beam("Steel", Vector3(x, top + 2.0, zb - sd * 3.0), Vector3(x, y_front - 0.5, zf), 0.2)
		lm.beam("Steel", Vector3(x, y_rear - 0.5, zb + sd * 0.8), Vector3(x, y_front - 0.5, zf), 0.2)

## An end stand on the side `sd` (-1 = -X): rows, rear wall, curved roof
## plate (two planes) to the pitch.
static func _stand_x(lm: LandmarkMesh, sd: float) -> void:
	var x0 := sd * (HX + RUN)
	var rows := 14
	var span := 2.0 * (HZ + RUN)
	for k in rows:
		var h := 0.45 * float(k + 1) + 0.4
		lm.box("Seat", Vector3(x0 + sd * 0.9 * (float(k) + 0.5), h * 0.5, 0.0), Vector3(0.9, h, span), Basis(), 0.0)
	var xb := x0 + sd * 0.9 * float(rows)
	lm.box("Wood", Vector3(xb + sd * 0.3, 5.0, 0.0), Vector3(0.5, 10.0, span), Basis(), 0.0)
	lm.quad("Roof", Vector3(xb + sd * 1.0, 11.0, -span * 0.5), Vector3(xb + sd * 1.0, 11.0, span * 0.5),
		Vector3(x0 + sd * 3.0, 8.5, span * 0.5), Vector3(x0 + sd * 3.0, 8.5, -span * 0.5), Vector3.UP)
	lm.quad("Dark", Vector3(xb + sd * 1.0, 10.7, -span * 0.5), Vector3(x0 + sd * 3.0, 8.2, -span * 0.5),
		Vector3(x0 + sd * 3.0, 8.2, span * 0.5), Vector3(xb + sd * 1.0, 10.7, span * 0.5), Vector3.DOWN)
