class_name LandmarkGwanghwamun
extends RefCounted

## Gwanghwamun, the main gate of Gyeongbokgung (rebuilt in Korean pine
## 2006-2010 to the 1865 design), in true metres (about 19 m to the
## ridge): the granite platform in coursed ashlar pierced by three
## rainbow-arched passages (hongyemun, the king's wider centre arch)
## that run right through it, its crenellated parapet (yeojang), and the
## two-storey timber pavilion of 3 x 2 bays on top — red columns,
## lattice doors, green-and-red dancheong bracket sets (dapo: between
## the columns as well as on them) under each eave, twin rafter layers,
## a skirt roof round the lower storey and the hipped-and-gabled upper
## roof (paljak) with concave tiled slopes, upswept corners, hip ridges
## carrying the japsang guardian figures and ridge-end ornaments. The
## pair of haetae guardians sits in front. Front faces south (+Z).

const TOP_M := 19.0
const BASE := Vector3(35.0, 5.6, 14.0)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B4ADA2", 3.0))
	lm.use("Timber", LandmarkMaterials.paint("#8E2B20", 0.7, 0.0))
	lm.use("Dancheong", LandmarkMaterials.paint("#3F7A66", 0.65, 0.0))
	lm.use("Tiles", LandmarkMaterials.pbr("slate", "#4A4E52", 1.5))
	lm.use("Shadow", LandmarkMaterials.paint("#1E1D1B", 0.9, 0.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#E8E2D6", 3.0))
	_platform(lm)
	# Lower storey: 3 x 2 bays of red columns round a plastered core with
	# lattice doors in the bays.
	var y1 := BASE.y + 0.6
	var low := Vector2(24.0, 9.6)
	lm.box("Granite", Vector3(0, BASE.y + 0.3, 0), Vector3(low.x + 2.0, 0.6, low.y + 2.0))
	lm.box("Plaster", Vector3(0, y1 + 1.6, 0), Vector3(low.x - 1.0, 3.2, low.y - 1.0))
	_columns(lm, y1, low, 3.4, 0.34)
	_lattice(lm, y1, low, 3.0)
	_brackets(lm, y1 + 3.4, low, 3)
	# Skirt roof round the lower storey.
	_rafters(lm, y1 + 4.3, low + Vector2(1.6, 1.6), 2.0)
	_roof(lm, y1 + 4.3, low + Vector2(5.0, 5.0), low + Vector2(-1.0, -1.0), 1.4, false)
	# Upper storey: columns, lattice wall and the hipped-and-gabled roof.
	var y2 := y1 + 5.0
	var up := Vector2(20.0, 6.6)
	lm.box("Timber", Vector3(0, y2 + 0.2, 0), Vector3(up.x + 0.6, 0.4, up.y + 0.6))
	lm.box("Plaster", Vector3(0, y2 + 1.3, 0), Vector3(up.x - 0.6, 2.6, up.y - 0.6))
	_columns(lm, y2, up, 2.6, 0.28)
	_lattice(lm, y2 + 0.2, up, 2.2)
	_brackets(lm, y2 + 2.6, up, 3)
	var ridge_y := TOP_M - 1.2
	_rafters(lm, y2 + 3.3, up + Vector2(1.6, 1.6), 2.6)
	var eave := up + Vector2(6.6, 6.0)
	var top := Vector2(up.x * 0.62, 0.8)
	_roof(lm, y2 + 3.3, eave, top, ridge_y - (y2 + 3.3), true)
	_hips(lm, y2 + 3.3, eave, top, ridge_y - (y2 + 3.3))
	# Main ridge, its tiled flanks and the chimi ridge-end ornaments.
	lm.box("Tiles", Vector3(0, ridge_y + 0.4, 0), Vector3(top.x + 1.0, 0.8, 0.9))
	lm.box("Plaster", Vector3(0, ridge_y + 0.05, 0), Vector3(top.x + 0.8, 0.12, 1.0), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		var e := Vector3(s * (top.x * 0.5 + 0.6), ridge_y, 0)
		lm.box("Tiles", e + Vector3(0, 0.6, 0), Vector3(0.8, TOP_M - ridge_y, 0.9))
		lm.box("Tiles", e + Vector3(-s * 0.4, TOP_M - ridge_y - 0.3, 0), Vector3(0.6, 0.6, 0.6))
		lm.beam("Tiles", e + Vector3(s * 0.3, TOP_M - ridge_y - 0.6, 0), e + Vector3(s * 0.7, TOP_M - ridge_y - 0.1, 0), 0.3, 0.5)
	# Haetae guardians on their plinths in front of the gate.
	for s in [-1.0, 1.0]:
		_haetae(lm, Vector3(s * 9.0, 0, BASE.z * 0.5 + 9.0))
	lm.commit(model)

## Granite platform: coursed ashlar with real passages — piers between
## the arches, the vault through the depth, voussoir rings on both
## faces — a moulded band and the crenellated parapet with gun holes.
static func _platform(lm: LandmarkMesh) -> void:
	var hx := BASE.x * 0.5
	var hz := BASE.z * 0.5
	# [x, width, crown height]
	var arches := [[-9.0, 3.6, 4.0], [0.0, 5.0, 4.6], [9.0, 3.6, 4.0]]
	var x0 := -hx
	for a in arches:
		var ax := float(a[0])
		var aw := float(a[1])
		var ah := float(a[2])
		var left := ax - aw * 0.5
		lm.box("Granite", Vector3((x0 + left) * 0.5, BASE.y * 0.5, 0), Vector3(left - x0, BASE.y, BASE.z))
		var spring := ah - aw * 0.5
		lm.box("Granite", Vector3(ax, (ah + BASE.y) * 0.5, 0), Vector3(aw, BASE.y - ah, BASE.z))
		_vault(lm, ax, aw * 0.5, spring, ah, hz)
		lm.box("Granite", Vector3(ax, 0.06, 0), Vector3(aw, 0.12, BASE.z), Basis(), 0.0)
		for s in [-1.0, 1.0]:
			LandmarkDetail.arch(lm, "Granite", Vector3(ax, spring, s * hz), Vector3(0, 0, s), aw, 0.45, 0.15)
		x0 = ax + aw * 0.5
	lm.box("Granite", Vector3((x0 + hx) * 0.5, BASE.y * 0.5, 0), Vector3(hx - x0, BASE.y, BASE.z))
	# Plinth and ashlar course lines.
	lm.box("Granite", Vector3(0, 0.3, 0), Vector3(BASE.x + 0.6, 0.6, BASE.z + 0.6))
	# Course joints on the piers (not across the passages).
	var piers := [[-hx, -10.8], [-7.2, -2.5], [2.5, 7.2], [10.8, hx]]
	for k in range(1, 6):
		var y := 0.95 * k
		for pr in piers:
			var pa := float(pr[0])
			var pb := float(pr[1])
			for s in [-1.0, 1.0]:
				lm.box("Shadow", Vector3((pa + pb) * 0.5, y, s * (hz + 0.005)), Vector3(pb - pa, 0.04, 0.02), Basis(), 0.0)
	lm.box("Granite", Vector3(0, BASE.y - 0.2, 0), Vector3(BASE.x + 0.5, 0.4, BASE.z + 0.5))
	# Parapet: low wall with crenels every 2.2 m and a gun hole in each.
	for s in [-1.0, 1.0]:
		_parapet(lm, Vector3(-hx + 0.3, BASE.y, s * (hz - 0.3)), Vector3(hx - 0.3, BASE.y, s * (hz - 0.3)), Vector3(0, 0, s))
		_parapet(lm, Vector3(s * (hx - 0.3), BASE.y, -hz + 0.9), Vector3(s * (hx - 0.3), BASE.y, hz - 0.9), Vector3(s, 0, 0))

## Half-round vault through the platform: the soffit as a half cylinder
## facing inward and the spandrel fill above it on both faces.
static func _vault(lm: LandmarkMesh, ax: float, r: float, spring: float, crown: float, hz: float) -> void:
	var rows: Array = []
	var segs := 12
	for zz in [-hz, hz]:
		var line := PackedVector3Array()
		for k in segs + 1:
			var t := PI * k / segs
			line.append(Vector3(ax + cos(t) * r, spring + sin(t) * r, float(zz)))
		rows.append(line)
	lm.grid("Shadow", rows, Vector3(ax, spring, 0), true)
	# Square-sided lower passage walls.
	for s in [-1.0, 1.0]:
		lm.quad("Shadow", Vector3(ax + s * r, 0, -hz), Vector3(ax + s * r, 0, hz), Vector3(ax + s * r, spring, hz),
			Vector3(ax + s * r, spring, -hz), Vector3(-s, 0, 0))
	# Spandrels between the arch and the crown block, both faces.
	for zs in [-1.0, 1.0]:
		var z: float = zs * hz
		var n := Vector3(0, 0, zs)
		for k in segs:
			var t0 := PI * k / segs
			var t1 := PI * (k + 1) / segs
			var p0 := Vector3(ax + cos(t0) * r, spring + sin(t0) * r, z)
			var p1 := Vector3(ax + cos(t1) * r, spring + sin(t1) * r, z)
			lm.quad("Granite", p0, p1, Vector3(p1.x, crown, z), Vector3(p0.x, crown, z), n)

## Parapet a-b on the platform edge facing `out`: wall, coping, and
## crenels with a square gun hole.
static func _parapet(lm: LandmarkMesh, a: Vector3, b: Vector3, out: Vector3) -> void:
	var dir := (b - a).normalized()
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var dl := a.distance_to(b)
	lm.box("Granite", (a + b) * 0.5 + Vector3(0, 0.45, 0), Vector3(dl, 0.9, 0.6), basis)
	var n := int(dl / 2.2)
	for k in n:
		var p := a.lerp(b, (k + 0.5) / n)
		lm.box("Granite", p + Vector3(0, 1.15, 0), Vector3(1.7, 0.5, 0.6), basis)
		lm.box("Shadow", p + Vector3(0, 0.55, 0) + out * 0.31, Vector3(0.22, 0.22, 0.02), basis, 0.0)
		lm.lathe("Granite", p + Vector3(0, 1.4, 0), PackedVector2Array([Vector2(0.85, 0), Vector2(0.0, 0.3)]),
			4, 1.0, 0.36, PI * 0.25, false)

## Round red columns on stone bases round a `size` rectangle: 4 x 3
## positions (3 x 2 bays), with the interior ones left out.
static func _columns(lm: LandmarkMesh, y: float, size: Vector2, h: float, r: float) -> void:
	for i in 4:
		for j in 3:
			if j == 1 and i > 0 and i < 3:
				continue
			var p := Vector3(-size.x * 0.5 + size.x * i / 3.0, y, -size.y * 0.5 + size.y * j / 2.0)
			lm.frustum("Granite", p, r * 1.5, r * 1.3, 0.25, 8)
			lm.lathe("Timber", p + Vector3(0, 0.25, 0), PackedVector2Array([Vector2(r, 0), Vector2(r * 1.04, h * 0.35),
				Vector2(r * 0.9, h - 0.25)]), 12)

## Lattice doors in each bay: a frame and a grid of thin muntins over
## the plaster (paper-backed changhoji), each bay split into four leaves.
static func _lattice(lm: LandmarkMesh, y: float, size: Vector2, h: float) -> void:
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * side)
		var span := size.x if side % 2 == 0 else size.y
		var depth := (size.y if side % 2 == 0 else size.x) * 0.5 - 0.45
		var bays := 3 if side % 2 == 0 else 2
		for b in bays:
			var x0 := -span * 0.5 + span * b / bays + 0.4
			var x1 := -span * 0.5 + span * (b + 1) / bays - 0.4
			var cx := (x0 + x1) * 0.5
			var w := x1 - x0
			lm.box("Timber", r * Vector3(cx, y + 0.25, depth), Vector3(w, 0.3, 0.12), r, 0.0)
			lm.box("Timber", r * Vector3(cx, y + h - 0.15, depth), Vector3(w, 0.3, 0.12), r, 0.0)
			for k in 5:
				lm.box("Timber", r * Vector3(x0 + w * k / 4.0, y + h * 0.5, depth), Vector3(0.12, h, 0.12), r, 0.0)
			var rows := int(h / 0.35)
			for k in range(1, rows):
				lm.box("Timber", r * Vector3(cx, y + 0.4 + (h - 0.55) * k / rows, depth + 0.02),
					Vector3(w, 0.05, 0.04), r, 0.0)
			for k in range(1, int(w / 0.35)):
				lm.box("Timber", r * Vector3(x0 + k * 0.35, y + h * 0.5, depth + 0.02), Vector3(0.05, h - 0.5, 0.04),
					r, 0.0)

## Dancheong bracket band under an eave: the painted beam, then bracket
## sets (dapo) on and between the columns, each three tiers of red
## bearing blocks and green arms stepping outward.
static func _brackets(lm: LandmarkMesh, y: float, size: Vector2, between: int) -> void:
	lm.box("Timber", Vector3(0, y + 0.15, 0), Vector3(size.x + 0.6, 0.3, size.y + 0.6))
	lm.box("Dancheong", Vector3(0, y + 0.45, 0), Vector3(size.x + 0.4, 0.3, size.y + 0.4))
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * side)
		var span := size.x if side % 2 == 0 else size.y
		var depth := (size.y if side % 2 == 0 else size.x) * 0.5
		var bays := 3 if side % 2 == 0 else 2
		var sets := bays * (between + 1)
		for k in sets + 1:
			var x := -span * 0.5 + span * k / sets
			for t in 3:
				var reach := 0.3 + 0.35 * t
				lm.box("Timber", r * Vector3(x, y + 0.7 + 0.25 * t, depth + reach - 0.1), Vector3(0.3, 0.14, 0.3), r, 0.0)
				lm.box("Dancheong", r * Vector3(x, y + 0.82 + 0.25 * t, depth + reach * 0.5),
					Vector3(0.18, 0.12, reach + 0.2), r, 0.0)
				lm.box("Dancheong", r * Vector3(x, y + 0.82 + 0.25 * t, depth + reach - 0.1),
					Vector3(0.9 + 0.2 * t, 0.12, 0.16), r, 0.0)
	lm.box("Dancheong", Vector3(0, y + 1.5, 0), Vector3(size.x + 2.2, 0.2, size.y + 2.2))

## Two rafter layers under an eave round a `size` rectangle: round
## rafters (seokkarae) every 0.45 m and the square flying rafters
## (buyeon) above them reaching further out, all `reach` long.
static func _rafters(lm: LandmarkMesh, y: float, size: Vector2, reach: float) -> void:
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * side)
		var span := size.x if side % 2 == 0 else size.y
		var depth := (size.y if side % 2 == 0 else size.x) * 0.5
		var n := int(span / 0.45)
		for k in n:
			var x := -span * 0.5 + span * (k + 0.5) / n
			lm.beam("Timber", r * Vector3(x, y - 0.35, depth - 0.2), r * Vector3(x, y - 0.05, depth + reach * 0.75),
				0.16, 0.16)
			lm.beam("Dancheong", r * Vector3(x, y - 0.12, depth + reach * 0.6), r * Vector3(x, y + 0.02, depth + reach),
				0.13, 0.13)

## Concave hipped roof from an eave rectangle `eave` up to a ridge
## rectangle `top` (a point-like top when tiny), `rise` high, with
## upswept corners and tile rows (sugiwa ribs) down every slope;
## `gabled` closes the ridge ends with gable boards.
static func _roof(lm: LandmarkMesh, y: float, eave: Vector2, top: Vector2, rise: float,
		gabled: bool) -> void:
	var rows: Array = []
	for k in 7:
		var t := float(k) / 6.0
		# Concave slope: steep near the ridge, flattening to the eave.
		var f := 1.0 - pow(1.0 - t, 1.8)
		var hx := lerpf(eave.x * 0.5, top.x * 0.5, f)
		var hz := lerpf(eave.y * 0.5, top.y * 0.5, f)
		var lift := (1.0 - t) * (1.0 - t) * 0.9
		var yy := y + rise * t
		var ring: Array = []
		for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)]:
			var cv := c as Vector2
			ring.append(Vector3(cv.x * hx, yy + lift, cv.y * hz))
		rows.append(ring)
	# Four slopes between consecutive corners, each a grid strip facing
	# away from a point deep under the roof.
	var res := 12
	for side in 4:
		var strip: Array = []
		for k in rows.size():
			var r := rows[k] as Array
			var a: Vector3 = r[side]
			var b: Vector3 = r[side + 1]
			var line := PackedVector3Array()
			for q in res + 1:
				var p := a.lerp(b, float(q) / res)
				line.append(p + Vector3(0, _sweep(float(q) / res, float(k) / 6.0), 0))
			strip.append(line)
		lm.grid("Tiles", strip, Vector3(0, y - 50.0, 0), true)
		# Tile rows: a convex roll every 0.55 m down the slope, from the
		# eave line up toward the top.
		var e0: Vector3 = (rows[0] as Array)[side]
		var e1: Vector3 = (rows[0] as Array)[side + 1]
		var n_rows := int(e0.distance_to(e1) / 0.55)
		for q in range(1, n_rows):
			var u := float(q) / n_rows
			var prev := Vector3.ZERO
			for k in rows.size():
				var a: Vector3 = (rows[k] as Array)[side]
				var b: Vector3 = (rows[k] as Array)[side + 1]
				var mid_t := 0.5 + (u - 0.5) * a.distance_to(b) / maxf(e0.distance_to(e1), 0.01)
				if mid_t < 0.02 or mid_t > 0.98:
					prev = Vector3.ZERO
					continue
				var p := a.lerp(b, mid_t) + Vector3(0, _sweep(mid_t, float(k) / 6.0) + 0.08, 0)
				if prev != Vector3.ZERO:
					lm.beam("Tiles", prev, p, 0.16, 0.12)
				prev = p
	var last: Array = rows[rows.size() - 1]
	var cap := PackedVector2Array()
	for i in 4:
		var v: Vector3 = last[i]
		cap.append(Vector2(v.x, v.z))
	lm.poly_prism("Tiles", cap, (last[0] as Vector3).y - 0.2, (last[0] as Vector3).y)
	if gabled:
		for s in [-1.0, 1.0]:
			var v0: Vector3 = last[0]
			lm.box("Timber", Vector3(s * absf(v0.x), v0.y + 0.4, 0), Vector3(0.2, 0.8, absf(v0.z) * 2.0 + 0.6))

## Corner upsweep of a roof slope at u along the eave (0..1) and t up
## the slope (0 eave, 1 top).
static func _sweep(u: float, t: float) -> float:
	var edge := absf(u - 0.5) * 2.0
	return pow(edge, 3.0) * 0.6 * (1.0 - t)

## Hip ridges from the four upswept eave corners to the ridge ends, each
## with a row of japsang guardian figures near its foot.
static func _hips(lm: LandmarkMesh, y: float, eave: Vector2, top: Vector2, rise: float) -> void:
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var cv := c as Vector2
		var prev := Vector3.ZERO
		for k in 7:
			var t := float(k) / 6.0
			var f := 1.0 - pow(1.0 - t, 1.8)
			var p := Vector3(cv.x * lerpf(eave.x * 0.5, top.x * 0.5, f), y + rise * t + (1.0 - t) * (1.0 - t) * 0.9
				+ 0.6 * (1.0 - t) + 0.3, cv.y * lerpf(eave.y * 0.5, top.y * 0.5, f))
			if k > 0:
				lm.beam("Tiles", prev, p, 0.55, 0.5)
				if k >= 1 and k <= 3:
					for m in 2:
						var q := prev.lerp(p, 0.3 + 0.4 * m)
						lm.box("Tiles", q + Vector3(0, 0.38, 0), Vector3(0.22, 0.32, 0.22), Basis(), 0.0)
						lm.box("Tiles", q + Vector3(0, 0.6, 0), Vector3(0.16, 0.14, 0.16), Basis(), 0.0)
			prev = p

## A haetae: a seated lion-like guardian on a stone plinth (about 2.5 m
## tall in all) looking out from the gate.
static func _haetae(lm: LandmarkMesh, p: Vector3) -> void:
	lm.box("Granite", p + Vector3(0, 0.45, 0), Vector3(2.0, 0.9, 3.0))
	var b := p + Vector3(0, 0.9, 0)
	lm.lathe("Granite", b, PackedVector2Array([Vector2(0.7, 0), Vector2(0.75, 0.5), Vector2(0.6, 1.0),
		Vector2(0.45, 1.3)]), 10, 1.0, 1.5)
	lm.lathe("Granite", b + Vector3(0, 1.1, 0.7), PackedVector2Array([Vector2(0.42, 0), Vector2(0.48, 0.3),
		Vector2(0.4, 0.6), Vector2(0.0, 0.75)]), 10)
	lm.box("Granite", b + Vector3(0, 1.4, 1.15), Vector3(0.5, 0.35, 0.3))
	lm.frustum("Granite", b + Vector3(0, 1.8, 0.65), 0.12, 0.02, 0.35, 6)
	for s in [-1.0, 1.0]:
		lm.box("Granite", b + Vector3(s * 0.45, 0.4, 1.0), Vector3(0.3, 0.8, 0.3))
		lm.lathe("Granite", b + Vector3(s * 0.6, 0.2, -0.6), PackedVector2Array([Vector2(0.35, 0), Vector2(0.4, 0.3),
			Vector2(0.0, 0.5)]), 8)
	lm.beam("Granite", b + Vector3(0, 0.3, -1.1), b + Vector3(0, 1.0, -1.5), 0.25, 0.25)
