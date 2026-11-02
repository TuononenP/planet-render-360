class_name LandmarkSeaStupas
extends RefCounted

## The two great stupas of the batch in true metres: the Shwedagon
## Pagoda and Borobudur.

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")

## Shwedagon Pagoda (99.4 m above the platform): the octagonal plinth
## (433 m round at platform level, 6.4 m high) ringed by 64 small
## stupas, eight to a side, and four larger ones on the axes; three
## octagonal terraces, the moulded round base, the gilded bell, the
## turban bands, the inverted alms bowl, the bands of down- and
## up-turned lotus petals, the banana bud, the seven-ringed hti with its
## bells, the vane and the diamond orb.
static func shwedagon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Base", LandmarkMaterials.pbr("limestone", "#D5C9AE", 3.0))
	lm.use("Red", LandmarkMaterials.pbr("terracotta", "#A5502F", 3.0))
	# Plinth and terraces: octagons (flat sides on the axes).
	var rot := PI / 8.0
	lm.frustum("Base", Vector3.ZERO, 70.5, 69.5, 5.8, 8, rot)
	lm.frustum("Red", Vector3(0, 5.8, 0), 70.2, 70.0, 0.6, 8, rot)
	var terr := [[64.0, 6.4, 3.4], [58.0, 9.8, 3.4], [52.0, 13.2, 3.4]]
	for t in terr:
		var r: float = t[0]
		var y0: float = t[1]
		var th: float = t[2]
		lm.frustum("Gold", Vector3(0, y0, 0), r, r - 0.4, th - 0.5, 8, rot)
		lm.frustum("Gold", Vector3(0, y0 + th - 0.5, 0), r + 0.3, r + 0.2, 0.5, 8, rot)
		# Small stupa finials along each terrace edge.
		for i in 32:
			var a := TAU * (float(i) + 0.5) / 32.0
			var rr := r * cos(PI / 8.0) / cos(fmod(a + PI / 8.0, PI / 4.0) - PI / 8.0) - 1.0
			_stupa(lm, Vector3(cos(a) * rr, y0 + th, sin(a) * rr), 0.5, 2.2)
	# Moulded round base of the bell (16.6 -> 21 m).
	lm.lathe("Gold", Vector3(0, 16.6, 0), PackedVector2Array([Vector2(47.0, 0), Vector2(47.0, 0.9),
		Vector2(45.8, 1.2), Vector2(45.8, 2.0), Vector2(46.4, 2.4), Vector2(44.6, 3.0), Vector2(44.6, 3.6),
		Vector2(44.0, 4.4)]), 64)
	# Bell (21 -> 50 m) with three moulded rings.
	lm.lathe("Gold", Vector3.ZERO, PackedVector2Array([Vector2(44.0, 21.0), Vector2(43.4, 24.0),
		Vector2(41.5, 28.0), Vector2(37.5, 33.0), Vector2(31.5, 39.0), Vector2(25.0, 44.0),
		Vector2(20.5, 47.5), Vector2(18.0, 50.0)]), 64)
	for b in [[25.0, 43.2], [33.0, 37.6], [40.0, 30.5]]:
		lm.frustum("Gold", Vector3(0, float(b[1]), 0), float(b[0]) + 0.6, float(b[0]) + 0.2, 0.6, 64)
	# Turban: seven ring mouldings.
	var y := 50.0
	for k in 7:
		var r := 17.6 - 0.7 * float(k)
		lm.lathe("Gold", Vector3(0, y, 0), PackedVector2Array([Vector2(r, 0), Vector2(r + 0.4, 0.4),
			Vector2(r, 0.9)]), 48)
		y += 0.95
	# Inverted alms bowl, then the down- and up-turned lotus petals.
	lm.lathe("Gold", Vector3(0, y, 0), PackedVector2Array([Vector2(12.0, 0), Vector2(14.0, 2.0),
		Vector2(13.6, 5.0), Vector2(11.4, 7.6), Vector2(9.0, 9.0)]), 48)
	y += 9.0
	lm.frustum("Gold", Vector3(0, y, 0), 9.0, 8.4, 3.4, 48)
	for i in 32:
		var a := TAU * float(i) / 32.0
		var d := Vector3(cos(a), 0, sin(a))
		var sd := d.cross(Vector3.UP)
		lm.beam("Gold", Vector3(0, y + 1.6, 0) + d * 9.0, Vector3(0, y, 0) + d * 10.6, 1.7, 0.25, sd)
		lm.beam("Gold", Vector3(0, y + 1.7, 0) + d * 8.6, Vector3(0, y + 3.4, 0) + d * 10.2, 1.7, 0.25, sd)
	y += 3.4
	# Banana bud (12.6 m) with its vertical ribs.
	var bud := PackedVector2Array([Vector2(6.0, 0), Vector2(6.4, 3.0), Vector2(5.4, 8.0),
		Vector2(3.0, 11.0), Vector2(1.4, 12.6)])
	lm.lathe("Gold", Vector3(0, y, 0), bud, 32)
	for i in 16:
		var a := TAU * float(i) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in bud.size() - 1:
			lm.beam("Gold", Vector3(0, y + bud[j].y, 0) + d * (bud[j].x + 0.05),
				Vector3(0, y + bud[j + 1].y, 0) + d * (bud[j + 1].x + 0.05), 0.3, 0.15, d.cross(Vector3.UP))
	y += 12.6
	# Hti: seven bell-shaped umbrella rings, each fringed with bells.
	for k in 7:
		var r := 4.2 - 0.48 * float(k)
		var hy := y + 1.37 * float(k)
		lm.lathe("Gold", Vector3(0, hy, 0), PackedVector2Array([Vector2(r * 0.75, 0), Vector2(r, 0.4),
			Vector2(r * 0.85, 1.0), Vector2(r * 0.5, 1.37)]), 24)
		var nb := int(r * 4.0)
		for i in nb:
			var a := TAU * float(i) / float(nb)
			lm.lathe("Gold", Vector3(cos(a) * r, hy - 0.35, sin(a) * r), PackedVector2Array([Vector2(0.12, 0),
				Vector2(0.14, 0.15), Vector2(0.06, 0.3), Vector2(0.0, 0.35)]), 6)
	y += 9.6
	# Vane, then the diamond orb to 99.4 m.
	lm.frustum("Gold", Vector3(0, y, 0), 0.5, 0.3, 3.1, 12)
	lm.box("Gold", Vector3(1.0, y + 1.6, 0), Vector3(2.0, 1.2, 0.08), Basis(), 0.0)
	y += 3.1
	lm.lathe("Gold", Vector3(0, y, 0), PackedVector2Array([Vector2(0.5, 0), Vector2(1.0, 0.4),
		Vector2(0.4, 0.9), Vector2(0.7, 1.4), Vector2(0.15, 2.4), Vector2(0.0, 99.4 - y)]), 12)
	# The ring of stupas round the plinth at platform level.
	for i in 64:
		var a := TAU * (float(i) + 0.5) / 64.0
		var rr := 74.0 / cos(fmod(a + PI / 8.0, PI / 4.0) - PI / 8.0)
		_shrine_stupa(lm, Vector3(cos(a) * rr, 0, sin(a) * rr), 1.6, 9.0)
	for k in 4:
		var a := PI * 0.5 * float(k)
		_shrine_stupa(lm, Vector3(cos(a), 0, sin(a)) * 84.0, 3.4, 18.0)
	lm.commit(model)

## A small gilded stupa (bell, rings, spire) of radius r, height h.
static func _stupa(lm: LandmarkMesh, base: Vector3, r: float, h: float) -> void:
	lm.lathe("Gold", base, PackedVector2Array([Vector2(r, 0), Vector2(r * 1.05, h * 0.2),
		Vector2(r * 0.75, h * 0.5), Vector2(r * 0.4, h * 0.65), Vector2(r * 0.3, h * 0.8),
		Vector2(0.0, h)]), 8)

## A satellite stupa on the platform: square red-painted base, octagonal
## terraces, gilded bell with turban rings, bud and a small hti.
static func _shrine_stupa(lm: LandmarkMesh, base: Vector3, r: float, h: float) -> void:
	lm.box("Red", base + Vector3(0, h * 0.05, 0), Vector3(r * 2.6, h * 0.1, r * 2.6))
	lm.frustum("Base", base + Vector3(0, h * 0.1, 0), r * 1.2, r * 1.1, h * 0.06, 8, PI / 8.0)
	lm.frustum("Gold", base + Vector3(0, h * 0.16, 0), r * 1.05, r * 1.0, h * 0.05, 8, PI / 8.0)
	lm.lathe("Gold", base + Vector3(0, h * 0.21, 0), PackedVector2Array([Vector2(r, 0), Vector2(r * 0.95, h * 0.12),
		Vector2(r * 0.7, h * 0.26), Vector2(r * 0.45, h * 0.34), Vector2(r * 0.48, h * 0.37),
		Vector2(r * 0.38, h * 0.4), Vector2(r * 0.42, h * 0.43), Vector2(r * 0.3, h * 0.47),
		Vector2(r * 0.34, h * 0.52), Vector2(r * 0.22, h * 0.6), Vector2(r * 0.1, h * 0.68),
		Vector2(0.0, h * 0.72)]), 12)
	for k in 3:
		lm.frustum("Gold", base + Vector3(0, h * (0.86 + 0.035 * float(k)), 0), r * (0.26 - 0.06 * float(k)),
			r * (0.18 - 0.05 * float(k)), h * 0.025, 8)

## Borobudur (35 m): the stepped Buddhist mandala of andesite. The 4 m
## foot (123 m square) and four galleried square terraces stepping in
## on a redented (20-cornered) plan, each edged by a balustrade wall with
## its Buddha niches (104, 104, 88, 72 and 64 of them, crowned by small
## stupas); the top square platform carries the three round terraces
## (51, 38 and 26 m across) with 32, 24 and 16 latticed stupas and the
## 16 m main stupa. Stairs with kala-makara gates climb the four axes;
## the main entrance is east.
static func borobudur(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#706B62", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#5A554D", 3.0))
	lm.use("Niche", LandmarkMaterials.pbr("concrete", "#2E2A25", 2.0))
	U.plan_frustum(lm, "Dark", Vector3.ZERO, U.redent(61.5, 3.0, 3), 1.0, 1.0, 0.0, 4.0)
	var hws := [54.5, 51.0, 47.5, 44.0, 40.5]
	var per_side := [26, 26, 22, 18, 16]
	var y := 4.0
	for k in 5:
		var hw: float = hws[k]
		var plan := U.redent(hw, 2.4, 3)
		var top := y + 3.2
		# Main wall up to the gallery floor, its cornice, the balustrade.
		U.plan_frustum(lm, "Stone", Vector3.ZERO, plan, 1.0, 1.0, y, top - 0.4)
		U.plan_frustum(lm, "Dark", Vector3.ZERO, plan, 1.012, 1.012, top - 0.4, top)
		var s_in := (hw - 0.9) / hw
		U.plan_ring(lm, "Stone", Vector3.ZERO, plan, 1.0, s_in, top, top + 2.0)
		# Buddha niches on the balustrade's outer face, small stupa crowns.
		var n: int = per_side[k]
		var straight := hw - 3.0 * 2.4 - 1.0
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			for i in n:
				var x := -straight + 2.0 * straight * (float(i) + 0.5) / float(n)
				if absf(x) < 3.0:
					continue
				var fp := b * Vector3(x, top + 0.2, hw)
				U.niche(lm, "Stone", "Niche", fp, b, 1.5, 1.5, 0.95, 0.0, 0.85, 0.45, 0.25, 4)
				lm.lathe("Stone", fp + b * Vector3(0, 1.5, 0.12), PackedVector2Array([Vector2(0.45, 0),
					Vector2(0.4, 0.25), Vector2(0.15, 0.45), Vector2(0.0, 0.8)]), 6)
			# Kala-makara gate over the stair through the balustrade.
			U.arch_wall(lm, "Dark", b * Vector3(0, top, hw - 0.45), b, 5.0, 3.4, 0.9, 2.4, 2.8, 8)
			lm.box("Dark", b * Vector3(0, top + 3.7, hw - 0.45), Vector3(3.0, 0.6, 0.9), b)
		y = top
	# Stairs on the four axes from the ground to the top platform.
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var steps := int(y / 0.3)
		for i in steps:
			var t := float(i) / float(steps)
			lm.box("Dark", b * Vector3(0, y * t + 0.15, 63.0 - (63.0 - 40.0) * t), Vector3(3.2, 0.3, 23.0 / steps + 0.05),
				b, 0.0)
		for sx in [-1.0, 1.0]:
			lm.beam("Dark", b * Vector3(sx * 1.9, 0.4, 63.0), b * Vector3(sx * 1.9, y + 0.4, 40.0), 0.6, 0.8,
				b * Vector3.RIGHT)
	# Round terraces: radius, count of latticed stupas, ring radius.
	for t in [[25.5, 32, 22.3], [19.0, 24, 15.9], [13.0, 16, 10.1]]:
		var r: float = t[0]
		lm.frustum("Stone", Vector3(0, y, 0), r, r - 0.1, 1.2, 64)
		lm.frustum("Dark", Vector3(0, y + 1.2, 0), r + 0.1, r, 0.3, 64)
		y += 1.5
		var cnt: int = t[1]
		for i in cnt:
			var a := TAU * (float(i) + 0.5) / float(cnt)
			_lattice_stupa(lm, Vector3(cos(a), 0, sin(a)) * float(t[2]) + Vector3(0, y, 0), cnt == 16)
	# Main stupa: lotus cushion, bell, harmika and octagonal spire to 35 m.
	lm.lathe("Stone", Vector3(0, y, 0), PackedVector2Array([Vector2(8.6, 0), Vector2(8.6, 0.45),
		Vector2(8.2, 0.65), Vector2(8.3, 0.9), Vector2(8.0, 1.0), Vector2(8.0, 1.8), Vector2(7.6, 3.2),
		Vector2(6.4, 4.5), Vector2(4.4, 5.4), Vector2(2.4, 5.75), Vector2(0.0, 5.85)]), 48)
	var hy := y + 5.6
	lm.box("Stone", Vector3(0, hy + 0.7, 0), Vector3(3.6, 1.4, 3.6))
	lm.box("Dark", Vector3(0, hy + 1.55, 0), Vector3(4.0, 0.3, 4.0))
	lm.frustum("Stone", Vector3(0, hy + 1.7, 0), 1.3, 0.6, 35.0 - hy - 2.3, 8, PI / 8.0)
	lm.lathe("Stone", Vector3(0, 35.0 - 0.6, 0), PackedVector2Array([Vector2(0.6, 0), Vector2(0.5, 0.3),
		Vector2(0.0, 0.6)]), 8)
	lm.commit(model)

## One perforated stupa (3.6 m across): lotus cushion, a bell of two
## crossing families of stone bars (diamond openings; square on the top
## ring) round a seated Buddha in the dark, harmika and spire.
static func _lattice_stupa(lm: LandmarkMesh, base: Vector3, square: bool) -> void:
	lm.frustum("Stone", base, 1.9, 1.85, 0.3, 12)
	lm.lathe("Stone", base + Vector3(0, 0.3, 0), PackedVector2Array([Vector2(1.85, 0), Vector2(1.65, 0.25)]), 12)
	# The Buddha in the dark: a seated figure.
	lm.lathe("Niche", base + Vector3(0, 0.3, 0), PackedVector2Array([Vector2(0.75, 0), Vector2(0.7, 0.35),
		Vector2(0.38, 0.5), Vector2(0.35, 1.0), Vector2(0.22, 1.15), Vector2(0.24, 1.4), Vector2(0.0, 1.55)]), 8)
	# Lattice bell from r 1.65 at 0.55 m to r 1.1 at 2.3 m.
	var n := 12
	for i in n:
		var a0 := TAU * float(i) / float(n)
		var a1 := TAU * float(i + 1) / float(n)
		var lo0 := base + Vector3(cos(a0) * 1.65, 0.55, sin(a0) * 1.65)
		var lo1 := base + Vector3(cos(a1) * 1.65, 0.55, sin(a1) * 1.65)
		var hi0 := base + Vector3(cos(a0) * 1.1, 2.3, sin(a0) * 1.1)
		var hi1 := base + Vector3(cos(a1) * 1.1, 2.3, sin(a1) * 1.1)
		if square:
			lm.beam("Stone", lo0, hi0, 0.2, 0.15)
			var m0 := lo0.lerp(hi0, 0.5)
			var m1 := lo1.lerp(hi1, 0.5)
			lm.beam("Stone", m0, m1, 0.18, 0.15)
		else:
			lm.beam("Stone", lo0, hi1, 0.17, 0.15)
			lm.beam("Stone", lo1, hi0, 0.17, 0.15)
	lm.frustum("Stone", base + Vector3(0, 0.5, 0), 1.7, 1.7, 0.12, 12)
	lm.frustum("Stone", base + Vector3(0, 2.25, 0), 1.15, 1.0, 0.25, 12)
	lm.lathe("Stone", base + Vector3(0, 2.5, 0), PackedVector2Array([Vector2(1.0, 0), Vector2(0.6, 0.45),
		Vector2(0.0, 0.5)]), 12)
	lm.box("Stone", base + Vector3(0, 3.15, 0), Vector3(0.75, 0.6, 0.75), Basis(Vector3.UP, 0.0 if square else PI * 0.25))
	lm.frustum("Stone", base + Vector3(0, 3.45, 0), 0.3, 0.05, 0.9, 8, PI / 8.0)
