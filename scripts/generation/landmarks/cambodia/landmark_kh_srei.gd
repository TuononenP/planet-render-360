extends RefCounted

## Banteay Srei (967) in true metres: the miniature pink-sandstone temple
## of three sanctuary towers on a T-shaped platform, the mandapa and its
## corbelled brick roof, the two brick libraries, the six stairways with
## kneeling guardians, the nested enclosures (brick 24 x 24 m, laterite
## 42 x 38 m, outer laterite wall 110 x 95 m) with their gopuras, the moat
## inside the outer wall crossed by east and west causeways, and the
## 67 m causeway to the outer gopura. Every storey and doorway carries the
## layered carved pediments and lintels the temple is known for. Built
## facing +X (east).

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")

const EB := Basis(Vector3(0, 0, -1), Vector3(0, 1, 0), Vector3(1, 0, 0))

## Banteay Srei (9.8 m): see the file header. Built facing +X (east).
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Pink", LandmarkMaterials.pbr("stone", "#B9776A", 2.0))
	lm.use("Rose", LandmarkMaterials.pbr("stone", "#CB8A74", 1.5))
	lm.use("Roof", LandmarkMaterials.pbr("stone", "#A5675A", 2.5))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", "#8A5C46", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9B5A40", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8C8170", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#2A2522", 2.0))
	lm.use("Moss", LandmarkMaterials.pbr("forest", "#4A5A34", 4.0))
	_ground(lm)
	_enclosures(lm)
	_platform(lm)
	_sanctuary(lm)
	_libraries(lm)
	_gates(lm)
	lm.commit(model)

static func _sb(lm: LandmarkMesh, key: String, c: Vector3, size: Vector3, b: Basis = Basis()) -> void:
	lm.box(key, c, size, b, 0.0)

## Moat inside the outer wall (still green water between low laterite
## kerbs), the two raised causeways across it and the 67 m paved causeway
## east of the outer wall with its boundary posts.
static func _ground(lm: LandmarkMesh) -> void:
	var y := 0.05
	for r in [[-50.0, -25.0, 50.0, -43.0], [-50.0, 25.0, 50.0, 43.0]]:
		lm.quad("Moss", Vector3(float(r[0]), y, float(r[1])), Vector3(float(r[2]), y, float(r[1])),
			Vector3(float(r[2]), y, float(r[3])), Vector3(float(r[0]), y, float(r[3])), Vector3.UP)
	for sx in [-1.0, 1.0]:
		lm.quad("Moss", Vector3(sx * 27.0, y, -25.0), Vector3(sx * 50.0, y, -25.0),
			Vector3(sx * 50.0, y, 25.0), Vector3(sx * 27.0, y, 25.0), Vector3.UP)
	# Kerbs round the moat and its islet.
	for hxz in [[27.0, 25.0], [50.0, 43.0]]:
		var kx: float = hxz[0]
		var kz: float = hxz[1]
		for s in [-1.0, 1.0]:
			U.wall_run(lm, "Laterite", "Stone", Vector3(-kx, 0, s * kz), Vector3(kx, 0, s * kz), 0.4, 0.8, 0.0)
			U.wall_run(lm, "Laterite", "Stone", Vector3(s * kx, 0, -kz), Vector3(s * kx, 0, kz), 0.4, 0.8, 0.0)
	# Causeways across the moat to the second enclosure.
	for sx in [-1.0, 1.0]:
		lm.box("Laterite", Vector3(sx * 38.0, 0.2, 0), Vector3(34.0, 0.4, 7.0))
		for sz in [-1.0, 1.0]:
			_sb(lm, "Stone", Vector3(sx * 38.0, 0.5, sz * 3.4), Vector3(34.0, 0.25, 0.4))
		for i in 7:
			for sz in [-1.0, 1.0]:
				_sb(lm, "Stone", Vector3(sx * (23.0 + 4.6 * float(i)), 0.75, sz * 3.4), Vector3(0.5, 0.8, 0.5))
	# The approach from the outer gopura.
	lm.box("Laterite", Vector3(89.0, 0.15, 0), Vector3(66.0, 0.3, 4.4))
	for i in 15:
		for sz in [-1.0, 1.0]:
			_sb(lm, "Stone", Vector3(59.0 + 4.4 * float(i), 0.55, sz * 2.3), Vector3(0.45, 0.8, 0.45))

## Walls of the three enclosures: pilastered laterite for the outer two,
## the brick wall with sandstone coping inside, each open at the gopuras.
static func _enclosures(lm: LandmarkMesh) -> void:
	_ring(lm, "Laterite", "Stone", 55.0, 47.5, 3.4, 1.8, 3.0, 5.0)
	_ring(lm, "Laterite", "Stone", 21.0, 19.0, 3.0, 1.4, 2.8, 4.5)
	_ring(lm, "Brick", "Pink", 12.0, 12.0, 2.6, 1.1, 2.0, 3.5)

## Walled rectangle (half-sizes hx, hz) open at the middle of the east and
## west sides for `gap`, with buttress pilasters every `step` metres.
static func _ring(lm: LandmarkMesh, key: String, cap: String, hx: float, hz: float, h: float,
		t: float, gap: float, step: float) -> void:
	for s in [-1.0, 1.0]:
		U.wall_run(lm, key, cap, Vector3(-hx, 0, s * hz), Vector3(hx, 0, s * hz), h, t)
		U.wall_run(lm, key, cap, Vector3(s * hx, 0, -hz), Vector3(s * hx, 0, -gap), h, t)
		U.wall_run(lm, key, cap, Vector3(s * hx, 0, gap), Vector3(s * hx, 0, hz), h, t)
		var nx := int(hx * 2.0 / step)
		for i in nx + 1:
			var x := -hx + hx * 2.0 * float(i) / float(nx)
			_sb(lm, key, Vector3(x, h * 0.5, s * (hz + t * 0.5 + 0.1)), Vector3(0.7, h, 0.3))
		var nz := int(hz * 2.0 / step)
		for i in nz + 1:
			var z := -hz + hz * 2.0 * float(i) / float(nz)
			if absf(z) < gap + 0.6:
				continue
			_sb(lm, key, Vector3(s * (hx + t * 0.5 + 0.1), h * 0.5, z), Vector3(0.3, h, 0.7))

## The T-shaped pink-sandstone platform (0.9 m): the cross bar carrying the
## three towers, the stem to the east, moulded edges, and six stairways
## (east end of the stem, two on the east face of the bar, one on its west
## face and one at each end), each flanked by two kneeling guardians.
static func _platform(lm: LandmarkMesh) -> void:
	for p in [[Vector3(-3.0, 0, 0), Vector3(9.0, 0.9, 21.0)], [Vector3(5.75, 0, 0), Vector3(8.5, 0.9, 7.0)]]:
		var c: Vector3 = p[0]
		var sz: Vector3 = p[1]
		lm.box("Pink", c + Vector3(0, 0.45, 0), sz)
		_sb(lm, "Rose", c + Vector3(0, 0.83, 0), Vector3(sz.x + 0.2, 0.14, sz.z + 0.2))
		_sb(lm, "Rose", c + Vector3(0, 0.07, 0), Vector3(sz.x + 0.3, 0.14, sz.z + 0.3))
	var stairs := [[Vector3(10.0, 0, 0), EB], [Vector3(1.5, 0, 7.0), EB], [Vector3(1.5, 0, -7.0), EB],
		[Vector3(-7.5, 0, 0), Basis(Vector3.UP, -PI * 0.5)], [Vector3(-3.0, 0, -10.5), Basis(Vector3.UP, PI)],
		[Vector3(-3.0, 0, 10.5), Basis()]]
	for st in stairs:
		var base: Vector3 = st[0]
		var b: Basis = st[1]
		U.stair(lm, "Pink", base, b, 2.8, 3, 0.5, 0.3)
		for s in [-1.0, 1.0]:
			_guard(lm, base + b * Vector3(s * 2.0, 0.9, -0.7), b)

## Kneeling guardian (about 1 m): folded legs, torso, arms resting on the
## knees, head under the pointed crown, facing basis +Z.
static func _guard(lm: LandmarkMesh, base: Vector3, b: Basis) -> void:
	_sb(lm, "Pink", base + b * Vector3(0, 0.08, 0), Vector3(0.7, 0.16, 0.8), b)
	_sb(lm, "Pink", base + b * Vector3(0, 0.26, 0.1), Vector3(0.52, 0.24, 0.5), b)
	_sb(lm, "Rose", base + b * Vector3(0, 0.6, 0), Vector3(0.36, 0.5, 0.26), b)
	for sx in [-1.0, 1.0]:
		lm.beam("Pink", base + b * Vector3(sx * 0.2, 0.74, 0), base + b * Vector3(sx * 0.26, 0.38, 0.28), 0.1, 0.1)
	_sb(lm, "Rose", base + b * Vector3(0, 0.95, 0.02), Vector3(0.2, 0.2, 0.2), b)
	lm.spire("Rose", base + b * Vector3(0, 1.04, 0.02), 0.12, 0.3, 0.02)

## Lotus-petal-fronted pediment of rise `rise` on the wall face at `base`
## (the eave line), basis +Z out of the wall: three superimposed tympana,
## the flaming rake of leaf scrolls ending in upturned curls, and the
## niche with the seated Indra.
static func _pediment(lm: LandmarkMesh, base: Vector3, b: Basis, w: float, rise: float) -> void:
	for k in 3:
		var f := 1.0 - 0.2 * float(k)
		var key := "Pink" if k % 2 == 0 else "Rose"
		lm.gable(key, base + b * Vector3(0, 0, 0.05 + 0.05 * float(k)), w * f, 0.08, rise * f, b, 0.0, key)
	for s in [-1.0, 1.0]:
		var lo := base + b * Vector3(s * w * 0.5, 0, 0.18)
		var hi := base + b * Vector3(0, rise, 0.18)
		lm.beam("Rose", lo, hi, w * 0.06, w * 0.05, b * Vector3.BACK)
		for j in 4:
			var p := lo.lerp(hi, 0.14 + 0.22 * float(j))
			_sb(lm, "Rose", p + b * Vector3(s * w * 0.03, w * 0.04, 0.06), Vector3(w * 0.07, w * 0.08, w * 0.05), b)
		lm.beam("Rose", lo, lo + b * Vector3(s * w * 0.08, rise * 0.4, 0.0), w * 0.05, w * 0.05, b * Vector3.BACK)
	_sb(lm, "Dark", base + b * Vector3(0, rise * 0.3, 0.12), Vector3(w * 0.16, rise * 0.34, 0.04), b)
	_sb(lm, "Rose", base + b * Vector3(0, rise * 0.34, 0.16), Vector3(w * 0.07, rise * 0.2, 0.05), b)
	_sb(lm, "Rose", base + b * Vector3(0, rise * 0.1, 0.16), Vector3(w * 0.2, rise * 0.08, 0.07), b)
	lm.spire("Rose", base + b * Vector3(0, rise, 0.18), w * 0.04, rise * 0.22, 0.0)

## Carved lintel over a doorway of width w with its scroll of leaf boxes
## and the central kala mask; `base` is the lintel's lower edge centre.
static func _lintel(lm: LandmarkMesh, base: Vector3, b: Basis, w: float) -> void:
	_sb(lm, "Pink", base + b * Vector3(0, 0.06, 0.05), Vector3(w + 0.2, 0.12, 0.2), b)
	for j in 7:
		var x := (float(j) - 3.0) * w * 0.15
		_sb(lm, "Rose", base + b * Vector3(x, 0.15 + (0.04 if j % 2 == 0 else 0.0), 0.15),
			Vector3(w * 0.1, 0.08, 0.06), b)
	_sb(lm, "Rose", base + b * Vector3(0, 0.2, 0.17), Vector3(w * 0.14, 0.14, 0.08), b)

## Doorway on a wall face: jambs (octagonal colonettes when `colon`), dark
## opening, carved lintel and pediment. `base` is the sill centre.
static func _door(lm: LandmarkMesh, base: Vector3, b: Basis, w: float, h: float, colon: bool,
		pedi: float) -> void:
	_sb(lm, "Dark", base + b * Vector3(0, h * 0.5, 0.03), Vector3(w, h, 0.08), b)
	for s in [-1.0, 1.0]:
		if colon:
			U.colonette(lm, "Pink", base + b * Vector3(s * (w * 0.5 + 0.1), 0, 0.12), 0.07, h, 6)
		else:
			_sb(lm, "Pink", base + b * Vector3(s * (w * 0.5 + 0.05), h * 0.5, 0.08), Vector3(0.1, h, 0.16), b)
	_lintel(lm, base + b * Vector3(0, h, 0.0), b, w + 0.3)
	if pedi > 0.0:
		_pediment(lm, base + b * Vector3(0, h + 0.3, 0.0), b, w + 0.5, pedi)

## One three-storeyed sanctuary tower of height h over a `hw` half-width
## cella on `base`: the moulded plinth with a lotus-petal frieze, three
## receding storeys with door avant-corps, colonnettes, lintels and
## layered pediments on all four sides, corner pilasters and antefixes,
## and the lotus-bud crown.
static func _tower(lm: LandmarkMesh, base: Vector3, hw: float, h: float) -> void:
	var ph := h * 0.13
	_sb(lm, "Pink", base + Vector3(0, ph * 0.14, 0), Vector3(hw * 2.9, ph * 0.28, hw * 2.9))
	_sb(lm, "Rose", base + Vector3(0, ph * 0.46, 0), Vector3(hw * 2.7, ph * 0.36, hw * 2.7))
	_sb(lm, "Pink", base + Vector3(0, ph * 0.86, 0), Vector3(hw * 2.85, ph * 0.28, hw * 2.85))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for j in 5:
			_sb(lm, "Rose", base + b * Vector3((float(j) - 2.0) * hw * 0.5, ph * 0.46, hw * 1.35 + 0.03),
				Vector3(hw * 0.28, ph * 0.3, 0.06), b)
	var crown_h := h * 0.27
	var sh := (h - ph - crown_h) / 3.0
	var y := ph
	var w := hw
	for k in 3:
		var wh := sh * 0.72
		lm.box("Pink", base + Vector3(0, y + wh * 0.5, 0), Vector3(w * 2.0, wh, w * 2.0), Basis(), 0.0)
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			_sb(lm, "Pink", base + b * Vector3(0, y + wh * 0.5, w + w * 0.08), Vector3(w * 0.95, wh, w * 0.16), b)
			var dw := w * 0.42
			var dh := wh * 0.62
			var db := base + b * Vector3(0, y + wh * 0.06, w + w * 0.16)
			_door(lm, db, b, dw, dh, k == 0, wh * 0.38)
			for sx in [-1.0, 1.0]:
				_sb(lm, "Pink", base + b * Vector3(sx * w * 0.98, y + wh * 0.5, w * 0.98), Vector3(w * 0.16, wh, w * 0.16), b)
		var cy := y + wh
		_sb(lm, "Rose", base + Vector3(0, cy + sh * 0.04, 0), Vector3(w * 2.25, sh * 0.08, w * 2.25))
		for q in 2:
			var sw := w * (2.0 - 0.2 * float(q))
			_sb(lm, "Pink", base + Vector3(0, cy + sh * (0.13 + 0.1 * float(q)), 0), Vector3(sw, sh * 0.1, sw))
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				lm.spire("Rose", base + Vector3(sx * w * 1.0, cy + sh * 0.08, sz * w * 1.0), w * 0.1, sh * 0.34, 0.0)
		y += sh
		w *= 0.86
	U.lotus_bud(lm, "Pink", base + Vector3(0, y, 0), w * 1.15, crown_h, 10)

## The three sanctuaries (the central one 9.8 m including the platform),
## the antarala corridor and the mandapa with its corbelled brick roof,
## windows and the east pediments.
static func _sanctuary(lm: LandmarkMesh) -> void:
	var py := 0.9
	_tower(lm, Vector3(-3.0, py, 0), 1.7, 8.9)
	for s in [-1.0, 1.0]:
		_tower(lm, Vector3(-3.0, py, s * 6.8), 1.45, 7.8)
	# Antarala: low corridor from the central tower to the mandapa.
	lm.box("Pink", Vector3(1.6, py + 1.5, 0), Vector3(5.2, 3.0, 2.6))
	_sb(lm, "Rose", Vector3(1.6, py + 3.05, 0), Vector3(5.5, 0.12, 2.9))
	for q in 3:
		_sb(lm, "Brick", Vector3(1.6, py + 3.3 + 0.28 * float(q), 0), Vector3(5.4, 0.28, 2.5 - 0.6 * float(q)))
	# Mandapa: walls with balustered windows, door, brick tiered roof.
	var mc := Vector3(6.9, py, 0)
	lm.box("Pink", mc + Vector3(0, 1.3, 0), Vector3(5.6, 2.6, 4.4))
	_sb(lm, "Rose", mc + Vector3(0, 2.65, 0), Vector3(5.9, 0.14, 4.7))
	for s in [-1.0, 1.0]:
		var sb := Basis(Vector3.UP, 0.0 if s > 0.0 else PI)
		for i in 2:
			var wc := mc + Vector3(-1.2 + 2.4 * float(i), 0.8, s * 2.2)
			_sb(lm, "Dark", wc + Vector3(0, 0.55, s * 0.0), Vector3(0.9, 1.1, 0.1), sb)
			_sb(lm, "Rose", wc + Vector3(0, 1.2, 0.0), Vector3(1.2, 0.14, 0.2), sb)
			for k in 3:
				lm.beam("Pink", wc + Vector3(-0.3 + 0.3 * float(k), 0.05, s * 0.04),
					wc + Vector3(-0.3 + 0.3 * float(k), 1.1, s * 0.04), 0.09, 0.09, sb * Vector3.RIGHT)
	_door(lm, mc + EB * Vector3(0, 0, 2.8), EB, 1.1, 1.9, true, 0.0)
	_pediment(lm, mc + Vector3(2.85, 2.7, 0), EB, 4.2, 1.7)
	_pediment(lm, mc + Vector3(-2.85, 2.7, 0), Basis(Vector3.UP, -PI * 0.5), 4.2, 1.5)
	U.tiered_roof(lm, "Brick", "Rose", "Pink", mc + Vector3(0, 2.72, 0), EB, 4.4, 5.6, 1.4, 2)

## Libraries in the south-east and north-east corners of the inner
## enclosure: a brick body with a stone plinth, windows, doors with
## sandstone frames and carved pediments east and west, side-aisle roofs
## and the corbelled brick tiers.
static func _libraries(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		var c := Vector3(6.8, 0, s * 8.0)
		lm.box("Pink", c + Vector3(0, 0.3, 0), Vector3(7.8, 0.6, 4.4))
		_sb(lm, "Rose", c + Vector3(0, 0.62, 0), Vector3(8.0, 0.12, 4.6))
		lm.box("Brick", c + Vector3(0, 0.6 + 1.2, 0), Vector3(7.0, 2.4, 3.4))
		_sb(lm, "Rose", c + Vector3(0, 3.1, 0), Vector3(7.3, 0.14, 3.7))
		for e in [-1.0, 1.0]:
			var fb := Basis(Vector3.UP, PI * 0.5 if e > 0.0 else -PI * 0.5)
			_door(lm, c + Vector3(e * 3.5, 0.6, 0), fb, 0.9, 1.7, true, 0.0)
			_pediment(lm, c + Vector3(e * 3.52, 3.2, 0), fb, 3.3, 1.5)
		for k in 3:
			var wx := -2.0 + 2.0 * float(k)
			for sz in [-1.0, 1.0]:
				var sb := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
				_sb(lm, "Dark", c + Vector3(wx, 1.6, sz * 1.72), Vector3(0.7, 0.9, 0.1), sb)
				_sb(lm, "Pink", c + Vector3(wx, 2.1, sz * 1.78), Vector3(1.0, 0.14, 0.2), sb)
				_sb(lm, "Pink", c + Vector3(wx, 1.1, sz * 1.78), Vector3(1.0, 0.1, 0.2), sb)
		# Side-aisle half roofs and the tiered gable.
		for sz in [-1.0, 1.0]:
			lm.quad("Brick", c + Vector3(-3.7, 3.0, sz * 2.0), c + Vector3(3.7, 3.0, sz * 2.0),
				c + Vector3(3.7, 3.55, sz * 1.1), c + Vector3(-3.7, 3.55, sz * 1.1))
		U.tiered_roof(lm, "Brick", "Rose", "Pink", c + Vector3(0, 3.2, 0), EB, 3.2, 7.0, 1.3, 2)

## Gopuras: the inner east gate (brick), the east and west gates of the
## second enclosure, of the outer wall, the isolated outer gopura at the
## end of the causeway, and the small brick shrine at the inner west end.
static func _gates(lm: LandmarkMesh) -> void:
	var wb := Basis(Vector3.UP, -PI * 0.5)
	_gopura(lm, Vector3(12.0, 0, 0), EB, 4.6, 5.8, 3.4, "Brick", false)
	_gopura(lm, Vector3(21.0, 0, 0), EB, 5.4, 7.2, 3.8, "Laterite", true)
	_gopura(lm, Vector3(-21.0, 0, 0), wb, 5.4, 7.2, 3.8, "Laterite", true)
	_gopura(lm, Vector3(55.0, 0, 0), EB, 5.0, 6.4, 3.8, "Laterite", true)
	_gopura(lm, Vector3(-55.0, 0, 0), wb, 5.0, 6.4, 3.8, "Laterite", true)
	_gopura(lm, Vector3(122.0, 0, 0), EB, 5.4, 5.0, 4.2, "Laterite", true)
	U.small_tower(lm, "Brick", Vector3(-10.2, 0, 0), 0.9, 4.2)
	_sb(lm, "Pink", Vector3(-10.2, 3.0, 0), Vector3(1.6, 0.14, 1.6))

## Gopura on the ground at `c` with its passage along the basis +Z: plinth,
## body of `wall`, dark passage doors with carved lintels and pediments at
## both ends, a tiered pink roof, and (with `wings`) lower side chambers.
static func _gopura(lm: LandmarkMesh, c: Vector3, b: Basis, w: float, d: float, h: float, wall: String,
		wings: bool) -> void:
	var fb := Basis(Vector3.UP, PI) * b
	var ends: Array[Basis] = [fb, b]
	lm.box("Laterite", c + b * Vector3(0, 0.25, 0), Vector3(w + 0.8, 0.5, d + 0.8), b)
	lm.box(wall, c + b * Vector3(0, 0.5 + (h - 0.5) * 0.5, 0), Vector3(w, h - 0.5, d), b)
	_sb(lm, "Rose", c + b * Vector3(0, h + 0.07, 0), Vector3(w + 0.4, 0.14, d + 0.4), b)
	for end in ends:
		_door(lm, c + end * Vector3(0, 0.5, d * 0.5 + 0.02), end, 1.5, 2.2, true, 1.1)
		for s in [-1.0, 1.0]:
			_sb(lm, "Pink", c + end * Vector3(s * (w * 0.5 - 0.35), 0.5 + (h - 0.5) * 0.5, d * 0.5 + 0.08),
				Vector3(0.5, h - 0.5, 0.18), end)
	U.tiered_roof(lm, "Roof", "Rose", "Pink", c + b * Vector3(0, h + 0.14, 0), b, w + 0.4, d + 0.4, 1.8, 2)
	if wings:
		for s in [-1.0, 1.0]:
			var wc := c + b * Vector3(s * (w * 0.5 + 1.5), 0, 0)
			lm.box(wall, wc + Vector3(0, 1.2, 0), Vector3(3.0, 2.4, d * 0.75), b)
			lm.gable("Roof", wc + Vector3(0, 2.4, 0), 3.0, d * 0.75, 0.9, b, 0.3, "Pink")
			for end in ends:
				_sb(lm, "Dark", wc + end * Vector3(0, 1.3, d * 0.375 + 0.02), Vector3(0.7, 1.0, 0.08), end)
				_sb(lm, "Pink", wc + end * Vector3(0, 1.9, d * 0.375 + 0.06), Vector3(1.1, 0.14, 0.14), end)
