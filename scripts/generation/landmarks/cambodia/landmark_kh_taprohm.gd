extends RefCounted

## Ta Prohm (Rajavihara) in true metres: the three galleried inner
## enclosures (I 46 x 36 m, II 80 x 62 m, III 132 x 104 m) and the laterite
## wall of the fourth (210 x 168 m) on the long east-west axis, the
## cruciform central sanctuary with the quincunx of corner towers, gopuras
## with the Bayon-style face towers added in the 13th century, the Hall of
## Dancers between the east gopuras of III and IV, the libraries in the
## south-east corners, the north and south satellite shrines, and the
## ruin: walls tumbling into rubble heaps under the huge silk-cotton and
## strangler-fig roots. Built facing +X (east).

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")
const BAYON = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_bayon.gd")

## Ta Prohm (18.5 m): see the file header. Built facing +X (east).
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7C7160", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("stone", "#645C4E", 3.0))
	lm.use("Face", LandmarkMaterials.pbr("stone", "#827866", 2.5))
	lm.use("Relief", LandmarkMaterials.pbr("stone", "#8D8471", 2.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", "#86593E", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#25221E", 2.0))
	lm.use("Rubble", LandmarkMaterials.pbr("stone", "#6A6252", 2.5))
	lm.use("Root", LandmarkMaterials.pbr("rock", "#4D4438", 3.0))
	lm.use("Moss", LandmarkMaterials.pbr("forest", "#4E5C34", 4.0))
	_platforms(lm)
	# Enclosure rings: (half-x, half-z, thickness, height, floor, seed, ruin).
	_ring(lm, 23.0, 18.0, 3.5, 4.4, 1.2, 11, 0.3, 5.0)
	_ring(lm, 40.0, 31.0, 3.5, 4.2, 0.7, 23, 0.45, 5.0)
	_ring(lm, 66.0, 52.0, 3.6, 4.0, 0.3, 37, 0.5, 5.5)
	_ring(lm, 105.0, 84.0, 1.8, 3.4, 0.0, 53, 0.4, 6.5)
	_sanctuary(lm)
	_corner_towers(lm)
	_gopuras(lm)
	_inner_buildings(lm)
	_hall_of_dancers(lm)
	_trees(lm)
	lm.commit(model)

## Deterministic 0..1 noise.
static func _hash(i: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + 7.233) * 43758.5453, 1.0)

static func _sb(lm: LandmarkMesh, key: String, c: Vector3, size: Vector3, b: Basis = Basis()) -> void:
	lm.box(key, c, size, b, 0.0)

## Raised laterite platforms under the three inner enclosures.
static func _platforms(lm: LandmarkMesh) -> void:
	for p in [[24.2, 19.2, 1.2], [41.2, 32.2, 0.7], [67.2, 53.2, 0.3]]:
		var ph: float = p[2]
		lm.box("Laterite", Vector3(0, ph * 0.5, 0), Vector3(float(p[0]) * 2.0, ph, float(p[1]) * 2.0))
	_sb(lm, "Stone", Vector3(0, 1.1, 0), Vector3(48.8, 0.2, 38.8))

## Heap of fallen blocks of radius `rad` at `c` (n blocks, mounded toward
## the middle), sizes from the noise seed.
static func _rubble(lm: LandmarkMesh, c: Vector3, rad: float, n: int, seed: int) -> void:
	for i in n:
		var u := _hash(seed * 31 + i * 3)
		var v := _hash(seed * 31 + i * 3 + 1)
		var s := 0.5 + _hash(seed * 31 + i * 3 + 2) * 1.0
		var d := rad * sqrt(u)
		var a := v * TAU
		var hgt := (1.0 - d / rad) * rad * 0.45
		var rot := Basis(Vector3.UP, a * 3.0) * Basis(Vector3.RIGHT, (u - 0.5) * 0.7) \
			* Basis(Vector3.FORWARD, (v - 0.5) * 0.5)
		_sb(lm, "Rubble", c + Vector3(cos(a) * d, hgt + s * 0.75, sin(a) * d),
			Vector3(s * 1.3, s * 0.7, s * 0.9), rot)

## Galleried ring (or, for the laterite outer wall, a plain wall) with the
## outer faces at half-sizes hx, hz: walls in segments of about 5 m, each
## intact (laterite foot, sandstone wall, slab roof, windows) or broken
## down to a stump or to a rubble heap, by `ruin` and the noise seed;
## `gate` is the half-width left open at the middle of every side.
static func _ring(lm: LandmarkMesh, hx: float, hz: float, t: float, h: float, y0: float,
		seed: int, ruin: float, gate: float) -> void:
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var lat := hx if side % 2 == 0 else hz
		var dep := hz if side % 2 == 0 else hx
		var n := int(ceil(lat * 2.0 / 5.0))
		var seg := lat * 2.0 / float(n)
		for i in n:
			var x := -lat + seg * (float(i) + 0.5)
			if absf(x) < gate:
				continue
			var r := _hash(seed + side * 97 + i * 13)
			if i == 0 or i == n - 1:
				r = 1.0
			var f := 1.0
			if r < ruin * 0.4:
				f = 0.0
			elif r < ruin:
				f = 0.25 + 0.5 * _hash(seed + i * 31 + side)
			var wz := dep - t * 0.5
			if f > 0.0:
				var foot := minf(h * f, h * 0.5)
				lm.box("Laterite", b * Vector3(x, y0 + foot * 0.5, wz), Vector3(seg - 0.1, foot, t), b, 0.0)
				if f * h > h * 0.5:
					var up := h * f - foot
					_sb(lm, "Stone", b * Vector3(x, y0 + foot + up * 0.5, wz), Vector3(seg - 0.1, up, t - 0.2), b)
				if f > 0.99:
					_sb(lm, "Roof", b * Vector3(x, y0 + h + 0.3, wz), Vector3(seg + 0.2, 0.6, t + 0.5), b)
					if t > 2.0 and i % 3 == 0:
						_sb(lm, "Dark", b * Vector3(x, y0 + h * 0.58, dep + 0.02), Vector3(0.9, 1.4, 0.1), b)
						_sb(lm, "Stone", b * Vector3(x, y0 + h * 0.58 + 0.85, dep + 0.08), Vector3(1.5, 0.22, 0.3), b)
				else:
					_sb(lm, "Rubble", b * Vector3(x + 0.6, y0 + foot + 0.25, wz + 0.3), Vector3(1.1, 0.5, 1.0),
						Basis(Vector3.UP, r * 5.0))
			if f < 1.0:
				_rubble(lm, b * Vector3(x, y0, dep + 0.9), 2.2, 4, seed + side * 17 + i)

## Cruciform central sanctuary on its plinth: the lotus-bud tower, the
## long east antechamber (mandapa) with its stair, and the porches.
static func _sanctuary(lm: LandmarkMesh) -> void:
	var y := 1.2
	lm.box("Stone", Vector3(0, y + 1.2, 0), Vector3(12.0, 2.4, 12.0))
	lm.box("Stone", Vector3(0, y + 1.2, 0), Vector3(18.4, 2.4, 7.0))
	lm.box("Stone", Vector3(0, y + 1.2, 0), Vector3(7.0, 2.4, 15.0))
	_sb(lm, "Roof", Vector3(0, y + 2.3, 0), Vector3(12.6, 0.2, 12.6))
	U.prasat(lm, "Stone", "Roof", "Dark", Vector3(0, y + 2.4, 0), 2.9, 11.0, 3, 0.3)
	var eb := Basis(Vector3.UP, PI * 0.5)
	# East antechamber with gabled roof, stair, and false-door porches.
	lm.box("Stone", Vector3(6.0, y + 2.4 + 1.6, 0), Vector3(4.6, 3.2, 4.4))
	_sb(lm, "Dark", Vector3(8.32, y + 2.4 + 1.2, 0), Vector3(0.06, 2.4, 1.8))
	lm.gable("Roof", Vector3(6.0, y + 2.4 + 3.2, 0), 4.4, 4.6, 1.5, eb, 0.3, "Stone")
	U.stair(lm, "Stone", eb * Vector3(0, y, 9.2), eb, 5.0, 4, 0.6, 2.4 / 4.0)
	for k in 3:
		var b := Basis(Vector3.UP, PI * (0.5 * float(k) + 1.0))
		lm.box("Stone", b * Vector3(0, y + 2.4 + 1.4, 3.8), Vector3(3.4, 2.8, 2.2), b)
		_door(lm, b * Vector3(0, y + 2.4, 4.9), b, 1.1, 2.0)
	_rubble(lm, Vector3(-6.5, y + 0.2, 3.5), 3.2, 12, 5)
	_rubble(lm, Vector3(3.0, y + 0.2, -7.0), 2.6, 9, 6)

## The quincunx of corner towers on the first gallery, the corner shrines
## of II and III (the north-west corner of III is a heap), the south and
## north satellite shrines of III.
static func _corner_towers(lm: LandmarkMesh) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var base_y := 1.2 + 4.4 + 0.6
			_prasat(lm, Vector3(sx * 21.25, base_y, sz * 16.25), 1.55, 6.5, 2)
			_sb(lm, "Stone", Vector3(sx * 21.25, 1.2 + 4.4 + 0.3, sz * 16.25), Vector3(4.6, 0.6, 4.6))
			var c2 := Vector3(sx * 38.25, 0.7 + 4.2 + 0.6, sz * 29.25)
			if sx < 0.0 and sz < 0.0:
				_rubble(lm, c2 + Vector3(0, -0.5, 0), 3.4, 10, 71)
				_prasat(lm, c2, 1.6, 3.2, 1)
			else:
				_prasat(lm, c2, 1.65, 5.8, 2)
			var c3 := Vector3(sx * 64.2, 0.3 + 4.0 + 0.6, sz * 50.2)
			if sx > 0.0 and sz < 0.0:
				_rubble(lm, c3 + Vector3(0, -0.6, 0), 4.0, 11, 83)
			else:
				_prasat(lm, c3, 1.75, 6.0, 2)
	for sz in [-1.0, 1.0]:
		var c := Vector3(-4.0, 0.3, sz * 41.5)
		lm.box("Stone", c + Vector3(0, 0.6, 0), Vector3(7.0, 1.2, 7.0))
		_prasat(lm, c + Vector3(0, 1.2, 0), 1.9, 8.0, 3)
		_rubble(lm, c + Vector3(4.0, 0, sz * 3.5), 2.4, 9, 91 + int(sz))

## Gopuras of the four enclosures, three-chambered with side wings and
## pedimented false doors: I and II crowned by small towers, III and IV by
## Bayon-style face towers (with some faces fallen).
static func _gopuras(lm: LandmarkMesh) -> void:
	# [hx, hz, y0, wall h, w, d, tower kind (0 none, 1 prasat, 2 face)]
	var rings := [[23.0, 18.0, 1.2, 4.4, 7.0, 6.0, 1], [40.0, 31.0, 0.7, 4.2, 8.0, 7.0, 1],
		[66.0, 52.0, 0.3, 4.0, 9.0, 8.0, 2], [105.0, 84.0, 0.0, 3.4, 10.0, 9.0, 2]]
	var ri := 0
	for r in rings:
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			var dep: float = float(r[1]) if side % 2 == 0 else float(r[0])
			var east_west := side % 2 == 1
			var kind: int = int(r[6])
			var wreck := 0
			if ri == 3 and side == 1:
				wreck = 1
			elif ri == 2 and side == 3:
				wreck = -1
			_gopura(lm, b, dep, float(r[2]), float(r[3]), float(r[4]), float(r[5]),
				kind if east_west or ri < 2 else (1 if kind == 2 else kind), ri, wreck)
		ri += 1

## One gopura on a ring side in the frame of basis `b` (local +Z out): the
## central block astride the wall, `w` wide, `d` deep, with the dark
## passage, the gabled wings with false doors on their outer faces, and its
## tower: 1 a small prasat, 2 a face tower. `wreck` +-1 drops that wing
## (local lateral sign) into rubble.
static func _gopura(lm: LandmarkMesh, b: Basis, dep: float, y0: float, wall_h: float, w: float,
		d: float, kind: int, ring: int, wreck: int) -> void:
	var zc := dep - d * 0.5 + 0.8
	var bh := wall_h + 0.9
	lm.box("Laterite", b * Vector3(0, y0 + bh * 0.25, zc), Vector3(w, bh * 0.5, d), b, 0.0)
	lm.box("Stone", b * Vector3(0, y0 + bh * 0.5 + bh * 0.25, zc), Vector3(w - 0.4, bh * 0.5, d - 0.4), b, 0.0)
	_sb(lm, "Roof", b * Vector3(0, y0 + bh + 0.2, zc), Vector3(w + 0.8, 0.4, d + 0.8), b)
	for sz in [-1.0, 1.0]:
		var pc := b * Vector3(0, y0, zc + sz * (d * 0.5 + 0.02))
		_sb(lm, "Dark", pc + b * Vector3(0, 1.8, 0), Vector3(2.4, 3.6, 0.14), b)
		for sx in [-1.0, 1.0]:
			_sb(lm, "Stone", pc + b * Vector3(sx * 1.5, 1.9, 0.18 * sz), Vector3(0.55, 3.8, 0.45), b)
		_sb(lm, "Stone", pc + b * Vector3(0, 3.95, 0.18 * sz), Vector3(3.8, 0.5, 0.55), b)
	# Wings.
	var ww := 4.6
	for s in [-1.0, 1.0]:
		var xs: float = s * (w * 0.5 + ww * 0.5 - 0.2)
		if wreck == int(s):
			_rubble(lm, b * Vector3(xs, y0, zc), 3.4, 11, 101 + ring)
			continue
		var wh := wall_h * 0.85
		lm.box("Laterite", b * Vector3(xs, y0 + wh * 0.3, zc), Vector3(ww, wh * 0.6, d - 0.8), b, 0.0)
		_sb(lm, "Stone", b * Vector3(xs, y0 + wh * 0.6 + wh * 0.2, zc), Vector3(ww - 0.3, wh * 0.4, d - 1.1), b)
		lm.gable("Roof", b * Vector3(xs, y0 + wh, zc), ww - 0.2, d - 0.8, 1.3, b, 0.3, "Stone")
		_door(lm, b * Vector3(xs, y0 + 0.2, zc + d * 0.5 - 0.4), b, 1.0, 2.2)
	# Tower.
	var top := y0 + bh + 0.4
	if kind == 2:
		var mask := 15
		if ring == 3:
			mask = 11 if wreck != 0 else 7
		elif ring == 2:
			mask = 13
		var h := 13.8 if ring == 3 else 12.0
		BAYON.face_tower(lm, b * Vector3(0, 0, zc) + Vector3(0, top, 0), 5.0, h, 2, mask)
	elif kind == 1:
		_prasat(lm, b * Vector3(0, 0, zc) + Vector3(0, top, 0), 1.6, 5.0 if ring == 0 else 6.2, 2)
	else:
		lm.gable("Roof", b * Vector3(0, y0 + bh + 0.4, zc), w - 0.4, d, 1.8, b, 0.3, "Stone")

## Libraries in the south-east corners of the first and third enclosures,
## the long halls against the second, and the House of Fire east of the
## fourth gopura.
static func _inner_buildings(lm: LandmarkMesh) -> void:
	var eb := Basis(Vector3.UP, PI * 0.5)
	_library(lm, Vector3(12.0, 1.2, 10.0), 4.0, 7.0)
	_library(lm, Vector3(54.0, 0.3, 40.0), 4.6, 8.0)
	# Long halls inside the north and south sides of the third enclosure.
	for sz in [-1.0, 1.0]:
		var c := Vector3(32.0, 0.3, sz * 45.0)
		lm.box("Laterite", c + Vector3(0, 0.6, 0), Vector3(22.0, 1.2, 4.2))
		for i in 7:
			lm.box("Stone", c + Vector3(-9.0 + 3.0 * float(i), 2.2, -1.6 * sz), Vector3(0.7, 2.2, 0.7), Basis(), 0.0)
			if i % 3 != 2:
				lm.box("Stone", c + Vector3(-9.0 + 3.0 * float(i), 2.2, 1.6 * sz), Vector3(0.7, 2.2, 0.7), Basis(), 0.0)
		_sb(lm, "Roof", c + Vector3(-3.0, 3.5, 0), Vector3(12.0, 0.3, 4.4))
	# House of Fire: a laterite hall east of the outer gopura, roof lost.
	var hc := Vector3(120.0, 0.0, 6.0)
	lm.box("Laterite", hc + Vector3(0, 0.7, 0), Vector3(7.0, 1.4, 11.0))
	for sz in [-1.0, 1.0]:
		lm.box("Laterite", hc + Vector3(0, 2.6, sz * 5.0), Vector3(7.0, 2.4, 1.0))
	lm.box("Laterite", hc + Vector3(3.0, 2.6, 0), Vector3(1.0, 2.4, 11.0))
	_sb(lm, "Dark", hc + Vector3(-3.55, 2.4, 0), Vector3(0.1, 2.0, 1.6))
	_rubble(lm, hc + Vector3(-1.0, 1.4, 1.5), 2.6, 10, 111)

## Small lotus-bud sanctuary tower of height h on `base`: moulded plinth,
## `tiers` receding storeys with dark doors and lintels on every side,
## cornices, and a lotus crown.
static func _prasat(lm: LandmarkMesh, base: Vector3, hw: float, h: float, tiers: int) -> void:
	var ph := h * 0.14
	_sb(lm, "Stone", base + Vector3(0, ph * 0.3, 0), Vector3(hw * 2.6, ph * 0.6, hw * 2.6))
	_sb(lm, "Roof", base + Vector3(0, ph * 0.85, 0), Vector3(hw * 2.4, ph * 0.3, hw * 2.4))
	var crown := h * 0.26
	var sh := (h - ph - crown) / float(tiers)
	var y := ph
	var w := hw
	for k in tiers:
		_sb(lm, "Stone", base + Vector3(0, y + sh * 0.32, 0), Vector3(w * 2.0, sh * 0.64, w * 2.0))
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			_sb(lm, "Dark", base + b * Vector3(0, y + sh * 0.3, w + 0.03), Vector3(w * 0.5, sh * 0.5, 0.06), b)
			if k == 0:
				_sb(lm, "Stone", base + b * Vector3(0, y + sh * 0.58, w + 0.06), Vector3(w * 0.8, sh * 0.1, 0.12), b)
		_sb(lm, "Roof", base + Vector3(0, y + sh * 0.7, 0), Vector3(w * 2.3, sh * 0.12, w * 2.3))
		_sb(lm, "Stone", base + Vector3(0, y + sh * 0.86, 0), Vector3(w * 1.9, sh * 0.2, w * 1.9))
		y += sh
		w *= 0.8
	U.lotus_bud(lm, "Stone", base + Vector3(0, y, 0), w * 1.1, crown, 6)

## Plain doorway on a wall face (sill centre `base`, basis +Z out): dark
## opening, jambs and lintel.
static func _door(lm: LandmarkMesh, base: Vector3, b: Basis, w: float, h: float) -> void:
	_sb(lm, "Dark", base + b * Vector3(0, h * 0.5, 0.03), Vector3(w, h, 0.06), b)
	for s in [-1.0, 1.0]:
		_sb(lm, "Stone", base + b * Vector3(s * (w * 0.5 + 0.12), h * 0.5, 0.08), Vector3(0.24, h, 0.16), b)
	_sb(lm, "Stone", base + b * Vector3(0, h + 0.14, 0.1), Vector3(w + 0.7, 0.28, 0.22), b)

## Library with the long axis east-west (`w` across, `l` along) on a
## plinth: windowed walls, dark end doors, a gabled roof.
static func _library(lm: LandmarkMesh, base: Vector3, w: float, l: float) -> void:
	var eb := Basis(Vector3.UP, PI * 0.5)
	_sb(lm, "Laterite", base + Vector3(0, 0.45, 0), Vector3(l + 2.0, 0.9, w + 2.0))
	lm.box("Stone", base + Vector3(0, 0.9 + 1.3, 0), Vector3(l, 2.6, w), Basis(), 0.0)
	_sb(lm, "Roof", base + Vector3(0, 3.65, 0), Vector3(l + 0.6, 0.3, w + 0.6))
	lm.gable("Roof", base + Vector3(0, 3.8, 0), w + 0.4, l, 1.6, eb, 0.3, "Stone")
	for e in [-1.0, 1.0]:
		var fb := Basis(Vector3.UP, PI * 0.5 * e)
		_door(lm, base + fb * Vector3(0, 0.9, l * 0.5), fb, 0.9, 1.7)
	for k in 2:
		for sz in [-1.0, 1.0]:
			var sb := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
			_sb(lm, "Dark", base + sb * Vector3(-l * 0.22 + l * 0.44 * float(k), 2.2, w * 0.5 + 0.03),
				Vector3(0.7, 0.9, 0.06), sb)

## Hall of Dancers: the cruciform pillared platform between the east
## gopuras of the third and fourth enclosures (x 72-100 m): a 1.4 m
## laterite platform with four rows of square pillars carrying part of its
## stone-slab roof, the west end open to the sky.
static func _hall_of_dancers(lm: LandmarkMesh) -> void:
	var cx := 84.0
	lm.box("Laterite", Vector3(cx, 0.7, 0), Vector3(24.0, 1.4, 9.0))
	lm.box("Laterite", Vector3(cx, 0.7, 0), Vector3(9.0, 1.4, 20.0))
	_sb(lm, "Stone", Vector3(cx, 1.5, 0), Vector3(24.4, 0.2, 9.4))
	_sb(lm, "Stone", Vector3(cx, 1.5, 0), Vector3(9.4, 0.2, 20.4))
	for row in 4:
		var z := -3.0 + 2.0 * float(row)
		for i in 9:
			var x := cx - 9.6 + 2.4 * float(i)
			_sb(lm, "Stone", Vector3(x, 1.6 + 1.6, z), Vector3(0.6, 3.2, 0.6))
			_sb(lm, "Roof", Vector3(x, 5.0, z), Vector3(0.9, 0.3, 0.9))
	for i in 4:
		_sb(lm, "Roof", Vector3(cx + 1.7 + 2.6 * float(i), 5.45, 0), Vector3(2.6, 0.5, 9.0))
	for i in 4:
		for sz in [-1.0, 1.0]:
			var z: float = sz * (5.6 + 2.2 * float(i))
			_sb(lm, "Stone", Vector3(cx - 3.0, 3.2, z), Vector3(0.6, 3.2, 0.6))
			_sb(lm, "Stone", Vector3(cx + 3.0, 3.2, z), Vector3(0.6, 3.2, 0.6))
	_rubble(lm, Vector3(cx - 9.0, 1.5, 2.0), 3.0, 12, 121)
	# Paved causeway across the east moat to the fourth gopura.
	lm.box("Laterite", Vector3(109.0, 0.15, 0), Vector3(12.0, 0.3, 6.0))

## The great trees: (x, base y, z, trunk radius, height, root spread, ground y).
static func _trees(lm: LandmarkMesh) -> void:
	var specs := [[103.8, 1.0, -7.2, 1.6, 15.5, 9.0, 0.0], [64.5, 3.4, 8.2, 1.3, 12.0, 8.0, 0.3],
		[-64.5, 0.6, -6.8, 1.4, 14.0, 8.5, 0.3], [-30.0, 4.9, -29.0, 1.2, 9.0, 7.0, 0.7],
		[74.0, 0.0, 7.0, 1.4, 14.5, 8.5, 0.0], [-21.2, 5.6, 6.0, 1.1, 8.0, 6.5, 1.2],
		[12.0, 0.3, 42.0, 1.6, 15.0, 9.5, 0.3], [80.0, 0.0, 70.0, 1.4, 13.0, 9.0, 0.0],
		[30.0, 4.3, -52.0, 1.2, 10.0, 7.0, 0.3]]
	var k := 0
	for s in specs:
		_tree(lm, Vector3(float(s[0]), float(s[1]), float(s[2])), float(s[3]), float(s[4]), float(s[5]),
			float(s[6]), 200 + k * 37)
		k += 1

## Silk-cotton/strangler tree: a fluted trunk of radius r and height h on
## `base`, with a mossy crown stub, and the buttress roots that pour from
## its upper trunk over the masonry to the ground at `ground_y`, spreading
## to about `spread` m, with flat buttresses along the ground.
static func _tree(lm: LandmarkMesh, base: Vector3, r: float, h: float, spread: float,
		ground_y: float, seed: int) -> void:
	lm.lathe("Root", base, PackedVector2Array([Vector2(r * 1.7, 0), Vector2(r * 1.2, h * 0.1),
		Vector2(r * 0.95, h * 0.3), Vector2(r * 1.08, h * 0.55), Vector2(r * 0.85, h * 0.8),
		Vector2(r * 0.5, h)]), 9)
	lm.lathe("Moss", base + Vector3(0, h * 0.82, 0), PackedVector2Array([Vector2(r * 0.9, 0),
		Vector2(r * 1.7, h * 0.05), Vector2(r * 1.4, h * 0.11), Vector2(r * 0.4, h * 0.16)]), 8)
	var nroots := 13
	for i in nroots:
		var a := TAU * float(i) / float(nroots) + _hash(seed + i) * 0.5
		var dir := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-dir.z, 0, dir.x)
		var rs := spread * (0.65 + 0.7 * _hash(seed + i * 5))
		var sy := base.y + h * (0.35 + 0.35 * _hash(seed + i * 7))
		var start := base + dir * r * 0.75 + Vector3(0, sy - base.y, 0)
		var endp := Vector3(base.x + dir.x * rs, ground_y + 0.25, base.z + dir.z * rs)
		var ctrl := start + dir * (rs * 0.55) + Vector3(0, -(sy - ground_y) * 0.12, 0)
		var prev := start
		var segs := 6
		for q in range(1, segs + 1):
			var t := float(q) / float(segs)
			var p := start * (1.0 - t) * (1.0 - t) + ctrl * 2.0 * (1.0 - t) * t + endp * t * t
			var wd := r * (0.55 - 0.38 * t) + 0.16
			lm.beam("Root", prev, p, wd, wd * 0.9, side)
			prev = p
		# Flat buttress along the ground.
		var g0 := Vector3(base.x + dir.x * r * 1.2, ground_y + r * 0.3, base.z + dir.z * r * 1.2)
		var g1 := Vector3(base.x + dir.x * (rs + 2.5), ground_y + r * 0.3, base.z + dir.z * (rs + 2.5))
		lm.beam("Root", g0, g1, r * 0.45, 0.3, Vector3.UP)
		if i % 3 == 0:
			var mp := g0.lerp(g1, 0.5)
			_sb(lm, "Moss", mp + Vector3(0, 0.25, 0), Vector3(1.4, 0.12, 0.9), Basis(Vector3.UP, a))
