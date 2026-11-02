class_name LandmarkAeChina
extends RefCounted

## Imperial halls of Beijing in true metres: the Hall of Supreme Harmony
## (35.05 m: three Sumeru-moulded marble terraces 8.13 m high ringed by
## dragon-spouted balustrades, an 11 x 5 bay red hall with a front
## porch of columns and lattice doors, dougong bracket sets and a
## double-eaved hip roof of yellow glazed tile with ten ridge beasts on
## every hip and chiwen at the ridge ends) and the Temple of Heaven's
## Hall of Prayer for Good Harvests (38 m: round, 32 m across on a
## three-tier marble altar with stairs on all four sides, twelve outer
## columns, three blue glazed roofs and a gilt finial). Halls face
## south (+Z).

# --- Hall of Supreme Harmony ---

const SH_TERRACE := 2.71
## Bay widths across the 60 m front: a wide central bay, four of 5.6 m
## each side, narrow end bays.
const SH_BAYS := [3.4, 5.6, 5.6, 5.6, 5.6, 8.4, 5.6, 5.6, 5.6, 5.6, 3.4]

static func supreme_harmony(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4E0D6", 3.0))
	lm.use("Lacquer", LandmarkMaterials.paint("#9A2B22", 0.65, 0.0))
	lm.use("Bracket", LandmarkMaterials.paint("#2F6B7E", 0.6, 0.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#D9A52C", 2.0, 0.35))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shadow", LandmarkMaterials.paint("#2A1E1A", 0.9, 0.0))
	# Three Sumeru-moulded terraces, each with stairs front and back and a
	# balustrade broken by the flights.
	var sizes := [Vector2(116, 84), Vector2(106, 74), Vector2(96, 64)]
	for t in 3:
		var sz: Vector2 = sizes[t]
		var y := SH_TERRACE * t
		_sumeru(lm, "Marble", sz.x, sz.y, y, SH_TERRACE)
		var top := y + SH_TERRACE
		for sz_sign in [-1.0, 1.0]:
			var out := Vector3(0, 0, sz_sign)
			var edge: float = sz.y * 0.5 * sz_sign
			for fx in [-16.0, 0.0, 16.0]:
				var w := 9.0 if fx == 0.0 else 5.0
				LandmarkAeParts.steps(lm, "Marble", Vector3(fx, y, edge), out, w, SH_TERRACE, 9)
				for s in [-1.0, 1.0]:
					# Stair cheeks (chuidai) either side of each flight.
					lm.beam("Marble", Vector3(fx + s * (w * 0.5 + 0.3), top + 0.3, edge),
						Vector3(fx + s * (w * 0.5 + 0.3), y + 0.4, edge + sz_sign * 2.9), 0.6, 0.7)
			# The carved dragon ramp up the middle of the central flight.
			lm.beam("Marble", Vector3(0, top + 0.1, edge), Vector3(0, y + 0.35, edge + sz_sign * 2.9), 3.4, 0.4,
				Vector3.RIGHT)
			_rail_with_gaps(lm, Vector3(-sz.x * 0.5 + 0.3, top, edge - sz_sign * 0.3),
				Vector3(sz.x * 0.5 - 0.3, top, edge - sz_sign * 0.3), [-16.0, 0.0, 16.0], [3.2, 5.2, 3.2], out)
		for s in [-1.0, 1.0]:
			var x: float = s * (sz.x * 0.5 - 0.3)
			LandmarkAeParts.cn_balustrade(lm, "Marble", Vector3(x, top, -sz.y * 0.5 + 0.3),
				Vector3(x, top, sz.y * 0.5 - 0.3), 1.3, 2.0, Vector3(s, 0, 0))
	_supreme_hall(lm, SH_TERRACE * 3.0)
	lm.commit(model)

## Balustrade along a-b with openings for flights centred at `gaps`
## (x offsets) of half-widths `halfs`; spouts point along `out`.
static func _rail_with_gaps(lm: LandmarkMesh, a: Vector3, b: Vector3, gaps: Array, halfs: Array,
		out: Vector3) -> void:
	var x := a.x
	for i in gaps.size():
		var g0 := float(gaps[i]) - float(halfs[i])
		LandmarkAeParts.cn_balustrade(lm, "Marble", Vector3(x, a.y, a.z), Vector3(g0, a.y, a.z), 1.3, 2.0, out)
		x = float(gaps[i]) + float(halfs[i])
	LandmarkAeParts.cn_balustrade(lm, "Marble", Vector3(x, a.y, a.z), b, 1.3, 2.0, out)

## Sumeru (xumizuo) base w x d, `h` tall from y: plinth, lower lotus
## moulding, the recessed waist, upper moulding and the coping slab.
static func _sumeru(lm: LandmarkMesh, key: String, w: float, d: float, y: float, h: float) -> void:
	var parts := [[0.15, 0.3], [0.13, 0.1], [0.37, -0.35], [0.13, 0.1], [0.22, 0.2]]
	var yy := y
	for p in parts:
		var ph := float(p[0]) * h
		var g := float(p[1])
		lm.box(key, Vector3(0, yy + ph * 0.5, 0), Vector3(w + g * 2.0 - 0.4, ph, d + g * 2.0 - 0.4))
		yy += ph

## The hall on the top terrace at y0: stylobate, porch columns, lattice
## front, walls, brackets, the double-eaved hip roof and its ornaments.
static func _supreme_hall(lm: LandmarkMesh, y0: float) -> void:
	lm.box("Marble", Vector3(0, y0 + 0.6, 0), Vector3(66.0, 1.2, 39.0))
	LandmarkAeParts.steps(lm, "Marble", Vector3(0, y0, 19.5), Vector3.BACK, 12.0, 1.2, 4)
	var yc := y0 + 1.2
	var col_h := 6.7
	# Column lines across the front.
	var xs: Array[float] = [-30.0]
	for bw in SH_BAYS:
		xs.append(xs[xs.size() - 1] + float(bw))
	for x in xs:
		for z in [16.5, 11.5, -16.5]:
			_column(lm, Vector3(x, yc, z), 0.53, col_h)
	for z in [-11.0, -5.5, 0.0, 5.5]:
		for s in [-1.0, 1.0]:
			_column(lm, Vector3(s * 30.0, yc, z), 0.53, col_h)
	# Walls: solid back and sides; the front (porch line z = 11.5) is
	# lattice doors in the nine middle bays, lattice windows at the ends.
	lm.box("Lacquer", Vector3(0, yc + col_h * 0.5, -2.5), Vector3(60.0, col_h, 28.0))
	for i in SH_BAYS.size():
		var a := Vector3(xs[i] + 0.5, yc, 11.55)
		var b := Vector3(xs[i + 1] - 0.5, yc, 11.55)
		var end_bay := i == 0 or i == SH_BAYS.size() - 1
		_lattice_bay(lm, a, b, col_h - 0.9, Vector3.BACK, 2 if end_bay else 4, 1.4 if end_bay else 0.3)
	# Architrave and bracket sets under the lower eave.
	var ya := yc + col_h
	lm.box("Bracket", Vector3(0, ya + 0.4, 0), Vector3(61.6, 0.8, 34.6))
	LandmarkAeParts.brackets(lm, "Bracket", Vector3(0, ya + 0.8, 0), 61.6, 34.6, 1.2, 1.7)
	var r1 := Vector3(0, ya + 2.3, 0)
	LandmarkAeParts.hip_roof(lm, "Roof", r1, Vector2(76.0, 46.0), Vector2(54.0, 26.0), 4.2, 1.2)
	LandmarkAeParts.hip_ridges(lm, "Roof", r1, Vector2(76.0, 46.0), Vector2(54.0, 26.0), 4.2, 1.2, 0.55, 10)
	# Upper storey band, its architrave, brackets and the plaque.
	var yu := r1.y + 2.7
	lm.box("Lacquer", Vector3(0, yu + 1.75, 0), Vector3(52.0, 3.5, 24.0))
	for x in [-26.0, -13.0, 0.0, 13.0, 26.0]:
		for z in [-12.0, 12.0]:
			_column(lm, Vector3(x, yu, z), 0.45, 3.5)
	lm.box("Bracket", Vector3(0, yu + 3.8, 0), Vector3(53.0, 0.6, 25.0))
	LandmarkAeParts.brackets(lm, "Bracket", Vector3(0, yu + 4.1, 0), 53.0, 25.0, 1.0, 1.5)
	lm.box("Gold", Vector3(0, yu + 2.4, 12.6), Vector3(2.8, 3.8, 0.25))
	lm.box("Bracket", Vector3(0, yu + 2.4, 12.75), Vector3(2.2, 3.2, 0.2))
	var r2 := Vector3(0, yu + 5.4, 0)
	LandmarkAeParts.hip_roof(lm, "Roof", r2, Vector2(70.0, 40.0), Vector2(24.0, 1.2), 5.6, 1.0)
	LandmarkAeParts.hip_ridges(lm, "Roof", r2, Vector2(70.0, 40.0), Vector2(24.0, 1.2), 5.6, 1.0, 0.6, 10)
	# Main ridge and the two chiwen to 35.05 m.
	var ridge := r2.y + 5.6
	lm.box("Roof", Vector3(0, ridge + 0.5, 0), Vector3(24.4, 1.0, 1.3))
	for s in [-1.0, 1.0]:
		LandmarkAeParts.chiwen(lm, "Roof", Vector3(s * 12.2, ridge + 0.2, 0), 35.0 - ridge - 0.2, -s)

## Red lacquer column of radius r on a marble drum base.
static func _column(lm: LandmarkMesh, base: Vector3, r: float, h: float) -> void:
	lm.frustum("Marble", base, r * 1.6, r * 1.45, 0.3, 12)
	lm.frustum("Lacquer", base + Vector3(0, 0.3, 0), r, r * 0.93, h - 0.3, 12)

## Lattice doors (or windows over a sill wall `sill` high) filling a bay
## from a to b on the floor line, `h` tall, facing `n`: `leaves`
## framed leaves, each with a latticed upper panel over a solid apron,
## a dark interior behind and a transom over the head rail.
static func _lattice_bay(lm: LandmarkMesh, a: Vector3, b: Vector3, h: float, n: Vector3, leaves: int,
		sill: float) -> void:
	var dir := (b - a).normalized()
	var w := a.distance_to(b)
	var basis := Basis(dir, Vector3.UP, n)
	var mid := (a + b) * 0.5
	lm.quad("Shadow", a + n * 0.02, b + n * 0.02, b + n * 0.02 + Vector3(0, h, 0), a + n * 0.02 + Vector3(0, h, 0), n)
	if sill > 0.5:
		lm.box("Lacquer", mid + Vector3(0, sill * 0.5, 0) + n * 0.1, Vector3(w, sill, 0.3), basis, 0.0)
	var y0 := sill
	var head := h * 0.84
	var lw := w / float(leaves)
	for i in leaves:
		var lc := a + dir * lw * (float(i) + 0.5) + n * 0.1
		for s in [-1.0, 1.0]:
			lm.box("Lacquer", lc + dir * (lw * 0.5 - 0.06) * s + Vector3(0, (y0 + head) * 0.5, 0),
				Vector3(0.12, head - y0, 0.14), basis, 0.0)
		var lattice_y := y0 + (head - y0) * 0.4
		for ry in [y0 + 0.06, lattice_y, head - 0.06]:
			lm.box("Lacquer", lc + Vector3(0, ry, 0), Vector3(lw, 0.12, 0.14), basis, 0.0)
		# Solid apron with a gilt fitting, latticed panel above.
		lm.box("Lacquer", lc + Vector3(0, (y0 + lattice_y) * 0.5, 0) - n * 0.03,
			Vector3(lw - 0.1, lattice_y - y0 - 0.1, 0.06), basis, 0.0)
		lm.box("Gold", lc + Vector3(0, lattice_y - 0.12, 0) + n * 0.06, Vector3(lw * 0.5, 0.1, 0.04), basis, 0.0)
		for k in 3:
			lm.box("Lacquer", lc + dir * lw * (float(k + 1) / 4.0 - 0.5) + Vector3(0, (lattice_y + head) * 0.5, 0),
				Vector3(0.05, head - lattice_y, 0.06), basis, 0.0)
		for k in 5:
			lm.box("Lacquer", lc + Vector3(0, lerpf(lattice_y, head, float(k + 1) / 6.0), 0),
				Vector3(lw - 0.1, 0.05, 0.06), basis, 0.0)
	# Transom over the leaves.
	for k in 4:
		lm.box("Lacquer", mid + n * 0.1 + dir * w * (float(k + 1) / 5.0 - 0.5) + Vector3(0, (head + h) * 0.5, 0),
			Vector3(0.06, h - head, 0.06), basis, 0.0)
	lm.box("Lacquer", mid + n * 0.1 + Vector3(0, h - 0.06, 0), Vector3(w, 0.12, 0.14), basis, 0.0)

# --- Temple of Heaven (Hall of Prayer for Good Harvests) ---

static func temple_of_heaven(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E2DED4", 3.0))
	lm.use("Lacquer", LandmarkMaterials.paint("#8E2A22", 0.65, 0.0))
	lm.use("Blue", LandmarkMaterials.pbr("terracotta", "#1F5C9E", 2.0, 0.3))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Bracket", LandmarkMaterials.paint("#2F6B7E", 0.6, 0.0))
	lm.use("Shadow", LandmarkMaterials.paint("#2A1E1A", 0.9, 0.0))
	# The three-tier round altar, 2 m a tier, stairs on all four sides.
	for t in 3:
		var r := 45.5 - 8.0 * t
		var y := 2.0 * t
		lm.lathe("Marble", Vector3(0, y, 0), PackedVector2Array([Vector2(r + 0.3, 0), Vector2(r + 0.3, 0.3),
			Vector2(r + 0.1, 0.42), Vector2(r - 0.3, 0.55), Vector2(r - 0.3, 1.35), Vector2(r + 0.1, 1.48),
			Vector2(r + 0.25, 1.62), Vector2(r + 0.25, 2.0)]), 72)
		for q in 4:
			var a := PI * 0.5 * q
			var out := Vector3(cos(a), 0, sin(a))
			var side := out.cross(Vector3.UP)
			var main := q % 2 == 1
			LandmarkAeParts.steps(lm, "Marble", out * (r + 0.2) + Vector3(0, y, 0), out, 9.0 if main else 5.0, 2.0, 7, 0.36)
			for s in [-1.0, 1.0]:
				var hw := (4.5 if main else 2.5) + 0.3
				lm.beam("Marble", out * (r + 0.2) + side * hw * s + Vector3(0, y + 2.3, 0),
					out * (r + 2.8) + side * hw * s + Vector3(0, y + 0.4, 0), 0.6, 0.7)
			if main:
				lm.beam("Marble", out * (r + 0.2) + Vector3(0, y + 2.1, 0), out * (r + 2.7) + Vector3(0, y + 0.35, 0),
					3.0, 0.4, side)
		_round_rail(lm, r - 0.1, y + 2.0, [5.4, 3.4, 5.4, 3.4])
	# The hall on its stylobate.
	var y0 := 6.0
	lm.frustum("Marble", Vector3(0, y0, 0), 16.2, 16.0, 0.5, 48)
	var yc := y0 + 0.5
	var col_h := 8.0
	lm.frustum("Lacquer", Vector3(0, yc, 0), 14.0, 14.0, col_h, 48)
	for i in 12:
		var a0 := TAU * float(i) / 12.0
		var a1 := TAU * float(i + 1) / 12.0
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		_column(lm, d0 * 14.6 + Vector3(0, yc, 0), 0.5, col_h)
		var am := (a0 + a1) * 0.5
		var door := i % 3 == 1
		_lattice_bay(lm, (d0 + (d1 - d0) * 0.06) * 14.05 + Vector3(0, yc, 0),
			(d1 - (d1 - d0) * 0.06) * 14.05 + Vector3(0, yc, 0), col_h - 0.8,
			Vector3(cos(am), 0, sin(am)), 4, 0.2 if door else 1.2)
	# Architrave, brackets and three roofs; red clerestory necks between.
	var ya := yc + col_h
	lm.frustum("Bracket", Vector3(0, ya, 0), 15.0, 15.0, 0.8, 48)
	_ring_brackets(lm, Vector3(0, ya + 0.8, 0), 15.2, 1.0, 44)
	_round_roof(lm, ya + 1.8, 19.5, 4.5, 14.0)
	var n2 := ya + 5.3
	_clerestory(lm, n2, 13.6, 2.5)
	_ring_brackets(lm, Vector3(0, n2 + 2.5, 0), 14.0, 0.9, 36)
	_round_roof(lm, n2 + 3.4, 16.8, 4.0, 11.4)
	var n3 := n2 + 6.6
	_clerestory(lm, n3, 11.0, 2.2)
	_ring_brackets(lm, Vector3(0, n3 + 2.2, 0), 11.4, 0.9, 30)
	var r3 := n3 + 3.1
	_round_roof(lm, r3, 13.8, 38.0 - 3.1 - r3, 1.2)
	# Gilt finial: lotus base, ball and spike to 38 m.
	var fy := 38.0 - 3.1
	lm.lathe("Gold", Vector3(0, fy, 0), PackedVector2Array([Vector2(1.4, 0), Vector2(1.6, 0.3),
		Vector2(1.0, 0.7), Vector2(0.5, 0.9)]), 16)
	LandmarkAeParts.ball(lm, "Gold", Vector3(0, fy + 1.7, 0), 0.9, 14, 7)
	lm.lathe("Gold", Vector3(0, fy + 2.4, 0), PackedVector2Array([Vector2(0.35, 0), Vector2(0.2, 0.3),
		Vector2(0.02, 3.1 - 2.4)]), 8)
	lm.commit(model)

## Marble balustrade round a circular deck of radius r at height y,
## broken at the four stairheads (half-widths `gaps` for E, S, W, N).
static func _round_rail(lm: LandmarkMesh, r: float, y: float, gaps: Array) -> void:
	var n := int(TAU * r / 2.0)
	for i in n:
		var a0 := TAU * float(i) / float(n)
		var a1 := TAU * float(i + 1) / float(n)
		var p0 := Vector3(cos(a0) * r, y, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, y, sin(a1) * r)
		var skip := false
		for q in 4:
			var c := Vector3(cos(PI * 0.5 * q), 0, sin(PI * 0.5 * q))
			var side := c.cross(Vector3.UP)
			if absf(((p0 + p1) * 0.5).dot(side)) < float(gaps[q]) and (p0 + p1).dot(c) > 0.0:
				skip = true
		if not skip:
			var am := (a0 + a1) * 0.5
			LandmarkAeParts.cn_balustrade(lm, "Marble", p0, p1, 1.2, 2.2, Vector3(cos(am), 0, sin(am)), false)

## Bracket sets round a circle of radius r at `c` (bottom), `h` tall.
static func _ring_brackets(lm: LandmarkMesh, c: Vector3, r: float, h: float, n: int) -> void:
	for i in n:
		var a := TAU * float(i) / float(n)
		var out := Vector3(cos(a), 0, sin(a))
		var basis := Basis(out.cross(Vector3.UP).normalized() * -1.0, Vector3.UP, out)
		for k in 3:
			lm.box("Bracket", c + out * (r + 0.15 + 0.25 * k) + Vector3(0, h * (float(k) + 0.5) / 3.0, 0),
				Vector3(0.45 + 0.3 * k, h / 3.0 * 0.9, 0.3 + 0.5 * k), basis, 0.0)
	lm.frustum("Bracket", c, r - 0.2, r - 0.2, h, 36)

## Red clerestory neck of radius r, `h` tall, with lattice windows in
## twelve bays and posts between them.
static func _clerestory(lm: LandmarkMesh, y: float, r: float, h: float) -> void:
	lm.frustum("Lacquer", Vector3(0, y, 0), r, r, h, 36)
	for i in 12:
		var a := TAU * float(i) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Lacquer", d * (r + 0.15) + Vector3(0, y + h * 0.5, 0), Vector3(0.4, h, 0.4),
			Basis(d.cross(Vector3.UP).normalized() * -1.0, Vector3.UP, d), 0.0)
		var am := a + PI / 12.0
		var dm := Vector3(cos(am), 0, sin(am))
		var side := dm.cross(Vector3.UP).normalized()
		var hw := r * sin(PI / 12.0) * 0.8
		var c := dm * (r * cos(PI / 12.0) + 0.05) + Vector3(0, y + 0.3, 0)
		_lattice_bay(lm, c - side * hw, c + side * hw, h - 0.6, dm, 2, 0.0)

## Round roof of blue glazed tile from eave radius re at y, `rise` up to
## radius rt: concave lathe with a turned-up eave lip and tile rolls
## running down it.
static func _round_roof(lm: LandmarkMesh, y: float, re: float, rise: float, rt: float) -> void:
	var prof := PackedVector2Array([Vector2(re + 0.6, 0.5), Vector2(re, 0.0),
		Vector2(lerpf(re, rt, 0.45), rise * 0.28), Vector2(lerpf(re, rt, 0.8), rise * 0.62),
		Vector2(rt, rise)])
	lm.lathe("Blue", Vector3(0, y, 0), prof, 48)
	var rolls := int(TAU * re / 1.6)
	for i in rolls:
		var a := TAU * (float(i) + 0.5) / float(rolls)
		var d := Vector3(cos(a), 0, sin(a))
		for k in range(1, prof.size() - 1):
			var p0 := prof[k]
			var p1 := prof[k + 1]
			if p1.x < 2.0:
				break
			lm.beam("Blue", d * p0.x + Vector3(0, y + p0.y + 0.12, 0), d * p1.x + Vector3(0, y + p1.y + 0.12, 0),
				0.22, 0.2, d.cross(Vector3.UP))
	# Gilt-tipped eave tile ring.
	lm.frustum("Gold", Vector3(0, y + 0.35, 0), re + 0.65, re + 0.65, 0.18, 48)
