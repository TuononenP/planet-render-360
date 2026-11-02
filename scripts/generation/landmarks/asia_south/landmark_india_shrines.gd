class_name LandmarkIndiaShrines
extends RefCounted

## Two holy sites in true metres: the Golden Temple (Harmandir Sahib)
## in its pool and the Boudhanath Stupa.

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")

## Harmandir Sahib (20 m): the 12.25 m square sanctum on its 19.7 m
## marble platform in the ~150 m Amrit Sarovar. Marble lower storey
## (inlaid dado, a door on each of the four sides between arched
## windows), gilded copper above it, a bracketed chhajja, the gilded
## upper floor with an arcade, a kangura parapet, four corner chhatris
## and the fluted lotus dome. A balustraded causeway with lanterns runs
## west to the two-storey Darshani Deori gate. The pool is built up as a
## raised basin (water 0.3 m, walkways 1.2 m), nothing below ground.
static func golden_temple(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDE8DC", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Water", LandmarkMaterials.pbr("concrete", "#4F7C86", 4.0, 0.1))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#6A5B48", 2.0))
	lm.box("Water", Vector3(0, 0.15, 0), Vector3(150.0, 0.3, 150.0))
	# Marble parikrama walkway all round the pool.
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(0, 0.6, s * 82.5), Vector3(180.0, 1.2, 15.0))
		lm.box("Marble", Vector3(s * 82.5, 0.6, 0), Vector3(15.0, 1.2, 150.0))
	# Platform 19.7 m square with a balustrade, open to the causeway.
	lm.box("Marble", Vector3(0, 0.6, 0), Vector3(19.7, 1.2, 19.7))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		if side == 3:
			for sx in [-1.0, 1.0]:
				LandmarkDetail.balustrade(lm, "Marble", b * Vector3(sx * 9.6, 1.2, 9.6), b * Vector3(sx * 3.2, 1.2, 9.6),
					0.9, 3.2)
		else:
			LandmarkDetail.balustrade(lm, "Marble", b * Vector3(-9.6, 1.2, 9.6), b * Vector3(9.6, 1.2, 9.6), 0.9, 3.2)
	# Causeway (guru's bridge) west to the gate: balustrades and lanterns.
	lm.box("Marble", Vector3(-41.0, 0.6, 0), Vector3(62.0, 1.2, 6.0))
	for sz in [-1.0, 1.0]:
		LandmarkDetail.balustrade(lm, "Marble", Vector3(-72.0, 1.2, sz * 2.8), Vector3(-10.0, 1.2, sz * 2.8), 0.9, 6.0)
		for k in 10:
			var lp := Vector3(-69.0 + 6.0 * float(k), 1.2, sz * 2.8)
			lm.frustum("Gold", lp, 0.12, 0.1, 2.6, 6)
			lm.lathe("Gold", lp + Vector3(0, 2.6, 0), PackedVector2Array([Vector2(0.2, 0), Vector2(0.32, 0.25),
				Vector2(0.3, 0.55), Vector2(0.12, 0.75), Vector2(0.0, 0.9)]), 8)
	_darshani_deori(lm, Vector3(-76.0, 1.2, 0))
	# Ground storey (1.2 -> 7.5 m): marble dado, gilded upper half.
	lm.box("Marble", Vector3(0, 3.0, 0), Vector3(12.25, 3.6, 12.25))
	lm.box("Gold", Vector3(0, 6.0, 0), Vector3(12.15, 3.0, 12.15))
	lm.box("Gold", Vector3(0, 4.85, 0), Vector3(12.45, 0.3, 12.45))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		U.niche(lm, "Marble", "Gold", b * Vector3(0, 1.2, 6.125), b, 3.0, 4.6, 1.9, 0.0, 2.8, 1.3, 0.35, 8)
		for sx in [-1.0, 1.0]:
			U.niche(lm, "Marble", "Recess", b * Vector3(sx * 3.3, 1.2, 6.125), b, 2.4, 3.6, 1.3, 0.8, 2.4, 0.8, 0.25, 6)
			lm.box("Gold", b * Vector3(sx * 5.9, 4.4, 6.2), Vector3(0.4, 6.4, 0.3), b)
		# Row of small blind arches in the gilded panels.
		U.arcade(lm, "Gold", "Recess", b * Vector3(0, 5.1, 6.075), b, 11.0, 2.2, 7, 0.55, 0.3, 1.3, 1.3, 0.12, 6)
		# Chhajja eave on brackets at 7.5 m.
		lm.box("Gold", b * Vector3(0, 7.6, 6.6), Vector3(13.6, 0.2, 1.2), b * Basis(Vector3.RIGHT, -0.25))
		for k in 9:
			lm.box("Gold", b * Vector3(-5.6 + 1.4 * float(k), 7.2, 6.4), Vector3(0.2, 0.6, 0.5), b, 0.0)
		# Upper floor: five arched windows on each face, then the parapet.
		U.arcade(lm, "Gold", "Recess", b * Vector3(0, 7.8, 5.25), b, 10.5, 4.0, 5, 0.6, 0.6, 2.4, 1.3, 0.25, 6)
		U.merlons(lm, "Gold", b * Vector3(-5.6, 12.15, 5.9), b * Vector3(5.6, 12.15, 5.9), 14, 0.55, 0.8)
		# Kiosk over the door on the parapet.
		lm.lathe("Gold", b * Vector3(0, 12.2, 5.6), LandmarkKits.onion_profile(0.6, 1.3), 12)
	lm.box("Gold", Vector3(0, 9.9, 0), Vector3(10.5, 4.2, 10.5))
	lm.box("Gold", Vector3(0, 12.05, 0), Vector3(12.0, 0.3, 12.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			U.chhatri8(lm, "Gold", "Gold", "Gold", Vector3(sx * 4.9, 12.2, sz * 4.9), 1.1, 1.4, 1.3)
	# Square drum, inverted lotus, the fluted dome and its finial.
	lm.box("Gold", Vector3(0, 12.9, 0), Vector3(7.0, 1.4, 7.0))
	lm.frustum("Gold", Vector3(0, 13.6, 0), 3.9, 3.9, 0.8, 32)
	for i in 24:
		var a := TAU * float(i) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Gold", Vector3(0, 14.3, 0) + d * 3.6, Vector3(0, 15.1, 0) + d * 4.45, 0.9, 0.12,
			d.cross(Vector3.UP))
	var prof := LandmarkKits.onion_profile(4.0, 4.2)
	lm.lathe("Gold", Vector3(0, 14.4, 0), prof, 32)
	for i in 16:
		var a := TAU * float(i) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in prof.size() - 2:
			var p0 := Vector3(0, 14.4 + prof[j].y, 0) + d * prof[j].x * 1.02
			var p1 := Vector3(0, 14.4 + prof[j + 1].y, 0) + d * prof[j + 1].x * 1.02
			lm.beam("Gold", p0, p1, 0.22, 0.14, d.cross(Vector3.UP))
	U.finial(lm, "Gold", Vector3(0, 18.4, 0), 1.6, 0.3)
	lm.commit(model)

## Darshani Deori: the two-storey gatehouse at the causeway head, the
## pointed passage along X, jharokhas above, gilded domes on the roof.
static func _darshani_deori(lm: LandmarkMesh, p: Vector3) -> void:
	var b := Basis(Vector3.UP, PI * 0.5)
	U.arch_wall(lm, "Marble", p, b, 16.0, 10.0, 8.0, 4.4, 6.6, 12, 2.6)
	for sx in [-1.0, 1.0]:
		var fb := Basis(Vector3.UP, sx * PI * 0.5)
		U.frame(lm, "Gold", p + Vector3(sx * 4.0, 0.0, 0), fb, 5.6, 7.4, 0.35, 0.12)
		for sz in [-1.0, 1.0]:
			U.niche(lm, "Marble", "Recess", p + Vector3(sx * 4.0, 5.4, sz * 5.0), fb, 3.0, 3.6, 1.6, 0.4, 2.2, 0.9,
				0.4, 6)
			lm.box("Gold", p + Vector3(sx * 4.6, 5.6, sz * 5.0), Vector3(1.0, 0.25, 2.8))
		U.merlons(lm, "Gold", p + Vector3(sx * 3.8, 10.0, -7.6), p + Vector3(sx * 3.8, 10.0, 7.6), 12, 0.5, 0.8)
	for sz in [-1.0, 1.0]:
		U.chhatri8(lm, "Gold", "Gold", "Gold", p + Vector3(0, 10.0, sz * 6.4), 1.2, 1.2, 1.3)
	lm.frustum("Gold", p + Vector3(0, 10.0, 0), 2.6, 2.6, 0.8, 16)
	lm.lathe("Gold", p + Vector3(0, 10.8, 0), LandmarkKits.onion_profile(2.6, 3.0), 24)
	U.finial(lm, "Gold", p + Vector3(0, 13.6, 0), 1.0, 0.18)

## Boudhanath Stupa (36 m, ~100 m across): three white mandala terraces
## on a 20-cornered plan with stairs on the axes, the ring of 108 Buddha
## niches under the white hemispherical dome, the gilded harmika with the
## Buddha's eyes, the nose (the Nepali numeral one) and the third eye
## on each face, 13 square gilded tiers, the umbrella and gajur finial;
## the prayer-wheel wall round the base and prayer-flag lines from the
## spire to the terrace.
static func boudhanath(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F1EEE6", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#C9772B", 3.0))
	lm.use("Eyes", LandmarkMaterials.pbr("concrete", "#1F2A44", 2.0))
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#9A8A78", 3.0))
	lm.use("FlagBlue", LandmarkMaterials.pbr("render", "#2F5BA8", 2.0))
	lm.use("FlagRed", LandmarkMaterials.pbr("render", "#C23B2E", 2.0))
	lm.use("FlagYellow", LandmarkMaterials.pbr("render", "#E2B93B", 2.0))
	# Prayer-wheel wall: 147 brass wheels in niches round the inner face.
	lm.lathe("Wall", Vector3.ZERO, PackedVector2Array([Vector2(49.5, 0), Vector2(49.5, 3.2),
		Vector2(49.2, 3.5), Vector2(47.9, 3.5), Vector2(47.6, 3.2), Vector2(47.6, 2.5), Vector2(47.0, 2.5),
		Vector2(47.0, 0.6), Vector2(47.6, 0.6), Vector2(47.6, 0)]), 72)
	for i in 147:
		var a := TAU * float(i) / 147.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.frustum("Gold", d * 46.75 + Vector3(0, 0.9, 0), 0.22, 0.22, 0.9, 8)
		lm.beam("Wall", d * 46.75 + Vector3(0, 0.6, 0), d * 46.75 + Vector3(0, 2.5, 0), 0.06)
	# Three mandala terraces, 20-cornered, each with a coping band.
	var y := 0.0
	for k in 3:
		var hw := 41.0 - 4.5 * float(k)
		var plan := U.redent(hw, 3.2, 2)
		U.plan_frustum(lm, "White", Vector3.ZERO, plan, 1.0, 1.0, y, y + 2.1)
		U.plan_frustum(lm, "Wall", Vector3.ZERO, plan, 1.008, 1.008, y + 2.1, y + 2.4)
		# Stair flights on the four axes.
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			for st in 6:
				lm.box("White", b * Vector3(0, y + 0.2 + 0.4 * float(st), hw + 2.6 - 0.45 * float(st)),
					Vector3(5.0, 0.4, 0.45), b, 0.0)
			for sx in [-1.0, 1.0]:
				lm.box("White", b * Vector3(sx * 2.8, y + 1.3, hw + 1.4), Vector3(0.5, 2.6, 2.9), b)
		y += 2.4
	# Dome base: two drum rings with the 108 Buddha niches.
	lm.frustum("White", Vector3(0, y, 0), 21.6, 21.4, 0.6, 72)
	lm.frustum("Ochre", Vector3(0, y + 0.6, 0), 21.0, 20.8, 1.0, 72)
	for i in 108:
		var a := TAU * float(i) / 108.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Eyes", d * 20.95 + Vector3(0, y + 1.1, 0), Vector3(0.55, 0.7, 0.1), Basis.looking_at(d), 0.0)
		lm.box("Gold", d * 21.02 + Vector3(0, y + 1.0, 0), Vector3(0.3, 0.4, 0.05), Basis.looking_at(d), 0.0)
	U.dome(lm, "White", Vector3(0, y + 1.6, 0), 20.5, 13.4, 72, 18)
	var hy := y + 1.6 + 13.4
	# Harmika: gilded cube (on a white collar) with the eyes on each face.
	lm.frustum("White", Vector3(0, hy - 0.6, 0), 6.5, 5.2, 1.0, 32)
	lm.box("Ochre", Vector3(0, hy + 0.4, 0), Vector3(9.6, 0.8, 9.6))
	lm.box("Gold", Vector3(0, hy + 3.0, 0), Vector3(9.0, 4.4, 9.0))
	lm.box("Gold", Vector3(0, hy + 5.45, 0), Vector3(9.8, 0.5, 9.8))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for sx in [-1.0, 1.0]:
			# Almond eye: white, a dark iris, the lid line and eyebrow.
			var ec := b * Vector3(sx * 1.8, hy + 3.9, 4.52)
			lm.box("White", ec, Vector3(2.3, 0.8, 0.05), b, 0.0)
			lm.disc("Eyes", ec + b * Vector3(sx * -0.15, -0.05, 0.05), b * Vector3(0, 0, 1), 0.38, 12)
			for j in 6:
				var t0 := float(j) / 6.0
				var t1 := float(j + 1) / 6.0
				var p0 := ec + b * Vector3(-1.25 + 2.5 * t0, 0.4 + sin(PI * t0) * 0.25, 0.06)
				var p1 := ec + b * Vector3(-1.25 + 2.5 * t1, 0.4 + sin(PI * t1) * 0.25, 0.06)
				lm.beam("Eyes", p0, p1, 0.12, 0.06, b * Vector3(0, 0, 1))
				lm.beam("Eyes", p0 + b * Vector3(0, 0.75, 0), p1 + b * Vector3(0, 0.75, 0), 0.16, 0.06, b * Vector3(0, 0, 1))
		# Nose: the curled numeral one, and the third eye above.
		var nc := b * Vector3(0, hy + 2.3, 4.56)
		var prev := nc + b * Vector3(0, 1.2, 0)
		for j in 10:
			var t := float(j + 1) / 10.0
			var a := PI * 0.5 + t * PI * 1.4
			var p := nc + b * Vector3(cos(a) * 0.45 * (1.0 - t * 0.4) + 0.1, 1.2 - t * 1.6 + sin(a) * 0.3, 0)
			lm.beam("Eyes", prev, p, 0.18, 0.06, b * Vector3(0, 0, 1))
			prev = p
		lm.disc("Eyes", b * Vector3(0, hy + 4.75, 4.53), b * Vector3(0, 0, 1), 0.28, 10)
		# Gilded torana panel above the eyes on the top band.
		lm.box("Gold", b * Vector3(0, hy + 5.45, 4.95), Vector3(4.0, 0.4, 0.12), b, 0.0)
	# Thirteen square gilded tiers, each with a rim.
	var ty := hy + 5.7
	for k in 13:
		var hw2 := lerpf(3.6, 1.15, float(k) / 12.0)
		lm.box("Gold", Vector3(0, ty + 0.15, 0), Vector3(hw2 * 2.0, 0.3, hw2 * 2.0))
		lm.box("Gold", Vector3(0, ty + 0.33, 0), Vector3(hw2 * 2.1, 0.06, hw2 * 2.1), Basis(), 0.0)
		ty += 0.36
	# Umbrella (chhatra) with its fringe, the gajur finial.
	lm.lathe("Gold", Vector3(0, ty, 0), PackedVector2Array([Vector2(0.9, 0), Vector2(2.6, 0.25),
		Vector2(2.6, 0.45), Vector2(1.9, 0.75), Vector2(0.5, 1.0)]), 24)
	for i in 24:
		var a := TAU * float(i) / 24.0
		lm.box("Gold", Vector3(cos(a) * 2.5, ty - 0.1, sin(a) * 2.5), Vector3(0.25, 0.5, 0.05),
			Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	U.finial(lm, "Gold", Vector3(0, ty + 0.9, 0), 36.0 - ty - 0.9, 0.42)
	# Prayer-flag lines from below the umbrella to the outer terrace.
	var colours := ["FlagBlue", "FlagYellow", "FlagRed"]
	for i in 16:
		var a := TAU * (float(i) + 0.5) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		var p0 := d * 1.4 + Vector3(0, ty - 0.4, 0)
		var p1 := d * 40.0 + Vector3(0, 2.4, 0)
		var n := 36
		var prev := p0
		for j in n:
			var t := float(j + 1) / float(n)
			var p := p0.lerp(p1, t) - Vector3(0, sin(PI * t) * 2.2, 0)
			lm.beam("Wall", prev, p, 0.03)
			var mid := (prev + p) * 0.5
			lm.box(colours[j % 3], mid - Vector3(0, 0.3, 0), Vector3(0.05, 0.5, 0.45),
				Basis.looking_at(d.cross(Vector3.UP)), 0.0)
			prev = p
	lm.commit(model)
