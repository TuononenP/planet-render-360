class_name LandmarkWestEarly
extends RefCounted

## Mont-Saint-Michel and Stonehenge in true metres. The crag site has
## y = 0 on the summit platform with the rock and the village built
## below it. (Edinburgh Castle is LandmarkEdinburgh.)

## Irregular granite crag: rings of (radius, y) from `prof`, `sides`
## around, each vertex jittered by up to `jit` of its radius; sx/sz
## stretch the plan.
static func crag(lm: LandmarkMesh, key: String, prof: PackedVector2Array, sides: int, jit: float,
		sx: float, sz: float, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	var rows: Array = []
	for j in prof.size():
		var ring := PackedVector3Array()
		for i in sides + 1:
			var a := TAU * float(i % sides) / float(sides)
			rng.seed = seed * 977 + (i % sides) * 31 + j * 7
			var k := 1.0 + rng.randf_range(-jit, jit)
			ring.append(Vector3(cos(a) * prof[j].x * k * sx, prof[j].y + rng.randf_range(-1.0, 1.0) * float(j > 0 and j < prof.size() - 1),
				sin(a) * prof[j].x * k * sz))
		rows.append(ring)
	lm.grid(key, rows, Vector3(0, prof[0].y, 0), true)

## Mont-Saint-Michel (90 m above the summit platform): the granite rock
## with the village houses stepping down its south-east flank; La
## Merveille (1211-1228) on the north face — three storeys of halls under
## the cloister, its buttresses and lancet tiers; the abbey church — the
## Romanesque nave with its 1780 west front, the transept and the
## Flamboyant Gothic choir (1446-1523) with its double flying buttresses
## and pinnacles; the abbots' lodgings and the Châtelet gatehouse with
## its twin turrets on the south-east; and the crossing tower's
## 1897 neo-Gothic spire with its lucarnes, crockets and Frémiet's gilded
## Archangel Michael.
static func mont_saint_michel(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#8D8472", 4.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A59D8C", 3.0))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#4F575C", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#20262A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var rot := Basis(Vector3.UP, PI * 0.5)
	crag(lm, "Rock", PackedVector2Array([Vector2(74, -45), Vector2(68, -36), Vector2(62, -25), Vector2(58, -16),
		Vector2(55, -8), Vector2(53, -2), Vector2(50, 0)]), 28, 0.08, 1.0, 1.0, 3)
	_msm_village(lm)
	# La Merveille: the 48 m north wall with buttresses and three tiers.
	LandmarkWestKit.blk(lm, "Granite", -2.0, -30.0, -21.0, 56.0, 48.0, 18.0)
	for k in 10:
		LandmarkWestKit.buttress(lm, "Granite", Vector3(-26.0 + 5.8 * float(k), -30.0, -30.0), Vector3(0, 0, -1),
			1.8, 2.6, 44.0, 3)
	lm.gable("Slate", Vector3(-2.0, 18.0, -21.0), 18.0, 56.0, 6.0, rot, 0.6, "Granite")
	var nn := Vector3(0, 0, -1)
	for k in 9:
		var x := -23.1 + 5.8 * float(k)
		LandmarkWestKit.lancet(lm, "Granite", "Glass", Vector3(x, -24.0, -30.0), nn, 1.2, 3.6, false)
		LandmarkWestKit.lancet(lm, "Granite", "Glass", Vector3(x, -10.0, -30.0), nn, 2.2, 7.5, true)
		for q in [-1.0, 1.0]:
			LandmarkWestKit.lancet(lm, "Granite", "Glass", Vector3(x + q * 1.2, 4.0, -30.0), nn, 0.9, 6.0, false)
	LandmarkWestKit.rail(lm, "Granite", Vector3(-30.0, 18.0, -30.3), Vector3(26.0, 18.0, -30.3), 0.8, 1.0)
	# West terrace and its buttressed substructure, west front of the nave.
	LandmarkWestKit.blk(lm, "Granite", -66.0, -40.0, 0, 26.0, 40.0, 40.0)
	LandmarkWestKit.merlons(lm, "Granite", Vector3(-79, 0, -20), Vector3(-79, 0, 20), 2.2, 1.0, 1.0, 1.0)
	LandmarkWestKit.rail(lm, "Granite", Vector3(-79.0, 0, -20.0), Vector3(-53.0, 0, -20.0), 1.0, 1.2)
	LandmarkWestKit.rail(lm, "Granite", Vector3(-79.0, 0, 20.0), Vector3(-53.0, 0, 20.0), 1.0, 1.2)
	_msm_church(lm, rot)
	# Abbots' lodgings (south) and the Châtelet's twin turrets.
	LandmarkWestKit.blk(lm, "Granite", 8.0, -24.0, 19.0, 40.0, 36.0, 12.0)
	lm.gable("Slate", Vector3(8.0, 12.0, 19.0), 12.0, 40.0, 5.0, rot, 0.5, "Granite")
	LandmarkDetail.pierced_face(lm, "Granite", "Glass", Vector3(-12.0, -24.0, 25.0), Vector3(1, 0, 0), Vector3(0, 0, 1),
		40.0, 36.0, 9, 5, Vector2(1.4, 2.6), 4.0, 6.4, 0.4)
	for k in 5:
		LandmarkWestKit.dormer(lm, "Granite", "Slate", "Glass", Vector3(-6.0 + 7.0 * float(k), 12.4, 25.2),
			Vector3(0, 0, 1), 1.8, 2.4, 2.0)
	for tz in [27.0, 35.0]:
		lm.frustum("Granite", Vector3(36.0, -30.0, tz), 2.6, 2.4, 40.0, 12)
		lm.frustum("Granite", Vector3(36.0, 8.0, tz), 3.0, 3.0, 1.4, 12)
		lm.lathe("Slate", Vector3(36.0, 9.4, tz), PackedVector2Array([Vector2(3.2, 0), Vector2(0.0, 6.0)]), 12)
	LandmarkWestKit.blk(lm, "Granite", 36.0, -30.0, 31.0, 6.0, 36.0, 6.0)
	LandmarkDetail.arch(lm, "Granite", Vector3(39.0, -27.0, 31.0), Vector3(1, 0, 0), 3.0, 0.5)
	lm.commit(model)

## Village houses stepping down the rock's south-east flank, with the
## parish church of Saint-Pierre.
static func _msm_village(lm: LandmarkMesh) -> void:
	var rock := PackedVector2Array([Vector2(-45, 72), Vector2(-25, 62), Vector2(-10, 56), Vector2(0, 50)])
	for k in 30:
		var a := -0.3 + 0.075 * float(k) * 2.2
		var y := -6.0 - float((k * 7) % 26)
		var rr := LandmarkMesh.profile_at(rock, y)
		var d := Vector3(cos(a), 0, sin(a))
		var p := d * (rr - 1.0)
		var w := 6.0 + float(k % 3)
		LandmarkWestKit.blk(lm, "Granite", p.x, y - 2.0, p.z, w, 7.0, 5.0, -a + PI * 0.5)
		lm.gable("Slate", Vector3(p.x, y + 5.0, p.z), 5.0, w, 2.8, Basis(Vector3.UP, -a), 0.4, "Granite")
		LandmarkWestKit.chimney(lm, "Granite", p - d * 1.2 + Vector3(0, y + 5.0, 0), 0.8, 1.2, 2.4)
		for q in [-1.0, 1.0]:
			var wp: Vector3 = p + d * 2.55 + Vector3(-d.z, 0, d.x) * q * 1.6
			lm.box("Glass", wp + Vector3(0, y + 2.6, 0), Vector3(0.9, 1.3, 0.06), Basis.looking_at(d), 0.0)
		LandmarkWestKit.dormer(lm, "Granite", "Slate", "Glass", p + d * 1.6 + Vector3(0, y + 5.0, 0), d, 1.2, 1.4, 1.2)
	var c := Vector3(cos(0.7), 0, sin(0.7)) * 56.0 + Vector3(0, -12.0, 0)
	LandmarkWestKit.blk(lm, "Granite", c.x, c.y, c.z, 14.0, 9.0, 7.0, -0.7)
	lm.gable("Slate", c + Vector3(0, 9.0, 0), 7.0, 14.0, 4.0, Basis(Vector3.UP, -0.7 + PI * 0.5), 0.4, "Granite")
	LandmarkWestKit.blk(lm, "Granite", c.x, c.y, c.z, 4.0, 15.0, 4.0)
	lm.spire("Slate", c + Vector3(0, 15.0, 0), 2.2, 7.0, 0.0, 8)

## Abbey church: nave, transept, Flamboyant choir with flyers and
## pinnacles, crossing tower and the spire with the archangel.
static func _msm_church(lm: LandmarkMesh, rot: Basis) -> void:
	# Romanesque nave (four bays survive) with round-headed windows.
	LandmarkWestKit.blk(lm, "Granite", -31.0, 0, 0, 50.0, 20.0, 20.0)
	lm.gable("Slate", Vector3(-31.0, 20.0, 0), 20.0, 50.0, 8.0, rot, 0.6, "Granite")
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for k in 6:
			var x := -52.0 + 8.0 * float(k)
			LandmarkDetail.window(lm, "Granite", "Glass", Vector3(x + 4.0, 13.5, sz * 10.0), n, 1.6, 4.0, true)
			lm.box("Granite", Vector3(x, 9.0, sz * 10.4), Vector3(1.4, 18.0, 0.8))
	# 1780 classical west front.
	lm.box("Granite", Vector3(-56.4, 10.0, 0), Vector3(0.8, 20.0, 20.4))
	for z in [-8.0, -3.0, 3.0, 8.0]:
		LandmarkWestKit.shaft(lm, "Granite", Vector3(-57.2, 0, z), 0.5, 11.0, 10)
	LandmarkWestKit.blk(lm, "Granite", -57.0, 11.0, 0, 1.6, 1.2, 20.4)
	lm.gable("Granite", Vector3(-57.0, 20.0, 0), 20.0, 1.6, 6.0, rot, 0.4, "Granite")
	LandmarkDetail.window(lm, "Granite", "Glass", Vector3(-57.2, 4.0, 0), Vector3(-1, 0, 0), 2.6, 6.0, true)
	LandmarkDetail.window(lm, "Granite", "Glass", Vector3(-57.2, 15.0, 0), Vector3(-1, 0, 0), 2.2, 4.0, true)
	# Transept with its gable ends.
	LandmarkWestKit.blk(lm, "Granite", 1.0, 0, 0, 14.0, 24.0, 42.0)
	lm.gable("Slate", Vector3(1.0, 24.0, 0), 14.0, 42.0, 7.0, Basis(), 0.6, "Granite")
	for sz in [-1.0, 1.0]:
		LandmarkWestKit.lancet(lm, "Granite", "Glass", Vector3(1.0, 8.0, sz * 21.0), Vector3(0, 0, sz), 3.6, 11.0, true)
	# Flamboyant choir and its chevet.
	LandmarkWestKit.blk(lm, "Granite", 25.0, 0, 0, 34.0, 24.0, 18.0)
	lm.gable("Slate", Vector3(25.0, 24.0, 0), 18.0, 34.0, 8.0, rot, 0.6, "Granite")
	lm.lathe("Granite", Vector3(42, 0, 0), PackedVector2Array([Vector2(9, 0), Vector2(9, 24)]), 14, 1.0, 1.0,
		0.0, false)
	lm.lathe("Slate", Vector3(42, 24, 0), PackedVector2Array([Vector2(9.8, 0), Vector2(0.0, 9.0)]), 14)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for k in 7:
			var x := 12.0 + 5.2 * float(k)
			if k < 6:
				LandmarkWestKit.lancet(lm, "Granite", "Glass", Vector3(x + 2.6, 11.0, sz * 9.0), n, 2.6, 11.0, true)
			LandmarkWestKit.blk(lm, "Granite", x, 0, sz * 12.6, 1.4, 16.0, 1.6)
			LandmarkWestKit.pinnacle(lm, "Granite", Vector3(x, 16.0, sz * 12.6), 0.7, 6.5)
			LandmarkWestKit.flyer(lm, "Granite", Vector3(x, 15.0, sz * 11.9), Vector3(x, 22.0, sz * 9.0), 0.7, 4)
		LandmarkWestKit.rail(lm, "Granite", Vector3(10.0, 24.0, sz * 9.3), Vector3(42.0, 24.0, sz * 9.3), 0.9, 0.8)
	for k in 5:
		var a := -PI * 0.5 + PI * float(k) / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWestKit.pinnacle(lm, "Granite", Vector3(42, 16.0, 0) + d * 12.0, 0.7, 6.5)
		LandmarkWestKit.blk(lm, "Granite", 42.0 + d.x * 12.0, 0, d.z * 12.0, 1.4, 16.0, 1.4)
		LandmarkWestKit.flyer(lm, "Granite", Vector3(42, 15.0, 0) + d * 11.3, Vector3(42, 22.0, 0) + d * 9.0, 0.7, 4)
		LandmarkWestKit.lancet(lm, "Granite", "Glass", Vector3(42, 11.0, 0) + d * 9.02, d, 2.4, 10.0, true)
	# Crossing tower: belfry with lancets, corner pinnacles, balustrade.
	LandmarkWestKit.blk(lm, "Granite", 1.0, 20.0, 0, 14.0, 14.0, 14.0)
	for s in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(s))
		var n: Vector3 = b * Vector3(0, 0, 1)
		for q in [-2.4, 2.4]:
			LandmarkWestKit.lancet(lm, "Granite", "Glass", Vector3(1, 23.0, 0) + n * 7.0 + b * Vector3(q, 0, 0), n, 1.8, 8.5, true)
		LandmarkWestKit.rail(lm, "Granite", Vector3(1, 34.0, 0) + b * Vector3(-7.0, 0, 7.0), Vector3(1, 34.0, 0) + b * Vector3(7.0, 0, 7.0),
			1.1, 0.7)
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		LandmarkWestKit.pinnacle(lm, "Granite", Vector3(1.0 + q.x * 6.4, 34.0, q.y * 6.4), 0.8, 7.0)
	# The spire (to 87 m) with lucarnes and crockets, then the archangel.
	var sp := Vector3(1, 34, 0)
	var needle := PackedVector2Array([Vector2(5.0, 0), Vector2(3.8, 10.0), Vector2(2.2, 28.0), Vector2(1.0, 44.0),
		Vector2(0.35, 50.0), Vector2(0.15, 52.6)])
	lm.lathe("Slate", sp, needle, 8, 1.0, 1.0, PI / 8.0, false)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var b := Basis(Vector3.UP, -a + PI * 0.5)
		LandmarkWestKit.blk(lm, "Granite", sp.x + d.x * 4.2, sp.y, sp.z + d.z * 4.2, 1.8, 3.0, 1.0, -a + PI * 0.5)
		lm.gable("Granite", sp + d * 4.2 + Vector3(0, 3.0, 0), 1.8, 1.0, 2.2, b, 0.1)
		if i % 2 == 0:
			LandmarkWestKit.lancet(lm, "Granite", "Glass", sp + d * 2.95 + Vector3(0, 16.0, 0), d, 0.8, 2.6, false, 0.15)
		var ea := a + PI / 8.0
		var de := Vector3(cos(ea), 0, sin(ea))
		for j in 10:
			var y := 3.0 + 4.6 * float(j)
			var rr := LandmarkMesh.profile_at(PackedVector2Array([Vector2(0, 5.0), Vector2(10, 3.8), Vector2(28, 2.2),
				Vector2(44, 1.0), Vector2(50, 0.35)]), y) / cos(PI / 8.0)
			lm.box("Slate", sp + de * (rr + 0.12) + Vector3(0, y, 0), Vector3(0.45, 0.3, 0.3), Basis(Vector3.UP, -ea), 0.0)
	var arch := sp + Vector3(0, 52.6, 0)
	LandmarkKits.statue_figure(lm, "Gilt", arch, 3.4, true)
	for s in [-1.0, 1.0]:
		lm.beam("Gilt", arch + Vector3(0, 2.4, s * 0.2), arch + Vector3(-0.4, 3.3, s * 1.3), 0.7, 0.08)
	lm.box("Gilt", arch + Vector3(0.48, 3.35, 0), Vector3(0.06, 0.9, 0.06), Basis(), 0.0)

## Stonehenge (7.3 m) as it stands today: the sarsen circle (33 m across,
## 30 uprights of which 17 stand, with six lintels in place over the
## north-east arc), fallen sarsens in the grass; the horseshoe of five
## trilithons opening on the midsummer-sunrise axis — three complete,
## the Great Trilithon reduced to its leaning upright beside its fallen
## partner and lintel, and one more single upright; the bluestone circle
## and horseshoe, the Altar Stone, the Slaughter Stone, the two Station
## Stones, the Heel Stone; the bank and ditch with the 56 Aubrey Holes
## marked in chalk, and the banks of the Avenue running north-east.
static func stonehenge(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sarsen", LandmarkMaterials.pbr("stone", "#8C877B", 2.5))
	lm.use("Blue", LandmarkMaterials.pbr("rock", "#6E767B", 2.0))
	lm.use("Bank", LandmarkMaterials.pbr("lawn", "#7C8F55", 4.0))
	lm.use("Chalk", LandmarkMaterials.pbr("concrete", "#E4E0D4", 2.0))
	# Midsummer-sunrise axis: the horseshoe opens along it (bearing 51 deg).
	var open := Vector2(sin(deg_to_rad(51.0)), -cos(deg_to_rad(51.0)))
	var axis_a := atan2(open.y, open.x)
	var back := atan2(-open.y, -open.x)
	# Sarsen circle: stone 1 and 30 flank the entrance on the axis.
	var standing := [1, 2, 3, 4, 5, 6, 7, 10, 11, 16, 19, 21, 23, 27, 28, 29, 30]
	var lintels := [[27, 28], [28, 29], [29, 30], [30, 1], [1, 2], [5, 6]]
	var fallen := [8, 9, 12, 14, 15, 22, 25]
	var ang := func(i: int) -> float: return axis_a + TAU * (float(i) - 0.5) / 30.0
	for i in range(1, 31):
		var a: float = ang.call(i)
		if i in standing:
			var hh := 4.1 + 0.15 * sin(float(i) * 1.7)
			LandmarkWestKit.rough_stone(lm, "Sarsen", Vector3(cos(a), 0, sin(a)) * 15.6, 2.1, 1.1, hh, -a - PI * 0.5, i)
			# Tenon knob on top (lintel joints), where no lintel sits.
			lm.frustum("Sarsen", Vector3(cos(a), 0, sin(a)) * 15.6 + Vector3(0, hh - 0.1, 0), 0.25, 0.2, 0.3, 6)
		elif i in fallen:
			var p := Vector3(cos(a), 0, sin(a)) * 17.5
			lm.box("Sarsen", p + Vector3(0, 0.5, 0), Vector3(4.0, 1.0, 2.0), Basis(Vector3.UP, -a + 0.3 * float(i % 3)))
	# Lintels: each curved to the circle (three dressed segments) and
	# jointed to its neighbours.
	for l in lintels:
		var a: float = (float(ang.call(int(l[0]))) + float(ang.call(int(l[1])))) * 0.5
		if int(l[0]) == 30:
			a = axis_a
		for k in 3:
			var b := a + (float(k) - 1.0) * TAU / 30.0 / 3.0
			var p := Vector3(cos(b), 0, sin(b)) * 15.6
			lm.box("Sarsen", p + Vector3(0, 4.55 - 0.04 * absf(float(k) - 1.0), 0), Vector3(1.15, 0.8, 1.15),
				Basis(Vector3.UP, -b - PI * 0.5))
	# Five trilithons (7.3 / 6.7 / 6.1 m including lintels).
	for t in [[0.0, 7.3, 1], [0.84, 6.7, 2], [-0.84, 6.7, 2], [1.68, 6.1, 2], [-1.68, 6.1, 3]]:
		var a: float = back + float(t[0])
		var h: float = float(t[1]) - 0.8
		var state: int = t[2]
		var basis := Basis(Vector3.UP, -a - PI * 0.5)
		for s in [-1.4, 1.4]:
			var c: Vector2 = Vector2(cos(a), sin(a)) * 9.0 + Vector2(-sin(a), cos(a)) * s
			if state == 2 or (state == 1 and s > 0.0) or (state == 3 and s < 0.0):
				LandmarkWestKit.rough_stone(lm, "Sarsen", Vector3(c.x, 0, c.y), 2.3, 1.4, h, -a - PI * 0.5, int(s * 10.0) + int(h * 10.0))
			else:
				lm.box("Sarsen", Vector3(c.x, 0.6, c.y) + Vector3(cos(a), 0, sin(a)) * 3.0, Vector3(2.2, 1.2, h),
					Basis(Vector3.UP, -a + 0.25))
		if state == 2:
			lm.box("Sarsen", Vector3(cos(a) * 9.0, h + 0.4, sin(a) * 9.0), Vector3(5.6, 0.8, 1.5), basis)
		else:
			lm.box("Sarsen", Vector3(cos(a) * 6.0, 0.5, sin(a) * 6.0), Vector3(5.4, 0.9, 1.4), Basis(Vector3.UP, -a + 0.4))
	# Bluestones: the circle of about sixty, today standing, leaning,
	# broken to stumps or lying in the grass; the horseshoe; the Altar Stone.
	for k in 58:
		var a := TAU * float(k) / 58.0 + 0.03
		var p := Vector3(cos(a), 0, sin(a)) * 11.8
		match k % 5:
			0, 2:
				LandmarkWestKit.rough_stone(lm, "Blue", p, 1.1, 0.7, 1.9 + 0.1 * float(k % 3), -a - PI * 0.5, 100 + k)
			1:
				LandmarkWestKit.rough_stone(lm, "Blue", p, 1.0, 0.7, 0.6, -a - PI * 0.5, 100 + k)
			3:
				if k % 2 == 0:
					lm.box("Blue", p + Vector3(0, 0.3, 0), Vector3(0.7, 0.6, 2.0), Basis(Vector3.UP, -a + 0.4))
	# Round barrows of the North and South Barrows round the Station Stones.
	for sa in [axis_a + 1.1 + PI * 0.5, axis_a + PI + 1.1 + PI * 0.5]:
		lm.lathe("Bank", Vector3(cos(sa), 0, sin(sa)) * 40.0, PackedVector2Array([Vector2(6.0, 0), Vector2(4.5, 0.4),
			Vector2(2.0, 0.6), Vector2(0.0, 0.65)]), 16, 1.0, 1.0, 0.0, true, false)
	for k in 15:
		var a := back - 1.9 + 3.8 * float(k) / 14.0
		LandmarkWestKit.rough_stone(lm, "Blue", Vector3(cos(a), 0, sin(a)) * 6.0, 0.8, 0.55, 2.3 - 0.3 * float(k % 2), -a - PI * 0.5, 200 + k)
	lm.box("Blue", Vector3(cos(back) * 5.0, 0.25, sin(back) * 5.0), Vector3(4.8, 0.5, 1.0),
		Basis(Vector3.UP, -back))
	# Heel Stone (leaning), Slaughter Stone, Station Stones.
	LandmarkWestKit.rough_stone(lm, "Sarsen", Vector3(open.x * 77.0, 0, open.y * 77.0), 2.4, 2.0, 4.8, 0.3, 77)
	lm.box("Sarsen", Vector3(open.x * 33.0, 0.35, open.y * 33.0), Vector3(2.1, 0.7, 6.4),
		Basis(Vector3.UP, -atan2(open.y, open.x) + PI * 0.5))
	for sa in [axis_a + 1.1, axis_a + PI + 1.1]:
		LandmarkWestKit.rough_stone(lm, "Sarsen", Vector3(cos(sa), 0, sin(sa)) * 40.0, 1.2, 1.0, 1.2, sa, 300)
	# Bank, ditch rim, Aubrey Holes, and the Avenue's banks.
	lm.lathe("Bank", Vector3.ZERO, PackedVector2Array([Vector2(46, 0), Vector2(48.5, 0.8), Vector2(51, 0.5),
		Vector2(54, 0.25), Vector2(57, 0.6), Vector2(59, 0)]), 64, 1.0, 1.0, 0.0, true, false)
	for k in 56:
		var a := TAU * float(k) / 56.0
		lm.disc("Chalk", Vector3(cos(a) * 43.5, 0.03, sin(a) * 43.5), Vector3.UP, 0.55, 8)
	var ax := Vector3(open.x, 0, open.y)
	var sd := Vector3(-open.y, 0, open.x)
	for s in [-1.0, 1.0]:
		var p0 := ax * 58.0 + sd * 11.0 * float(s)
		var p1 := ax * 160.0 + sd * 11.0 * float(s)
		for k in 8:
			var q0 := p0.lerp(p1, float(k) / 8.0)
			var q1 := p0.lerp(p1, float(k + 1) / 8.0)
			lm.beam("Bank", q0 + Vector3(0, 0.2, 0), q1 + Vector3(0, 0.2, 0), 3.0, 0.5, sd)
			lm.beam("Bank", q0 + sd * 3.0 * float(s) + Vector3(0, 0.08, 0), q1 + sd * 3.0 * float(s) + Vector3(0, 0.08, 0), 2.0, 0.2, sd)
	lm.commit(model)
