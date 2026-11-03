extends RefCounted

## The Bayon of Angkor Thom in true metres: the basal platform, the outer
## gallery (156 x 141 m) with its balustered windows, pillared half-gallery and
## bas-relief wall, the raised inner gallery (80 x 70 m) with relief on its
## outer face and cruciform gopuras, the octagonal upper terrace and the
## circular central sanctuary, among 49 face towers (1 + 12 + 16 + 20).
## Shared with Ta Prohm: face_tower. Built facing +X (east).

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")

const G := 0.9          # courtyard level on the basal platform
const Y2 := 6.5         # inner gallery platform
const Y2T := 11.3       # inner gallery roof / first terrace level
const Y3 := 14.8        # upper terrace
const OX := 78.0        # outer gallery outer faces, half E-W
const OZ := 70.5        # half N-S
const IX := 40.0        # inner gallery outer faces
const IZ := 35.0
const OWALL := 4.4      # outer gallery wall height above G
const IWALL := 4.8      # inner gallery wall height above Y2

## Bayon (43 m): see the file header. Built facing +X (east).
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#76705F", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("stone", "#5C574C", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#26231F", 2.0))
	lm.use("Relief", LandmarkMaterials.pbr("stone", "#8B8372", 2.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", "#7A5A46", 3.0))
	lm.use("Face", LandmarkMaterials.pbr("stone", "#857D6B", 2.5))
	lm.use("Moss", LandmarkMaterials.pbr("forest", "#4E5A38", 4.0))
	_platform(lm)
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var lat := OX if side % 2 == 0 else OZ
		var dep := OZ if side % 2 == 0 else OX
		_outer_side(lm, b, lat, dep)
		var ilat := IX if side % 2 == 0 else IZ
		var idep := IZ if side % 2 == 0 else IX
		_inner_side(lm, b, ilat, idep)
	_courtyard(lm)
	_terrace(lm)
	_central(lm)
	_towers(lm)
	_moss_and_rubble(lm)
	lm.commit(model)

## Deterministic 0..1 noise.
static func _hash(i: int) -> float:
	return fposmod(sin(float(i) * 12.9898 + 4.1414) * 43758.5453, 1.0)

static func _sb(lm: LandmarkMesh, key: String, c: Vector3, size: Vector3, b: Basis = Basis()) -> void:
	lm.box(key, c, size, b, 0.0)

## Low laterite basal platform with a stone cornice, and the east entrance
## apron with its steps and guardian lions.
static func _platform(lm: LandmarkMesh) -> void:
	lm.box("Laterite", Vector3(0, G * 0.45, 0), Vector3(OX * 2.0 + 8.0, G * 0.9, OZ * 2.0 + 8.0))
	_sb(lm, "Stone", Vector3(0, G - 0.12, 0), Vector3(OX * 2.0 + 8.6, 0.24, OZ * 2.0 + 8.6))
	# East apron, 24 m wide, with three steps down to the road.
	lm.box("Laterite", Vector3(OX + 7.0, G * 0.45, 0), Vector3(6.0, G * 0.9, 24.0))
	var eb := Basis(Vector3.UP, PI * 0.5)
	U.stair(lm, "Stone", eb * Vector3(0, 0, OX + 10.0), eb, 24.0, 2, 0.55, G * 0.5)
	for s in [-1.0, 1.0]:
		_lion(lm, Vector3(OX + 7.0, G, s * 10.5), eb)
		_lion(lm, Vector3(OX + 7.0, G, s * 4.5), eb)

## Seated guardian lion on a plinth facing the basis +Z.
static func _lion(lm: LandmarkMesh, base: Vector3, b: Basis) -> void:
	_sb(lm, "Stone", base + b * Vector3(0, 0.3, 0), Vector3(1.4, 0.6, 2.4), b)
	_sb(lm, "Stone", base + b * Vector3(0, 1.0, -0.4), Vector3(0.9, 0.9, 1.0), b)
	_sb(lm, "Stone", base + b * Vector3(0, 1.8, -0.2), Vector3(0.5, 0.8, 0.5), b)
	_sb(lm, "Stone", base + b * Vector3(0, 2.2, 0.1), Vector3(0.7, 0.6, 0.7), b)
	_sb(lm, "Dark", base + b * Vector3(0, 2.2, 0.47), Vector3(0.4, 0.14, 0.06), b)
	for sx in [-1.0, 1.0]:
		_sb(lm, "Stone", base + b * Vector3(sx * 0.3, 1.0, 0.6), Vector3(0.2, 0.8, 0.3), b)
		_sb(lm, "Stone", base + b * Vector3(sx * 0.4, 1.0, -0.8), Vector3(0.3, 0.8, 0.5), b)

## One side of the outer gallery in the frame of basis `b` (local +Z out):
## `lat` the half-length along the side, `dep` the distance of the outer
## face from the centre. Balustered windows outside, bas-relief panels on
## the inner face of the wall, the pillared half-gallery under a stepped
## stone roof, and the cardinal gopura.
static func _outer_side(lm: LandmarkMesh, b: Basis, lat: float, dep: float) -> void:
	var y0 := G
	var h := OWALL
	var wall_z := dep - 0.8
	lm.box("Stone", b * Vector3(0, y0 + h * 0.5, wall_z), Vector3(lat * 2.0, h, 1.6), b)
	_sb(lm, "Stone", b * Vector3(0, y0 + 0.4, dep - 0.35), Vector3(lat * 2.0 + 0.2, 0.8, 1.9), b)
	_sb(lm, "Roof", b * Vector3(0, y0 + h + 0.2, dep - 1.0), Vector3(lat * 2.0 + 0.4, 0.4, 2.4), b)
	# Stepped corbelled roof sloping in to the pillars.
	var aisle := 2.6
	for k in 3:
		var kf := float(k)
		_sb(lm, "Roof", b * Vector3(0, y0 + h - 0.1 - 0.45 * kf, dep - 2.2 - (aisle + 0.4) * (kf + 0.5) / 3.0),
			Vector3(lat * 2.0 - 0.2, 0.4, (aisle + 0.4) / 3.0 + 0.1), b)
	# Architrave and pillars of the half-gallery.
	var pz := dep - 2.2 - aisle - 0.4
	_sb(lm, "Stone", b * Vector3(0, y0 + h - 1.55, pz), Vector3(lat * 2.0 - 0.2, 0.5, 0.7), b)
	var np := int(lat * 2.0 / 5.0)
	for i in np + 1:
		var x := -lat + 1.0 + (lat * 2.0 - 2.0) * float(i) / float(np)
		if absf(x) < 8.0:
			continue
		_sb(lm, "Stone", b * Vector3(x, y0 + (h - 1.8) * 0.5, pz), Vector3(0.5, h - 1.8, 0.5), b)
		_sb(lm, "Roof", b * Vector3(x, y0 + h - 1.95, pz), Vector3(0.78, 0.3, 0.78), b)
	# Bas-relief registers on the inner face of the wall, between pilasters.
	var rz := dep - 1.6 - 0.06
	var n := int(lat * 2.0 / 6.0)
	for i in n:
		var x := -lat + 3.0 + 6.0 * float(i)
		if absf(x) < 9.0:
			continue
		for r in 2:
			_sb(lm, "Relief", b * Vector3(x, y0 + 1.4 + 1.5 * float(r), rz), Vector3(5.4, 1.2, 0.12), b)
		_sb(lm, "Stone", b * Vector3(x + 3.0, y0 + h * 0.5, rz), Vector3(0.5, h, 0.2), b)
		# Standing figure rows along the lower register.
		for k in 2:
			var fh := 0.5 + 0.35 * _hash(i * 7 + k + int(dep))
			_sb(lm, "Face", b * Vector3(x - 0.8 + 1.6 * float(k), y0 + 1.4 + fh * 0.5 - 0.5, rz + 0.08),
				Vector3(0.4, fh, 0.08), b)
	# Balustered windows in the outer face.
	var nw := int(lat * 2.0 / 6.0)
	for i in nw:
		var x := -lat + 3.0 + 6.0 * float(i)
		if absf(x) < 10.0 or absf(x) > lat - 6.0 or i % 2 == 1:
			continue
		var wc := b * Vector3(x, y0 + 2.2, dep + 0.02)
		_sb(lm, "Dark", wc + b * Vector3(0, 0.1, 0), Vector3(1.5, 1.8, 0.14), b)
		_sb(lm, "Stone", wc + b * Vector3(0, 1.15, 0.12), Vector3(2.0, 0.3, 0.4), b)
		_sb(lm, "Stone", wc + b * Vector3(0, -0.95, 0.12), Vector3(1.9, 0.2, 0.36), b)
		for k in 2:
			lm.beam("Stone", wc + b * Vector3(-0.3 + 0.6 * float(k), -0.85, 0.16),
				wc + b * Vector3(-0.3 + 0.6 * float(k), 1.05, 0.16), 0.14, 0.14, b * Vector3.RIGHT)
	_gopura(lm, b, dep, y0 + h, 11.0, 8.0, 2.4, G)

## Cruciform gopura at the middle of a gallery side: stone block astride the
## wall with the dark passage, the crossed pedimented roofs, and the plinth
## for its face tower. `top` is the wall-top level, `w` the block width.
static func _gopura(lm: LandmarkMesh, b: Basis, dep: float, top: float, w: float, d: float,
		rise: float, floor_y: float) -> void:
	var hh := top - floor_y + 2.2
	var zc := dep - d * 0.5 + 1.4
	lm.box("Stone", b * Vector3(0, floor_y + hh * 0.5, zc), Vector3(w, hh, d), b)
	_sb(lm, "Roof", b * Vector3(0, floor_y + hh + 0.15, zc), Vector3(w + 0.8, 0.3, d + 0.8), b)
	# Dark passage through both faces, framed by jambs and a corbelled head.
	for sz in [-1.0, 1.0]:
		var pc := b * Vector3(0, floor_y, zc + sz * (d * 0.5 + 0.02))
		_sb(lm, "Dark", pc + b * Vector3(0, 2.3, 0), Vector3(3.2, 4.6, 0.14), b)
		for sx in [-1.0, 1.0]:
			_sb(lm, "Stone", pc + b * Vector3(sx * 2.0, 2.4, 0.2 * sz), Vector3(0.7, 4.8, 0.5), b)
		_sb(lm, "Stone", pc + b * Vector3(0, 4.9, 0.2 * sz), Vector3(4.8, 0.6, 0.6), b)
		_sb(lm, "Roof", pc + b * Vector3(0, 5.3, 0.25 * sz), Vector3(5.2, 0.3, 0.7), b)
	# Crossed gables carried on the block; the central tower rises between.
	var roof_c := b * Vector3(0, floor_y + hh + 0.3, zc)
	var sb := Basis(Vector3.UP, PI * 0.5) * b
	lm.gable("Roof", roof_c, w - 1.0, d - 0.5, rise, b, 0.3, "Stone")
	lm.gable("Roof", roof_c, d - 1.0, w - 0.5, rise * 0.9, sb, 0.3, "Stone")
	for s in [-1.0, 1.0]:
		var fb := Basis(b.y.normalized(), PI if s < 0.0 else 0.0) * b
		U.pediment(lm, "Roof", roof_c + b * Vector3(0, 0, s * ((d - 0.5) * 0.5)), fb, w - 1.0, rise)

## Entrance wings and pavilion blocks use this: a cruciform pavilion of
## half-width `hw` and height `hgt` standing at `c` on a roof.
static func _pavilion(lm: LandmarkMesh, c: Vector3, hw: float, hgt: float) -> void:
	lm.box("Stone", c + Vector3(0, hgt * 0.5, 0), Vector3(hw * 2.0, hgt, hw * 2.0))
	_sb(lm, "Roof", c + Vector3(0, hgt + 0.15, 0), Vector3(hw * 2.0 + 0.7, 0.3, hw * 2.0 + 0.7))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		_sb(lm, "Stone", c + b * Vector3(0, hgt * 0.42, hw + 0.4), Vector3(hw * 1.1, hgt * 0.84, 0.8), b)
		_sb(lm, "Dark", c + b * Vector3(0, hgt * 0.38, hw + 0.82), Vector3(hw * 0.6, hgt * 0.56, 0.06), b)

## Inner gallery on its platform, one side: stepped laterite and stone
## base, the 4.8 m wall carrying two registers of mythological relief on its
## outer face, cornice and roof, the steep axial stair and the projecting
## cruciform gopura with its pedimented roofs.
static func _inner_side(lm: LandmarkMesh, b: Basis, lat: float, dep: float) -> void:
	# Moulded platform base: laterite foot, stone die and cornice.
	lm.box("Laterite", b * Vector3(0, (Y2 - G) * 0.25 + G, dep + 2.2), Vector3(lat * 2.0 + 4.4, (Y2 - G) * 0.5, 4.4), b)
	lm.box("Stone", b * Vector3(0, G + (Y2 - G) * 0.75, dep + 1.8), Vector3(lat * 2.0 + 3.6, (Y2 - G) * 0.5, 3.6), b)
	_sb(lm, "Roof", b * Vector3(0, Y2 - 0.2, dep + 1.9), Vector3(lat * 2.0 + 4.2, 0.4, 4.0), b)
	# Gallery wall with relief.
	lm.box("Stone", b * Vector3(0, Y2 + IWALL * 0.5, dep - 1.0), Vector3(lat * 2.0, IWALL, 2.0), b)
	_sb(lm, "Roof", b * Vector3(0, Y2 + IWALL + 0.25, dep - 1.4), Vector3(lat * 2.0 + 0.8, 0.5, 3.2), b)
	_sb(lm, "Roof", b * Vector3(0, Y2 + IWALL + 0.75, dep - 2.2), Vector3(lat * 2.0 - 0.6, 0.5, 2.8), b)
	_sb(lm, "Stone", b * Vector3(0, Y2 + 0.3, dep + 0.05), Vector3(lat * 2.0 + 0.3, 0.6, 0.3), b)
	var n := int(lat * 2.0 / 4.0)
	for i in n:
		var x := -lat + 2.0 + 4.0 * float(i)
		if absf(x) < 8.5 or absf(x) > lat - 6.0:
			continue
		for r in 2:
			_sb(lm, "Relief", b * Vector3(x, Y2 + 1.6 + 1.4 * float(r), dep + 0.08), Vector3(3.5, 1.1, 0.14), b)
		_sb(lm, "Stone", b * Vector3(x + 2.0, Y2 + IWALL * 0.5, dep + 0.1), Vector3(0.4, IWALL, 0.24), b)
		for k in 1:
			var fh := 0.5 + 0.4 * _hash(i * 5 + k + int(lat))
			_sb(lm, "Face", b * Vector3(x + 1.6 * float(k), Y2 + 1.6 + fh * 0.5 - 0.5, dep + 0.2),
				Vector3(0.45, fh, 0.1), b)
	# Axial stair up the 5.6 m platform and the gopura above it.
	var steps := 8
	U.stair(lm, "Stone", b * Vector3(0, G, dep + 3.6), b, 9.0, steps, 0.7, (Y2 - G) / float(steps))
	for sx in [-1.0, 1.0]:
		lm.beam("Stone", b * Vector3(sx * 5.0, Y2 - 0.4, dep + 3.6), b * Vector3(sx * 5.0, G + 0.4, dep + 9.2),
			1.0, 1.0, b * Vector3.RIGHT, true)
	_gopura(lm, b, dep + 1.6, Y2 + IWALL, 10.0, 8.0, 2.2, Y2)

## Courtyard fittings: the two libraries flanking the east stair, and the
## paved foundations of the sixteen vanished chapels.
static func _courtyard(lm: LandmarkMesh) -> void:
	var eb := Basis(Vector3.UP, PI * 0.5)
	for s in [-1.0, 1.0]:
		_library(lm, Vector3(58.0, G, s * 20.0), 4.8, 10.5)
	# Paved foundations of the sixteen vanished chapels round the platform.
	var spots: Array[Vector2] = []
	for sz in [-1.0, 1.0]:
		for xi in [-60.0, -30.0, 0.0, 30.0, 60.0]:
			spots.append(Vector2(xi, sz * 55.0))
	for zz in [-36.0, -12.0, 12.0, 36.0]:
		spots.append(Vector2(-58.0, zz))
	spots.append(Vector2(58.0, -36.0))
	spots.append(Vector2(58.0, 36.0))
	for sp in spots:
		_sb(lm, "Laterite", Vector3(sp.x, G + 0.12, sp.y), Vector3(4.2, 0.24, 3.2))
		_sb(lm, "Stone", Vector3(sp.x, G + 0.34, sp.y), Vector3(3.6, 0.2, 2.6))

## East-west library in the courtyard: plinth, windowed stone walls,
## dark end doors, tiered gabled roof.
static func _library(lm: LandmarkMesh, base: Vector3, w: float, l: float) -> void:
	var eb := Basis(Vector3.UP, PI * 0.5)
	lm.box("Laterite", base + Vector3(0, 0.5, 0), Vector3(l + 2.2, 1.0, w + 2.2), Basis(), 0.0)
	lm.box("Stone", base + Vector3(0, 1.0 + 1.3, 0), Vector3(l, 2.6, w), Basis(), 0.0)
	_sb(lm, "Roof", base + Vector3(0, 3.75, 0), Vector3(l + 0.8, 0.3, w + 0.8))
	lm.gable("Roof", base + Vector3(0, 3.9, 0), w + 0.4, l, 1.7, eb, 0.3, "Stone")
	for e in [-1.0, 1.0]:
		var fb := Basis(Vector3.UP, PI * 0.5 * e)
		_sb(lm, "Dark", base + fb * Vector3(0, 2.1, l * 0.5 + 0.03), Vector3(1.0, 2.0, 0.06), fb)
		_sb(lm, "Stone", base + fb * Vector3(0, 3.2, l * 0.5 + 0.1), Vector3(1.7, 0.28, 0.22), fb)
	for k in 3:
		for sz in [-1.0, 1.0]:
			var sb := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
			_sb(lm, "Dark", base + sb * Vector3(-l * 0.3 + l * 0.3 * float(k), 2.3, w * 0.5 + 0.03),
				Vector3(0.8, 1.0, 0.06), sb)

## Upper terrace: first terrace fill at roof level, the octagonal second
## step with cornices, the axial stairs and the circular base of the
## central sanctuary with its ring of columns.
static func _terrace(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(0, (Y2T - Y2) * 0.5 + Y2 - 0.1, 0), Vector3(IX * 2.0 - 3.6, Y2T - Y2 - 0.2, IZ * 2.0 - 3.6))
	var o := PackedVector2Array([Vector2(-21, -25), Vector2(21, -25), Vector2(28, -17), Vector2(28, 17),
		Vector2(21, 25), Vector2(-21, 25), Vector2(-28, 17), Vector2(-28, -17)])
	lm.poly_prism("Stone", o, Y2T - 0.1, Y3 - 0.5)
	var o2 := PackedVector2Array()
	for p in o:
		o2.append(p * 1.025)
	lm.poly_prism("Roof", o2, Y3 - 0.5, Y3)
	# Stepped base moulding at the foot of the terrace.
	var o3 := PackedVector2Array()
	for p in o:
		o3.append(p * 1.05)
	lm.poly_prism("Roof", o3, Y2T - 0.1, Y2T + 0.5)
	# Axial stairs from the first level onto the terrace.
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var dd := 28.0 if side % 2 == 1 else 25.0
		U.stair(lm, "Stone", b * Vector3(0, Y2T, dd + 0.5), b, 7.0, 5, 0.6, (Y3 - Y2T) / 5.0)
	# Circular base, three steps, and the ring of sixteen columns.
	for k in 3:
		var kf := float(k)
		lm.frustum("Stone", Vector3(0, Y3 + 0.5 * kf, 0), 17.0 - 1.1 * kf, 16.5 - 1.1 * kf, 0.5, 32)
	var cols: Array[Vector3] = []
	for i in 16:
		var a := TAU * float(i) / 16.0
		var p := Vector3(cos(a) * 14.6, Y3 + 1.5, sin(a) * 14.6)
		cols.append(p)
		_sb(lm, "Stone", p + Vector3(0, 2.0, 0), Vector3(0.7, 4.0, 0.7), Basis(Vector3.UP, -a))
		_sb(lm, "Roof", p + Vector3(0, 4.1, 0), Vector3(1.1, 0.35, 1.1), Basis(Vector3.UP, -a))
	for i in 16:
		lm.beam("Roof", cols[i] + Vector3(0, 4.45, 0), cols[(i + 1) % 16] + Vector3(0, 4.45, 0), 0.7, 0.5)

## The central sanctuary: the 43 m round tower of ringed storeys (drum,
## carved relief band, sixteen ribs, eight doorways), the eight radial
## porches linking it to the ring of terrace towers, and the lotus crown.
static func _central(lm: LandmarkMesh) -> void:
	var base := Vector3(0, Y3 + 1.5, 0)
	var prof := PackedVector2Array([Vector2(12.2, 0), Vector2(12.2, 2.0), Vector2(11.2, 2.4),
		Vector2(11.2, 8.0), Vector2(11.9, 8.4), Vector2(11.9, 9.6), Vector2(10.3, 10.0),
		Vector2(10.3, 15.0), Vector2(10.9, 15.4), Vector2(10.9, 16.4), Vector2(9.0, 16.9),
		Vector2(8.8, 19.6), Vector2(9.2, 20.0), Vector2(7.6, 21.2)])
	lm.lathe("Stone", base, prof, 28)
	lm.frustum("Relief", base + Vector3(0, 3.6, 0), 11.26, 11.26, 1.8, 28)
	lm.frustum("Relief", base + Vector3(0, 11.0, 0), 10.36, 10.36, 1.6, 28)
	for i in 16:
		var a := TAU * float(i) / 16.0
		var rb := Basis(Vector3.UP, -a)
		_sb(lm, "Face", base + Vector3(cos(a) * 11.2, 5.2, sin(a) * 11.2), Vector3(0.5, 5.6, 0.5), rb)
		_sb(lm, "Face", base + Vector3(cos(a) * 10.3, 12.5, sin(a) * 10.3), Vector3(0.45, 4.6, 0.45), rb)
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0
		var rb := Basis(Vector3.UP, PI * 0.5 - a)
		_sb(lm, "Dark", base + Vector3(cos(a) * 11.25, 5.0, sin(a) * 11.25), Vector3(2.6, 3.6, 0.2), rb)
		_sb(lm, "Dark", base + Vector3(cos(a) * 10.35, 12.3, sin(a) * 10.35), Vector3(2.0, 3.0, 0.2), rb)
	# Lotus crown to 43 m.
	U.lotus_bud(lm, "Stone", base + Vector3(0, 21.2, 0), 7.6, 43.0 - (base.y + 21.2), 16)
	# Radial porches: eight low gabled arms from the drum to the towers.
	for i in 8:
		var a := TAU * float(i) / 8.0
		var pb := Basis(Vector3.UP, PI * 0.5 - a)
		var pc := Vector3(cos(a) * 15.6, Y3, sin(a) * 15.6)
		lm.box("Stone", pc + Vector3(0, 1.8, 0), Vector3(5.0, 3.6, 7.0), pb)
		_sb(lm, "Dark", pc + pb * Vector3(0, 1.4, 3.52), Vector3(1.8, 2.5, 0.06), pb)
		lm.gable("Roof", pc + Vector3(0, 3.6, 0), 5.0, 7.0, 1.6, pb, 0.3, "Stone")

## All 49 face towers: 1 central (above), 12 on the terrace, 16 on the
## inner gallery, 20 on the outer gallery.
static func _towers(lm: LandmarkMesh) -> void:
	# Terrace: eight at the ends of the radial porches, four on the corners.
	for i in 8:
		var a := TAU * float(i) / 8.0
		var r := 19.4
		var hh := 16.2 if i % 2 == 0 else 15.2
		face_tower(lm, Vector3(cos(a) * r, Y3, sin(a) * r), 4.8, hh, 2 if i % 2 == 0 else 1)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			face_tower(lm, Vector3(sx * 24.0, Y3, sz * 11.0), 4.2, 14.0, 1)
	# Inner gallery (base at the roof level): corners, gopuras, flanking.
	var ib := Y2T + 0.5
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_pavilion(lm, Vector3(sx * (IX - 4.0), Y2 + IWALL, sz * (IZ - 4.0)), 3.4, 2.6)
			face_tower(lm, Vector3(sx * (IX - 4.0), ib + 2.2, sz * (IZ - 4.0)), 4.4, 13.0, 0)
	for k in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		var dd := IX if k % 2 == 1 else IZ
		var lat := IZ if k % 2 == 1 else IX
		face_tower(lm, b * Vector3(0, ib + 3.2, dd - 4.2), 5.4, 14.5, 1)
		for s in [-1.0, 1.0]:
			var p := b * Vector3(s * (lat * 0.5 - 2.0), 0, dd - 2.2)
			face_tower(lm, Vector3(p.x, ib, p.z), 4.0, 12.5, 0)
	# Outer gallery: corners, cardinal gopuras, long-side pavilions.
	var ob := G + OWALL
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_pavilion(lm, Vector3(sx * (OX - 4.4), ob, sz * (OZ - 4.4)), 3.0, 2.4)
			face_tower(lm, Vector3(sx * (OX - 4.4), ob + 2.4, sz * (OZ - 4.4)), 4.0, 10.0, 0)
	for k in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		var dd := OX if k % 2 == 1 else OZ
		face_tower(lm, b * Vector3(0, ob + 2.5, dd - 5.0), 5.0, 10.2, 1)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_pavilion(lm, Vector3(sx * 46.0, ob, sz * (OZ - 4.4)), 2.8, 2.2)
			face_tower(lm, Vector3(sx * 46.0, ob + 2.2, sz * (OZ - 4.4)), 3.8, 9.6, 0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			for zz in [17.0, 41.0]:
				_pavilion(lm, Vector3(sx * (OX - 4.4), ob, sz * zz), 2.8, 2.2)
				face_tower(lm, Vector3(sx * (OX - 4.4), ob + 2.2, sz * zz), 3.8, 9.6, 0)

## Four-faced tower of total height h and width w at `base`: moulded
## plinth (with sculpted doorways from detail 1), the redented face block
## with the serene face on every side (detail 0: brow, eyes, nose, lips;
## 1: + diadem, mouth, cheek slab; 2: + lidded eyes, earlobes, cheeks,
## chin, nostrils, jewel pendants), the stepped headdress with corner
## spires and the lotus-bud top. `sides` is a bit mask of the faces that
## survive (broken faces leave bare stone).
static func face_tower(lm: LandmarkMesh, base: Vector3, w: float, h: float, detail: int,
		sides: int = 15) -> void:
	var plinth := h * 0.3
	var face_h := h * 0.3
	var hat_h := h - plinth - face_h
	_sb(lm, "Stone", base + Vector3(0, plinth * 0.4, 0), Vector3(w * 1.12, plinth * 0.8, w * 1.12))
	_sb(lm, "Roof", base + Vector3(0, plinth * 0.9, 0), Vector3(w * 1.2, plinth * 0.2, w * 1.2))
	if detail >= 2:
		_sb(lm, "Stone", base + Vector3(0, plinth * 0.08, 0), Vector3(w * 1.22, plinth * 0.16, w * 1.22))
	var fy := plinth
	_sb(lm, "Face", base + Vector3(0, fy + face_h * 0.5, 0), Vector3(w * 0.96, face_h, w * 0.96))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		if detail >= 1:
			_sb(lm, "Dark", base + b * Vector3(0, plinth * 0.42, w * 0.565), Vector3(w * 0.3, plinth * 0.55, 0.06), b)
		if (sides & (1 << side)) != 0:
			_face(lm, base, b, w, fy, face_h, detail)
		lm.spire("Face", base + b * Vector3(0, fy + face_h, w * 0.4), w * 0.08, hat_h * 0.2, 0.0)
	var hy := fy + face_h
	var steps := 3 if detail >= 1 else 2
	for q in steps:
		var sw := w * (1.08 - 0.15 * float(q))
		_sb(lm, "Roof", base + Vector3(0, hy + hat_h * (0.04 + 0.07 * float(q)), 0),
			Vector3(sw, hat_h * 0.07, sw))
	var lh := hat_h * 0.79
	var lr := w * 0.4
	lm.lathe("Face", base + Vector3(0, hy + hat_h * 0.21, 0), PackedVector2Array([Vector2(lr * 0.9, 0),
		Vector2(lr, lh * 0.06), Vector2(lr * 0.8, lh * 0.16), Vector2(lr * 0.95, lh * 0.3),
		Vector2(lr * 0.62, lh * 0.5), Vector2(lr * 0.5, lh * 0.74), Vector2(lr * 0.2, lh * 0.92),
		Vector2(0, lh)]), 8)

## The serene face on the side of basis `b`, on a face block of width w.
static func _face(lm: LandmarkMesh, base: Vector3, b: Basis, w: float, fy: float, fh: float,
		detail: int) -> void:
	var z := w * 0.48
	var fp := func(x: float, yy: float, dz: float) -> Vector3:
		return base + b * Vector3(x, fy + fh * yy, z + dz)
	if detail >= 1:
		_sb(lm, "Stone", fp.call(0.0, 0.5, w * 0.03), Vector3(w * 0.84, fh * 0.96, w * 0.06), b)
		_sb(lm, "Roof", fp.call(0.0, 0.86, w * 0.07), Vector3(w * 0.82, fh * 0.07, w * 0.05), b)
		_sb(lm, "Dark", fp.call(0.0, 0.255, w * 0.06), Vector3(w * 0.28, fh * 0.025, w * 0.04), b)
	_sb(lm, "Roof", fp.call(0.0, 0.68, w * 0.07), Vector3(w * 0.66, fh * 0.05, w * 0.05), b)
	_sb(lm, "Face", fp.call(0.0, 0.45, w * 0.1), Vector3(w * 0.1, fh * 0.3, w * 0.1), b)
	_sb(lm, "Face", fp.call(0.0, 0.25, w * 0.08), Vector3(w * 0.3, fh * 0.12, w * 0.07), b)
	for sx in [-1.0, 1.0]:
		_sb(lm, "Dark", fp.call(sx * w * 0.17, 0.6, w * 0.065), Vector3(w * 0.15, fh * 0.04, w * 0.03), b)
		if detail >= 2:
			_sb(lm, "Face", fp.call(sx * w * 0.17, 0.64, w * 0.08), Vector3(w * 0.19, fh * 0.03, w * 0.05), b)
			_sb(lm, "Face", fp.call(sx * w * 0.43, 0.45, w * 0.03), Vector3(w * 0.07, fh * 0.42, w * 0.06), b)
			_sb(lm, "Face", fp.call(sx * w * 0.22, 0.38, w * 0.06), Vector3(w * 0.14, fh * 0.16, w * 0.04), b)
			_sb(lm, "Dark", fp.call(sx * w * 0.05, 0.38, w * 0.13), Vector3(w * 0.03, fh * 0.03, w * 0.03), b)
	if detail >= 2:
		_sb(lm, "Face", fp.call(0.0, 0.1, w * 0.06), Vector3(w * 0.2, fh * 0.09, w * 0.06), b)
		for j in 5:
			_sb(lm, "Face", fp.call((float(j) - 2.0) * w * 0.15, 0.8, w * 0.085),
				Vector3(w * 0.06, fh * 0.06, w * 0.04), b)

## Weathering: moss patches on the cornices and ledges, and fallen blocks
## at the foot of the galleries and the corners of the platform.
static func _moss_and_rubble(lm: LandmarkMesh) -> void:
	for i in 40:
		var u := _hash(i * 3 + 1)
		var v := _hash(i * 3 + 2)
		var on_outer := i % 3 != 0
		var p := Vector3((u * 2.0 - 1.0) * (OX - 2.0), G + OWALL + 0.5, 0)
		p.z = (OZ - 2.5) * (1.0 if v > 0.5 else -1.0)
		if not on_outer:
			p = Vector3((u * 2.0 - 1.0) * (IX - 3.0), Y2 + IWALL + 1.05, (IZ - 2.5) * (1.0 if v > 0.5 else -1.0))
		_sb(lm, "Moss", p, Vector3(0.9 + u * 1.6, 0.12, 0.6 + v * 1.1), Basis(Vector3.UP, u * 3.0))
	for i in 40:
		var u := _hash(i * 5 + 11)
		var v := _hash(i * 5 + 12)
		var side_x := i % 2 == 0
		var p := Vector3(0, G, 0)
		if side_x:
			p = Vector3((OX + 4.0 if u > 0.5 else -OX - 4.0), G, (v * 2.0 - 1.0) * OZ)
		else:
			p = Vector3((v * 2.0 - 1.0) * OX, G, (OZ + 4.0 if u > 0.5 else -OZ - 4.0))
		var s := 0.5 + _hash(i * 7) * 0.9
		_sb(lm, "Stone", p + Vector3(0, s * 0.4, 0), Vector3(s * 1.3, s * 0.8, s),
			Basis(Vector3.UP, u * 6.0) * Basis(Vector3.RIGHT, v * 0.4))
