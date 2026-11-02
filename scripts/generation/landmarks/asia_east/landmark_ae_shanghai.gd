class_name LandmarkAeShanghai
extends RefCounted

## The Shanghai Pudong skyline in true metres: the Oriental Pearl Tower
## (468 m: three 9 m columns from the ground to the upper sphere, three
## raking 7 m legs, the 50 m lower and 45 m upper spheres with their
## glazed observation belts, five small spheres on the columns, the
## 14 m space module and the antenna), Shanghai Tower (632 m: nine
## zones of a rounded triangle with its vertical notch twisting 120
## degrees while it tapers, stacked curtain-wall rings and the sloping
## crown), the Shanghai World Financial Center (492 m: a 58 m square
## prism cut by two sweeping arcs into a knife edge, the trapezoid
## aperture at its crown) and the Jin Mao Tower (420.5 m: 13 octagonal
## pagoda tiers, each shorter than the last, with flared setbacks and
## mullion fins, then the stepped crown and steel spire).

# --- Oriental Pearl Tower ---

const PEARL_M := 468.0

static func pearl(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#D4D0C8", 4.0))
	lm.use("Pearl", LandmarkMaterials.pbr("render", "#C24F78", 3.0, 0.22, 0.35))
	lm.use("Mast", LandmarkMaterials.paint("#DADDE0", 0.4, 0.6))
	lm.use("Glass", LandmarkMaterials.glass("#5A6670"))
	for i in 3:
		var a := TAU * i / 3.0 + PI * 0.5
		var dir := Vector3(cos(a), 0, sin(a))
		var side := dir.cross(Vector3.UP)
		# Raking leg from its footing to the lower sphere.
		lm.frustum("Concrete", dir * 40.0, 6.0, 5.6, 2.0, 16)
		LandmarkAeParts.tube(lm, "Concrete", dir * 40.0 + Vector3(0, 1.5, 0), dir * 12.0 + Vector3(0, 74.0, 0), 3.5, 3.5, 16)
		# Column from the ground to the upper sphere.
		LandmarkAeParts.tube(lm, "Concrete", dir * 11.0, dir * 11.0 + Vector3(0, 252.0, 0), 4.5, 4.2, 20)
		# Tie girders between the columns.
		var nxt := Vector3(cos(a + TAU / 3.0), 0, sin(a + TAU / 3.0)) * 11.0
		for y in [30.0, 55.0, 128.0, 180.0, 232.0]:
			lm.beam("Concrete", dir * 11.0 + Vector3(0, y, 0), nxt + Vector3(0, y, 0), 2.4, 3.0, Vector3.UP)
		# Small spheres on the columns, spiralling up between the great ones.
		LandmarkAeParts.ball(lm, "Pearl", dir * 11.0 + side * 3.0 + Vector3(0, 150.0, 0), 7.0, 20, 10)
		_ribs(lm, dir * 11.0 + side * 3.0 + Vector3(0, 150.0, 0), 7.0, 3)
		if i < 2:
			LandmarkAeParts.ball(lm, "Pearl", dir * 11.0 - side * 3.0 + Vector3(0, 205.0, 0), 6.0, 20, 10)
			_ribs(lm, dir * 11.0 - side * 3.0 + Vector3(0, 205.0, 0), 6.0, 3)
	# The two great spheres with observation belts, and the central lift shaft.
	lm.frustum("Concrete", Vector3.ZERO, 5.0, 4.6, 290.0, 16)
	_sphere(lm, Vector3(0, 93.0, 0), 25.0, [-4.0, 4.0])
	_sphere(lm, Vector3(0, 267.0, 0), 22.5, [-6.0, 0.0, 5.0])
	lm.frustum("Concrete", Vector3(0, 285.0, 0), 5.5, 4.0, 60.0, 20)
	for y in [300.0, 318.0, 335.0]:
		lm.frustum("Mast", Vector3(0, y, 0), 6.2, 6.0, 1.2, 20)
	# Space module and the antenna with its gallery rings.
	_sphere(lm, Vector3(0, 350.0, 0), 7.5, [0.0])
	lm.lathe("Mast", Vector3(0, 357.0, 0), PackedVector2Array([Vector2(3.4, 0), Vector2(2.6, 40.0),
		Vector2(1.5, 80.0), Vector2(0.4, PEARL_M - 357.0)]), 16)
	for k in 6:
		var y := 362.0 + 14.0 * k
		var r := lerpf(3.4, 1.5, (y - 357.0) / 80.0) + 1.0
		lm.frustum("Mast", Vector3(0, y, 0), r, r, 1.0, 16)
	# Base hall between the legs.
	lm.frustum("Concrete", Vector3.ZERO, 26.0, 24.0, 8.0, 36)
	lm.commit(model)

## Pink-glass sphere of radius r at c with meridian ribs and a glazed
## observation belt at each offset in `belts` (from the centre).
static func _sphere(lm: LandmarkMesh, c: Vector3, r: float, belts: Array) -> void:
	LandmarkAeParts.ball(lm, "Pearl", c, r, 40, 20)
	_ribs(lm, c, r, 12)
	for b in belts:
		var y := float(b)
		var rr := sqrt(maxf(r * r - y * y, 0.0)) + 0.25
		lm.frustum("Glass", c + Vector3(0, y - 1.4, 0), rr, rr, 2.8, 40)
		lm.frustum("Mast", c + Vector3(0, y + 1.4, 0), rr + 0.3, rr + 0.3, 0.4, 40)

## `n` meridian frame ribs over a sphere of radius r at c.
static func _ribs(lm: LandmarkMesh, c: Vector3, r: float, n: int) -> void:
	for i in n:
		var a := TAU * float(i) / float(n)
		var d := Vector3(cos(a), 0, sin(a))
		var prev := c + Vector3(0, -r, 0)
		for k in range(1, 9):
			var phi := PI * float(k) / 8.0
			var p := c + d * sin(phi) * (r + 0.1) - Vector3(0, cos(phi) * (r + 0.1), 0)
			lm.beam("Mast", prev, p, maxf(r * 0.025, 0.15), maxf(r * 0.02, 0.12), d.cross(Vector3.UP))
			prev = p

# --- Shanghai Tower ---

const SH_M := 632.0
const SH_ROOF := 580.0
const SH_ZONES := 9
const SH_TWIST := TAU / 3.0
const SH_PTS := 72
static var SH_SCALE := PackedVector2Array([Vector2(0, 1.0), Vector2(0.2, 0.93),
	Vector2(0.4, 0.8), Vector2(0.6, 0.62), Vector2(0.8, 0.42), Vector2(0.95, 0.26), Vector2(1, 0.22)])

static func shanghai_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#8FA6B3"))
	lm.use("Band", LandmarkMaterials.paint("#C5CBD0", 0.35, 0.8))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#CFCBC2", 4.0))
	# The outer skin up to the roof, then the crown whose rim slopes from
	# 600 m on one side to the 632 m tip on the other.
	var slices := 64
	var rings: Array = []
	for k in slices + 1:
		rings.append(_sh_ring(SH_ROOF / SH_M * float(k) / slices, 1.0))
	var crown := 6
	for k in range(1, crown + 1):
		var t := float(k) / crown
		var f := SH_ROOF / SH_M + (1.0 - SH_ROOF / SH_M) * t
		var r := _sh_ring(f, 1.0)
		for i in r.size():
			var th := TAU * float(i) / SH_PTS + SH_TWIST * f
			var cut := lerpf(SH_ROOF, 600.0 + 32.0 * (0.5 + 0.5 * cos(th)), t)
			r[i] = Vector3(r[i].x, minf(r[i].y, cut), r[i].z)
		rings.append(r)
	LandmarkAeParts.loft(lm, "Glass", rings, false)
	lm.lathe("Band", Vector3(0, SH_ROOF - 1.0, 0), PackedVector2Array([Vector2(0.0, 0.0),
		Vector2(42.0 * LandmarkMesh.profile_at(SH_SCALE, SH_ROOF / SH_M) * 0.75, 0.0),
		Vector2(42.0 * LandmarkMesh.profile_at(SH_SCALE, SH_ROOF / SH_M) * 0.75, 1.0)]), 36)
	# Curtain-wall support rings every third floor, sky-lobby belts at
	# the top of each zone.
	var y := 13.5
	while y < SH_ROOF - 5.0:
		var f := y / SH_M
		LandmarkAeParts.loft(lm, "Band", [_sh_ring(f, 1.008), _sh_ring(f + 0.6 / SH_M, 1.008)], false)
		y += 13.5
	for z in range(1, SH_ZONES):
		var f := float(z) / SH_ZONES * SH_ROOF / SH_M
		LandmarkAeParts.loft(lm, "Band", [_sh_ring(f, 1.025), _sh_ring(f + 4.5 / SH_M, 1.025)], false)
	lm.frustum("Podium", Vector3.ZERO, 50.0, 48.0, 22.0, 48)
	lm.frustum("Band", Vector3(0, 22.0, 0), 50.5, 50.5, 1.0, 48)
	lm.commit(model)

## Rounded-triangle section with the vertical notch at one corner, at
## height fraction f (scaled by `grow`).
static func _sh_ring(f: float, grow: float) -> PackedVector3Array:
	var r0 := 42.0 * LandmarkMesh.profile_at(SH_SCALE, f) * grow
	var shape: Callable = func(th: float) -> float:
		var d := wrapf(th, -PI, PI)
		return r0 * (0.8 + 0.2 * cos(3.0 * th)) * (1.0 - 0.1 * exp(-pow(d / 0.07, 2.0)))
	return LandmarkAeParts.ring(SH_PTS, SH_M * f, shape, SH_TWIST * f)

# --- Shanghai World Financial Center ---

const SWFC_M := 492.0
const SWFC_AP0 := 440.0
const SWFC_AP1 := 472.0
## Half-diagonal of the 58 m square base (diagonals along x and z).
const SWFC_HD := 41.0

static func swfc(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#9DB0BA"))
	lm.use("Frame", LandmarkMaterials.paint("#B9C0C5", 0.35, 0.8))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#CBC7BE", 4.0))
	# Shaft: the square clipped by the two arcs (|z| <= hz), banded every
	# floor group with a frame line, mullions on its six edges.
	var n := 48
	var prev := _swfc_hex(0.0)
	for k in range(1, n + 1):
		var y := SWFC_AP0 * float(k) / n
		var cur := _swfc_hex(y)
		_band(lm, "Glass", prev, cur)
		var fl := _swfc_hex(y - 1.0)
		_band(lm, "Frame", _grow(fl, 0.4), _grow(cur, 0.4))
		for i in 6:
			lm.beam("Frame", prev[i] + Vector3(0, 0.6 if k == 1 else 0.0, 0), cur[i], 0.8, 0.8)
		# Vertical mullions every other band: six on each square side,
		# four on the long faces the arcs open up.
		if k % 2 == 0:
			var low := _swfc_hex(y - SWFC_AP0 * 2.0 / n)
			for i in 6:
				var j := (i + 1) % 6
				var m := 4 if i == 1 or i == 4 else 6
				for q in m:
					var t := (float(q) + 0.5) / float(m)
					var a := low[i].lerp(low[j], t) + Vector3(0, 0.5 if k == 2 else 0.0, 0)
					var b := cur[i].lerp(cur[j], t)
					var out := Vector3((a + b).x, 0, (a + b).z).normalized()
					lm.beam("Frame", a + out * 0.2, b + out * 0.2, 0.35, 0.5, out)
		prev = cur
	# Crown: the two piers either side of the trapezoid aperture, the
	# bridge over it and the observation deck across its foot.
	var steps := 12
	for k in steps:
		var y0 := lerpf(SWFC_AP0, SWFC_AP1, float(k) / steps)
		var y1 := lerpf(SWFC_AP0, SWFC_AP1, float(k + 1) / steps)
		var ap := lerpf(30.0, 48.0, (float(k) + 0.5) / steps) * 0.5
		var hz := _swfc_hz((y0 + y1) * 0.5)
		for s in [-1.0, 1.0]:
			var poly := PackedVector2Array([Vector2(ap, -hz), Vector2(SWFC_HD - hz, -hz), Vector2(SWFC_HD, 0),
				Vector2(SWFC_HD - hz, hz), Vector2(ap, hz)])
			if s < 0.0:
				for i in poly.size():
					poly[i] = Vector2(-poly[i].x, poly[i].y)
			lm.poly_prism("Glass", poly, y0, y1)
			lm.box("Frame", Vector3(s * ap, (y0 + y1) * 0.5, 0), Vector3(0.6, y1 - y0, hz * 2.0 + 0.4), Basis(), 0.0)
	var hz_top := _swfc_hz(SWFC_AP1)
	var top := PackedVector2Array([Vector2(SWFC_HD, 0), Vector2(SWFC_HD - hz_top, hz_top), Vector2(-SWFC_HD + hz_top, hz_top),
		Vector2(-SWFC_HD, 0), Vector2(-SWFC_HD + hz_top, -hz_top), Vector2(SWFC_HD - hz_top, -hz_top)])
	lm.poly_prism("Frame", top, SWFC_AP1, SWFC_M)
	lm.box("Frame", Vector3(0, SWFC_AP0 + 1.5, 0), Vector3(30.0, 3.0, _swfc_hz(SWFC_AP0) * 2.0))
	lm.box("Podium", Vector3(0, 9.0, 0), Vector3(84.0, 18.0, 84.0))
	lm.commit(model)

static func _swfc_hz(y: float) -> float:
	return SWFC_HD - (SWFC_HD - 4.5) * pow(clampf(y / SWFC_M, 0.0, 1.0), 1.5)

## Hexagon section at height y: the square (diagonals on the axes)
## clipped to |z| <= hz(y).
static func _swfc_hex(y: float) -> PackedVector3Array:
	var hz := _swfc_hz(y)
	var a := SWFC_HD - hz
	return PackedVector3Array([Vector3(SWFC_HD, y, 0), Vector3(a, y, hz), Vector3(-a, y, hz),
		Vector3(-SWFC_HD, y, 0), Vector3(-a, y, -hz), Vector3(a, y, -hz)])

static func _grow(r: PackedVector3Array, d: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	for p in r:
		var h := Vector3(p.x, 0, p.z)
		out.append(p + h.normalized() * d)
	return out

## Flat-faced band between two closed rings of equal size.
static func _band(lm: LandmarkMesh, key: String, r0: PackedVector3Array, r1: PackedVector3Array) -> void:
	for i in r0.size():
		var k := (i + 1) % r0.size()
		var mid := (r0[i] + r0[k]) * 0.5
		var out := Vector3(mid.x, 0, mid.z).normalized()
		lm.quad(key, r0[i], r0[k], r1[k], r1[i], out)

# --- Jin Mao Tower ---

const JM_M := 420.5
const JM_TIERS := 13

static func jin_mao(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#A7B4BC"))
	lm.use("Frame", LandmarkMaterials.paint("#AEB4B8", 0.35, 0.8))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#C9C4BA", 4.0))
	var y := 0.0
	for i in JM_TIERS:
		var hw := 27.0 - 1.1 * i
		var h := 36.0 - 1.3 * i
		var r := hw / cos(PI / 8.0)
		lm.frustum("Glass", Vector3(0, y, 0), r, r * 0.985, h - 1.4, 8, PI / 8.0)
		# Flared setback ledge, and the aluminium fins up each face.
		lm.frustum("Frame", Vector3(0, y + h - 1.4, 0), r * 1.0, r * 1.07, 1.4, 8, PI / 8.0)
		for f in 8:
			var a0 := TAU * float(f) / 8.0 + PI / 8.0
			var a1 := a0 + TAU / 8.0
			var p0 := Vector3(cos(a0), 0, sin(a0))
			var p1 := Vector3(cos(a1), 0, sin(a1))
			var out := ((p0 + p1) * 0.5).normalized()
			for m in 4:
				var t := (float(m) + 0.5) / 4.0
				var b := p0.lerp(p1, t) * r + out * 0.4
				var tp := p0.lerp(p1, t) * r * 0.985 + out * 0.4
				lm.beam("Frame", b + Vector3(0, y + 0.4, 0), tp + Vector3(0, y + h - 1.4, 0), 0.5, 0.8, out)
		y += h
	# Crown: stepped octagonal tiers, the lantern, the steel spire.
	for k in 5:
		var r := (13.5 - 1.6 * k) / cos(PI / 8.0)
		lm.frustum("Glass", Vector3(0, y, 0), r, r * 0.97, 3.6, 8, PI / 8.0)
		lm.frustum("Frame", Vector3(0, y + 3.6, 0), r, r * 1.06, 0.8, 8, PI / 8.0)
		y += 4.4
	lm.frustum("Glass", Vector3(0, y, 0), 6.0, 4.6, 8.0, 8, PI / 8.0)
	lm.lathe("Frame", Vector3(0, y + 8.0, 0), PackedVector2Array([Vector2(3.4, 0),
		Vector2(2.2, (JM_M - y - 8.0) * 0.5), Vector2(0.3, JM_M - y - 8.0)]), 10)
	for k in 4:
		var sy := y + 8.0 + (JM_M - y - 8.0) * 0.12 * (k + 1)
		lm.frustum("Frame", Vector3(0, sy, 0), 3.4 - 0.4 * k, 3.4 - 0.4 * k, 0.6, 10)
	lm.frustum("Podium", Vector3.ZERO, 44.0, 42.0, 10.0, 8, PI / 8.0)
	lm.commit(model)
