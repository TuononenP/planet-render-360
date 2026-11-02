class_name LandmarkMonuments
extends RefCounted

## Giza pyramid field and the Statue of Liberty, in true metres.

# --- Giza ---

## The Giza plateau around Khufu (registry point): Khufu (230.3 m base,
## 138.5 m now, 146.6 m as built) and its three queens' pyramids to the
## east, sides on the compass. Khafre, Menkaure and the Sphinx are
## registry landmarks of their own at the same surveyed offsets
## (LandmarkSetEgypt, LandmarkMaAncient), so they are not drawn here a
## second time. Khufu's stripped core reads as ~100 stepped courses
## (203 survive) up to the ragged ~10 m summit platform; on the north
## face the original entrance (17 m up, 7.3 m east of the axis) under
## its chevron gable of paired limestone beams, Ma'mun's forced tunnel
## below it, and the few casing stones left at the foot; the basalt
## pavement of the mortuary temple on the east face with the causeway
## leaving it, the covered south boat pit, the enclosure pavement. The
## queens' pyramids (G1-a/b/c, ~49 m bases) are ruined stepped cores
## on rubble aprons, each with its chapel on the east side.
static func giza(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Limestone", LandmarkMaterials.pbr("limestone", "#C2A574", 6.0))
	lm.use("Casing", LandmarkMaterials.pbr("limestone", "#DCCDA8", 5.0))
	lm.use("Basalt", LandmarkMaterials.pbr("stone", "#3C3A36", 3.0))
	var hb := 115.15
	var apex := 146.6
	_pyramid(lm, "Limestone", Vector3.ZERO, hb, 138.5, apex, 101)
	_khufu_details(lm, hb, apex)
	var queens := [[170.0, 20.0, 24.75, 18.0, 4], [170.0, 73.0, 24.5, 20.0, 4], [168.0, 124.0, 23.1, 24.0, 5]]
	for q in queens:
		var c := Vector3(float(q[0]), 0, float(q[1]))
		var qhb: float = q[2]
		_rubble(lm, c, qhb)
		_pyramid(lm, "Casing" if int(q[4]) == 5 else "Limestone", c, qhb * 0.9, float(q[3]), qhb * 0.9 * 1.27,
			int(q[4]))
		# Offering chapel against the east face.
		lm.box("Limestone", c + Vector3(qhb + 4.0, 2.0, 0), Vector3(8.0, 4.0, 12.0))
		lm.box("Limestone", c + Vector3(qhb + 4.0, 4.3, 0), Vector3(8.6, 0.6, 12.6))
	lm.commit(model)

## Square pyramid of half-base `hb`, built to `h` (true apex `apex`),
## `steps` stripped courses (near-vertical risers, flat treads), in
## material `mat`.
static func _pyramid(lm: LandmarkMesh, mat: String, c: Vector3, hb: float, h: float,
		apex: float, steps: int) -> void:
	var prof := PackedVector2Array()
	var k := sqrt(2.0)
	for s in steps:
		# Courses thin toward the top, with the real alternation of
		# thick and thin courses.
		var f0 := float(s) / float(steps)
		var f1 := float(s + 1) / float(steps)
		var y0 := h * (1.0 - pow(1.0 - f0, 1.15))
		var y1 := h * (1.0 - pow(1.0 - f1, 1.15))
		if s % 3 == 1:
			y1 = lerpf(y0, y1, 0.85)
		var r0 := hb * (1.0 - y0 / apex) * k
		var r1 := hb * (1.0 - y1 / apex) * k
		prof.append(Vector2(r0, y0))
		prof.append(Vector2(r0 - (r0 - r1) * 0.15, y1))
		prof.append(Vector2(r1, y1))
	lm.lathe(mat, c, prof, 4, 1.0, 1.0, PI * 0.25, false, false)
	var top_r := hb * (1.0 - h / apex) * k
	lm.lathe(mat, c + Vector3(0, h, 0), PackedVector2Array([Vector2(top_r, 0),
		Vector2(0.0, 0.0)]), 4, 1.0, 1.0, PI * 0.25, false)

## Half-width of Khufu's face at height y.
static func _hw(hb: float, apex: float, y: float) -> float:
	return hb * (1.0 - y / apex)

static func _khufu_details(lm: LandmarkMesh, hb: float, apex: float) -> void:
	# Ragged summit platform: loose courses of blocks.
	for i in 14:
		var a := float(i) * 2.3
		var p := Vector3(cos(a) * float(i % 4) * 1.5, 138.5 + 0.5, sin(a) * float(i % 5) * 1.2)
		lm.box("Limestone", p, Vector3(1.6 + float(i % 3) * 0.5, 1.0, 1.2 + float(i % 2) * 0.6),
			Basis(Vector3.UP, float(i) * 0.1))
	# North face: original entrance and its chevron gable.
	var ey := 17.0
	var ex := 7.3
	var ez := -_hw(hb, apex, ey) - 0.4
	var n := Vector3(0, hb / apex, -1.0).normalized()
	lm.box("Basalt", Vector3(ex, ey + 0.6, ez - 0.2), Vector3(1.05, 1.2, 0.2), Basis(), 0.0)
	for pair in 2:
		var lift := 1.8 + float(pair) * 1.6
		var out := -0.6 - float(pair) * 0.5
		for sv in [-1.0, 1.0]:
			var lo := Vector3(ex + float(sv) * (2.4 + float(pair) * 0.6), ey + lift, -_hw(hb, apex, ey + lift) + out)
			var hi := Vector3(ex, ey + lift + 2.2 + float(pair) * 0.5, -_hw(hb, apex, ey + lift + 2.4) + out)
			lm.beam("Casing", lo, hi, 1.4, 1.6, n)
	# Ma'mun's tunnel (the visitors' way in), a ragged dark breach.
	var my := 7.0
	var mz := -_hw(hb, apex, my) - 0.2
	lm.box("Basalt", Vector3(0, my + 1.4, mz), Vector3(3.2, 2.8, 0.3), Basis(), 0.0)
	for i in 6:
		var a := TAU * float(i) / 6.0
		lm.box("Limestone", Vector3(cos(a) * 2.2, my + 1.4 + sin(a) * 2.0, mz - 0.5),
			Vector3(1.2, 1.0, 1.0), Basis(Vector3.BACK, a))
	# Surviving casing stones at the foot of the north face.
	var ch := 1.5
	var cw := 18.0
	var hb1 := _hw(hb, apex, ch)
	lm.quad("Casing", Vector3(-cw, 0, -hb - 0.4), Vector3(cw, 0, -hb - 0.4), Vector3(cw, ch, -hb1 - 0.4),
		Vector3(-cw, ch, -hb1 - 0.4), n)
	lm.box("Casing", Vector3(0, ch * 0.5, -hb1 + 0.3), Vector3(cw * 2.0, ch, 1.4), Basis(), 0.0)
	for i in 12:
		lm.box("Casing", Vector3(-cw + 1.5 + float(i) * 3.0, ch * 0.5, -hb - 0.2), Vector3(0.08, ch * 0.9, 0.4),
			Basis(), 0.0)
	# Enclosure pavement round the foot.
	for side in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("Casing", rot * Vector3(-5.0, 0.15, hb + 5.0), Vector3(hb * 2.0 + 10.0, 0.3, 10.0), rot, 0.0)
	# Mortuary temple: the basalt pavement and its wall footings on the
	# east face, and the causeway leaving it eastward.
	lm.box("Basalt", Vector3(hb + 20.0, 0.35, 0), Vector3(40.0, 0.7, 52.0))
	for i in 9:
		lm.box("Limestone", Vector3(hb + 6.0 + float(i) * 3.6, 1.2, -18.0), Vector3(1.4, 1.0, 1.4))
		lm.box("Limestone", Vector3(hb + 6.0 + float(i) * 3.6, 1.2, 18.0), Vector3(1.4, 1.0, 1.4))
	for sv in [-1.0, 1.0]:
		lm.box("Limestone", Vector3(hb + 20.0, 0.9, float(sv) * 25.5), Vector3(40.0, 1.8, 1.0))
	lm.box("Limestone", Vector3(hb + 39.5, 0.9, 0), Vector3(1.0, 1.8, 52.0))
	var cz0 := -12.0
	for i in 10:
		var x0 := hb + 40.0 + float(i) * 12.0
		lm.box("Limestone", Vector3(x0 + 6.0, 0.6, cz0 - float(i) * 1.6), Vector3(12.4, 1.2, 9.0),
			Basis(Vector3.UP, 0.13))
	# South boat pit, still roofed by its rows of limestone slabs.
	for i in 20:
		lm.box("Casing", Vector3(-30.0 + float(i) * 2.0, 0.45, hb + 18.0), Vector3(1.9, 0.9, 5.0))

## Rubble apron of a ruined queen's pyramid.
static func _rubble(lm: LandmarkMesh, c: Vector3, hb: float) -> void:
	var k := sqrt(2.0)
	lm.lathe("Limestone", c, PackedVector2Array([Vector2(hb * k, 0), Vector2(hb * 0.92 * k, 2.5),
		Vector2(hb * 0.86 * k, 3.6)]), 4, 1.0, 1.0, PI * 0.25, false)

# --- Statue of Liberty ---

## Liberty Island: Fort Wood's eleven-point granite star, the stepped
## concrete foundation (to 20 m) and Hunt's granite pedestal (to 47 m) —
## rusticated quoins, the loggia of three openings between Doric
## columns on each face, the frieze of discs under the cornice — then
## Bartholdi's 46 m copper statue (verdigris): the stola falling in
## folds over the stepping right foot, the palla swagged across the
## breast, the tablet (7.19 x 4.14 m, JULY IV MDCCLXXVI) in the left
## arm, the broken chain at her feet, the 5.26 m head with its diadem
## of 25 windows and seven 2.7 m rays, and the 12.8 m raised right arm
## with the torch, its balcony and the gilded flame at 93 m. She
## faces south-east (local +Z, turned 45°).
static func liberty(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("limestone", "#B4A99A", 3.0))
	lm.use("Fort", LandmarkMaterials.pbr("concrete", "#8E8578", 4.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B8B2A6", 4.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6AA391", 2.0, 0.7, 0.15))
	lm.use("Flame", LandmarkMaterials.gold())
	lm.use("Windows", LandmarkMaterials.glass("#22292C"))
	_fort(lm)
	_pedestal(lm)
	_statue(lm)
	lm.commit(model)
	model.rotation.y = deg_to_rad(45.0)

static func _fort(lm: LandmarkMesh) -> void:
	var star := PackedVector2Array()
	for k in 22:
		var a := TAU * float(k) / 22.0
		var r := 52.0 if k % 2 == 0 else 34.0
		star.append(Vector2(cos(a) * r, sin(a) * r))
	lm.poly_prism("Fort", star, 0.0, 7.5)
	# Coping along the star's walls and the sally port in the south point.
	for k in 22:
		var p := star[k]
		var q := star[(k + 1) % 22]
		var a3 := Vector3(p.x, 7.5, p.y)
		var b3 := Vector3(q.x, 7.5, q.y)
		var out := (b3 - a3).cross(Vector3.UP).normalized()
		if out.dot(a3 + b3) < 0.0:
			out = -out
		lm.beam("Fort", a3 + out * 0.4 + Vector3(0, 0.3, 0), b3 + out * 0.4 + Vector3(0, 0.3, 0), 1.0, 0.6, Vector3.UP)
	var gate := Vector3(cos(TAU * 6.0 / 22.0) * 52.0, 0, sin(TAU * 6.0 / 22.0) * 52.0) * 0.95
	lm.box("Windows", gate + Vector3(0, 1.8, 0), Vector3(3.0, 3.6, 3.0), Basis(Vector3.UP, -TAU * 6.0 / 22.0), 0.0)
	lm.lathe("Concrete", Vector3.ZERO, PackedVector2Array([Vector2(26.0, 7.5),
		Vector2(26.0, 9.0), Vector2(19.0, 9.0), Vector2(19.0, 14.0), Vector2(14.5, 14.0),
		Vector2(14.5, 20.0)]), 4, 1.0, 1.0, PI * 0.25, false)

static func _pedestal(lm: LandmarkMesh) -> void:
	var k := sqrt(2.0)
	lm.lathe("Granite", Vector3.ZERO, PackedVector2Array([Vector2(14.0 * k, 20.0),
		Vector2(13.0 * k, 22.0), Vector2(11.5 * k, 23.5), Vector2(10.4 * k, 33.0),
		Vector2(11.2 * k, 34.0), Vector2(9.6 * k, 35.0), Vector2(9.6 * k, 42.5),
		Vector2(10.4 * k, 43.5), Vector2(9.0 * k, 44.5), Vector2(8.0 * k, 47.0)]),
		4, 1.0, 1.0, PI * 0.25, false)
	for side in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(side))
		var out := rot * Vector3(0, 0, 1)
		# Loggia: three deep openings between Doric columns.
		for j in 3:
			var x := -5.2 + float(j) * 5.2
			lm.box("Windows", rot * Vector3(x, 38.6, 8.6), Vector3(2.4, 5.4, 0.1), rot, 0.0)
			for sv in [-1.0, 1.0]:
				lm.box("Granite", rot * Vector3(x + float(sv) * 1.3, 38.6, 9.1), Vector3(0.2, 5.4, 1.0), rot, 0.0)
			lm.box("Granite", rot * Vector3(x, 41.35, 9.1), Vector3(2.8, 0.2, 1.0), rot, 0.0)
			lm.box("Granite", rot * Vector3(x, 35.85, 9.4), Vector3(3.0, 0.3, 0.6), rot, 0.0)
		for j in 4:
			var x := -7.8 + float(j) * 5.2
			LandmarkDetail.column(lm, "Granite", rot * Vector3(x, 35.2, 9.9), 0.42, 7.0, "doric", 0)
		lm.box("Granite", rot * Vector3(0, 42.6, 9.9), Vector3(17.2, 0.8, 0.9), rot)
		# Frieze of discs under the crowning cornice.
		for j in 10:
			var x := -8.1 + float(j) * 1.8
			lm.disc("Granite", rot * Vector3(x, 45.6, 8.7) + out * 0.25, out, 0.6, 12)
		# Central panel and the dark doorway at the base of each face.
		lm.box("Granite", rot * Vector3(0, 27.0, 10.75), Vector3(7.0, 6.0, 0.5), rot)
		lm.box("Granite", rot * Vector3(0, 27.0, 11.05), Vector3(5.6, 4.6, 0.2), rot, 0.0)
		lm.box("Windows", rot * Vector3(0, 25.6, 12.9), Vector3(3.0, 3.6, 0.1), rot, 0.0)
		# Rusticated quoins up the pedestal's corners.
		for c in 8:
			var y := 24.2 + float(c) * 1.1
			var long := c % 2 == 0
			lm.box("Granite", rot * Vector3(10.6 - (0.9 if long else 0.6), y, 10.6 - 0.6),
				Vector3(1.8 if long else 1.2, 0.9, 1.4), rot)

## Ring of `seg` points round `c` in the plane normal to `axis`.
static func _ring(c: Vector3, axis: Vector3, r: float, seg: int, sx: float = 1.0) -> PackedVector3Array:
	var a := axis.normalized()
	var u := a.cross(Vector3.FORWARD if absf(a.z) < 0.9 else Vector3.RIGHT).normalized()
	var v := a.cross(u).normalized()
	var ring := PackedVector3Array()
	for i in seg + 1:
		var t := TAU * float(i) / float(seg)
		ring.append(c + u * cos(t) * r * sx + v * sin(t) * r)
	return ring

## Tube through `pts` with radii `rs` (arms, sleeves, the swag).
static func _tube(lm: LandmarkMesh, key: String, pts: Array[Vector3], rs: Array[float], seg: int = 12) -> void:
	var rows: Array = []
	for i in pts.size():
		var t := pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]
		rows.append(_ring(pts[i], t, rs[i], seg))
	lm.grid(key, rows)
	lm.disc(key, pts[pts.size() - 1], pts[pts.size() - 1] - pts[pts.size() - 2], rs[rs.size() - 1], seg)

## Four-sided spike from `root` to `tip`, `w` wide at the root.
static func _spike(lm: LandmarkMesh, key: String, root: Vector3, tip: Vector3, w: float) -> void:
	var a := (tip - root).normalized()
	var u := a.cross(Vector3.UP).normalized() * w * 0.5
	var v := a.cross(u).normalized() * w * 0.3
	var cs := [root + u, root + v, root - u, root - v]
	for i in 4:
		var p: Vector3 = cs[i]
		var q: Vector3 = cs[(i + 1) % 4]
		var n := (p + q - root * 2.0).normalized()
		lm.tri(key, p, q, tip, n, n, n, Vector2.ZERO, Vector2(w, 0), Vector2(w * 0.5, -root.distance_to(tip)))

## The copper figure.
static func _statue(lm: LandmarkMesh) -> void:
	var b := 47.0
	# Robe and body: elliptic sections (y, half-width, half-depth),
	# deep vertical folds of the stola below the waist, shallower ones
	# above, the hem lifted behind over the stepping right foot.
	var prof := [[0.0, 4.9, 4.0], [1.5, 5.0, 4.1], [6.0, 4.5, 3.6], [12.0, 3.9, 3.1], [17.0, 3.6, 2.8],
		[21.0, 3.8, 2.8], [24.0, 4.0, 2.9], [26.0, 4.3, 3.0], [27.4, 4.4, 2.8], [28.2, 3.0, 2.3],
		[28.8, 1.5, 1.5], [29.4, 1.3, 1.4]]
	var rows: Array = []
	for p in prof:
		var y: float = float(p[0])
		var row := PackedVector3Array()
		for i in 41:
			var a := TAU * float(i) / 40.0
			var amp := 0.09 if y < 21.0 else (0.035 if y < 28.0 else 0.0)
			var fold := 1.0 + amp * sin(a * 11.0 + y * 0.22) + amp * 0.5 * sin(a * 5.0 - y * 0.4)
			var lift := 0.0
			if y < 0.5 and sin(a) < -0.3 and cos(a) > -0.2:
				lift = 1.2 * (-sin(a) - 0.3)
			row.append(Vector3(cos(a) * float(p[1]) * fold, b + y + lift, sin(a) * float(p[2]) * fold))
		rows.append(row)
	lm.grid("Copper", rows, Vector3(0, b + 15.0, 0), true)
	lm.lathe("Copper", Vector3(0, b, 0), PackedVector2Array([Vector2(5.0, 0), Vector2(5.1, 0.4)]), 24, 1.0, 0.82)
	# Feet: the left foot forward, toes showing below the hem; the right
	# heel raised behind; the broken shackle and chain between them.
	lm.lathe("Copper", Vector3(-1.4, b, 4.2), PackedVector2Array([Vector2(0.9, 0), Vector2(0.95, 0.4),
		Vector2(0.6, 0.9), Vector2(0.0, 1.0)]), 10, 0.8, 1.4)
	_tube(lm, "Copper", [Vector3(2.0, b + 0.2, -3.6), Vector3(2.1, b + 1.4, -4.6), Vector3(2.1, b + 2.6, -4.9)],
		[0.9, 0.8, 0.7], 10)
	for i in 6:
		var c := Vector3(-1.0 + float(i) * 1.1, b + 0.25, 5.0 - absf(float(i) - 2.5) * 0.4)
		var ring := _ring(c, Vector3(1, 0, 0.3) if i % 2 == 0 else Vector3(0.3, 0, 1), 0.38, 8)
		for j in 8:
			lm.beam("Copper", ring[j], ring[j + 1], 0.14, 0.14)
	# Palla: the cloak swagged from the left shoulder across the breast
	# to the right hip, and its fall down the back.
	_tube(lm, "Copper", [Vector3(-3.6, b + 27.6, 0.6), Vector3(-1.8, b + 25.6, 2.8), Vector3(0.6, b + 23.4, 3.1),
		Vector3(2.8, b + 21.6, 2.6), Vector3(3.9, b + 20.6, 1.0)], [0.7, 0.8, 0.8, 0.75, 0.6], 10)
	_tube(lm, "Copper", [Vector3(-3.4, b + 27.8, -0.6), Vector3(-3.6, b + 22.0, -2.6), Vector3(-3.4, b + 14.0, -3.4),
		Vector3(-3.0, b + 6.0, -4.0)], [0.9, 1.2, 1.3, 1.2], 10)
	# Head: lathed ovoid (5.26 m chin to cranium), nose, brow, hair bun.
	var hb := Vector3(0, b + 29.3, 0.35)
	lm.lathe("Copper", hb, PackedVector2Array([Vector2(0.0, 0), Vector2(0.9, 0.2), Vector2(1.45, 0.9),
		Vector2(1.6, 2.0), Vector2(1.7, 3.1), Vector2(1.55, 4.1), Vector2(1.1, 4.8), Vector2(0.0, 5.26)]), 16, 0.9, 1.05)
	_spike(lm, "Copper", hb + Vector3(0, 2.0, 1.55), hb + Vector3(0, 1.25, 2.1), 0.7)
	lm.box("Copper", hb + Vector3(0, 2.85, 1.55), Vector3(2.0, 0.3, 0.35), Basis(), 0.0)
	lm.box("Copper", hb + Vector3(0, 0.75, 1.45), Vector3(0.9, 0.18, 0.2), Basis(), 0.0)
	lm.lathe("Copper", hb + Vector3(0, 3.0, -1.5), _dome_ball(0.9), 10)
	# Diadem: the band with its 25 windows, then the seven rays.
	var cb := hb + Vector3(0, 3.6, 0)
	lm.frustum("Copper", cb, 1.85, 1.75, 1.1, 20)
	for i in 25:
		var a := PI * 0.15 + PI * 0.7 * float(i) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Windows", cb + Vector3(d.x * 1.62, 0.55, d.z * 1.82), Vector3(0.22, 0.45, 0.05),
			Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	for k in 7:
		var a := deg_to_rad(-75.0 + 25.0 * float(k))
		var d := Vector3(sin(a), 0.3, cos(a)).normalized()
		var root := cb + Vector3(0, 0.8, 0) + Vector3(d.x, 0, d.z) * 1.6
		_spike(lm, "Copper", root, root + d * 2.7, 0.55)
	# Raised right arm (+X): the loose sleeve to the elbow, the forearm,
	# the hand round the torch handle.
	_tube(lm, "Copper", [Vector3(2.9, b + 26.6, 0.0), Vector3(3.5, b + 29.8, -0.2), Vector3(3.8, b + 33.5, -0.3),
		Vector3(3.75, b + 36.2, -0.25), Vector3(3.65, b + 39.0, -0.15)], [1.9, 1.8, 1.4, 0.95, 0.75], 14)
	lm.lathe("Copper", Vector3(3.8, b + 31.0, -0.3), PackedVector2Array([Vector2(1.6, 0), Vector2(2.0, 1.2),
		Vector2(1.5, 2.6)]), 12, 1.0, 0.9)
	var hand := Vector3(3.6, b + 39.0, -0.15)
	lm.lathe("Copper", hand, PackedVector2Array([Vector2(0.8, 0), Vector2(0.95, 0.6), Vector2(0.75, 1.3)]), 10)
	# Torch: handle, cup, balcony with its railing, gilded flame to 93 m.
	lm.frustum("Copper", hand + Vector3(0, 1.3, 0), 0.6, 0.85, 1.4, 12)
	lm.lathe("Copper", hand + Vector3(0, 2.7, 0), PackedVector2Array([Vector2(0.85, 0), Vector2(1.5, 0.6),
		Vector2(1.7, 1.1)]), 16)
	var bal := hand + Vector3(0, 3.8, 0)
	lm.frustum("Copper", bal, 2.4, 2.4, 0.2, 20)
	for i in 20:
		var a := TAU * float(i) / 20.0
		lm.beam("Copper", bal + Vector3(cos(a) * 2.3, 0.2, sin(a) * 2.3), bal + Vector3(cos(a) * 2.3, 1.1, sin(a) * 2.3),
			0.08, 0.08)
		var a1 := TAU * float(i + 1) / 20.0
		lm.beam("Copper", bal + Vector3(cos(a) * 2.3, 1.1, sin(a) * 2.3), bal + Vector3(cos(a1) * 2.3, 1.1, sin(a1) * 2.3),
			0.1, 0.1)
	var fl := bal + Vector3(0, 0.2, 0)
	lm.lathe("Flame", fl, PackedVector2Array([Vector2(1.3, 0), Vector2(1.35, 0.8), Vector2(1.1, 1.6),
		Vector2(0.6, 2.4), Vector2(0.0, b + 46.0 - fl.y)]), 12)
	for i in 5:
		var a := TAU * float(i) / 5.0
		_spike(lm, "Flame", fl + Vector3(cos(a) * 0.9, 1.0, sin(a) * 0.9),
			fl + Vector3(cos(a) * 0.5, 2.6 + 0.2 * float(i % 2), sin(a) * 0.5), 0.6)
	# Left arm: bent at the side, the hand gripping the tablet's top.
	_tube(lm, "Copper", [Vector3(-3.4, b + 26.8, 0.2), Vector3(-4.2, b + 24.0, 0.6), Vector3(-4.3, b + 22.0, 1.0),
		Vector3(-3.5, b + 23.6, 2.4), Vector3(-2.9, b + 24.6, 2.9)], [1.4, 1.3, 1.1, 0.8, 0.65], 12)
	var tab := Basis(Vector3.UP, -0.55) * Basis(Vector3.BACK, 0.22) * Basis(Vector3.RIGHT, -0.15)
	var tc := Vector3(-3.9, b + 21.6, 2.3)
	lm.box("Copper", tc, Vector3(0.61, 7.19, 4.14), tab)
	lm.box("Copper", tc + tab * Vector3(0.35, 0, 0), Vector3(0.1, 6.6, 3.6), tab, 0.0)
	for r in 3:
		lm.box("Copper", tc + tab * Vector3(0.42, 1.2 - float(r) * 1.0, 0), Vector3(0.06, 0.35, 2.6 - float(r) * 0.4),
			tab, 0.0)

static func _dome_ball(r: float) -> PackedVector2Array:
	var pr := PackedVector2Array()
	for k in 7:
		var t := PI * float(k) / 6.0
		pr.append(Vector2(sin(t) * r, r - cos(t) * r))
	return pr

# --- Memorial column and obelisk ---

## Free-standing memorial column (Nelson's Column, Vendome, the Monument):
## stepped granite plinth, tapering Portland-stone shaft, bronze capital
## and a figure on top. Proportions follow Nelson's Column (51.6 m:
## plinth 19 %, shaft 57 %, capital 7 %, figure 10 %). Windowless: OSM
## maps these as `building=yes`, which would otherwise get floors of
## windows like a block of flats.
static func column(lm: LandmarkMesh, h: float) -> void:
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8A84", 3.0))
	lm.use("Shaft", LandmarkMaterials.pbr("limestone", "#BDB6A6", 4.0))
	lm.use("Bronze", LandmarkMaterials.paint("#5E6B52", 0.55, 0.5))
	var plinth := h * 0.19
	var pw := h * 0.1
	var step := h * 0.03
	lm.box("Granite", Vector3(0, step * 0.5, 0), Vector3(pw * 2.3, step, pw * 2.3))
	lm.box("Granite", Vector3(0, step + (plinth - step * 1.6) * 0.5, 0),
		Vector3(pw * 2.0, plinth - step * 1.6, pw * 2.0))
	lm.box("Granite", Vector3(0, plinth - step * 0.3, 0), Vector3(pw * 2.15, step * 0.6, pw * 2.15))
	var r0 := h * 0.033
	var r1 := r0 * 0.85
	var shaft_h := h * 0.57
	lm.frustum("Shaft", Vector3(0, plinth, 0), r0, r1, shaft_h, 28)
	var cap_y := plinth + shaft_h
	var cap_h := h * 0.07
	lm.lathe("Bronze", Vector3(0, cap_y, 0), PackedVector2Array([Vector2(r1, 0),
		Vector2(r1 * 1.2, cap_h * 0.4), Vector2(r1 * 1.5, cap_h * 0.8),
		Vector2(r1 * 1.6, cap_h)]), 24)
	lm.box("Shaft", Vector3(0, cap_y + cap_h + h * 0.01, 0), Vector3(r1 * 3.6, h * 0.02, r1 * 3.6))
	var fig_y := cap_y + cap_h + h * 0.02
	lm.frustum("Granite", Vector3(0, fig_y, 0), r1 * 0.9, r1 * 0.7, h * 0.03, 12)
	lm.lathe("Bronze", Vector3(0, fig_y + h * 0.03, 0), PackedVector2Array([Vector2(r1 * 0.5, 0),
		Vector2(r1 * 0.42, h * 0.04), Vector2(r1 * 0.5, h * 0.06), Vector2(r1 * 0.3, h * 0.075),
		Vector2(r1 * 0.12, h * 0.085)]), 10)

## Obelisk: square tapering shaft on a stepped base, pyramidion on top.
static func obelisk(lm: LandmarkMesh, h: float) -> void:
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E8A84", 3.0))
	lm.use("Shaft", LandmarkMaterials.pbr("limestone", "#C4BBA8", 4.0))
	var hb := h * 0.075
	lm.box("Granite", Vector3(0, h * 0.015, 0), Vector3(hb * 2.4, h * 0.03, hb * 2.4))
	lm.box("Granite", Vector3(0, h * 0.045, 0), Vector3(hb * 2.0, h * 0.03, hb * 2.0))
	lm.spire("Shaft", Vector3(0, h * 0.06, 0), h * 0.05, h * 0.84, h * 0.034)
	lm.spire("Shaft", Vector3(0, h * 0.9, 0), h * 0.034, h * 0.1, 0.0)
