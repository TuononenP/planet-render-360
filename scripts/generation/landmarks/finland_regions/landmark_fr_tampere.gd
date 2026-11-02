class_name LandmarkFrTampere
extends RefCounted

## Tampere's landmarks of the finland_regions batch in true metres, in the
## frame of the real plan (+X east, +Z south, turned onto the map by the
## entry's yaw_deg): Lars Sonck's National Romantic granite cathedral, the
## Nasinneula and Pyynikki observation towers and the Pietilas' Kaleva
## Church. Plans follow the OpenStreetMap footprints.

## Tampere Cathedral (Tampereen tuomiokirkko), Lars Sonck, 1902-07: rough
## grey Uusikaupunki granite with dressed quoins and surrounds, a wide
## three-nave body under one steep roof with a gabled south transept, a
## small annex at the south-east, the slender 64 m tower at the south-west
## corner (deep round-arched portal, paired belfry openings, a tall pointed
## roof and four corner pinnacles) and the lower round stair tower on the
## north-west. Round-arched windows (Simberg's stained glass), a rose in
## the transept gable. Nave along X, the tower at the west (-X) end.
const CATHEDRAL_TOP := 64.0

static func cathedral(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8D87", 3.5))
	lm.use("Dressed", LandmarkMaterials.pbr("stone", "#A9A79F", 3.0))
	lm.use("Roof", LandmarkFrKit.copper("#55756A"))
	lm.use("Dark", LandmarkMaterials.pbr("slate", "#2E3234", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var rh := LandmarkFrParts.HEAD_ROUND
	# Nave and aisles with the single roof (eaves 13, ridge 26.5 m).
	LandmarkFrKit.rect(lm, "Granite", -21.0, 18.8, -17.3, 12.9, 0.0, 13.0)
	LandmarkFrKit.rect(lm, "Dressed", -21.4, 19.2, -17.7, 13.3, 0.0, 1.0)
	LandmarkFrKit.gable(lm, "Roof", -21.0, 18.8, -17.3, 12.9, 13.0, 13.5, 0.7, "Granite", 1)
	LandmarkFrParts.roof_trim(lm, "Roof", -21.0, 18.8, -17.3, 12.9, 13.0, 13.5, 0.7, 1, 0.35)
	LandmarkFrParts.cornice_ring(lm, "Dressed", -21.0, 18.8, -17.3, 12.9, 12.4, 0.6)
	# South transept and the little annex at the south-east.
	LandmarkFrKit.rect(lm, "Granite", -2.4, 12.6, 12.9, 17.3, 0.0, 13.0)
	LandmarkFrKit.gable(lm, "Roof", -2.4, 12.6, 0.0, 17.3, 13.0, 8.5, 0.6, "Granite", 0)
	LandmarkFrParts.roof_trim(lm, "Roof", -2.4, 12.6, 0.0, 17.3, 13.0, 8.5, 0.6, 0, 0.3)
	LandmarkFrKit.house(lm, "Granite", "Roof", 18.8, 22.3, 4.4, 12.7, 0.0, 6.0, 3.2, 0.3, 0)
	LandmarkFrParts.opening(lm, "Dressed", "Glass", Vector3(22.3, 1.6, 8.55), Vector3.RIGHT, 1.2, 2.6, rh, 0.3, 0.15)
	# Quoins up the corners of the body and the transept.
	LandmarkFrParts.corner_strips(lm, "Dressed", -21.0, 18.8, -17.3, 12.9, 1.0, 12.4, 0.9, 0.12)
	LandmarkFrParts.corner_strips(lm, "Dressed", -2.4, 12.6, 12.9, 17.3, 1.0, 12.4, 0.9, 0.12)
	# Windows: tall round-arched windows on both long fronts with
	# buttresses between, a rose and three windows in the transept gable,
	# a rose and lancets in the east gable, small round gable lights.
	for k in 5:
		var x := -17.0 + 6.6 * float(k)
		LandmarkFrParts.opening(lm, "Dressed", "Glass", Vector3(x, 3.6, -17.3), Vector3.FORWARD, 2.2, 7.4, rh,
			0.45, 0.2, 1)
		LandmarkFrParts.buttress(lm, "Granite", Vector3(x + 3.3, 0, -17.3), Vector3.FORWARD, 1.4, 1.6, 11.0, 2)
	for k in 3:
		var x2 := -13.0 + 3.6 * float(k)
		LandmarkFrParts.opening(lm, "Dressed", "Glass", Vector3(x2, 3.6, 12.9), Vector3.BACK, 1.8, 6.8, rh, 0.4, 0.2, 1)
		LandmarkFrParts.opening(lm, "Dressed", "Glass", Vector3(15.7, 3.6, 12.9), Vector3.BACK, 1.8, 6.8, rh, 0.4, 0.2, 1)
	for k in 3:
		LandmarkFrParts.opening(lm, "Dressed", "Glass", Vector3(1.0 + 4.1 * float(k), 3.2, 17.3), Vector3.BACK, 1.8,
			7.2, rh, 0.4, 0.2, 1)
	lm.disc("Dressed", Vector3(5.1, 19.0, 17.42), Vector3(0, 0, 1), 2.9, 24)
	lm.disc("Glass", Vector3(5.1, 19.0, 17.5), Vector3(0, 0, 1), 2.4, 24)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.beam("Dressed", Vector3(5.1, 19.0, 17.55), Vector3(5.1 + cos(a) * 2.4, 19.0 + sin(a) * 2.4, 17.55), 0.16, 0.1)
	lm.disc("Dressed", Vector3(18.85, 20.0, -2.2), Vector3(1, 0, 0), 2.9, 24)
	lm.disc("Glass", Vector3(18.93, 20.0, -2.2), Vector3(1, 0, 0), 2.4, 24)
	for k in 8:
		var a2 := TAU * float(k) / 8.0
		lm.beam("Dressed", Vector3(18.98, 20.0, -2.2), Vector3(18.98, 20.0 + sin(a2) * 2.4, -2.2 + cos(a2) * 2.4),
			0.16, 0.1)
	for k in 3:
		LandmarkFrParts.opening(lm, "Dressed", "Glass", Vector3(18.8, 3.6, -9.0 + 5.4 * float(k)), Vector3.RIGHT, 1.8,
			7.4, rh, 0.4, 0.2, 1)
	for k in 2:
		LandmarkFrParts.opening(lm, "Dressed", "Glass", Vector3(-21.0, 15.0, -9.0 + 7.0 * float(k)), Vector3.LEFT, 1.0,
			1.8, rh, 0.25, 0.12)
	# The tower: granite shaft with quoins, the portal, slit windows, the
	# belfry with paired louvred openings, the pointed roof and pinnacles.
	var tx := -17.7
	var tz := 11.25
	LandmarkFrKit.rect(lm, "Granite", tx - 4.6, tx + 4.6, tz - 4.4, tz + 4.4, 0.0, 38.0)
	LandmarkFrKit.rect(lm, "Dressed", tx - 4.9, tx + 4.9, tz - 4.7, tz + 4.7, 0.0, 1.2)
	LandmarkFrParts.corner_strips(lm, "Dressed", tx - 4.6, tx + 4.6, tz - 4.4, tz + 4.4, 1.2, 37.4, 1.0, 0.14)
	LandmarkFrKit.rect(lm, "Dressed", tx - 4.9, tx + 4.9, tz - 4.7, tz + 4.7, 37.4, 38.4)
	LandmarkFrParts.band(lm, "Dressed", tx - 4.6, tx + 4.6, tz - 4.4, tz + 4.4, 13.0, 0.5, 0.15)
	LandmarkFrParts.band(lm, "Dressed", tx - 4.6, tx + 4.6, tz - 4.4, tz + 4.4, 26.0, 0.5, 0.15)
	LandmarkFrParts.opening(lm, "Dressed", "Dark", Vector3(tx - 4.6, 0.0, tz), Vector3.LEFT, 2.6, 5.0, rh, 0.6, 0.35)
	LandmarkDetail.arch(lm, "Dressed", Vector3(tx - 4.6, 3.7, tz), Vector3.LEFT, 4.2, 0.6, 0.5)
	LandmarkFrParts.opening(lm, "Dressed", "Dark", Vector3(tx, 0.0, tz + 4.4), Vector3.BACK, 2.4, 4.6, rh, 0.55, 0.3)
	for f in 4:
		var rb := Basis(Vector3.UP, PI * 0.5 * float(f))
		var fn: Vector3 = rb * Vector3(0, 0, 1)
		var half := 4.4 if f % 2 == 0 else 4.6
		var c0 := Vector3(tx, 0, tz) + fn * half
		for y: float in [15.0, 21.0, 28.5]:
			LandmarkFrParts.opening(lm, "Dressed", "Glass", c0 + Vector3(0, y, 0), fn, 0.9, 3.2, rh, 0.3, 0.14)
		var hb := 3.9 if f % 2 == 0 else 4.0
		var c1 := Vector3(tx, 0, tz) + fn * hb
		for s: float in [-1.0, 1.0]:
			var off: Vector3 = rb * Vector3(s * 1.2, 40.0, 0)
			LandmarkFrParts.opening(lm, "Dressed", "Dark", c1 + off, fn, 1.4, 4.4, rh, 0.3, 0.16)
			LandmarkFrParts.louvre(lm, "Dark", c1 + off, fn, 1.3, 3.6, 7)
		lm.disc("Gilt", Vector3(tx, 34.6, tz) + fn * (half + 0.16), fn, 1.4, 20)
	LandmarkFrKit.rect(lm, "Granite", tx - 4.0, tx + 4.0, tz - 3.9, tz + 3.9, 38.4, 46.0)
	LandmarkFrKit.rect(lm, "Dressed", tx - 4.4, tx + 4.4, tz - 4.3, tz + 4.3, 45.6, 46.6)
	lm.spire("Roof", Vector3(tx, 46.6, tz), 4.6, 16.9, 0.35)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var pc := Vector3(tx + sx * 4.0, 46.6, tz + sz * 3.9)
			lm.frustum("Granite", pc, 0.7, 0.62, 3.6, 8, PI / 8.0)
			lm.frustum("Dressed", pc + Vector3(0, 3.6, 0), 0.8, 0.8, 0.3, 8, PI / 8.0)
			lm.lathe("Roof", pc + Vector3(0, 3.9, 0), PackedVector2Array([Vector2(0.9, 0), Vector2(0.5, 1.6),
				Vector2(0.05, 4.4)]), 8, 1.0, 1.0, PI / 8.0, false)
			lm.lathe("Gilt", pc + Vector3(0, 8.3, 0), LandmarkFrKit.ball(0.12), 6)
	lm.lathe("Gilt", Vector3(tx, 63.2, tz), LandmarkFrKit.ball(0.2), 8)
	lm.box("Gilt", Vector3(tx, 63.6 - 0.3, tz), Vector3(0.14, 1.6, 0.14))
	lm.box("Gilt", Vector3(tx, 63.4, tz), Vector3(0.8, 0.1, 0.1))
	# Round stair tower at the north-west corner with its conical cap.
	var sc := Vector3(-21.6, 0, -15.6)
	lm.frustum("Granite", sc, 2.6, 2.5, 19.0, 24)
	lm.frustum("Dressed", sc, 2.85, 2.85, 1.0, 24)
	lm.frustum("Dressed", sc + Vector3(0, 18.6, 0), 2.75, 2.8, 0.6, 24)
	lm.lathe("Roof", sc + Vector3(0, 19.2, 0), PackedVector2Array([Vector2(3.0, 0), Vector2(1.8, 2.4),
		Vector2(0.06, 7.0)]), 16)
	for y2: float in [5.0, 10.0, 15.0]:
		var a3 := PI * 0.75 + y2 * 0.05
		var on := Vector3(cos(a3), 0, sin(a3))
		LandmarkFrParts.opening(lm, "Dressed", "Glass", sc + on * 2.55 + Vector3(0, y2, 0), on, 0.6, 1.4, rh, 0.2, 0.1)
	lm.commit(model)

## Nasinneula (the Needle of Nasi), Pekka Ilveskoski, 1971, Sarkanniemi:
## 168 m to the antenna tip, Finland's tallest free-standing structure.
## The slip-formed shaft starts 10.5 m across with a 0.6 m wall and
## narrows 2 cm per metre of height; the open-air platform at 110 m, the
## observation deck and cafe at 120 m behind their window band, the
## revolving restaurant at 124 m, the roof at 134.5 m, then the steel mast
## with the fibreglass tip and the weather-forecast beacon lights. The
## round entrance building stands at the foot.
const NASINNEULA_TOP := 168.0

static func nasinneula(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C7C4BC", 4.0))
	lm.use("Head", LandmarkMaterials.paint("#E4E2DC", 0.5, 0.35))
	lm.use("Glass", LandmarkMaterials.glass("#26323A"))
	lm.use("Mast", LandmarkMaterials.paint("#C9CBCC", 0.5, 0.5))
	lm.use("Lit", LandmarkMaterials.lit("#FFB347", 0.8))
	lm.use("Red", LandmarkMaterials.lit("#E0352B", 0.7))
	# Entrance building: a low drum with a glazed ground floor and roof slab.
	lm.frustum("Concrete", Vector3.ZERO, 12.0, 12.0, 0.6, 48)
	lm.frustum("Glass", Vector3(0, 0.6, 0), 11.4, 11.4, 3.0, 48)
	for k in 36:
		var a := TAU * float(k) / 36.0
		lm.box("Head", Vector3(cos(a) * 11.45, 2.1, sin(a) * 11.45), Vector3(0.18, 3.0, 0.18), Basis(Vector3.UP, -a))
	lm.lathe("Head", Vector3(0, 3.6, 0), PackedVector2Array([Vector2(12.2, 0), Vector2(12.2, 0.9),
		Vector2(11.6, 1.2), Vector2(7.0, 1.6), Vector2(0.0, 1.8)]), 48)
	# Shaft: 10.5 m across at the foot, narrowing 2 cm per metre.
	var prof := PackedVector2Array()
	for k in 12:
		var y := 110.0 * float(k) / 11.0
		prof.append(Vector2(5.26 - 0.01 * y, y))
	lm.lathe("Concrete", Vector3.ZERO, prof, 40)
	# Stairwell slit windows up the north side, lift landings marked.
	for k in 26:
		var y2 := 8.0 + 4.0 * float(k)
		var r := 5.26 - 0.01 * y2
		LandmarkFrParts.opening(lm, "", "Glass", Vector3(0, y2, -r - 0.02), Vector3.FORWARD, 0.35, 1.6)
	# Open-air platform at 110 m: slab, railing, then the head's underside
	# on 24 radial brackets.
	lm.frustum("Head", Vector3(0, 109.4, 0), 7.0, 7.0, 0.6, 40)
	LandmarkFrParts.ring_railing(lm, "Mast", Vector3(0, 110.0, 0), 6.8, 1.2, 48)
	lm.frustum("Concrete", Vector3(0, 110.0, 0), 4.2, 4.2, 4.0, 40)
	lm.lathe("Head", Vector3(0, 114.0, 0), PackedVector2Array([Vector2(4.2, 0), Vector2(6.0, 1.0),
		Vector2(8.6, 2.4), Vector2(10.6, 3.6), Vector2(11.4, 4.0)]), 48)
	for k in 24:
		var a2 := TAU * float(k) / 24.0
		var d := Vector3(cos(a2), 0, sin(a2))
		lm.beam("Head", d * 4.3 + Vector3(0, 112.0, 0), d * 10.8 + Vector3(0, 117.6, 0), 0.3, 0.5, d.cross(Vector3.UP))
	# Observation deck (120 m) and restaurant (124 m) window bands with
	# mullions, the floor slabs between, the roof cap at 134.5 m.
	lm.frustum("Head", Vector3(0, 118.0, 0), 11.6, 11.6, 0.8, 48)
	lm.frustum("Glass", Vector3(0, 118.8, 0), 11.4, 11.6, 3.8, 48)
	lm.frustum("Head", Vector3(0, 122.6, 0), 11.9, 11.9, 1.0, 48)
	lm.frustum("Glass", Vector3(0, 123.6, 0), 11.6, 11.9, 4.2, 48)
	lm.frustum("Head", Vector3(0, 127.8, 0), 12.1, 12.1, 0.8, 48)
	for k in 48:
		var a3 := TAU * float(k) / 48.0
		var d2 := Vector3(cos(a3), 0, sin(a3))
		lm.box("Head", d2 * 11.62 + Vector3(0, 120.7, 0), Vector3(0.14, 3.8, 0.14), Basis(Vector3.UP, -a3))
		lm.box("Head", d2 * 11.86 + Vector3(0, 125.7, 0), Vector3(0.14, 4.2, 0.14), Basis(Vector3.UP, -a3))
	lm.lathe("Head", Vector3(0, 128.6, 0), PackedVector2Array([Vector2(12.1, 0), Vector2(11.4, 1.4),
		Vector2(9.0, 3.2), Vector2(6.0, 4.6), Vector2(3.6, 5.6), Vector2(3.6, 5.9)]), 48)
	# Mast: steel tube with ring platforms, the fibreglass tip, the beacon
	# lights and red aircraft lights.
	lm.lathe("Mast", Vector3(0, 134.5, 0), PackedVector2Array([Vector2(1.7, 0), Vector2(1.4, 6.0),
		Vector2(1.1, 11.5)]), 16)
	lm.frustum("Lit", Vector3(0, 146.0, 0), 1.25, 1.1, 9.0, 16)
	lm.lathe("Mast", Vector3(0, 155.0, 0), PackedVector2Array([Vector2(0.8, 0), Vector2(0.5, 7.0),
		Vector2(0.18, 13.0)]), 12)
	for y3: float in [138.0, 145.6, 155.2]:
		lm.frustum("Mast", Vector3(0, y3, 0), 2.1, 2.1, 0.25, 16)
		LandmarkFrParts.ring_railing(lm, "Mast", Vector3(0, y3 + 0.25, 0), 2.0, 1.0, 12, 0.05)
	for y4: float in [134.8, 145.4, 162.0]:
		for k in 4:
			var a4 := TAU * float(k) / 4.0
			lm.box("Red", Vector3(cos(a4) * 1.75, y4, sin(a4) * 1.75), Vector3(0.3, 0.3, 0.3))
	lm.box("Red", Vector3(0, 167.85, 0), Vector3(0.3, 0.3, 0.3))
	lm.commit(model)

## Pyynikki Observation Tower (Pyynikin nakotorni), Vilho Kolho, 1929: the
## 26 m tower of rusticated red granite brought from Aland, on the crest
## of the Pyynikki esker 152 m above sea level: an octagonal battered
## shaft with an arched door and slit windows, coursed in rough blocks,
## the corbelled gallery with its band of windows and the low pointed
## roof; the cafe house beside it is left out.
const PYYNIKKI_TOP := 26.0

static func pyynikki(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9B7B6C", 2.5))
	lm.use("Dressed", LandmarkMaterials.pbr("stone", "#B79A88", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3B3D3E", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	var rot := PI / 8.0
	lm.lathe("Granite", Vector3.ZERO, PackedVector2Array([Vector2(3.9, 0), Vector2(3.6, 4.0),
		Vector2(3.2, 6.0), Vector2(2.7, 22.0)]), 8, 1.0, 1.0, rot, false)
	lm.frustum("Dressed", Vector3.ZERO, 4.2, 4.0, 1.0, 8, rot)
	# Rough course lines: a proud band every 1.6 m round the shaft.
	for k in 12:
		var y := 6.6 + 1.3 * float(k)
		var r := 3.2 - 0.5 * (y - 6.0) / 16.0
		lm.frustum("Granite", Vector3(0, y, 0), r + 0.06, r + 0.05, 0.22, 8, rot)
	# Door and slit windows on alternate faces, rising round the stair.
	var apo := cos(PI / 8.0)
	LandmarkFrParts.opening(lm, "Dressed", "Glass", Vector3(0, 0.0, 3.9 * apo), Vector3.BACK, 1.3, 2.6,
		LandmarkFrParts.HEAD_ROUND, 0.35, 0.2)
	for k in 7:
		var y2 := 7.0 + 2.1 * float(k)
		var a := PI * 0.5 + PI * 0.25 * float(k * 3)
		var n := Vector3(cos(a), 0, sin(a))
		var r2 := (3.2 - 0.5 * (y2 - 6.0) / 16.0) * apo
		LandmarkFrParts.opening(lm, "Dressed", "Glass", n * r2 + Vector3(0, y2, 0), n, 0.45, 1.3,
			LandmarkFrParts.HEAD_ROUND, 0.2, 0.1)
	# Gallery: corbels under a flared cornice, the window band with piers,
	# a dressed cornice, the low pointed roof and finial.
	for k in 16:
		var a2 := TAU * float(k) / 16.0
		var d := Vector3(cos(a2), 0, sin(a2))
		lm.beam("Dressed", d * 2.6 + Vector3(0, 20.6, 0), d * 4.2 + Vector3(0, 22.2, 0), 0.4, 0.5, d.cross(Vector3.UP))
	lm.lathe("Dressed", Vector3(0, 21.6, 0), PackedVector2Array([Vector2(2.9, 0), Vector2(4.4, 0.9),
		Vector2(4.6, 1.4), Vector2(4.6, 1.6)]), 8, 1.0, 1.0, rot, false)
	lm.frustum("Glass", Vector3(0, 23.2, 0), 4.5, 4.5, 1.6, 8, rot)
	for k in 8:
		var a3 := TAU * float(k) / 8.0
		lm.box("Granite", Vector3(cos(a3) * 4.4, 24.0, sin(a3) * 4.4), Vector3(0.7, 1.6, 0.7), Basis(Vector3.UP, -a3))
		var a4 := a3 + PI / 8.0
		var n4 := Vector3(cos(a4), 0, sin(a4))
		lm.box("Dressed", n4 * 4.2 + Vector3(0, 24.0, 0), Vector3(0.1, 1.6, 0.1), Basis(Vector3.UP, -a4))
	lm.frustum("Dressed", Vector3(0, 24.8, 0), 4.75, 4.85, 0.35, 8, rot)
	lm.lathe("Roof", Vector3(0, 25.15, 0), PackedVector2Array([Vector2(4.85, 0), Vector2(4.5, 0.25),
		Vector2(0.15, 0.65)]), 8, 1.0, 1.0, rot, false)
	lm.box("Dressed", Vector3(0, 25.6, 0), Vector3(0.18, 0.8, 0.18))
	lm.commit(model)

## Kaleva Church (Kalevan kirkko), Reima and Raili Pietila, 1966: the
## fish-shaped hall slip-cast in tall concrete U-shaped wall elements clad
## in pale yellow clay tiles (about 150,000 of them), each bulging out of
## the plan, with the 18 floor-to-ceiling slit windows between them; the
## nave 30 m high inside under 4 m deep roof beams, the low parish wing at
## the west end and the cross-shaped bell tower rising from the roof.
const KALEVA_TOP := 43.5
const KALEVA_HALL := [Vector2(-19, 2), Vector2(-15, -10), Vector2(-5, -19), Vector2(10, -21),
	Vector2(22, -20), Vector2(27, -10), Vector2(30, 3), Vector2(30, 12), Vector2(24, 19),
	Vector2(8, 21), Vector2(-8, 17), Vector2(-19, 10)]
const KALEVA_WALL_H := 35.0
const KALEVA_SLITS := 18

static func kaleva(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Tile", LandmarkMaterials.pbr("limestone", "#DDD3AC", 2.5))
	lm.use("Fin", LandmarkMaterials.pbr("concrete", "#A8A59C", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("membrane", "#4A4947", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Bell", LandmarkMaterials.pbr("concrete", "#D6D3CA", 3.0))
	var hall := PackedVector2Array(KALEVA_HALL)
	var wall_h := KALEVA_WALL_H
	lm.poly_prism("Fin", hall, 0.0, wall_h, false)
	var c := Vector2.ZERO
	for p in hall:
		c += p
	c /= float(hall.size())
	var roof_poly := PackedVector2Array()
	for p in hall:
		roof_poly.append(c + (p - c) * 1.01)
	lm.poly_prism("Roof", roof_poly, wall_h - 0.4, wall_h + 0.5)
	# The tiled U-shells between the slits, bulging out of the plan.
	var perim := 0.0
	for i in hall.size():
		perim += hall[i].distance_to(hall[(i + 1) % hall.size()])
	var pitch := perim / float(KALEVA_SLITS)
	var gap := 1.1
	for e in KALEVA_SLITS:
		var s0 := pitch * float(e) + gap * 0.5
		var s1 := pitch * float(e + 1) - gap * 0.5
		var bottom := PackedVector3Array()
		var top := PackedVector3Array()
		var cap := PackedVector3Array()
		for k in 9:
			var t := float(k) / 8.0
			var pp := _perim_at(hall, c, lerpf(s0, s1, t))
			var p2: Vector2 = pp[0]
			var o: Vector2 = pp[1]
			var bulge := 0.25 + 1.3 * sin(PI * t)
			var q := p2 + o * bulge
			bottom.append(Vector3(q.x, 0.0, q.y))
			top.append(Vector3(q.x, wall_h + 0.6, q.y))
			cap.append(Vector3(p2.x, wall_h + 0.6, p2.y))
		lm.grid("Tile", [bottom, top], Vector3(c.x, wall_h * 0.5, c.y), true)
		lm.grid("Fin", [top, cap], Vector3.UP)
		# Returns of the shell into the slit.
		for end in [0, 8]:
			var pe := _perim_at(hall, c, s0 if end == 0 else s1)
			var pb: Vector2 = pe[0]
			var sn := (top[end] - Vector3(pb.x, 0, pb.y))
			sn.y = 0.0
			var side := Vector3((pe[1] as Vector2).y, 0, -(pe[1] as Vector2).x) * (1.0 if end == 0 else -1.0)
			lm.quad("Fin", Vector3(pb.x, 0.0, pb.y), bottom[end], top[end], Vector3(pb.x, wall_h + 0.6, pb.y), side)
		# The slit window in the gap after this shell, with transoms.
		var g0 := _perim_at(hall, c, s1)
		var g1 := _perim_at(hall, c, s1 + gap)
		var a: Vector2 = g0[0]
		var b: Vector2 = g1[0]
		var on: Vector2 = g0[1]
		var gn := Vector3(on.x, 0, on.y)
		lm.quad("Glass", Vector3(a.x, 0.0, a.y) + gn * 0.05, Vector3(b.x, 0.0, b.y) + gn * 0.05,
			Vector3(b.x, wall_h - 1.0, b.y) + gn * 0.05, Vector3(a.x, wall_h - 1.0, a.y) + gn * 0.05, gn)
		for k2 in 11:
			var y := 3.0 * float(k2 + 1)
			lm.beam("Fin", Vector3(a.x, y, a.y) + gn * 0.1, Vector3(b.x, y, b.y) + gn * 0.1, 0.12, 0.12)
	# Roof beams (4 m deep) across the hall, seen above the roof line.
	for k in 4:
		var x := -10.0 + 10.0 * float(k)
		lm.box("Roof", Vector3(x, wall_h + 0.8, 0.0), Vector3(1.0, 0.6, 36.0 - absf(x - 5.0) * 0.3))
	# Parish wing and entrance hall at the west end.
	var wing := PackedVector2Array([Vector2(-33.0, 16.0), Vector2(-33.0, 4.0), Vector2(-25.0, 0.0),
		Vector2(-17.0, 3.0), Vector2(-17.0, 12.0), Vector2(-24.0, 17.0)])
	lm.poly_prism("Tile", wing, 0.0, 9.0, false)
	lm.poly_prism("Roof", PackedVector2Array([Vector2(-33.4, 16.4), Vector2(-33.4, 3.7), Vector2(-25.0, -0.4),
		Vector2(-16.8, 2.8), Vector2(-16.8, 12.2), Vector2(-24.0, 17.4)]), 8.8, 9.6)
	LandmarkFrParts.facade(lm, "Tile", "Glass", Vector3(-33.0, 0.0, 15.5), Vector3(-33.0, 0.0, 4.5), Vector3.LEFT,
		9.0, 4, 2, Vector2(1.8, 2.4), 1.0, 4.2, 0.25)
	LandmarkFrParts.opening(lm, "Fin", "Glass", Vector3(-28.5, 0.0, 17.4 - 1.95), Vector3(-0.5, 0, 1).normalized(),
		3.6, 3.0, LandmarkFrParts.HEAD_FLAT, 0.25, 0.2, 2)
	lm.box("Fin", Vector3(-28.5, 3.3, 18.4), Vector3(6.0, 0.3, 3.0), Basis(Vector3.UP, atan2(0.5, 1.0)))
	# Cross-shaped bell tower on the roof, with the three bells in its arms.
	var bt := Vector3(-6.0, wall_h, 0)
	lm.box("Bell", bt + Vector3(0, 4.25, 0), Vector3(2.4, 8.5, 2.2))
	lm.box("Bell", bt + Vector3(0, 6.0, 0), Vector3(7.6, 2.2, 2.2))
	for s: float in [-2.6, 0.0, 2.6]:
		lm.lathe("Fin", bt + Vector3(s, 5.2 if s != 0.0 else 2.2, 0), PackedVector2Array([Vector2(0.55, 0),
			Vector2(0.5, 0.3), Vector2(0.35, 0.7), Vector2(0.15, 0.85)]), 12)
	lm.commit(model)

## Point and outward normal at arc length s along the closed polygon.
static func _perim_at(poly: PackedVector2Array, c: Vector2, s: float) -> Array:
	var walked := 0.0
	var total := 0.0
	for i in poly.size():
		total += poly[i].distance_to(poly[(i + 1) % poly.size()])
	var ss := fposmod(s, total)
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		var el := p.distance_to(q)
		if ss <= walked + el or i == poly.size() - 1:
			var dir := (q - p) / el
			var o := Vector2(dir.y, -dir.x)
			if o.dot((p + q) * 0.5 - c) < 0.0:
				o = -o
			return [p + dir * clampf(ss - walked, 0.0, el), o]
		walked += el
	return [poly[0], Vector2.RIGHT]
