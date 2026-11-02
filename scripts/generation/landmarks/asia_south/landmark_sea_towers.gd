class_name LandmarkSeaTowers
extends RefCounted

## South-east Asian towers in true metres: the Petronas Towers with the
## skybridge, Marina Bay Sands with its SkyPark ship, and Monas in Jakarta.

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")

const PETRONAS_TOP_M := 451.9
## Centre of each tower from the registry point; the star's points are
## 24 m out, leaving the 58.4 m bridge span between the inner points.
const PETRONAS_X := 53.2
const STAR_R := 24.0
const STAR_NOTCH := 17.5
## 88 storeys to the 375 m top floor.
const PETRONAS_FLOOR_M := 4.26

## Petronas Towers (451.9 m): two 88-storey towers on the Rub el Hizb
## plan (an eight-pointed star of two squares) with round lobes in the
## notches, setting back in five stages to the crown (roof 405.5 m) and
## the 46.4 m pinnacle of rings and spheres. Every floor carries the
## stainless-steel sunshade band, mullions run up the points and lobes,
## each setback ends in a ring of rods. The two-storey skybridge at
## 170 m (floors 41-42, 58.4 m) rests on a two-hinged arch whose 51 m
## legs land on level 29. Towers along X.
static func petronas(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.paint("#B3BEC5", 0.3, 0.5))
	lm.use("Steel", LandmarkMaterials.paint("#C9CED1", 0.3, 0.85))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#BDB8AE", 3.0))
	# top y of each stage and its star scale
	var stages := [[0.0, 258.0, 1.0], [258.0, 314.0, 0.82], [314.0, 353.0, 0.65],
		[353.0, 366.0, 0.5], [366.0, 378.6, 0.38]]
	for sx in [-1.0, 1.0]:
		var c := Vector3(sx * PETRONAS_X, 0, 0)
		lm.box("Podium", c + Vector3(0, 4.5, 0), Vector3(72.0, 9.0, 72.0))
		lm.box("Podium", c + Vector3(0, 9.3, 0), Vector3(73.0, 0.6, 73.0))
		for st in stages:
			var y0: float = st[0]
			var y1: float = st[1]
			var sc: float = st[2]
			lm.poly_prism("Glass", _star(c, sc), maxf(y0, 9.0), y1)
			for k in 8:
				var a := TAU * float(k) / 8.0
				lm.box("Steel", c + Vector3(cos(a), 0, sin(a)) * STAR_R * sc + Vector3(0, (maxf(y0, 9.0) + y1) * 0.5, 0),
					Vector3(1.4, y1 - maxf(y0, 9.0), 1.4), Basis(Vector3.UP, -a))
			# Sunshade band on every floor of the stage.
			var y := maxf(y0, 9.0) + PETRONAS_FLOOR_M
			while y < y1 - 1.0:
				lm.poly_prism("Steel", _star(c, sc * 1.012), y, y + 0.45, false)
				if y1 <= 258.0:
					for k in 8:
						var a := TAU * (float(k) + 0.5) / 8.0
						lm.lathe("Steel", c + Vector3(cos(a), 0, sin(a)) * 19.0 + Vector3(0, y, 0),
							PackedVector2Array([Vector2(4.85, 0), Vector2(4.85, 0.45)]), 12, 1.0, 1.0, 0.0, true, false)
				y += PETRONAS_FLOOR_M
			# Ring of rods crowning the setback.
			for k in 16:
				var a := TAU * float(k) / 16.0
				var r := (STAR_R if k % 2 == 0 else STAR_NOTCH) * sc * 0.96
				lm.beam("Steel", c + Vector3(cos(a) * r, y1, sin(a) * r), c + Vector3(cos(a) * r, y1 + 3.5, sin(a) * r), 0.5)
		# Round lobes in the star's notches, up to the first setback, with mullions.
		for k in 8:
			var a := TAU * (float(k) + 0.5) / 8.0
			var lc := c + Vector3(cos(a), 0, sin(a)) * 19.0
			lm.frustum("Glass", lc + Vector3(0, 9.0, 0), 4.7, 4.7, 249.0, 12)
			for j in 3:
				var b := a + (float(j) - 1.0) * 0.7
				lm.box("Steel", lc + Vector3(cos(b), 0, sin(b)) * 4.75 + Vector3(0, 133.5, 0), Vector3(0.35, 249.0, 0.35),
					Basis(Vector3.UP, -b), 0.0)
		# Crown and pinnacle to 451.9 m: cone, rings and spheres.
		lm.lathe("Steel", c + Vector3(0, 378.6, 0), PackedVector2Array([Vector2(7.0, 0), Vector2(7.0, 13.0),
			Vector2(6.0, 16.0), Vector2(4.2, 22.0), Vector2(3.4, 24.0), Vector2(2.6, 30.0),
			Vector2(1.8, 45.0), Vector2(1.0, 60.0), Vector2(0.3, PETRONAS_TOP_M - 378.6)]), 16)
		for y in [384.0, 389.0, 394.0]:
			lm.frustum("Steel", c + Vector3(0, y, 0), 7.6, 7.6, 1.0, 24)
		for y in [403.0, 410.0, 418.0, 430.0]:
			lm.lathe("Steel", c + Vector3(0, y, 0), PackedVector2Array([Vector2(1.5, 0), Vector2(3.2, 0.5),
				Vector2(3.2, 1.2), Vector2(1.5, 1.7)]), 16)
		for y in [398.0, 424.0, 438.0]:
			var r := 3.0 if y < 430.0 else 1.8
			var sph := PackedVector2Array()
			for i in 9:
				var t := PI * float(i) / 8.0
				sph.append(Vector2(sin(t) * r, r - cos(t) * r))
			lm.lathe("Steel", c + Vector3(0, y, 0), sph, 16)
	# Skybridge: glazed two-storey deck and its supporting inverted V.
	var half := PETRONAS_X - STAR_R
	lm.box("Glass", Vector3(0, 169.0, 0), Vector3(half * 2.0, 9.0, 9.0))
	for y in [164.0, 169.0, 173.6]:
		lm.box("Steel", Vector3(0, y, 0), Vector3(half * 2.0, 0.9, 10.0))
	for i in 15:
		var x := -half + half * 2.0 * float(i) / 14.0
		for z in [-4.6, 4.6]:
			lm.box("Steel", Vector3(x, 169.0, z), Vector3(0.35, 9.0, 0.3), Basis(), 0.0)
	for z in [-4.0, 4.0]:
		for s in [-1.0, 1.0]:
			lm.beam("Steel", Vector3(s * 1.0, 163.0, z), Vector3(s * (half - 1.0), 122.0, z), 2.0, 2.0)
		lm.lathe("Steel", Vector3(0, 161.4, z), PackedVector2Array([Vector2(0.0, 0), Vector2(1.4, 0.4),
			Vector2(1.4, 1.4), Vector2(0.0, 1.8)]), 12)
	lm.commit(model)

## The 16-vertex star (points on the axes) at `scale`, around `c`.
static func _star(c: Vector3, scale: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for k in 16:
		var a := TAU * float(k) / 16.0
		var r := (STAR_R if k % 2 == 0 else STAR_NOTCH) * scale
		p.append(Vector2(c.x + cos(a) * r, c.z + sin(a) * r))
	return p

## Marina Bay Sands (207 m): three 55-storey hotel towers, each a
## straight slab (west leg) with a curved east leg leaning onto it,
## floor lines on every storey; the 340 m SkyPark boat on top (hull with
## its ribs, garden of trees and palms, the 150 m infinity pool, the
## observation deck on the 66.5 m cantilever at the north end) and the
## low podium. Built along X (cantilever to +X), turned onto the real
## axis by the registry yaw.
static func marina_bay_sands(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.paint("#789BAA", 0.25, 0.4))
	lm.use("Frame", LandmarkMaterials.pbr("concrete", "#E4E1DA", 3.0))
	lm.use("Hull", LandmarkMaterials.pbr("concrete", "#CFCBC2", 3.0))
	lm.use("Water", LandmarkMaterials.pbr("concrete", "#5FA3B8", 4.0, 0.08))
	lm.use("Trees", LandmarkMaterials.pbr("forest", "#41632F", 4.0))
	lm.box("Hull", Vector3(0, 4.0, 0), Vector3(300.0, 8.0, 96.0))
	lm.box("Frame", Vector3(0, 8.2, 0), Vector3(302.0, 0.4, 98.0))
	var floor_h := 3.4
	for cx in [-105.0, 0.0, 105.0]:
		# West leg: straight slab, z -11..0.
		lm.box("Glass", Vector3(cx, 98.0, -5.5), Vector3(50.0, 180.0, 11.0))
		for e in [-1.0, 1.0]:
			lm.box("Frame", Vector3(cx + e * 25.2, 98.0, -5.5), Vector3(1.6, 180.0, 11.6))
		# East leg: curved, from z 26 at the podium to the west leg at the top.
		var prev := Vector3(cx, 8.0, _leg_z(0.0))
		for i in 18:
			var t := float(i + 1) / 18.0
			var p := Vector3(cx, 8.0 + 180.0 * t, _leg_z(t))
			lm.beam("Glass", prev, p + (p - prev).normalized() * 0.3, 50.0, 11.0, Vector3.RIGHT, true)
			for e in [-1.0, 1.0]:
				lm.beam("Frame", prev + Vector3(e * 25.2, 0, 0), p + Vector3(e * 25.2, 0, 0), 1.6, 11.6, Vector3.RIGHT)
			prev = p
		# Floor lines on both legs, every storey.
		var y := 8.0 + floor_h
		while y < 187.0:
			var t := (y - 8.0) / 180.0
			lm.box("Frame", Vector3(cx, y, -5.5), Vector3(50.4, 0.3, 11.4), Basis(), 0.0)
			lm.box("Frame", Vector3(cx, y, _leg_z(t)), Vector3(50.4, 0.3, 11.4), Basis(), 0.0)
			y += floor_h
	# SkyPark ship: half-width by station along X, hull then deck.
	var stations := [[-147.0, 3.0], [-140.0, 13.0], [-100.0, 19.0], [0.0, 19.5], [130.0, 19.0],
		[170.0, 14.0], [190.0, 7.0], [196.5, 1.5]]
	lm.poly_prism("Hull", _ship(stations, 0.6), 185.0, 188.0)
	lm.poly_prism("Hull", _ship(stations, 0.78), 188.0, 193.0)
	lm.poly_prism("Frame", _ship(stations, 1.0), 193.0, 199.0)
	lm.poly_prism("Hull", _ship(stations, 0.94), 199.0, 199.6)
	# Hull ribs under the overhangs.
	for i in 34:
		var x := -140.0 + 10.0 * float(i)
		var hw := _ship_hw(stations, x)
		lm.box("Frame", Vector3(x, 190.5, 0), Vector3(0.8, 5.0, hw * 1.7), Basis(), 0.0)
	# Infinity pool on the south edge, with its deck and edge.
	lm.box("Water", Vector3(40.0, 199.9, -11.0), Vector3(150.0, 0.6, 8.0))
	lm.box("Frame", Vector3(40.0, 199.8, -15.4), Vector3(150.0, 0.8, 0.8), Basis(), 0.0)
	for i in 20:
		lm.box("Frame", Vector3(-30.0 + 7.4 * float(i), 200.0, -6.2), Vector3(2.0, 0.4, 0.8), Basis(), 0.0)
	# Glass balustrade round the deck edge.
	var deck := _ship(stations, 0.94)
	for i in deck.size():
		var a: Vector2 = deck[i]
		var b: Vector2 = deck[(i + 1) % deck.size()]
		lm.box("Glass", Vector3((a.x + b.x) * 0.5, 200.2, (a.y + b.y) * 0.5), Vector3(a.distance_to(b), 1.2, 0.1),
			Basis(Vector3.UP, -atan2(b.y - a.y, b.x - a.x)), 0.0)
	# Garden: tree clumps and palms on the north half.
	for i in 26:
		var x := -135.0 + 12.5 * float(i)
		var h := 7.0 if i == 11 else 4.0 + 2.6 * absf(sin(float(i) * 1.7))
		var z := 9.0 + 3.0 * sin(float(i) * 2.3)
		U.dome(lm, "Trees", Vector3(x, 199.6, z), 3.4, h, 10, 4)
		var px := x + 6.0
		lm.frustum("Hull", Vector3(px, 199.6, z - 2.5), 0.25, 0.18, 5.0, 6)
		for k in 6:
			var a := TAU * float(k) / 6.0
			lm.beam("Trees", Vector3(px, 204.6, z - 2.5), Vector3(px + cos(a) * 2.4, 203.8, z - 2.5 + sin(a) * 2.4),
				0.8, 0.1)
	# Observation deck on the cantilever.
	lm.box("Frame", Vector3(185.0, 200.4, 0), Vector3(16.0, 1.0, 8.0))
	lm.commit(model)

## Centre z of the curved east leg at height fraction t (0..1).
static func _leg_z(t: float) -> float:
	return 5.5 + 20.5 * pow(1.0 - t, 1.7)

static func _ship(stations: Array, width: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for s in stations:
		p.append(Vector2(float(s[0]), float(s[1]) * width))
	for i in range(stations.size() - 1, -1, -1):
		var s: Array = stations[i]
		p.append(Vector2(float(s[0]), -float(s[1]) * width))
	return p

## Half-width of the ship's hull at station x (linear between stations).
static func _ship_hw(stations: Array, x: float) -> float:
	for i in stations.size() - 1:
		var a: Array = stations[i]
		var b: Array = stations[i + 1]
		if x >= float(a[0]) and x <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / (float(b[0]) - float(a[0])))
	return 1.0

## Monas, the National Monument (132 m): the 117.7 m Italian-marble
## obelisk (8 m wide at its foot) rising from the goblet-shaped platform
## (cawan, 45 m square, 17 m high, a railed terrace on top) on its
## plaza, the glazed viewing room under the 115 m top platform, and the
## 14 m gilded Flame of Independence on its 3 m bronze goblet.
static func monas(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDEAE0", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#A8A397", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#2F3E46"))
	lm.box("Plinth", Vector3(0, 0.6, 0), Vector3(84.0, 1.2, 84.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for i in 4:
			lm.box("Plinth", b * Vector3(0, 0.15 + 0.3 * float(i), 43.4 - 0.4 * float(i)), Vector3(14.0, 0.3, 0.4), b, 0.0)
	lm.box("Plinth", Vector3(0, 2.4, 0), Vector3(30.0, 2.4, 30.0))
	# The goblet: square, flaring out on a concave curve to 45 m at 17 m.
	var k := 1.0 / cos(PI / 4.0)
	var prof := PackedVector2Array()
	for i in 9:
		var t := float(i) / 8.0
		prof.append(Vector2((13.0 + 9.5 * pow(t, 2.2)) * k, 3.6 + 12.4 * t))
	prof.append(Vector2(22.5 * k, 16.4))
	prof.append(Vector2(22.9 * k, 16.6))
	prof.append(Vector2(22.9 * k, 17.0))
	lm.lathe("Marble", Vector3.ZERO, prof, 4, 1.0, 1.0, PI / 4.0, false)
	# Railing round the cup's terrace.
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for i in 30:
			var x := -21.75 + 43.5 * float(i) / 29.0
			lm.box("Plinth", b * Vector3(x, 17.55, 22.1), Vector3(0.15, 1.1, 0.15), b, 0.0)
		lm.box("Plinth", b * Vector3(0, 18.1, 22.1), Vector3(44.4, 0.12, 0.2), b, 0.0)
	# Obelisk: plinth, 4 m half-width at the foot tapering to 2.9 m.
	lm.box("Marble", Vector3(0, 17.6, 0), Vector3(10.0, 1.2, 10.0))
	lm.spire("Marble", Vector3(0, 18.2, 0), 4.0, 91.8, 2.9)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.beam("Marble", Vector3(sx * 4.0, 18.2, sz * 4.0), Vector3(sx * 2.9, 110.0, sz * 2.9), 0.45, 0.45)
	for y in [40.0, 70.0, 100.0]:
		var hw := lerpf(4.0, 2.9, (y - 18.2) / 91.8) + 0.05
		lm.box("Marble", Vector3(0, y, 0), Vector3(hw * 2.0, 0.3, hw * 2.0), Basis(), 0.0)
	# Viewing room and top platform (115 m) flaring out from the shaft.
	lm.lathe("Marble", Vector3(0, 108.0, 0), PackedVector2Array([Vector2(2.95 * k, 0), Vector2(5.5 * k, 2.0)]),
		4, 1.0, 1.0, PI / 4.0, false)
	lm.box("Glass", Vector3(0, 111.8, 0), Vector3(10.4, 3.4, 10.4))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for i in 7:
			lm.box("Marble", b * Vector3(-4.8 + 1.6 * float(i), 111.8, 5.25), Vector3(0.25, 3.4, 0.2), b, 0.0)
	lm.box("Marble", Vector3(0, 114.25, 0), Vector3(12.0, 1.5, 12.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		for i in 12:
			lm.box("Plinth", b * Vector3(-5.5 + float(i), 115.5, 5.8), Vector3(0.1, 1.0, 0.1), b, 0.0)
		lm.box("Plinth", b * Vector3(0, 116.0, 5.8), Vector3(11.8, 0.1, 0.12), b, 0.0)
	# Bronze goblet (3 m) and the flame (14 m) to 132 m.
	lm.lathe("Gold", Vector3(0, 115.0, 0), PackedVector2Array([Vector2(2.2, 0), Vector2(2.2, 0.3),
		Vector2(0.9, 0.6), Vector2(0.8, 1.5), Vector2(1.6, 2.2), Vector2(3.0, 2.8), Vector2(3.0, 3.0)]), 24)
	lm.lathe("Gold", Vector3(0, 118.0, 0), PackedVector2Array([Vector2(2.8, 0), Vector2(3.0, 1.5),
		Vector2(2.6, 4.0), Vector2(1.9, 7.0), Vector2(1.2, 10.0), Vector2(0.5, 12.5), Vector2(0.0, 14.0)]), 20)
	for i in 8:
		var a0 := TAU * float(i) / 8.0
		var r0 := 2.6
		var prev := Vector3(cos(a0) * r0, 118.5, sin(a0) * r0)
		var top := 8.0 + 4.0 * absf(sin(float(i) * 1.9))
		for j in 6:
			var t := float(j + 1) / 6.0
			var a := a0 + t * 0.9
			var r := lerpf(r0, 0.4, t) + sin(t * PI) * 0.6
			var p := Vector3(cos(a) * r, 118.5 + top * t, sin(a) * r)
			lm.beam("Gold", prev, p, lerpf(1.3, 0.2, t), lerpf(0.6, 0.15, t))
			prev = p
	lm.commit(model)
