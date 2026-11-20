extends RefCounted

## Hakaniemi Market Hall (Hakaniemen kauppahalli, Karl Hård af Segerstad,
## 1914), at the registry point, yaw -53.7 so the 30-point outline of OSM way
## 139499388 (1527 m2: two wings round a service yard, 55 x 47 m) runs along
## the model axes.
##
## From the photographs (visual-plan/refs/landmarks/hakaniemi_market_hall/):
## - Red-brick walls on a rough granite plinth, a pale granite string course
##   under the first-floor windows and another under the eaves.
## - Large half-round multi-pane windows on the ground floor, paired tall
##   rectangular windows above, small square lights under the eave.
## - Low roofs of green patinated copper with a broad eave, flat over the
##   wings; the rooftop sign (yellow letters over a white line) is lit.
##
## Measured: footprint and orientation (OSM). Estimated: 12 m eaves, the
## 14.8 m roof and 17 m top of the sign (the registry height), window
## counts, the plinth height and the sign length. Which face is the front is
## a guess: the OSM outline does not say.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "hakaniemi_market_hall", "name": "Hakaniemi Market Hall", "lat": 60.180073, "lon": 24.951208,
	"radius_m": 5000.0, "wiki_title": "Hakaniemi market hall", "height_m": 17.0, "clear_m": 34.0,
	"yaw_deg": -53.7, "kind": "Market hall", "aliases": ["hakaniemi market hall", "hakaniemen kauppahalli", "hagnas saluhall"]}

const OUTLINE := [Vector2(33.4, -13.0), Vector2(31.8, -6.3), Vector2(29.6, -3.7), Vector2(23.6, -2.2),
	Vector2(20.4, -3.6), Vector2(18.4, -6.2), Vector2(17.6, -11.9), Vector2(8.0, -12.0), Vector2(8.1, 14.3),
	Vector2(11.3, 14.2), Vector2(11.2, 24.7), Vector2(8.2, 24.8), Vector2(8.2, 27.5), Vector2(-4.5, 27.7),
	Vector2(-7.9, 27.7), Vector2(-8.0, 24.8), Vector2(-11.0, 24.7), Vector2(-10.9, 14.2), Vector2(-8.1, 14.2),
	Vector2(-7.6, -13.3), Vector2(-8.1, -14.6), Vector2(-11.0, -14.6), Vector2(-11.0, -25.1), Vector2(-8.0, -25.1),
	Vector2(-8.0, -27.8), Vector2(33.2, -27.7), Vector2(33.2, -25.1), Vector2(36.2, -25.1), Vector2(36.1, -14.5),
	Vector2(33.3, -14.6)]
const EAVE := 12.0
const ROOF_TOP := 14.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A4503A", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8E8B84", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#BDB6A6", 2.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6F9A87", 2.0, 0.45, 0.35))
	lm.use("Frame", LandmarkMaterials.paint("#E8E4D6", 0.55, 0.1))
	lm.use("Glass", LandmarkMaterials.glass("#2E383C"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFD25A", 1.6))
	lm.use("Sign", LandmarkMaterials.paint("#EFEFEF", 0.5, 0.1))
	var poly := PackedVector2Array(OUTLINE)
	lm.poly_prism("Stone", F.offset(poly, 0.12), 0.0, 1.3)
	lm.poly_prism("Brick", poly, 1.3, EAVE, false)
	lm.poly_prism("Trim", F.offset(poly, 0.12), 5.9, 6.2, false)
	lm.poly_prism("Trim", F.offset(poly, 0.25), EAVE - 0.5, EAVE, false)
	for i in poly.size():
		_facade(lm, poly, i)
	# Roofs: broad green eaves rising to a low hip, flat deck on top.
	var rim := F.offset(poly, 0.7)
	var cen := FhP.centre(poly)
	FhP.slope_roof(lm, "Copper", rim, cen, 0.94, EAVE, ROOF_TOP)
	# The rooftop sign over the long side facing +Z: two lines of lit letters.
	lm.box("Sign", Vector3(0.0, ROOF_TOP + 0.7, 26.0), Vector3(14.0, 1.4, 0.2))
	lm.box("Lamp", Vector3(0.0, ROOF_TOP + 1.5, 26.1), Vector3(12.5, 0.9, 0.12))
	lm.box("Lamp", Vector3(0.0, ROOF_TOP + 0.5, 26.1), Vector3(11.0, 0.6, 0.12))
	for p in [Vector3(-6.0, ROOF_TOP + 0.5, 26.0), Vector3(0.0, ROOF_TOP + 0.5, 26.0), Vector3(6.0, ROOF_TOP + 0.5, 26.0)]:
		lm.beam("Frame", p, p + Vector3(0, 1.6, 0), 0.12)
	lm.commit(model)

## Windows on one outline edge: round-headed ground-floor lights, paired
## rectangular lights above and a small row under the eaves.
static func _facade(lm: LandmarkMesh, poly: PackedVector2Array, i: int) -> void:
	var a := poly[i]
	var b := poly[(i + 1) % poly.size()]
	var l := a.distance_to(b)
	if l < 4.0:
		return
	var o := FhP.edge_out(poly, i)
	var a3 := Vector3(a.x, 0, a.y)
	var b3 := Vector3(b.x, 0, b.y)
	var n := maxi(int(l / 4.4), 1)
	FhP.win_row(lm, "Frame", "Glass", a3, b3, o, 2.0, n, 2.4, 4.0, true, 0.22)
	FhP.win_row(lm, "Frame", "Glass", a3, b3, o, 7.0, n * 2, 1.2, 2.6, false, 0.16)
	if l > 12.0:
		FhP.win_row(lm, "Frame", "Glass", a3, b3, o, 10.2, n * 2, 1.1, 1.0, false, 0.12)
