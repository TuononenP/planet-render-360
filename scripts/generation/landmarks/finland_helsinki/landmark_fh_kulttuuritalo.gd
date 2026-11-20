extends RefCounted

## House of Culture (Kulttuuritalo, Alvar Aalto, 1958), Sturenkatu 4, Alppila.
## Origin at the centroid of the OSM way 24450724 (2713 m2, 60.18824, 24.94416),
## yaw -36.1 so the outline's walls run along the model axes; the street
## front with the canopy is +Z (south-west on the map).
##
## From the photographs (visual-plan/refs/landmarks/kulttuuritalo/):
## - The auditorium is a mass of dark red-orange brick laid in fine courses,
##   its street wall curving in two soft bays, without windows, under a
##   hipped roof of green patinated copper.
## - A long, thin copper canopy on slender steel posts runs along the street
##   front at about 4.6 m, with an edge fascia and a row of lamps.
## - The block behind the hall to the west is a lower brick volume; the
##   office wing along the north edge is a copper-green clad slab with
##   storey-high window ribbons.
##
## Measured: the footprint (OSM, simplified 0.7 m) and the 2-3 m wall
## offsets; the 22 m height (registry value, LoD2 not re-read). Estimated:
## eaves 15.4 m, the roof rise, the canopy depth, the office wing's storey
## count and cladding (the OSM way tags the whole as a public building with
## a quadruple saltbox roof).

const ENTRY := {"type": "kulttuuritalo", "name": "House of Culture", "lat": 60.18824, "lon": 24.94416,
	"radius_m": 1500.0, "wiki_title": "House of Culture (Helsinki)", "height_m": 22.0, "clear_m": 46.0,
	"yaw_deg": -36.1, "kind": "Concert hall", "aliases": ["house of culture", "house of culture helsinki", "kulttuuritalo", "kulturhuset helsingfors"]}

const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const EAVE := 15.4
const TOP := 22.0
const AUD := [Vector2(-8.0, -18.3), Vector2(10.7, -18.3), Vector2(10.7, -17.2), Vector2(23.9, -8.0), Vector2(20.4, 4.3),
	Vector2(24.1, 7.8), Vector2(20.5, 12.2), Vector2(20.5, 17.5), Vector2(17.8, 17.5), Vector2(17.7, 21.2),
	Vector2(-8.1, 21.1)]
const WEST := [Vector2(-30.8, -32.2), Vector2(-7.8, -32.3), Vector2(-8.0, 21.1), Vector2(-11.7, 14.2),
	Vector2(-16.1, 16.4), Vector2(-26.0, 13.6), Vector2(-30.5, 8.8), Vector2(-30.5, 1.5), Vector2(-28.6, 0.0),
	Vector2(-30.9, -3.0)]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A8452B", 2.0))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#4A4642", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9A86", 2.0, 0.45, 0.35))
	lm.use("Glass", LandmarkMaterials.glass("#2E3A40"))
	lm.use("Frame", LandmarkMaterials.paint("#3E4A44", 0.5, 0.4))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A8", 1.4))
	var aud := PackedVector2Array(AUD)
	var west := PackedVector2Array(WEST)
	# Hall: dark granite plinth, windowless brick wall, hipped copper roof.
	lm.poly_prism("Base", aud, 0.0, 1.0)
	lm.poly_prism("Brick", aud, 1.0, EAVE)
	lm.poly_prism("Copper", aud, EAVE, EAVE + 0.5, false)
	FhP.slope_roof(lm, "Copper", aud, FhP.centre(aud) + Vector2(1.0, 0.0), 0.55, EAVE + 0.5, TOP - 0.4)
	_hall_details(lm)
	# Lower brick block to the west under a shallow copper roof.
	lm.poly_prism("Base", west, 0.0, 1.0)
	lm.poly_prism("Brick", west, 1.0, 11.0)
	FhP.slope_roof(lm, "Copper", west, FhP.centre(west), 0.82, 11.0, 12.4)
	for i in west.size():
		var p := west[i]
		var q := west[(i + 1) % west.size()]
		if p.distance_to(q) > 6.0 and absf(p.x - q.x) < 0.5 and p.x < -20.0:
			var o := FhP.edge_out(west, i)
			for k in 3:
				FhP.win_row(lm, "Frame", "Glass", Vector3(p.x, 0, p.y), Vector3(q.x, 0, q.y), o, 3.2 + 2.8 * float(k),
					int(p.distance_to(q) / 4.0), 1.6, 1.9, false, 0.2)
	_wing(lm)
	_canopy(lm)
	lm.commit(model)

## Small projecting bay and eave band on the hall.
static func _hall_details(lm: LandmarkMesh) -> void:
	lm.box("Copper", Vector3(-9.5, 12.0, 14.5), Vector3(2.4, 3.2, 2.6))
	for k in 5:
		lm.box("Frame", Vector3(-10.8, 12.0, 13.5 + 0.5 * float(k)), Vector3(0.06, 2.6, 0.18), Basis(), 0.0)
	lm.poly_prism("Copper", PackedVector2Array(AUD), EAVE - 0.5, EAVE)

## Office wing along the north edge: copper-green cladding with storey-high
## glazed ribbons and a flat copper roof edge.
static func _wing(lm: LandmarkMesh) -> void:
	var x0 := -30.6
	var x1 := 15.1
	var z0 := -43.9
	var z1 := -32.2
	var h := 13.2
	lm.box("Base", Vector3((x0 + x1) * 0.5, 0.5, (z0 + z1) * 0.5), Vector3(x1 - x0 + 0.4, 1.0, z1 - z0 + 0.4))
	lm.box("Copper", Vector3((x0 + x1) * 0.5, 1.0 + (h - 1.0) * 0.5, (z0 + z1) * 0.5), Vector3(x1 - x0, h - 1.0, z1 - z0))
	lm.box("Copper", Vector3((x0 + x1) * 0.5, h + 0.2, (z0 + z1) * 0.5), Vector3(x1 - x0 + 0.8, 0.4, z1 - z0 + 0.8))
	for z in [z0, z1]:
		var o := Vector3(0, 0, -1 if z == z0 else 1)
		var a := Vector3(x0 + 1.0, 0, z) + o * 0.03
		var b := Vector3(x1 - 1.0, 0, z) + o * 0.03
		for k in 4:
			var y := 2.0 + 3.1 * float(k)
			lm.quad("Glass", a + Vector3(0, y, 0), b + Vector3(0, y, 0), b + Vector3(0, y + 1.6, 0), a + Vector3(0, y + 1.6, 0), o)
		FhP.ribs(lm, "Frame", a, b, o, 2.0, 14.0, 3.6, 0.18, 0.12)
	for x in [x0, x1]:
		var o2 := Vector3(-1 if x == x0 else 1, 0, 0)
		for k in 4:
			var y := 2.0 + 3.1 * float(k)
			lm.quad("Glass", Vector3(x, y, z0 + 2.0) + o2 * 0.03, Vector3(x, y, z1 - 2.0) + o2 * 0.03,
				Vector3(x, y + 1.6, z1 - 2.0) + o2 * 0.03, Vector3(x, y + 1.6, z0 + 2.0) + o2 * 0.03, o2)

## The long copper canopy along the street front on slender posts.
static func _canopy(lm: LandmarkMesh) -> void:
	var x0 := -14.0
	var x1 := 25.0
	var cx := (x0 + x1) * 0.5
	lm.box("Copper", Vector3(cx, 4.7, 23.9), Vector3(x1 - x0, 0.22, 5.6))
	lm.box("Copper", Vector3(cx, 4.95, 26.6), Vector3(x1 - x0, 0.5, 0.18))
	lm.box("Frame", Vector3(cx, 4.5, 21.5), Vector3(x1 - x0, 0.14, 0.14))
	var n := int((x1 - x0) / 5.0)
	for i in n + 1:
		var x := x0 + (x1 - x0) * float(i) / float(n)
		lm.beam("Frame", Vector3(x, 0.0, 26.4), Vector3(x, 4.6, 26.4), 0.14)
		lm.box("Lamp", Vector3(x + 2.5, 4.52, 25.5), Vector3(0.35, 0.08, 0.35), Basis(), 0.0)
	# Entrance: a glazed door set in the hall's plinth wall under the canopy.
	lm.quad("Glass", Vector3(-12.0, 0.0, 21.2), Vector3(-6.0, 0.0, 21.2), Vector3(-6.0, 3.6, 21.2), Vector3(-12.0, 3.6, 21.2),
		Vector3(0, 0, 1))
