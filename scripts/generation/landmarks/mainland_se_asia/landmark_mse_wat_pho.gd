class_name LandmarkMseWatPho
extends RefCounted

## Wat Pho (Wat Phra Chetuphon) in Bangkok in true metres (42 m), in the
## palette of LandmarkMseBangkok: the four Phra Maha Chedi of the first
## four Chakri kings (42 m, redented, in green, white, yellow and blue
## mosaic), the ordination hall in its double cloister of about 400
## Buddha images with a viharn on each axis and a marble prang in each
## corner of the court, the chedi groups outside the cloister corners,
## a row of the 71 Phra Chedi Rai, and the viharn of the 46 m Reclining
## Buddha.

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")

const WAT_PHO_M := 42.0

static func wat_pho(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkMseBangkok._tiles(lm)
	lm.use("ChediGreen", LandmarkMaterials.pbr("render", "#2F7D5B", 3.0))
	lm.use("ChediYellow", LandmarkMaterials.pbr("render", "#D9A83A", 3.0))
	lm.use("ChediBlue", LandmarkMaterials.pbr("render", "#2C5FA3", 3.0))
	# Four great chedis on their walled court, one for each of the first four kings.
	var keys := ["ChediGreen", "Wall", "ChediYellow", "ChediBlue"]
	var k := 0
	lm.box("Stone", Vector3(-55, 0.4, -38), Vector3(62, 0.8, 50))
	var ring := [Vector3(-86, 0, -63), Vector3(-24, 0, -63), Vector3(-24, 0, -13), Vector3(-86, 0, -13)]
	for i in 4:
		K.sema_wall(lm, "Wall", ring[i], ring[(i + 1) % 4], 2.2, 0.8, 2.0)
	for cz in [-51.0, -25.0]:
		for cx in [-68.0, -42.0]:
			K.redent_chedi(lm, keys[k], keys[k], "Gold", Vector3(cx, 0.8, cz), 6.4, WAT_PHO_M - 0.8)
			for side in 4:
				var b := Basis(Vector3.UP, PI * 0.5 * float(side))
				lm.box(keys[k], Vector3(cx, 0.8, cz) + b * Vector3(0, 2.6, 11.4), Vector3(3.2, 5.2, 2.0), b)
				lm.box("Dark", Vector3(cx, 0.8, cz) + b * Vector3(0, 2.0, 12.42), Vector3(1.4, 2.8, 0.1), b, 0.0)
			k += 1
	# Phra Ubosot facing east, in the double cloister (Phra Rabiang).
	var oc := Vector3(70, 0, 32)
	K.thai_hall(lm, LandmarkMseBangkok.hall_keys(), oc, Basis(Vector3.UP, PI * 0.5), 15.0, 30.0, 9.0, 7, 2.4, 2, 1,
		5.0, 1.4)
	_cloister(lm, oc, 45.0, 33.0)
	# The four marble prangs in the corners of the court.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			K.redent_prang(lm, "Wall", "Dark", "Gold", oc + Vector3(sx * 33.0, 0, sz * 21.0), 1.9, 16.0, 5, true)
	# The chedi groups: five chedis on one base outside each cloister corner.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var gc := oc + Vector3(sx * 52.0, 0, sz * 38.0)
			lm.box("Stone", gc + Vector3(0, 0.6, 0), Vector3(10.0, 1.2, 10.0))
			K.small_chedi(lm, "Wall", "Gold", gc + Vector3(0, 1.2, 0), 1.6, 11.0)
			for dx in [-3.2, 3.2]:
				for dz in [-3.2, 3.2]:
					K.small_chedi(lm, "ChediGreen", "Gold", gc + Vector3(dx, 1.2, dz), 0.9, 7.0)
	# Phra Chedi Rai: a row of the 5 m chedis west of the cloister.
	for i in 14:
		K.small_chedi(lm, "Wall", "Gold", Vector3(6, 0, -12.0 + 6.0 * float(i)), 1.0, 5.0)
	# Viharn of the Reclining Buddha (46 m image): a long hall on a
	# peristyle under a two-step, two-layer roof.
	var vc := Vector3(-73, 0, 20)
	K.thai_hall(lm, LandmarkMseBangkok.hall_keys(), vc, Basis(Vector3.UP, PI * 0.5), 20.0, 54.0, 10.0, 12, 2.6, 2, 2,
		5.4, 1.2)
	lm.commit(model)

## The double cloister round the ordination hall (outer half-sizes hx,
## hz): two galleries back to back on a common wall, each under its
## own tiled roof and open to the court on square pillars, a row of
## seated gilded Buddha images along the inner gallery, and a cross
## viharn where each axis passes through it.
static func _cloister(lm: LandmarkMesh, c: Vector3, hx: float, hz: float) -> void:
	var t := 8.0
	for s in [-1.0, 1.0]:
		for g in 2:
			var off := t * 0.25 + t * 0.5 * float(g)
			var zc: float = s * (hz - off)
			lm.gable("Orange", c + Vector3(0, 4.2, zc), t * 0.5, hx * 2.0 - off * 2.0, 2.2, Basis(Vector3.UP, PI * 0.5),
				0.4, "Wall")
			var xc: float = s * (hx - off)
			lm.gable("Orange", c + Vector3(xc, 4.2, 0), t * 0.5, hz * 2.0 - off * 2.0, 2.2, Basis(), 0.4, "Wall")
		lm.box("Wall", c + Vector3(0, 2.1, s * (hz - t * 0.5)), Vector3(hx * 2.0 - t, 4.2, 0.6))
		lm.box("Wall", c + Vector3(s * (hx - t * 0.5), 2.1, 0), Vector3(0.6, 4.2, hz * 2.0 - t))
		lm.box("Wall", c + Vector3(0, 2.1, s * hz), Vector3(hx * 2.0, 4.2, 0.6))
		lm.box("Wall", c + Vector3(s * hx, 2.1, 0), Vector3(0.6, 4.2, hz * 2.0))
		U.posts(lm, "Wall", c + Vector3(-hx + t, 0, s * (hz - t)), c + Vector3(hx - t, 0, s * (hz - t)), 26, 4.2, 0.5, 0.0)
		U.posts(lm, "Wall", c + Vector3(s * (hx - t), 0, -hz + t), c + Vector3(s * (hx - t), 0, hz - t), 18, 4.2, 0.5, 0.0)
		var fb := Basis(Vector3.UP, 0.0 if s < 0.0 else PI)
		for i in 22:
			var x := -hx + t + 2.0 + (hx * 2.0 - t * 2.0 - 4.0) * float(i) / 21.0
			K.seated_buddha(lm, "Gold", c + Vector3(x, 0.4, s * (hz - t * 0.5 - 1.2)), fb, 1.6)
		var sb := Basis(Vector3.UP, -PI * 0.5 * s)
		for i in 14:
			var z := -hz + t + 2.0 + (hz * 2.0 - t * 2.0 - 4.0) * float(i) / 13.0
			K.seated_buddha(lm, "Gold", c + Vector3(s * (hx - t * 0.5 - 1.2), 0.4, z), sb, 1.6)
	# The four viharns crossing the cloister on the axes.
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var half := hz if side % 2 == 0 else hx
		var vc := c + b * Vector3(0, 0, half - t * 0.5)
		lm.box("Stone", vc + Vector3(0, 0.4, 0), Vector3(12.0, 0.8, 16.0), b)
		lm.box("Wall", vc + Vector3(0, 3.6, 0), Vector3(10.0, 5.6, 14.0), b)
		K.thai_window(lm, "Wall", "Dark", "Gold", vc + b * Vector3(0, 0.8, 7.02), b, 2.2, 4.0)
		K.thai_roof(lm, "Orange", "Green", "Gold", "Wall", vc + Vector3(0, 6.4, 0), b, 11.0, 16.0, 3.6, 1.0, 1, 0, 1.6)
