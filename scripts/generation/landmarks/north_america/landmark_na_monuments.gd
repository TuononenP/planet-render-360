class_name LandmarkNaMonuments
extends RefCounted

## Three commemorative monuments in true metres: the Washington
## Monument and Lincoln Memorial on the National Mall, and Mexico City's
## Angel of Independence.

const WASHINGTON_TOP_M := 169.0
const WASHINGTON_SEAM_M := 46.0
const LINCOLN_TOP_M := 30.0
const ANGEL_TOP_M := 36.0

## Washington Monument (1848-1884): the 169 m marble obelisk, 16.8 m
## square at the foot narrowing to 10.5 m at 152 m (500 ft) under the
## 16.8 m pyramidion, with the visible change of stone at 46 m where
## building stopped from 1854 to 1879; the eight observation windows
## (two per face) under the pyramidion, the aluminium apex, the east
## door with its security pavilion, and the ring of 50 flags round the
## granite plaza on its knoll.
static func washington_monument(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E6E3DB", 3.0))
	lm.use("Upper", LandmarkMaterials.pbr("limestone", "#DCD7CC", 3.0))
	lm.use("Cap", LandmarkMaterials.paint("#D8DCE0", 0.25, 0.9))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9C968B", 4.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	lm.use("Flag", LandmarkMaterials.paint("#E8E6E2", 0.6, 0.1))
	var base := 1.8
	var hw_at := func(y: float) -> float: return lerpf(8.4, 5.25, y / 152.2)
	var seam := WASHINGTON_SEAM_M
	lm.spire("Marble", Vector3(0, base, 0), 8.4, seam, hw_at.call(seam))
	lm.spire("Upper", Vector3(0, base + seam, 0), hw_at.call(seam), 150.4 - seam, 5.25)
	lm.spire("Upper", Vector3(0, base + 150.4, 0), 5.25, WASHINGTON_TOP_M - base - 150.4 - 0.6, 0.35)
	lm.spire("Cap", Vector3(0, WASHINGTON_TOP_M - 0.6, 0), 0.35, 0.6, 0.0)
	# Observation windows at the 500 ft level: recessed openings with
	# a marble surround and dark glazing, two per face.
	var slope := (8.4 - 5.25) / 152.2
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		var face: float = hw_at.call(148.6)
		var n := r * Vector3(0, slope, 1.0).normalized()
		for x in [-1.3, 1.3]:
			var c := r * Vector3(x, base + 148.6, face)
			lm.box("Upper", c + n * 0.05, Vector3(1.3, 1.8, 0.2), Basis(r.x, n.cross(r.x), n))
			lm.box("Windows", c + n * 0.12, Vector3(0.75, 1.2, 0.2), Basis(r.x, n.cross(r.x), n))
	# East door (+X) and the 2001 security pavilion in front of it.
	var e := Basis(Vector3.UP, PI * 0.5)
	lm.box("Windows", e * Vector3(0, base + 2.4, 8.35), Vector3(2.4, 4.8, 0.2), e)
	lm.box("Granite", e * Vector3(0, base + 2.0, 11.2), Vector3(8.0, 4.0, 5.4), e)
	lm.box("Granite", e * Vector3(0, base + 4.2, 11.2), Vector3(8.8, 0.4, 6.2), e)
	for x in [-2.6, 0.0, 2.6]:
		lm.box("Windows", e * Vector3(x, base + 1.9, 13.95), Vector3(1.8, 3.0, 0.15), e)
	# Plaza: the knoll, the round granite pavement, its seat wall.
	lm.lathe("Granite", Vector3.ZERO, PackedVector2Array([Vector2(46.0, 0.0), Vector2(40.0, 0.9),
		Vector2(34.0, base)]), 48)
	lm.box("Granite", Vector3(0, base + 0.25, 0), Vector3(21.0, 0.5, 21.0))
	LandmarkNaParts.ring(lm, "Granite", Vector3(0, base, 0), 30.0, 0.6, 0.55, 64)
	# The ring of 50 flags (one per state) round the foot of the knoll.
	for i in 50:
		var a := TAU * float(i) / 50.0
		var d := Vector3(cos(a), 0, sin(a))
		var p := d * 48.0
		lm.frustum("Cap", p, 0.09, 0.05, 12.0, 6)
		lm.lathe("Cap", p + Vector3(0, 12.0, 0), PackedVector2Array([Vector2(0.0, 0.0),
			Vector2(0.14, 0.12), Vector2(0.0, 0.26)]), 6)
		var t := Vector3(-d.z, 0, d.x)
		lm.quad("Flag", p + Vector3(0, 11.8, 0), p + t * 2.4 + Vector3(0, 11.8, 0),
			p + t * 2.4 + Vector3(0, 10.3, 0), p + Vector3(0, 10.3, 0), d)
		lm.quad("Flag", p + Vector3(0, 10.3, 0), p + t * 2.4 + Vector3(0, 10.3, 0),
			p + t * 2.4 + Vector3(0, 11.8, 0), p + Vector3(0, 11.8, 0), -d)
	lm.commit(model)

## Lincoln Memorial (1922, Henry Bacon): the Doric temple of 36 fluted
## Colorado Yule marble columns 13.4 m tall (12 on each long side, 8 on
## each end, one per state then) on a 57.8 x 36.1 m stylobate; the
## entablature with its frieze of state names and wreaths and moulded
## cornice; the set-back attic with festoons and eagles for the 48 states
## of 1922; the cella open to the east (+X) where the seated statue of
## Lincoln looks out over the broad flight of steps to the Reflecting
## Pool.
static func lincoln_memorial(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E2DFD7", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#CBC6BB", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#8C9192", 3.0))
	lm.use("Door", LandmarkMaterials.glass("#1F2528"))
	lm.use("Statue", LandmarkMaterials.pbr("limestone", "#EEEBE4", 2.0))
	# Terraces and the stylobate.
	lm.box("Steps", Vector3(-2.0, 0.8, 0), Vector3(76.0, 1.6, 52.0))
	lm.box("Steps", Vector3(0, 2.4, 0), Vector3(68.0, 1.6, 46.0))
	lm.box("Marble", Vector3(0, 3.85, 0), Vector3(62.0, 1.3, 41.0))
	# East steps: a broad flight from the plaza, cheek blocks each side.
	for k in 9:
		var top := 4.5 - 0.5 * float(k)
		lm.box("Steps", Vector3(31.4 + 0.9 * k, top * 0.5, 0), Vector3(0.9, top, 34.0), Basis(), 0.0)
	for sz in [-1.0, 1.0]:
		lm.box("Marble", Vector3(35.0, 2.6, sz * 18.0), Vector3(8.0, 5.2, 2.0))
		lm.box("Marble", Vector3(35.0, 5.4, sz * 18.0), Vector3(5.0, 0.4, 3.2))
	# Peristyle.
	var cy := 4.5
	var ch := 13.4
	var cr := 1.14
	for sx in [-1.0, 1.0]:
		for i in 12:
			LandmarkDetail.column(lm, "Marble", Vector3(sx * 16.5, cy, -27.5 + 5.0 * i), cr, ch, "doric", 20)
	for sz in [-1.0, 1.0]:
		for i in 6:
			LandmarkDetail.column(lm, "Marble", Vector3(-16.5 + 33.0 / 7.0 * (i + 1), cy, sz * 27.5), cr, ch,
				"doric", 20)
	# Entablature: architrave, frieze with a wreath over every column,
	# moulded cornice.
	var ey := cy + ch
	lm.box("Marble", Vector3(0, ey + 0.9, 0), Vector3(35.6, 1.8, 57.8))
	lm.box("Marble", Vector3(0, ey + 2.5, 0), Vector3(35.6, 1.4, 57.8))
	for sx in [-1.0, 1.0]:
		for i in 12:
			_wreath(lm, Vector3(sx * 17.85, ey + 2.5, -27.5 + 5.0 * i), Vector3(sx, 0, 0), 0.5)
	_cornice_box(lm, "Marble", Vector3(0, ey + 3.2, 0), 35.6, 57.8, 1.2)
	# Attic, set back: festoon swags held by eagles, its own cornice.
	var ay := ey + 4.4
	lm.box("Marble", Vector3(0, ay + 1.9, 0), Vector3(31.0, 3.8, 51.0))
	_festoons(lm, Vector3(0, ay, 0), 15.5, 25.5)
	_cornice_box(lm, "Marble", Vector3(0, ay + 3.8, 0), 31.0, 51.0, 0.8)
	lm.box("Roof", Vector3(0, ay + 5.3, 0), Vector3(29.0, 1.5, 49.0))
	lm.box("Roof", Vector3(0, LINCOLN_TOP_M - 0.4, 0), Vector3(20.0, 0.8, 40.0))
	# Cella: walls round the hall, open on the east between two antae.
	var cb := Vector3(0, cy, 0)
	lm.box("Marble", cb + Vector3(-13.2, 6.6, 0), Vector3(0.9, 13.2, 44.0))
	for sz in [-1.0, 1.0]:
		lm.box("Marble", cb + Vector3(0, 6.6, sz * 21.6), Vector3(27.0, 13.2, 0.9))
		lm.box("Marble", cb + Vector3(13.2, 6.6, sz * 13.8), Vector3(0.9, 13.2, 16.6))
	lm.box("Marble", cb + Vector3(13.2, 11.6, 0), Vector3(0.9, 3.2, 11.0))
	lm.box("Door", cb + Vector3(-12.6, 6.0, 0), Vector3(0.2, 10.0, 14.0))
	# Inside: the two rows of Ionic columns dividing the chambers.
	for sz in [-1.0, 1.0]:
		for i in 4:
			LandmarkDetail.column(lm, "Marble", cb + Vector3(-9.0 + 6.0 * i, 0, sz * 7.0), 0.75, 13.0,
				"ionic", 0)
	lm.box("Marble", cb + Vector3(0, 13.4, 0), Vector3(27.0, 0.6, 44.0))
	_lincoln_statue(lm, cb + Vector3(-7.5, 0, 0))
	lm.commit(model)

## A laurel wreath of radius r on a wall facing `n` at `c`: a ring of
## leaf clusters round a recessed disc.
static func _wreath(lm: LandmarkMesh, c: Vector3, n: Vector3, r: float) -> void:
	var t := n.cross(Vector3.UP).normalized()
	lm.disc("Marble", c + n * 0.03, n, r * 0.6, 10)
	for i in 10:
		var a0 := TAU * float(i) / 10.0
		var a1 := TAU * float(i + 1) / 10.0
		lm.beam("Marble", c + n * 0.08 + (t * cos(a0) + Vector3.UP * sin(a0)) * r,
			c + n * 0.08 + (t * cos(a1) + Vector3.UP * sin(a1)) * r, r * 0.3, 0.16, n)

## Moulded cornice round a w (X) x l (Z) block whose top edge is at `c`.
static func _cornice_box(lm: LandmarkMesh, key: String, c: Vector3, w: float, l: float, h: float) -> void:
	var hx := w * 0.5
	var hz := l * 0.5
	var corners := [Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, 0, hz), Vector3(-hx, 0, hz)]
	for i in 4:
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i + 1) % 4]
		var out := (a + b).normalized()
		out = Vector3(signf(out.x), 0, 0) if absf(out.x) > absf(out.z) else Vector3(0, 0, signf(out.z))
		var ext := (b - a).normalized() * h
		LandmarkDetail.cornice(lm, key, c + a - ext, c + b + ext, out, h)

## The attic's festoons: hanging swags between eagles, round all four
## faces of an attic hx x hz at `c` (the attic's foot).
static func _festoons(lm: LandmarkMesh, c: Vector3, hx: float, hz: float) -> void:
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		var half: float = hz if q % 2 == 0 else hx
		var face: float = hx if q % 2 == 0 else hz
		var n := 12 if q % 2 == 0 else 8
		for i in n + 1:
			var x := -half + 2.0 * half * float(i) / float(n)
			var eagle := c + r * Vector3(face + 0.25, 2.7, x)
			lm.box("Marble", eagle, Vector3(0.6, 0.9, 0.7), r)
			lm.box("Marble", eagle + Vector3(0, 0.35, 0), Vector3(0.8, 0.3, 1.3), r, 0.0)
			if i == n:
				continue
			var x1 := -half + 2.0 * half * float(i + 1) / float(n)
			var prev := c + r * Vector3(face + 0.25, 2.6, x + 0.4)
			for k in 6:
				var t := float(k + 1) / 6.0
				var zz := lerpf(x + 0.4, x1 - 0.4, t)
				var p := c + r * Vector3(face + 0.25, 2.6 - sin(PI * t) * 1.2, zz)
				lm.beam("Marble", prev, p, 0.32, 0.32)
				prev = p

## Daniel Chester French's seated Lincoln (5.8 m) on its pedestal,
## facing east.
static func _lincoln_statue(lm: LandmarkMesh, b: Vector3) -> void:
	lm.box("Statue", b + Vector3(0, 1.6, 0), Vector3(5.0, 3.2, 6.2))
	lm.box("Statue", b + Vector3(0, 3.3, 0), Vector3(5.4, 0.2, 6.6))
	var s := b + Vector3(0, 3.4, 0)
	# Chair: seat, back, arms draped with the flag.
	lm.box("Statue", s + Vector3(-0.2, 1.0, 0), Vector3(2.6, 2.0, 3.6))
	lm.box("Statue", s + Vector3(-1.3, 3.0, 0), Vector3(0.5, 4.0, 3.6))
	for sz in [-1.0, 1.0]:
		lm.box("Statue", s + Vector3(0.0, 2.4, sz * 1.65), Vector3(2.4, 0.6, 0.35))
	# Figure: legs, coat, torso, arms on the chair arms, head.
	for sz in [-1.0, 1.0]:
		lm.beam("Statue", s + Vector3(-0.4, 2.2, sz * 0.5), s + Vector3(1.2, 2.2, sz * 0.55), 0.7, 0.7)
		lm.beam("Statue", s + Vector3(1.2, 2.2, sz * 0.55), s + Vector3(1.5, 0.1, sz * 0.6), 0.55, 0.55)
		lm.box("Statue", s + Vector3(1.75, 0.1, sz * 0.6), Vector3(0.8, 0.25, 0.4))
		lm.beam("Statue", s + Vector3(-0.5, 4.2, sz * 0.95), s + Vector3(0.0, 3.0, sz * 1.25), 0.45, 0.45)
		lm.beam("Statue", s + Vector3(0.0, 3.0, sz * 1.25), s + Vector3(1.0, 2.8, sz * 1.5), 0.4, 0.4)
	lm.lathe("Statue", s + Vector3(-0.5, 2.2, 0), PackedVector2Array([Vector2(0.95, 0.0),
		Vector2(0.85, 1.0), Vector2(0.9, 2.0), Vector2(0.5, 2.3)]), 12, 0.8, 1.15)
	lm.frustum("Statue", s + Vector3(-0.45, 4.5, 0), 0.22, 0.2, 0.3, 8)
	lm.lathe("Statue", s + Vector3(-0.4, 4.8, 0), PackedVector2Array([Vector2(0.0, 0.0),
		Vector2(0.24, 0.08), Vector2(0.3, 0.35), Vector2(0.26, 0.6), Vector2(0.0, 0.75)]), 10, 1.0, 0.9)

## Angel of Independence (1910): the stepped base and the square
## pedestal (the heroes' mausoleum, its door to the south), the four
## seated bronze allegories on the corners (Law, Justice, War, Peace),
## the lion led by a child on the front steps, the 17 m fluted column
## ringed with laurel bands under its Corinthian capital with corner
## eagles, and the gilded winged Victory (6.7 m) holding up her laurel
## wreath and a broken chain, to 36 m.
static func angel_of_independence(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D5CDBB", 3.0))
	lm.use("Column", LandmarkMaterials.pbr("limestone", "#E3DCCB", 2.5))
	lm.use("Bronze", LandmarkMaterials.paint("#4B4033", 0.5, 0.5))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Door", LandmarkMaterials.glass("#1F2528"))
	for k in 3:
		lm.box("Stone", Vector3(0, 0.3 + 0.6 * k, 0), Vector3(26.0 - 3.0 * k, 0.6, 26.0 - 3.0 * k))
	# Corner piers with the seated allegories.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * 8.8, 1.8, sz * 8.8)
			lm.box("Stone", p + Vector3(0, 1.0, 0), Vector3(3.4, 2.0, 3.4))
			LandmarkDetail.cornice(lm, "Stone", p + Vector3(-1.7, 2.0, sz * 1.7), p + Vector3(1.7, 2.0, sz * 1.7),
				Vector3(0, 0, sz), 0.35, false)
			_seated(lm, "Bronze", p + Vector3(0, 2.2, 0), Vector3(sx, 0, sz).normalized())
	# Pedestal: plinth, die with pilasters and the mausoleum door, cornice.
	lm.box("Stone", Vector3(0, 2.4, 0), Vector3(15.0, 1.2, 15.0))
	lm.box("Stone", Vector3(0, 5.25, 0), Vector3(14.0, 4.5, 14.0))
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		for x in [-6.4, -2.4, 2.4, 6.4]:
			lm.box("Stone", r * Vector3(x, 5.25, 7.1), Vector3(0.9, 4.5, 0.3), r)
		lm.box("Bronze", r * Vector3(0, 5.6, 7.15), Vector3(3.2, 1.0, 0.1), r)
	lm.box("Door", Vector3(0, 4.4, 7.08), Vector3(2.2, 3.4, 0.2))
	LandmarkDetail.arch(lm, "Stone", Vector3(0, 6.1, 7.1), Vector3.BACK, 2.2, 0.35, 0.3)
	_cornice_square(lm, Vector3(0, 7.5, 0), 14.0, 0.6)
	lm.box("Stone", Vector3(0, 7.9, 0), Vector3(11.0, 0.8, 11.0))
	# Lion led by a child, on the south steps.
	var lion := Vector3(0, 1.8, 11.2)
	lm.box("Stone", lion + Vector3(0, 0.4, 0), Vector3(4.0, 0.8, 2.6))
	lm.lathe("Bronze", lion + Vector3(0, 0.8, 0) + Vector3(0, 1.0, 0), PackedVector2Array([Vector2(0.55, 0.0),
		Vector2(0.65, 0.3), Vector2(0.55, 0.6)]), 10, 2.6, 1.0)
	for x in [-1.1, 1.1]:
		for z in [-0.35, 0.35]:
			lm.frustum("Bronze", lion + Vector3(x, 0.8, z), 0.18, 0.15, 1.0, 6)
	lm.lathe("Bronze", lion + Vector3(1.7, 1.9, 0), PackedVector2Array([Vector2(0.3, 0.0),
		Vector2(0.55, 0.25), Vector2(0.5, 0.65), Vector2(0.0, 0.85)]), 10)
	LandmarkKits.statue_figure(lm, "Bronze", lion + Vector3(-1.0, 0.8, 0.9), 1.6)
	# The column: Attic base, fluted shaft, laurel rings, capital.
	var cb := Vector3(0, 8.3, 0)
	lm.box("Stone", cb + Vector3(0, 0.6, 0), Vector3(5.0, 1.2, 5.0))
	LandmarkDetail.column(lm, "Column", cb + Vector3(0, 1.2, 0), 1.75, 17.8, "corinthian", 24)
	for k in 3:
		var y := 2.8 + 4.2 * float(k)
		var rr := 1.75 if k == 0 else lerpf(1.75, 1.45, (y - 6.0) / 10.0)
		LandmarkNaParts.ring(lm, "Gold", cb + Vector3(0, y, 0), rr + 0.05, 0.22, 0.45, 32)
	# Corner eagles on the capital's abacus.
	var ab := cb + Vector3(0, 19.0, 0)
	for i in 4:
		var a := TAU * (float(i) + 0.5) / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Bronze", ab + d * 2.6 + Vector3(0, 0.5, 0), Vector3(0.6, 1.0, 0.6), Basis.looking_at(d))
		lm.beam("Bronze", ab + d * 2.6 + Vector3(0, 0.8, 0), ab + d * 2.6 + d.cross(Vector3.UP) * 0.9
			+ Vector3(0, 1.0, 0), 0.6, 0.1)
		lm.beam("Bronze", ab + d * 2.6 + Vector3(0, 0.8, 0), ab + d * 2.6 - d.cross(Vector3.UP) * 0.9
			+ Vector3(0, 1.0, 0), 0.6, 0.1)
	# Drum-shaped die under the statue, then the Victory.
	lm.frustum("Stone", ab, 3.0, 3.0, 0.6, 4, PI / 4.0)
	lm.frustum("Stone", ab + Vector3(0, 0.6, 0), 1.5, 1.2, 1.4, 16)
	lm.frustum("Stone", ab + Vector3(0, 2.0, 0), 1.4, 1.4, 0.2, 16)
	_victory(lm, ab + Vector3(0, 2.2, 0))
	lm.commit(model)

## Moulded cornice round a square block of side w whose top is at `c`.
static func _cornice_square(lm: LandmarkMesh, c: Vector3, w: float, h: float) -> void:
	_cornice_box(lm, "Stone", c - Vector3(0, h, 0), w, w, h)

## A seated robed bronze figure at `b` facing `d`: a draped lap and
## shins over a block seat, torso, arms and head.
static func _seated(lm: LandmarkMesh, key: String, b: Vector3, d: Vector3) -> void:
	var t := d.cross(Vector3.UP)
	var basis := Basis(t, Vector3.UP, d)
	lm.box(key, b + Vector3(0, 0.5, 0) - d * 0.2, Vector3(1.4, 1.0, 1.2), basis)
	lm.box(key, b + Vector3(0, 0.25, 0) + d * 0.55, Vector3(1.2, 0.5, 0.5), basis)
	lm.lathe(key, b + Vector3(0, 1.0, 0) - d * 0.25, PackedVector2Array([Vector2(0.45, 0.0),
		Vector2(0.42, 0.5), Vector2(0.48, 0.9), Vector2(0.25, 1.1)]), 10, 1.0, 0.75)
	lm.frustum(key, b + Vector3(0, 2.1, 0) - d * 0.25, 0.1, 0.1, 0.12, 8)
	lm.lathe(key, b + Vector3(0, 2.2, 0) - d * 0.25, PackedVector2Array([Vector2(0.0, 0.0),
		Vector2(0.17, 0.06), Vector2(0.2, 0.22), Vector2(0.0, 0.42)]), 10)
	for s in [-1.0, 1.0]:
		var sh: Vector3 = b + Vector3(0, 1.95, 0) - d * 0.25 + t * 0.42 * float(s)
		var el := sh + Vector3(0, -0.55, 0) + d * 0.15 + t * 0.08 * float(s)
		lm.beam(key, sh, el, 0.22, 0.22)
		lm.beam(key, el, el + d * 0.6 + Vector3(0, -0.1, 0), 0.18, 0.18)

## The gilded Victory (6.7 m to the wreath) at `b`: robed body, wings
## swept back, the right arm raising the laurel wreath and the left
## holding the broken chain.
static func _victory(lm: LandmarkMesh, b: Vector3) -> void:
	lm.lathe("Gold", b, PackedVector2Array([Vector2(0.95, 0.0), Vector2(0.75, 1.0), Vector2(0.7, 1.8),
		Vector2(0.55, 3.0), Vector2(0.6, 3.6), Vector2(0.66, 4.3), Vector2(0.3, 4.9), Vector2(0.22, 5.1)]), 16,
		1.0, 0.8)
	# Robe folds.
	for i in 8:
		var a := TAU * float(i) / 8.0
		var d := Vector3(cos(a), 0, sin(a) * 0.8)
		lm.frustum("Gold", b + d * 0.75, 0.1, 0.05, 2.8, 6)
	lm.lathe("Gold", b + Vector3(0, 5.1, 0), PackedVector2Array([Vector2(0.25, 0.0), Vector2(0.4, 0.25),
		Vector2(0.4, 0.6), Vector2(0.2, 0.9), Vector2(0.0, 1.0)]), 12)
	# Right arm up with the wreath, left arm out with the chain.
	lm.beam("Gold", b + Vector3(0.4, 4.6, 0), b + Vector3(0.9, 5.6, 0), 0.32, 0.32)
	lm.beam("Gold", b + Vector3(0.9, 5.6, 0), b + Vector3(1.3, 6.4, 0), 0.28, 0.28)
	LandmarkNaParts.ring(lm, "Gold", b + Vector3(1.35, 6.45, 0), 0.5, 0.18, 0.2, 16)
	lm.beam("Gold", b + Vector3(-0.4, 4.6, 0), b + Vector3(-1.0, 4.0, 0.4), 0.3, 0.3)
	lm.beam("Gold", b + Vector3(-1.0, 4.0, 0.4), b + Vector3(-1.5, 3.7, 1.0), 0.26, 0.26)
	for k in 5:
		lm.box("Gold", b + Vector3(-1.55, 3.45 - 0.3 * k, 1.05), Vector3(0.12, 0.26, 0.2), Basis(), 0.0)
	# Wings: each a fan of feathered panels swept back (-Z), both faces.
	for s in [-1.0, 1.0]:
		var root: Vector3 = b + Vector3(float(s) * 0.25, 4.2, -0.5)
		for f in 5:
			var t := float(f) / 4.0
			var tip: Vector3 = b + Vector3(float(s) * lerpf(1.4, 3.2, t), lerpf(6.6, 3.0, t), -0.9 - 0.2 * t)
			var tip2: Vector3 = b + Vector3(float(s) * lerpf(1.1, 2.9, t), lerpf(6.0, 2.6, t), -0.85 - 0.2 * t)
			for nz in [-1.0, 1.0]:
				lm.tri("Gold", root, tip, tip2, Vector3(0, 0, nz), Vector3(0, 0, nz), Vector3(0, 0, nz),
					Vector2.ZERO, Vector2(2.0, 0), Vector2(2.0, -0.5))
