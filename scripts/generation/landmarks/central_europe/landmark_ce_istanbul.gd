class_name LandmarkCeIstanbul
extends RefCounted

## Istanbul in true metres: Hagia Sophia (537: the 31 m dome ringed by
## 40 windows and ribs, crown at 55.6 m, on pendentives between the
## east and west semi-domes and their exedrae, the windowed north and
## south tympana, the great buttresses and four Ottoman minarets, 60 m),
## the Sultan Ahmed or Blue Mosque (1617: 23.5 m dome at 43 m on its
## drum of 28 windows, four semi-domes each with three exedrae, four
## weight turrets, a forecourt arcade of 30 domes round the ablution
## fountain, six minarets, 64 m) and the Galata Tower (1348: stone
## cylinder 16.45 m across, arched windows, machicolated gallery at
## 51.7 m and conical lead cap, 66.9 m).

const SOPHIA_TOP := 60.0

static func hagia_sophia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#C99A7A", 4.0))
	lm.use("Pale", LandmarkMaterials.pbr("limestone", "#D8C4A4", 4.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#7A7E80", 2.5, 0.5, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Nave block with aisles and galleries; arched windows on two levels.
	lm.box("Wall", Vector3(0, 13.0, 0), Vector3(64.0, 26.0, 56.0))
	lm.box("Pale", Vector3(0, 26.2, 0), Vector3(64.6, 0.6, 56.6))
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for i in 12:
			var x := -27.5 + 5.0 * i
			if absf(x + 1.0) < 1.0:
				continue
			LandmarkDetail.window(lm, "Pale", "Windows", Vector3(x, 6.0, sz * 28.0), n, 1.6, 3.6, true, 0.25)
			LandmarkDetail.window(lm, "Pale", "Windows", Vector3(x, 17.0, sz * 28.0), n, 1.6, 3.6, true, 0.25)
		# Great buttresses with stepped Ottoman tops.
		for bx in [-20.0, -6.0, 8.0, 22.0]:
			lm.box("Wall", Vector3(bx, 13.0, sz * 32.5), Vector3(7.0, 26.0, 9.0))
			lm.box("Pale", Vector3(bx, 26.4, sz * 32.5), Vector3(7.6, 0.8, 9.6))
			lm.box("Wall", Vector3(bx, 29.5, sz * 30.0), Vector3(5.0, 5.4, 4.0))
			lm.gable("Dome", Vector3(bx, 32.2, sz * 30.0), 5.0, 4.0, 1.4, Basis(Vector3.UP, PI * 0.5), 0.2, "Wall")
	# Central square: the four pier towers and the tympanum walls.
	lm.box("Wall", Vector3(0, 31.0, 0), Vector3(34.0, 10.0, 34.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var pc := Vector3(sx * 17.0, 0, sz * 17.0)
			lm.box("Wall", pc + Vector3(0, 19.0, 0), Vector3(7.0, 38.0, 7.0))
			lm.box("Pale", pc + Vector3(0, 38.2, 0), Vector3(7.6, 0.6, 7.6))
			lm.spire("Dome", pc + Vector3(0, 38.5, 0), 3.6, 3.0, 0.0, 4)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		# Tympanum: a great arch filled with two tiers of windows.
		LandmarkDetail.arch(lm, "Pale", Vector3(0, 30.0, sz * 17.0), n, 26.0, 1.4, 0.8)
		for i in 7:
			LandmarkDetail.window(lm, "Pale", "Windows", Vector3(-9.0 + 3.0 * i, 30.6, sz * 17.0), n, 1.8, 3.4, true, 0.2)
		for i in 5:
			LandmarkDetail.window(lm, "Pale", "Windows", Vector3(-6.0 + 3.0 * i, 36.4, sz * 17.0), n, 1.8, 3.4, true, 0.2)
	# East and west semi-domes with their exedrae, the apse and narthex.
	for sx in [-1.0, 1.0]:
		var d := Vector3(sx, 0, 0)
		_half_dome(lm, "Dome", Vector3(sx * 16.0, 26.0, 0), d, 15.5, 12.0, 24)
		LandmarkCeParts.arched_ring(lm, "Pale", "Windows", Vector3(sx * 16.0, 26.2, 0), 15.6, 10, 1.2, 2.2, 0.0)
		for sz in [-1.0, 1.0]:
			var ed := Vector3(sx, 0, sz).normalized()
			_half_dome(lm, "Dome", Vector3(sx * 22.0, 22.0, sz * 9.0), ed, 6.5, 5.0, 12)
	lm.box("Wall", Vector3(38.0, 12.0, 0), Vector3(12.0, 24.0, 30.0))
	lm.lathe("Wall", Vector3(44.0, 0, 0), PackedVector2Array([Vector2(8.0, 0), Vector2(8.0, 18.0)]), 12, 1.0, 1.0, 0.0, false)
	_half_dome(lm, "Dome", Vector3(44.0, 18.0, 0), Vector3.RIGHT, 8.4, 5.6, 12)
	for k in 3:
		var a := (float(k) - 1.0) * 0.6
		var ad := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Pale", "Windows", Vector3(44.0, 9.0, 0) + ad * 8.0, ad, 1.6, 4.0, true, 0.25)
	# Inner and outer narthex along the west front.
	lm.box("Pale", Vector3(-36.0, 11.0, 0), Vector3(8.0, 22.0, 56.0))
	lm.box("Pale", Vector3(-43.0, 7.0, 0), Vector3(6.0, 14.0, 52.0))
	for i in 9:
		var z := -20.0 + 5.0 * i
		LandmarkDetail.window(lm, "Wall", "Windows", Vector3(-46.0, 6.0, z), Vector3.LEFT, 2.0, 4.6, true, 0.25)
		LandmarkDetail.window(lm, "Wall", "Windows", Vector3(-40.0, 17.0, z), Vector3.LEFT, 2.0, 3.6, true, 0.25)
	# Main dome: 40 windows between 40 buttresses, ribbed shell, crescent.
	var db := Vector3(0, 36.0, 0)
	LandmarkKits.dome_on_drum(lm, "Pale", "Dome", db, 16.0, 5.0, 14.0, 0.0, 40, 40)
	LandmarkCeParts.arched_ring(lm, "Pale", "Windows", db + Vector3(0, 0.8, 0), 16.0, 40, 1.4, 3.2, 0.0)
	for k in 40:
		var a := TAU * float(k) / 40.0
		lm.box("Wall", db + Vector3(cos(a) * 16.6, 2.4, sin(a) * 16.6), Vector3(1.2, 4.8, 1.0), Basis(Vector3.UP, PI * 0.5 - a))
	var ct := db + Vector3(0, 19.0, 0)
	lm.frustum("Gilt", ct, 0.25, 0.2, 1.4, 8)
	lm.lathe("Gilt", ct + Vector3(0, 1.4, 0), PackedVector2Array([Vector2(0.0, 0), Vector2(0.4, 0.2),
		Vector2(0.45, 0.5), Vector2(0.0, 0.8)]), 10)
	_crescent(lm, ct + Vector3(0, 2.8, 0), 0.9)
	# Four Ottoman minarets at the corners.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkKits.minaret(lm, "Pale", "Dome", Vector3(sx * 46.0, 0, sz * 34.0), 2.1, SOPHIA_TOP, 2 if sx > 0.0 else 1)
	lm.commit(model)

## Half dome (quarter-sphere shell) of radius r and rise h whose open
## face is the vertical plane through `c` and whose shell bulges along
## `dir` (horizontal unit), closed by a flat back wall in `key`.
static func _half_dome(lm: LandmarkMesh, key: String, c: Vector3, dir: Vector3, r: float, h: float,
		seg: int = 16) -> void:
	var d := dir.normalized()
	var side := d.cross(Vector3.UP).normalized()
	var rows: Array = []
	for j in 9:
		var e := PI * 0.5 * float(j) / 8.0
		var row := PackedVector3Array()
		for i in seg + 1:
			var a := -PI * 0.5 + PI * float(i) / float(seg)
			row.append(c + (d * cos(a) + side * sin(a)) * r * cos(e) + Vector3(0, h * sin(e), 0))
		rows.append(row)
	lm.grid(key, rows, c, true)
	for j in 8:
		var e0 := PI * 0.5 * float(j) / 8.0
		var e1 := PI * 0.5 * float(j + 1) / 8.0
		lm.quad(key, c - side * r * cos(e0) + Vector3(0, h * sin(e0), 0), c + side * r * cos(e0) + Vector3(0, h * sin(e0), 0),
			c + side * r * cos(e1) + Vector3(0, h * sin(e1), 0), c - side * r * cos(e1) + Vector3(0, h * sin(e1), 0), -d)

## Gilt crescent finial of radius r facing along X at `c`.
static func _crescent(lm: LandmarkMesh, c: Vector3, r: float) -> void:
	var prev := c + Vector3(0, -r, 0)
	for k in 8:
		var a := -PI * 0.5 + PI * 1.4 * float(k + 1) / 8.0
		var p := c + Vector3(0, sin(a), cos(a)) * r
		lm.beam("Gilt", prev, p, r * 0.22, r * 0.12, Vector3(0, 0, 1))
		prev = p

# --- Blue Mosque ---

const BLUE_TOP := 64.0

static func blue_mosque(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#D2CABA", 4.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#6F7479", 2.5, 0.5, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#B5AE9F", 4.0))
	lm.box("Court", Vector3(0, 0.1, -50.0), Vector3(62.0, 0.2, 72.0))
	# Prayer hall, 64 x 72 with three tiers of arched windows.
	lm.box("Wall", Vector3(0, 9.0, 14.0), Vector3(62.0, 18.0, 56.0))
	lm.box("Wall", Vector3(0, 18.3, 14.0), Vector3(62.8, 0.6, 56.8))
	for f in 4:
		var n := [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK][f] as Vector3
		var half := 28.0 if f < 2 else 31.0
		var out := 31.0 if f < 2 else 28.0
		var r := Vector3.UP.cross(n).normalized()
		var c := Vector3(0, 0, 14.0) + n * out
		for i in 9:
			var q := c + r * (-half + 2.0 * half * (float(i) + 0.5) / 9.0)
			if f == 2 and absf(i - 4) <= 1:
				continue
			LandmarkDetail.window(lm, "Wall", "Windows", q + Vector3(0, 3.6, 0), n, 1.5, 3.0, false, 0.25)
			LandmarkDetail.window(lm, "Wall", "Windows", q + Vector3(0, 9.4, 0), n, 1.5, 3.4, true, 0.25)
			LandmarkDetail.window(lm, "Wall", "Windows", q + Vector3(0, 14.8, 0), n, 1.2, 2.4, true, 0.2)
	# Cascade: main dome on its drum of 28 windows, four semi-domes each
	# with three exedrae, four corner domes and four weight turrets.
	var mc := Vector3(0, 18.0, 14.0)
	lm.box("Wall", mc + Vector3(0, 5.0, 0), Vector3(25.0, 10.0, 25.0))
	LandmarkKits.dome_on_drum(lm, "Wall", "Dome", mc + Vector3(0, 6.0, 0), 11.75, 4.0, 15.0, 0.0, 32, 28)
	LandmarkCeParts.arched_ring(lm, "Wall", "Windows", mc + Vector3(0, 6.6, 0), 11.75, 28, 1.2, 2.6, 0.0)
	var ft := mc + Vector3(0, 25.0, 0)
	lm.frustum("Gilt", ft, 0.3, 0.25, 1.6, 8)
	lm.lathe("Gilt", ft + Vector3(0, 1.6, 0), PackedVector2Array([Vector2(0.0, 0), Vector2(0.45, 0.25),
		Vector2(0.5, 0.6), Vector2(0.0, 0.9)]), 10)
	_crescent(lm, ft + Vector3(0, 3.1, 0), 0.9)
	for k in 4:
		var a := PI * 0.5 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		var sd := mc + d * 12.5 + Vector3(0, 4.0, 0)
		_half_dome(lm, "Dome", sd, d, 11.0, 9.0, 20)
		for e in 3:
			var ea := a + (float(e) - 1.0) * 0.75
			var ed := Vector3(cos(ea), 0, sin(ea))
			_half_dome(lm, "Dome", sd + ed * 9.0 + Vector3(0, -4.0, 0), ed, 4.0, 3.6, 10)
		for e in 5:
			var wa := a + (float(e) - 2.0) * 0.32
			var wd := Vector3(cos(wa), 0, sin(wa))
			LandmarkDetail.window(lm, "Wall", "Windows", sd + wd * 10.8 + Vector3(0, -0.2, 0), wd, 0.9, 1.6, true, 0.15)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var cc := mc + Vector3(sx * 22.0, 0, sz * 22.0)
			lm.frustum("Wall", cc, 5.4, 5.4, 2.0, 16)
			LandmarkCeParts.dome(lm, "Dome", cc + Vector3(0, 2.0, 0), 5.4, 4.0, 16)
			lm.frustum("Gilt", cc + Vector3(0, 6.0, 0), 0.15, 0.05, 1.2, 6)
			# Weight turret on the main dome's corner pier.
			var wt := mc + Vector3(sx * 11.0, 10.0, sz * 11.0)
			lm.frustum("Wall", wt, 2.2, 2.0, 7.0, 8, PI / 8.0)
			for k in 8:
				var a := TAU * (float(k) + 0.5) / 8.0
				lm.box("Windows", wt + Vector3(cos(a), 0, sin(a)) * 1.92 + Vector3(0, 3.6, 0), Vector3(0.6, 2.2, 0.05),
					Basis(Vector3.UP, PI * 0.5 - a), 0.0)
			lm.frustum("Wall", wt + Vector3(0, 7.0, 0), 2.4, 2.4, 0.5, 8, PI / 8.0)
			LandmarkCeParts.dome(lm, "Dome", wt + Vector3(0, 7.5, 0), 2.2, 2.4, 12)
			lm.frustum("Gilt", wt + Vector3(0, 9.9, 0), 0.12, 0.04, 1.4, 6)
	_blue_court(lm)
	# Six minarets: four on the prayer hall, two at the forecourt corners.
	for sx in [-1.0, 1.0]:
		for z in [-12.0, 40.0]:
			LandmarkKits.minaret(lm, "Wall", "Dome", Vector3(sx * 34.0, 0, z), 2.0, BLUE_TOP, 3)
		LandmarkKits.minaret(lm, "Wall", "Dome", Vector3(sx * 34.0, 0, -86.0), 2.0, 58.0, 2)
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 0, -14.0)
	model.add_child(pivot)
	lm.commit(pivot)

## Forecourt: outer wall with windows and the gate, the arcade of
## columns and pointed arches under 30 domes, and the hexagonal
## ablution fountain under its dome.
static func _blue_court(lm: LandmarkMesh) -> void:
	for p in [[0.0, -86.5, 65.0, 3.0], [-32.5, -50.0, 3.0, 76.0], [32.5, -50.0, 3.0, 76.0]]:
		lm.box("Wall", Vector3(float(p[0]), 4.5, float(p[1])), Vector3(float(p[2]), 9.0, float(p[3])))
	lm.box("Wall", Vector3(0, 7.0, -88.5), Vector3(8.0, 14.0, 3.0))
	lm.box("Windows", Vector3(0, 3.5, -90.02), Vector3(3.0, 7.0, 0.05), Basis(), 0.0)
	LandmarkDetail.arch(lm, "Wall", Vector3(0, 7.0, -90.0), Vector3.FORWARD, 3.0, 0.5, 0.3)
	LandmarkCeParts.dome(lm, "Dome", Vector3(0, 14.0, -88.5), 3.0, 2.6, 14)
	for i in 6:
		LandmarkDetail.window(lm, "Wall", "Windows", Vector3(-27.0 + 4.0 * i + (0.0 if i < 3 else 30.0), 3.4, -88.0),
			Vector3.FORWARD, 1.4, 2.4, false, 0.2)
	# Arcade bays: (x, z) of each dome, columns on the inner corners.
	var bays: Array[Vector2] = []
	for i in 9:
		bays.append(Vector2(-26.0 + 6.5 * i, -82.0))
		bays.append(Vector2(-26.0 + 6.5 * i, -18.0))
	for i in 6:
		bays.append(Vector2(-27.5, -82.0 + 64.0 * float(i + 1) / 7.0))
		bays.append(Vector2(27.5, -82.0 + 64.0 * float(i + 1) / 7.0))
	for b in bays:
		var c := Vector3(b.x, 9.0, b.y)
		lm.frustum("Wall", c, 3.2, 3.2, 1.0, 16)
		LandmarkCeParts.dome(lm, "Dome", c + Vector3(0, 1.0, 0), 3.2, 2.6, 16)
		lm.frustum("Gilt", c + Vector3(0, 3.6, 0), 0.1, 0.03, 0.9, 6)
	lm.box("Wall", Vector3(0, 8.4, -78.3), Vector3(58.0, 1.2, 0.8))
	lm.box("Wall", Vector3(0, 8.4, -21.7), Vector3(58.0, 1.2, 0.8))
	for sx in [-1.0, 1.0]:
		lm.box("Wall", Vector3(sx * 23.6, 8.4, -50.0), Vector3(0.8, 1.2, 57.0))
	var cols: Array[Vector3] = []
	for i in 9:
		cols.append(Vector3(-23.6 + 5.9 * i, 0, -78.3))
		cols.append(Vector3(-23.6 + 5.9 * i, 0, -21.7))
	for i in 5:
		cols.append(Vector3(-23.6, 0, -78.3 + 56.6 * float(i + 1) / 6.0))
		cols.append(Vector3(23.6, 0, -78.3 + 56.6 * float(i + 1) / 6.0))
	for c in cols:
		LandmarkDetail.column(lm, "Wall", c, 0.42, 5.6, "tuscan", 0)
	# Pointed arches springing from the column capitals.
	for i in 8:
		for z in [-78.3, -21.7]:
			var a := Vector3(-23.6 + 5.9 * i, 5.6, float(z))
			_pointed_arch(lm, "Wall", a, a + Vector3(5.9, 0, 0), 2.4)
	for sx in [-1.0, 1.0]:
		for i in 6:
			var a := Vector3(sx * 23.6, 5.6, -78.3 + 56.6 * float(i) / 6.0)
			_pointed_arch(lm, "Wall", a, a + Vector3(0, 0, 56.6 / 6.0), 2.6)
	# Şadırvan: hexagonal fountain with grilles under a dome on columns.
	var fc := Vector3(0, 0, -50.0)
	lm.frustum("Wall", fc, 4.2, 4.0, 0.6, 6)
	lm.frustum("Wall", fc + Vector3(0, 0.6, 0), 3.0, 3.0, 1.4, 6)
	for k in 6:
		var a := TAU * float(k) / 6.0
		lm.frustum("Wall", fc + Vector3(cos(a) * 3.8, 0.6, sin(a) * 3.8), 0.2, 0.18, 3.6, 8)
	lm.frustum("Wall", fc + Vector3(0, 4.2, 0), 4.4, 4.4, 0.4, 6)
	LandmarkCeParts.dome(lm, "Dome", fc + Vector3(0, 4.6, 0), 4.2, 3.0, 12)
	lm.frustum("Gilt", fc + Vector3(0, 7.6, 0), 0.12, 0.04, 1.0, 6)

## Pointed arch from springer a to b (same height), apex `rise` above.
static func _pointed_arch(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, rise: float) -> void:
	var prev := a
	for k in 8:
		var t := float(k + 1) / 8.0
		var p := a.lerp(b, t) + Vector3(0, rise * pow(sin(PI * t), 0.7), 0)
		lm.beam(key, prev, p, 0.4, 0.6)
		prev = p

# --- Galata Tower ---

const GALATA_TOP := 66.9

static func galata(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B0A184", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#7C705C", 3.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#6B7176", 2.5))
	lm.use("Windows", LandmarkMaterials.glass("#202A30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Terrace and plinth at street level, then the battered shaft.
	lm.frustum("Dark", Vector3.ZERO, 11.5, 11.2, 0.6, 32)
	lm.frustum("Stone", Vector3(0, 0.6, 0), 9.0, 8.4, 2.4, 32)
	lm.lathe("Stone", Vector3(0, 3.0, 0), PackedVector2Array([Vector2(8.22, 0), Vector2(7.9, 20.0),
		Vector2(7.6, 44.0), Vector2(7.5, 47.0)]), 40)
	# String courses between the nine storeys.
	for lvl in 9:
		var y := 3.0 + 5.2 * lvl
		var rr := 8.22 - y * 0.0152
		lm.frustum("Dark", Vector3(0, y, 0), rr + 0.12, rr + 0.12, 0.35, 40)
	# Arched windows, staggered storey by storey, and the door.
	for lvl in 7:
		var y := 9.0 + 5.6 * lvl
		var count := 4 if lvl < 2 else 6
		for k in count:
			var a := TAU * float(k) / float(count) + (0.5 if lvl % 2 == 1 else 0.0)
			var d := Vector3(cos(a), 0, sin(a))
			var rr := 8.22 - (y - 3.0) * 0.0152 - 0.08
			LandmarkDetail.window(lm, "Dark", "Windows", d * rr + Vector3(0, y, 0), d, 0.9, 2.2, true, 0.2)
	LandmarkDetail.window(lm, "Dark", "Windows", Vector3(0, 4.6, -8.2), Vector3.FORWARD, 1.6, 2.8, true, 0.3)
	# Machicolated flare: corbels with small arches between them.
	lm.lathe("Stone", Vector3(0, 50.0, 0), PackedVector2Array([Vector2(7.5, 0), Vector2(8.6, 1.0),
		Vector2(9.2, 2.2), Vector2(9.2, 4.4), Vector2(8.8, 4.8)]), 40)
	for k in 24:
		var a := TAU * k / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.lathe("Dark", d * 8.0 + Vector3(0, 49.2, 0), PackedVector2Array([Vector2(0.2, 0), Vector2(0.5, 1.0),
			Vector2(0.55, 2.0)]), 6)
		var b := Basis(Vector3.UP, PI * 0.5 - a)
		# Arched openings of the gallery and its parapet piers.
		lm.box("Dark", d * 9.2 + Vector3(0, 53.2, 0), Vector3(0.8, 2.0, 0.5), b)
		var na := a + TAU / 48.0
		var nd := Vector3(cos(na), 0, sin(na))
		LandmarkDetail.arch(lm, "Stone", nd * 9.3 + Vector3(0, 54.2, 0), nd, 1.6, 0.2, 0.2)
		lm.box("Dark", d * 9.2 + Vector3(0, 55.6, 0), Vector3(0.7, 0.9, 0.4), b)
	lm.frustum("Stone", Vector3(0, 54.8, 0), 7.6, 7.2, 4.6, 32)
	for k in 12:
		var a := TAU * k / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Dark", "Windows", d * 7.3 + Vector3(0, 57.0, 0), d, 1.1, 2.4, true, 0.2)
	# Railing round the viewing gallery.
	lm.frustum("Dark", Vector3(0, 55.0, 0), 9.3, 9.3, 0.12, 48)
	lm.frustum("Dark", Vector3(0, 56.1, 0), 9.3, 9.3, 0.08, 48)
	# Conical lead cap with its seams, and the finial.
	lm.lathe("Lead", Vector3(0, 59.4, 0), PackedVector2Array([Vector2(8.4, 0), Vector2(7.8, 0.6),
		Vector2(0.9, 6.6), Vector2(0.4, 7.0)]), 40)
	for k in 24:
		var a := TAU * k / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Lead", d * 7.85 + Vector3(0, 60.05, 0), d * 0.95 + Vector3(0, 66.05, 0), 0.1, 0.1, d.cross(Vector3.UP))
	lm.lathe("Gilt", Vector3(0, 65.8, 0), PackedVector2Array([Vector2(0.4, 0), Vector2(0.5, 0.3),
		Vector2(0.25, 0.5), Vector2(0.1, 0.6)]), 8)
	lm.frustum("Gilt", Vector3(0, 66.3, 0), 0.1, 0.03, GALATA_TOP - 66.3, 6)
	lm.commit(model)
