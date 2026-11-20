extends RefCounted

## KTH Royal Institute of Technology, the brick main campus on
## Valhallavägen/Osquars backe (Erik Lallerstedt, 1917 onward). Origin at
## the centroid of the KTH Entré range (OSM way 20682986, 118 x 23 m, three
## levels, bearing 152, registry yaw 62), front +Z (WSW).
##
## - The Entré bar is the long gate range: dark red brick, three storeys
##   under a hipped tile roof with a green copper gutter and a granite
##   plinth, rows of cream-framed windows, and the great round-headed
##   carriage arch through its middle with a window over it (front.jpg).
## - The E wing (OSM way 8107989, 156 x 47 m, five levels, firebrick, hipped
##   roof) runs back from the bar's east end on a cranked line: the same
##   brick, five storeys, a steeper tile roof.
##
## Sources: docs/stockholm-landmark-sources.md (Tier C), OSM ways 20682986
## and 8107989, Commons photos in visual-plan/refs/landmarks/kth_main/
## (front.jpg: arch and window rhythm; aerial.jpg: arcade and green copper
## gutter; quarter.jpg: the tile roof). Storey heights are about 4.6 m
## (Entré) and 3.9 m (E); window spacing is scaled from front.jpg.

const Far = preload("res://scripts/generation/landmarks/sweden_stockholm/outer/sto_far_kit.gd")

const BAR := [Vector2(-58.2, 4.7), Vector2(45.7, 11.0), Vector2(59.8, -0.6),
	Vector2(49.9, -11.7), Vector2(43.1, -5.8), Vector2(-57.1, -11.2)]
const WING := [Vector2(78.8, -9.7), Vector2(74.6, -14.5), Vector2(69.2, -10.0),
	Vector2(13.9, -67.7), Vector2(-27.1, -122.7), Vector2(-0.8, -145.5), Vector2(10.4, -133.5),
	Vector2(-6.0, -119.4), Vector2(44.9, -56.4), Vector2(57.3, -66.1), Vector2(68.3, -52.9),
	Vector2(81.7, -64.4), Vector2(90.5, -54.0), Vector2(78.7, -43.8), Vector2(94.7, -23.8)]
const BAR_EAVE := 15.0
const BAR_ROOF := 6.0
const WING_EAVE := 20.0
const WING_ROOF := 5.0

static func build(model: Node3D) -> void:
	var lm := Far.fresh(_materials())
	_range(lm, PackedVector2Array(BAR), BAR_EAVE, 6.0, BAR_ROOF, 3, 4.6, 3.4)
	_range(lm, PackedVector2Array(WING), WING_EAVE, 4.5, WING_ROOF, 5, 3.9, 3.6)
	_gate(lm)
	_chimneys(lm)
	lm.commit(model)

static func _materials() -> Dictionary:
	return {
		"Brick": LandmarkMaterials.pbr("brick", "#6E3629", 3.0),
		"Granite": LandmarkMaterials.pbr("stone", "#8D8478", 3.0),
		"Tile": LandmarkMaterials.pbr("terracotta", "#7A3C2E", 2.5),
		"Copper": LandmarkMaterials.pbr("copper", "#5A8670", 2.0),
		"Glass": LandmarkMaterials.glass("#26303A"),
		"Dark": LandmarkMaterials.pbr("brick", "#3B1F1A", 3.0),
	}

## One range: brick walls, granite plinth, window rows, copper gutter, tile hip.
static func _range(lm: LandmarkMesh, poly: PackedVector2Array, eave: float, inset: float, rise: float,
		rows: int, pitch: float, spacing: float) -> void:
	lm.poly_prism("Brick", poly, 0.0, eave, false)
	Far.band(lm, "Granite", poly, 0.0, 1.2, 0.25)
	Far.windows(lm, "Glass", poly, 2.0 if rows < 4 else 2.2, rows, pitch, spacing, 1.5, pitch - 2.0, 8.0)
	Far.band(lm, "Copper", poly, eave - 0.5, 0.5, 0.45)
	Far.hip_roof(lm, "Tile", poly, eave, inset, rise)

## The carriage arch through the Entré bar's middle: a dark round-headed
## opening on both faces under a granite-ringed brick arch and a window.
static func _gate(lm: LandmarkMesh) -> void:
	for f in [[8.2, 1.0], [-8.1, -1.0]]:
		var z: float = f[0]
		var s: float = f[1]
		var out := Vector3(0, 0, s)
		Far.FhU.opening(lm, "Dark", Vector3(0.0, 0.0, z + s * 0.1), out, 9.6, 9.0, true)
		lm.box("Granite", Vector3(-5.1, 4.5, z + s * 0.15), Vector3(0.8, 9.0, 0.3), Basis(), 0.0)
		lm.box("Granite", Vector3(5.1, 4.5, z + s * 0.15), Vector3(0.8, 9.0, 0.3), Basis(), 0.0)
		lm.box("Granite", Vector3(0.0, 11.2, z + s * 0.15), Vector3(6.0, 0.6, 0.6), Basis(), 0.0)

## Chimney stacks along the Entré ridge.
static func _chimneys(lm: LandmarkMesh) -> void:
	for x in [-44.0, -22.0, 22.0, 40.0]:
		lm.box("Brick", Vector3(x, BAR_EAVE + BAR_ROOF + 1.2, 0.0), Vector3(1.6, 3.6, 1.6), Basis(), 0.0)
