class_name LandmarkSaoAustralia
extends RefCounted

## Melbourne's Flinders Street Station in true metres (Parliament House,
## Canberra, is in LandmarkSaoCanberra).

# --- Flinders Street Station ---

## Front line along Flinders Street; the model faces -Z (north) with
## Swanston Street at +X and Elizabeth Street at -X.
const FACADE_Z := -10.0
const BACK_Z := 10.0
const EAVE_Y := 17.0
const STOREY := 5.6
const WEST_X := -100.0
const DOME_X0 := 76.0
const DOME_X1 := 102.0
## [x0, x1] of the two arched pavilions breaking the long front.
const PAVILIONS := [[-44.0, -32.0], [22.0, 34.0]]
const TOWER_X0 := -100.0
const TOWER_X1 := -88.0

## The Edwardian terminus (1905-10) by Fawcett and Ashworth: red brick
## and render repainted in 2017 to its 1910 stone and red scheme, the
## 200 m front on Flinders Street with an arcade of shop arches, two
## storeys of windows over it and two pavilions with curved gables; the
## domed main entrance at the Swanston Street corner with its great arch
## over the row of indicator clocks; the clock tower at the Elizabeth
## Street end; the platform canopies behind.
static func flinders(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D6BF8F", 4.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E8DCC0", 3.0))
	lm.use("Red", LandmarkMaterials.pbr("brick", "#8E3B2C", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#5E8D78", 3.0, 0.5, 0.2))
	lm.use("Iron", LandmarkMaterials.paint("#6B6E6C", 0.55, 0.4))
	lm.use("Windows", LandmarkMaterials.glass("#22292C"))
	lm.use("Clock", LandmarkMaterials.lit("#F4F0E0", 0.3))
	var wings := [[TOWER_X1, float(PAVILIONS[0][0])], [float(PAVILIONS[0][1]), float(PAVILIONS[1][0])],
		[float(PAVILIONS[1][1]), DOME_X0]]
	for w in wings:
		_wing(lm, float(w[0]), float(w[1]))
	for p in PAVILIONS:
		_pavilion(lm, float(p[0]), float(p[1]))
	_clock_tower(lm)
	_dome_block(lm)
	_canopies(lm)
	lm.commit(model)

## One wing of the front: mass, granite plinth, arcade of shop arches,
## two pierced storeys of windows, red bands, cornice, parapet and the
## hipped iron roof.
static func _wing(lm: LandmarkMesh, x0: float, x1: float) -> void:
	var w := x1 - x0
	var cx := (x0 + x1) * 0.5
	var d := BACK_Z - FACADE_Z
	var cz := (FACADE_Z + BACK_Z) * 0.5
	lm.box("Wall", Vector3(cx, EAVE_Y * 0.5, cz), Vector3(w, EAVE_Y, d), Basis(), 0.0)
	lm.box("Trim", Vector3(cx, 0.4, FACADE_Z - 0.2), Vector3(w, 0.8, 0.5))
	var bays := maxi(int(w / 4.8), 1)
	var pitch := w / float(bays)
	for k in bays + 1:
		var x := x0 + pitch * float(k)
		lm.box("Red", Vector3(x, STOREY * 0.5, FACADE_Z - 0.3), Vector3(1.0, STOREY, 0.6))
	for k in bays:
		var x := x0 + pitch * (float(k) + 0.5)
		lm.quad("Windows", Vector3(x - pitch * 0.5 + 0.5, 0.8, FACADE_Z - 0.02), Vector3(x + pitch * 0.5 - 0.5, 0.8, FACADE_Z - 0.02),
			Vector3(x + pitch * 0.5 - 0.5, 4.6, FACADE_Z - 0.02), Vector3(x - pitch * 0.5 + 0.5, 4.6, FACADE_Z - 0.02), Vector3.FORWARD)
		LandmarkDetail.arch(lm, "Trim", Vector3(x, 3.4, FACADE_Z - 0.05), Vector3.FORWARD, pitch - 1.0, 0.45, 0.35)
	LandmarkDetail.pierced_face(lm, "Wall", "Windows", Vector3(x0, STOREY, FACADE_Z), Vector3.RIGHT, Vector3.FORWARD,
		w, EAVE_Y - STOREY, bays, 2, Vector2(1.7, 3.2), 1.2, STOREY, 0.35)
	# Red string courses and window heads, the cornice and the parapet.
	for y in [STOREY, STOREY * 2.0]:
		lm.box("Red", Vector3(cx, float(y) + 0.2, FACADE_Z - 0.45), Vector3(w, 0.4, 0.3), Basis(), 0.0)
	for k in bays:
		var x := x0 + pitch * (float(k) + 0.5)
		for j in 2:
			lm.box("Red", Vector3(x, STOREY + 4.6 + STOREY * float(j), FACADE_Z - 0.5), Vector3(2.4, 0.5, 0.3))
	LandmarkDetail.cornice(lm, "Trim", Vector3(x0, EAVE_Y, FACADE_Z - 0.35), Vector3(x1, EAVE_Y, FACADE_Z - 0.35),
		Vector3.FORWARD, 0.8, false)
	lm.box("Wall", Vector3(cx, EAVE_Y + 1.3, FACADE_Z + 0.1), Vector3(w, 1.0, 0.6))
	for k in bays + 1:
		lm.box("Trim", Vector3(x0 + pitch * float(k), EAVE_Y + 1.6, FACADE_Z + 0.1), Vector3(0.7, 1.6, 0.8))
	lm.gable("Iron", Vector3(cx, EAVE_Y + 0.8, cz + 0.5), d - 1.0, w, 3.0, Basis(Vector3.UP, PI * 0.5), 0.0)

## A projecting pavilion with a giant arched window, red-banded piers,
## a curved gable and finials.
static func _pavilion(lm: LandmarkMesh, x0: float, x1: float) -> void:
	var cx := (x0 + x1) * 0.5
	var w := x1 - x0
	var fz := FACADE_Z - 1.5
	var h := EAVE_Y + 4.0
	lm.box("Wall", Vector3(cx, h * 0.5, (fz + BACK_Z) * 0.5), Vector3(w, h, BACK_Z - fz))
	for s in [-1.0, 1.0]:
		var x: float = cx + float(s) * (w * 0.5 - 1.0)
		lm.box("Trim", Vector3(x, h * 0.5, fz - 0.2), Vector3(2.0, h, 0.5))
		for k in 8:
			lm.box("Red", Vector3(x, 1.5 + 2.4 * float(k), fz - 0.48), Vector3(2.1, 0.6, 0.1), Basis(), 0.0)
		lm.lathe("Trim", Vector3(x, h, fz + 0.4), PackedVector2Array([Vector2(0.7, 0.0), Vector2(0.5, 0.6),
			Vector2(0.65, 1.2), Vector2(0.2, 2.0), Vector2(0.05, 3.2), Vector2(0.0, 3.2)]), 8)
	lm.quad("Windows", Vector3(cx - 3.5, 1.0, fz - 0.02), Vector3(cx + 3.5, 1.0, fz - 0.02),
		Vector3(cx + 3.5, 11.0, fz - 0.02), Vector3(cx - 3.5, 11.0, fz - 0.02), Vector3.FORWARD)
	LandmarkDetail.arch(lm, "Trim", Vector3(cx, 11.0, fz - 0.05), Vector3.FORWARD, 7.0, 0.9, 0.5)
	for k in 4:
		lm.box("Trim", Vector3(cx - 2.6 + 1.73 * float(k), 7.5, fz - 0.1), Vector3(0.2, 13.0, 0.2), Basis(), 0.0)
	LandmarkDetail.window(lm, "Trim", "Windows", Vector3(cx, h - 3.6, fz), Vector3.FORWARD, 2.2, 2.6, true, 0.3)
	LandmarkSaoTeatro.segment(lm, "Wall", Vector3(cx, h, fz + 1.0), w - 3.0, 3.0, 1.0)
	LandmarkSaoTeatro.segment(lm, "Trim", Vector3(cx, h, fz + 0.2), w - 2.0, 3.4, 0.3)

## The Elizabeth Street clock tower: a tall square shaft with banded
## piers, clock faces on three sides, a balustraded stage and cupola.
static func _clock_tower(lm: LandmarkMesh) -> void:
	var cx := (TOWER_X0 + TOWER_X1) * 0.5
	var w := TOWER_X1 - TOWER_X0
	var cz := (FACADE_Z + BACK_Z) * 0.5
	lm.box("Wall", Vector3(cx, 13.0, cz), Vector3(w, 26.0, BACK_Z - FACADE_Z))
	lm.box("Wall", Vector3(cx, 28.5, FACADE_Z + 6.0), Vector3(w - 2.0, 5.0, w - 2.0))
	for sx in [-1.0, 1.0]:
		var x: float = cx + float(sx) * (w * 0.5 - 0.7)
		lm.box("Trim", Vector3(x, 13.0, FACADE_Z - 0.2), Vector3(1.6, 26.0, 0.5))
		for k in 10:
			lm.box("Red", Vector3(x, 1.5 + 2.6 * float(k), FACADE_Z - 0.48), Vector3(1.7, 0.7, 0.1), Basis(), 0.0)
	lm.quad("Windows", Vector3(cx - 3.0, 0.8, FACADE_Z - 0.02), Vector3(cx + 3.0, 0.8, FACADE_Z - 0.02),
		Vector3(cx + 3.0, 6.0, FACADE_Z - 0.02), Vector3(cx - 3.0, 6.0, FACADE_Z - 0.02), Vector3.FORWARD)
	LandmarkDetail.arch(lm, "Trim", Vector3(cx, 6.0, FACADE_Z - 0.05), Vector3.FORWARD, 6.0, 0.7, 0.4)
	for k in 3:
		LandmarkDetail.window(lm, "Trim", "Windows", Vector3(cx, 10.5 + 4.8 * float(k), FACADE_Z), Vector3.FORWARD, 1.8, 3.0,
			k == 2, 0.3)
	LandmarkDetail.cornice(lm, "Trim", Vector3(TOWER_X0, 26.0, FACADE_Z - 0.2), Vector3(TOWER_X1, 26.0, FACADE_Z - 0.2),
		Vector3.FORWARD, 0.9, true)
	var cc := Vector3(cx, 28.6, FACADE_Z + 6.0)
	for n in [Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT]:
		var nn: Vector3 = n
		lm.disc("Clock", cc + nn * (w * 0.5 - 0.9), nn, 1.8, 24)
		lm.box("Trim", cc + nn * (w * 0.5 - 0.95) + Vector3(0, 2.1, 0), Vector3(4.2, 0.4, 4.2) * (Vector3.ONE - nn.abs()) + nn.abs() * 0.2, Basis(), 0.0)
	lm.box("Trim", Vector3(cx, 31.3, FACADE_Z + 6.0), Vector3(w - 1.4, 0.6, w - 1.4))
	LandmarkKits.dome_on_drum(lm, "Wall", "Roof", Vector3(cx, 31.6, FACADE_Z + 6.0), 3.2, 1.6, 2.6, 0.0, 24, 8)
	lm.spire("Trim", Vector3(cx, 35.8, FACADE_Z + 6.0), 0.3, 1.0, 0.0, 6)

## The corner block on Swanston Street: the great arched entrance with
## its glazed lunette over the indicator clocks, the steps, corner
## piers, then the octagonal drum, copper dome and lantern to 40 m.
static func _dome_block(lm: LandmarkMesh) -> void:
	var cx := (DOME_X0 + DOME_X1) * 0.5
	var w := DOME_X1 - DOME_X0
	var fz := FACADE_Z - 2.0
	var cz := (fz + BACK_Z) * 0.5
	var h := 24.0
	lm.box("Wall", Vector3(cx, h * 0.5, cz), Vector3(w, h, BACK_Z - fz))
	lm.box("Trim", Vector3(cx, h + 0.4, cz), Vector3(w + 1.0, 0.8, BACK_Z - fz + 1.0))
	for s in [-1.0, 1.0]:
		var x: float = cx + float(s) * (w * 0.5 - 2.0)
		lm.box("Trim", Vector3(x, h * 0.5, fz - 0.3), Vector3(4.0, h, 0.6))
		for k in 9:
			lm.box("Red", Vector3(x, 1.5 + 2.5 * float(k), fz - 0.62), Vector3(4.1, 0.7, 0.1), Basis(), 0.0)
		LandmarkDetail.window(lm, "Trim", "Windows", Vector3(x, 15.0, fz - 0.6), Vector3.FORWARD, 1.4, 2.6, true, 0.25)
	# The great arch: dark entrance, lunette glazing, archivolt.
	var span := 14.0
	var spring := 11.0
	lm.quad("Windows", Vector3(cx - span * 0.5, 0.0, fz - 0.02), Vector3(cx + span * 0.5, 0.0, fz - 0.02),
		Vector3(cx + span * 0.5, spring, fz - 0.02), Vector3(cx - span * 0.5, spring, fz - 0.02), Vector3.FORWARD)
	for i in 16:
		var a0 := PI * float(i) / 16.0
		var a1 := PI * float(i + 1) / 16.0
		var c := Vector3(cx, spring, fz - 0.02)
		lm.tri("Windows", c, c + Vector3(cos(a0), sin(a0), 0) * span * 0.5, c + Vector3(cos(a1), sin(a1), 0) * span * 0.5,
			Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD, Vector2.ZERO, Vector2(cos(a0), sin(a0)), Vector2(cos(a1), sin(a1)))
	LandmarkDetail.arch(lm, "Trim", Vector3(cx, spring, fz - 0.05), Vector3.FORWARD, span, 1.2, 0.6)
	for k in 7:
		var a := PI * (float(k) + 1.0) / 8.0
		lm.beam("Trim", Vector3(cx, spring, fz - 0.1), Vector3(cx, spring, fz - 0.1) + Vector3(cos(a), sin(a), 0) * span * 0.5,
			0.18, 0.18)
	lm.box("Trim", Vector3(cx, spring, fz - 0.2), Vector3(span, 0.5, 0.4))
	# The indicator clocks in a row across the arch under the transom.
	for k in 9:
		lm.disc("Clock", Vector3(cx - 5.6 + 1.4 * float(k), 8.8, fz - 0.25), Vector3.FORWARD, 0.55, 14)
	lm.box("Iron", Vector3(cx, 8.8, fz - 0.15), Vector3(13.0, 1.6, 0.2), Basis(), 0.0)
	# Entrance steps.
	for k in 4:
		lm.box("Trim", Vector3(cx, 0.15 * float(k) + 0.075, fz - 3.0 + 0.7 * float(k)), Vector3(span + 4.0, 0.15, 3.0 - 0.7 * float(k)), Basis(), 0.0)
	# Drum, dome and lantern.
	var base := Vector3(cx, h + 0.8, cz)
	lm.frustum("Wall", base, 9.0, 9.0, 4.6, 8, PI / 8.0)
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.disc("Windows", base + d * 8.35 + Vector3(0, 2.4, 0), d, 1.1, 14)
		var e := Vector3(cos(a + TAU / 16.0), 0, sin(a + TAU / 16.0))
		lm.box("Trim", base + e * 8.95 + Vector3(0, 2.3, 0), Vector3(1.0, 4.6, 0.4), Basis.looking_at(e))
	lm.frustum("Trim", base + Vector3(0, 4.6, 0), 9.5, 9.5, 0.6, 8, PI / 8.0)
	var prof := PackedVector2Array()
	for i in 12:
		var a := PI * 0.5 * float(i) / 11.0
		prof.append(Vector2(8.4 * cos(a), 6.4 * sin(a)))
	lm.lathe("Roof", base + Vector3(0, 5.2, 0), prof, 32)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var prev := base + Vector3(0, 5.2, 0) + d * 8.5
		for j in range(1, 10):
			var t := PI * 0.5 * float(j) / 11.0
			var p := base + Vector3(0, 5.2 + 6.5 * sin(t), 0) + d * 8.5 * cos(t)
			lm.beam("Roof", prev, p, 0.35, 0.25, d.cross(Vector3.UP))
			prev = p
	var top := base + Vector3(0, 11.5, 0)
	lm.frustum("Trim", top, 1.6, 1.5, 0.4, 12)
	lm.frustum("Windows", top + Vector3(0, 0.4, 0), 1.2, 1.2, 1.6, 12)
	for i in 6:
		var a := TAU * float(i) / 6.0
		lm.frustum("Trim", top + Vector3(cos(a) * 1.35, 0.4, sin(a) * 1.35), 0.14, 0.12, 1.6, 6)
	lm.lathe("Roof", top + Vector3(0, 2.0, 0), PackedVector2Array([Vector2(1.5, 0.0), Vector2(1.1, 0.4),
		Vector2(0.3, 0.8), Vector2(0.08, 1.0), Vector2(0.0, 1.0)]), 12)
	lm.spire("Trim", top + Vector3(0, 2.9, 0), 0.12, 0.6, 0.0, 6)

## Platform canopies behind the station: six long iron roofs on rows
## of columns, the platforms under them.
static func _canopies(lm: LandmarkMesh) -> void:
	for k in 6:
		var z := BACK_Z + 10.0 + 16.0 * float(k)
		lm.box("Trim", Vector3(-5.0, 0.5, z), Vector3(180.0, 1.0, 7.0), Basis(), 0.0)
		lm.gable("Iron", Vector3(-5.0, 6.0, z), 9.0, 180.0, 1.2, Basis(Vector3.UP, PI * 0.5), 0.3)
		for i in 19:
			var x := -95.0 + 10.0 * float(i)
			lm.beam("Iron", Vector3(x, 1.0, z), Vector3(x, 6.0, z), 0.3, 0.3)
			lm.beam("Iron", Vector3(x, 5.0, z), Vector3(x, 6.0, z - 3.0), 0.15, 0.15)
			lm.beam("Iron", Vector3(x, 5.0, z), Vector3(x, 6.0, z + 3.0), 0.15, 0.15)
