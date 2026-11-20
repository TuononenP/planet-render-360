class_name StoCityHallGarden
extends RefCounted

## The ground of City Hall on the Riddarfjärden side, and its night lights.
## From the aerial photo and OSM (park way 28953992, Stadshusträdgården,
## z 43.6..78.8; Engelbrekt's column is mapped at x 74, z 66.8):
## - A granite-paved terrace along the water front (z 33..47) raised 0.8 m,
##   four steps down to the garden paving; the garden runs to the quay
##   edge (z 78.8), whose granite kerb carries the dark railing.
## - West of the centre a box-hedge parterre in an ornamental scroll; in
##   the middle two round stone basins and the two flagpoles (the city's
##   and the European flag); bronze figures on stone pedestals.
## - On the east corner of the quay Engelbrekt's column: a red granite
##   shaft on a plinth under his bronze figure, as tall as the shaft of
##   the tower's first stage.
## Night: FLOOD_META spots wash the water front, the west and north walls
## and, from the quay, the tower shaft and its gilded lantern.

const X0 := -84.0
const X1 := 78.0
const Z_QUAY := 78.4

static func build(lm: LandmarkMesh) -> void:
	_paving(lm)
	_parterre(lm)
	_basins_and_flags(lm)
	_figures(lm)
	_railing(lm)
	_engelbrekt(lm, Vector3(74.0, 0.0, 66.8))

static func _paving(lm: LandmarkMesh) -> void:
	# Terrace slab under the loggia, the steps, and the garden paving.
	lm.box("Stone", Vector3((X0 + X1) * 0.5, 0.4, 40.0), Vector3(X1 - X0, 0.8, 14.0))
	for k in 4:
		var top := 0.6 - 0.15 * float(k)
		lm.box("Stone", Vector3((X0 + X1) * 0.5, top * 0.5, 47.15 + 0.3 * float(k)), Vector3(X1 - X0, top, 0.3))
	lm.box("Granite", Vector3((X0 + X1) * 0.5, 0.06, (48.3 + Z_QUAY) * 0.5), Vector3(X1 - X0, 0.12, Z_QUAY - 48.3))
	lm.box("Granite", Vector3((X0 + X1) * 0.5, 0.3, Z_QUAY + 0.4), Vector3(X1 - X0 + 0.8, 0.6, 0.8))
	lm.box("Granite", Vector3(X1 + 0.4, 0.3, (33.0 + Z_QUAY) * 0.5), Vector3(0.8, 0.6, Z_QUAY - 33.0))

## Box-hedge parterre: a frame, two scrolls and a central ring.
static func _parterre(lm: LandmarkMesh) -> void:
	var c := Vector3(-47.0, 0.0, 66.0)
	lm.box("Stone", c + Vector3(0, 0.1, 0), Vector3(24.0, 0.2, 18.0), Basis(), 0.0)
	for e in [[0.0, -8.6, 23.0, 0.7], [0.0, 8.6, 23.0, 0.7], [-11.6, 0.0, 0.7, 17.0], [11.6, 0.0, 0.7, 17.0]]:
		lm.box("Hedge", c + Vector3(float(e[0]), 0.5, float(e[1])), Vector3(float(e[2]), 0.6, float(e[3])))
	for sx in [-1.0, 1.0]:
		lm.box("Hedge", c + Vector3(sx * 5.5, 0.4, 0.0), Vector3(5.5, 0.4, 0.6))
		lm.box("Hedge", c + Vector3(sx * 8.4, 0.4, -2.8), Vector3(0.6, 0.4, 5.6))
		lm.box("Hedge", c + Vector3(sx * 3.0, 0.4, 4.4), Vector3(0.6, 0.4, 4.0))
		lm.box("Hedge", c + Vector3(sx * 3.0, 0.4, -4.4), Vector3(0.6, 0.4, 4.0))
	lm.frustum("Hedge", c + Vector3(0, 0.2, 0), 2.6, 2.3, 0.5, 16)

static func _basins_and_flags(lm: LandmarkMesh) -> void:
	for x in [-16.0, 36.0]:
		var c := Vector3(float(x), 0.12, 61.0)
		lm.lathe("Stone", c, PackedVector2Array([Vector2(2.7, 0.0), Vector2(2.7, 0.75), Vector2(2.3, 0.75),
			Vector2(2.3, 0.3)]), 20, 1.0, 1.0, 0.0, true, false)
		lm.disc("Water", c + Vector3(0, 0.55, 0), Vector3.UP, 2.3, 20)
	# The city flag and the European flag, 19.3 m apart (aerial photo).
	for i in 2:
		var p := Vector3(0.5 + 19.3 * float(i), 0.12, 65.0)
		lm.frustum("Bronze", p, 0.12, 0.07, 12.5, 6)
		lm.lathe("Gilt", p + Vector3(0, 12.5, 0), PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.14, 0.1),
			Vector2(0.0, 0.3)]), 6)
		var fc := p + Vector3(0, 11.2, 1.3)
		for s in [-1.0, 1.0]:
			var n := Vector3(0, 0, s)
			lm.quad("FlagBlue", fc + Vector3(-1.3, -0.8, 0), fc + Vector3(1.3, -0.8, 0), fc + Vector3(1.3, 0.8, 0),
				fc + Vector3(-1.3, 0.8, 0), n)
			if i == 0:
				lm.quad("FlagYellow", fc + Vector3(-0.35, -0.5, 0.01 * s), fc + Vector3(0.35, -0.5, 0.01 * s),
					fc + Vector3(0.35, 0.3, 0.01 * s), fc + Vector3(-0.35, 0.3, 0.01 * s), n)
			else:
				for k in 8:
					var a := TAU * float(k) / 8.0
					var sp := fc + Vector3(cos(a) * 0.5, sin(a) * 0.5, 0.01 * s)
					lm.quad("FlagYellow", sp + Vector3(-0.07, -0.07, 0), sp + Vector3(0.07, -0.07, 0),
						sp + Vector3(0.07, 0.07, 0), sp + Vector3(-0.07, 0.07, 0), n)

## Bronze figures on stone pedestals along the garden.
static func _figures(lm: LandmarkMesh) -> void:
	for p in [Vector2(-26.0, 53.0), Vector2(30.0, 53.0), Vector2(-33.0, 70.0), Vector2(8.0, 74.0), Vector2(52.0, 62.0)]:
		var base := Vector3(p.x, 0.12, p.y)
		lm.box("Stone", base + Vector3(0, 0.9, 0), Vector3(1.4, 1.8, 1.4))
		lm.box("Stone", base + Vector3(0, 1.9, 0), Vector3(1.8, 0.2, 1.8), Basis(), 0.0)
		LandmarkKits.statue_figure(lm, "Bronze", base + Vector3(0, 2.0, 0), 2.7)

## Dark railing along the quay edge and round the east corner.
static func _railing(lm: LandmarkMesh) -> void:
	var y := 0.6
	var n := int((X1 - X0) / 3.0)
	for k in n + 1:
		lm.box("Bronze", Vector3(X0 + (X1 - X0) * float(k) / float(n), y + 0.55, Z_QUAY + 0.2), Vector3(0.12, 1.1, 0.12), Basis(), 0.0)
	lm.box("Bronze", Vector3((X0 + X1) * 0.5, y + 1.05, Z_QUAY + 0.2), Vector3(X1 - X0, 0.1, 0.1), Basis(), 0.0)
	lm.box("Bronze", Vector3((X0 + X1) * 0.5, y + 0.5, Z_QUAY + 0.2), Vector3(X1 - X0, 0.08, 0.08), Basis(), 0.0)
	var m := int((Z_QUAY - 47.0) / 3.0)
	for k in m + 1:
		lm.box("Bronze", Vector3(X1 + 0.3, y + 0.55, 47.0 + (Z_QUAY - 47.0) * float(k) / float(m)), Vector3(0.12, 1.1, 0.12), Basis(), 0.0)
	lm.box("Bronze", Vector3(X1 + 0.3, y + 1.05, (47.0 + Z_QUAY) * 0.5), Vector3(0.1, 0.1, Z_QUAY - 47.0), Basis(), 0.0)

## Engelbrekt's column: red granite shaft on a stone plinth, bronze figure.
static func _engelbrekt(lm: LandmarkMesh, c: Vector3) -> void:
	var y := 0.12
	lm.box("Granite", c + Vector3(0, y + 0.5, 0), Vector3(3.2, 1.0, 3.2))
	lm.box("Granite", c + Vector3(0, y + 1.5, 0), Vector3(2.4, 1.0, 2.4))
	lm.lathe("Tile", c + Vector3(0, y + 2.0, 0), PackedVector2Array([Vector2(0.95, 0.0), Vector2(0.82, 0.3),
		Vector2(0.75, 11.0), Vector2(0.62, 11.0), Vector2(0.62, 11.2)]), 16, 1.0, 1.0, 0.0, true, false)
	lm.box("Stone", c + Vector3(0, y + 13.35, 0), Vector3(1.6, 0.3, 1.6))
	lm.box("Stone", c + Vector3(0, y + 13.75, 0), Vector3(1.2, 0.5, 1.2))
	LandmarkKits.statue_figure(lm, "Bronze", c + Vector3(0, y + 14.0, 0), 3.4)

## Floodlights: the water front, the tower and its lantern from the quay,
## the west and north faces.
static func lights(model: Node3D) -> void:
	var warm := Color(1.0, 0.84, 0.58)
	var cool := Color(1.0, 0.95, 0.82)
	var spots: Array = []
	for x in [-40.0, -12.0, 16.0, 40.0]:
		spots.append([Vector3(x, 1.0, 62.0), Vector3(x, 14.0, 35.5), 50.0, 1.0, 80.0, warm])
	spots.append([Vector3(50.0, 1.0, 58.0), Vector3(61.0, 36.0, 32.0), 36.0, 1.3, 120.0, warm])
	spots.append([Vector3(82.0, 1.0, 46.0), Vector3(63.0, 34.0, 32.0), 36.0, 1.0, 110.0, warm])
	spots.append([Vector3(84.0, 1.0, 12.0), Vector3(66.0, 42.0, 24.0), 34.0, 0.9, 120.0, warm])
	spots.append([Vector3(52.0, 1.0, 54.0), Vector3(61.05, 92.0, 31.7), 22.0, 1.4, 130.0, cool])
	spots.append([Vector3(-80.0, 1.0, 0.0), Vector3(-66.0, 14.0, 0.0), 50.0, 0.8, 65.0, warm])
	spots.append([Vector3(10.0, 1.0, -52.0), Vector3(10.0, 14.0, -37.5), 50.0, 0.9, 70.0, warm])
	spots.append([Vector3(-50.0, 1.0, -48.0), Vector3(-50.0, 14.0, -34.0), 50.0, 0.7, 65.0, warm])
	model.set_meta(LandmarkLights.FLOOD_META, spots)
