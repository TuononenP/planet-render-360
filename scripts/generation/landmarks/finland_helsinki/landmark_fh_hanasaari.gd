extends RefCounted

## Hanasaari B power station (Helsingin Energia, 1974-77), Hanasaari,
## Sörnäinen. Origin at the centroid of the OSM way 16184191 "B-voimala"
## (9829 m2, 60.183891 N 24.971027 E), yaw 48 so the boiler-house walls run
## along the model axes.
##
## Still standing: the Commons photos dated June and October 2026 show the
## plant (closed as a power producer in 2024) with its tall chimney and the
## coal-yard gallery, although the older A plant that stood west of it is
## gone (cleared lot in the October 2026 view). Demolition is announced
## but had not reached the B plant in those photos.
##
## From the photographs (visual-plan/refs/landmarks/hanasaari_power_plant/):
## stacked boxes of rust-red weathering-steel panels, the boiler hall the
## tallest, lower ranges around it, a long inclined coal gallery climbing
## from the east into the top of the hall, lit offices low on the street
## side; the 150 m concrete chimney rising from the hall and a second,
## shorter chimney (97.7 m) behind it.
##
## Measured: the layered outlines of the OSM building parts (13, 12, 11, 8
## and 5 levels, simplified to 0.7 m), the chimney positions and heights (OSM
## nodes, 150 m and 97.7 m). Estimated: 3.6 m per mapped level for the box
## heights, the gallery slope and the cladding colour. The registry's earlier
## point (60.1784 N, 24.9605 E) was 700 m west of the plant.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "hanasaari_power_plant", "name": "Hanasaari Power Station", "lat": 60.183891, "lon": 24.971027,
	"radius_m": 6000.0, "wiki_title": "Hanasaari Power Plant", "height_m": 150.0, "clear_m": 75.0,
	"yaw_deg": 48.0, "kind": "Power station", "aliases": ["hanasaari power station", "hanasaaren voimalaitos", "hanaholmens kraftverk"]}

const LEVEL_M := 3.6
## Outlines of the stacked parts, [levels, points] in the model frame.
const PARTS := [
	[5, [Vector2(-57.0, -58.1), Vector2(-14.2, -58.0), Vector2(-14.2, -71.6), Vector2(14.0, -71.6), Vector2(14.0, -58.0),
		Vector2(57.4, -58.0), Vector2(57.4, -23.8), Vector2(46.6, -23.8), Vector2(46.6, -16.8), Vector2(43.1, -16.9),
		Vector2(43.6, -9.1), Vector2(57.4, -9.8), Vector2(57.4, 12.9), Vector2(43.7, 12.2), Vector2(43.6, 29.2),
		Vector2(37.5, 29.2), Vector2(38.5, 53.6), Vector2(21.1, 53.6), Vector2(21.8, 29.2), Vector2(15.7, 29.2),
		Vector2(15.7, 9.8), Vector2(-13.9, 10.3), Vector2(-13.9, 9.5), Vector2(-15.7, 9.5), Vector2(-15.7, 29.2), Vector2(-21.6, 29.2),
		Vector2(-20.9, 53.7), Vector2(-38.4, 53.8), Vector2(-37.6, 29.3), Vector2(-43.6, 29.2), Vector2(-43.6, 12.2),
		Vector2(-57.2, 13.0), Vector2(-57.2, -9.9), Vector2(-43.6, -9.2), Vector2(-46.3, -16.6), Vector2(-46.3, -23.7),
		Vector2(-57.0, -23.8)]],
	[8, [Vector2(-57.2, -9.9), Vector2(-57.2, 13.0), Vector2(-43.6, 12.2), Vector2(-43.6, 29.2), Vector2(-15.7, 29.2),
		Vector2(-15.7, 9.5), Vector2(-13.9, 9.5), Vector2(-13.9, 10.3), Vector2(15.7, 9.8), Vector2(15.7, 29.2),
		Vector2(43.6, 29.2), Vector2(43.7, 12.2), Vector2(57.4, 12.9), Vector2(57.4, -9.8),
		Vector2(43.6, -9.1), Vector2(46.6, -16.8), Vector2(46.6, -23.8), Vector2(57.4, -23.8), Vector2(57.4, -58.0),
		Vector2(-57.0, -58.1), Vector2(-57.0, -23.8), Vector2(-46.3, -23.7), Vector2(-46.3, -16.6), Vector2(-43.6, -9.2)]],
	[11, [Vector2(-57.2, -9.9), Vector2(-57.2, 13.0), Vector2(-43.6, 12.2), Vector2(-43.6, 29.2), Vector2(-15.7, 29.2),
		Vector2(-15.7, 9.5), Vector2(-13.9, 9.5), Vector2(-13.9, 10.3), Vector2(15.7, 9.8), Vector2(15.7, 29.2),
		Vector2(43.6, 29.2), Vector2(43.7, 12.2), Vector2(57.4, 12.9), Vector2(57.4, -9.8), Vector2(43.6, -9.1),
		Vector2(43.1, -16.9), Vector2(46.6, -16.8), Vector2(46.6, -23.8), Vector2(-46.3, -23.7), Vector2(-46.3, -16.6),
		Vector2(-42.9, -16.6), Vector2(-43.6, -9.2)]],
	[12, [Vector2(-43.6, -15.5), Vector2(43.6, -15.5), Vector2(43.6, 3.4), Vector2(-43.6, 3.4)]],
	[13, [Vector2(15.7, -15.2), Vector2(41.7, -15.3), Vector2(43.1, -16.9), Vector2(43.6, 29.2), Vector2(15.7, 29.2)]],
	[13, [Vector2(-43.6, -15.2), Vector2(-15.7, -15.5), Vector2(-15.7, 29.2), Vector2(-43.6, 29.2)]],
]
const CHIMNEY := Vector2(0.2, 40.0)
const CHIMNEY_H := 150.0
const SMALL_CHIMNEY := Vector2(37.7, -89.9)
const SMALL_H := 97.7

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.pbr("concrete", "#7E3F2F", 3.0, 0.65, 0.3))
	lm.use("Roof", LandmarkMaterials.paint("#4A4644", 0.7, 0.3))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#8E8A7E", 4.0))
	lm.use("Band", LandmarkMaterials.paint("#D8D4C8", 0.6, 0.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3238"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFD98A", 1.6))
	lm.use("Warn", LandmarkMaterials.lit("#FF3322", 2.0))
	for part in PARTS:
		var poly := PackedVector2Array(part[1])
		var h := float(part[0]) * LEVEL_M
		lm.poly_prism("Steel", poly, 0.0, h, false)
		lm.poly_prism("Roof", poly, h, h + 0.5)
		# Panel joints: a vertical rib every 4.5 m on the long outer faces.
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			if a.distance_to(b) > 14.0 and float(part[0]) > 5.0:
				var o := FhP.edge_out(poly, i)
				FhP.ribs(lm, "Roof", Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), o, 1.0, h - 1.0, 4.5, 0.18, 0.12)
	_offices(lm)
	_gallery(lm)
	# The chimneys: concrete shafts with a darker band near the top and a lit
	# aviation lamp.
	for c in [[CHIMNEY, CHIMNEY_H, 6.7, 3.9], [SMALL_CHIMNEY, SMALL_H, 2.9, 2.2]]:
		var at: Vector2 = c[0]
		var h: float = c[1]
		lm.frustum("Concrete", Vector3(at.x, 0, at.y), c[2], c[3], h, 24)
		for k in 6:
			var t := float(k + 1) / 7.0
			var r: float = lerpf(c[2], c[3], t) + 0.1
			lm.frustum("Band", Vector3(at.x, h * t, at.y), r, r, 0.5, 24)
		lm.frustum("Roof", Vector3(at.x, h - 4.0, at.y), c[3] + 0.15, c[3] + 0.15, 4.0, 24)
		lm.box("Warn", Vector3(at.x, h + 0.4, at.y), Vector3(0.7, 0.8, 0.7))
	model.set_meta(LandmarkLights.HALO_META, [[Vector3(CHIMNEY.x, CHIMNEY_H + 0.4, CHIMNEY.y), 3.0, Color(1.0, 0.12, 0.06)],
		[Vector3(SMALL_CHIMNEY.x, SMALL_H + 0.4, SMALL_CHIMNEY.y), 2.0, Color(1.0, 0.12, 0.06)]])
	lm.commit(model)

## Lit office windows low on the north street face and the gatehouse side.
static func _offices(lm: LandmarkMesh) -> void:
	for y in [4.0, 8.0, 12.0]:
		lm.quad("Lamp", Vector3(-50.0, y, -58.2), Vector3(50.0, y, -58.2), Vector3(50.0, y + 1.5, -58.2),
			Vector3(-50.0, y + 1.5, -58.2), Vector3(0, 0, -1))
	for x in range(-50, 51, 5):
		lm.box("Roof", Vector3(float(x), 8.0, -58.25), Vector3(0.3, 12.0, 0.15), Basis(), 0.0)

## The inclined coal gallery climbing from the east to the top of the hall.
static func _gallery(lm: LandmarkMesh) -> void:
	var a := Vector3(110.0, 6.0, -3.0)
	var b := Vector3(57.4, 38.0, -3.0)
	lm.beam("Steel", a, b, 4.0, 3.2, Vector3(0, 0, 1))
	lm.beam("Roof", a + Vector3(0, 1.8, 0), b + Vector3(0, 1.8, 0), 4.4, 0.3, Vector3(0, 0, 1))
	for t in [0.25, 0.55, 0.85]:
		var p := a.lerp(b, t)
		lm.beam("Concrete", Vector3(p.x, 0.0, p.z), p - Vector3(0, 2.0, 0), 1.2, 3.0)
