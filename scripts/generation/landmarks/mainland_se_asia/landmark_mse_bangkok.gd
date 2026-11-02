class_name LandmarkMseBangkok
extends RefCounted

## Bangkok temples in true metres: the Grand Palace (45 m: the golden
## Phra Si Rattana Chedi, Mondop and Pantheon of Wat Phra Kaew, the
## Chakri Maha Prasat with its three Thai spires over a European body,
## the Dusit Maha Prasat, inside the white crenellated wall) and Wat Pho
## (42 m: the four great tiled chedis, the ordination hall in its
## cloister and the Reclining Buddha viharn).

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")

const PALACE_M := 45.0
const WAT_PHO_M := 42.0

static func _tiles(lm: LandmarkMesh) -> void:
	lm.use("Wall", LandmarkMaterials.pbr("render", "#EDE6D2", 3.0))
	lm.use("Orange", LandmarkMaterials.pbr("terracotta", "#D9661F", 2.0))
	lm.use("Green", LandmarkMaterials.pbr("slate", "#2F7F5A", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.paint("#2A2320", 0.9, 0.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D8D0BE", 3.0))

# --- Grand Palace ---

## Wat Phra Kaew in the north-east of the compound (160 x 155 m inside its
## white crenellated wall and gallery: the golden chedi, Mondop and Pantheon
## in a row on the upper terrace, the eight prangs, the ubosot to the east),
## the Chakri Maha Prasat 165 m south-west of it and the Dusit hall beyond.
## Placed from OpenStreetMap positions; the courts between are left open.
static func grand_palace(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_tiles(lm)
	# Wat Phra Kaew (160 x 155 m): crenellated wall, gallery, the raised
	# terrace with the chedi, Mondop and Pantheon in a row, the ubosot east.
	var wk := Vector3(84, 0, -54)
	U.crenel_ring(lm, "Wall", wk, 80.0, 77.5, 4.0, 1.8)
	U.cloister(lm, "Wall", "Orange", wk + Vector3(0, 0, 0), 76.0, 73.5, 5.0, 4.2, 2.5)
	lm.box("Stone", Vector3(68, 0.6, -68), Vector3(84, 1.2, 42))
	# Phra Si Rattana Chedi: the gilded bell stupa (45 m).
	U.bell_chedi(lm, "Gold", "Gold", "Gold", Vector3(44, 1.2, -67), 7.0, PALACE_M - 1.2)
	_mondop(lm, Vector3(68, 1.2, -68))
	_pantheon(lm, Vector3(92, 1.2, -70))
	_ubosot(lm, Vector3(132, 0, -43), 36.0, 15.0)
	# The eight prangs along the terrace (the Phra Atthaphra).
	for i in 8:
		U.prang(lm, "Wall", "Dark", Vector3(28.0 + 10.0 * float(i), 0, -40), 2.1, 13.0, 3)
	# Chakri Maha Prasat (87 m long, facing north) and the Dusit hall to its west.
	_chakri(lm, Vector3(-65, 0, 109), Basis(Vector3.UP, PI))
	_dusit(lm, Vector3(-148, 0, 94))
	lm.commit(model)

## Phra Mondop: the scripture library, a square hall under a stepped roof
## and a five-tier spire (33 m).
static func _mondop(lm: LandmarkMesh, base: Vector3) -> void:
	lm.box("Stone", base + Vector3(0, 0.75, 0), Vector3(16, 1.5, 16))
	lm.box("Wall", base + Vector3(0, 5.5, 0), Vector3(12, 8, 12))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("Dark", base + b * Vector3(0, 4.2, 6.05), Vector3(3, 5, 0.15), b)
		lm.box("Gold", base + b * Vector3(0, 8.6, 6.05), Vector3(8, 0.5, 0.2), b)
	lm.spire("Green", base + Vector3(0, 9.5, 0), 7.6, 3.0, 5.2)
	U.prasat_spire(lm, "Gold", "Orange", "Gold", base + Vector3(0, 12.5, 0), 5.0, 33.0 - 1.2 - 12.5, 5)

## Prasat Phra Thep Bidon (the Royal Pantheon): cruciform hall under
## crossed gabled roofs and a gilded prang (31 m).
static func _pantheon(lm: LandmarkMesh, base: Vector3) -> void:
	lm.box("Stone", base + Vector3(0, 0.5, 0), Vector3(24, 1.0, 24))
	lm.box("Wall", base + Vector3(0, 5.5, 0), Vector3(20, 9, 8))
	lm.box("Wall", base + Vector3(0, 5.5, 0), Vector3(8, 9, 20))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("Dark", base + b * Vector3(0, 4.0, 10.05), Vector3(2.6, 5, 0.15), b)
	U.swept_roof(lm, "Orange", "Green", "Wall", base + Vector3(0, 10.0, 0), Basis(), 8.0, 20.0, 3.4, 1.2)
	U.swept_roof(lm, "Orange", "Green", "Wall", base + Vector3(0, 10.0, 0), Basis(Vector3.UP, PI * 0.5), 8.0, 20.0, 3.4, 1.2)
	U.prang(lm, "Gold", "Dark", base + Vector3(0, 12.0, 0), 4.6, 31.0 - 1.2 - 12.0)

## The ubosot of the Emerald Buddha: a long hall facing east with a
## three-tier roof in orange tiles and green borders on gilded columns.
static func _ubosot(lm: LandmarkMesh, base: Vector3, l: float, w: float) -> void:
	lm.box("Stone", base + Vector3(0, 0.6, 0), Vector3(l + 6.0, 1.2, w + 6.0))
	var y0 := 1.2
	lm.box("Wall", base + Vector3(0, y0 + 4.5, 0), Vector3(l, 9.0, w))
	for s in [-1.0, 1.0]:
		U.posts(lm, "Gold", base + Vector3(-l * 0.5 - 1.0, y0, s * (w * 0.5 + 1.2)),
			base + Vector3(l * 0.5 + 1.0, y0, s * (w * 0.5 + 1.2)), 10, 9.0, 0.8)
		lm.box("Dark", base + Vector3(l * 0.5 + 0.05, y0 + 3.0, s * 3.2), Vector3(0.15, 5.0, 2.6))
	U.tiered_roof(lm, "Wall", "Orange", "Green", base + Vector3(0, y0 + 9.0, 0),
		Basis(Vector3.UP, PI * 0.5), w + 2.0, l + 2.0, 4.5, 3, 1.4)

## Chakri Maha Prasat: a long three-storey Renaissance body in cream
## plaster (arched windows in two rows, central and end pavilions, grand
## stair) crowned by three Thai prasat spires (44 m central). `b` turns
## the front (+Z in its own frame) to face north.
static func _chakri(lm: LandmarkMesh, o: Vector3, b: Basis) -> void:
	lm.box("Stone", o + b * Vector3(0, 1.1, 0), Vector3(88, 2.2, 29), b)
	lm.box("Wall", o + b * Vector3(0, 9.95, 0), Vector3(78, 15.5, 22), b)
	lm.box("Wall", o + b * Vector3(0, 17.9, 0), Vector3(80, 0.8, 24), b)
	lm.box("Wall", o + b * Vector3(0, 9.95, 14.5), Vector3(22, 15.5, 7), b)
	lm.box("Wall", o + b * Vector3(0, 17.9, 14.5), Vector3(24, 0.8, 9), b)
	for sx in [-1.0, 1.0]:
		lm.box("Wall", o + b * Vector3(sx * 31, 9.95, 12.5), Vector3(16, 15.5, 3), b)
		lm.box("Wall", o + b * Vector3(sx * 31, 17.9, 12.5), Vector3(18, 0.8, 5), b)
	for row in 2:
		var wy := 6.6 + 7.2 * float(row)
		for i in 9:
			var x := -32.0 + 8.0 * float(i)
			var zf := 18.1 if absf(x) < 10.0 else (14.1 if absf(x) > 26.0 else 11.1)
			lm.box("Dark", o + b * Vector3(x, wy, zf), Vector3(2.2, 4.2, 0.2), b)
	lm.box("Dark", o + b * Vector3(0, 5.2, 18.1), Vector3(5.0, 6.0, 0.2), b)
	U.stairs(lm, "Stone", o + b * Vector3(0, 0, 18), b, 14.0, 5, 0.6, 0.44)
	U.swept_roof(lm, "Orange", "Green", "Wall", o + b * Vector3(0, 18.3, 0),
		b * Basis(Vector3.UP, PI * 0.5), 22.0, 78.0, 4.2, 1.0, 1.0)
	for sx in [-1.0, 1.0]:
		var pc := o + b * Vector3(sx * 31, 18.3, 3)
		lm.spire("Green", pc, 8.4, 3.5, 5.4)
		U.prasat_spire(lm, "Wall", "Orange", "Gold", pc + Vector3(0, 3.5, 0), 4.8, 32.0 - 21.8, 4)
	var cc := o + b * Vector3(0, 18.3, 3.5)
	lm.spire("Orange", cc, 11.6, 3.5, 9.0)
	lm.spire("Green", cc + Vector3(0, 3.5, 0), 9.2, 2.8, 6.4)
	U.prasat_spire(lm, "Wall", "Orange", "Gold", cc + Vector3(0, 6.3, 0), 6.2, PALACE_M - 1.0 - 24.6, 7)

## Dusit Maha Prasat: the cruciform audience hall under crossed Thai
## roofs and a four-tier spire (27 m).
static func _dusit(lm: LandmarkMesh, o: Vector3) -> void:
	lm.box("Stone", o + Vector3(0, 0.6, 0), Vector3(30, 1.2, 30))
	lm.box("Wall", o + Vector3(0, 5.7, 0), Vector3(26, 9, 9))
	lm.box("Wall", o + Vector3(0, 5.7, 0), Vector3(9, 9, 26))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("Dark", o + b * Vector3(0, 4.7, 13.05), Vector3(3.0, 5.4, 0.15), b)
	U.swept_roof(lm, "Orange", "Green", "Wall", o + Vector3(0, 10.2, 0), Basis(), 9.0, 26.0, 4.0, 1.4)
	U.swept_roof(lm, "Orange", "Green", "Wall", o + Vector3(0, 10.2, 0), Basis(Vector3.UP, PI * 0.5),
		9.0, 26.0, 4.0, 1.4)
	U.prasat_spire(lm, "Wall", "Orange", "Gold", o + Vector3(0, 13.0, 0), 4.4, 27.0 - 13.0, 4)

# --- Wat Pho ---

## Wat Pho: the Reclining Buddha viharn (west), the four great chedis
## (green, white, yellow, blue; 42 m) in the north-west, and the ordination
## hall inside its double cloister with a row of small chedis.
static func wat_pho(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_tiles(lm)
	lm.use("ChediGreen", LandmarkMaterials.pbr("render", "#2F7D5B", 3.0))
	lm.use("ChediYellow", LandmarkMaterials.pbr("render", "#D9A83A", 3.0))
	lm.use("ChediBlue", LandmarkMaterials.pbr("render", "#2C5FA3", 3.0))
	# Four great chedis, one for each of the first four Chakri kings.
	var keys := ["ChediGreen", "Wall", "ChediYellow", "ChediBlue"]
	var k := 0
	lm.box("Stone", Vector3(-55, 0.4, -38), Vector3(62, 0.8, 50))
	for cz in [-51.0, -25.0]:
		for cx in [-68.0, -42.0]:
			U.bell_chedi(lm, keys[k], keys[k], "Gold", Vector3(cx, 0.8, cz), 6.4, WAT_PHO_M - 0.8)
			k += 1
	# Ordination hall: marble terrace, white hall, three-tier roof, gilded posts.
	var oc := Vector3(70, 0, 32)
	lm.box("Stone", oc + Vector3(0, 0.7, 0), Vector3(58, 1.4, 34))
	lm.box("Wall", oc + Vector3(0, 1.4 + 4.5, 0), Vector3(34, 9.0, 18))
	for s in [-1.0, 1.0]:
		U.posts(lm, "Gold", oc + Vector3(-18, 1.4, s * 10.2), oc + Vector3(18, 1.4, s * 10.2), 9, 9.0, 0.8)
		lm.box("Dark", oc + Vector3(17.05, 4.4, s * 3.4), Vector3(0.15, 5.0, 2.6))
	U.tiered_roof(lm, "Wall", "Orange", "Green", oc + Vector3(0, 10.4, 0), Basis(Vector3.UP, PI * 0.5),
		20.0, 36.0, 4.6, 3, 1.4)
	# Phra Rabieng: the double cloister of 394 Buddha images, corner prasats.
	U.cloister(lm, "Wall", "Green", oc, 45.0, 33.0, 6.0, 4.2, 2.6)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			U.prasat_spire(lm, "Wall", "Orange", "Gold", oc + Vector3(sx * 40.0, 0, sz * 28.0), 2.6, 14.0, 4)
	# Row of small chedis (phra chedi rai) west of the cloister.
	for i in 7:
		U.bell_chedi(lm, "Wall", "Wall", "Gold", Vector3(12, 0, 5.0 + 9.0 * float(i)), 1.5, 9.0)
	# Reclining Buddha viharn (70 x 50 m with its porches): a long hall under a two-tier roof.
	var vc := Vector3(-73, 0, 20)
	lm.box("Stone", vc + Vector3(0, 0.6, 0), Vector3(70, 1.2, 36))
	lm.box("Wall", vc + Vector3(0, 1.2 + 5.0, 0), Vector3(60, 10.0, 24))
	for s in [-1.0, 1.0]:
		U.posts(lm, "Gold", vc + Vector3(-30, 1.2, s * 13.4), vc + Vector3(30, 1.2, s * 13.4), 12, 10.0, 0.8)
		lm.box("Dark", vc + Vector3(s * 30.05, 4.4, 0), Vector3(0.15, 6.0, 4.0))
	U.tiered_roof(lm, "Wall", "Orange", "Green", vc + Vector3(0, 11.2, 0), Basis(Vector3.UP, PI * 0.5),
		26.0, 62.0, 5.0, 2, 1.6)
	lm.commit(model)
