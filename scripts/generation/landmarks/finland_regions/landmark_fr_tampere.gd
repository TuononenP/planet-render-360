class_name LandmarkFrTampere
extends RefCounted

## Tampere's landmarks of the finland_regions batch in true metres, in the
## frame of the real plan (+X east, +Z south, turned onto the map by the
## entry's yaw_deg): Lars Sonck's National Romantic granite cathedral, the
## Nasinneula and Pyynikki observation towers and the Pietilas' Kaleva
## Church. Plans follow the OpenStreetMap footprints.

## Tampere Cathedral (Tampereen tuomiokirkko), Lars Sonck, 1902-07: rough
## grey Uusikaupunki granite, a wide three-nave body under one steep roof
## with a gabled south transept, a small annex at the south-east and the
## slender 64 m tower at the south-west corner whose belfry carries a
## tall pointed copper roof and four corner pinnacles. Nave along X, the
## tower at the west (-X) end.
const CATHEDRAL_TOP := 64.0

static func cathedral(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8D87", 3.5))
	lm.use("Dressed", LandmarkMaterials.pbr("stone", "#A9A79F", 3.0))
	lm.use("Roof", LandmarkFrKit.copper("#55756A"))
	lm.use("Dark", LandmarkMaterials.pbr("slate", "#2E3234", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Nave and aisles with the single roof (eaves 13, ridge 26.5 m).
	LandmarkFrKit.rect(lm, "Granite", -21.0, 18.8, -17.3, 12.9, 0.0, 13.0)
	LandmarkFrKit.rect(lm, "Dressed", -21.2, 19.0, -17.5, 13.1, 0.0, 1.0)
	LandmarkFrKit.gable(lm, "Roof", -21.0, 18.8, -17.3, 12.9, 13.0, 13.5, 0.7, "Granite", 1)
	# South transept and the little annex at the south-east.
	LandmarkFrKit.rect(lm, "Granite", -2.4, 12.6, 12.9, 17.3, 0.0, 13.0)
	LandmarkFrKit.gable(lm, "Roof", -2.4, 12.6, 0.0, 17.3, 13.0, 8.5, 0.6, "Granite", 0)
	LandmarkFrKit.house(lm, "Granite", "Roof", 18.8, 22.3, 4.4, 12.7, 0.0, 6.0, 3.2, 0.3, 0)
	# Windows: tall lancets on the south side, a rose and lancets in the gables.
	for k in 3:
		lm.box("Glass", Vector3(-10.6 + 3.8 * float(k), 7.2, 12.95), Vector3(1.5, 6.4, 0.15))
	for k in 5:
		lm.box("Glass", Vector3(-17.0 + 6.6 * float(k), 7.2, -17.35), Vector3(1.5, 6.4, 0.15))
	for k in 3:
		lm.box("Glass", Vector3(1.0 + 4.5 * float(k), 7.0, 17.35), Vector3(1.6, 6.8, 0.15))
	lm.disc("Glass", Vector3(5.1, 19.0, 17.45), Vector3(0, 0, 1), 2.2, 20)
	lm.disc("Glass", Vector3(18.85, 20.0, -2.2), Vector3(1, 0, 0), 2.4, 20)
	for k in 3:
		lm.box("Glass", Vector3(18.85, 8.0, -8.0 + 6.0 * float(k)), Vector3(0.15, 6.6, 1.6))
	# The tower: granite shaft, louvred belfry, copper roof and pinnacles.
	var tx := -17.7
	var tz := 11.25
	LandmarkFrKit.rect(lm, "Granite", tx - 4.6, tx + 4.6, tz - 4.4, tz + 4.4, 0.0, 38.0)
	LandmarkFrKit.rect(lm, "Dressed", tx - 4.9, tx + 4.9, tz - 4.7, tz + 4.7, 37.4, 38.4)
	for k in 3:
		var y := 8.0 + 11.0 * float(k)
		LandmarkFrKit.ring_windows(lm, "Glass", tx, tz, 4.45, y, 1, 1.0, Vector3(1.2, 4.0, 0.15))
	LandmarkFrKit.rect(lm, "Granite", tx - 4.0, tx + 4.0, tz - 3.9, tz + 3.9, 38.4, 46.0)
	LandmarkFrKit.ring_windows(lm, "Dark", tx, tz, 3.95, 42.2, 2, 3.0, Vector3(1.6, 4.4, 0.2))
	LandmarkFrKit.rect(lm, "Dressed", tx - 4.4, tx + 4.4, tz - 4.3, tz + 4.3, 45.6, 46.6)
	lm.spire("Roof", Vector3(tx, 46.6, tz), 4.6, 16.9, 0.35)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Granite", Vector3(tx + sx * 4.0, 48.4, tz + sz * 3.9), Vector3(1.1, 3.6, 1.1))
			lm.spire("Roof", Vector3(tx + sx * 4.0, 50.2, tz + sz * 3.9), 0.85, 5.0)
	lm.box("Gilt", Vector3(tx, 63.6 - 0.3, tz), Vector3(0.14, 1.6, 0.14))
	lm.commit(model)

## Nasinneula (the Needle of Nasi), Pekka Ilveskoski, 1971, Sarkanniemi:
## 168 m, Finland's tallest free-standing structure. A tapering concrete
## shaft on a round base building, the saucer-like head at 112-134 m with
## the cafe, the revolving restaurant behind its glass band and the open
## deck, and the steel mast with the weather-forecast beacon lights.
const NASINNEULA_TOP := 168.0

static func nasinneula(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C7C4BC", 4.0))
	lm.use("Head", LandmarkMaterials.paint("#E4E2DC", 0.5, 0.35))
	lm.use("Glass", LandmarkMaterials.glass("#26323A"))
	lm.use("Mast", LandmarkMaterials.paint("#C9CBCC", 0.5, 0.5))
	lm.use("Lit", LandmarkMaterials.lit("#FFB347", 0.8))
	lm.frustum("Concrete", Vector3.ZERO, 12.0, 11.0, 5.0, 24)
	lm.lathe("Head", Vector3(0, 5.0, 0), PackedVector2Array([Vector2(11.0, 0), Vector2(7.0, 1.2),
		Vector2(0.0, 1.6)]), 24)
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(6.4, 0), Vector2(5.4, 18.0),
		Vector2(4.6, 62.0), Vector2(4.1, 112.0)]), 20)
	# Head: cafe underside, restaurant glass band, deck and roof.
	lm.lathe("Head", Vector3(0, 112.0, 0), PackedVector2Array([Vector2(4.1, 0), Vector2(5.2, 1.6),
		Vector2(8.4, 4.4), Vector2(10.8, 7.2), Vector2(11.4, 10.2)]), 24)
	lm.frustum("Glass", Vector3(0, 122.2, 0), 11.4, 11.4, 5.4, 24)
	lm.lathe("Head", Vector3(0, 127.6, 0), PackedVector2Array([Vector2(11.7, 0), Vector2(11.5, 1.0),
		Vector2(8.0, 3.0), Vector2(5.2, 5.2), Vector2(3.4, 6.4)]), 24)
	lm.lathe("Mast", Vector3(0, 134.0, 0), PackedVector2Array([Vector2(1.7, 0), Vector2(1.3, 8.0),
		Vector2(0.9, 20.0), Vector2(0.55, 28.0), Vector2(0.25, 34.0)]), 10)
	lm.frustum("Lit", Vector3(0, 146.0, 0), 1.5, 1.35, 9.0, 10)
	lm.commit(model)

## Pyynikki Observation Tower (Pyynikin nakotorni), Vilho Kolho, 1929: the
## 26 m octagonal tower of local rusticated red granite on the crest of the
## Pyynikki esker, its cantilevered viewing gallery with windows and the
## low pointed roof; the cafe house beside it is left out.
const PYYNIKKI_TOP := 26.0

static func pyynikki(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9B7B6C", 2.5))
	lm.use("Dressed", LandmarkMaterials.pbr("stone", "#B79A88", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3B3D3E", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	lm.lathe("Granite", Vector3(0, -2.0, 0), PackedVector2Array([Vector2(3.9, 0), Vector2(3.9, 2.0),
		Vector2(3.2, 6.0), Vector2(2.7, 22.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.frustum("Dressed", Vector3(0, 0, 0), 3.9, 3.9, 1.0, 8, PI / 8.0)
	# Gallery: flared cornice, windows all round, flat cap and spire.
	lm.lathe("Dressed", Vector3(0, 21.6, 0), PackedVector2Array([Vector2(2.9, 0), Vector2(4.4, 0.9),
		Vector2(4.6, 1.4), Vector2(4.6, 3.2)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.box("Glass", Vector3(cos(a) * 4.66, 23.4, sin(a) * 4.66), Vector3(0.15, 1.5, 2.2),
			Basis(Vector3.UP, -a))
	lm.lathe("Roof", Vector3(0, 24.8, 0), PackedVector2Array([Vector2(5.0, 0), Vector2(4.7, 0.5),
		Vector2(0.15, 1.2)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.box("Dressed", Vector3(0, 25.6, 0), Vector3(0.18, 0.8, 0.18))
	lm.box("Glass", Vector3(0, 1.2, 3.85), Vector3(1.4, 2.4, 0.15))
	for k in 3:
		lm.box("Glass", Vector3(0, 7.0 + 5.5 * float(k), 3.1 - 0.4 * float(k)), Vector3(0.6, 1.4, 0.15))
	lm.commit(model)

## Kaleva Church (Kalevan kirkko), Reima and Raili Pietila, 1966: the
## fish-shaped hall cast in 17 tall concrete U-shaped fins clad in pale
## yellow clay tiles with full-height slit windows between them, 35 m
## high with a flat roof, the lower parish wing at the west end and the
## cross-shaped bell tower rising from the roof.
const KALEVA_TOP := 43.5
const KALEVA_HALL := [Vector2(-19, 2), Vector2(-15, -10), Vector2(-5, -19), Vector2(10, -21),
	Vector2(22, -20), Vector2(27, -10), Vector2(30, 3), Vector2(30, 12), Vector2(24, 19),
	Vector2(8, 21), Vector2(-8, 17), Vector2(-19, 10)]

static func kaleva(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Tile", LandmarkMaterials.pbr("limestone", "#DDD3AC", 2.5))
	lm.use("Fin", LandmarkMaterials.pbr("concrete", "#A8A59C", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("membrane", "#4A4947", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Bell", LandmarkMaterials.pbr("concrete", "#D6D3CA", 3.0))
	var hall := PackedVector2Array(KALEVA_HALL)
	var wall_h := 35.0
	lm.poly_prism("Tile", hall, -1.0, wall_h, false)
	var roof_poly := PackedVector2Array()
	var c := Vector2.ZERO
	for p in hall:
		c += p
	c /= float(hall.size())
	for p in hall:
		roof_poly.append(c + (p - c) * 0.985)
	lm.poly_prism("Roof", roof_poly, wall_h - 0.4, wall_h + 0.5)
	# Parish wing and entrance hall at the west end.
	lm.poly_prism("Tile", PackedVector2Array([Vector2(-33.0, 16.0), Vector2(-33.0, 4.0), Vector2(-25.0, 0.0),
		Vector2(-17.0, 3.0), Vector2(-17.0, 12.0), Vector2(-24.0, 17.0)]), -1.0, 9.0, false)
	lm.poly_prism("Roof", PackedVector2Array([Vector2(-33.2, 16.2), Vector2(-33.2, 3.8), Vector2(-25.0, -0.2),
		Vector2(-16.8, 2.8), Vector2(-16.8, 12.2), Vector2(-24.0, 17.2)]), 8.8, 9.6)
	lm.box("Glass", Vector3(-33.05, 4.0, 10.0), Vector3(0.15, 6.0, 7.0))
	# Fins round the hall with a slit window between each pair.
	var perim := 0.0
	for i in hall.size():
		perim += hall[i].distance_to(hall[(i + 1) % hall.size()])
	var count := 17
	var fin_step := perim / float(count)
	var walked := 0.0
	var next_fin := fin_step * 0.5
	for i in hall.size():
		var p := hall[i]
		var q := hall[(i + 1) % hall.size()]
		var e := q - p
		var el := e.length()
		var dir := e / el
		var out := Vector2(dir.y, -dir.x)
		if out.dot((p + q) * 0.5 - c) < 0.0:
			out = -out
		var basis := Basis(Vector3.UP, atan2(-dir.y, dir.x))
		while next_fin <= walked + el:
			var t := next_fin - walked
			var pos := p + dir * t
			lm.box("Fin", Vector3(pos.x + out.x * 0.5, wall_h * 0.5, pos.y + out.y * 0.5),
				Vector3(1.6, wall_h, 1.0), basis)
			var mid := pos + dir * (fin_step * 0.5)
			if t + fin_step * 0.5 < el:
				lm.box("Glass", Vector3(mid.x + out.x * 0.05, 17.5, mid.y + out.y * 0.05),
					Vector3(1.0, 29.0, 0.2), basis)
			next_fin += fin_step
		walked += el
	# Cross-shaped bell tower on the roof.
	lm.box("Bell", Vector3(-6.0, wall_h + 4.25, 0), Vector3(2.4, 8.5, 2.2))
	lm.box("Bell", Vector3(-6.0, wall_h + 6.0, 0), Vector3(7.6, 2.2, 2.2))
	lm.commit(model)
