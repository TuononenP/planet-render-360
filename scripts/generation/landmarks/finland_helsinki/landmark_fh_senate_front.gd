class_name LandmarkFhSenateFront
extends RefCounted

## Helsinki Cathedral's front on Senate Square, in the cathedral model's
## frame (origin the church's centre, +Z south down the stair, metres; the
## registry turns it with the mapped front): the monumental stair, the two
## raised granite wings that run from its sides to Lohrmann's corner
## pavilions (1840s) with their posts and iron rails, the pavilions on
## their granite bases, and Walter Runeberg's Alexander II monument (1894)
## in the square before it. Plan from OSM (steps 29478214, wings
## 643455996 / 643455988 between their retaining walls, pavilions 4253124
## / 33084558, the statue's node); heights and detail from photographs
## of the square. The model replaces those mapped walls and buildings
## (registry `model_rects_m`); LandmarkStairCut holds the ground under it.

## Stair: 49 risers from the deck at TOP_Z to the square at FOOT_Z, 64 m
## wide; the last steps past the wings' fronts step out at their ends.
const TOP_Z := 40.0
const FOOT_Z := 57.0
const STAIR_HALF := 32.0
const RISERS := 49
## Wings: from the stair's sides to the pavilions, their decks level with
## the stair where it opens onto them (OPEN_Z).
const WING_OUT := 55.8
const WING_BACK := 39.0
const WING_FRONT := 54.0
const WING_DECK := 5.7
const OPEN_Z := Vector2(46.5, 49.5)
## Pavilions: x WING_OUT..PAV_OUT, z PAV_Z, a granite base up to the
## wing's post tops, an 11 m two-storey white body under a gabled roof.
const PAV_OUT := 65.3
const PAV_Z := Vector2(38.5, 54.3)
const PAV_BASE := 7.4
const PAV_BODY := 11.0
## Alexander II's monument: the platform's centre on the square. The
## square falls away south of the stair, so it is its own node, seated on
## the ground under it (LandmarkTerrain), not on the stair's datum.
const STATUE := Vector3(0.6, 0.0, 97.0)

static func build(lm: LandmarkMesh, plat: float, found: float) -> void:
	lm.use("Roof", LandmarkMaterials.paint("#6B7570", 0.6, 0.3))
	var deck := plat + 0.6
	_stair(lm, deck, found)
	_terrace_ends(lm, plat, deck, found)
	for sx in [-1.0, 1.0]:
		_wing(lm, sx, found)
		_pavilion(lm, sx, found)

## Alexander II is now a first-class standalone landmark (`alexander_ii_monument`
## in `landmark_fh_alexander_ii.gd`) so it renders with its full 38k-triangle
## museum-scan bronze ensemble without competing with Helsinki Cathedral's budget.
static func monument(_model: Node3D, _granite: Material, _iron: Material) -> void:
	pass

## A 1 m landing flush with the terrace paving, then the risers; every step
## stands on the walls' `found` footing so the square never opens under it.
static func _stair(lm: LandmarkMesh, deck: float, found: float) -> void:
	lm.box("Stairs", Vector3(0, (deck - found) * 0.5, TOP_Z - 0.5),
		Vector3(STAIR_HALF * 2.0, deck + found, 1.0), Basis(), 0.0)
	var tread := (FOOT_Z - TOP_Z) / float(RISERS)
	for k in RISERS:
		var z := TOP_Z + (float(k) + 0.5) * tread
		var h := deck * (1.0 - float(k + 1) / float(RISERS + 1))
		var w := STAIR_HALF * 2.0 + maxf(z - WING_FRONT, 0.0) * 2.0
		lm.box("Stairs", Vector3(0, (h - found) * 0.5, z), Vector3(w, h + found, tread), Basis(), 0.0)

## The terrace reaches out behind the wings to the pavilions' backs, its
## front edge railed over the wings.
static func _terrace_ends(lm: LandmarkMesh, plat: float, deck: float, found: float) -> void:
	for sx in [-1.0, 1.0]:
		var cx: float = sx * (39.0 + PAV_OUT) * 0.5
		var w := PAV_OUT - 39.0
		lm.box("Granite", Vector3(cx, (plat - found) * 0.5, 27.5), Vector3(w, plat + found, 23.0))
		lm.box("Stairs", Vector3(cx, plat + 0.3, 27.5), Vector3(w + 0.3, 0.6, 23.3))
		lm.box("Granite", Vector3(sx * (STAIR_HALF + WING_OUT) * 0.5, (plat - found) * 0.5, 38.6),
			Vector3(WING_OUT - STAIR_HALF, plat + found, 0.8))
		_parapet(lm, Vector3(sx * STAIR_HALF, deck, WING_BACK - 0.3),
			Vector3(sx * WING_OUT, deck, WING_BACK - 0.3))

## A raised granite wing from the stair's side to its pavilion: railed
## along its front and, where its deck stands over the stair, its side.
static func _wing(lm: LandmarkMesh, sx: float, found: float) -> void:
	var cx := sx * (STAIR_HALF + WING_OUT) * 0.5
	var w := WING_OUT - STAIR_HALF
	var cz := (WING_BACK + WING_FRONT) * 0.5
	var d := WING_FRONT - WING_BACK
	lm.box("Granite", Vector3(cx, (WING_DECK - 0.3 - found) * 0.5, cz), Vector3(w, WING_DECK - 0.3 + found, d))
	lm.box("Stairs", Vector3(cx, WING_DECK - 0.15, cz), Vector3(w + 0.3, 0.3, d + 0.3))
	_parapet(lm, Vector3(sx * STAIR_HALF, WING_DECK, WING_FRONT - 0.3),
		Vector3(sx * WING_OUT, WING_DECK, WING_FRONT - 0.3))
	_parapet(lm, Vector3(sx * (STAIR_HALF + 0.3), WING_DECK, OPEN_Z.y),
		Vector3(sx * (STAIR_HALF + 0.3), WING_DECK, WING_FRONT - 0.3))

## Granite kerb and square posts about every 4.7 m, two iron rails and
## balusters between them, standing on `a`..`b` (y the deck).
static func _parapet(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var run := b - a
	var run_len := run.length()
	var dir := run / run_len
	var r := Basis(Vector3.UP, atan2(dir.x, dir.z))
	lm.box("Granite", (a + b) * 0.5 + Vector3(0, 0.2, 0), Vector3(0.6, 0.4, run_len), r)
	var bays := maxi(int(round(run_len / 4.7)), 1)
	for i in bays + 1:
		lm.box("Granite", a + run * float(i) / float(bays) + Vector3(0, 0.75, 0), Vector3(0.85, 1.5, 0.85), r)
	for ry in [0.75, 1.2]:
		lm.box("Iron", (a + b) * 0.5 + Vector3(0, ry, 0), Vector3(0.06, 0.06, run_len), r, 0.0)
	var n := int(run_len / 0.6)
	for k in n:
		lm.box("Iron", a + run * (float(k) + 0.5) / float(n) + Vector3(0, 0.8, 0), Vector3(0.04, 0.8, 0.04), r, 0.0)

## A corner pavilion: its granite base up to the wing's post tops, flush
## with the wing's front, a white body of two storeys (small square windows
## below, tall arched ones above: two on each end, four on each side)
## between corner pilasters, a cornice, and a low gabled roof with a
## pediment at each end.
static func _pavilion(lm: LandmarkMesh, sx: float, found: float) -> void:
	var deck := PAV_BASE
	var cx := sx * (WING_OUT + PAV_OUT) * 0.5
	var w := PAV_OUT - WING_OUT
	var cz := (PAV_Z.x + PAV_Z.y) * 0.5
	var d := PAV_Z.y - PAV_Z.x
	lm.box("Granite", Vector3(cx, (deck - found) * 0.5, cz), Vector3(w, deck + found, d))
	lm.box("White", Vector3(cx, deck + PAV_BODY * 0.5, cz), Vector3(w - 0.4, PAV_BODY, d - 0.4))
	lm.box("White", Vector3(cx, deck + 0.3, cz), Vector3(w, 0.6, d))
	lm.box("White", Vector3(cx, deck + 4.2, cz), Vector3(w - 0.1, 0.35, d - 0.1))
	var top := deck + PAV_BODY
	for px in [-1.0, 1.0]:
		for pz in [-1.0, 1.0]:
			lm.box("White", Vector3(cx + px * (w * 0.5 - 0.6), deck + PAV_BODY * 0.5, cz + pz * (d * 0.5 - 0.6)),
				Vector3(1.3, PAV_BODY, 1.3))
	var faces := [[Vector3(0, 0, 1), d * 0.5 - 0.2, [-2.2, 2.2], w], [Vector3(0, 0, -1), d * 0.5 - 0.2, [-2.2, 2.2], w],
		[Vector3(1, 0, 0), w * 0.5 - 0.2, [-5.4, -1.8, 1.8, 5.4], d], [Vector3(-1, 0, 0), w * 0.5 - 0.2, [-5.4, -1.8, 1.8, 5.4], d]]
	for f in faces:
		var n: Vector3 = f[0]
		var side := Vector3(-n.z, 0, n.x)
		var c := Vector3(cx, 0, cz) + n * float(f[1])
		for o in f[2]:
			var p := c + side * float(o)
			# The back's lower storey stands against the terrace behind it.
			if n.z >= 0.0:
				LandmarkDetail.window(lm, "White", "Windows", p + Vector3(0, deck + 2.2, 0), n, 1.1, 1.3)
			LandmarkDetail.window(lm, "White", "Windows", p + Vector3(0, deck + 7.6, 0), n, 1.7, 3.8, true)
		var half: float = float(f[3]) * 0.5
		LandmarkDetail.cornice(lm, "White", c - side * half + Vector3(0, top - 0.8, 0),
			c + side * half + Vector3(0, top - 0.8, 0), n, 0.8, false)
	lm.gable("Roof", Vector3(cx, top, cz), w + 0.4, d + 0.4, 2.4, Basis(), 0.5, "White")

## Alexander II (Runeberg, 1894): a granite platform railed between posts
## with steps down to the square in front, clipped conifers, a tall
## five-lantern candelabrum at each front corner and a three-lantern one
## at each back corner; the stepped red-granite pedestal with the bronze
## emperor on its die and the four bronze groups (Lex, Pax, Lux, Labor)
## round its foot.
static func _monument(lm: LandmarkMesh) -> void:
	var c := Vector3.ZERO
	var hw := 8.5
	var hd := 7.5
	var top := 0.9
	lm.box("Granite", c + Vector3(0, (top - 2.0) * 0.5, 0), Vector3(hw * 2.0, top + 2.0, hd * 2.0))
	for k in 2:
		var h := top * float(2 - k) / 3.0
		lm.box("Granite", c + Vector3(0, (h - 2.0) * 0.5, hd + 0.25 + 0.5 * float(k)),
			Vector3(9.0, h + 2.0, 0.5), Basis(), 0.0)
	# Railing round the platform's edge, open over the front steps.
	var corners := [Vector3(-hw + 0.3, top, hd - 0.3), Vector3(-hw + 0.3, top, -hd + 0.3),
		Vector3(hw - 0.3, top, -hd + 0.3), Vector3(hw - 0.3, top, hd - 0.3)]
	for i in 3:
		_fence(lm, c + corners[i], c + corners[i + 1])
	for sx in [-1.0, 1.0]:
		_fence(lm, c + Vector3(sx * (hw - 0.3), top, hd - 0.3), c + Vector3(sx * 4.7, top, hd - 0.3))
	for p in [Vector3(-5.5, 0, 4.8), Vector3(-3.6, 0, 5.6), Vector3(3.6, 0, 5.6), Vector3(5.5, 0, 4.8),
			Vector3(-5.5, 0, -4.8), Vector3(5.5, 0, -4.8)]:
		lm.frustum("Bronze", c + p + Vector3(0, top, 0), 0.45, 0.05, 1.6, 8)
	for sx in [-1.0, 1.0]:
		_candelabrum(lm, c + Vector3(sx * (hw - 1.4), top, hd - 1.4), 8.0, 5)
		_candelabrum(lm, c + Vector3(sx * (hw - 1.4), top, -hd + 1.4), 5.5, 3)
	# Extracted City of Helsinki 3D+ Reality Mesh (2024, CC BY 4.0) Alexander II ensemble
	# mounted directly onto the crisp granite platform (y = 0.9 m -> 10.7 m exact).
	if not SculptureKit.stamp_path(lm, "Bronze", "res://assets/landmarks/helsinki_3d/alexander_ii.glb",
			c + Vector3(0.0, top, 0.0), Vector3(1.14, 1.16, 1.14), 0.0):
		var y := top
		for t in [[6.0, 0.5, 6.0], [4.6, 0.5, 4.6], [3.4, 0.9, 2.8], [2.6, 3.6, 2.0], [3.0, 0.4, 2.4], [2.2, 0.4, 1.6]]:
			lm.box("RedGranite", c + Vector3(0, y + float(t[1]) * 0.5, 0), Vector3(float(t[0]), float(t[1]), float(t[2])))
			y += float(t[1])
		LandmarkKits.statue_figure(lm, "Bronze", c + Vector3(0, y, 0), 3.5)

## Granite posts every ~2.5 m with iron panels between them on `a`..`b`.
static func _fence(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var run := b - a
	var run_len := run.length()
	var r := Basis(Vector3.UP, atan2(run.x, run.z))
	var bays := maxi(int(round(run_len / 2.5)), 1)
	for i in bays + 1:
		lm.box("Granite", a + run * float(i) / float(bays) + Vector3(0, 0.5, 0), Vector3(0.5, 1.0, 0.5), r)
	for ry in [0.15, 0.85]:
		lm.box("Iron", (a + b) * 0.5 + Vector3(0, ry, 0), Vector3(0.05, 0.06, run_len), r, 0.0)
	var n := int(run_len / 0.25)
	for k in n:
		lm.box("Iron", a + run * (float(k) + 0.5) / float(n) + Vector3(0, 0.5, 0), Vector3(0.03, 0.7, 0.03), r, 0.0)

## A granite lamp column `h` tall with an iron candelabrum of `n` lanterns:
## one on the stem, the rest on arms round it.
static func _candelabrum(lm: LandmarkMesh, base: Vector3, h: float, n: int) -> void:
	var shaft := h - 1.8
	lm.box("Granite", base + Vector3(0, 0.6, 0), Vector3(1.1, 1.2, 1.1))
	lm.frustum("Granite", base + Vector3(0, 1.2, 0), 0.42, 0.3, shaft - 1.2, 12)
	lm.box("Granite", base + Vector3(0, shaft + 0.15, 0), Vector3(0.8, 0.3, 0.8))
	var stem := base + Vector3(0, shaft + 0.3, 0)
	lm.frustum("Iron", stem, 0.08, 0.06, 1.2, 8)
	_lantern(lm, stem + Vector3(0, 1.2, 0))
	for i in n - 1:
		var a := TAU * (float(i) + 0.5) / float(n - 1)
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Iron", stem + d * 0.35 + Vector3(0, 0.55, 0), Vector3(0.7, 0.05, 0.05),
			Basis(Vector3.UP, -a), 0.0)
		_lantern(lm, stem + d * 0.7 + Vector3(0, 0.35, 0))

static func _lantern(lm: LandmarkMesh, base: Vector3) -> void:
	lm.box("Lamp", base + Vector3(0, 0.25, 0), Vector3(0.3, 0.5, 0.3), Basis(), 0.0)
	lm.frustum("Iron", base + Vector3(0, 0.5, 0), 0.22, 0.04, 0.25, 6)
	lm.box("Iron", base, Vector3(0.34, 0.05, 0.34), Basis(), 0.0)
