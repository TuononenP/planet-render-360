class_name LandmarkNaCivil
extends RefCounted

## Four landmarks of the open air in true metres: the Gateway Arch in
## St. Louis, Hoover Dam, the Hollywood Sign and Chichén Itzá's El Castillo.

const ARCH_TOP_M := 192.0
const HOOVER_TOP_M := 27.0
const HOLLYWOOD_M := 13.7

## Gateway Arch: the 192 m weighted catenary (centreline
## y = 693.86 − 68.77·cosh(0.01003 x) ft) of stainless-steel triangular
## section, 16.5 m a side at the foot tapering to 5.2 m at the crown, with
## its footings. The arch stands in the north-south plane (legs along ±Z).
static func gateway_arch(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#C4C8CC", 0.22, 0.9))
	lm.use("Base", LandmarkMaterials.pbr("concrete", "#9E9A92", 4.0))
	var ft := 0.3048
	var steps := 64
	var centre: Array[Vector3] = []
	for i in steps + 1:
		var x := -299.2668 + 598.5336 * float(i) / float(steps)
		centre.append(Vector3(0, (693.8597 - 68.7672 * cosh(0.0100333 * x)) * ft, x * ft))
	var y_top := centre[steps / 2].y
	var rings: Array = []
	var cs: Array[Vector3] = []
	var shift := 0.0
	for pass_i in 2:
		rings.clear()
		cs.clear()
		for i in steps + 1:
			var t := centre[mini(i + 1, steps)] - centre[maxi(i - 1, 0)]
			var n := Vector3(0, t.z, -t.y).normalized()
			var u := centre[i].y / y_top
			var side := lerpf(17.0, 54.0, pow(1.0 - u, 1.1)) * ft
			var h := side * 0.866
			var c := centre[i] + Vector3(0, shift, 0)
			rings.append([c + n * h * 0.6667, c - n * h * 0.3333 + Vector3(side * 0.5, 0, 0),
				c - n * h * 0.3333 - Vector3(side * 0.5, 0, 0)])
			cs.append(c)
		if pass_i == 0:
			var ymax := -INF
			for ring in rings:
				for v in ring:
					ymax = maxf(ymax, (v as Vector3).y)
			shift = ARCH_TOP_M - ymax
	for i in steps:
		var r0: Array = rings[i]
		var r1: Array = rings[i + 1]
		var mid := (cs[i] + cs[i + 1]) * 0.5
		for a in 3:
			var b := (a + 1) % 3
			var p: Vector3 = r0[a]
			var q: Vector3 = r0[b]
			var pn: Vector3 = r1[a]
			var qn: Vector3 = r1[b]
			var n := (pn - p).cross(q - p).normalized()
			if n.dot((p + q + pn + qn) * 0.25 - mid) < 0.0:
				n = -n
			lm.quad("Steel", p, q, qn, pn, n)
	for s in [-1.0, 1.0]:
		lm.box("Base", Vector3(0, -1.5, s * 91.2), Vector3(24.0, 3.0, 22.0))
	lm.commit(model)

## Hoover Dam: the curved concrete gravity-arch wall bowing upstream
## (north, −Z) from the canyon rock, 13.7 m thick on the crest and
## widening to 200 m at the foot 221 m below the crest (y = 0), the
## roadway along the top and the four Art Deco intake towers standing in
## the lake above it.
static func hoover_dam(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B8B3A7", 8.0))
	lm.use("Tower", LandmarkMaterials.pbr("limestone", "#CDC3AE", 4.0))
	lm.use("Road", LandmarkMaterials.pbr("asphalt", "#3C3C3E", 4.0))
	var radius := 380.0
	var depth := 221.0
	var theta0 := asin(189.5 / radius)
	var up_rows: Array = []
	var dn_rows: Array = []
	for j in 11:
		var d := depth * float(j) / 10.0
		var ang := theta0 * (1.0 - 0.82 * d / depth)
		var thick := 13.7 + (201.0 - 13.7) * pow(d / depth, 1.5)
		var up := PackedVector3Array()
		var dn := PackedVector3Array()
		for k in 25:
			var th := -ang + 2.0 * ang * float(k) / 24.0
			up.append(Vector3(radius * sin(th), -d, radius - radius * cos(th)))
			dn.append(Vector3((radius - thick) * sin(th), -d, radius - (radius - thick) * cos(th)))
		up_rows.append(up)
		dn_rows.append(dn)
	lm.grid("Concrete", up_rows, Vector3(0, 0, -1))
	lm.grid("Concrete", dn_rows, Vector3(0, 0, 1))
	var up0: PackedVector3Array = up_rows[0]
	var dn0: PackedVector3Array = dn_rows[0]
	for k in 24:
		lm.quad("Concrete", up0[k], up0[k + 1], dn0[k + 1], dn0[k], Vector3.UP)
		var a := Vector3(0, 0.06, 0)
		var ra := radius - 2.0
		var rb := radius - 11.7
		var t0 := asin(189.5 / radius) * (-1.0 + 2.0 * float(k) / 24.0)
		var t1 := asin(189.5 / radius) * (-1.0 + 2.0 * float(k + 1) / 24.0)
		lm.quad("Road", a + Vector3(ra * sin(t0), 0, radius - ra * cos(t0)),
			a + Vector3(ra * sin(t1), 0, radius - ra * cos(t1)),
			a + Vector3(rb * sin(t1), 0, radius - rb * cos(t1)),
			a + Vector3(rb * sin(t0), 0, radius - rb * cos(t0)), Vector3.UP)
	# Intake towers: round shafts rising from the lake, capped and roofed.
	for ang_deg in [-22.0, -15.0, 15.0, 22.0]:
		var th := deg_to_rad(ang_deg)
		var rt := radius + 9.0
		var p := Vector3(rt * sin(th), 0, radius - rt * cos(th))
		lm.frustum("Tower", p + Vector3(0, -120.0, 0), 7.5, 7.0, 140.0, 16)
		lm.frustum("Tower", p + Vector3(0, 20.0, 0), 8.6, 8.6, 2.5, 16)
		lm.lathe("Tower", p + Vector3(0, 22.5, 0), PackedVector2Array([Vector2(8.0, 0.0),
			Vector2(5.0, 2.0), Vector2(2.2, HOOVER_TOP_M - 22.5)]), 16)
		var crest := Vector3((radius - 6.0) * sin(th), 8.0, radius - (radius - 6.0) * cos(th))
		lm.beam("Tower", p + Vector3(0, 8.0, 0), crest, 4.0, 3.0)
	lm.commit(model)

## Hollywood Sign: nine white sheet-metal letters 13.7 m tall in a row
## 106 m long, facing south (+Z), each on a concrete footing with steel
## back-bracing running down the slope.
static func hollywood_sign(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Letter", LandmarkMaterials.paint("#F2F1EC", 0.55, 0.15))
	lm.use("Frame", LandmarkMaterials.paint("#6C7074", 0.6, 0.5))
	lm.use("Footing", LandmarkMaterials.pbr("concrete", "#A29D94", 3.0))
	# Centre-line strokes in letter space (u across, v up), one entry per
	# stroke as [u0, v0, u1, v1].
	var o := [[0.25, 0.0, 0.75, 0.0], [0.75, 0.0, 1.0, 0.18], [1.0, 0.18, 1.0, 0.82],
		[1.0, 0.82, 0.75, 1.0], [0.75, 1.0, 0.25, 1.0], [0.25, 1.0, 0.0, 0.82],
		[0.0, 0.82, 0.0, 0.18], [0.0, 0.18, 0.25, 0.0]]
	var letters := [
		[9.2, [[0, 0, 0, 1], [1, 0, 1, 1], [0, 0.5, 1, 0.5]]], [9.8, o],
		[7.4, [[0, 0, 0, 1], [0, 0, 1, 0]]], [7.4, [[0, 0, 0, 1], [0, 0, 1, 0]]],
		[10.4, [[0, 1, 0.5, 0.5], [1, 1, 0.5, 0.5], [0.5, 0.5, 0.5, 0]]],
		[13.6, [[0, 1, 0.25, 0], [0.25, 0, 0.5, 0.65], [0.5, 0.65, 0.75, 0], [0.75, 0, 1, 1]]],
		[9.8, o], [9.8, o],
		[9.2, [[0, 0, 0, 1], [0, 1, 0.55, 1], [0.55, 1, 1, 0.8], [1, 0.8, 1, 0.2],
			[1, 0.2, 0.55, 0], [0.55, 0, 0, 0]]]]
	var gap := 2.4
	var total := gap * 8.0
	for l in letters:
		total += float(l[0])
	var x0 := -total * 0.5
	var s := 2.4
	for l in letters:
		var w: float = l[0]
		for st in l[1]:
			var a := Vector3(x0 + s * 0.5 + float(st[0]) * (w - s), s * 0.5 + float(st[1]) * (HOLLYWOOD_M - s), 0)
			var b := Vector3(x0 + s * 0.5 + float(st[2]) * (w - s), s * 0.5 + float(st[3]) * (HOLLYWOOD_M - s), 0)
			lm.beam("Letter", a, b, 0.9, s, Vector3.BACK, true)
		var cx := x0 + w * 0.5
		lm.box("Footing", Vector3(cx, -1.5, -1.5), Vector3(w + 1.0, 3.0, 5.0))
		for dx in [-0.3, 0.3]:
			lm.beam("Frame", Vector3(cx + dx * w, HOLLYWOOD_M - 3.0, -0.6),
				Vector3(cx + dx * w, -2.0, -6.0), 0.5, 0.5)
		x0 += w + gap
	lm.commit(model)

## Chichén Itzá, El Castillo: the nine-terrace stepped pyramid (55 m
## square, 24 m high) with the four 91-step stairways (balustrades
## and serpent heads at the foot) and the 6 m temple of Kukulcán on
## top with a doorway on each side, to 30 m.
static func el_castillo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#BDB39B", 4.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#CEC5AD", 3.0))
	lm.use("Door", LandmarkMaterials.glass("#1F2528"))
	var tier_h := 24.0 / 9.0
	for k in 9:
		var hw := 27.65 - 2.0 * float(k)
		lm.box("Stone", Vector3(0, tier_h * (float(k) + 0.5), 0), Vector3(hw * 2.0, tier_h, hw * 2.0))
	var n := 45
	var rise := 24.0 / float(n)
	var run := (27.65 - 11.65) / float(n)
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(q))
		for i in n:
			var top := rise * float(i + 1)
			lm.box("Steps", r * Vector3(0, top * 0.5, 27.9 - run * (float(i) + 0.5)),
				Vector3(9.0, top, run + 0.05), r)
		for sx in [-1.0, 1.0]:
			lm.beam("Stone", r * Vector3(sx * 5.4, 0.8, 28.4), r * Vector3(sx * 5.4, 24.8, 11.2), 1.6, 1.6)
			lm.box("Stone", r * Vector3(sx * 5.4, 1.2, 29.2), Vector3(1.8, 2.4, 2.4), r)
		lm.box("Door", r * Vector3(0, 26.0, 6.55), Vector3(3.6, 3.8, 0.3), r)
	lm.box("Stone", Vector3(0, 26.5, 0), Vector3(13.0, 5.0, 13.0))
	lm.box("Stone", Vector3(0, 29.5, 0), Vector3(14.4, 1.0, 14.4))
	lm.commit(model)
