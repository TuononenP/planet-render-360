class_name LandmarkMseBangkok
extends RefCounted

## The Grand Palace of Bangkok in true metres (45 m): Wat Phra Kaew (the
## golden Phra Si Rattana Chedi, 40 m, the Phra Mondop and the Royal
## Pantheon on the upper terrace, the ubosot of the Emerald Buddha, the
## eight prangs along the east wall, all inside the white bai sema wall
## and the Ramakien gallery), the Chakri Maha Prasat with its three
## Thai spires over a European body, and the Dusit Maha Prasat. Wat Pho
## is built by LandmarkMseWatPho with the same palette.

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")

const PALACE_M := 45.0
const SI_RATTANA_M := 40.0

static func _tiles(lm: LandmarkMesh) -> void:
	lm.use("Wall", LandmarkMaterials.pbr("render", "#EDE6D2", 3.0))
	lm.use("Orange", LandmarkMaterials.pbr("terracotta", "#D9661F", 2.0))
	lm.use("Green", LandmarkMaterials.pbr("slate", "#2F7F5A", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.paint("#2A2320", 0.9, 0.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D8D0BE", 3.0))

## Key set for LandmarkMseKit.thai_hall in the Bangkok palette.
static func hall_keys(col: String = "Gold") -> Dictionary:
	return {"wall": "Wall", "stone": "Stone", "tile": "Orange", "border": "Green", "gold": "Gold",
		"dark": "Dark", "col": col}

# --- Grand Palace ---

## Wat Phra Kaew in the north-east of the compound (160 x 155 m inside its
## white bai sema wall and gallery: the golden chedi, Mondop and Pantheon
## in a row on the upper terrace, the ubosot south of it facing east, the
## eight prangs along the east wall), the Chakri Maha Prasat 165 m
## south-west of it and the Dusit hall beyond. -Z is north; placed from
## OpenStreetMap positions; the courts between are left open.
static func grand_palace(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_tiles(lm)
	lm.use("Blue", LandmarkMaterials.pbr("render", "#3E6EA8", 3.0))
	lm.use("Pink", LandmarkMaterials.pbr("render", "#C9877F", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E3A40"))
	var wk := Vector3(84, 0, -54)
	var hx := 80.0
	var hz := 77.5
	var corners := [Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, 0, hz), Vector3(-hx, 0, hz)]
	for i in 4:
		K.sema_wall(lm, "Wall", wk + (corners[i] as Vector3), wk + (corners[(i + 1) % 4] as Vector3), 4.0, 1.8)
	_gallery(lm, wk, hx - 0.9, hz - 0.9)
	# The upper terrace (90 x 42 m) with its balustrade.
	lm.box("Stone", Vector3(71, 0.6, -68), Vector3(90, 1.2, 42))
	lm.box("Stone", Vector3(71, 1.3, -68), Vector3(90.6, 0.2, 42.6))
	for s in [-1.0, 1.0]:
		U.posts(lm, "Stone", Vector3(27, 1.2, -68 + s * 20.6), Vector3(115, 1.2, -68 + s * 20.6), 30, 1.0, 0.3)
		lm.box("Stone", Vector3(71, 2.25, -68 + s * 20.6), Vector3(88, 0.2, 0.4))
	_si_rattana(lm, Vector3(44, 1.2, -68))
	_mondop(lm, Vector3(68, 1.2, -68))
	_pantheon(lm, Vector3(94, 1.2, -68))
	# Phra Suwannachedi: the two gilded chedis (16 m) before the Pantheon.
	for s in [-1.0, 1.0]:
		K.redent_chedi(lm, "Gold", "Gold", "Gold", Vector3(112, 1.2, -68 + s * 10.0), 3.4, 16.0)
	# The ubosot of the Emerald Buddha: 48 columns, three doors each end, facing east.
	var uc := Vector3(122, 0, -28)
	K.thai_hall(lm, hall_keys("Blue"), uc, Basis(Vector3.UP, PI * 0.5), 14.0, 34.0, 10.0, 8, 3.0, 2, 1, 6.0, 1.8)
	# 112 garudas round the base: gilded figures holding nagas.
	for i in 56:
		for s in [-1.0, 1.0]:
			var x := -21.0 + 42.0 * float(i) / 55.0
			lm.box("Gold", uc + Vector3(x, 1.0, s * 12.2), Vector3(0.36, 1.1, 0.2), Basis(), 0.0)
	# The eight bai sema shrines round the ubosot.
	for p in [Vector2(-25, -14), Vector2(0, -16), Vector2(25, -14), Vector2(27, 0), Vector2(25, 14), Vector2(0, 16),
			Vector2(-25, 14), Vector2(-27, 0)]:
		var sc := uc + Vector3(p.x, 0, p.y)
		lm.box("Stone", sc + Vector3(0, 0.4, 0), Vector3(2.6, 0.8, 2.6))
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				lm.box("Wall", sc + Vector3(sx * 0.9, 1.7, sz * 0.9), Vector3(0.3, 1.8, 0.3), Basis(), 0.0)
		lm.spire("Gold", sc + Vector3(0, 2.6, 0), 1.4, 0.6, 1.0)
		U.prasat_spire(lm, "Gold", "Orange", "Gold", sc + Vector3(0, 3.2, 0), 0.9, 3.4, 3)
	# The eight prangs (Phra Atsada Maha Chedi), north to south along the east wall.
	var pk := ["Wall", "Blue", "Pink", "Green", "Wall", "Blue", "Pink", "Wall"]
	for i in 8:
		var px := 171.0 if i >= 2 else 150.0
		var pz := -126.0 + 17.0 * float(i)
		K.redent_prang(lm, pk[i], "Dark", "Gold", Vector3(px, 0, pz), 2.0, 15.0, 5, true)
	# Chakri Maha Prasat (87 m long, facing north) and the Dusit hall to its west.
	LandmarkMseChakri.chakri(lm, Vector3(-65, 0, 109), Basis(Vector3.UP, PI), PALACE_M)
	LandmarkMseChakri.dusit(lm, Vector3(-148, 0, 94))
	lm.commit(model)

## Phra Rabiang, the Ramakien gallery: a roofed walk round the inside of
## the wall, open to the court on a row of square pillars.
static func _gallery(lm: LandmarkMesh, c: Vector3, hx: float, hz: float) -> void:
	var t := 5.0
	for s in [-1.0, 1.0]:
		var zc: float = s * (hz - t * 0.5)
		lm.gable("Orange", c + Vector3(0, 4.2, zc), t, hx * 2.0, 2.4, Basis(Vector3.UP, PI * 0.5), 0.6, "Wall")
		U.posts(lm, "Wall", c + Vector3(-hx + t, 0, zc - s * t * 0.5), c + Vector3(hx - t, 0, zc - s * t * 0.5), 46, 4.2, 0.45, 0.0)
		lm.box("Wall", c + Vector3(0, 4.0, zc - s * t * 0.5), Vector3(hx * 2.0 - t * 2.0, 0.4, 0.5))
		var xc: float = s * (hx - t * 0.5)
		lm.gable("Orange", c + Vector3(xc, 4.2, 0), t, hz * 2.0 - t * 2.0, 2.4, Basis(), 0.6, "Wall")
		U.posts(lm, "Wall", c + Vector3(xc - s * t * 0.5, 0, -hz + t), c + Vector3(xc - s * t * 0.5, 0, hz - t), 44, 4.2, 0.45, 0.0)
		lm.box("Wall", c + Vector3(xc - s * t * 0.5, 4.0, 0), Vector3(0.5, 0.4, hz * 2.0 - t * 2.0))

## Phra Si Rattana Chedi (40 m): the gilded round bell chedi of 1855 on
## stepped circular bases, four porticoed entrances each carrying a
## small chedi, the square harmika with its colonnettes, twenty
## concentric rings of the spire and the needle.
static func _si_rattana(lm: LandmarkMesh, base: Vector3) -> void:
	var h := SI_RATTANA_M - base.y
	var r := 8.0
	K.redent_lathe(lm, "Gold", base, PackedVector2Array([Vector2(r * 1.55, 0), Vector2(r * 1.55, 1.2),
		Vector2(r * 1.42, 1.3), Vector2(r * 1.42, 2.4)]), 0.08)
	lm.lathe("Gold", base + Vector3(0, 2.4, 0), PackedVector2Array([Vector2(r * 1.3, 0), Vector2(r * 1.3, 0.8),
		Vector2(r * 1.2, 0.9), Vector2(r * 1.2, 1.7), Vector2(r * 1.12, 1.8), Vector2(r * 1.12, 2.6),
		Vector2(r * 1.04, 2.7), Vector2(r * 1.06, 3.2), Vector2(r * 1.0, 3.4)]), 32)
	lm.lathe("Gold", base + Vector3(0, 5.8, 0), PackedVector2Array([Vector2(r, 0), Vector2(r * 1.02, 1.2),
		Vector2(r * 0.97, 3.0), Vector2(r * 0.86, 5.4), Vector2(r * 0.66, 7.6), Vector2(r * 0.44, 9.0),
		Vector2(r * 0.3, 9.4)]), 32)
	# Harmika (balang) with its colonnettes.
	var hy := 15.2
	lm.box("Gold", base + Vector3(0, hy + 0.3, 0), Vector3(r * 0.85, 0.6, r * 0.85))
	for i in 5:
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			lm.box("Gold", base + b * Vector3(-r * 0.32 + r * 0.16 * float(i), hy + 1.2, r * 0.36), Vector3(0.22, 1.2, 0.22), b, 0.0)
	lm.box("Gold", base + Vector3(0, hy + 2.0, 0), Vector3(r * 0.9, 0.5, r * 0.9))
	# Twenty rings (plong chanai) narrowing to the needle.
	var prof := PackedVector2Array()
	var sy := hy + 2.25
	var rh := (h - sy) * 0.62 / 20.0
	for i in 20:
		var rr := r * 0.3 * (1.0 - float(i) / 22.0)
		prof.append(Vector2(rr, rh * float(i)))
		prof.append(Vector2(rr * 1.18, rh * float(i) + rh * 0.3))
		prof.append(Vector2(rr * 0.96, rh * float(i) + rh * 0.9))
	lm.lathe("Gold", base + Vector3(0, sy, 0), prof, 16)
	var ty := sy + rh * 20.0
	lm.lathe("Gold", base + Vector3(0, ty, 0), PackedVector2Array([Vector2(r * 0.07, 0), Vector2(r * 0.11, 0.6),
		Vector2(r * 0.05, 1.6), Vector2(r * 0.08, 2.2), Vector2(r * 0.03, 3.4), Vector2(0.0, h - ty)]), 10)
	# The four porticoes with their small chedis.
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var pc := base + b * Vector3(0, 0, r * 1.6)
		lm.box("Gold", pc + Vector3(0, 3.0, 0), Vector3(4.6, 6.0, 4.0), b)
		lm.box("Dark", pc + b * Vector3(0, 2.4, 2.05), Vector3(1.8, 3.6, 0.1), b, 0.0)
		K.roof_piece(lm, "Gold", "", "Gold", "Gold", pc + Vector3(0, 6.0, 0), b, 4.6, 4.0, 1.8, 0.5, 0.4, 1.0, 1)
		K.small_chedi(lm, "Gold", "Gold", pc + Vector3(0, 7.2, 0) + b * Vector3(0, 0, -0.6), 0.7, 5.0)

## Phra Mondop: the scripture library, a square hall on a redented
## plinth ringed by 20 notched glass-mosaic columns, under a stepped
## green roof and a seven-tier gilded spire (33 m).
static func _mondop(lm: LandmarkMesh, base: Vector3) -> void:
	K.redent_lathe(lm, "Stone", base, PackedVector2Array([Vector2(9.0, 0), Vector2(9.0, 0.6), Vector2(8.4, 0.8),
		Vector2(8.4, 1.5)]), 0.1)
	var y0 := 1.5
	lm.box("Wall", base + Vector3(0, y0 + 4.0, 0), Vector3(11.0, 8.0, 11.0))
	K.peristyle(lm, "Green", "Gold", base + Vector3(0, y0, 0), Basis(), 14.4, 14.4, 7.6, 0.7, 2.88)
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		K.thai_window(lm, "Wall", "Dark", "Gold", base + b * Vector3(0, y0, 5.52), b, 2.4, 4.4)
	lm.box("Gold", base + Vector3(0, y0 + 8.3, 0), Vector3(15.6, 0.6, 15.6))
	lm.spire("Green", base + Vector3(0, y0 + 8.6, 0), 8.4, 1.8, 6.6)
	lm.box("Gold", base + Vector3(0, y0 + 10.6, 0), Vector3(13.4, 0.4, 13.4))
	lm.spire("Orange", base + Vector3(0, y0 + 10.8, 0), 6.8, 1.6, 5.0)
	U.prasat_spire(lm, "Gold", "Green", "Gold", base + Vector3(0, y0 + 12.4, 0), 5.0, 33.0 - base.y - y0 - 12.4, 7)

## Prasat Phra Thep Bidon (the Royal Pantheon): cruciform hall with a
## porch on each arm under stepped green-and-orange Thai roofs, the
## main door east, and the tall prang crown (31 m).
static func _pantheon(lm: LandmarkMesh, base: Vector3) -> void:
	K.plinth(lm, "Stone", base, Basis(), 26.0, 26.0, 1.2)
	var y0 := 1.2
	for b in [Basis(), Basis(Vector3.UP, PI * 0.5)]:
		lm.box("Wall", base + Vector3(0, y0 + 4.5, 0), Vector3(8.0, 9.0, 22.0), b)
		K.thai_roof(lm, "Orange", "Green", "Gold", "Wall", base + Vector3(0, y0 + 9.0, 0), b, 9.0, 23.0, 3.6, 1.0,
			1, 1, 1.6)
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		K.thai_window(lm, "Wall", "Dark", "Gold", base + b * Vector3(0, y0, 11.02), b, 2.4, 4.8)
		for sx in [-1.0, 1.0]:
			K.thai_window(lm, "Wall", "Dark", "Gold", base + b * Vector3(sx * 4.02, y0 + 2.0, 7.0),
				b * Basis(Vector3.UP, PI * 0.5 * sx), 1.4, 3.0)
			K.thai_column(lm, "Green", "Gold", base + b * Vector3(sx * 3.4, y0, 12.6), 0.6, 8.6)
	K.redent_prang(lm, "Gold", "Dark", "Gold", base + Vector3(0, y0 + 10.6, 0), 3.4, 31.0 - base.y - y0 - 10.6, 5, false)
