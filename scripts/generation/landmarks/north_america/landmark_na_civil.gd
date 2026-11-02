class_name LandmarkNaCivil
extends RefCounted

## Three landmarks of the open air in true metres: the Gateway Arch in
## St. Louis, Hoover Dam and the Hollywood Sign. (Chichén Itzá's El
## Castillo is in LandmarkNaCastillo.)

const ARCH_TOP_M := 192.0
const ARCH_SECTIONS := 142
const HOOVER_TOP_M := 27.0
const HOLLYWOOD_M := 13.7

## Gateway Arch (1965, Eero Saarinen): the 192 m weighted catenary
## (centreline y = 693.86 − 68.77·cosh(0.01003 x) ft) of stainless-steel
## equilateral-triangle section, 16.5 m a side at the foot tapering to
## 5.2 m at the crown, built of 142 stacked sections (71 a leg) whose
## welded joints ring the legs; the 32 slot windows of the observation
## room at the top (16 each side), the granite footing pads, and the
## round sunken west entrance of the museum between the legs. The arch
## stands in the north-south plane (legs along ±Z), facing east to the
## Mississippi.
static func gateway_arch(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#C4C8CC", 0.22, 0.9))
	lm.use("Base", LandmarkMaterials.pbr("concrete", "#9E9A92", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E3A40"))
	var ft := 0.3048
	var steps := ARCH_SECTIONS
	var centre: Array[Vector3] = []
	for i in steps + 1:
		var x := -299.2668 + 598.5336 * float(i) / float(steps)
		centre.append(Vector3(0, (693.8597 - 68.7672 * cosh(0.0100333 * x)) * ft, x * ft))
	var y_top := centre[steps / 2].y
	var rings: Array = []
	var cs: Array[Vector3] = []
	var ns: Array[Vector3] = []
	var shift := 0.0
	for pass_i in 2:
		rings.clear()
		cs.clear()
		ns.clear()
		for i in steps + 1:
			var t := centre[mini(i + 1, steps)] - centre[maxi(i - 1, 0)]
			var n := Vector3(0, t.z, -t.y).normalized()
			var u := centre[i].y / y_top
			var side := lerpf(17.0, 54.0, pow(1.0 - u, 1.1)) * ft
			var h := side * 0.866
			var c := centre[i] + Vector3(0, shift, 0)
			var tri_pts: Array = [c + n * h * 0.6667, c - n * h * 0.3333 + Vector3(side * 0.5, 0, 0),
				c - n * h * 0.3333 - Vector3(side * 0.5, 0, 0)]
			if pass_i == 1:
				# The legs are cut off where they meet the ground.
				for v in 3:
					var pv: Vector3 = tri_pts[v]
					pv.y = maxf(pv.y, 0.0)
					tri_pts[v] = pv
			rings.append(tri_pts)
			cs.append(c)
			ns.append(n)
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
	# Section joints: a slightly proud weld band round every joint.
	for i in range(1, steps):
		var ring: Array = rings[i]
		var c := cs[i]
		for a in 3:
			var p: Vector3 = ring[a]
			var q: Vector3 = ring[(a + 1) % 3]
			var out := ((p + q) * 0.5 - c).normalized()
			lm.beam("Steel", p + out * 0.02, q + out * 0.02, 0.12, 0.04, out)
	# Observation room windows: 16 slots down each face at the crown.
	var mid_i := steps / 2
	for k in 16:
		var i := mid_i - 8 + k
		var ring: Array = rings[i]
		var nxt: Array = rings[i + 1]
		for s in [1, 2]:
			var a: Vector3 = ring[0]
			var b: Vector3 = ring[s]
			var a1: Vector3 = nxt[0]
			var ctr := (a + b + a1 + (nxt[s] as Vector3)) * 0.25
			var out := (ctr - (cs[i] + cs[i + 1]) * 0.5)
			out = (out - out.project(cs[i + 1] - cs[i])).normalized()
			var along := (cs[i + 1] - cs[i]).normalized()
			lm.box("Glass", ctr + out * 0.03 + (a - b).normalized() * 0.4, Vector3(0.18, 0.68, 0.06),
				Basis(along, (a - b).normalized(), out).orthonormalized(), 0.0)
	# Footing pads and the west entrance of the museum under the grounds.
	for s in [-1.0, 1.0]:
		lm.box("Base", Vector3(0, 0.15, s * 91.2), Vector3(24.0, 0.3, 22.0))
	var e := Vector3(-60.0, 0, 0)
	LandmarkNaParts.ring(lm, "Base", e, 15.0, 1.2, 1.0, 40)
	lm.lathe("Glass", e, PackedVector2Array([Vector2(13.4, 0.0), Vector2(13.4, 0.6), Vector2(9.0, 1.4),
		Vector2(0.0, 1.8)]), 32)
	for k in 24:
		var a := TAU * float(k) / 24.0
		lm.beam("Steel", e + Vector3(cos(a), 0, sin(a)) * 13.4 + Vector3(0, 0.6, 0),
			e + Vector3(0, 1.8, 0) + Vector3(cos(a), 0, sin(a)) * 0.6, 0.12, 0.12)
	lm.commit(model)

## Hoover Dam (1936): the curved concrete gravity-arch wall bowing
## upstream (north, −Z) from the canyon rock, 13.7 m thick on the crest
## and widening to 200 m at the foot 221 m below the crest (y = 0, the
## crest road; the canyon floor lies below the model's ground), the
## crest roadway between Art Deco parapets with their bronze lamp
## standards, the four fluted Art Deco intake towers in the lake above
## it (the outer two with the Nevada and Arizona time clocks), the U of
## the powerhouse wings at the toe, and on the Nevada abutment the
## Winged Figures of the Republic (Oskar Hansen) on their diorite base.
static func hoover_dam(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B8B3A7", 8.0))
	lm.use("Tower", LandmarkMaterials.pbr("limestone", "#CDC3AE", 4.0))
	lm.use("Road", LandmarkMaterials.pbr("asphalt", "#3C3C3E", 4.0))
	lm.use("Bronze", LandmarkMaterials.paint("#5C4B34", 0.45, 0.6))
	lm.use("Dial", LandmarkMaterials.lit("#EDE6D2", 0.3))
	lm.use("Diorite", LandmarkMaterials.pbr("stone", "#2B2B2D", 3.0))
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
	var arc := func(rr: float, th: float, y: float) -> Vector3:
		return Vector3(rr * sin(th), y, radius - rr * cos(th))
	for k in 24:
		lm.quad("Concrete", up0[k], up0[k + 1], dn0[k + 1], dn0[k], Vector3.UP)
		var t0 := theta0 * (-1.0 + 2.0 * float(k) / 24.0)
		var t1 := theta0 * (-1.0 + 2.0 * float(k + 1) / 24.0)
		lm.quad("Road", arc.call(radius - 2.0, t0, 0.06), arc.call(radius - 2.0, t1, 0.06),
			arc.call(radius - 11.7, t1, 0.06), arc.call(radius - 11.7, t0, 0.06), Vector3.UP)
		# Parapets both sides of the crest, stepped Art Deco coping.
		for rr in [radius - 0.5, radius - 13.2]:
			var a: Vector3 = arc.call(rr, t0, 0.0)
			var b: Vector3 = arc.call(rr, t1, 0.0)
			lm.box("Concrete", (a + b) * 0.5 + Vector3(0, 0.6, 0), Vector3(0.6, 1.2, a.distance_to(b)),
				Basis.looking_at(b - a), 0.0)
			lm.box("Concrete", (a + b) * 0.5 + Vector3(0, 1.28, 0), Vector3(0.8, 0.16, a.distance_to(b)),
				Basis.looking_at(b - a), 0.0)
	# Bronze lamp standards along both parapets.
	for k in 13:
		var th := theta0 * (-1.0 + 2.0 * float(k) / 12.0) * 0.96
		for rr in [radius - 0.5, radius - 13.2]:
			var p: Vector3 = arc.call(rr, th, 1.36)
			lm.box("Concrete", p + Vector3(0, 0.4, 0), Vector3(0.9, 0.8, 0.9))
			lm.frustum("Bronze", p + Vector3(0, 0.8, 0), 0.14, 0.1, 4.2, 6)
			lm.lathe("Bronze", p + Vector3(0, 5.0, 0), PackedVector2Array([Vector2(0.1, 0.0), Vector2(0.38, 0.3),
				Vector2(0.36, 0.9), Vector2(0.12, 1.2), Vector2(0.0, 1.35)]), 8)
	# Intake towers: fluted shafts rising from the lake, capped and roofed.
	var angs := [-22.0, -15.0, 15.0, 22.0]
	for ti in angs.size():
		var th := deg_to_rad(float(angs[ti]))
		var rt := radius + 9.0
		var p := Vector3(rt * sin(th), 0, radius - rt * cos(th))
		lm.frustum("Tower", p + Vector3(0, -120.0, 0), 7.5, 7.0, 140.0, 24)
		for f in 16:
			var a := TAU * float(f) / 16.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.box("Tower", p + d * 7.15 + Vector3(0, 8.0, 0), Vector3(0.7, 24.0, 0.7), Basis.looking_at(d), 0.0)
		lm.frustum("Tower", p + Vector3(0, 20.0, 0), 8.6, 8.6, 2.5, 24)
		for k in 3:
			lm.frustum("Tower", p + Vector3(0, 22.5 + 0.6 * k, 0), 8.0 - 0.9 * k, 7.8 - 0.9 * k, 0.6, 24)
		lm.lathe("Tower", p + Vector3(0, 24.3, 0), PackedVector2Array([Vector2(5.4, 0.0),
			Vector2(4.0, 1.2), Vector2(2.2, HOOVER_TOP_M - 24.3)]), 24)
		var crest: Vector3 = arc.call(radius - 6.0, th, 8.0)
		lm.beam("Tower", p + Vector3(0, 8.0, 0), crest, 4.0, 3.0)
		if ti == 0 or ti == angs.size() - 1:
			var to_crest := (crest - p)
			to_crest.y = 0.0
			var dn := to_crest.normalized()
			lm.disc("Dial", p + dn * 7.62 + Vector3(0, 15.0, 0), dn, 2.4, 24)
			lm.beam("Bronze", p + dn * 7.7 + Vector3(0, 15.0, 0), p + dn * 7.7 + Vector3(0, 16.8, 0), 0.18, 0.05, dn.cross(Vector3.UP))
			lm.beam("Bronze", p + dn * 7.7 + Vector3(0, 15.0, 0), p + dn * 7.7 + Vector3(0, 15.0, 0) + dn.cross(Vector3.UP) * 1.2,
				0.18, 0.05, Vector3.UP)
	# Powerhouse wings at the toe, along each canyon wall.
	for s in [-1.0, 1.0]:
		var c := Vector3(s * 28.0, -depth + 22.0, 290.0)
		lm.box("Concrete", c, Vector3(20.0, 44.0, 150.0))
		for k in 9:
			lm.box("Tower", c + Vector3(-s * 10.1, 6.0, -64.0 + 16.0 * k), Vector3(0.4, 30.0, 6.0), Basis(), 0.0)
	# Winged Figures of the Republic on the Nevada abutment (their 43 m
	# flagstaff is left out: it would outreach the registry's tower-top
	# height).
	var m: Vector3 = arc.call(radius + 30.0, -theta0 - 0.05, 0.0)
	lm.box("Concrete", m + Vector3(0, 0.15, 0), Vector3(30.0, 0.3, 30.0))
	lm.box("Diorite", m + Vector3(0, 2.45, 0), Vector3(8.0, 4.3, 3.0))
	for s in [-1.0, 1.0]:
		var f := m + Vector3(s * 2.0, 4.6, 0)
		LandmarkKits.statue_figure(lm, "Bronze", f, 6.0)
		for k in 2:
			lm.tri("Bronze", f + Vector3(0, 4.0, -0.2), f + Vector3(s * 0.6, 9.1, -0.4 - 0.2 * k),
				f + Vector3(s * 0.3, 2.0, -0.5 - 0.2 * k), Vector3(s, 0, 0), Vector3(s, 0, 0), Vector3(s, 0, 0),
				Vector2.ZERO, Vector2(5.0, 0), Vector2(2.0, -1.0))
			lm.tri("Bronze", f + Vector3(0, 4.0, -0.2), f + Vector3(s * 0.3, 2.0, -0.5 - 0.2 * k),
				f + Vector3(s * 0.6, 9.1, -0.4 - 0.2 * k), Vector3(-s, 0, 0), Vector3(-s, 0, 0), Vector3(-s, 0, 0),
				Vector2.ZERO, Vector2(5.0, 0), Vector2(2.0, -1.0))
	lm.commit(model)

## Hollywood Sign (1923, rebuilt 1978): nine white sheet-metal letters
## 13.7 m tall in a row 106 m long, facing south (+Z), each on its
## concrete pads and held up behind by its steel frame: vertical posts,
## horizontal girts and diagonal braces, with raking struts down the
## slope.
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
	var foot := 0.4
	for l in letters:
		var w: float = l[0]
		for st in l[1]:
			var a := Vector3(x0 + s * 0.5 + float(st[0]) * (w - s), foot + s * 0.5 + float(st[1]) * (HOLLYWOOD_M - foot - s), 0)
			var b := Vector3(x0 + s * 0.5 + float(st[2]) * (w - s), foot + s * 0.5 + float(st[3]) * (HOLLYWOOD_M - foot - s), 0)
			lm.beam("Letter", a, b, 0.9, s, Vector3.BACK, true)
		# Back frame: posts every ~2.5 m, three girts, X braces between
		# the posts, a raking strut from each post down the slope.
		var cx := x0 + w * 0.5
		var np := maxi(3, roundi(w / 2.5) + 1)
		var posts: Array[float] = []
		for k in np:
			posts.append(x0 + 0.6 + (w - 1.2) * float(k) / float(np - 1))
		for px in posts:
			lm.beam("Frame", Vector3(px, foot, -0.9), Vector3(px, HOLLYWOOD_M - 0.4, -0.9), 0.3, 0.3)
			lm.beam("Frame", Vector3(px, HOLLYWOOD_M * 0.7, -1.0), Vector3(px, foot, -6.0), 0.25, 0.25)
			lm.box("Footing", Vector3(px, foot * 0.5, -0.9), Vector3(1.0, foot, 1.0), Basis(), 0.0)
			lm.box("Footing", Vector3(px, foot * 0.5, -6.0), Vector3(0.9, foot, 0.9), Basis(), 0.0)
		for gy in [0.18, 0.5, 0.82]:
			var y: float = foot + float(gy) * (HOLLYWOOD_M - foot)
			lm.beam("Frame", Vector3(posts[0], y, -1.1), Vector3(posts[np - 1], y, -1.1), 0.2, 0.2)
		for k in np - 1:
			lm.beam("Frame", Vector3(posts[k], foot + 0.5, -1.2), Vector3(posts[k + 1], HOLLYWOOD_M * 0.5, -1.2), 0.12, 0.12)
			lm.beam("Frame", Vector3(posts[k], HOLLYWOOD_M * 0.5, -1.2), Vector3(posts[k + 1], HOLLYWOOD_M - 1.0, -1.2), 0.12, 0.12)
		lm.box("Footing", Vector3(cx, foot * 0.5, 0.0), Vector3(w + 0.6, foot, 1.6), Basis(), 0.0)
		x0 += w + gap
	lm.commit(model)
