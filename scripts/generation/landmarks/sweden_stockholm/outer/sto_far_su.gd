extends RefCounted

## Stockholm University, Södra huset (1971, Frescati), the campus's
## signature slab complex. Origin at the centroid of OSM way 5879630
## (243.8 x 85.8 m, eight levels), long spine along +X (bearing 93,
## registry yaw 3), front +Z (south, toward the fingers).
##
## A 242 x 25 m spine at the north with six 14.5 m wide, 60 m long
## fingers reaching south at a 41 m pitch, each with a small step 8 m in
## from its south end (the mapped 40-point outline is used as is). Every
## block is eight storeys of pale blue-grey enamelled panels with paired
## ribbon windows, a dark glazed ground storey, flat roofs behind a low
## parapet with rooftop plant boxes and stair cores.
##
## Sources: OSM way 5879630 (building:colour PaleTurquoise, levels 8,
## start 1971), the Commons photos in
## visual-plan/refs/landmarks/stockholm_university/ (front.jpg, quarter.jpg:
## the panel colour, window rhythm and rooftop plant; aerial.jpg shows the
## neighbouring Aula Magna, not modelled). Storey height 3.6 m is scaled
## from quarter.jpg; the rooftop plant boxes are approximate.

const Far = preload("res://scripts/generation/landmarks/sweden_stockholm/outer/sto_far_kit.gd")

const OUTLINE := [Vector2(13.3, 50.3), Vector2(28.8, 50.3), Vector2(29.0, 17.8),
	Vector2(35.3, 17.8), Vector2(35.4, -10.6), Vector2(55.4, -10.5), Vector2(55.1, 50.3), Vector2(69.3, 50.3),
	Vector2(69.5, 18.3), Vector2(76.5, 18.3), Vector2(76.7, -10.4), Vector2(96.8, -10.3), Vector2(96.5, 50.3),
	Vector2(110.3, 50.3), Vector2(110.4, 18.8), Vector2(115.8, 18.8), Vector2(115.9, -10.2),
	Vector2(126.0, -10.0), Vector2(126.1, -31.4), Vector2(-116.1, -35.5), Vector2(-117.7, -11.2),
	Vector2(-109.8, -11.4), Vector2(-111.1, 50.2), Vector2(-93.9, 50.4), Vector2(-93.7, 16.4),
	Vector2(-87.4, 16.4), Vector2(-87.3, -11.2), Vector2(-67.5, -11.2), Vector2(-67.9, 50.3),
	Vector2(-52.2, 50.4), Vector2(-52.0, 16.9), Vector2(-46.2, 16.9), Vector2(-46.0, -11.0),
	Vector2(-26.8, -11.0), Vector2(-27.1, 50.3), Vector2(-12.6, 50.3), Vector2(-12.5, 17.3),
	Vector2(-5.9, 17.4), Vector2(-5.8, -10.8), Vector2(13.7, -10.7)]
const FLOORS := 8
const FLOOR_H := 3.6
const WALL_H := FLOORS * FLOOR_H + 0.6
const PLANT_H := 1.9

static func build(model: Node3D) -> void:
	var lm := Far.fresh(_materials())
	var poly := PackedVector2Array(OUTLINE)
	lm.poly_prism("Panel", poly, 0.0, WALL_H, false)
	Far.band(lm, "Dark", poly, 0.0, 3.2, 0.15)
	Far.windows(lm, "Glass", poly, 4.5, FLOORS - 1, FLOOR_H, 2.7, 1.5, 1.4, 6.0)
	for k in FLOORS - 1:
		Far.band(lm, "Seam", poly, 3.2 + FLOOR_H * float(k), 0.18, 0.08)
	Far.band(lm, "Panel", poly, WALL_H - 0.7, 0.7, 0.2)
	lm.poly_prism("Roof", poly, WALL_H - 0.02, WALL_H + 0.05, true)
	_plant(lm)
	lm.commit(model)

static func _materials() -> Dictionary:
	return {
		"Panel": LandmarkMaterials.pbr("concrete", "#A3BDBB", 3.0),
		"Seam": LandmarkMaterials.pbr("concrete", "#8FA6A6", 3.0),
		"Dark": LandmarkMaterials.pbr("concrete", "#2E3A3E", 3.0),
		"Glass": LandmarkMaterials.glass("#2A3A44"),
		"Roof": LandmarkMaterials.pbr("concrete", "#6E7273", 3.0),
		"Plant": LandmarkMaterials.pbr("concrete", "#A9B3B3", 3.0),
	}

## Rooftop plant: a long box on the spine, a stair core and a box on every
## finger (the tallest reaches the 31 m registry height).
static func _plant(lm: LandmarkMesh) -> void:
	var top := WALL_H + 0.05
	for x in [-100.0, -60.0, -20.0, 20.0, 62.0, 104.0]:
		lm.box("Plant", Vector3(x, top + PLANT_H * 0.5, 5.0), Vector3(11.0, PLANT_H, 9.0), Basis(), 0.0)
		lm.box("Plant", Vector3(x + 0.5, top + PLANT_H * 0.5 - 0.2, 40.0), Vector3(7.0, PLANT_H - 0.4, 6.0),
			Basis(), 0.0)
	for x in [-80.0, -40.0, 0.0, 42.0, 84.0]:
		lm.box("Plant", Vector3(x, top + PLANT_H * 0.5 - 0.3, -22.0), Vector3(16.0, PLANT_H - 0.6, 6.0), Basis(), 0.0)
