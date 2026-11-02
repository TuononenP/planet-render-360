class_name LandmarkFrAalto
extends RefCounted

## Three buildings by Alvar Aalto in true metres, in the frame of the real
## plan (+X east, +Z south, turned onto the map by yaw_deg): the Lakeuden
## Risti church and campanile in Seinajoki, the Saynatsalo Town Hall and the
## Church of the Three Crosses in Vuoksenniska, Imatra. Plans follow the
## OpenStreetMap footprints.

## Lakeuden Risti (Cross of the Plains), Seinajoki, 1960: the long white
## church narrowing to the west, its roof stepping up in three volumes
## towards the altar at the east end, tall slit windows along the south
## wall, and Aalto's free-standing campanile, 65 m of white concrete that
## tapers up to an open bell frame and a great cross on top.
const LAKEUDEN_TOP := 65.0

static func lakeuden_risti(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F0EEE8", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("membrane", "#55524F", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#D4D1C9", 4.0))
	lm.use("Copper", LandmarkFrKit.copper("#6E9482"))
	var west := PackedVector2Array([Vector2(-27.2, -15), Vector2(-12, -10), Vector2(-12, 15), Vector2(-31.6, 15),
		Vector2(-30, 9.5), Vector2(-35, 9.5)])
	var mid := PackedVector2Array([Vector2(-12, -10), Vector2(16, -0.6), Vector2(15.8, 12.9), Vector2(14.4, 15),
		Vector2(-12, 15)])
	var east := PackedVector2Array([Vector2(16, -0.6), Vector2(17.4, -0.3), Vector2(21.3, -11.6), Vector2(35, -6.9),
		Vector2(27.6, 14.2), Vector2(15.8, 12.9)])
	var heights := [9.0, 13.0, 18.0]
	var vols := [west, mid, east]
	for i in 3:
		var poly: PackedVector2Array = vols[i]
		var h: float = heights[i]
		lm.poly_prism("White", poly, -0.5, h, false)
		var c := Vector2.ZERO
		for p in poly:
			c += p
		c /= float(poly.size())
		var cap := PackedVector2Array()
		for p in poly:
			cap.append(c + (p - c) * 0.98)
		lm.poly_prism("Roof", cap, h - 0.3, h + 0.35)
	# Tall slit windows along the south wall.
	for k in 11:
		var x := -28.0 + 3.9 * float(k)
		var h2: float = 9.0 if x < -12.0 else (13.0 if x < 15.0 else 16.0)
		if x > 14.0:
			continue
		lm.box("Glass", Vector3(x, h2 * 0.5 + 0.5, 15.02), Vector3(0.9, h2 - 2.5, 0.15))
	# Campanile at the north-east of the church: tapering shaft, open bell
	# frame (piers and slabs) and the cross.
	var tx := 21.0
	var tz := -21.7
	lm.frustum("Concrete", Vector3(tx, -1.0, tz), 4.81, 3.9, 49.0, 4, PI / 4.0, 1.0, 0.75)
	for k in 5:
		lm.box("Glass", Vector3(tx, 8.0 + 8.0 * float(k), tz + 2.4), Vector3(0.7, 3.0, 0.15))
	lm.box("Concrete", Vector3(tx, 48.4, tz), Vector3(6.0, 1.0, 4.8))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Concrete", Vector3(tx + sx * 2.2, 53.4, tz + sz * 1.6), Vector3(1.2, 9.0, 1.2))
	lm.box("Concrete", Vector3(tx, 58.2, tz), Vector3(6.0, 1.0, 4.8))
	lm.box("Copper", Vector3(tx, 53.0, tz), Vector3(1.6, 1.8, 1.6))
	lm.box("Concrete", Vector3(tx, 61.7, tz), Vector3(1.0, 6.6, 1.0))
	lm.box("Concrete", Vector3(tx, 63.6, tz), Vector3(4.4, 1.0, 1.0))
	lm.commit(model)

## Saynatsalo Town Hall (Saynatsalon kunnantalo), 1952: the red-brick civic
## centre round a raised, grassed courtyard on the island of Saynatsalo, a
## low office wing, the library over shops (ground floor glazed, flats above)
## and the council chamber, the highest block, at the corner with its
## mono-pitch roof rising towards the court; timber posts line the court.
const SAYNATSALO_TOP := 14.6

static func saynatsalo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8C4A38", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("membrane", "#413F3D", 3.0))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#B38A5C", 1.8))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#6E8F55", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8C877C", 3.0))
	# Raised courtyard (x -8.5..11.4, z -5.8..9.9) on a brick plinth.
	LandmarkFrKit.rect(lm, "Brick", -8.5, 11.4, -5.8, 14.3, -0.5, 1.8)
	LandmarkFrKit.rect(lm, "Lawn", -8.2, 11.1, -5.5, 13.8, 1.8, 1.95)
	for k in 5:
		LandmarkFrKit.rect(lm, "Stone", -5.0 + 2.0 * float(k), -3.4 + 2.0 * float(k), 12.0 + 0.4 * float(k),
			13.8, 1.95, 2.0 + 0.1 * float(k))
	# Office wing (west), library and flats (north), east link.
	LandmarkFrKit.rect(lm, "Brick", -21.1, -8.5, -14.3, 9.9, 0.0, 7.4)
	LandmarkFrKit.rect(lm, "Roof", -21.4, -8.2, -14.6, 10.2, 7.4, 7.9)
	LandmarkFrKit.rect(lm, "Brick", -8.5, 17.6, -14.3, -5.8, 0.0, 8.2)
	LandmarkFrKit.rect(lm, "Roof", -8.5, 17.9, -14.6, -5.5, 8.2, 8.7)
	LandmarkFrKit.rect(lm, "Brick", 11.4, 17.6, -5.8, 2.5, 0.0, 7.4)
	LandmarkFrKit.rect(lm, "Roof", 11.2, 17.9, -5.8, 2.8, 7.4, 7.9)
	# Council chamber block: brick walls to 12 m, wedge ends, roof rising to 14.6.
	LandmarkFrKit.rect(lm, "Brick", 5.9, 21.1, 2.5, 14.3, 0.0, 12.0)
	lm.box("Brick", Vector3(5.95, 13.3, 8.4), Vector3(0.1, 2.6, 11.8))
	for z in [2.5, 14.3]:
		var n := Vector3(0, 0, 1.0 if z > 3.0 else -1.0)
		lm.tri("Brick", Vector3(5.9, 12.0, z), Vector3(21.1, 12.0, z), Vector3(5.9, 14.6, z), n, n, n,
			Vector2(0, 0), Vector2(15.2, 0), Vector2(0, -2.6))
	lm.quad("Roof", Vector3(5.9, 14.6, 2.5), Vector3(21.1, 12.0, 2.5), Vector3(21.1, 12.0, 14.3),
		Vector3(5.9, 14.6, 14.3), Vector3(0.17, 1.0, 0).normalized())
	# Windows and the timber posts along the courtyard front.
	for k in 8:
		lm.box("Glass", Vector3(-6.0 + 3.0 * float(k), 5.8, -14.35), Vector3(1.8, 1.4, 0.15))
		lm.box("Glass", Vector3(-6.0 + 3.0 * float(k), 1.8, -14.35), Vector3(2.2, 2.4, 0.15))
	for k in 7:
		lm.box("Glass", Vector3(-21.15, 3.6, -12.0 + 3.4 * float(k)), Vector3(0.15, 1.8, 2.0))
		lm.box("Glass", Vector3(-8.45, 3.6, -12.0 + 3.4 * float(k)), Vector3(0.15, 1.8, 1.8))
	for k in 10:
		lm.box("Timber", Vector3(-7.4 + 1.8 * float(k), 5.1, -5.7), Vector3(0.28, 6.4, 0.28))
	for k in 5:
		lm.box("Glass", Vector3(8.5 + 3.0 * float(k), 5.0, 14.35), Vector3(1.6, 4.8, 0.15))
	lm.commit(model)

## Church of the Three Crosses (Kolmen Ristin kirkko), Vuoksenniska, Imatra,
## 1958: three white plastered halls in a row (separable by sliding walls)
## each under its own copper roof stepped higher towards the middle, and the
## slender 34 m bell tower, cast in concrete, whose top widens in three
## stages, beside them.
const VUOKSEN_TOP := 34.0

static func vuoksenniska(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F1EFE9", 3.0))
	lm.use("Copper", LandmarkFrKit.copper("#6F9683"))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#D6D3CB", 4.0))
	# Three halls in a row: wall, then the copper roof rising towards the north.
	var halls := [[-19.5, -5.0, -15.0, 3.0, 7.0, 3.0], [-5.0, 9.5, -17.3, 4.7, 7.8, 4.6],
		[9.5, 19.7, -17.6, 5.0, 7.2, 3.4]]
	for h in halls:
		var x0: float = h[0]
		var x1: float = h[1]
		var z0: float = h[2]
		var z1: float = h[3]
		var eave: float = h[4]
		var rise: float = h[5]
		LandmarkFrKit.rect(lm, "White", x0, x1, z0, z1, 0.0, eave)
		# Mono-pitch copper roof: low on the south side, high on the north.
		var n := Vector3(0, (z1 - z0), rise).normalized()
		lm.quad("Copper", Vector3(x0 - 0.4, eave, z1 + 0.5), Vector3(x1 + 0.4, eave, z1 + 0.5),
			Vector3(x1 + 0.4, eave + rise, z0 - 0.4), Vector3(x0 - 0.4, eave + rise, z0 - 0.4), n)
		for sx in [x0, x1]:
			lm.tri("White", Vector3(sx, eave, z1), Vector3(sx, eave, z0), Vector3(sx, eave + rise, z0),
				Vector3(1 if sx == x1 else -1, 0, 0), Vector3(1 if sx == x1 else -1, 0, 0),
				Vector3(1 if sx == x1 else -1, 0, 0), Vector2(0, 0), Vector2(z1 - z0, 0), Vector2(z1 - z0, -rise))
		lm.box("White", Vector3((x0 + x1) * 0.5, eave + rise * 0.5, z0 - 0.0), Vector3(x1 - x0, rise, 0.5))
		for k in 3:
			lm.box("Glass", Vector3(x0 + (x1 - x0) * (0.2 + 0.3 * float(k)), eave * 0.55, z1 + 0.04),
				Vector3(1.2, eave * 0.55, 0.12))
	# Bell tower: three stacked white volumes on a shaft.
	var tx := 3.0
	var tz := 12.5
	lm.box("White", Vector3(tx, 11.0, tz), Vector3(4.4, 22.0, 4.4))
	for k in 3:
		var y := 22.0 + 3.7 * float(k)
		var w := 4.8 + 0.6 * float(k)
		lm.box("White", Vector3(tx, y + 1.5, tz), Vector3(w, 3.0, w))
		lm.box("Glass", Vector3(tx, y + 1.5, tz + w * 0.5 + 0.04), Vector3(w * 0.5, 1.8, 0.1))
		lm.box("Glass", Vector3(tx + w * 0.5 + 0.04, y + 1.5, tz), Vector3(0.1, 1.8, w * 0.5))
		lm.box("Concrete", Vector3(tx, y + 3.2, tz), Vector3(w + 0.5, 0.4, w + 0.5))
	lm.box("Concrete", Vector3(tx, 33.4, tz), Vector3(0.3, 1.4, 0.3))
	lm.commit(model)
