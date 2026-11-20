extends RefCounted

## Lauttasaari Church (Lauttasaaren kirkko, Keijo and Marja Petaja, 1958), the
## church hall complex round its raised churchyard with the slender
## cross-crowned bell tower. Origin at the church entry (OSM way 8597256), yaw
## 0; the bell tower (OSM way 404164145, 61 m) stands 7.8 m east and 4.8 m
## north of it.
##
## From the Commons photos (visual-plan/refs/landmarks/lauttasaari_church/):
## - The halls stand on a dark brown brick base with timber doors. Above runs
##   a band of dark verdigris copper cladding, then three tiers of tall glazed
##   panes between green-patinated copper piers, under a thick copper fascia.
## - The tower is pale cast-stone ashlar in even courses, 5.0 x 4.4 m, with a
##   clock on its face, a tall column of vertical louvre slits, a cap of
##   green fins at the bell stage and a copper cross above.
## - A broad stair of dark stone treads leads up to the churchyard.
##
## Measured: the complex outline and the 61 m tower (OSM); the City LoD2 has
## the halls at up to 17.3 m and the tower missing. Estimated: the halls'
## 10 m eaves (the nave is higher than the rest), the band heights, tower
## detailing and all colours.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

## Bell tower centre about the church entry (OSM way 404164145).
const TOWER := Vector2(7.8, -4.8)
const TOWER_M := 61.0

const ENTRY := {"type": "lauttasaari_church", "name": "Lauttasaari Church", "lat": 60.158735, "lon": 24.869437,
	"radius_m": 5000.0, "wiki_title": "Lauttasaari Church", "height_m": 61.0, "clear_m": 24.0,
	"clear_offsets_m": [[-5.0, 24.0], [-5.0, -28.0], [-37.0, 12.0], [-1.0, 8.0]],
	"kind": "Church", "aliases": ["lauttasaari church", "lauttasaaren kirkko", "drumsö kyrka"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#5F4638", 2.5))
	lm.use("Copper", LandmarkMaterials.paint("#2F4B45", 0.55, 0.45))
	lm.use("Pier", LandmarkMaterials.paint("#3F6A5E", 0.5, 0.5))
	lm.use("Glass", LandmarkMaterials.glass("#2E3B40"))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#C9BD9F", 2.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#CFCBC0", 3.0))
	lm.use("Metal", LandmarkMaterials.paint("#2F3335", 0.5))
	lm.use("Roof", LandmarkMaterials.paint("#4A4E4E", 0.8))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2B0", 0.6))
	var poly := W.outline("lauttasaari_church")
	var eave := 10.0
	lm.poly_prism("Brick", poly, 0.0, 3.8)
	lm.poly_prism("Copper", F.offset(poly, 0.05), 3.8, 6.2)
	lm.poly_prism("Glass", F.offset(poly, 0.02), 6.2, eave - 0.9)
	W.ribs(lm, "Pier", poly, 6.2, eave - 0.9, 3.6, 0.5, 0.25)
	lm.poly_prism("Copper", F.offset(poly, 0.3), eave - 0.9, eave)
	lm.poly_prism("Roof", F.offset(poly, -0.4), eave, eave + 0.2)
	# Glazed upper tiers glow warm at night.
	lm.poly_prism("Lamp", F.offset(poly, 0.0), 6.6, eave - 1.3, false)
	# Tower: pale ashlar shaft with courses, a clock, a louvre column.
	var shaft := 54.0
	U.blk(lm, "Stone", TOWER.x, 0.0, TOWER.y, 5.0, shaft, 4.4)
	for k in range(1, 49):
		var y := 1.1 * float(k)
		for s in [-1.0, 1.0]:
			U.blk(lm, "Concrete", TOWER.x, y, TOWER.y + s * 2.2, 5.04, 0.05, 0.06)
			U.blk(lm, "Concrete", TOWER.x + s * 2.5, y, TOWER.y, 0.06, 0.05, 4.44)
	for k in 14:
		var y := 13.0 + 2.8 * float(k)
		U.blk(lm, "Metal", TOWER.x, y, TOWER.y + 2.23, 1.6, 2.0, 0.08)
	lm.disc("Lamp", Vector3(TOWER.x - 1.0, 44.5, TOWER.y + 2.27), Vector3(0, 0, 1), 0.55, 20)
	# The bell stage: green fins round the top, then the crowning cross.
	for k in 7:
		var off := (float(k) - 3.0) * 0.7
		U.blk(lm, "Pier", TOWER.x + off, shaft - 6.0, TOWER.y + 2.0, 0.3, 8.0, 0.3)
		U.blk(lm, "Pier", TOWER.x + off, shaft - 6.0, TOWER.y - 2.0, 0.3, 8.0, 0.3)
	U.blk(lm, "Stone", TOWER.x, shaft, TOWER.y, 5.4, 0.5, 4.8)
	U.blk(lm, "Pier", TOWER.x, shaft + 0.5, TOWER.y, 0.4, TOWER_M - shaft - 0.5, 0.4)
	U.blk(lm, "Pier", TOWER.x, TOWER_M - 2.6, TOWER.y, 3.0, 0.4, 0.4)
	lm.commit(model, "Lauttasaari_church_")
