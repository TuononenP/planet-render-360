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

## Petronas Towers (451.9 m): two 88-storey glass-and-steel towers on an
## eight-pointed star plan with round lobes in the notches, setting back
## in five stages to a crown and a 73 m spire; the two-level skybridge at
## 170 m rests on inverted-V struts. Towers along X.
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
		lm.box("Podium", c + Vector3(0, 4.0, 0), Vector3(72.0, 10.0, 72.0))
		for st in stages:
			var y0: float = st[0]
			var y1: float = st[1]
			var sc: float = st[2]
			lm.poly_prism("Glass", _star(c, sc), y0, y1)
			for k in 8:
				var a := TAU * float(k) / 8.0
				lm.box("Steel", c + Vector3(cos(a), 0, sin(a)) * STAR_R * sc + Vector3(0, (y0 + y1) * 0.5, 0),
					Vector3(1.4, y1 - y0, 1.4))
		# Round lobes in the star's notches, up to the first setback.
		for k in 8:
			var a := TAU * (float(k) + 0.5) / 8.0
			lm.frustum("Glass", c + Vector3(cos(a), 0, sin(a)) * 19.0, 4.7, 4.7, 258.0, 12)
		for y in [43.0, 86.0, 129.0, 172.0, 215.0, 258.0, 300.0, 340.0]:
			var sc := 1.0 if y <= 258.0 else (0.82 if y <= 314.0 else 0.65)
			lm.poly_prism("Steel", _star(c, sc * 1.015), y, y + 1.2)
		# Crown and spire to 451.9 m.
		lm.lathe("Steel", c + Vector3(0, 378.6, 0), PackedVector2Array([Vector2(7.0, 0), Vector2(7.0, 13.0),
			Vector2(6.0, 16.0), Vector2(4.2, 22.0), Vector2(3.4, 24.0), Vector2(2.6, 30.0),
			Vector2(1.8, 45.0), Vector2(1.0, 60.0), Vector2(0.3, PETRONAS_TOP_M - 378.6)]), 16)
		for y in [392.0, 410.0, 430.0]:
			lm.frustum("Steel", c + Vector3(0, y, 0), 2.6, 2.6, 1.4, 12)
	# Skybridge: glazed two-storey deck and its supporting inverted V.
	var half := PETRONAS_X - STAR_R
	lm.box("Glass", Vector3(0, 169.0, 0), Vector3(half * 2.0, 12.0, 9.0))
	lm.box("Steel", Vector3(0, 175.5, 0), Vector3(half * 2.0, 1.0, 10.0))
	lm.box("Steel", Vector3(0, 162.5, 0), Vector3(half * 2.0, 1.0, 10.0))
	for z in [-4.0, 4.0]:
		for s in [-1.0, 1.0]:
			lm.beam("Steel", Vector3(0, 162.0, z), Vector3(s * (half - 1.0), 105.0, z), 2.2, 2.2)
	lm.commit(model)

## The 16-vertex star (points on the axes) at `scale`, around `c`.
static func _star(c: Vector3, scale: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for k in 16:
		var a := TAU * float(k) / 16.0
		var r := (STAR_R if k % 2 == 0 else STAR_NOTCH) * scale
		p.append(Vector2(c.x + cos(a) * r, c.z + sin(a) * r))
	return p

## Marina Bay Sands (207 m): three 55-storey hotel towers, each a pair of
## slabs leaning together, joined at the top by the 340 m SkyPark boat
## (tapering hull, garden, infinity pool) with its 66 m cantilever at the
## north end. Built along X (cantilever to +X), turned onto the real axis
## by the registry yaw.
static func marina_bay_sands(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.paint("#789BAA", 0.25, 0.4))
	lm.use("Frame", LandmarkMaterials.pbr("concrete", "#E4E1DA", 3.0))
	lm.use("Hull", LandmarkMaterials.pbr("concrete", "#CFCBC2", 3.0))
	lm.use("Water", LandmarkMaterials.pbr("concrete", "#5FA3B8", 4.0, 0.08))
	lm.use("Trees", LandmarkMaterials.pbr("forest", "#41632F", 4.0))
	lm.box("Hull", Vector3(0, 3.0, 0), Vector3(300.0, 10.0, 96.0))
	for cx in [-105.0, 0.0, 105.0]:
		for s in [-1.0, 1.0]:
			lm.beam("Glass", Vector3(cx, 3.0, s * 26.0), Vector3(cx, 192.0, s * 5.5), 50.0, 11.0,
				Vector3.RIGHT, true)
			for e in [-1.0, 1.0]:
				lm.beam("Frame", Vector3(cx + e * 25.2, 3.0, s * 26.0), Vector3(cx + e * 25.2, 192.0, s * 5.5),
					1.6, 11.6, Vector3.RIGHT)
	# SkyPark ship: half-width by station along X, hull then deck.
	var stations := [[-147.0, 3.0], [-140.0, 13.0], [-100.0, 19.0], [0.0, 19.5], [130.0, 19.0],
		[170.0, 14.0], [190.0, 7.0], [196.5, 1.5]]
	lm.poly_prism("Hull", _ship(stations, 0.78), 187.0, 193.0)
	lm.poly_prism("Frame", _ship(stations, 1.0), 193.0, 199.0)
	lm.poly_prism("Hull", _ship(stations, 0.94), 199.0, 199.6)
	lm.box("Water", Vector3(40.0, 199.9, -11.0), Vector3(150.0, 0.6, 8.0))
	for i in 26:
		var x := -135.0 + 12.5 * float(i)
		var h := 7.5 if i == 11 else 4.0 + 3.0 * absf(sin(float(i) * 1.7))
		U.dome(lm, "Trees", Vector3(x, 199.6, 9.0 + 3.0 * sin(float(i) * 2.3)), 3.4, h, 8, 3)
	lm.commit(model)

static func _ship(stations: Array, width: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for s in stations:
		p.append(Vector2(float(s[0]), float(s[1]) * width))
	for i in range(stations.size() - 1, -1, -1):
		var s: Array = stations[i]
		p.append(Vector2(float(s[0]), -float(s[1]) * width))
	return p

## Monas, the National Monument (132 m): the white marble obelisk on its
## cup-shaped platform and stepped base, the viewing gallery at 115 m and
## the gilded flame (14.5 m) on top.
static func monas(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDEAE0", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#A8A397", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#2F3E46"))
	lm.box("Plinth", Vector3(0, 0.5, 0), Vector3(84.0, 4.0, 84.0))
	lm.box("Plinth", Vector3(0, 3.0, 0), Vector3(64.0, 1.0, 64.0))
	lm.spire("Marble", Vector3(0, 3.5, 0), 15.0, 13.5, 22.5)
	lm.box("Marble", Vector3(0, 17.5, 0), Vector3(46.0, 1.0, 46.0))
	lm.spire("Marble", Vector3(0, 18.0, 0), 8.5, 94.0, 4.8)
	# Viewing gallery: slab, glazed pavilion, parapet.
	lm.box("Marble", Vector3(0, 113.0, 0), Vector3(17.0, 2.0, 17.0))
	lm.box("Glass", Vector3(0, 115.75, 0), Vector3(11.0, 3.5, 11.0))
	lm.box("Marble", Vector3(0, 117.25, 0), Vector3(13.0, 0.5, 13.0))
	lm.lathe("Gold", Vector3(0, 117.5, 0), PackedVector2Array([Vector2(3.0, 0), Vector2(3.5, 1.5),
		Vector2(3.2, 4.0), Vector2(2.4, 7.0), Vector2(1.5, 10.0), Vector2(0.7, 12.5),
		Vector2(0.0, 14.5)]), 12)
	lm.commit(model)
