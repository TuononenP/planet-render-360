class_name LandmarkGtBronzeAge
extends RefCounted

## Mycenae in true metres: the Lion Gate with its bastion, Grave Circle A
## inside the walls and the Treasury of Atreus (the Minoan palace of
## Knossos is LandmarkGtKnossos).

const MYC_TOP := 9.0
## Cyclopean courses (height min / spread) and blocks (length min / spread).
const CYCLOPEAN := [Vector2(0.8, 0.4), Vector2(1.3, 1.6), 0.18]
## Conglomerate pseudo-ashlar of the 13th-century BC gate works.
const ASHLAR := [Vector2(0.7, 0.2), Vector2(1.4, 0.9), 0.04]

## Lion Gate (c. 1250 BC), origin at the middle of the threshold on the
## gate's outer face, front to +Z (the approach from the north-west):
## the two conglomerate door-post monoliths leaning in from 3.1 m apart
## at the threshold to 2.8 m under the 4.5 m lintel; the limestone
## relieving slab (3.6 m at its base, 3.3 m high) with the two
## lionesses, forepaws on a double altar, flanking the Minoan column
## with its capital and beam ends, their separately carved heads lost;
## the corbelled courses each side of the slab; the cyclopean walls,
## and on the approach's left the conglomerate bastion (14.8 x 7.2 m)
## that makes the 15 x 7.2 m court before the gate. Inside: Grave
## Circle A (27.5 m across, a double ring of upright slabs round six
## shaft graves) and the Granary; drawn nearer than it lies, the
## Treasury of Atreus.
static func lion_gate(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#9D917C", 3.0))
	lm.use("Relief", LandmarkMaterials.pbr("limestone", "#C4B696", 2.0))
	lm.use("Mound", LandmarkMaterials.pbr("lawn", "#8F8B5D", 5.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3C342B", 2.5))
	lm.use("Green", LandmarkMaterials.pbr("stone", "#6C7B5E", 2.0))
	lm.use("Floor", LandmarkMaterials.pbr("gravel", "#A8987C", 3.0))
	lm.use("Conglom", LandmarkMaterials.pbr("stone", "#8C7A66", 2.5))
	lm.use("Red", LandmarkMaterials.pbr("stone", "#8E4E3E", 2.0))
	# Cyclopean walls either side of the gate, conglomerate facing next to it.
	_lay(lm, "Wall", Vector3(-26.0, 0, 0), Vector3(-4.2, 0, 0), Vector3.BACK, 6.0, 0.0, MYC_TOP, CYCLOPEAN, 1)
	_lay(lm, "Wall", Vector3(4.2, 0, 0), Vector3(26.0, 0, 0), Vector3.BACK, 6.0, 0.0, MYC_TOP, CYCLOPEAN, 2)
	for s in [-1.0, 1.0]:
		var x0: float = 2.1 * s
		var x1: float = 4.2 * s
		_lay(lm, "Conglom", Vector3(minf(x0, x1), 0, 0), Vector3(maxf(x0, x1), 0, 0), Vector3.BACK, 6.0, 0.0, MYC_TOP,
			ASHLAR, 5 + int(s))
		# Door-post monolith, leaning in, and the pivot block behind it.
		lm.beam("Conglom", Vector3(s * 1.9, 0.03, -1.0), Vector3(s * 1.74, 3.1, -1.0), 0.7, 2.0, Vector3.RIGHT)
		LandmarkGtUtil.block(lm, "Conglom", s * 1.55 - 0.3, s * 1.55 + 0.3, 0.0, 3.1, -2.6, -2.0)
	# Threshold, lintel and the passage floor behind.
	LandmarkGtUtil.block(lm, "Conglom", -1.6, 1.6, 0.0, 0.12, -2.0, 0.0)
	for k in 2:
		LandmarkGtUtil.block(lm, "Shadow", -0.9 + 1.6 * float(k), -0.75 + 1.6 * float(k), 0.12, 0.13, -1.9, 0.0)
	LandmarkGtUtil.block(lm, "Conglom", -2.25, 2.25, 3.1, 4.1, -2.0, 0.0)
	LandmarkGtUtil.block(lm, "Floor", -2.1, 2.1, 0.0, 0.05, -6.0, -2.0)
	# Masonry above the lintel: the backing, and corbelled courses beside
	# the relieving triangle.
	_lay(lm, "Conglom", Vector3(-2.25, 0, -0.7), Vector3(2.25, 0, -0.7), Vector3.BACK, 5.3, 4.1, MYC_TOP, ASHLAR, 7)
	var y := 4.1
	var row := 0
	while y < MYC_TOP - 0.01:
		var hh := minf(0.55 + 0.2 * LandmarkGtUtil.hash01(row, 77), MYC_TOP - y)
		var hw := maxf(1.8 * (1.0 - (y + hh * 0.5 - 4.1) / 3.3), 0.0)
		if hw < 0.05:
			LandmarkGtUtil.block(lm, "Conglom", -2.25, 2.25, y, y + hh - 0.03, -0.7, 0.0)
		else:
			LandmarkGtUtil.block(lm, "Conglom", -2.25, -hw - 0.02, y, y + hh - 0.03, -0.7, 0.0)
			LandmarkGtUtil.block(lm, "Conglom", hw + 0.02, 2.25, y, y + hh - 0.03, -0.7, 0.0)
		y += hh
		row += 1
	_relief(lm)
	# Court before the gate: the bastion on the left, the older wall's
	# slope on the right.
	LandmarkGtUtil.block(lm, "Floor", -3.6, 3.6, 0.0, 0.05, 0.0, 15.0)
	_lay(lm, "Conglom", Vector3(-3.6, 0, 0.0), Vector3(-3.6, 0, 14.8), Vector3.RIGHT, 7.2, 0.0, 8.4, ASHLAR, 11)
	_lay(lm, "Conglom", Vector3(-10.8, 0, 14.8), Vector3(-3.6, 0, 14.8), Vector3.BACK, 1.0, 0.0, 8.4, ASHLAR, 12)
	_lay(lm, "Wall", Vector3(3.6, 0, 15.0), Vector3(3.6, 0, 0.0), Vector3.LEFT, 4.0, 0.0, 5.5, CYCLOPEAN, 13)
	_grave_circle(lm, Vector3(13.0, 0, -24.0))
	_granary(lm, Vector3(-6.5, 0, -11.0))
	LandmarkGtUtil.block(lm, "Floor", -26.0, 26.0, 0.0, 0.04, -40.0, -6.0)
	_atreus(lm, Vector3(75.0, 0, -50.0))
	lm.commit(model)

## Blocks laid course by course along the face line a..b (at ground,
## y0..y1 high), front facing `out`, each `depth` deep behind the face.
## `kind` is [course height (min, spread), length (min, spread), how
## far a block face may stand proud]; `salt` varies the pattern.
static func _lay(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, out: Vector3, depth: float,
		y0: float, y1: float, kind: Array, salt: int) -> void:
	var ch: Vector2 = kind[0]
	var bl: Vector2 = kind[1]
	var rough: float = kind[2]
	var dir := (b - a).normalized()
	var run := a.distance_to(b)
	var o := out.normalized()
	var bas := Basis(dir, Vector3.UP, o)
	var y := y0
	var row := 0
	while y < y1 - 0.01:
		var hh := minf(ch.x + ch.y * LandmarkGtUtil.hash01(row, salt), y1 - y)
		if y1 - y - hh < ch.x * 0.5:
			hh = y1 - y
		var t := 0.0
		var k := 0
		while t < run - 0.01:
			var w := minf(bl.x + bl.y * LandmarkGtUtil.hash01(row * 31 + k, salt + 7), run - t)
			if run - t - w < bl.x * 0.6:
				w = run - t
			var proud := rough * (LandmarkGtUtil.hash01(row * 57 + k, salt + 13) - 0.3)
			var c := a + dir * (t + w * 0.5) + Vector3(0, y + hh * 0.5, 0) - o * (depth * 0.5 - proud)
			lm.box(key, c, Vector3(w - 0.04, hh - 0.03, depth), bas)
			t += w
			k += 1
		y += hh
		row += 1

## The relieving slab over the lintel (front face at z = 0.05): the
## triangle itself, the double altar, the column tapering downward with
## its cushion capital, abacus and the four beam ends, and the two
## lionesses rearing against it (hind legs on the lintel, forepaws on
## the altars, necks raised toward the lost heads).
static func _relief(lm: LandmarkMesh) -> void:
	var z0 := 0.05
	var zb := -0.7
	var l := Vector3(-1.8, 4.1, z0)
	var r := Vector3(1.8, 4.1, z0)
	var t := Vector3(0, 7.4, z0)
	lm.tri("Relief", l, r, t, Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector2(0, 0), Vector2(3.6, 0), Vector2(1.8, -3.3))
	for s in [-1.0, 1.0]:
		var e: Vector3 = l if s < 0.0 else r
		var n := Vector3(s * 3.3, 1.8, 0).normalized()
		lm.quad("Relief", e, t, t + Vector3(0, 0, zb - z0), e + Vector3(0, 0, zb - z0), n)
	var f := z0 + 0.15
	for s in [-1.0, 1.0]:
		LandmarkGtUtil.block(lm, "Relief", s * 0.62 - 0.27, s * 0.62 + 0.27, 4.1, 4.5, z0, z0 + 0.25)
		LandmarkGtUtil.block(lm, "Relief", s * 0.62 - 0.33, s * 0.62 + 0.33, 4.5, 4.62, z0, z0 + 0.3)
	LandmarkGtUtil.block(lm, "Relief", -0.95, 0.95, 4.62, 4.7, z0, z0 + 0.3)
	lm.lathe("Relief", Vector3(0, 4.7, f - 0.1), PackedVector2Array([Vector2(0.2, 0), Vector2(0.2, 0.06),
		Vector2(0.15, 0.08), Vector2(0.22, 1.5), Vector2(0.24, 1.55), Vector2(0.32, 1.66), Vector2(0.3, 1.74)]), 16)
	LandmarkGtUtil.block(lm, "Relief", -0.38, 0.38, 6.44, 6.56, z0, z0 + 0.3)
	for k in 4:
		LandmarkGtUtil.cylinder(lm, "Relief", Vector3(-0.27 + 0.18 * float(k), 6.65, z0),
			Vector3(-0.27 + 0.18 * float(k), 6.65, z0 + 0.28), 0.075, 0.075, 8)
	LandmarkGtUtil.block(lm, "Relief", -0.45, 0.45, 6.74, 6.88, z0, z0 + 0.3)
	for s in [-1.0, 1.0]:
		var bk := Vector3.BACK
		var p := func(x: float, yy: float) -> Vector3:
			return Vector3(s * x, yy, f)
		lm.beam("Relief", p.call(1.45, 4.1), p.call(1.38, 4.8), 0.28, 0.17, bk)
		lm.beam("Relief", p.call(1.18, 4.1), p.call(1.26, 4.8), 0.28, 0.17, bk)
		lm.beam("Relief", p.call(1.38, 4.7), p.call(1.08, 5.15), 0.32, 0.48, bk)
		lm.beam("Relief", p.call(1.2, 4.98), p.call(0.66, 5.72), 0.34, 0.46, bk)
		lm.beam("Relief", p.call(0.7, 5.62), p.call(0.48, 6.02), 0.34, 0.42, bk)
		lm.beam("Relief", p.call(0.56, 5.58), p.call(0.42, 4.95), 0.26, 0.15, bk)
		lm.beam("Relief", p.call(0.42, 4.95), p.call(0.4, 4.7), 0.26, 0.13, bk)
		lm.beam("Relief", p.call(0.78, 5.4), p.call(0.66, 4.85), 0.24, 0.14, bk)
		lm.beam("Relief", p.call(0.66, 4.85), p.call(0.66, 4.62), 0.24, 0.12, bk)
		lm.beam("Relief", p.call(1.42, 4.9), p.call(1.62, 5.12), 0.12, 0.07, bk)
		lm.beam("Relief", p.call(1.62, 5.12), p.call(1.56, 5.45), 0.12, 0.07, bk)
		lm.beam("Relief", p.call(0.5, 5.98), p.call(0.48, 6.3), 0.3, 0.3, bk)

## Grave Circle A at `c`: the double ring of upright slabs 27.5 m across
## capped by horizontal slabs, its entrance toward the gate (+Z), and
## the outlines of the six shaft graves inside.
static func _grave_circle(lm: LandmarkMesh, c: Vector3) -> void:
	for ring in [13.75, 12.85]:
		var n := int(TAU * float(ring) / 1.05)
		for k in n:
			var a := TAU * (float(k) + 0.5) / float(n) + PI * 0.5
			var off := absf(wrapf(a - PI * 0.5, -PI, PI))
			if off < 0.1:
				continue
			var d := Vector3(cos(a), 0, sin(a))
			var hh := 1.15 + 0.25 * LandmarkGtUtil.hash01(k, int(ring))
			lm.box("Relief", c + d * float(ring) + Vector3(0, hh * 0.5, 0), Vector3(0.98, hh, 0.32),
				Basis(Vector3.UP, -a + PI * 0.5))
			if float(ring) > 13.0 and LandmarkGtUtil.hash01(k, 91) > 0.35:
				lm.box("Relief", c + d * 13.3 + Vector3(0, 1.48, 0), Vector3(1.0, 0.18, 1.25),
					Basis(Vector3.UP, -a + PI * 0.5))
	for g in 6:
		var gc := c + Vector3(-6.0 + 5.0 * float(g % 3), 0, -3.5 + (7.0 if g >= 3 else 0.0))
		var hx := 1.4 + 0.6 * LandmarkGtUtil.hash01(g, 3)
		var hz := 2.0 + 0.8 * LandmarkGtUtil.hash01(g, 4)
		for s in [-1.0, 1.0]:
			LandmarkGtUtil.block(lm, "Wall", gc.x - hx, gc.x + hx, 0.0, 0.45, gc.z + s * hz - 0.3, gc.z + s * hz + 0.3)
			LandmarkGtUtil.block(lm, "Wall", gc.x + s * hx - 0.3, gc.x + s * hx + 0.3, 0.0, 0.45, gc.z - hz, gc.z + hz)
		LandmarkGtUtil.block(lm, "Shadow", gc.x - hx + 0.3, gc.x + hx - 0.3, 0.0, 0.06, gc.z - hz + 0.3, gc.z + hz - 0.3)

## The Granary at `c`: rubble walls of its long rooms standing to about
## two metres just inside the gate.
static func _granary(lm: LandmarkMesh, c: Vector3) -> void:
	for w in [[-3.0, 3.0, -5.0, -4.3], [-3.0, 3.0, 4.3, 5.0], [-3.0, -2.3, -4.3, 4.3], [2.3, 3.0, -4.3, 4.3],
			[-2.3, 2.3, -0.35, 0.35]]:
		_lay(lm, "Wall", Vector3(c.x + w[0], 0, c.z + w[3]), Vector3(c.x + w[1], 0, c.z + w[3]), Vector3.BACK,
			float(w[3]) - float(w[2]), 0.0, 2.0, [Vector2(0.45, 0.2), Vector2(0.7, 0.6), 0.06], 31)

## Treasury of Atreus at `c` (the tholos centre), dromos and facade to
## +Z: the 36 m dromos, 6 m wide, between conglomerate ashlar walls that
## rise from 0.5 m at the open end to 10 m at the facade, the hill
## banked behind them; the 10.5 m facade with the 2.7 x 5.4 m door in
## its stepped frame, the 8 m lintel, the open relieving triangle, the
## green half-columns tapering downward beside the door, the smaller
## pair beside the triangle, the red bands of spiral slabs; the grassed
## mound over the 14.5 m tholos behind.
static func _atreus(lm: LandmarkMesh, c: Vector3) -> void:
	lm.lathe("Mound", c, PackedVector2Array([Vector2(16.0, 0), Vector2(15.4, 3.0), Vector2(13.6, 6.4),
		Vector2(10.0, 9.0), Vector2(5.0, 10.3), Vector2(0, 10.6)]), 32)
	var zf := c.z + 12.65
	var cx := c.x
	LandmarkGtUtil.block(lm, "Floor", cx - 3.0, cx + 3.0, 0.0, 0.05, zf, zf + 36.0)
	for s in [-1.0, 1.0]:
		var xf: float = cx + s * 3.0
		var y := 0.0
		var row := 0
		while y < 10.0 - 0.01:
			var hh := minf(0.75 + 0.15 * LandmarkGtUtil.hash01(row, 51 + int(s)), 10.0 - y)
			var top := y + hh
			var reach := 36.0 * clampf(1.0 - (top - 0.5) / 9.5, 0.04, 1.0)
			_lay(lm, "Conglom", Vector3(xf, 0, zf), Vector3(xf, 0, zf + reach), Vector3(-s, 0, 0), 2.6, y, top,
				ASHLAR, 60 + row * 3 + int(s))
			y = top
			row += 1
		# Hill banked behind the wall.
		var xo: float = cx + s * 5.6
		var xg: float = cx + s * 14.0
		lm.quad("Mound", Vector3(xo, 10.0, zf), Vector3(xo, 0.5, zf + 36.0), Vector3(xg, 0.0, zf + 36.0),
			Vector3(xg, 0.0, zf), Vector3(s * 9.5, 8.4, 0).normalized())
		lm.tri("Mound", Vector3(xo, 0.5, zf + 36.0), Vector3(xg, 0.0, zf + 36.0), Vector3(xo, 0.0, zf + 36.0),
			Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector2.ZERO, Vector2(8.4, 0), Vector2(0, -0.5))
	# Facade: masonry either side of the door (5.4 m deep passage), lintel,
	# courses round the open relieving triangle.
	for s in [-1.0, 1.0]:
		var x0: float = cx + s * 1.35
		var x1: float = cx + s * 3.0
		_lay(lm, "Conglom", Vector3(minf(x0, x1), 0, zf), Vector3(maxf(x0, x1), 0, zf), Vector3.BACK, 5.4, 0.0, 5.4,
			ASHLAR, 80 + int(s))
		# Stepped door frame (two fasciae).
		for k in 2:
			LandmarkGtUtil.block(lm, "Conglom", cx + s * (1.35 + 0.18 * float(k)) - 0.09, cx + s * (1.35 + 0.18 * float(k)) + 0.09,
				0.0, 5.4 + 0.18 * float(k), zf, zf + 0.08 * float(2 - k))
	LandmarkGtUtil.block(lm, "Shadow", cx - 1.35, cx + 1.35, 0.0, 5.4, zf - 5.4, zf - 5.3)
	for s in [-1.0, 1.0]:
		LandmarkGtUtil.block(lm, "Shadow", cx + s * 1.35 - 0.02, cx + s * 1.35 + 0.02, 0.0, 5.4, zf - 5.4, zf)
	LandmarkGtUtil.block(lm, "Conglom", cx - 3.0, cx + 3.0, 5.4, 6.6, zf - 5.4, zf + 0.1)
	var y2 := 6.6
	var r2 := 0
	while y2 < 10.5 - 0.01:
		var hh2 := minf(0.6, 10.5 - y2)
		var hw := maxf(1.5 * (1.0 - (y2 + hh2 * 0.5 - 6.6) / 3.2), 0.0)
		if hw < 0.05:
			LandmarkGtUtil.block(lm, "Conglom", cx - 3.0, cx + 3.0, y2, y2 + hh2 - 0.03, zf - 2.0, zf)
		else:
			LandmarkGtUtil.block(lm, "Conglom", cx - 3.0, cx - hw, y2, y2 + hh2 - 0.03, zf - 2.0, zf)
			LandmarkGtUtil.block(lm, "Conglom", cx + hw, cx + 3.0, y2, y2 + hh2 - 0.03, zf - 2.0, zf)
		y2 += hh2
		r2 += 1
	lm.tri("Shadow", Vector3(cx - 1.5, 6.6, zf - 1.9), Vector3(cx + 1.5, 6.6, zf - 1.9), Vector3(cx, 9.8, zf - 1.9),
		Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector2.ZERO, Vector2(3.0, 0), Vector2(1.5, -3.2))
	# Red spiral bands across the facade and the half-columns.
	LandmarkGtUtil.block(lm, "Red", cx - 3.0, cx + 3.0, 6.6, 7.0, zf, zf + 0.12)
	LandmarkGtUtil.block(lm, "Red", cx - 3.0, cx + 3.0, 10.1, 10.5, zf - 0.1, zf + 0.12)
	for k in 10:
		lm.disc("Red", Vector3(cx - 2.7 + 0.6 * float(k), 6.8, zf + 0.13), Vector3.BACK, 0.16, 10)
	for s in [-1.0, 1.0]:
		_half_column(lm, Vector3(cx + s * 2.05, 0, zf), 5.4, 0.36)
		_half_column(lm, Vector3(cx + s * 1.95, 7.0, zf), 3.0, 0.22)

## Engaged Mycenaean half-column at `base` against the facade (+Z):
## shaft swelling upward with zigzag bands, torus capital and abacus.
static func _half_column(lm: LandmarkMesh, base: Vector3, h: float, r: float) -> void:
	var cap := r * 1.1
	lm.lathe("Green", base, PackedVector2Array([Vector2(r * 1.25, 0), Vector2(r * 1.25, r * 0.25),
		Vector2(r * 0.85, r * 0.3), Vector2(r * 1.08, h - cap)]), 16)
	for k in 5:
		var yb := (h - cap) * (0.12 + 0.18 * float(k))
		var rr := lerpf(r * 0.85, r * 1.08, yb / (h - cap)) + 0.03
		lm.frustum("Green", base + Vector3(0, yb, 0), rr, rr, 0.08, 16)
	lm.lathe("Green", base + Vector3(0, h - cap, 0), PackedVector2Array([Vector2(r * 1.08, 0),
		Vector2(r * 1.4, cap * 0.35), Vector2(r * 1.35, cap * 0.6), Vector2(r * 1.1, cap * 0.65)]), 16)
	lm.box("Green", base + Vector3(0, h - cap * 0.17, 0), Vector3(r * 3.0, cap * 0.34, r * 2.2))
