class_name SEuPisa
extends RefCounted

## Piazza dei Miracoli in true metres, origin at the foot of the Leaning
## Tower: the 56 m campanile (outer diameter 15.48 m) of eight storeys -
## the ground storey's blind arcade of fifteen arches on half-columns
## with inlaid lozenges, six open galleries each ringed by thirty
## columns carrying round arches, and the narrower bell chamber of 1372 -
## leaning 3.97° to the south (+Z); the Romanesque cathedral (west
## facade of a blind arcade and four open loggias, five-aisled nave,
## transept, apse, elliptical crossing dome) to the north-west and the
## round Baptistery (34.1 m across, 54.9 m tall) with its loggia of
## gables and pinnacles and its half-lead, half-tile dome to the west.

## tan of the 3.97° lean: the axis shifts this far south per metre of height.
const LEAN := 0.0694
const TOWER_R := 7.74
const GROUND_TOP := 11.0
const GALLERY_H := 6.0
const CATHEDRAL := Vector3(-40.0, 0.0, -38.0)
const BAPTISTERY := Vector3(-132.0, 0.0, -36.0)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EAE4D6", 3.0))
	lm.use("Grey", LandmarkMaterials.pbr("limestone", "#A9ADA6", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4F483E", 3.0))
	lm.use("Lead", LandmarkMaterials.pbr("concrete", "#8E9094", 2.0, 0.5, 0.4))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#6C5A3C", 2.0, 0.4, 0.7))
	_tower(lm)
	_cathedral(lm)
	_baptistery(lm)
	lm.commit(model)

## A point on the leaning axis at height y.
static func _ax(y: float) -> Vector3:
	return Vector3(0, y, y * LEAN)

static func _tower(lm: LandmarkMesh) -> void:
	var r := TOWER_R
	# Two-step marble footing.
	lm.frustum("Grey", _ax(0.0), r + 0.9, r + 0.9, 0.35, 32)
	lm.frustum("Marble", _ax(0.35), r + 0.5, r + 0.45, 0.35, 32)
	# Ground storey: drum, fifteen half-columns, blind arches, lozenges.
	var g0 := 0.7
	lm.frustum("Marble", _ax(g0), r, r, GROUND_TOP - g0, 30)
	for i in 15:
		var a := TAU * float(i) / 15.0
		var d := Vector3(cos(a), 0, sin(a))
		SEuParts.col(lm, "Marble", _ax(g0) + d * (r + 0.05), 0.42, 8.6, "corinthian", 8)
		var am := TAU * (float(i) + 0.5) / 15.0
		var dm := Vector3(cos(am), 0, sin(am))
		var span := TAU * r / 15.0
		SEuParts.arch_ring(lm, "Marble", _ax(g0 + 8.6) + dm * (r * cos(PI / 15.0)), Vector3.UP.cross(dm),
			dm, span - 0.9, 0.45, 0.5, false, 6)
		# Inlaid grey lozenge in the lunette and a panel below it.
		lm.box("Grey", _ax(g0 + 8.9) + dm * (r + 0.02), Vector3(0.9, 0.9, 0.06),
			Basis(Vector3.UP, atan2(dm.x, dm.z)) * Basis(Vector3.BACK, PI * 0.25), 0.0)
		if i % 5 == 0:
			# Doorway on the north side and two windows.
			var nd := Vector3(cos(am), 0, sin(am))
			SEuParts.niche(lm, "Marble", "Shadow", _ax(g0) + nd * (r * cos(PI / 15.0) + 0.05), nd,
				2.0, 4.8 if i == 10 else 3.2, SEuParts.ROUND, 0.3)
	_cornice_ring(lm, GROUND_TOP, r + 0.15)
	# Six open galleries.
	for f in 6:
		var y0 := GROUND_TOP + GALLERY_H * float(f)
		_gallery(lm, y0, f)
	# Bell chamber: narrower drum ringed by its own arcade, cornice and
	# the low lead roof with the parapet.
	var by := GROUND_TOP + GALLERY_H * 6.0
	lm.frustum("Marble", _ax(by), r - 0.9, r - 0.9, 0.6, 30)
	var br := 5.3
	lm.frustum("Marble", _ax(by + 0.6), br, br, 6.4, 24)
	for i in 12:
		var a := TAU * (float(i) + 0.5) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		SEuParts.niche(lm, "Marble", "Shadow", _ax(by + 1.6) + d * (br * cos(PI / 24.0)), d, 1.5, 4.2,
			SEuParts.ROUND, 0.35)
	for i in 16:
		var a := TAU * float(i) / 16.0
		SEuParts.col(lm, "Marble", _ax(by + 0.6) + Vector3(cos(a), 0, sin(a)) * (br + 0.35), 0.24, 5.6,
			"corinthian", 6)
	lm.frustum("Grey", _ax(by + 6.2), br + 0.9, br + 0.7, 0.8, 24)
	lm.frustum("Marble", _ax(by + 7.0), br + 0.6, br + 0.6, 0.6, 24)
	lm.lathe("Lead", _ax(by + 7.6), PackedVector2Array([Vector2(br + 0.2, 0), Vector2(br - 0.6, 0.5),
		Vector2(0.0, 1.3)]), 24)

## Gallery `f` from y0: floor slab, inner wall with its doors, thirty
## columns and arches, the frieze over the arches and the cornice.
static func _gallery(lm: LandmarkMesh, y0: float, f: int) -> void:
	var r := TOWER_R
	var c := _ax(y0)
	lm.frustum("Marble", c, r, r, 0.45, 30)
	var core := r - 1.7
	lm.frustum("Marble", c + Vector3(0, 0.45, 0), core, core, GALLERY_H - 0.45, 24)
	for i in 8:
		var a := TAU * (float(i) + 0.25 * float(f)) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		SEuParts.niche(lm, "Grey", "Shadow", c + Vector3(0, 0.45, 0) + d * (core * cos(PI / 24.0)), d,
			0.9 if i % 2 == 1 else 1.1, 2.0 if i % 2 == 1 else 3.0, SEuParts.ROUND if i % 2 == 0 else SEuParts.RECT,
			0.2)
	var ch := 3.7
	SEuParts.arcade_ring(lm, "Marble", "Marble", c + Vector3(0, 0.45, 0), r - 0.35, 30, ch, 0.24,
		PI / 30.0 * float(f % 2), "corinthian", 6)
	# Frieze band carried by the arches, with a grey string course.
	lm.frustum("Marble", c + Vector3(0, 0.45 + ch + 0.5, 0), r - 0.05, r - 0.05, 1.0, 30)
	lm.frustum("Grey", c + Vector3(0, 0.45 + ch + 0.5, 0), r + 0.02, r + 0.02, 0.18, 30)
	_cornice_ring(lm, y0 + GALLERY_H, r + 0.2)

## Moulded cornice ring at height y (on the leaning axis), radius r.
static func _cornice_ring(lm: LandmarkMesh, y: float, r: float) -> void:
	lm.lathe("Marble", _ax(y - 0.5), PackedVector2Array([Vector2(r - 0.25, 0), Vector2(r - 0.1, 0.12),
		Vector2(r + 0.05, 0.3), Vector2(r + 0.3, 0.42), Vector2(r + 0.35, 0.5)]), 30, 1.0, 1.0, 0.0, true, false)

static func _cathedral(lm: LandmarkMesh) -> void:
	var c := CATHEDRAL
	var along := Basis(Vector3.UP, PI * 0.5)
	# Nave (five aisles read as a tall centre plus two lower sides).
	lm.box("Marble", c + Vector3(0, 12.0, 0), Vector3(92.0, 24.0, 20.0))
	lm.gable("Lead", c + Vector3(0, 24.0, 0), 20.0, 92.0, 7.0, along, 0.6, "Marble")
	for s in [-1.0, 1.0]:
		lm.box("Marble", c + Vector3(0, 7.0, s * 15.0), Vector3(92.0, 14.0, 10.0))
		lm.gable("Lead", c + Vector3(0, 14.0, s * 15.0), 10.0, 92.0, 2.4, along, 0.3)
		# Clerestory: pilasters and arched windows above the aisle roofs.
		for k in 15:
			var x := c.x - 42.0 + 6.0 * float(k)
			lm.box("Marble", Vector3(x - 3.0, 19.0, c.z + s * 10.15), Vector3(0.7, 10.0, 0.3))
			SEuParts.niche(lm, "Marble", "Shadow", Vector3(x, 17.0, c.z + s * 10.0), Vector3(0, 0, s), 1.2,
				3.4, SEuParts.ROUND, 0.2)
	# Transept across the east end, apse beyond it.
	lm.box("Marble", c + Vector3(14.0, 12.0, 0), Vector3(20.0, 24.0, 54.0))
	lm.gable("Lead", c + Vector3(14.0, 24.0, 0), 20.0, 54.0, 6.0, Basis(), 0.6, "Marble")
	for s in [-1.0, 1.0]:
		lm.frustum("Marble", c + Vector3(14.0, 0, s * 27.0), 7.0, 7.0, 16.0, 16)
		lm.lathe("Lead", c + Vector3(14.0, 16.0, s * 27.0), SEuUtil.dome(7.3, 3.5, 5), 16)
	lm.frustum("Marble", c + Vector3(46.0, 0, 0), 11.0, 11.0, 20.0, 24)
	lm.lathe("Lead", c + Vector3(46.0, 20.0, 0), SEuUtil.dome(11.4, 6.0, 6), 24)
	for k in 9:
		var a := -PI * 0.5 + PI * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Marble", c + Vector3(46.0, 10.0, 0) + d * 11.1, Vector3(0.6, 20.0, 0.8),
			Basis(Vector3.UP, atan2(d.x, d.z)))
		if k < 8:
			var am := a + PI / 16.0
			var dm := Vector3(cos(am), 0, sin(am))
			SEuParts.niche(lm, "Marble", "Shadow", c + Vector3(46.0, 12.0, 0) + dm * 10.95, dm, 1.2, 3.6,
				SEuParts.ROUND, 0.2)
	# Striped bands of grey marble and the blind arcade along the aisles.
	for s in [-1.0, 1.0]:
		for k in 3:
			lm.box("Grey", c + Vector3(0, 3.0 + 4.0 * float(k), s * 20.05), Vector3(92.0, 0.5, 0.2))
		for k in 20:
			var x := c.x - 44.0 + 4.6 * float(k) + 2.3
			lm.box("Marble", Vector3(x - 2.3, 6.0, c.z + s * 20.2), Vector3(0.6, 12.0, 0.4))
			SEuParts.niche(lm, "Marble", "Shadow", Vector3(x, 6.5, c.z + s * 20.0), Vector3(0, 0, s), 1.4,
				3.6, SEuParts.ROUND, 0.25)
		lm.box("Marble", c + Vector3(0, 13.5, s * 20.25), Vector3(92.4, 0.6, 0.6))
	# Crossing dome (elliptical in plan) on its drum, with a loggia.
	LandmarkKits.dome_on_drum(lm, "Marble", "Lead", c + Vector3(14.0, 24.0, 0), 7.5, 5.0, 8.0,
		4.0, 24)
	# West facade: blind arcade of seven arches with three bronze doors,
	# then four open loggias of small columns under a stepped gable.
	var fx := c.x - 46.5
	lm.box("Marble", Vector3(fx, 15.0, c.z), Vector3(4.0, 30.0, 36.0))
	lm.gable("Marble", Vector3(fx, 30.0, c.z), 36.0, 4.0, 6.0, along, 0.0, "Marble")
	var face := fx - 2.0
	var nx := Vector3(-1, 0, 0)
	for k in 7:
		var z := c.z - 15.4 + 30.8 * float(k) / 6.0
		SEuParts.col(lm, "Marble", Vector3(face - 0.4, 0, z), 0.45, 9.0, "corinthian", 8)
		if k < 6:
			var zm := z + 30.8 / 12.0
			SEuParts.arch_ring(lm, "Marble", Vector3(face - 0.4, 9.0, zm), Vector3(0, 0, 1), nx, 3.6, 0.5,
				0.5, false, 6)
			if k == 0 or k == 2 or k == 3 or k == 5:
				var big := k == 2 or k == 3
				var dz := zm + (2.57 if k == 2 else (-2.57 if k == 3 else 0.0))
				if big:
					dz = c.z
				SEuParts.niche(lm, "Marble", "Bronze", Vector3(face, 0, dz), nx, 3.4 if big else 2.4,
					7.0 if big else 5.6, SEuParts.RECT, 0.45, -1.0, false)
			else:
				lm.box("Grey", Vector3(face - 0.05, 10.0, zm), Vector3(0.1, 1.2, 1.2),
					Basis(Vector3.RIGHT, PI * 0.25), 0.0)
	var tiers := [[11.0, 36.0, 19], [17.0, 28.0, 15], [22.6, 18.0, 9], [28.0, 16.0, 8]]
	for t in tiers:
		var y: float = t[0]
		var wdt: float = t[1]
		var n: int = t[2]
		lm.box("Marble", Vector3(face - 0.6, y - 0.25, c.z), Vector3(1.4, 0.5, wdt + 0.6))
		for k in n:
			var z := c.z - wdt * 0.5 + wdt * (float(k) + 0.5) / float(n)
			SEuParts.col(lm, "Marble", Vector3(face - 0.9, y, z), 0.2, 3.6, "corinthian", 6)
		SEuParts.niche(lm, "Grey", "Shadow", Vector3(face, y, c.z), nx, wdt - 1.0, 4.2, SEuParts.RECT, 0.05, 0.1, false)
		lm.box("Marble", Vector3(face - 0.7, y + 4.4, c.z), Vector3(1.6, 1.0, wdt + 0.8))
	for s in [-1.0, 1.0]:
		SEuParts.figure(lm, "Marble", Vector3(face - 0.6, 30.0, c.z + s * 17.5), 2.4)
	SEuParts.figure(lm, "Marble", Vector3(face - 0.2, 36.0, c.z), 2.6)

static func _baptistery(lm: LandmarkMesh) -> void:
	var c := BAPTISTERY
	lm.frustum("Grey", c, 18.8, 18.5, 1.2, 40)
	# Ground storey: twenty half-columns and blind round arches, four portals.
	lm.frustum("Marble", c + Vector3(0, 1.2, 0), 17.1, 17.1, 13.8, 40)
	for i in 20:
		var a := TAU * float(i) / 20.0
		var d := Vector3(cos(a), 0, sin(a))
		SEuParts.col(lm, "Marble", c + Vector3(0, 1.2, 0) + d * 17.2, 0.6, 10.5, "corinthian", 8)
		var am := a + TAU / 40.0
		var dm := Vector3(cos(am), 0, sin(am))
		SEuParts.arch_ring(lm, "Marble", c + Vector3(0, 11.7, 0) + dm * 16.95, Vector3.UP.cross(dm), dm, 4.0,
			0.6, 0.6, false, 6)
		if i % 5 == 0:
			SEuParts.niche(lm, "Marble", "Bronze", c + Vector3(0, 1.2, 0) + dm * 16.9, dm, 3.0, 7.0,
				SEuParts.RECT, 0.6)
		else:
			SEuParts.niche(lm, "Marble", "Shadow", c + Vector3(0, 6.0, 0) + dm * 16.9, dm, 1.0, 3.0,
				SEuParts.ROUND, 0.25)
	for k in 3:
		lm.frustum("Grey", c + Vector3(0, 3.5 + 3.0 * float(k), 0), 17.13, 17.13, 0.35, 40)
	lm.frustum("Grey", c + Vector3(0, 15.0, 0), 18.0, 17.8, 0.8, 40)
	# Loggia of sixty small columns, then Gothic gables with pinnacles.
	var ly := 15.8
	lm.frustum("Marble", c + Vector3(0, ly, 0), 16.2, 16.2, 8.0, 40)
	SEuParts.arcade_ring(lm, "Marble", "Marble", c + Vector3(0, ly, 0), 17.2, 60, 3.4, 0.22, 0.0, "corinthian", 6)
	lm.frustum("Marble", c + Vector3(0, ly + 4.4, 0), 17.4, 17.4, 0.6, 40)
	for i in 30:
		var a := TAU * (float(i) + 0.5) / 30.0
		var d := Vector3(cos(a), 0, sin(a))
		var rt := Vector3.UP.cross(d)
		var b := c + Vector3(0, ly + 5.0, 0) + d * 17.3
		lm.tri("Marble", b - rt * 1.6, b + rt * 1.6, b + Vector3(0, 3.0, 0), d, d, d,
			Vector2.ZERO, Vector2(3.2, 0), Vector2(1.6, -3.0))
		lm.disc("Shadow", b + Vector3(0, 1.1, 0) + d * 0.02, d, 0.55, 8)
		var pa := TAU * float(i) / 30.0
		var pd := Vector3(cos(pa), 0, sin(pa))
		SEuParts.pinnacle(lm, "Marble", c + Vector3(0, ly + 5.0, 0) + pd * 17.3, 0.6, 4.4,
			"Marble" if i % 3 == 0 else "")
	lm.frustum("Grey", c + Vector3(0, 23.8, 0), 17.4, 17.2, 0.8, 40)
	# Clerestory drum with windows under gables, then the dome.
	lm.frustum("Marble", c + Vector3(0, 24.6, 0), 14.2, 14.2, 9.4, 36)
	for i in 12:
		var a := TAU * float(i) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		SEuParts.niche(lm, "Marble", "Shadow", c + Vector3(0, 27.0, 0) + d * 14.15, d, 1.8, 4.6,
			SEuParts.POINTED, 0.35)
		var rt := Vector3.UP.cross(d)
		var b := c + Vector3(0, 32.2, 0) + d * 14.5
		lm.tri("Marble", b - rt * 1.8, b + rt * 1.8, b + Vector3(0, 3.0, 0), d, d, d,
			Vector2.ZERO, Vector2(3.6, 0), Vector2(1.8, -3.0))
		SEuParts.pinnacle(lm, "Marble", c + Vector3(0, 32.0, 0) + Vector3(cos(a + PI / 12.0), 0,
			sin(a + PI / 12.0)) * 14.4, 0.5, 3.2)
	# The truncated cone is roofed in red tile on the east (sea) side and
	# lead on the west; a small hemispherical cap rises through it.
	var prof := PackedVector2Array([Vector2(14.0, 0), Vector2(13.2, 3.5), Vector2(10.6, 8.5),
		Vector2(6.6, 13.2), Vector2(3.2, 16.0), Vector2(2.4, 17.0)])
	_half_lathe(lm, "Tile", c + Vector3(0, 34.0, 0), prof, -PI * 0.5, PI * 0.5, 16)
	_half_lathe(lm, "Lead", c + Vector3(0, 34.0, 0), prof, PI * 0.5, PI * 1.5, 16)
	for k in 12:
		var a := TAU * float(k) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in prof.size() - 1:
			lm.beam("Grey", c + Vector3(0, 34.0 + prof[j].y, 0) + d * (prof[j].x + 0.1),
				c + Vector3(0, 34.0 + prof[j + 1].y, 0) + d * (prof[j + 1].x + 0.1), 0.35, 0.2)
	lm.frustum("Marble", c + Vector3(0, 51.0, 0), 2.4, 1.6, 2.8, 12)
	lm.frustum("Bronze", c + Vector3(0, 53.8, 0), 0.4, 0.3, 0.3, 8)
	SEuParts.figure(lm, "Bronze", c + Vector3(0, 54.1, 0), 1.6)

## Part of a surface of revolution between angles a0 and a1 (radians).
static func _half_lathe(lm: LandmarkMesh, key: String, base: Vector3, prof: PackedVector2Array,
		a0: float, a1: float, seg: int) -> void:
	var rows: Array = []
	for j in prof.size():
		var row := PackedVector3Array()
		for i in seg + 1:
			var a := lerpf(a0, a1, float(i) / float(seg))
			row.append(base + Vector3(cos(a) * prof[j].x, prof[j].y, sin(a) * prof[j].x))
		rows.append(row)
	lm.grid(key, rows, base + Vector3(0, -20.0, 0), true)
