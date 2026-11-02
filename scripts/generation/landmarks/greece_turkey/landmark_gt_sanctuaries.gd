class_name LandmarkGtSanctuaries
extends RefCounted

## Greek sanctuaries in true metres, all fronts to the east (+X): the
## Temple of Poseidon on Cape Sounion, the Delphic sanctuary of Apollo
## and the Olympia ruins of the Temples of Zeus and Hera. y = 0 is the
## ground at the foot of the krepis; foundations drop below it.

# --- Sounion ---------------------------------------------------------------

const SOUNION_Y := 1.2
const SOUNION_COLS := 6.1

## Temple of Poseidon on its headland, origin at the temple centre: the
## 6 x 13 Doric peristyle (stylobate 31.1 x 13.4 m, slender marble
## columns 6.1 m high on a three-step krepis) with the 15 columns that
## still stand, a few architraves, the cella foundations and fallen
## drums, on a levelled platform over the cliff.
static func sounion(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E8E1D2", 2.5))
	lm.use("Block", LandmarkMaterials.pbr("stone", "#B7AA90", 3.0))
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#8C7F6B", 5.0))
	# Cliff mass and levelled platform under the temple.
	lm.poly_prism("Rock", PackedVector2Array([Vector2(-23, -11.5), Vector2(23, -11.5), Vector2(26, 0),
		Vector2(23, 11.5), Vector2(-23, 11.5), Vector2(-26, 0)]), -17.0, -7.0)
	lm.poly_prism("Block", PackedVector2Array([Vector2(-19.5, -9.6), Vector2(19.5, -9.6), Vector2(21, 0),
		Vector2(19.5, 9.6), Vector2(-19.5, 9.6), Vector2(-21, 0)]), -7.0, 0.0)
	LandmarkGtUtil.steps(lm, "Marble", Vector2.ZERO, Vector2(31.1, 13.4), SOUNION_Y, 3, 0.4, 0.6)
	var dx := 29.8 / 12.0
	var dz := 12.2 / 5.0
	for i in 13:
		for s in [-1.0, 1.0]:
			var standing: bool = (s > 0.0 and i >= 6) or (s < 0.0 and i >= 8)
			_sounion_column(lm, Vector3(-14.9 + dx * float(i), SOUNION_Y, s * 6.1), standing)
	for j in range(1, 5):
		for s in [-1.0, 1.0]:
			var standing2: bool = (s > 0.0 and j <= 2) or (s < 0.0 and j == 3)
			_sounion_column(lm, Vector3(s * 14.9, SOUNION_Y, -6.1 + dz * float(j)), standing2)
	# Architraves still bridging the east end of both flanks.
	for i in range(6, 10):
		lm.box("Marble", Vector3(-14.9 + dx * (float(i) + 0.5), SOUNION_Y + SOUNION_COLS + 0.5, 6.1),
			Vector3(dx, 1.0, 1.1))
	for i in range(9, 12):
		lm.box("Marble", Vector3(-14.9 + dx * (float(i) + 0.5), SOUNION_Y + SOUNION_COLS + 0.5, -6.1),
			Vector3(dx, 1.0, 1.1))
	# Cella: foundation walls, pronaos and opisthodomos steps.
	for w in [[Vector3(0.5, 0, -2.9), Vector3(19.0, 1.4, 1.0)], [Vector3(0.5, 0, 2.9), Vector3(19.0, 1.4, 1.0)],
			[Vector3(-9.0, 0, 0), Vector3(1.0, 1.4, 6.8)], [Vector3(-2.5, 0, 0), Vector3(0.9, 1.0, 5.0)]]:
		var ws: Vector3 = w[1]
		lm.box("Block", (w[0] as Vector3) + Vector3(0, SOUNION_Y + ws.y * 0.5, 0), ws)
	# Toppled drums on the platform.
	for k in 4:
		var c := Vector3(-6.0 + 3.6 * float(k), SOUNION_Y + 0.5, 3.6 + 1.2 * LandmarkGtUtil.hash01(k, 3))
		var ax := Vector3(cos(0.5 * float(k)), 0, sin(0.5 * float(k)))
		LandmarkGtUtil.cylinder(lm, "Marble", c - ax * 0.8, c + ax * 0.8, 0.5, 0.48, 12)
	lm.commit(model)

## One peristyle column: the full Doric shaft where it still stands,
## otherwise the stump of its lowest drum.
static func _sounion_column(lm: LandmarkMesh, base: Vector3, standing: bool) -> void:
	if standing:
		LandmarkGtUtil.doric(lm, "Marble", base, SOUNION_COLS, 0.5, 0.4, 16)
	else:
		lm.frustum("Marble", base, 0.5, 0.49, 0.35, 12)

# --- Delphi ----------------------------------------------------------------

const DELPHI_Y := 1.5
const APOLLO_COLS := 7.8

## Sanctuary of Apollo, origin at the Temple of Apollo: its 22 x 60 m
## stylobate with the six re-erected Doric columns at the south-east
## corner and the cella foundations; the Athenian Treasury (Doric temple
## in antis, Pentelic marble, restored 1906) on its terrace to the south;
## and, drawn closer than it stands, the Tholos of Marmaria with the
## three columns and entablature put up in 1938.
static func delphi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E6DFCE", 2.5))
	lm.use("Block", LandmarkMaterials.pbr("stone", "#B5A88F", 3.0))
	lm.use("Wall", LandmarkMaterials.pbr("cliff", "#8E8271", 4.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#5E5346", 2.5))
	# Apollo terrace: polygonal retaining wall and the krepis.
	lm.poly_prism("Wall", PackedVector2Array([Vector2(-36, -16), Vector2(36, -16), Vector2(40, 0),
		Vector2(36, 17), Vector2(-36, 17), Vector2(-40, 0)]), -9.0, 0.0)
	LandmarkGtUtil.steps(lm, "Marble", Vector2.ZERO, Vector2(60.3, 21.7), DELPHI_Y, 3, 0.5, 0.45)
	var dx := 58.2 / 14.0
	var dz := 19.9 / 5.0
	for i in range(11, 15):
		LandmarkGtUtil.doric(lm, "Marble", Vector3(-29.1 + dx * float(i), DELPHI_Y, 9.95), APOLLO_COLS, 0.78, 0.6)
	for j in [3, 4]:
		LandmarkGtUtil.doric(lm, "Marble", Vector3(29.1, DELPHI_Y, -9.95 + dz * float(j)), APOLLO_COLS, 0.78, 0.6)
	# Cella and adyton foundations, the altar of the Chians before the front.
	for w in [[Vector3(-3.0, 0, -5.4), Vector3(40.0, 1.0, 1.4)], [Vector3(-3.0, 0, 5.4), Vector3(40.0, 1.0, 1.4)],
			[Vector3(-23.0, 0, 0), Vector3(1.4, 1.0, 11.0)], [Vector3(13.0, 0, 0), Vector3(1.4, 1.0, 11.0)],
			[Vector3(-14.0, 0, 0), Vector3(1.2, 1.0, 9.0)]]:
		var ws: Vector3 = w[1]
		lm.box("Block", (w[0] as Vector3) + Vector3(0, DELPHI_Y + ws.y * 0.5, 0), ws)
	lm.box("Shadow", Vector3(36.5, 0.8, 2.0), Vector3(4.5, 1.6, 2.4))
	_treasury(lm, Vector3(39.0, 0, 35.0))
	_tholos(lm, Vector3(76.0, 0, 62.0))
	lm.commit(model)

## Athenian Treasury at `c` facing +Z: distyle in antis, 6.6 x 9.7 m,
## triglyph frieze and a low pediment.
static func _treasury(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Wall", c + Vector3(0, -3.0, 0), Vector3(11.0, 6.0, 14.0))
	LandmarkGtUtil.steps(lm, "Marble", Vector2(c.x, c.z), Vector2(6.6, 9.7), 0.6, 3, 0.2, 0.25)
	var y := 0.6
	for sx in [-1.0, 1.0]:
		lm.box("Marble", c + Vector3(sx * 2.95, y + 1.95, 0), Vector3(0.7, 3.9, 9.7))
		lm.box("Marble", c + Vector3(sx * 2.6, y + 1.95, 4.5), Vector3(1.4, 3.9, 0.7))
		LandmarkGtUtil.doric(lm, "Marble", c + Vector3(sx * 1.05, y, 4.35), 3.7, 0.38, 0.31, 16)
	lm.box("Marble", c + Vector3(0, y + 1.95, -4.5), Vector3(6.6, 3.9, 0.7))
	lm.box("Marble", c + Vector3(0, y + 3.7 + 0.3, 0), Vector3(6.6, 0.6, 9.7))
	lm.box("Marble", c + Vector3(0, y + 4.55, 4.45), Vector3(6.8, 0.5, 0.9))
	lm.box("Marble", c + Vector3(0, y + 5.1, 4.45), Vector3(6.8, 0.6, 0.9))
	for k in 7:
		lm.box("Shadow", c + Vector3(-2.7 + 0.9 * float(k), y + 5.1, 4.95), Vector3(0.38, 0.55, 0.12))
	lm.box("Marble", c + Vector3(0, y + 5.55, 4.4), Vector3(7.0, 0.2, 1.2))
	lm.gable("Marble", c + Vector3(0, y + 5.65, 0), 6.8, 10.1, 0.9, Basis(), 0.0, "Marble")

## Tholos of Marmaria at `c`: 20-column Doric ring (13.5 m across), three
## columns standing with architrave, frieze and cornice, and the cella
## ring wall.
static func _tholos(lm: LandmarkMesh, c: Vector3) -> void:
	lm.frustum("Wall", c + Vector3(0, -7.0, 0), 8.6, 8.1, 7.0, 24)
	LandmarkGtUtil.ring_steps(lm, "Marble", c, 6.75, 0.9, 3, 0.3, 0.4, 36)
	var ring := 6.0
	var top := 0.9 + 5.9
	for k in 20:
		var a := TAU * float(k) / 20.0
		var p := c + Vector3(cos(a) * ring, 0.9, sin(a) * ring)
		if k in [5, 6, 7]:
			LandmarkGtUtil.doric(lm, "Marble", p, 5.9, 0.44, 0.34, 16)
		else:
			lm.frustum("Marble", p, 0.44, 0.43, 0.3, 12)
	for k in [5, 6]:
		var am := TAU * (float(k) + 0.5) / 20.0
		var bas := Basis(Vector3.UP, -(am + PI * 0.5))
		var m := c + Vector3(cos(am) * ring, 0, sin(am) * ring)
		lm.box("Marble", m + Vector3(0, top + 0.31, 0), Vector3(2.0, 0.62, 0.9), bas)
		lm.box("Block", m + Vector3(0, top + 0.95, 0), Vector3(2.0, 0.66, 0.85), bas)
		lm.box("Marble", m + Vector3(0, top + 1.43, 0), Vector3(2.0, 0.3, 1.1), bas)
	# Triglyphs above each standing column and mid-bay.
	for k2 in 5:
		var at := TAU * (5.0 + 0.5 * float(k2)) / 20.0
		var bt := Basis(Vector3.UP, -(at + PI * 0.5))
		lm.box("Shadow", c + Vector3(cos(at) * ring, top + 0.95, sin(at) * ring), Vector3(0.4, 0.6, 0.92), bt)
	lm.lathe("Block", c + Vector3(0, 0.9, 0), PackedVector2Array([Vector2(4.2, 0), Vector2(4.2, 2.6),
		Vector2(3.5, 2.6), Vector2(3.5, 0)]), 28, 1.0, 1.0, 0.0, false, false)

# --- Olympia ---------------------------------------------------------------

const ZEUS_Y := 1.65
const ZEUS_COLS := 10.53

## The Altis of Olympia, origin at the Temple of Zeus (stylobate 64.1 x
## 27.7 m, 6 x 13 Doric columns 10.5 m high): the krepis and cella
## foundations, the one column re-erected in the opisthodomos and the
## 13 columns of each flank lying where the earthquake dropped them,
## drum after drum; and, drawn a little nearer than they stand, the
## Heraion (6 x 16 Doric ruin with its surviving columns) and the
## round foundations of the Philippeion.
static func olympia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Poros", LandmarkMaterials.pbr("limestone", "#D5C49D", 2.5))
	lm.use("Block", LandmarkMaterials.pbr("stone", "#AA9D85", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4DDCC", 2.5))
	LandmarkGtUtil.steps(lm, "Poros", Vector2.ZERO, Vector2(64.1, 27.7), ZEUS_Y, 3, 0.55, 0.7)
	lm.box("Block", Vector3(0, -2.0, 0), Vector3(70.0, 4.0, 34.0))
	# Cella walls and the two porches as foundation courses.
	for w in [[Vector3(0, 0, -6.5), Vector3(46.0, 1.3, 1.6)], [Vector3(0, 0, 6.5), Vector3(46.0, 1.3, 1.6)],
			[Vector3(-23.0, 0, 0), Vector3(1.6, 1.3, 13.0)], [Vector3(23.0, 0, 0), Vector3(1.6, 1.3, 13.0)]]:
		var ws: Vector3 = w[1]
		lm.box("Block", (w[0] as Vector3) + Vector3(0, ZEUS_Y + ws.y * 0.5, 0), ws)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.frustum("Poros", Vector3(sx * 27.0, ZEUS_Y, sz * 2.4), 1.2, 1.15, 0.5, 14)
	LandmarkGtUtil.doric(lm, "Poros", Vector3(-27.0, ZEUS_Y, -2.4), ZEUS_COLS, 1.12, 0.85, 20)
	# Fallen flank columns: six drums and a capital per column, in rows.
	var dx := 61.3 / 12.0
	for i in 13:
		for s in [-1.0, 1.0]:
			if s < 0.0 and i % 3 == 1:
				continue
			var x := -30.65 + dx * float(i) + 0.5 * (LandmarkGtUtil.hash01(i, 5) - 0.5)
			var z: float = s * 16.2
			for k in 6:
				var r0 := lerpf(1.12, 0.9, float(k) / 6.0)
				var z0: float = z + s * (1.65 * float(k) + 0.25 * LandmarkGtUtil.hash01(i * 7 + k, 9))
				LandmarkGtUtil.cylinder(lm, "Poros", Vector3(x, r0, z0), Vector3(x, r0, z0 + s * 1.5),
					r0, r0 - 0.04, 10)
			LandmarkGtUtil.cylinder(lm, "Poros", Vector3(x, 1.5, z + s * 10.4), Vector3(x, 1.5, z + s * 11.1),
				1.5, 1.2, 10)
	_heraion(lm, Vector3(-22.0, 0, -100.0))
	_philippeion(lm, Vector3(-3.0, 0, -77.0))
	lm.commit(model)

## Heraion at `c`: archaic Doric temple 50 x 18.75 m, 6 x 16 columns;
## five tall columns stand on the south flank, the rest are stumps of
## every height. The "Block" key carries the platform.
static func _heraion(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkGtUtil.steps(lm, "Block", Vector2(c.x, c.z), Vector2(50.0, 18.75), 0.6, 2, 0.3, 0.4)
	lm.box("Block", c + Vector3(0, -1.5, 0), Vector3(54.0, 3.0, 23.0))
	var dx := 48.4 / 15.0
	var dz := 17.15 / 5.0
	for i in 16:
		for s in [-1.0, 1.0]:
			var p := c + Vector3(-24.2 + dx * float(i), 0.6, s * 8.57)
			if s > 0.0 and i >= 6 and i <= 10:
				LandmarkGtUtil.doric(lm, "Poros", p, 5.2, 0.52, 0.42, 16)
			else:
				lm.frustum("Poros", p, 0.52, 0.5, 0.3 + 1.1 * LandmarkGtUtil.hash01(i, 21 + int(s)), 14)
	for j in range(1, 5):
		for s in [-1.0, 1.0]:
			lm.frustum("Poros", c + Vector3(s * 24.2, 0.6, -8.57 + dz * float(j)), 0.52, 0.5,
				0.3 + 0.9 * LandmarkGtUtil.hash01(j, 33 + int(s)), 14)
	for w in [[Vector3(0, 0, -3.0), Vector3(38.0, 0.9, 1.0)], [Vector3(0, 0, 3.0), Vector3(38.0, 0.9, 1.0)]]:
		var ws: Vector3 = w[1]
		lm.box("Block", c + (w[0] as Vector3) + Vector3(0, 0.6 + ws.y * 0.5, 0), ws)

## Philippeion at `c`: the circular Ionic shrine of Philip II, 15 m
## across; only the stepped foundation, the stubs of its 18 columns
## and the cella wall footing survive.
static func _philippeion(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkGtUtil.ring_steps(lm, "Marble", c, 7.1, 0.7, 3, 0.25, 0.3, 36)
	for k in 18:
		var a := TAU * float(k) / 18.0
		lm.frustum("Marble", c + Vector3(cos(a) * 6.3, 0.7, sin(a) * 6.3), 0.45, 0.4,
			0.25 + 0.5 * LandmarkGtUtil.hash01(k, 2), 12)
	lm.lathe("Block", c + Vector3(0, 0.7, 0), PackedVector2Array([Vector2(4.4, 0), Vector2(4.4, 0.8),
		Vector2(3.8, 0.8), Vector2(3.8, 0)]), 28, 1.0, 1.0, 0.0, false, false)
