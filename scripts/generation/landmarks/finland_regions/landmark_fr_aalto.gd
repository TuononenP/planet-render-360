class_name LandmarkFrAalto
extends RefCounted

## Three buildings by Alvar Aalto in true metres, in the frame of the real
## plan (+X east, +Z south, turned onto the map by yaw_deg): the Lakeuden
## Risti church and campanile in Seinajoki, the Saynatsalo Town Hall and the
## Church of the Three Crosses in Vuoksenniska, Imatra. Plans follow the
## OpenStreetMap footprints.

## Lakeuden Risti (Cross of the Plains), Seinajoki, built 1957-59,
## consecrated 1960: the white church (whitewashed brick on a polished
## black granite base, copper roof; the hall 47 m long, 1,200 seats) that
## narrows to the west, its roof stepping up in three volumes towards the
## altar at the east end, tall slit windows along the south wall, and the
## free-standing campanile north of it, 65.2 m of white concrete that
## tapers up to the open bell frame for its three bells, clock faces on
## every side, the observation platform (276 steps) and the great cross.
const LAKEUDEN_TOP := 65.0

static func lakeuden_risti(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F0EEE8", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("membrane", "#55524F", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#D4D1C9", 4.0))
	lm.use("Copper", LandmarkFrKit.copper("#6E9482"))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#2B2B2D", 2.0))
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
		lm.poly_prism("White", poly, 0.0, h, false)
		var c := Vector2.ZERO
		for p in poly:
			c += p
		c /= float(poly.size())
		var cap := PackedVector2Array()
		var base := PackedVector2Array()
		for p in poly:
			cap.append(c + (p - c) * 0.98)
			base.append(c + (p - c) + (p - c).normalized() * 0.08)
		lm.poly_prism("Roof", cap, h - 0.3, h + 0.35)
		lm.poly_prism("Granite", base, 0.0, 1.4, false)
		# Copper flashing round the roof edge.
		for k in poly.size():
			var a := poly[k]
			var b := poly[(k + 1) % poly.size()]
			lm.beam("Copper", Vector3(a.x, h + 0.25, a.y), Vector3(b.x, h + 0.25, b.y), 0.5, 0.25, Vector3.UP)
	# Tall slit windows along the south wall with their mullions, the
	# clerestory band of the altar volume and the west entrance.
	for k in 11:
		var x := -28.0 + 3.9 * float(k)
		var h2: float = 9.0 if x < -12.0 else (13.0 if x < 15.0 else 16.0)
		if x > 14.0:
			continue
		LandmarkFrParts.opening(lm, "White", "Glass", Vector3(x, 1.6, 15.0), Vector3.BACK, 0.9, h2 - 3.0,
			LandmarkFrParts.HEAD_FLAT, 0.14, 0.12)
		for j in int((h2 - 3.0) / 1.5):
			lm.box("White", Vector3(x, 1.6 + 1.5 * float(j + 1), 15.08), Vector3(0.9, 0.08, 0.08), Basis(), 0.0)
	LandmarkFrParts.facade(lm, "White", "Glass", Vector3(35.0, 13.0, -6.9), Vector3(27.6, 13.0, 14.2),
		Vector3(0.94, 0, 0.33), 4.6, 8, 1, Vector2(1.6, 2.6), 1.0, 3.0, 0.2)
	LandmarkFrParts.opening(lm, "Concrete", "Glass", Vector3(-31.0, 0.0, 15.0), Vector3.BACK, 3.0, 3.0,
		LandmarkFrParts.HEAD_FLAT, 0.25, 0.2, 2)
	lm.box("Concrete", Vector3(-31.0, 3.3, 16.4), Vector3(5.0, 0.3, 3.0))
	for k2 in 4:
		LandmarkFrParts.opening(lm, "White", "Glass", Vector3(-6.0 + 5.5 * float(k2), 9.0, -10.0 + 0.336 * float(k2) * 5.5
			+ 2.0), Vector3(0.32, 0, -0.95), 1.2, 3.0, LandmarkFrParts.HEAD_FLAT, 0.12, 0.12)
	# Campanile north-east of the church: tapering white shaft with its
	# vertical grooves and slit windows, clock faces, the platform, the
	# open bell frame with the three bells, and the cross.
	var tx := 21.0
	var tz := -21.7
	lm.frustum("Concrete", Vector3(tx, 0.0, tz), 4.81, 3.9, 48.0, 4, PI / 4.0, 1.0, 0.75)
	lm.frustum("Granite", Vector3(tx, 0.0, tz), 4.95, 4.9, 1.2, 4, PI / 4.0, 1.0, 0.76)
	for s: float in [-1.0, 1.0]:
		for k3 in 2:
			var gx := tx + s * (0.8 + 1.0 * float(k3))
			lm.beam("White", Vector3(gx, 1.2, tz + 2.56), Vector3(gx * 0.81 + tx * 0.19, 47.5, tz + 2.09), 0.18, 0.12)
			lm.beam("White", Vector3(gx, 1.2, tz - 2.56), Vector3(gx * 0.81 + tx * 0.19, 47.5, tz - 2.09), 0.18, 0.12)
	for k4 in 9:
		var y := 6.0 + 4.6 * float(k4)
		var zf := 2.55 - 0.48 * y / 48.0
		LandmarkFrParts.opening(lm, "", "Glass", Vector3(tx, y, tz + zf + 0.02), Vector3.BACK, 0.6, 2.4)
	for f in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
		var fn: Vector3 = rb * Vector3(0, 0, 1)
		var half := 2.11 if f % 2 == 0 else 2.81
		lm.disc("White", Vector3(tx, 44.0, tz) + fn * (half + 0.1), fn, 1.3, 24)
		lm.disc("Granite", Vector3(tx, 44.0, tz) + fn * (half + 0.14), fn, 1.1, 24)
	lm.box("Concrete", Vector3(tx, 48.4, tz), Vector3(6.0, 1.0, 4.8))
	var rail := [Vector3(tx - 3.0, 48.9, tz - 2.4), Vector3(tx + 3.0, 48.9, tz - 2.4), Vector3(tx + 3.0, 48.9, tz + 2.4),
		Vector3(tx - 3.0, 48.9, tz + 2.4)]
	for k5 in 4:
		LandmarkFrParts.railing(lm, "Copper", rail[k5] as Vector3, rail[(k5 + 1) % 4] as Vector3, 1.1, 1.2, 0.06)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			lm.box("Concrete", Vector3(tx + sx * 2.2, 53.4, tz + sz * 1.6), Vector3(1.2, 9.0, 1.2))
	lm.box("Concrete", Vector3(tx, 58.2, tz), Vector3(6.0, 1.0, 4.8))
	for k6 in 3:
		lm.lathe("Copper", Vector3(tx - 1.2 + 1.2 * float(k6), 50.0 + 1.2 * float(k6 % 2), tz), PackedVector2Array([
			Vector2(0.75, 0), Vector2(0.68, 0.4), Vector2(0.5, 1.0), Vector2(0.3, 1.3), Vector2(0.0, 1.4)]), 16)
		lm.box("Concrete", Vector3(tx - 1.2 + 1.2 * float(k6), 51.4 + 1.2 * float(k6 % 2) + 1.5, tz),
			Vector3(0.15, 3.0, 0.15))
	lm.box("Concrete", Vector3(tx, 61.7, tz), Vector3(1.0, 6.6, 1.0))
	lm.box("Concrete", Vector3(tx, 63.6, tz), Vector3(4.4, 1.0, 1.0))
	lm.commit(model)

## Saynatsalo Town Hall (Saynatsalon kunnantalo), built 1949-52: the
## red-brick civic centre (the municipal hall until 1993, now library and
## meeting rooms) round a raised, grassed courtyard on the island of
## Saynatsalo, the office wing on the west, the library over shops on the
## north (ground floor glazed, flats above), the council chamber, the
## highest block, at the corner with its mono-pitch roof rising towards
## the court, the timber-framed glazing and posts lining the court, and the
## stepped grass terraces climbing to the court from the west.
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
	LandmarkFrKit.rect(lm, "Brick", -8.5, 11.4, -5.8, 14.3, 0.0, 1.8)
	LandmarkFrKit.rect(lm, "Lawn", -8.2, 11.1, -5.5, 13.8, 1.8, 1.95)
	for k in 5:
		LandmarkFrKit.rect(lm, "Stone", -5.0 + 2.0 * float(k), -3.4 + 2.0 * float(k), 12.0 + 0.4 * float(k),
			13.8, 1.95, 2.0 + 0.1 * float(k))
	# The grass terraces climbing to the court from the south-west, each
	# riser held by timber.
	for k2 in 6:
		var zt := 14.3 + 0.9 * float(5 - k2)
		LandmarkFrKit.rect(lm, "Lawn", -8.0, -1.0, zt, zt + 0.9, 0.0, 0.3 * float(k2 + 1))
		lm.box("Timber", Vector3(-4.5, 0.3 * float(k2 + 1) - 0.15, zt + 0.88), Vector3(7.0, 0.3, 0.08), Basis(), 0.0)
	# Office wing (west), library and flats (north), east link, each with a
	# brick parapet coping.
	for b in [[-21.1, -8.5, -14.3, 9.9, 7.4], [-8.5, 17.6, -14.3, -5.8, 8.2], [11.4, 17.6, -5.8, 2.5, 7.4]]:
		LandmarkFrKit.rect(lm, "Brick", b[0], b[1], b[2], b[3], 0.0, b[4])
		LandmarkFrKit.rect(lm, "Roof", float(b[0]) - 0.1, float(b[1]) + 0.1, float(b[2]) - 0.1, float(b[3]) + 0.1,
			float(b[4]), float(b[4]) + 0.5)
		LandmarkFrParts.band(lm, "Timber", b[0], b[1], b[2], b[3], float(b[4]) + 0.35, 0.2, 0.25)
	# Council chamber block: brick walls to 12 m, wedge ends, roof rising
	# to 14.6, the clerestory and the tall window strip on the court side.
	LandmarkFrKit.rect(lm, "Brick", 5.9, 21.1, 2.5, 14.3, 0.0, 12.0)
	lm.box("Brick", Vector3(5.95, 13.3, 8.4), Vector3(0.1, 2.6, 11.8))
	for z: float in [2.5, 14.3]:
		var n := Vector3(0, 0, 1.0 if z > 3.0 else -1.0)
		lm.tri("Brick", Vector3(5.9, 12.0, z), Vector3(21.1, 12.0, z), Vector3(5.9, 14.6, z), n, n, n,
			Vector2(0, 0), Vector2(15.2, 0), Vector2(0, -2.6))
	lm.quad("Roof", Vector3(5.9, 14.6, 2.5), Vector3(21.1, 12.0, 2.5), Vector3(21.1, 12.0, 14.3),
		Vector3(5.9, 14.6, 14.3), Vector3(0.17, 1.0, 0).normalized())
	lm.beam("Timber", Vector3(5.9, 14.5, 2.4), Vector3(5.9, 14.5, 14.4), 0.25, 0.3, Vector3.UP)
	lm.beam("Timber", Vector3(21.2, 11.9, 2.4), Vector3(21.2, 11.9, 14.4), 0.25, 0.3, Vector3.UP)
	# The chamber's timber-slatted window on the north-west and the stair.
	LandmarkFrParts.opening(lm, "Timber", "Glass", Vector3(5.9, 5.0, 4.4), Vector3.LEFT, 2.4, 6.0,
		LandmarkFrParts.HEAD_FLAT, 0.16, 0.12, 5)
	# Windows: the library's ground-floor shop glazing and upper windows on
	# the north front, the office windows, the court-side timber posts.
	for k3 in 8:
		var x := -6.0 + 3.0 * float(k3)
		LandmarkFrParts.opening(lm, "Timber", "Glass", Vector3(x, 0.4, -14.3), Vector3.FORWARD, 2.4, 2.6,
			LandmarkFrParts.HEAD_FLAT, 0.12, 0.1, 2)
		LandmarkFrParts.opening(lm, "Timber", "Glass", Vector3(x, 5.1, -14.3), Vector3.FORWARD, 1.8, 1.4,
			LandmarkFrParts.HEAD_FLAT, 0.12, 0.1, 1)
	for k4 in 7:
		var zz := -12.0 + 3.4 * float(k4)
		LandmarkFrParts.opening(lm, "Timber", "Glass", Vector3(-21.1, 2.7, zz), Vector3.LEFT, 2.0, 1.8,
			LandmarkFrParts.HEAD_FLAT, 0.12, 0.1, 1)
		LandmarkFrParts.opening(lm, "Timber", "Glass", Vector3(-21.1, 5.2, zz), Vector3.LEFT, 2.0, 1.2,
			LandmarkFrParts.HEAD_FLAT, 0.12, 0.1, 1)
		if zz > -5.0:
			LandmarkFrParts.opening(lm, "Timber", "Glass", Vector3(-8.5, 2.7, zz), Vector3.RIGHT, 1.8, 2.6,
				LandmarkFrParts.HEAD_FLAT, 0.12, 0.1, 1)
	for k5 in 10:
		lm.box("Timber", Vector3(-7.4 + 1.8 * float(k5), 5.1, -5.7), Vector3(0.28, 6.4, 0.28))
	LandmarkFrParts.facade(lm, "Brick", "Glass", Vector3(-8.0, 1.95, -5.8), Vector3(11.0, 1.95, -5.8), Vector3.BACK,
		6.2, 10, 1, Vector2(1.5, 4.2), 0.6, 4.0, 0.15)
	for k6 in 5:
		LandmarkFrParts.opening(lm, "Timber", "Glass", Vector3(8.5 + 3.0 * float(k6), 2.6, 14.3), Vector3.BACK, 1.6,
			4.8, LandmarkFrParts.HEAD_FLAT, 0.14, 0.12, 1)
	LandmarkFrParts.facade(lm, "Brick", "Glass", Vector3(17.6, 0.0, -14.3), Vector3(17.6, 0.0, 2.5), Vector3.RIGHT,
		7.4, 5, 2, Vector2(1.4, 1.5), 1.0, 3.4, 0.15)
	lm.commit(model)

## Church of the Three Crosses (Kolmen Ristin kirkko), Vuoksenniska,
## Imatra, 1957-58: whitewashed brick walls and a copper roof, the nave in
## three sections (separable by sliding walls, five entrances, about 800
## seats) each under its own roof stepped higher towards the middle, 103
## windows of which only two share a shape, and the slender 34 m bell
## tower of slip-formed concrete, shaped like a downward-shot crossbow
## bolt: the shaft narrows towards the ground and its top widens in three
## stages. Three white wooden crosses stand inside instead of an altarpiece.
const VUOKSEN_TOP := 34.0

static func vuoksenniska(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F1EFE9", 3.0))
	lm.use("Copper", LandmarkFrKit.copper("#6F9683"))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#D6D3CB", 4.0))
	# Three halls in a row: wall, then the copper roof rising towards the
	# north with its standing seams.
	var halls := [[-19.5, -5.0, -15.0, 3.0, 7.0, 3.0], [-5.0, 9.5, -17.3, 4.7, 7.8, 4.6],
		[9.5, 19.7, -17.6, 5.0, 7.2, 3.4]]
	var hi := 0
	for h in halls:
		var x0: float = h[0]
		var x1: float = h[1]
		var z0: float = h[2]
		var z1: float = h[3]
		var eave: float = h[4]
		var rise: float = h[5]
		LandmarkFrKit.rect(lm, "White", x0, x1, z0, z1, 0.0, eave)
		var n := Vector3(0, (z1 - z0), rise).normalized()
		lm.quad("Copper", Vector3(x0 - 0.4, eave, z1 + 0.5), Vector3(x1 + 0.4, eave, z1 + 0.5),
			Vector3(x1 + 0.4, eave + rise, z0 - 0.4), Vector3(x0 - 0.4, eave + rise, z0 - 0.4), n)
		var seams := int((x1 - x0 + 0.8) / 0.9)
		for k in seams + 1:
			var sx := x0 - 0.4 + (x1 - x0 + 0.8) * float(k) / float(seams)
			lm.beam("Copper", Vector3(sx, eave + 0.04, z1 + 0.5), Vector3(sx, eave + rise + 0.04, z0 - 0.4), 0.06, 0.08,
				n.cross(Vector3.RIGHT))
		for sx2: float in [x0, x1]:
			var en := Vector3(1 if sx2 == x1 else -1, 0, 0)
			lm.tri("White", Vector3(sx2, eave, z1), Vector3(sx2, eave, z0), Vector3(sx2, eave + rise, z0),
				en, en, en, Vector2(0, 0), Vector2(z1 - z0, 0), Vector2(z1 - z0, -rise))
		lm.box("White", Vector3((x0 + x1) * 0.5, eave + rise * 0.5, z0), Vector3(x1 - x0, rise, 0.5))
		# Irregular windows: a high band on the south front, tall ones and
		# small square ones of varied sizes, and a clerestory on the north.
		var cnt := 4 + hi
		for k2 in cnt:
			var t := (float(k2) + 0.5) / float(cnt)
			var ww := 0.8 + 0.5 * float((k2 * 7 + hi * 3) % 3)
			var wh := 1.4 + 1.6 * float((k2 * 5 + hi) % 3)
			LandmarkFrParts.opening(lm, "White", "Glass", Vector3(lerpf(x0 + 1.0, x1 - 1.0, t), eave - wh - 1.0, z1),
				Vector3.BACK, ww, wh, LandmarkFrParts.HEAD_FLAT, 0.12, 0.1, 1 if wh > 2.5 else 0)
			LandmarkFrParts.opening(lm, "White", "Glass", Vector3(lerpf(x0 + 1.0, x1 - 1.0, t), eave + rise - 2.2, z0),
				Vector3.FORWARD, ww * 0.8, 1.4, LandmarkFrParts.HEAD_FLAT, 0.1, 0.1)
		LandmarkFrParts.opening(lm, "Concrete", "Glass", Vector3((x0 + x1) * 0.5, 0.0, z1), Vector3.BACK, 1.8, 2.4,
			LandmarkFrParts.HEAD_FLAT, 0.18, 0.15, 1)
		hi += 1
	for ex: float in [-19.5, 19.7]:
		LandmarkFrParts.opening(lm, "Concrete", "Glass", Vector3(ex, 0.0, -6.0), Vector3(signf(ex), 0, 0), 1.8, 2.4,
			LandmarkFrParts.HEAD_FLAT, 0.18, 0.15, 1)
		LandmarkFrParts.openings(lm, "White", "Glass", Vector3(ex, 3.4, -13.0), Vector3(ex, 3.4, 1.0),
			Vector3(signf(ex), 0, 0), 3, 0.9, 1.8, LandmarkFrParts.HEAD_FLAT, 0.1, 0.1)
	# Bell tower: the shaft narrowing towards the ground, three widening
	# stages at the top with the bell openings and louvres, the cross.
	var tx := 3.0
	var tz := 12.5
	lm.frustum("White", Vector3(tx, 0.0, tz), 1.6, 2.4, 22.0, 4, PI / 4.0)
	lm.frustum("Concrete", Vector3(tx, 0.0, tz), 1.9, 1.85, 0.6, 4, PI / 4.0)
	for k3 in 5:
		var y := 3.0 + 3.8 * float(k3)
		var hwy := (1.6 + 0.8 * y / 22.0) * 0.7071
		lm.box("Glass", Vector3(tx, y, tz + hwy + 0.03), Vector3(0.3, 1.4, 0.08))
	for k in 3:
		var y2 := 22.0 + 3.7 * float(k)
		var w := 4.8 + 0.6 * float(k)
		lm.box("White", Vector3(tx, y2 + 1.5, tz), Vector3(w, 3.0, w))
		for f in 4:
			var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
			var fn: Vector3 = rb * Vector3(0, 0, 1)
			var oc := Vector3(tx, y2 + 0.6, tz) + fn * w * 0.5
			LandmarkFrParts.opening(lm, "Concrete", "Glass", oc, fn, w * 0.5, 1.8, LandmarkFrParts.HEAD_FLAT, 0.1, 0.08)
			LandmarkFrParts.louvre(lm, "Concrete", oc + fn * 0.02, fn, w * 0.48, 1.8, 6)
		lm.box("Concrete", Vector3(tx, y2 + 3.2, tz), Vector3(w + 0.5, 0.4, w + 0.5))
	lm.box("Concrete", Vector3(tx, 33.4, tz), Vector3(0.3, 1.4, 0.3))
	lm.box("Concrete", Vector3(tx, 33.6, tz), Vector3(0.9, 0.2, 0.2))
	lm.commit(model)
