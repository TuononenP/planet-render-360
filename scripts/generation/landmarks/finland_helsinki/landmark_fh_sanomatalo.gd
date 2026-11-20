extends RefCounted

## Sanomatalo (1999, Antti-Matti Siikala), Töölönkatu / Kansalaistori, built
## on its OpenStreetMap outline (way 122595236, simplified to 0.6 m,
## recentred on its bounding box and turned by the entry's yaw onto the street
## grid).
##
## From the Commons photos in visual-plan/refs/landmarks/sanomatalo/:
## - An all-glass box of nine levels in blue-green reflective glass, with
##   chamfered corners, wrapped by a steel exoskeleton: stainless columns
##   every 6 m standing proud of the glass, horizontal tubes every storey
##   and crossing tension rods in the bays.
## - A low glazed ground floor with a lobby and a grey stainless service
##   tower at the east corner, rising a little above the flat roof.
## - It glows at night: the offices are lit behind the glass.
##
## Measured: the outline (OSM) and the 39.5 m height (OSM height tag; LoD2
## 38.2 m). Estimated: the column and tube spacing, the service tower.

const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "sanomatalo", "name": "Sanomatalo", "lat": 60.172444, "lon": 24.937885,
	"radius_m": 1500.0, "wiki_title": "Sanomatalo", "height_m": 39.5, "clear_m": 52.0,
	"yaw_deg": -7.4, "kind": "Office", "aliases": ["sanomatalo", "sanoma house", "sanomahuset"]}

const OUTLINE := [-35.0, 17.2, -35.0, -24.7, -30.7, -24.7, -30.7, -26.7, -31.7, -27.7, -26.3, -33.0, -25.2, -31.9,
	24.8, -31.8, 25.9, -32.9, 31.2, -27.8, 30.2, -26.8, 30.2, -24.5, 35.0, -24.5, 34.6, 21.0, 30.2, 21.0, 30.1,
	23.2, 31.2, 24.3, 25.8, 29.6, 22.8, 28.7, 22.8, 33.0, -19.3, 33.0, -19.3, 23.0, -22.3, 20.1, -25.1, 23.1,
	-28.0, 20.3, -25.0, 17.3]

const TOP := 39.5
const STOREY := 4.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.paint("#5C8790", 0.2, 0.5))
	lm.use("Steel", LandmarkMaterials.paint("#A9AEB0", 0.35, 0.8))
	lm.use("Rod", LandmarkMaterials.paint("#8A9092", 0.4, 0.8))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#7B7A76", 3.0))
	lm.use("Roof", LandmarkMaterials.paint("#6C7072", 0.7))
	lm.use("Core", LandmarkMaterials.paint("#B7BBBB", 0.4, 0.7))
	lm.use("Lamp", LandmarkMaterials.lit("#76A0A6", 0.3))
	var poly := PackedVector2Array()
	for i in range(0, OUTLINE.size() - 1, 2):
		poly.append(Vector2(float(OUTLINE[i]), float(OUTLINE[i + 1])))
	lm.poly_prism("Glass", poly, 0.0, TOP)
	lm.poly_prism("Base", F.offset(poly, 0.3), 0.0, 0.8)
	# The exoskeleton: stainless columns every 6 m, tubes every storey.
	W.ribs(lm, "Steel", poly, 0.0, TOP + 0.6, 6.0, 0.4, 0.55)
	for k in 10:
		lm.poly_prism("Steel", F.offset(poly, 0.45), float(k) * STOREY + 0.3, float(k) * STOREY + 0.55, false)
	# Lit floors behind the glass: a thin bright band at each slab.
	for k in range(1, 9):
		lm.poly_prism("Lamp", F.offset(poly, 0.05), float(k) * STOREY + 1.0, float(k) * STOREY + 1.9, false)
	# Crossing tension rods in the bays of the two long faces.
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		if a.distance_to(b) < 18.0:
			continue
		var out := W.outward(poly, a, b)
		var n := int(a.distance_to(b) / 6.0)
		for j in n:
			var p0 := a.lerp(b, float(j) / float(n)) + out * 0.4
			var p1 := a.lerp(b, float(j + 1) / float(n)) + out * 0.4
			for lvl in [0, 3, 6]:
				var y0 := float(lvl) * STOREY + 0.5
				lm.beam("Rod", Vector3(p0.x, y0, p0.y), Vector3(p1.x, y0 + 3.0 * STOREY - 1.0, p1.y), 0.07, 0.07)
				lm.beam("Rod", Vector3(p1.x, y0, p1.y), Vector3(p0.x, y0 + 3.0 * STOREY - 1.0, p0.y), 0.07, 0.07)
	lm.poly_prism("Roof", F.offset(poly, 0.2), TOP, TOP + 0.4)
	# Stainless service tower at the east corner.
	FhU.blk(lm, "Core", 31.0, 0.0, -29.0, 6.0, TOP + 1.0, 6.0)
	lm.commit(model)
