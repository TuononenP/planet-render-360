class_name LandmarkEiffel
extends RefCounted

## The Eiffel Tower in true metres (PRD AC-06 / §4.1): four curved
## lattice piers on a 125 m square base that taper continuously and
## merge into one shaft, the four great arches under the first floor,
## the arcaded first-floor frieze (57.6 m), the second floor (115.7 m),
## the third-floor cabin and campanile (276 m) and the antenna mast to
## 330 m. Every member is a merged lattice bar (one surface per part),
## matte bronze-brown paint #6B4A2F ("Eiffel Tower brown"), so the
## tower reads as open lace — never stacked cylinders or solid cones.
## Piers point at the compass (north/east/south/west pillars), faces
## square to the Champ de Mars (bearing 134.4°).

const TOP_Y := 276.0
const ANTENNA_Y := 330.0
const FLOOR1_Y := 57.6
const FLOOR2_Y := 115.7

## Outer half-width of the tower (centre to the outer pier edge) by
## height — the published elevation's exponential-looking flare.
static var OUTER := PackedVector2Array([Vector2(0, 62.5), Vector2(30, 47.5),
	Vector2(57.6, 36.0), Vector2(87, 27.0), Vector2(115.7, 20.0), Vector2(160, 13.5),
	Vector2(200, 9.6), Vector2(240, 7.0), Vector2(276, 5.2)])
## Inner half-width (centre to the pier's inner edge): the 74 m great
## arch span at the ground, closing to a single shaft near the top.
static var INNER := PackedVector2Array([Vector2(0, 37.0), Vector2(57.6, 21.0),
	Vector2(115.7, 10.0), Vector2(180, 3.2), Vector2(240, 0.8), Vector2(276, 0.0)])

static func outer(y: float) -> float:
	return LandmarkMesh.profile_at(OUTER, y)

static func inner(y: float) -> float:
	return maxf(LandmarkMesh.profile_at(INNER, y), 0.0)

static func build(model: Node3D) -> void:
	var iron := LandmarkMaterials.paint("#6B4A2F", 0.72, 0.2)
	var deck := LandmarkMaterials.paint("#58402A", 0.8, 0.15)
	var lm := LandmarkMesh.new()
	for k in ["PierN", "PierE", "PierS", "PierW", "Arches", "Upper", "Top"]:
		lm.use(k, iron)
	lm.use("Decks", deck)
	lm.use("Glass", LandmarkMaterials.glass("#3A4448"))
	lm.use("Antenna", LandmarkMaterials.paint("#D9D6CF", 0.5, 0.3))
	var levels := _levels()
	var piers := {"PierS": Vector2(1, 1), "PierE": Vector2(1, -1),
		"PierN": Vector2(-1, -1), "PierW": Vector2(-1, 1)}
	for key in piers:
		_pier(lm, key, piers[key], levels)
	_arches(lm)
	_floor1(lm)
	_floor2(lm)
	_top(lm)
	lm.commit(model)
	model.rotation.y = -deg_to_rad(44.4)

## Panel levels: 4 tall panels to the first floor, 5 to the second,
## then ~8 m panels up the shaft (keeps the X-bracing near 45°).
static func _levels() -> PackedFloat32Array:
	var ys := PackedFloat32Array()
	for i in 4:
		ys.append(FLOOR1_Y * float(i) / 4.0)
	for i in 5:
		ys.append(FLOOR1_Y + (FLOOR2_Y - FLOOR1_Y) * float(i) / 5.0)
	var y := FLOOR2_Y
	while y < TOP_Y - 0.5:
		ys.append(y)
		y += clampf(outer(y) * 0.75, 5.5, 13.0)
	ys.append(TOP_Y)
	return ys

## One pier: four curved corner chords and X-lattice on all four faces
## (outer, inner and both sides — the inner faces show through the
## arches), finer and double-stacked in the wide lower panels.
static func _pier(lm: LandmarkMesh, key: String, q: Vector2, ys: PackedFloat32Array) -> void:
	var corners := func(y: float) -> Array:
		var o := outer(y)
		var i := inner(y)
		return [Vector3(q.x * i, y, q.y * i), Vector3(q.x * o, y, q.y * i),
			Vector3(q.x * o, y, q.y * o), Vector3(q.x * i, y, q.y * o)]
	for li in ys.size() - 1:
		var y0 := ys[li]
		var y1 := ys[li + 1]
		var c0: Array = corners.call(y0)
		var c1: Array = corners.call(y1)
		var chord := lerpf(2.6, 0.9, y0 / TOP_Y)
		for k in 4:
			lm.beam(key, c0[k], c1[k], chord, chord)
		var w := lerpf(0.75, 0.32, y0 / TOP_Y)
		var cols := 2 if y0 < FLOOR1_Y else 1
		var rows := 2 if y0 < FLOOR1_Y else 1
		if inner(y0) < 0.6:
			# Merged shaft: only the outward faces carry lattice.
			for k in [1, 2]:
				_face(lm, key, c0[k], c0[k + 1], c1[k], c1[k + 1], w, 1, 1)
			continue
		for k in 4:
			var k2 := (k + 1) % 4
			_face(lm, key, c0[k], c0[k2], c1[k], c1[k2], w, cols, rows)

static func _face(lm: LandmarkMesh, key: String, p0: Vector3, p1: Vector3,
		q0: Vector3, q1: Vector3, w: float, cols: int, rows: int) -> void:
	for c in cols:
		var t0 := float(c) / float(cols)
		var t1 := float(c + 1) / float(cols)
		lm.lattice_panel(key, p0.lerp(p1, t0), p0.lerp(p1, t1), q0.lerp(q1, t0),
			q0.lerp(q1, t1), w, rows)

## The four decorative great arches: a lattice girder in each face
## plane spanning the inner pier edges, springing near the ground and
## cresting under the first-floor girder, with spandrel posts above.
static func _arches(lm: LandmarkMesh) -> void:
	var n := 24
	for side in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(side))
		var lo: Array[Vector3] = []
		var hi: Array[Vector3] = []
		for s in n + 1:
			var u := -1.0 + 2.0 * float(s) / float(n)
			var y := 8.0 + 31.0 * pow(maxf(1.0 - u * u, 0.0), 0.5)
			var y2 := y + lerpf(6.0, 3.2, 1.0 - absf(u))
			lo.append(rot * Vector3(u * inner(y), y, outer(y) - 1.5))
			hi.append(rot * Vector3(u * inner(y2), y2, outer(y2) - 1.5))
		for s in n:
			lm.beam("Arches", lo[s], lo[s + 1], 1.3, 1.6)
			lm.beam("Arches", hi[s], hi[s + 1], 1.1, 1.4)
			lm.beam("Arches", lo[s], hi[s + 1], 0.5, 0.8)
			lm.beam("Arches", hi[s], lo[s + 1], 0.5, 0.8)
		# Spandrel posts from the arch to the first-floor girder.
		for s in range(2, n - 1, 2):
			var top := Vector3(hi[s].x, FLOOR1_Y - 1.0, hi[s].z)
			top = rot.inverse() * top
			var y_top := FLOOR1_Y - 1.0
			top = rot * Vector3(top.x, y_top, outer(y_top) - 1.0)
			if top.y > hi[s].y + 1.0:
				lm.beam("Arches", hi[s], top, 0.6, 0.7)

## First floor: deck girder plus the arcaded frieze of round-headed
## bays around the 70 m platform, with the glass pavilions inside.
static func _floor1(lm: LandmarkMesh) -> void:
	var y0 := FLOOR1_Y
	var hw := outer(y0) + 0.5
	lm.box("Decks", Vector3(0, y0 + 0.9, 0), Vector3(hw * 2.0, 1.8, hw * 2.0))
	_frieze(lm, hw, y0 + 1.8, 6.2, 15)
	lm.box("Glass", Vector3(0, y0 + 4.2, 0), Vector3(hw * 1.55, 4.6, hw * 1.55))

static func _floor2(lm: LandmarkMesh) -> void:
	var y0 := FLOOR2_Y
	var hw := outer(y0) + 0.8
	lm.box("Decks", Vector3(0, y0 + 0.7, 0), Vector3(hw * 2.0, 1.4, hw * 2.0))
	_frieze(lm, hw, y0 + 1.4, 3.4, 9)
	lm.box("Glass", Vector3(0, y0 + 3.4, 0), Vector3(hw * 1.3, 4.0, hw * 1.3))
	# Central lift spine where the piers have merged.
	lm.box("Upper", Vector3(0, (190.0 + TOP_Y) * 0.5, 0), Vector3(2.0, TOP_Y - 190.0, 2.0))
	# Intermediate platform ring (old 196 m landing).
	var ym := 196.0
	var hm := outer(ym) + 0.4
	lm.box("Decks", Vector3(0, ym, 0), Vector3(hm * 2.0, 1.0, hm * 2.0))

## Arcade band: `bays` round-headed openings per side, posts and a
## cornice rail, `h` tall from y0.
static func _frieze(lm: LandmarkMesh, hw: float, y0: float, h: float, bays: int) -> void:
	for side in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(side))
		var a := rot * Vector3(-hw, 0, hw)
		var b := rot * Vector3(hw, 0, hw)
		lm.beam("Decks", a + Vector3(0, y0 + h, 0), b + Vector3(0, y0 + h, 0), 0.9, 0.9)
		lm.beam("Decks", a + Vector3(0, y0 + 0.3, 0), b + Vector3(0, y0 + 0.3, 0), 0.6, 0.6)
		for i in bays:
			var p := a.lerp(b, float(i) / float(bays))
			var p2 := a.lerp(b, float(i + 1) / float(bays))
			lm.beam("Decks", p + Vector3(0, y0, 0), p + Vector3(0, y0 + h, 0), 0.55, 0.8)
			var spring := y0 + h * 0.55
			var r := p.distance_to(p2) * 0.5
			var prev := p + Vector3(0, spring, 0)
			for s in range(1, 7):
				var t := float(s) / 6.0
				var q := p.lerp(p2, t) + Vector3(0, spring + sin(t * PI) * minf(r, h * 0.4), 0)
				lm.beam("Decks", prev, q, 0.3, 0.4)
				prev = q

## Third-floor cabin, campanile lantern and the antenna mast.
static func _top(lm: LandmarkMesh) -> void:
	var y := TOP_Y
	lm.box("Decks", Vector3(0, y + 0.6, 0), Vector3(18.0, 1.2, 18.0))
	lm.box("Glass", Vector3(0, y + 4.0, 0), Vector3(14.5, 5.6, 14.5))
	lm.box("Top", Vector3(0, y + 7.2, 0), Vector3(16.5, 0.9, 16.5))
	# Campanile: four curved ribs and rings tapering to the lantern.
	var ribs: Array = []
	for s in 4:
		var q := Vector2(1, 1).rotated(PI * 0.5 * float(s))
		var pts: Array[Vector3] = []
		for k in 7:
			var t := float(k) / 6.0
			var half := lerpf(6.0, 1.8, pow(t, 0.8))
			pts.append(Vector3(q.x * half, y + 7.6 + t * 16.0, q.y * half))
		ribs.append(pts)
		for k in 6:
			lm.beam("Top", pts[k], pts[k + 1], 0.7, 0.7)
	for k in [0, 2, 4, 6]:
		for s in 4:
			lm.beam("Top", (ribs[s] as Array)[k], (ribs[(s + 1) % 4] as Array)[k], 0.45, 0.45)
	lm.frustum("Top", Vector3(0, y + 23.6, 0), 2.2, 1.6, 3.0, 8)
	# Antenna mast with its stacked transmitter sections.
	lm.frustum("Antenna", Vector3(0, y + 26.6, 0), 1.1, 0.75, 14.0, 8)
	lm.frustum("Antenna", Vector3(0, y + 40.6, 0), 0.55, 0.3, ANTENNA_Y - y - 40.6, 8)
	for k in 3:
		lm.frustum("Antenna", Vector3(0, y + 30.0 + float(k) * 4.0, 0), 1.6, 1.6, 0.8, 8)
