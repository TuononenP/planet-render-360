class_name LandmarkEgGiza
extends RefCounted

## The second and third Giza pyramids in true metres as they stand
## today: Khafre with its surviving smooth Tura casing cap and granite
## foot, Menkaure with its red-granite lower courses and the vertical
## gash cut into the north face. Built about the pyramid centre, faces
## to the compass, mortuary temple on the east (+X), north is -Z.

# --- Pyramid of Khafre ---

## 215.25 m square (slope 53.13 deg, 4:3), 143.5 m when built, 136.4 m
## today: stripped core in roughly 1 m courses, the casing cap over the
## top 33 m with its ragged lower edge, a granite foot course, the two
## north entrances (11.5 m up the face and in the pavement), the paved
## court and its enclosure wall, the bedrock scarp cut on the north and
## west, the mortuary temple and causeway east and the satellite pyramid
## south.
static func khafre(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Core", LandmarkMaterials.pbr("stone", "#C9B48A", 3.8))
	lm.use("Casing", LandmarkMaterials.pbr("stone", "#E2D6B4", 5.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8E5E4B", 2.4))
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#B59C74", 6.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	var hb := 107.625
	var apex := 143.5
	var top := 136.4
	lm.box("Sand", Vector3(0, 0.1, 0), Vector3(hb * 2.0 + 60.0, 0.2, hb * 2.0 + 60.0), Basis(), 0.0)
	lm.box("Casing", Vector3(0, 0.25, 0), Vector3(hb * 2.0 + 20.0, 0.3, hb * 2.0 + 20.0))
	LandmarkEgParts.smooth(lm, "Granite", Vector3.ZERO, hb, apex, 0.0, 3.4)
	LandmarkEgParts.courses(lm, "Core", Vector3.ZERO, hb, apex, 3.4, 104.0, 1.1)
	LandmarkEgParts.smooth(lm, "Casing", Vector3.ZERO, hb, apex, 104.0, top, true)
	_ragged_casing(lm, "Casing", hb, apex, 104.0, 7.0, 18)
	# North entrances: the upper one 11.5 m up the face, the lower cut in the pavement.
	_face_door(lm, "Dark", hb, apex, 11.5, 1.05, 1.2, 12.0)
	lm.box("Dark", Vector3(12.0, 0.42, -hb - 6.0), Vector3(1.1, 0.05, 2.4), Basis(), 0.0)
	# Enclosure wall round the paved court, ruined to a metre or two.
	var ew := hb + 10.5
	for s in [-1.0, 1.0]:
		LandmarkEgParts.wall(lm, "Core", Vector2(-ew, s * ew), Vector2(ew, s * ew), 1.6, 3.0)
		LandmarkEgParts.wall(lm, "Core", Vector2(s * ew, -ew), Vector2(s * ew, ew), 1.6, 3.0)
	# Bedrock scarp left where the plateau was cut down on the north and west.
	var sc := hb + 24.0
	lm.box("Rock", Vector3(-sc - 6.0, 4.0, -12.0), Vector3(12.0, 8.0, hb * 2.0 + 72.0))
	lm.box("Rock", Vector3(10.0, 3.0, -sc - 6.0), Vector3(hb * 2.0 + 48.0, 6.0, 12.0))
	for i in 9:
		lm.box("Rock", Vector3(-sc + 0.6, 1.5 + 0.7 * float(i % 3), -hb + 24.0 * i), Vector3(2.4, 3.0, 9.0))
	LandmarkEgParts.courses(lm, "Core", Vector3(0, 0, 132.0), 10.5, 14.0, 0.0, 12.0, 1.0, true)
	_khafre_temple(lm)
	lm.commit(model)

## Mortuary temple (110 x 49 m) east of the pyramid: entrance hall, the
## T-shaped hall of granite pillars under architraves, the open court
## ringed by pillars that once fronted statues, five statue niches and
## the offering hall, and the start of the 494 m causeway.
static func _khafre_temple(lm: LandmarkMesh) -> void:
	lm.box("Core", Vector3(146.0, 0.7, 0), Vector3(66.0, 1.4, 104.0))
	lm.box("Core", Vector3(178.0, 4.4, 0), Vector3(4.0, 6.0, 104.0))
	for s in [-1.0, 1.0]:
		lm.box("Core", Vector3(146.0, 4.4, s * 50.0), Vector3(66.0, 6.0, 4.0))
		lm.box("Core", Vector3(116.0, 4.4, s * 30.0), Vector3(4.0, 6.0, 40.0))
		lm.box("Core", Vector3(146.0, 3.9, s * 22.0), Vector3(30.0, 5.0, 2.4))
	# Open court: pillars round the edge, architraves on top.
	for i in 7:
		for x in [134.0, 158.0]:
			lm.box("Granite", Vector3(x, 4.4, -18.0 + 6.0 * i), Vector3(1.4, 6.0, 1.4))
		for z in [-18.0, 18.0]:
			lm.box("Granite", Vector3(134.0 + 4.0 * i, 4.4, z), Vector3(1.4, 6.0, 1.4))
	for x in [134.0, 158.0]:
		lm.box("Granite", Vector3(x, 7.9, 0), Vector3(1.6, 1.0, 37.6))
	for z in [-18.0, 18.0]:
		lm.box("Granite", Vector3(146.0, 7.9, z), Vector3(25.6, 1.0, 1.6))
	# T-shaped pillar hall at the front.
	for i in 6:
		for x in [166.0, 171.0]:
			lm.box("Granite", Vector3(x, 4.4, -25.0 + 10.0 * i), Vector3(1.6, 6.0, 1.6))
	for x in [166.0, 171.0]:
		lm.box("Granite", Vector3(x, 7.9, 0), Vector3(1.8, 1.0, 52.0))
	lm.box("Core", Vector3(168.5, 8.9, 0), Vector3(9.0, 1.0, 54.0))
	# Statue niches in the west wall and the dark sanctuary door.
	for i in 5:
		lm.box("Dark", Vector3(120.1, 4.0, -12.0 + 6.0 * i), Vector3(0.3, 4.0, 2.4), Basis(), 0.0)
	# Causeway with its parapet walls, running off east.
	lm.box("Core", Vector3(198.0, 1.5, 0), Vector3(36.0, 3.0, 8.0))
	for s in [-1.0, 1.0]:
		lm.box("Core", Vector3(198.0, 3.6, s * 3.6), Vector3(36.0, 1.2, 0.8))
	lm.box("Core", Vector3(118.0, 4.0, 0), Vector3(6.0, 8.0, 10.0))

## Strips of surviving casing hanging below the cap: per face `n` strips
## laid on the true face plane, ending between `y_top - drop` and y_top.
static func _ragged_casing(lm: LandmarkMesh, key: String, hb: float, apex: float, y_top: float,
		drop: float, n: int) -> void:
	for f in 4:
		var out := Vector3(sin(PI * 0.5 * f), 0, cos(PI * 0.5 * f))
		var rt := Vector3.UP.cross(out)
		var fn := (out * apex + Vector3.UP * hb).normalized()
		var at := func(x: float, y: float) -> Vector3:
			var half := hb * (1.0 - y / apex)
			return out * half + rt * x * half + fn * 0.06 + Vector3(0, y, 0)
		for i in n:
			var x0 := -1.0 + 2.0 * float(i) / float(n)
			var x1 := -1.0 + 2.0 * float(i + 1) / float(n)
			var t := 0.5 + 0.5 * sin(float(i) * 2.3 + float(f) * 1.7)
			var yb := y_top - drop * t * (1.0 - absf(x0 + x1) * 0.35)
			lm.quad(key, at.call(x0, yb), at.call(x1, yb), at.call(x1, y_top + 0.2), at.call(x0, y_top + 0.2), fn)

## Dark entrance passage mouth `w` x `h` on the north (-Z) face, `y` up
## the face and `x` east of the centre line.
static func _face_door(lm: LandmarkMesh, key: String, hb: float, apex: float, y: float, w: float,
		h: float, x: float) -> void:
	var n := Vector3(0, hb, -apex).normalized()
	var z0 := -hb * (1.0 - y / apex)
	var z1 := -hb * (1.0 - (y + h) / apex)
	var o := n * 0.12
	lm.quad(key, Vector3(x - w * 0.5, y, z0) + o, Vector3(x + w * 0.5, y, z0) + o,
		Vector3(x + w * 0.5, y + h, z1) + o, Vector3(x - w * 0.5, y + h, z1) + o, n)

# --- Pyramid of Menkaure ---

## 104.6 m square (slope 51.3 deg), 65.5 m when built, 61 m today: the
## lower 16 courses (16 m) of red granite casing (left undressed except
## round the entrance), coursed limestone core above, the dark gash down
## the north (-Z) face, the entrance 4 m up the north face, the mortuary
## temple and causeway east and the three queens' pyramids south (G3-a a
## true pyramid, G3-b and G3-c left as four-step pyramids).
static func menkaure(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Core", LandmarkMaterials.pbr("stone", "#C2AB80", 3.4))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8A5645", 2.2))
	lm.use("Gash", LandmarkMaterials.pbr("stone", "#3C3228", 3.0))
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	var hb := 52.3
	var apex := 65.5
	var top := 61.0
	lm.box("Sand", Vector3(0, 0.1, 30.0), Vector3(hb * 2.0 + 90.0, 0.2, hb * 2.0 + 110.0), Basis(), 0.0)
	LandmarkEgParts.courses(lm, "Granite", Vector3.ZERO, hb, apex, 0.0, 16.0, 1.0)
	# Dressed granite apron round the entrance on the north face.
	_face_patch(lm, "Granite", hb, apex, 0.0, 9.0, 12.0)
	_bosses(lm, "Granite", hb, apex, 16)
	LandmarkEgParts.courses(lm, "Core", Vector3.ZERO, hb, apex, 16.0, top, 0.9, true)
	_gash(lm, hb, apex, 60.0, 24.0, 7.5, 3.0)
	_entrance(lm, hb, apex, 4.0)
	# Queens' pyramids on the south side: G3-a cased, G3-b and G3-c stepped.
	LandmarkEgParts.courses(lm, "Core", Vector3(-34.0, 0, hb + 36.0), 22.0, 28.5, 0.0, 21.5, 1.0, true)
	LandmarkEgParts.smooth(lm, "Granite", Vector3(-34.0, 0, hb + 36.0), 22.0, 28.5, 0.0, 2.0)
	for qx in [6.0, 40.0]:
		_step_pyramid(lm, "Core", Vector3(qx, 0, hb + 29.5), 15.5, 4, 3.5)
		lm.box("Core", Vector3(qx + 19.0, 1.4, hb + 29.5), Vector3(5.0, 2.8, 9.0))
	lm.box("Core", Vector3(-6.0, 1.6, hb + 36.0), Vector3(6.0, 3.2, 12.0))
	_menkaure_temple(lm, hb)
	lm.commit(model)

## Mortuary temple: mud-brick-finished limestone walls round an open
## court, the granite-cased portico and offering hall against the
## pyramid, and the causeway going east.
static func _menkaure_temple(lm: LandmarkMesh, hb: float) -> void:
	lm.box("Core", Vector3(hb + 24.0, 0.7, 0), Vector3(40.0, 1.4, 54.0))
	lm.box("Core", Vector3(hb + 42.0, 2.9, 0), Vector3(4.0, 4.4, 54.0))
	for s in [-1.0, 1.0]:
		lm.box("Core", Vector3(hb + 24.0, 2.9, s * 25.0), Vector3(40.0, 4.4, 4.0))
		lm.box("Core", Vector3(hb + 31.0, 2.4, s * 10.0), Vector3(18.0, 3.4, 2.0))
	lm.box("Core", Vector3(hb + 9.0, 3.4, 0), Vector3(10.0, 5.4, 46.0))
	for z in [-9.0, -3.0, 3.0, 9.0]:
		lm.box("Granite", Vector3(hb + 16.5, 4.0, z), Vector3(1.6, 5.2, 1.6))
	lm.box("Granite", Vector3(hb + 16.5, 7.0, 0), Vector3(1.8, 0.8, 20.0))
	lm.box("Gash", Vector3(hb + 4.0, 3.0, 0), Vector3(0.3, 3.4, 2.4), Basis(), 0.0)
	lm.box("Core", Vector3(hb + 58.0, 1.2, 0), Vector3(28.0, 2.4, 7.0))
	for s in [-1.0, 1.0]:
		lm.box("Core", Vector3(hb + 58.0, 2.9, s * 3.1), Vector3(28.0, 1.0, 0.8))

## The undressed granite casing: every block of the lowest `courses`
## courses still carries the rough boss the masons meant to dress off,
## except on the dressed apron round the north entrance.
static func _bosses(lm: LandmarkMesh, key: String, hb: float, apex: float, courses: int) -> void:
	for f in 4:
		var out := Vector3(sin(PI * 0.5 * f), 0, cos(PI * 0.5 * f))
		var rt := Vector3.UP.cross(out)
		var fn := (out * apex + Vector3.UP * hb).normalized()
		var basis := Basis(rt, fn.cross(rt).normalized(), fn)
		for k in courses:
			var y := float(k) + 0.5
			var half := hb * (1.0 - y / apex)
			var n := int(half * 2.0 / 3.2)
			for i in n:
				var x := -half + (float(i) + 0.5 + 0.5 * float(k % 2)) * half * 2.0 / float(n + 1)
				if f == 2 and absf(x) < 6.5 and y < 9.0:
					continue
				var j := 0.5 + 0.5 * sin(float(i * 7 + k * 3 + f))
				lm.box(key, out * half + rt * x + Vector3(0, y, 0) + fn * 0.15,
					Vector3(1.8 + j, 0.6, 0.3 + 0.2 * j), basis, 0.0)

## Smoothed band of the north (-Z) face `w` wide from y0 to y1.
static func _face_patch(lm: LandmarkMesh, key: String, hb: float, apex: float, y0: float, y1: float,
		w: float) -> void:
	var n := Vector3(0, hb, -apex).normalized()
	var o := n * 0.35
	var z0 := -hb * (1.0 - y0 / apex)
	var z1 := -hb * (1.0 - y1 / apex)
	lm.quad(key, Vector3(-w * 0.5, y0, z0) + o, Vector3(w * 0.5, y0, z0) + o, Vector3(w * 0.5, y1, z1) + o,
		Vector3(-w * 0.5, y1, z1) + o, n)

## North entrance `y` up the face: a dark passage mouth framed by a
## granite lintel and jambs.
static func _entrance(lm: LandmarkMesh, hb: float, apex: float, y: float) -> void:
	var n := Vector3(0, hb, -apex).normalized()
	var z := -hb * (1.0 - y / apex)
	var o := n * 0.45
	lm.quad("Gash", Vector3(-0.6, y, z) + o, Vector3(0.6, y, z) + o,
		Vector3(0.6, y + 1.3, z + 1.3 * hb / apex) + o, Vector3(-0.6, y + 1.3, z + 1.3 * hb / apex) + o, n)
	lm.box("Granite", Vector3(0, y + 1.6, z + 1.0), Vector3(3.2, 0.8, 1.2))

## Unfinished step pyramid: `steps` battered tiers on a 2 hb square, each
## `tier` m high.
static func _step_pyramid(lm: LandmarkMesh, key: String, c: Vector3, hb: float, steps: int,
		tier: float) -> void:
	var w := hb * 2.0
	for i in steps:
		var lean := tier * 0.25
		LandmarkEgParts.taper(lm, key, c + Vector3(0, tier * i, 0), w, w, w - lean * 2.0, w - lean * 2.0, tier)
		w -= lean * 2.0 + w * 0.12

## The cleft cut by Uthman in 1196: a wedge `w_top` wide at y_top
## narrowing to `w_bot` at y_bot, cut 3 m back into the north face with
## dark side walls and back.
static func _gash(lm: LandmarkMesh, hb: float, apex: float, y_top: float, y_bot: float,
		w_top: float, w_bot: float) -> void:
	var n := Vector3(0, hb, -apex).normalized()
	var pts: Array[Vector3] = []
	var back: Array[Vector3] = []
	for e in [[y_bot, w_bot], [y_top, w_top]]:
		var y: float = e[0]
		var w: float = e[1]
		var z := -hb * (1.0 - y / apex)
		pts.append(Vector3(-w * 0.5, y, z) + n * 0.4)
		pts.append(Vector3(w * 0.5, y, z) + n * 0.4)
		back.append(Vector3(-w * 0.35, y, z + 3.0))
		back.append(Vector3(w * 0.35, y, z + 3.0))
	lm.quad("Gash", back[0], back[1], back[3], back[2], n)
	lm.quad("Gash", pts[0], back[0], back[2], pts[2], Vector3.RIGHT)
	lm.quad("Gash", back[1], pts[1], pts[3], back[3], Vector3.LEFT)
	lm.quad("Gash", pts[0], pts[1], back[1], back[0], Vector3.UP)
