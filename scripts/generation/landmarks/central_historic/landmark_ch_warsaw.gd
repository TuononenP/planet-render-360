class_name LandmarkChWarsaw
extends RefCounted

## The Palace of Culture and Science in Warsaw (Lev Rudnev, 1952-55) in
## true metres: a stepped Socialist-Realist tower of 42 floors, roof at
## 187.7 m and the 49 m spire to 237 m, the observation terrace on the
## 30th floor at 114 m, four 6.3 m clock faces (2000), the tiers clad in
## cream ceramic with vertical lesenes and crowned by Polish Renaissance
## attics with pinnacles, four corner pavilions, and the long side wings
## round a front court with the columned main entrance (front to +Z).

const PALACE_TOP := 237.0
## Tower tiers: half-width, base and top height.
const PALACE_TIERS := [[40.0, 0.0, 46.0], [28.0, 46.0, 112.0], [22.0, 112.0, 148.0], [17.0, 148.0, 172.0],
	[12.0, 172.0, 187.0]]

static func palace(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#C4B9A0", 4.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#8F8672", 4.0))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E907F", 2.0, 0.55, 0.3))
	lm.use("Steel", LandmarkMaterials.paint("#8B96A0", 0.4, 0.6))
	lm.use("Clock", LandmarkMaterials.paint("#ECE9DE", 0.5, 0.1))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.box("Dark", Vector3(0, 0.6, 8.0), Vector3(160.0, 1.2, 116.0))
	for i in PALACE_TIERS.size():
		var t: Array = PALACE_TIERS[i]
		_tier(lm, Vector3.ZERO, float(t[0]), float(t[1]), float(t[2]), 6.0 if float(t[0]) > 20.0 else 4.5)
	# Tall pinnacle turrets at the corners of the upper setbacks.
	for t in PALACE_TIERS.slice(1, 4):
		var q: float = float(t[0]) - 2.0
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_pinnacle_turret(lm, Vector3(sx * q, float(t[2]) + 3.2, sz * q), 1.5, 9.0)
	# Four tall corner pavilions round the foot of the tower.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * 32.0, 0, sz * 32.0)
			_tier(lm, p, 9.0, 46.0, 92.0, 6.0)
			lm.spire("Copper", p + Vector3(0, 93.0, 0), 8.0, 12.0, 0.0, 4)
			LandmarkChParts.finial(lm, "Gilt", p + Vector3(0, 105.0, 0), 2.5, 0.4)
	_wings(lm)
	_entrance(lm)
	_spire(lm)
	lm.commit(model)

## One square tier: the mass, a window skin with real openings on each
## face, lesenes between the window columns, a cornice and the toothed
## Polish attic with pinnacles at its piers.
static func _tier(lm: LandmarkMesh, c: Vector3, hw: float, y0: float, y1: float, row_h: float) -> void:
	lm.box("Wall", c + Vector3(0, (y0 + y1) * 0.5, 0), Vector3(hw * 2.0, y1 - y0, hw * 2.0))
	lm.box("Dark", c + Vector3(0, y1 + 0.5, 0), Vector3(hw * 2.0 + 1.6, 1.0, hw * 2.0 + 1.6))
	var cols := maxi(int(hw * 2.0 / 5.0), 2)
	var pitch := hw * 2.0 / float(cols)
	var top_band := 3.0
	var h := y1 - y0 - top_band
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var r := b.x
		var n := b.z
		var origin := c + b * Vector3(-hw, y0, hw)
		LandmarkDetail.pierced_face(lm, "Wall", "Windows", origin, r, n, hw * 2.0, h, cols, int(h / row_h),
			Vector2(minf(pitch * 0.42, 2.2), row_h * 0.55), 2.0, row_h, 0.35)
		# Lesenes up the piers, each ending in a little pinnacle above the attic.
		for i in cols + 1:
			var x := pitch * float(i)
			var lp := origin + r * x + n * 0.6
			lm.box("Wall", lp + Vector3(0, (y1 - y0) * 0.5, 0), Vector3(0.9, y1 - y0, 0.5), b)
		# Cornice and attic merlons along the head of the face.
		var a := c + b * Vector3(-hw, y1 + 1.0, hw)
		LandmarkCeParts.merlons(lm, "Wall", a, a + r * hw * 2.0, 3.6, 1.6, 2.0, 1.2)
		for i in cols + 1:
			var x := pitch * float(i)
			var pp := c + b * Vector3(-hw + x, y1 + 1.0, hw + 0.2)
			lm.box("Wall", pp + Vector3(0, 1.4, 0), Vector3(1.0, 2.8, 1.0), b)
			lm.spire("Wall", pp + Vector3(0, 2.8, 0), 0.5, 1.8)
		lm.box("Dark", c + b * Vector3(0, y1 - top_band * 0.5, hw + 0.2), Vector3(hw * 2.0, top_band * 0.6, 0.4), b, 0.0)

## Slim pinnacle turret: a square shaft with corner shafts, a lantern
## stage of arches, copper needle.
static func _pinnacle_turret(lm: LandmarkMesh, p: Vector3, r: float, h: float) -> void:
	lm.box("Wall", p + Vector3(0, h * 0.35, 0), Vector3(r * 2.0, h * 0.7, r * 2.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.frustum("Wall", p + Vector3(sx * r, 0, sz * r), 0.3, 0.25, h * 0.75, 8)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		LandmarkChParts.arched_window(lm, "Dark", "Windows", p + b * Vector3(0, h * 0.35, r), b.z, r * 0.8, h * 0.28, 0.15)
	lm.box("Dark", p + Vector3(0, h * 0.72, 0), Vector3(r * 2.4, 0.4, r * 2.4))
	lm.spire("Copper", p + Vector3(0, h * 0.74, 0), r * 1.1, h * 0.7)
	LandmarkChParts.finial(lm, "Gilt", p + Vector3(0, h * 1.44, 0), 1.0, 0.2)

## Side wings forward of the tower round the front court: window skins,
## lesenes, cornices and crenellated attics.
static func _wings(lm: LandmarkMesh) -> void:
	for sx in [-1.0, 1.0]:
		var x0: float = sx * 40.0
		var x1: float = sx * 76.0
		lm.box("Wall", Vector3(sx * 58.0, 15.0, 10.0), Vector3(36.0, 30.0, 100.0))
		lm.box("Dark", Vector3(sx * 58.0, 30.5, 10.0), Vector3(37.0, 1.0, 101.0))
		# Faces: outer side, court side, front end (origin, right, normal, width).
		var faces := [[Vector3(x1, 0, 10.0 + 50.0 * sx), Vector3(0, 0, -sx), Vector3(sx, 0, 0), 100.0],
			[Vector3(x0, 0, 10.0 - 50.0 * sx), Vector3(0, 0, sx), Vector3(-sx, 0, 0), 100.0],
			[Vector3(minf(x0, x1), 0, 60.0), Vector3.RIGHT, Vector3.BACK, 36.0]]
		for fc in faces:
			var fo: Vector3 = fc[0]
			var r: Vector3 = fc[1]
			var n: Vector3 = fc[2]
			var w: float = fc[3]
			var cols := int(w / 5.0)
			LandmarkDetail.pierced_face(lm, "Wall", "Windows", fo, r, n, w, 27.5, cols, 4, Vector2(2.0, 3.4), 3.0, 6.0, 0.35)
			for k in cols + 1:
				var lp := fo + r * (w * float(k) / float(cols)) + n * 0.6
				lm.box("Wall", lp + Vector3(0, 14.0, 0), Vector3(0.8, 28.0, 0.5), Basis(Vector3.UP, atan2(n.x, n.z)))
			var a := fo + Vector3(0, 31.0, 0)
			LandmarkCeParts.merlons(lm, "Wall", a, a + r * w, 3.6, 1.6, 1.8, 1.2)
			LandmarkDetail.cornice(lm, "Dark", fo + Vector3(0, 28.6, 0) + n * 0.35, fo + r * w + Vector3(0, 28.6, 0) + n * 0.35,
				n, 1.2, false)

## The main entrance: a portico of twelve columns with an entablature,
## steps, and the two seated figures (Copernicus, Mickiewicz) in front.
static func _entrance(lm: LandmarkMesh) -> void:
	for i in 4:
		lm.box("Dark", Vector3(0, 0.6 + 0.3 * i, 47.5 - 0.8 * i), Vector3(52.0, 0.6, 1.6), Basis(), 0.0)
	for i in 12:
		LandmarkDetail.column(lm, "Wall", Vector3(-22.0 + 4.0 * i, 2.1, 43.0), 1.0, 14.6, "corinthian", 0)
	lm.box("Wall", Vector3(0, 17.8, 42.0), Vector3(52.0, 2.4, 6.0))
	LandmarkDetail.cornice(lm, "Wall", Vector3(-26.0, 19.0, 45.0), Vector3(26.0, 19.0, 45.0), Vector3.BACK, 1.2)
	LandmarkChParts.roof_balustrade(lm, "Wall", Vector3(-26.0, 20.2, 44.6), Vector3(26.0, 20.2, 44.6), 1.4, 4.0)
	for sx in [-1.0, 1.0]:
		var p := Vector3(sx * 34.0, 1.2, 56.0)
		lm.box("Dark", p + Vector3(0, 1.4, 0), Vector3(3.0, 2.8, 3.0))
		LandmarkKits.statue_figure(lm, "Dark", p + Vector3(0, 2.8, 0), 3.6, false)

## The spire: an octagonal needle with ribs and rings on the tower's
## crown, to 237 m.
static func _spire(lm: LandmarkMesh) -> void:
	var y0 := 187.0
	var prof := PackedVector2Array([Vector2(4.4, 0), Vector2(3.2, 10.0), Vector2(1.9, 25.0), Vector2(1.0, 38.0),
		Vector2(0.35, PALACE_TOP - y0)])
	lm.lathe("Steel", Vector3(0, y0, 0), prof, 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		for j in 3:
			var p0 := Vector3(cos(a) * (prof[j].x + 0.25), y0 + prof[j].y, sin(a) * (prof[j].x + 0.25))
			var p1 := Vector3(cos(a) * (prof[j + 1].x + 0.2), y0 + prof[j + 1].y, sin(a) * (prof[j + 1].x + 0.2))
			lm.beam("Steel", p0, p1, 0.4, 0.4)
	for y in [4.0, 12.0, 20.0, 30.0]:
		var rr := _radius_at(prof, y) + 0.3
		lm.frustum("Steel", Vector3(0, y0 + y, 0), rr, rr, 0.6, 16)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		lm.disc("Dark", b * Vector3(0, 160.0, 17.12), b.z, 3.6, 32)
		lm.disc("Clock", b * Vector3(0, 160.0, 17.2), b.z, 3.15, 32)
		for k in 12:
			var a := TAU * float(k) / 12.0
			lm.box("Dark", b * Vector3(cos(a) * 2.7, 160.0 + sin(a) * 2.7, 17.26), Vector3(0.18, 0.5, 0.05),
				b * Basis(Vector3.BACK, a - PI * 0.5), 0.0)
		lm.beam("Dark", b * Vector3(0, 160.0, 17.3), b * Vector3(1.6, 161.2, 17.3), 0.18, 0.05)
		lm.beam("Dark", b * Vector3(0, 160.0, 17.32), b * Vector3(-0.4, 162.5, 17.32), 0.14, 0.05)

## Radius of a (radius, y) profile at height y, linear between points.
static func _radius_at(prof: PackedVector2Array, y: float) -> float:
	for j in prof.size() - 1:
		if y <= prof[j + 1].y:
			return lerpf(prof[j].x, prof[j + 1].x, (y - prof[j].y) / (prof[j + 1].y - prof[j].y))
	return prof[prof.size() - 1].x
