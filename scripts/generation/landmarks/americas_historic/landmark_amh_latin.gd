class_name LandmarkAmhLatin
extends RefCounted

## Havana's neoclassical El Capitolio (1926-29) on the Paseo del Prado,
## in true metres. Mexico City's cathedral is in LandmarkAmhCathedral.

const CAPITOLIO_TOP_M := 91.7

## El Capitolio: the 207 x 91 m block on its rusticated basement; the two
## long wings (end pavilions, colossal pilasters, framed windows in two
## storeys, cornice and balustrade, hipped roofs) either side of the
## raised centre; the 36 m portico of twelve smooth granite Ionic
## columns in two rows of six (14 m, 1.55 m through) under its
## entablature and attic, above the 56-step granite stair flanked by
## Zanelli's two 6.5 m bronzes (Work, the Tutelary Virtue); and the
## forward dome after the Pantheon in Paris: colonnaded drum, attic,
## ribbed stone dome, lantern of ten columns and gilded finial, to
## 91.7 m. The front faces +X; yaw turns it onto the Paseo del Prado.
static func el_capitolio(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#DCD3BC", 3.0))
	lm.use("Base", LandmarkMaterials.pbr("limestone", "#C4BBA3", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("stone", "#B3AFA5", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#7C8584", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("limestone", "#E0DBCD", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	lm.use("Bronze", LandmarkMaterials.paint("#5C4B34", 0.5, 0.5))
	lm.use("Gold", LandmarkMaterials.gold())
	# Basement with rustication grooves, the raised centre block.
	lm.box("Base", Vector3(-6.0, 4.2, 0), Vector3(72.0, 8.4, 205.0))
	for j in 4:
		lm.box("Base", Vector3(-6.0, 1.6 + 1.9 * float(j), 0), Vector3(72.6, 0.25, 205.6), Basis(), 0.0)
	lm.box("Base", Vector3(-6.0, 8.6, 0), Vector3(73.0, 0.5, 206.0))
	lm.box("Wall", Vector3(-6.0, 19.7, 0), Vector3(72.0, 22.6, 36.0))
	lm.box("Wall", Vector3(-6.0, 31.6, 0), Vector3(74.0, 1.2, 38.0))
	for s in [-1.0, 1.0]:
		_capitolio_wing(lm, float(s))
	for s in [-1.0, 1.0]:
		LandmarkDetail.window(lm, "Wall", "Windows", Vector3(-42.0, 20.0, s * 9.0), Vector3.LEFT, 2.0,
			4.6, true, 0.3)
	_capitolio_portico(lm)
	_capitolio_dome(lm, Vector3(6.0, 32.2, 0))
	lm.commit(model)

## One wing (s = -1 south, +1 north): the block, its cornice, balustrade
## and hipped roof, the end pavilion, colossal pilasters and two storeys
## of framed windows on the front, back and end.
static func _capitolio_wing(lm: LandmarkMesh, s: float) -> void:
	var zc := s * 60.25
	lm.box("Wall", Vector3(-6.0, 18.5, zc), Vector3(72.0, 20.2, 84.5))
	lm.box("Wall", Vector3(-6.0, 29.2, zc), Vector3(74.0, 1.2, 86.5))
	LandmarkNaParts.hip(lm, "Roof", Vector3(-6.0, 29.8, zc), Basis(), 34.0, 41.0, 0.8, 3.0)
	LandmarkNaParts.balusters(lm, "Wall", Vector3(30.6, 29.8, zc - 41.5),
		Vector3(30.6, 29.8, zc + 41.5), 1.2, 0.6, 5.6)
	# End pavilion projecting 2 m on the front, back and end.
	var pz := zc + s * 34.0
	lm.box("Wall", Vector3(-6.0, 19.0, pz), Vector3(76.0, 21.2, 16.5))
	lm.box("Wall", Vector3(-6.0, 29.9, pz), Vector3(77.0, 1.2, 17.5))
	for x in [32.1, -44.1]:
		var n := Vector3(signf(x), 0, 0)
		for dz in [-6.6, 6.6]:
			lm.box("Wall", Vector3(x + signf(x) * 0.3, 19.0, pz + dz), Vector3(0.6, 20.0, 1.6))
		LandmarkDetail.window(lm, "Wall", "Windows", Vector3(x, 14.2, pz), n, 2.6, 5.0, true, 0.35)
		LandmarkDetail.window(lm, "Wall", "Windows", Vector3(x, 23.6, pz), n, 2.2, 3.6, false, 0.35)
	# Colossal pilasters and windows on the long faces.
	for x in [30.0, -42.0]:
		var n := Vector3(signf(x), 0, 0)
		for i in 11:
			var z := zc - s * 41.0 + s * 6.6 * float(i)
			lm.box("Wall", Vector3(x + signf(x) * 0.3, 18.8, z), Vector3(0.6, 19.6, 1.2))
			lm.box("Wall", Vector3(x + signf(x) * 0.5, 28.2, z), Vector3(1.0, 1.0, 1.6))
			if i < 10:
				var wz := z + s * 3.3
				LandmarkDetail.window(lm, "Wall", "Windows", Vector3(x, 14.0, wz), n, 1.9, 4.2, true,
					0.3)
				LandmarkDetail.window(lm, "Wall", "Windows", Vector3(x, 23.4, wz), n, 1.7, 2.8, false,
					0.3)
	# Windows on the wing's end.
	var ez := zc + s * 42.25
	var en := Vector3(0, 0, s)
	for i in 7:
		var x := -36.0 + 10.0 * float(i)
		if absf(x + 6.0) < 9.0:
			continue
		LandmarkDetail.window(lm, "Wall", "Windows", Vector3(x, 14.0, ez), en, 1.9, 4.2, true, 0.3)
		LandmarkDetail.window(lm, "Wall", "Windows", Vector3(x, 23.4, ez), en, 1.7, 2.8, false, 0.3)

## The portico (12 smooth Ionic columns in two rows of six on the
## podium, entablature, attic and doors behind), the 56-step stair with
## its side walls and Zanelli's two bronzes on their pedestals.
static func _capitolio_portico(lm: LandmarkMesh) -> void:
	lm.box("Base", Vector3(38.0, 4.2, 0), Vector3(16.0, 8.4, 48.0))
	lm.box("Base", Vector3(38.0, 8.6, 0), Vector3(16.6, 0.4, 48.6))
	for x in [34.0, 41.5]:
		for i in 6:
			LandmarkDetail.column(lm, "Wall", Vector3(x, 8.8, -15.0 + 6.0 * float(i)), 0.78, 14.1,
				"ionic", 0)
	# Entablature: architrave, frieze, dentilled cornice; the attic.
	lm.box("Wall", Vector3(37.5, 23.6, 0), Vector3(12.5, 1.4, 34.0))
	lm.box("Wall", Vector3(37.5, 25.2, 0), Vector3(12.2, 1.8, 33.8))
	LandmarkDetail.cornice(lm, "Wall", Vector3(43.6, 26.1, -17.0), Vector3(43.6, 26.1, 17.0),
		Vector3.RIGHT, 1.1, true)
	lm.box("Wall", Vector3(37.4, 26.65, 0), Vector3(13.0, 1.1, 35.2))
	lm.box("Wall", Vector3(36.5, 28.6, 0), Vector3(11.0, 2.8, 33.0))
	lm.box("Wall", Vector3(36.5, 30.15, 0), Vector3(11.6, 0.5, 33.6))
	# Three bronze doors in the back wall of the portico.
	for z in [-7.5, 0.0, 7.5]:
		var w: float = 5.0 if z == 0.0 else 3.6
		LandmarkAmhParts.opening(lm, "Bronze", Vector3(30.1, 8.8 + w, z), Basis(Vector3.UP, PI * 0.5),
			w, w * 2.0, 0.2)
		LandmarkDetail.arch(lm, "Wall", Vector3(30.0, 8.8 + w * 2.0, z), Vector3.RIGHT, w, 0.7, 0.4)
	var east := Basis(Vector3.UP, PI * 0.5)
	LandmarkAmhParts.stair(lm, "Steps", Vector3.ZERO, east, 36.0, 65.6, 0.0, 46.0, 8.4, 40.0, 56)
	LandmarkAmhParts.rails(lm, "Steps", Vector3.ZERO, east, 36.0, 65.6, 0.0, 46.0, 8.4, 2.2, 1.8)
	for s in [-1.0, 1.0]:
		lm.box("Steps", Vector3(48.0, 5.4, s * 20.4), Vector3(3.6, 10.8, 3.6))
		lm.box("Steps", Vector3(48.0, 10.95, s * 20.4), Vector3(4.0, 0.3, 4.0))
		LandmarkKits.statue_figure(lm, "Bronze", Vector3(48.0, 11.1, s * 20.4), 6.5, s > 0.0)

## Colonnaded drum, attic with windows, ribbed dome, lantern of ten
## columns and the gilded finial.
static func _capitolio_dome(lm: LandmarkMesh, c: Vector3) -> void:
	lm.frustum("Wall", c, 17.4, 17.4, 3.0, 48)
	lm.frustum("Wall", c + Vector3(0, 2.6, 0), 18.0, 18.0, 0.4, 48)
	var d := c + Vector3(0, 3.0, 0)
	lm.frustum("Wall", d, 14.5, 14.5, 11.0, 48)
	for k in 24:
		var a := TAU * float(k) / 24.0
		LandmarkNaParts.column_lite(lm, "Wall", d + Vector3(cos(a), 0, sin(a)) * 16.3, 0.6, 10.6, 1.0,
			12)
	for k in 12:
		var a := TAU * (float(k) + 0.5) / 12.0
		var dir := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Wall", "Windows", d + dir * 14.5 + Vector3(0, 5.4, 0), dir, 1.8, 5.0,
			true, 0.3)
	lm.frustum("Wall", d + Vector3(0, 10.6, 0), 17.4, 17.4, 1.4, 48)
	lm.lathe("Wall", d + Vector3(0, 12.0, 0),
		PackedVector2Array([Vector2(17.4, 0.0), Vector2(17.8, 0.4), Vector2(17.9, 0.8)]), 48)
	LandmarkNaParts.ring_posts(lm, "Wall", d + Vector3(0, 12.8, 0), 17.2, 1.0, 96, 0.25, 0.25)
	LandmarkNaParts.ring(lm, "Wall", d + Vector3(0, 13.7, 0), 17.2, 0.5, 0.25, 48)
	lm.frustum("Wall", d + Vector3(0, 12.8, 0), 14.2, 14.2, 2.2, 48)
	for k in 16:
		var a := TAU * (float(k) + 0.5) / 16.0
		var dir := Vector3(cos(a), 0, sin(a))
		lm.box("Windows", d + dir * 14.22 + Vector3(0, 13.9, 0), Vector3(1.2, 1.0, 0.1),
			Basis.looking_at(dir), 0.0)
	var b := d + Vector3(0, 15.0, 0)
	var prof := PackedVector2Array([Vector2(14.2, 0.0), Vector2(14.0, 1.5), Vector2(13.2, 4.5),
		Vector2(11.6, 8.5), Vector2(9.4, 12.5), Vector2(6.9, 16.0), Vector2(4.6, 18.8),
		Vector2(3.4, 20.4), Vector2(3.0, 21.0)])
	lm.lathe("Dome", b, prof, 48)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var dir := Vector3(cos(a), 0, sin(a))
		for j in prof.size() - 2:
			lm.beam("Dome", b + dir * (prof[j].x + 0.12) + Vector3(0, prof[j].y, 0),
				b + dir * (prof[j + 1].x + 0.12) + Vector3(0, prof[j + 1].y, 0), 0.7, 0.35,
				dir.cross(Vector3.UP))
	var t := b + Vector3(0, 21.0, 0)
	lm.frustum("Wall", t, 4.2, 4.2, 0.8, 24)
	lm.frustum("Dome", t + Vector3(0, 0.8, 0), 2.7, 2.7, 6.5, 24)
	for k in 10:
		var a := TAU * float(k) / 10.0
		LandmarkNaParts.column_lite(lm, "Wall", t + Vector3(cos(a) * 3.4, 0.8, sin(a) * 3.4), 0.28, 6.5,
			1.0, 10)
	lm.frustum("Wall", t + Vector3(0, 7.3, 0), 4.0, 4.0, 0.8, 24)
	lm.lathe("Dome", t + Vector3(0, 8.1, 0),
		PackedVector2Array([Vector2(3.8, 0.0), Vector2(3.2, 1.3), Vector2(2.0, 3.8), Vector2(0.9, 5.8),
		Vector2(0.5, 7.0)]), 24)
	var f := t + Vector3(0, 15.1, 0)
	lm.lathe("Gold", f,
		PackedVector2Array([Vector2(0.9, 0.0), Vector2(1.1, 0.7), Vector2(0.5, 1.6), Vector2(0.6, 2.6),
		Vector2(0.25, 4.0), Vector2(0.1, CAPITOLIO_TOP_M - f.y)]), 12)
