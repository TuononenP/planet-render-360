extends RefCounted

## Helsinki Ice Hall (Helsingin jäähalli, Nordenskiöldinkatu 11-13, 1966).
## Origin at the centroid of OSM way 99404270 (9337 m2, 60.189276 N
## 24.92253 E), yaw -40.6 so the hall's long walls run along the model axes.
##
## From the photographs (visual-plan/refs/landmarks/helsinki_ice_hall/): a
## wide, low arena whose bowed outer walls are one continuous curtain wall of
## glass on a grid of slender mullions and transoms, under a deep dark
## graphite fascia with round vents, and a shallow barrel-vaulted roof of
## dark grey sheet metal. A concrete pier and low concrete plinth stand at
## the corners, with entrance doors on the low front.
##
## Measured: the outline (OSM, 22 points simplified to 0.7 m, 105 x 105 m)
## and its orientation. Estimated: the 11 m glazing height, the fascia, the
## roof rise (to 20 m, the registry value), mullion spacing. The registry
## point was 370 m south of the building.

const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")

const ENTRY := {"type": "helsinki_ice_hall", "name": "Helsinki Ice Hall", "lat": 60.189276, "lon": 24.92253,
	"radius_m": 1500.0, "wiki_title": "Helsinki Ice Hall", "height_m": 20.0, "clear_m": 70.0,
	"yaw_deg": -40.6, "kind": "Arena", "aliases": ["helsinki ice hall", "helsingin jäähalli", "nordis", "helsingfors ishall"]}

const OUTLINE := [Vector2(-44.4, 55.9), Vector2(-49.2, 39.0), Vector2(-52.9, 9.1), Vector2(-50.8, -13.1),
	Vector2(-42.7, -40.1), Vector2(-29.7, -39.5), Vector2(-29.1, -44.4), Vector2(-18.2, -44.6), Vector2(24.7, -43.6),
	Vector2(24.9, -39.0), Vector2(38.2, -39.6), Vector2(44.3, -14.1), Vector2(45.6, 4.2), Vector2(52.0, 5.0),
	Vector2(51.9, 10.6), Vector2(45.4, 10.1), Vector2(44.6, 21.9), Vector2(37.5, 55.9), Vector2(23.4, 55.8),
	Vector2(23.3, 60.5), Vector2(-29.4, 60.5), Vector2(-29.5, 56.4)]
const WALL := 11.5
const TOP := 20.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A7A9A6", 3.0))
	lm.use("Glass", LandmarkMaterials.paint("#7FA2B2", 0.18, 0.3))
	lm.use("Frame", LandmarkMaterials.paint("#7E8588", 0.5, 0.5))
	lm.use("Roof", LandmarkMaterials.paint("#4C5053", 0.55, 0.5))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF1CC", 1.2))
	var poly := PackedVector2Array(OUTLINE)
	lm.poly_prism("Concrete", F.offset(poly, 0.2), 0.0, 1.1)
	lm.poly_prism("Glass", poly, 1.1, WALL, false)
	for i in poly.size():
		_curtain(lm, poly, i)
	# Fascia band and the shallow vault: a hipped skirt up to a flat crown
	# with the roof's own deep edge.
	lm.poly_prism("Roof", F.offset(poly, 0.8), WALL, WALL + 2.6, false)
	var cen := FhP.centre(poly)
	FhP.slope_roof(lm, "Roof", F.offset(poly, 0.8), cen, 0.82, WALL + 2.6, TOP - 1.6)
	var crown := PackedVector2Array()
	for p in poly:
		crown.append(cen + (p - cen) * 0.74)
	lm.poly_prism("Roof", crown, TOP - 1.7, TOP, true)
	# Fascia vents (round, lit).
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		if a.distance_to(b) < 14.0:
			continue
		var o := FhP.edge_out(poly, i)
		var n := int(a.distance_to(b) / 7.0)
		for k in n:
			var p := a.lerp(b, (float(k) + 0.5) / float(n)) + Vector2(o.x, o.z) * 0.85
			lm.disc("Lamp", Vector3(p.x, WALL + 1.4, p.y), o, 0.4, 10)
	# Corner pier of the entrance block.
	lm.box("Concrete", Vector3(48.0, 6.0, 8.0), Vector3(5.0, 12.0, 8.0))
	lm.commit(model)

## One wall edge of the curtain: mullions every 2.4 m, transoms every 2.6 m.
static func _curtain(lm: LandmarkMesh, poly: PackedVector2Array, i: int) -> void:
	var a := poly[i]
	var b := poly[(i + 1) % poly.size()]
	if a.distance_to(b) < 6.0:
		return
	var o := FhP.edge_out(poly, i)
	var a3 := Vector3(a.x, 0, a.y) + o * 0.04
	var b3 := Vector3(b.x, 0, b.y) + o * 0.04
	FhP.ribs(lm, "Frame", a3, b3, o, 1.1, WALL, 2.4, 0.1, 0.12)
	for k in 4:
		FhP.band(lm, "Frame", a3, b3, o, 1.1 + 2.6 * float(k), 0.1, 0.12)
	FhP.band(lm, "Frame", a3, b3, o, WALL - 0.2, 0.3, 0.2)
