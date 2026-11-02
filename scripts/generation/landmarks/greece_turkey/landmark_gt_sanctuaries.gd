class_name LandmarkGtSanctuaries
extends RefCounted

## Greek sanctuaries in true metres, all fronts to the east (+X): the
## Temple of Poseidon on Cape Sounion and the Delphic sanctuary of
## Apollo (the Olympia ruins are LandmarkGtOlympia). y = 0 is the ground
## at the foot of the lowest terrace; nothing is sunk below it.

# --- Sounion ---------------------------------------------------------------

const SOUNION_Y := 1.2
const SOUNION_COLS := 6.1
const SOUNION_X := 14.9
const SOUNION_Z := 6.1

## Temple of Poseidon on its headland (444-440 BC), origin at the temple
## centre: the 6 x 13 Doric peristyle on a 31.1 x 13.4 m stylobate, three
## steps of 0.4 m, slender marble columns 6.1 m high and 1.0 m across with
## only 16 flutes. The 15 columns that still stand (the long run of the
## south flank, the east end of the north flank, two at the east front
## and one at the west), the architraves still bridging them, the
## fluted lowest drums of the fallen ones, the cella and pronaos
## footings with the anta ends, toppled drums, the levelled rock of the
## temenos and the footings of its propylon and stoa.
static func sounion(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E8E1D2", 2.5))
	lm.use("Block", LandmarkMaterials.pbr("stone", "#B7AA90", 3.0))
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#8C7F6B", 5.0))
	_sounion_ground(lm)
	LandmarkGtUtil.steps(lm, "Marble", Vector2.ZERO, Vector2(31.1, 13.4), SOUNION_Y, 3, 0.4, 0.6)
	var dx := SOUNION_X * 2.0 / 12.0
	var dz := SOUNION_Z * 2.0 / 5.0
	for i in 13:
		for s in [-1.0, 1.0]:
			var standing: bool = (s > 0.0 and i >= 6) or (s < 0.0 and i >= 8)
			_sounion_column(lm, Vector3(-SOUNION_X + dx * float(i), SOUNION_Y, s * SOUNION_Z), standing, i * 2 + int(s))
	for j in range(1, 5):
		for s in [-1.0, 1.0]:
			var standing2: bool = (s > 0.0 and j <= 2) or (s < 0.0 and j == 3)
			_sounion_column(lm, Vector3(s * SOUNION_X, SOUNION_Y, -SOUNION_Z + dz * float(j)), standing2, 40 + j * 2 + int(s))
	# Architraves still bridging the standing runs of both flanks and the
	# east front corner.
	var ay := SOUNION_Y + SOUNION_COLS
	_architrave(lm, Vector3(-SOUNION_X + dx * 6.0, ay, SOUNION_Z), Vector3(SOUNION_X, ay, SOUNION_Z), Vector3.BACK, 6)
	_architrave(lm, Vector3(-SOUNION_X + dx * 8.0, ay, -SOUNION_Z), Vector3(SOUNION_X, ay, -SOUNION_Z), Vector3.FORWARD, 4)
	_architrave(lm, Vector3(SOUNION_X, ay, SOUNION_Z), Vector3(SOUNION_X, ay, SOUNION_Z - dz * 2.0), Vector3.RIGHT, 2)
	# Cella footing (in courses), the pronaos antae and its two column
	# stumps, the opisthodomos cross wall.
	for w in [[-9.4, 10.4, -3.4, -2.4], [-9.4, 10.4, 2.4, 3.4], [-9.4, -8.4, -3.4, 3.4], [3.6, 4.5, -2.4, 2.4]]:
		LandmarkGtUtil.courses(lm, "Block", w[0], w[1], SOUNION_Y, SOUNION_Y + 1.4, w[2], w[3], 3, 1.6)
	for s in [-1.0, 1.0]:
		LandmarkGtUtil.block(lm, "Marble", 9.6, 10.6, SOUNION_Y, SOUNION_Y + 2.3, s * 3.4 - 0.5, s * 3.4 + 0.5)
		LandmarkGtUtil.block(lm, "Marble", 9.45, 10.75, SOUNION_Y + 2.3, SOUNION_Y + 2.55, s * 3.4 - 0.62, s * 3.4 + 0.62)
		LandmarkGtUtil.fluted(lm, "Marble", Vector3(10.1, SOUNION_Y, s * 1.2), Vector3(10.1, SOUNION_Y + 0.7, s * 1.2),
			0.45, 0.45, 16)
	# Toppled drums and a fallen capital on the platform.
	for k in 5:
		var c := Vector3(-7.0 + 3.4 * float(k), SOUNION_Y + 0.48, 4.6 + 0.6 * LandmarkGtUtil.hash01(k, 3))
		var ax := Vector3(cos(0.5 * float(k)), 0, sin(0.5 * float(k)))
		LandmarkGtUtil.fluted(lm, "Marble", c - ax * 0.55, c + ax * 0.55, 0.48, 0.47, 16)
	LandmarkGtUtil.block(lm, "Marble", -4.2, -3.0, SOUNION_Y, SOUNION_Y + 0.3, -5.0, -3.8)
	lm.lathe("Marble", Vector3(-3.6, SOUNION_Y + 0.3, -4.4), PackedVector2Array([Vector2(0.55, 0),
		Vector2(0.48, 0.2), Vector2(0.4, 0.3)]), 16)
	lm.commit(model)

## One peristyle column: the full Doric column (16 flutes) where it
## still stands, otherwise its lowest fluted drum at a scattered height.
static func _sounion_column(lm: LandmarkMesh, base: Vector3, standing: bool, salt: int) -> void:
	if standing:
		LandmarkGtUtil.doric_column(lm, "Marble", base, 0.5, SOUNION_COLS, 16)
	else:
		LandmarkGtUtil.fluted(lm, "Marble", base, base + Vector3(0, 0.25 + 0.6 * LandmarkGtUtil.hash01(salt, 17), 0),
			0.5, 0.5, 16)

## Plain Doric architrave a..b at soffit level (column axes), 1.0 m
## tall, with the taenia along its top and a regula (six guttae) under
## each of the `n` + 1 triglyph positions on the face `out`.
static func _architrave(lm: LandmarkMesh, a: Vector3, b: Vector3, out: Vector3, n: int) -> void:
	var dir := (b - a).normalized()
	var bas := Basis(dir, Vector3.UP, out)
	var run := a.distance_to(b) + 1.0
	lm.box("Marble", (a + b) * 0.5 + Vector3(0, 0.45, 0), Vector3(run, 0.9, 1.0), bas)
	lm.box("Marble", (a + b) * 0.5 + Vector3(0, 0.95, 0) + out * 0.03, Vector3(run, 0.1, 1.08), bas, 0.0)
	for i in n * 2 + 1:
		var p := a.lerp(b, float(i) / float(n * 2)) + out * 0.53
		lm.box("Marble", p + Vector3(0, 0.86, 0), Vector3(0.5, 0.06, 0.06), bas, 0.0)
		for g in 6:
			lm.frustum("Marble", p + dir * (-0.21 + 0.084 * float(g)) + Vector3(0, 0.78, 0), 0.025, 0.03, 0.06, 6)

## The temenos on the headland: a levelled rock floor round the temple,
## outcrops of the cliff edge, the footings of the propylon on the north
## and of the stoa beside it.
static func _sounion_ground(lm: LandmarkMesh) -> void:
	lm.poly_prism("Rock", PackedVector2Array([Vector2(-23, -11.5), Vector2(23, -11.5), Vector2(26, 0),
		Vector2(23, 11.5), Vector2(-23, 11.5), Vector2(-26, 0)]), 0.0, 0.05)
	for k in 9:
		var a := TAU * float(k) / 9.0 + 0.3
		var c := Vector3(cos(a) * 24.0, 0, sin(a) * 12.5)
		var r := 1.4 + 1.2 * LandmarkGtUtil.hash01(k, 41)
		lm.lathe("Rock", c, PackedVector2Array([Vector2(r, 0), Vector2(r * 0.85, r * 0.35),
			Vector2(r * 0.45, r * 0.6), Vector2(0, r * 0.68)]), 7, 1.3, 0.9, a, false)
	for w in [[-6.0, 2.0, -21.0, -19.0], [-6.0, -4.6, -25.0, -19.0], [0.6, 2.0, -25.0, -19.0],
			[-22.0, -6.0, -24.0, -22.6], [-22.0, -6.0, -20.0, -19.2]]:
		LandmarkGtUtil.courses(lm, "Block", w[0], w[1], 0.0, 0.9, w[2], w[3], 2, 1.4)
	for k in 7:
		lm.frustum("Block", Vector3(-20.5 + 2.3 * float(k), 0.9, -21.3), 0.32, 0.32, 0.4, 10)

# --- Delphi ----------------------------------------------------------------

const DELPHI_TERRACE := 1.2
const DELPHI_Y := 2.7
const APOLLO_H := 10.6
const APOLLO_R := 0.84
const APOLLO_X := 28.1
const APOLLO_Z := 9.8

## Sanctuary of Apollo, origin at the Temple of Apollo (4th century BC,
## 6 x 15 Doric, stylobate 58.2 x 21.6 m on three steps of grey
## limestone): its terrace held by the polygonal wall along the Sacred
## Way, the six columns re-erected 1938-41 at the south-east corner to
## differing heights, the fluted stumps of the rest, the cella and
## adyton foundations, the ramp up to the east front and the Altar of
## the Chians (black limestone on a white base) before it; the Athenian
## Treasury (Doric distyle in antis, 6.7 x 9.7 m, restored 1906) on its
## terrace to the south; and, drawn closer than it stands, the Tholos
## of Marmaria with the three columns and entablature put up in 1938.
static func delphi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E6DFCE", 2.5))
	lm.use("Block", LandmarkMaterials.pbr("stone", "#B5A88F", 3.0))
	lm.use("Wall", LandmarkMaterials.pbr("cliff", "#8E8271", 4.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#5E5346", 2.5))
	lm.use("Black", LandmarkMaterials.pbr("stone", "#3B3A38", 2.5))
	# Temple terrace and its polygonal retaining wall on the south.
	lm.poly_prism("Wall", PackedVector2Array([Vector2(-36, -16), Vector2(36, -16), Vector2(42, 0),
		Vector2(36, 17), Vector2(-36, 17), Vector2(-40, 0)]), 0.0, DELPHI_TERRACE)
	_polygonal(lm, Vector3(-36.0, 0, 17.0), Vector3(36.0, 0, 17.0), DELPHI_TERRACE, 9)
	LandmarkGtUtil.steps(lm, "Block", Vector2.ZERO, Vector2(58.2, 21.6), DELPHI_Y, 3, 0.5, 0.45)
	var dx := APOLLO_X * 2.0 / 14.0
	var dz := APOLLO_Z * 2.0 / 5.0
	# Re-erected south-east columns: four on the flank, two on the front,
	# each built up to a different drum.
	var tall := {11: 5.0, 12: 6.6, 13: 5.8, 14: 6.2}
	for i in 15:
		for s in [-1.0, 1.0]:
			var p := Vector3(-APOLLO_X + dx * float(i), DELPHI_Y, s * APOLLO_Z)
			var up: float = tall[i] if (s > 0.0 and tall.has(i)) else 0.25 + 0.5 * LandmarkGtUtil.hash01(i * 3 + int(s), 5)
			LandmarkGtUtil.doric_column(lm, "Marble", p, APOLLO_R, APOLLO_H, 20, up)
	for j in range(1, 5):
		for s in [-1.0, 1.0]:
			var up2 := 4.1 if (s > 0.0 and j == 4) else (3.0 if (s > 0.0 and j == 3) else 0.3)
			LandmarkGtUtil.doric_column(lm, "Marble", Vector3(s * APOLLO_X, DELPHI_Y, -APOLLO_Z + dz * float(j)),
				APOLLO_R, APOLLO_H, 20, up2)
	# Cella and adyton foundations, in courses.
	for w in [[-23.0, 17.0, -6.1, -4.7], [-23.0, 17.0, 4.7, 6.1], [-23.7, -22.3, -4.7, 4.7], [12.3, 13.7, -4.7, 4.7],
			[-14.6, -13.4, -4.7, 4.7]]:
		LandmarkGtUtil.courses(lm, "Block", w[0], w[1], DELPHI_Y, DELPHI_Y + 1.0, w[2], w[3], 2, 1.8)
	# Ramp up to the east front.
	_ramp(lm, "Block", Vector3(APOLLO_X + 1.4, DELPHI_TERRACE, 0), Vector3(APOLLO_X + 8.0, DELPHI_TERRACE, 0),
		DELPHI_Y - DELPHI_TERRACE, 5.0)
	_chians_altar(lm, Vector3(APOLLO_X + 8.0, DELPHI_TERRACE, 9.0))
	_treasury(lm, Vector3(39.0, 0, 35.0))
	_tholos(lm, Vector3(76.0, 0, 62.0))
	lm.commit(model)

## Polygonal masonry face along a..b (ground level), facing away from
## the terrace (+Z here), h tall: interlocking many-sided blocks, each a
## low prism standing a little proud of the core, drawn from a jittered
## lattice (`salt` varies it).
static func _polygonal(lm: LandmarkMesh, a: Vector3, b: Vector3, h: float, salt: int) -> void:
	var dir := (b - a).normalized()
	var out := dir.cross(Vector3.UP).normalized()
	var run := a.distance_to(b)
	var nx := int(run / 1.3)
	var ny := maxi(int(h / 0.6), 1)
	var pts: Array = []
	for j in ny + 1:
		var row: Array = []
		for i in nx + 1:
			var jx := 0.0 if (i == 0 or i == nx) else (LandmarkGtUtil.hash01(i * 13 + j, salt) - 0.5) * 0.7
			var jy := 0.0 if (j == 0 or j == ny) else (LandmarkGtUtil.hash01(i * 7 + j * 31, salt + 3) - 0.5) * 0.3
			row.append(Vector2(run * float(i) / float(nx) + jx, h * float(j) / float(ny) + jy))
		pts.append(row)
	for j in ny:
		for i in nx:
			var q: Array = [pts[j][i], pts[j][i + 1], pts[j + 1][i + 1], pts[j + 1][i]]
			var c := Vector2.ZERO
			for v in q:
				c += v as Vector2
			c /= 4.0
			var proud := 0.08 + 0.06 * LandmarkGtUtil.hash01(i * 3 + j, salt + 9)
			var front: Array = []
			var back: Array = []
			for v in q:
				var vv: Vector2 = c + ((v as Vector2) - c) * 0.96
				back.append(a + dir * vv.x + Vector3(0, vv.y, 0))
				front.append(a + dir * vv.x + Vector3(0, vv.y, 0) + out * proud)
			lm.quad("Wall", front[0], front[1], front[2], front[3], out)
			for k in 4:
				var e0: Vector3 = front[k]
				var e1: Vector3 = front[(k + 1) % 4]
				var mid := (e0 + e1) * 0.5 - (a + dir * c.x + Vector3(0, c.y, 0) + out * proud)
				lm.quad("Wall", back[k], back[(k + 1) % 4], e1, e0, (mid - out * mid.dot(out)).normalized())

## Straight ramp rising `rise` from its foot (on the ground) to the
## platform edge above `top` (both on its axis), `w` wide, with its two
## sloping sides and the face against the platform.
static func _ramp(lm: LandmarkMesh, key: String, top: Vector3, foot: Vector3, rise: float, w: float) -> void:
	var dir := (foot - top).normalized()
	var side := dir.cross(Vector3.UP).normalized() * w * 0.5
	var t := top + Vector3(0, rise, 0)
	lm.quad(key, t - side, t + side, foot + side, foot - side, Vector3.UP)
	for s in [-1.0, 1.0]:
		var sv: Vector3 = side * float(s)
		lm.tri(key, top + sv, t + sv, foot + sv, sv, sv, sv, Vector2.ZERO, Vector2(0, -rise), Vector2(top.distance_to(foot), 0))
	lm.quad(key, top - side, top + side, t + side, t - side, -dir)

## Altar of the Chians at `c` (east face to +X): white marble base and
## crown mouldings on a black limestone body, 8.6 x 5.1 m, with the
## stair to its table on the west.
static func _chians_altar(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkGtUtil.block(lm, "Marble", c.x - 2.7, c.x + 2.7, c.y, c.y + 0.35, c.z - 4.4, c.z + 4.4)
	LandmarkGtUtil.block(lm, "Black", c.x - 2.55, c.x + 2.55, c.y + 0.35, c.y + 2.3, c.z - 4.3, c.z + 4.3)
	LandmarkGtUtil.block(lm, "Marble", c.x - 2.7, c.x + 2.7, c.y + 2.3, c.y + 2.55, c.z - 4.45, c.z + 4.45)
	LandmarkDetail.cornice(lm, "Marble", Vector3(c.x + 2.55, c.y + 2.55, c.z - 4.3), Vector3(c.x + 2.55, c.y + 2.55, c.z + 4.3),
		Vector3.RIGHT, 0.35, true)
	for k in 6:
		LandmarkGtUtil.block(lm, "Marble", c.x - 2.55 - 0.4 * float(k + 1), c.x - 2.55 - 0.4 * float(k), c.y,
			c.y + 2.3 - 0.38 * float(k), c.z - 1.6, c.z + 1.6)

## Athenian Treasury at `c` facing +Z: distyle in antis, 6.7 x 9.7 m on
## three steps; ashlar side walls, two Doric columns between the antae,
## the door, a triglyph frieze all round (30 metopes) and the pediment
## with its acroteria.
static func _treasury(lm: LandmarkMesh, c: Vector3) -> void:
	_polygonal(lm, c + Vector3(-5.5, 0, 7.0), c + Vector3(5.5, 0, 7.0), 1.1, 4)
	LandmarkGtUtil.block(lm, "Wall", c.x - 5.5, c.x + 5.5, 0.0, 1.1, c.z - 7.0, c.z + 7.0)
	var y := 1.1 + 0.6
	LandmarkGtUtil.steps(lm, "Marble", Vector2(c.x, c.z), Vector2(6.7, 9.7), y, 3, 0.2, 0.25)
	for sx in [-1.0, 1.0]:
		LandmarkGtUtil.courses(lm, "Marble", c.x + sx * 2.95 - 0.35, c.x + sx * 2.95 + 0.35, y, y + 3.9, c.z - 4.85, c.z + 4.5, 7, 1.3)
		LandmarkGtUtil.block(lm, "Marble", c.x + sx * 2.95 - 0.42, c.x + sx * 2.95 + 0.42, y + 3.6, y + 3.9, c.z + 4.0, c.z + 4.85)
		LandmarkGtUtil.doric_column(lm, "Marble", c + Vector3(sx * 1.05, y, 4.35), 0.38, 3.9, 20)
	LandmarkGtUtil.courses(lm, "Marble", c.x - 3.3, c.x + 3.3, y, y + 3.9, c.z - 4.85, c.z - 4.15, 7, 1.3)
	# Cella front wall and its door.
	LandmarkGtUtil.block(lm, "Marble", c.x - 2.6, c.x - 0.8, y, y + 3.9, c.z + 1.6, c.z + 2.2)
	LandmarkGtUtil.block(lm, "Marble", c.x + 0.8, c.x + 2.6, y, y + 3.9, c.z + 1.6, c.z + 2.2)
	LandmarkGtUtil.block(lm, "Marble", c.x - 0.8, c.x + 0.8, y + 3.0, y + 3.9, c.z + 1.6, c.z + 2.2)
	LandmarkGtUtil.block(lm, "Shadow", c.x - 0.8, c.x + 0.8, y, y + 3.0, c.z + 1.65, c.z + 1.7)
	var ey := y + 3.9
	var h := Vector3(0, ey, 0)
	LandmarkGtUtil.doric_entablature(lm, "Marble", c + h + Vector3(-2.95, 0, 4.5), c + h + Vector3(2.95, 0, 4.5),
		Vector3.BACK, 0.9, 0.55, 0.65, 0.3, 5)
	LandmarkGtUtil.doric_entablature(lm, "Marble", c + h + Vector3(2.95, 0, -4.5), c + h + Vector3(-2.95, 0, -4.5),
		Vector3.FORWARD, 0.9, 0.55, 0.65, 0.3, 5)
	for sx in [-1.0, 1.0]:
		LandmarkGtUtil.doric_entablature(lm, "Marble", c + h + Vector3(sx * 2.95, 0, -4.1), c + h + Vector3(sx * 2.95, 0, 4.1),
			Vector3(sx, 0, 0), 0.8, 0.55, 0.65, 0.3, 8)
	var py := ey + 1.5
	lm.gable("Marble", c + Vector3(0, py, 0), 6.9, 10.1, 0.95, Basis(), 0.25, "Shadow")
	for sz in [-1.0, 1.0]:
		LandmarkDetail.cornice(lm, "Marble", c + Vector3(-3.45, py, sz * 5.0), c + Vector3(3.45, py, sz * 5.0),
			Vector3(0, 0, sz), 0.22, false)
		lm.box("Marble", c + Vector3(0, py + 1.15, sz * 5.0), Vector3(0.45, 0.45, 0.2))
		for sx2 in [-1.0, 1.0]:
			lm.box("Marble", c + Vector3(sx2 * 3.35, py + 0.2, sz * 5.0), Vector3(0.3, 0.4, 0.2))

## Tholos of Marmaria at `c`: a ring of 20 Doric columns on a three-step
## base 13.5 m across; three columns (5.9 m) re-erected with a run of
## curved architrave, triglyph frieze and cornice; the others fluted
## stumps; the cella ring wall with the bench and the stubs of its
## inner Corinthian half-columns.
static func _tholos(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkGtUtil.ring_steps(lm, "Marble", c, 6.75, 0.9, 3, 0.3, 0.4, 40)
	var ring := 6.0
	var y := 0.9
	var top := y + 5.9
	for k in 20:
		var a := TAU * float(k) / 20.0
		var p := c + Vector3(cos(a) * ring, y, sin(a) * ring)
		if k in [5, 6, 7]:
			LandmarkGtUtil.doric_column(lm, "Marble", p, 0.44, 5.9, 20)
		else:
			LandmarkGtUtil.fluted(lm, "Marble", p, p + Vector3(0, 0.2 + 0.7 * LandmarkGtUtil.hash01(k, 6), 0), 0.44, 0.44, 20)
	for k in [5, 6]:
		var a0 := TAU * float(k) / 20.0
		var a1 := TAU * float(k + 1) / 20.0
		var p0 := c + Vector3(cos(a0) * ring, top, sin(a0) * ring)
		var p1 := c + Vector3(cos(a1) * ring, top, sin(a1) * ring)
		var am := (a0 + a1) * 0.5
		LandmarkGtUtil.doric_entablature(lm, "Marble", p0, p1, Vector3(cos(am), 0, sin(am)), 0.85, 0.6, 0.62, 0.3, 3)
	# Cella ring wall, its bench and the inner half-column stubs.
	lm.lathe("Block", c + Vector3(0, y, 0), PackedVector2Array([Vector2(4.2, 0), Vector2(4.2, 1.6),
		Vector2(3.6, 1.6), Vector2(3.6, 0)]), 40, 1.0, 1.0, 0.0, false, false)
	lm.lathe("Black", c + Vector3(0, y, 0), PackedVector2Array([Vector2(3.6, 0.45), Vector2(3.1, 0.45),
		Vector2(3.1, 0)]), 40, 1.0, 1.0, 0.0, false, false)
	for k in 10:
		var a2 := TAU * (float(k) + 0.5) / 10.0
		lm.frustum("Marble", c + Vector3(cos(a2) * 3.55, y + 0.45, sin(a2) * 3.55), 0.24, 0.23, 0.9, 12)
