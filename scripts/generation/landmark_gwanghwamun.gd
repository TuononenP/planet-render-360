class_name LandmarkGwanghwamun
extends RefCounted

## Gwanghwamun, the main gate of Gyeongbokgung, in true metres (about
## 19 m to the ridge): the granite platform pierced by three arched
## passages (the king's wider centre arch), its parapet, and the
## two-storey timber pavilion on top — red columns, green-and-red
## dancheong brackets under each eave, a skirt roof round the lower
## storey and the hipped-and-gabled upper roof with concave slopes,
## upswept corners and ridge-end ornaments. Front faces south (+Z).

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
	var hx := BASE.x * 0.5
	var hz := BASE.z * 0.5
	# Platform: piers and lintels round the three passages [x, width, height].
	var arches := [[-9.0, 3.6, 4.0], [0.0, 5.0, 4.6], [9.0, 3.6, 4.0]]
	var x0 := -hx
	for a in arches:
		var ax := float(a[0])
		var aw := float(a[1])
		var ah := float(a[2])
		var left := ax - aw * 0.5
		lm.box("Granite", Vector3((x0 + left) * 0.5, BASE.y * 0.5, 0), Vector3(left - x0, BASE.y, BASE.z))
		# The arch springs at ah - aw/2: a square passage under a painted
		# half-round, crown at ah.
		var spring := ah - aw * 0.5
		lm.box("Granite", Vector3(ax, (spring + BASE.y) * 0.5, 0), Vector3(aw, BASE.y - spring, BASE.z))
		for s in [-1.0, 1.0]:
			lm.disc("Shadow", Vector3(ax, spring, s * (hz + 0.02)), Vector3(0, 0, s), aw * 0.5, 16)
		lm.box("Shadow", Vector3(ax, 0.02, 0), Vector3(aw, 0.04, BASE.z))
		x0 = ax + aw * 0.5
	lm.box("Granite", Vector3((x0 + hx) * 0.5, BASE.y * 0.5, 0), Vector3(hx - x0, BASE.y, BASE.z))
	for s in [-1.0, 1.0]:
		lm.box("Granite", Vector3(0, BASE.y + 0.5, s * (hz - 0.3)), Vector3(BASE.x, 1.0, 0.6))
		lm.box("Granite", Vector3(s * (hx - 0.3), BASE.y + 0.5, 0), Vector3(0.6, 1.0, BASE.z))
	# Lower storey: 3 x 2 bays of red columns round a plastered core.
	var y1 := BASE.y
	var low := Vector2(24.0, 9.6)
	lm.box("Plaster", Vector3(0, y1 + 1.7, 0), Vector3(low.x - 3.0, 3.4, low.y - 3.0))
	for i in 4:
		for j in 3:
			if j == 1 and i > 0 and i < 3:
				continue
			lm.lathe("Timber", Vector3(-low.x * 0.5 + low.x * i / 3.0, y1, -low.y * 0.5 + low.y * j / 2.0),
				PackedVector2Array([Vector2(0.32, 0), Vector2(0.3, 3.6)]), 8)
	_brackets(lm, y1 + 3.6, low)
	# Skirt roof round the lower storey.
	_roof(lm, y1 + 4.3, low + Vector2(5.0, 5.0), low + Vector2(-1.0, -1.0), 1.4, false)
	# Upper storey and the hipped-and-gabled roof.
	var y2 := y1 + 5.4
	var up := Vector2(20.0, 6.6)
	lm.box("Timber", Vector3(0, y2 + 1.3, 0), Vector3(up.x, 2.6, up.y))
	for i in 6:
		var x := -up.x * 0.5 + 2.0 + (up.x - 4.0) * i / 5.0
		for s in [-1.0, 1.0]:
			lm.box("Dancheong", Vector3(x, y2 + 1.4, s * (up.y * 0.5 + 0.06)), Vector3(1.6, 1.4, 0.1))
	_brackets(lm, y2 + 2.6, up)
	var ridge_y := TOP_M - 1.2
	_roof(lm, y2 + 3.3, up + Vector2(6.6, 6.0), Vector2(up.x * 0.62, 0.8), ridge_y - (y2 + 3.3), true)
	lm.box("Tiles", Vector3(0, ridge_y + 0.4, 0), Vector3(up.x * 0.62 * 2.0 * 0.5 + 1.0, 0.8, 0.9))
	for s in [-1.0, 1.0]:
		var e := Vector3(s * (up.x * 0.31 + 0.6), ridge_y, 0)
		lm.box("Tiles", e + Vector3(0, 0.6, 0), Vector3(0.8, TOP_M - ridge_y, 0.9))
		lm.box("Tiles", e + Vector3(-s * 0.4, TOP_M - ridge_y - 0.3, 0), Vector3(0.6, 0.6, 0.6))
	lm.commit(model)

## Green-and-red bracket band under an eave round an `size` rectangle.
static func _brackets(lm: LandmarkMesh, y: float, size: Vector2) -> void:
	lm.box("Dancheong", Vector3(0, y + 0.4, 0), Vector3(size.x + 0.8, 0.8, size.y + 0.8))
	lm.box("Timber", Vector3(0, y + 0.1, 0), Vector3(size.x + 1.0, 0.25, size.y + 1.0))

## Concave hipped roof from an eave rectangle `eave` up to a ridge
## rectangle `top` (a point-like top when tiny), `rise` high, with
## upswept corners; `gabled` closes the ridge ends with gable boards.
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
	for side in 4:
		var strip: Array = []
		for k in rows.size():
			var r := rows[k] as Array
			var a: Vector3 = r[side]
			var b: Vector3 = r[side + 1]
			var line := PackedVector3Array()
			for q in 7:
				var p := a.lerp(b, float(q) / 6.0)
				# Corners sweep up more than the middle of the eave.
				var edge := absf(float(q) / 6.0 - 0.5) * 2.0
				line.append(p + Vector3(0, pow(edge, 3.0) * 0.6 * (1.0 - float(k) / 6.0), 0))
			strip.append(line)
		lm.grid("Tiles", strip, Vector3(0, y - 50.0, 0), true)
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
