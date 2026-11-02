class_name LandmarkAeTowers
extends RefCounted

## Skyscrapers of China and Taiwan in true metres: CCTV Headquarters
## (234 m: a three-dimensional loop; an L-shaped base, two towers each
## leaning about 6 degrees, and an L-shaped overhang whose corner
## cantilevers some 75 m, all wrapped in an irregular diagrid that
## thickens where the stresses run), Canton Tower (600 m: 24 inclined
## columns and 46 ring beams twisting 135 degrees between an 80 x 60 m
## base ellipse, the 30 m waist and the 54 x 41 m top, braced
## diagonally round an elliptical core, then the 146 m mast), Bank of
## China Tower in Hong Kong (367.4 m: a 52 m square cut on its
## diagonals into four triangular shafts ending at different heights in
## sloping glass tops, white X-braced 12-storey modules, twin masts)
## and Taipei 101 (508 m: a tapering 25-storey base, eight flared
## eight-storey pagoda segments with double-notched corners and ruyi
## emblems, the crown and the pinnacle).

# --- CCTV Headquarters ---

const CCTV_M := 234.0
const CCTV_H := 72.5
const CCTV_W := 50.0
const CCTV_LEAN := 20.0
const CCTV_BASE := 40.0
const CCTV_OVER := 180.0

static func cctv(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#4E6672"))
	lm.use("Frame", LandmarkMaterials.paint("#9AA2A8", 0.4, 0.6))
	var h := CCTV_H
	var w := CCTV_W
	var l := CCTV_LEAN
	# L-shaped base along the south and east edges.
	_block(lm, Rect2(-h, h - w, h * 2.0, w), 0.0, CCTV_BASE, Vector3.ZERO, 0)
	_block(lm, Rect2(h - w, -h, w, h * 2.0 - w), 0.0, CCTV_BASE, Vector3.ZERO, 1)
	# Tower 1 rises from the south-west corner leaning north, tower 2
	# from the north-east corner leaning west.
	_block(lm, Rect2(-h, h - w, w, w), CCTV_BASE, CCTV_OVER, Vector3(0, 0, -l), 2)
	_block(lm, Rect2(h - w, -h, w, w), CCTV_BASE, CCTV_OVER, Vector3(-l, 0, 0), 3)
	# L-shaped overhang along the west and north edges joining the tower
	# heads; its north-west corner hangs free.
	_block(lm, Rect2(-h, -h, w, h * 2.0 - l), CCTV_OVER, CCTV_M, Vector3.ZERO, 4)
	_block(lm, Rect2(-h + w, -h, h * 2.0 - w - l, w), CCTV_OVER, CCTV_M, Vector3.ZERO, 5)
	lm.commit(model)

## A block over the plan rectangle `r` (x, z) from y0 to y1 whose top is
## shifted by `lean` relative to its foot at y = 0 (so leaning towers
## keep a straight line from the ground). Glass faces wrapped in a
## diagrid of uneven density, a frame band at the top and foot.
static func _block(lm: LandmarkMesh, r: Rect2, y0: float, y1: float, lean: Vector3, seed: int) -> void:
	var s0 := lean * (y0 / CCTV_OVER)
	var s1 := lean * (y1 / CCTV_OVER)
	var c := [Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y),
		Vector2(r.position.x, r.end.y)]
	var lo := PackedVector2Array()
	var hi := PackedVector2Array()
	for p in c:
		var v: Vector2 = p
		lo.append(v + Vector2(s0.x, s0.z))
		hi.append(v + Vector2(s1.x, s1.z))
	LandmarkAeParts.poly_band(lm, "Glass", lo, y0, hi, y1)
	lm.poly_prism("Glass", hi, y1 - 0.5, y1)
	var ctr := Vector3((r.position.x + r.end.x) * 0.5, 0, (r.position.y + r.end.y) * 0.5)
	for i in 4:
		var k := (i + 1) % 4
		var a := Vector3(lo[i].x, maxf(y0, 0.8), lo[i].y)
		var b := Vector3(lo[k].x, maxf(y0, 0.8), lo[k].y)
		var q0 := Vector3(hi[i].x, y1, hi[i].y)
		var q1 := Vector3(hi[k].x, y1, hi[k].y)
		var mid := (a + b) * 0.5
		var out := Vector3(mid.x - ctr.x - s0.x, 0, mid.z - ctr.z - s0.z).normalized() * 0.35
		var strips := maxi(int(a.distance_to(b) / 18.0), 1)
		for j in strips:
			var t0 := float(j) / float(strips)
			var t1 := float(j + 1) / float(strips)
			# Denser cells low on the towers and at the overhang's root.
			var n := maxi(int((y1 - y0) / 14.0) - ((j + i + seed) % 3) * 2, 2)
			lm.lattice_panel("Frame", a.lerp(b, t0) + out, a.lerp(b, t1) + out, q0.lerp(q1, t0) + out,
				q0.lerp(q1, t1) + out, 0.9, n)
			lm.beam("Frame", a.lerp(b, t0) + out, q0.lerp(q1, t0) + out, 1.1, 0.6)
		lm.beam("Frame", a + out + Vector3(0, 0.6, 0), b + out + Vector3(0, 0.6, 0), 1.2, 0.6)

# --- Canton Tower ---

const CANTON_M := 600.0
const CANTON_BODY := 454.0
const CANTON_RINGS := 46
const CANTON_COLS := 24
static var CANTON_SCALE := PackedVector2Array([Vector2(0, 1.0), Vector2(0.3, 0.62),
	Vector2(0.617, 0.344), Vector2(0.82, 0.5), Vector2(1, 0.675)])

static func canton(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Frame", LandmarkMaterials.paint("#E4E3DE", 0.4, 0.5))
	lm.use("Core", LandmarkMaterials.pbr("concrete", "#BDBAB2", 4.0))
	lm.use("Deck", LandmarkMaterials.glass("#7E95A3"))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#CCC8BE", 4.0))
	var prev := _canton_ring(0.0)
	for j in CANTON_COLS:
		prev[j].y = 1.2
	for k in range(1, CANTON_RINGS + 1):
		var f := float(k) / CANTON_RINGS
		var cur := _canton_ring(f)
		var cr := lerpf(1.0, 0.6, f)
		for j in CANTON_COLS:
			var j1 := (j + 1) % CANTON_COLS
			LandmarkAeParts.tube(lm, "Frame", prev[j], cur[j], cr, cr * 0.97, 8)
			lm.beam("Frame", cur[j], cur[j1], 0.7, 0.9)
			lm.beam("Frame", prev[j], cur[j1], 0.45, 0.45)
		prev = cur
	lm.frustum("Core", Vector3.ZERO, 8.5, 8.5, CANTON_BODY, 24, 0.0, 1.0, 0.82)
	# Floor clusters on the core: lobby, the zones B, D and E, the open
	# skywalk between them and the top deck.
	for d in [[20.0, 30.0], [116.0, 56.0], [334.0, 40.0], [412.0, 38.0]]:
		var y0 := float(d[0])
		var y1 := y0 + float(d[1])
		var s := LandmarkMesh.profile_at(CANTON_SCALE, (y0 + y1) * 0.5 / CANTON_BODY)
		lm.frustum("Deck", Vector3(0, y0, 0), 34.0 * s, 34.0 * s, y1 - y0, 32, deg_to_rad(135.0) * y0 / CANTON_BODY, 1.0, 0.72)
		var fy := y0 + 4.0
		while fy < y1:
			lm.frustum("Frame", Vector3(0, fy, 0), 34.4 * s, 34.4 * s, 0.4, 32, deg_to_rad(135.0) * y0 / CANTON_BODY, 1.0, 0.72)
			fy += 8.0
	# Open-air deck on the top ring, then the mast with its galleries.
	var st := LandmarkMesh.profile_at(CANTON_SCALE, 1.0)
	lm.frustum("Frame", Vector3(0, CANTON_BODY - 1.0, 0), 39.0 * st, 39.0 * st, 1.0, 36, deg_to_rad(135.0), 1.0, 0.75)
	lm.lathe("Frame", Vector3(0, CANTON_BODY, 0), PackedVector2Array([Vector2(6.0, 0),
		Vector2(4.2, 55.0), Vector2(2.0, 105.0), Vector2(0.3, CANTON_M - CANTON_BODY)]), 12)
	for k in 6:
		var y := 10.0 + 16.0 * k
		var r := lerpf(6.0, 2.0, y / 105.0) + 1.0
		lm.frustum("Frame", Vector3(0, CANTON_BODY + y, 0), r, r, 1.2, 12)
	lm.box("Podium", Vector3(0, 4.0, 0), Vector3(110.0, 8.0, 80.0))
	lm.commit(model)

## The column points on the ellipse at height fraction f, turned through
## 135 degrees overall.
static func _canton_ring(f: float) -> Array[Vector3]:
	var s := LandmarkMesh.profile_at(CANTON_SCALE, f)
	var out: Array[Vector3] = []
	for j in CANTON_COLS:
		var a := TAU * float(j) / CANTON_COLS
		var p := Vector3(40.0 * s * cos(a), CANTON_BODY * f, 30.0 * s * sin(a))
		out.append(p.rotated(Vector3.UP, deg_to_rad(135.0) * f))
	return out

# --- Bank of China Tower, Hong Kong ---

const BOC_M := 367.4
## Apex heights of the shafts N, E, S, W (floors 70, 52, 38 and 25).
const BOC_H := [315.0, 234.0, 171.0, 113.0]
const BOC_SLOPE := 26.0
const BOC_MODULE := 52.0

static func bank_of_china(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#6F8A98"))
	lm.use("Frame", LandmarkMaterials.paint("#D2D6D8", 0.3, 0.8))
	lm.use("Podium", LandmarkMaterials.pbr("limestone", "#B8B2A6", 4.0))
	var hw := 26.0
	var corners := [Vector2(-hw, -hw), Vector2(hw, -hw), Vector2(hw, hw), Vector2(-hw, hw)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var h := float(BOC_H[i])
		var eave := h - BOC_SLOPE
		lm.poly_prism("Glass", PackedVector2Array([a, b, Vector2.ZERO]), 0.0, eave, false)
		# Sloping glass top: from the outer edge up to the apex at the centre.
		var A := Vector3(a.x, eave, a.y)
		var B := Vector3(b.x, eave, b.y)
		var O := Vector3(0, h, 0)
		var out := Vector3((a + b).x, 0, (a + b).y).normalized()
		lm.tri("Glass", A, B, O, (out + Vector3.UP).normalized(), (out + Vector3.UP).normalized(),
			(out + Vector3.UP).normalized(), Vector2.ZERO, Vector2(52, 0), Vector2(26, 37))
		# Inner faces exposed above lower neighbours, closed up to the slope.
		for side in 2:
			var edge: Vector2 = a if side == 0 else b
			var nb := float(BOC_H[(i + 3) % 4] if side == 0 else BOC_H[(i + 1) % 4])
			if h <= nb:
				continue
			var lo := nb - BOC_SLOPE
			var E := Vector3(edge.x, lo, edge.y)
			var n := Vector3(edge.x, 0, edge.y).cross(Vector3.UP).normalized() * (1.0 if side == 0 else -1.0)
			lm.quad("Glass", E, Vector3(0, nb, 0), O, Vector3(edge.x, eave, edge.y), n)
			lm.lattice_panel("Frame", E, Vector3(0, nb, 0), Vector3(edge.x, eave, edge.y), O, 1.4,
				maxi(int((h - nb) / 40.0), 1))
		# White X-braced modules on the outer face, mullions between.
		var face_n := out * 0.25
		var mods := maxi(int(round(eave / BOC_MODULE)), 1)
		lm.lattice_panel("Frame", A - Vector3(0, eave - 14.0, 0) + face_n, B - Vector3(0, eave - 14.0, 0) + face_n,
			A + face_n, B + face_n, 2.0, mods)
		var fy := 30.0
		while fy < eave - 4.0:
			lm.beam("Frame", Vector3(a.x, fy, a.y) + face_n * 0.6, Vector3(b.x, fy, b.y) + face_n * 0.6, 0.3, 0.3, Vector3.UP)
			fy += 16.0
		for m in 15:
			var t := float(m + 1) / 16.0
			var p := Vector3(a.x, 0, a.y).lerp(Vector3(b.x, 0, b.y), t) + face_n * 0.6
			lm.beam("Frame", p + Vector3(0, 14.0, 0), p + Vector3(0, eave, 0), 0.25, 0.3, out)
		for e in [A, B]:
			var ev: Vector3 = e
			lm.beam("Frame", ev + face_n - Vector3(0, eave - 14.0, 0), ev + face_n, 2.4, 2.4)
		lm.beam("Frame", A + face_n, O, 1.4, 1.0)
		lm.beam("Frame", B + face_n, O, 1.4, 1.0)
	# Twin masts on the apex of the tallest shaft.
	for x in [-5.0, 5.0]:
		lm.lathe("Frame", Vector3(x, float(BOC_H[0]) - 6.0, -10.0), PackedVector2Array([Vector2(1.2, 0),
			Vector2(0.7, 36.0), Vector2(0.12, BOC_M - float(BOC_H[0]) + 6.0)]), 10)
		for k in 3:
			lm.frustum("Frame", Vector3(x, float(BOC_H[0]) + 6.0 + 12.0 * k, -10.0), 1.0, 1.0, 0.6, 10)
	# Granite podium with its terraced base.
	lm.box("Podium", Vector3(0, 7.0, 0), Vector3(66.0, 14.0, 66.0))
	lm.box("Podium", Vector3(0, 1.5, 0), Vector3(76.0, 3.0, 76.0))
	lm.commit(model)

# --- Taipei 101 ---

const T101_M := 508.0
const T101_ROOF := 449.2

static func taipei_101(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#5E8F86"))
	lm.use("Frame", LandmarkMaterials.paint("#37464A", 0.4, 0.5))
	lm.use("Podium", LandmarkMaterials.pbr("limestone", "#C9C1B2", 4.0))
	lm.use("Mast", LandmarkMaterials.paint("#CDD1D4", 0.35, 0.7))
	lm.box("Podium", Vector3(0, 9.0, 0), Vector3(80.0, 18.0, 80.0))
	# Tapering 25-storey base, then the eight flared segments.
	_t101_stage(lm, 0.0, 96.0, 31.0, 25.0, 24)
	var y := 96.0
	for i in 8:
		_t101_stage(lm, y, 32.0, 21.5, 26.5, 8)
		LandmarkAeParts.poly_band(lm, "Frame", _t101_plan(26.8), y + 32.0, _t101_plan(22.0), y + 36.0)
		y += 36.0
	# Ruyi emblems on each face at the top of the base.
	for f in 4:
		var a := PI * 0.5 * f
		var n := Vector3(cos(a), 0, sin(a))
		var r := n.cross(Vector3.UP)
		var c := n * 26.0 + Vector3(0, 86.0, 0)
		lm.disc("Frame", c, n, 4.2, 24)
		for s in [-1.0, 1.0]:
			lm.disc("Frame", c + r * s * 4.6 + Vector3(0, 1.2, 0), n, 2.4, 16)
		lm.disc("Frame", c + Vector3(0, 4.4, 0) + n * 0.02, n, 2.6, 16)
		lm.beam("Frame", c - Vector3(0, 3.8, 0) + n * 0.1, c - Vector3(0, 9.0, 0) + n * 0.2, 1.2, 0.3, r)
	# Crown: four set-backs below the pinnacle.
	for step in [[22.0, 24.0], [20.0, 18.0], [17.0, 13.0], [13.6, T101_ROOF - 384.0 - 55.0]]:
		var sh := float(step[1])
		_t101_stage(lm, y, sh, float(step[0]), float(step[0]), maxi(int(sh / 4.4), 1))
		y += sh
	lm.lathe("Mast", Vector3(0, y, 0), PackedVector2Array([Vector2(4.5, 0), Vector2(4.0, 25.0),
		Vector2(2.0, 40.0), Vector2(0.4, T101_M - y)]), 12)
	for k in 5:
		var my := y + 8.0 * (k + 1)
		var mr := lerpf(4.5, 2.0, minf((my - y) / 40.0, 1.0)) + 0.6
		lm.frustum("Mast", Vector3(0, my, 0), mr, mr, 0.8, 12)
	lm.commit(model)

## A glass stage of the tower from y, `h` tall, half-width hw0 at the
## foot to hw1 at the head, in the double-notched plan, with a dark
## spandrel line at each of `floors` floors.
static func _t101_stage(lm: LandmarkMesh, y: float, h: float, hw0: float, hw1: float, floors: int) -> void:
	LandmarkAeParts.poly_band(lm, "Glass", _t101_plan(hw0), y, _t101_plan(hw1), y + h)
	lm.poly_prism("Glass", _t101_plan(hw1), y + h - 0.2, y + h)
	for k in range(1, floors):
		var t := float(k) / float(floors)
		var hw := lerpf(hw0, hw1, t) + 0.12
		LandmarkAeParts.poly_band(lm, "Frame", _t101_plan(hw), y + h * t - 0.35, _t101_plan(hw), y + h * t + 0.35)

## Square plan of half-width hw with two notches stepped into each
## corner (the "double notch" of the facade), counter-clockwise.
static func _t101_plan(hw: float) -> PackedVector2Array:
	var n := hw * 0.1
	var out := PackedVector2Array()
	for q in 4:
		var a := PI * 0.5 * q
		var u := Vector2(cos(a), sin(a))
		var v := Vector2(-sin(a), cos(a))
		for p in [Vector2(hw, hw - 2.0 * n), Vector2(hw - n, hw - 2.0 * n), Vector2(hw - n, hw - n),
				Vector2(hw - 2.0 * n, hw - n), Vector2(hw - 2.0 * n, hw)]:
			var pv: Vector2 = p
			out.append(u * pv.x + v * pv.y)
	return out
