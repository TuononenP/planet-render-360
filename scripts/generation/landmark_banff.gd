class_name LandmarkBanff
extends RefCounted

## Banff Springs Hotel in true metres: the Scottish-baronial "castle in
## the Rockies" — the eleven-storey central tower block (Painter, 1914)
## under a steep copper-green hipped roof with two tiers of dormers,
## corbelled corner bartizans with candle-snuffer caps and tall stone
## chimney stacks (59.5 m), and the two lower wings swept back from it
## with their own steep roofs, gabled pavilions, oriel bays and round
## end towers, all in grey-buff Mount Rundle limestone with dressed
## window surrounds and string courses; recessed windows throughout and
## the arched porte-cochère on the front. Front faces +Z, the wings
## angle back (−Z).

const TOP_M := 59.5
const FLOOR_M := 3.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9A9084", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#C9BFAE", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5C7466", 2.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	# Central tower block: 11 storeys, steep roof, dormers, bartizans.
	var walls := 11.0 * FLOOR_M + 1.0
	_block(lm, Vector3.ZERO, 0.0, Vector2(40.0, 22.0), walls, 14.0, 11)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3(sx * 20.5, 0, sz * 11.5)
			_bartizan(lm, c, 3.0, walls - 8.0, walls + 2.0, TOP_M - walls - 2.0)
	# Chimney stacks rising through the roof.
	for x in [-11.0, 11.0]:
		_chimney(lm, Vector3(float(x), walls + 2.0, 0), walls + 15.5)
	# Wings: eight storeys, swept back 30° from each end of the block.
	for s in [-1.0, 1.0]:
		var yaw: float = s * deg_to_rad(30.0)
		var dir := Vector3(s * cos(deg_to_rad(30.0)), 0, -sin(deg_to_rad(30.0)))
		var c := Vector3(s * 20.0, 0, -4.0) + dir * 36.0
		var ww := 8.0 * FLOOR_M + 1.0
		var r := Basis(Vector3.UP, yaw)
		_block(lm, c, yaw, Vector2(70.0, 16.0), ww, 10.0, 8)
		var end := c + dir * 36.0
		_tower(lm, end, 4.2, ww + 3.0, 12.0)
		for x in [-24.0, 14.0]:
			_chimney(lm, c + r * Vector3(float(x), ww, 0), ww + 9.0)
		# A gabled pavilion halfway along each wing, with an oriel bay.
		_pavilion(lm, c + r * Vector3(0, 0, 9.0), r, ww + 6.0)
		for x in [-20.0, 20.0]:
			_oriel(lm, c + r * Vector3(float(x), FLOOR_M * 2.0, 8.0), r, FLOOR_M * 4.0)
	_porte_cochere(lm)
	lm.commit(model)

## A storeyed block at `c`, turned `yaw`, `size` (length X, depth Z),
## `walls` high under a steep flat-topped hipped roof `rise` high: a
## rusticated ground storey, string courses, recessed windows with
## dressed sills and heads on every face, a corbel table under the
## eaves, cresting on the flat top and two tiers of dormers.
static func _block(lm: LandmarkMesh, c: Vector3, yaw: float, size: Vector2, walls: float,
		rise: float, storeys: int) -> void:
	var r := Basis(Vector3.UP, yaw)
	lm.box("Stone", c + Vector3(0, walls * 0.5, 0), Vector3(size.x, walls, size.y), r)
	lm.box("Trim", c + Vector3(0, 0.5, 0), Vector3(size.x + 0.9, 1.0, size.y + 0.9), r)
	lm.box("Trim", c + Vector3(0, walls - 0.4, 0), Vector3(size.x + 1.0, 0.8, size.y + 1.0), r)
	lm.box("Trim", c + Vector3(0, FLOOR_M * 1.5, 0), Vector3(size.x + 0.8, 0.4, size.y + 0.8), r)
	lm.box("Trim", c + Vector3(0, walls - FLOOR_M - 0.6, 0), Vector3(size.x + 0.8, 0.3, size.y + 0.8), r)
	# Recessed windows on all four faces.
	for side in 4:
		var fr := r * Basis(Vector3.UP, PI * 0.5 * side)
		var span := size.x if side % 2 == 0 else size.y
		var half := (size.y if side % 2 == 0 else size.x) * 0.5
		var right := fr * Vector3.RIGHT
		var n := fr * Vector3.BACK
		var cols := maxi(2, floori(span / 4.2))
		var origin := c + n * half - right * span * 0.5
		LandmarkDetail.pierced_face(lm, "Stone", "Windows", origin, right, n, span, walls - 1.0, cols, storeys,
			Vector2(1.2, 2.0), FLOOR_M * 0.3, FLOOR_M, 0.35)
		for st in storeys:
			var y := FLOOR_M * (0.3 + st)
			for k in cols:
				var x := -span * 0.5 + span * (k + 0.5) / cols
				var wc := c + fr * Vector3(x, 0, half + 0.35)
				lm.box("Trim", wc + Vector3(0, y - 0.1, 0) + n * 0.08, Vector3(1.6, 0.2, 0.25), fr, 0.0)
				lm.box("Trim", wc + Vector3(0, y + 2.15, 0) + n * 0.06, Vector3(1.5, 0.3, 0.2), fr, 0.0)
		# Corbel table under the eaves.
		for k in int(span / 1.2):
			var x := -span * 0.5 + 0.6 + 1.2 * k
			lm.box("Trim", c + fr * Vector3(x, walls - 1.1, half + 0.55), Vector3(0.4, 0.6, 0.4), fr, 0.0)
	var hx := size.x * 0.5 + 0.8
	var hz := size.y * 0.5 + 0.8
	_hip(lm, c + Vector3(0, walls, 0), r, hx, hz, 0.32, rise)
	# Iron cresting along the flat top.
	var tx := hx * 0.32
	var tz := hz * 0.32
	for s in [-1.0, 1.0]:
		lm.box("Trim", c + r * Vector3(0, walls + rise + 0.3, s * tz), Vector3(tx * 2.0, 0.6, 0.2), r, 0.0)
		lm.box("Trim", c + r * Vector3(s * tx, walls + rise + 0.3, 0), Vector3(0.2, 0.6, tz * 2.0), r, 0.0)
	# Dormers in two tiers on the long slopes, one on each hip end.
	for tier in 2:
		var f := 0.3 + 0.35 * tier
		var dz := lerpf(hz, hz * 0.32, f + 0.1)
		var n_d := maxi(2, floori(size.x / (7.0 + 3.0 * tier)))
		for k in n_d:
			var x := -size.x * 0.4 + size.x * 0.8 * (k + 0.5) / n_d
			for s in [-1.0, 1.0]:
				_dormer(lm, c + r * Vector3(x * lerpf(1.0, 0.6, f), walls + rise * f, s * dz), r * Basis(Vector3.UP,
					0.0 if s > 0.0 else PI), 2.0 - 0.4 * tier)
	for s in [-1.0, 1.0]:
		_dormer(lm, c + r * Vector3(s * lerpf(hx, hx * 0.32, 0.45), walls + rise * 0.35, 0),
			r * Basis(Vector3.UP, PI * 0.5 * s), 1.8)

## A gabled dormer on a roof slope at `c` facing basis z: stone cheeks,
## a recessed window with a dressed surround, a steep gable with a
## finial.
static func _dormer(lm: LandmarkMesh, c: Vector3, r: Basis, w: float) -> void:
	var h := w * 1.3
	lm.box("Stone", c + Vector3(0, h * 0.5, 0), Vector3(w * 1.25, h, w * 1.2), r)
	lm.box("Trim", c + r * Vector3(0, h * 0.5, w * 0.6 + 0.06), Vector3(w * 0.85, h * 0.8, 0.12), r, 0.0)
	lm.box("Windows", c + r * Vector3(0, h * 0.5, w * 0.6 + 0.13), Vector3(w * 0.6, h * 0.62, 0.04), r, 0.0)
	lm.box("Trim", c + r * Vector3(0, h * 0.5, w * 0.6 + 0.16), Vector3(0.08, h * 0.62, 0.04), r, 0.0)
	lm.gable("Roof", c + Vector3(0, h, 0), w * 1.25, w * 1.2, w * 0.95, r, 0.15, "Stone")
	lm.frustum("Trim", c + Vector3(0, h + w * 0.95, 0) + r * Vector3(0, 0, w * 0.6), 0.12, 0.02, 0.9, 6)

## Steep hipped roof with a flat cresting top (k of the eave size) over
## an hx x hz eave rectangle at `c`, turned by `r`.
static func _hip(lm: LandmarkMesh, c: Vector3, r: Basis, hx: float, hz: float, k: float,
		rise: float) -> void:
	var corners := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	var eave: Array[Vector3] = []
	var top: Array[Vector3] = []
	for q in corners:
		var v := q as Vector2
		eave.append(c + r * Vector3(v.x * hx, 0, v.y * hz))
		top.append(c + r * Vector3(v.x * hx * k, rise, v.y * hz * k))
	for i in 4:
		var j := (i + 1) % 4
		var n := (eave[j] - eave[i]).cross(top[i] - eave[i]).normalized()
		var mid := (eave[i] + eave[j]) * 0.5 - c
		if n.dot(Vector3(mid.x, 0.0, mid.z)) < 0.0:
			n = -n
		lm.quad("Roof", eave[i], eave[j], top[j], top[i], n)
		# Hip roll along each arris.
		lm.beam("Roof", eave[i] + Vector3(0, 0.15, 0), top[i] + Vector3(0, 0.15, 0), 0.35, 0.3)
	lm.quad("Roof", top[0], top[1], top[2], top[3], Vector3.UP)

## A corbelled bartizan at a corner: the round turret springs at
## `from` from a stepped corbel cone, string courses and slit windows,
## up to `h`, then the candle-snuffer cap `cap` high and its finial.
static func _bartizan(lm: LandmarkMesh, c: Vector3, rad: float, from: float, h: float, cap: float) -> void:
	lm.lathe("Stone", c + Vector3(0, from - 3.0, 0), PackedVector2Array([Vector2(0.4, 0), Vector2(rad * 0.6, 1.0),
		Vector2(rad * 0.85, 2.0), Vector2(rad, 3.0)]), 16)
	for k in 3:
		lm.frustum("Trim", c + Vector3(0, from - 2.4 + 0.9 * k, 0), rad * (0.55 + 0.17 * k) + 0.15,
			rad * (0.55 + 0.17 * k) + 0.15, 0.25, 16)
	lm.frustum("Stone", c + Vector3(0, from, 0), rad, rad, h - from, 16)
	for k in 2:
		lm.frustum("Trim", c + Vector3(0, from + (h - from) * (0.33 + 0.33 * k), 0), rad + 0.15, rad + 0.15, 0.3, 16)
	for k in 4:
		var a := TAU * (k + 0.5) / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Windows", c + d * (rad + 0.02) + Vector3(0, from + (h - from) * 0.55, 0), Vector3(0.5, 1.8, 0.08),
			Basis.looking_at(d), 0.0)
	_cap(lm, c + Vector3(0, h, 0), rad, cap)

## Round end tower: from the ground, with windows per storey, a corbel
## ring, the conical cap and finial.
static func _tower(lm: LandmarkMesh, c: Vector3, rad: float, h: float, cap: float) -> void:
	lm.frustum("Trim", c, rad + 0.4, rad + 0.3, 1.0, 20)
	lm.frustum("Stone", c, rad, rad, h, 20)
	for st in int(h / FLOOR_M) - 1:
		for k in 5:
			var a := TAU * k / 5.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.box("Windows", c + d * (rad + 0.02) + Vector3(0, FLOOR_M * (st + 0.7), 0), Vector3(1.0, 1.8, 0.08),
				Basis.looking_at(d), 0.0)
			lm.box("Trim", c + d * (rad + 0.1) + Vector3(0, FLOOR_M * (st + 0.7) - 1.0, 0), Vector3(1.4, 0.2, 0.25),
				Basis.looking_at(d), 0.0)
	for k in 20:
		var a := TAU * k / 20.0
		lm.box("Trim", c + Vector3(cos(a), 0, sin(a)) * (rad + 0.2) + Vector3(0, h - 0.8, 0), Vector3(0.4, 0.6, 0.4),
			Basis(), 0.0)
	_cap(lm, c + Vector3(0, h, 0), rad, cap)

## Candle-snuffer cap: eave ring, a concave cone, a ball and spike finial.
static func _cap(lm: LandmarkMesh, base: Vector3, rad: float, cap: float) -> void:
	lm.frustum("Trim", base, rad + 0.35, rad + 0.35, 0.5, 20)
	lm.lathe("Roof", base + Vector3(0, 0.5, 0), PackedVector2Array([Vector2(rad + 0.5, 0),
		Vector2(rad * 0.75, cap * 0.2), Vector2(rad * 0.45, cap * 0.5), Vector2(rad * 0.15, cap * 0.85),
		Vector2(0.0, cap - 1.4)]), 20)
	lm.lathe("Trim", base + Vector3(0, cap - 1.2, 0), PackedVector2Array([Vector2(0.06, 0), Vector2(0.22, 0.2),
		Vector2(0.06, 0.45)]), 8)
	lm.frustum("Trim", base + Vector3(0, cap - 0.75, 0), 0.06, 0.01, 0.75, 6)

## A stone chimney stack from `base` up to `top`: shaft, a band and a
## corbelled cap with four pots.
static func _chimney(lm: LandmarkMesh, base: Vector3, top: float) -> void:
	var h := top - base.y
	lm.box("Stone", base + Vector3(0, h * 0.5 - 0.5, 0), Vector3(2.6, h - 1.0, 1.4))
	lm.box("Trim", base + Vector3(0, h * 0.6, 0), Vector3(2.8, 0.25, 1.6), Basis(), 0.0)
	lm.box("Trim", base + Vector3(0, h - 0.7, 0), Vector3(3.0, 0.4, 1.8))
	for k in 4:
		lm.frustum("Stone", base + Vector3(-0.9 + 0.6 * k, h - 0.5, 0), 0.22, 0.18, 0.5, 8)

## A gabled pavilion projecting from a wing: stone front with recessed
## windows, a stepped (crow-step) gable and a finial.
static func _pavilion(lm: LandmarkMesh, c: Vector3, r: Basis, h: float) -> void:
	lm.box("Stone", c + Vector3(0, h * 0.5, 0), Vector3(12.0, h, 4.0), r)
	var n := r * Vector3.BACK
	var right := r * Vector3.RIGHT
	LandmarkDetail.pierced_face(lm, "Stone", "Windows", c + n * 2.0 - right * 6.0, right, n, 12.0, h - 1.0, 3,
		int(h / FLOOR_M), Vector2(1.2, 2.0), FLOOR_M * 0.3, FLOOR_M, 0.3)
	lm.box("Trim", c + Vector3(0, h - 0.3, 0), Vector3(12.6, 0.6, 4.6), r)
	lm.gable("Roof", c + Vector3(0, h, 0), 12.0, 4.0, 6.0, r, 0.4, "Stone")
	# Crow-steps up both rakes of the front gable.
	for s in [-1.0, 1.0]:
		for k in 5:
			var x: float = s * (6.0 - 1.2 * k - 0.6)
			lm.box("Stone", c + r * Vector3(x, h + 0.6 + 1.2 * k, 2.1), Vector3(1.2, 1.2, 0.6), r)
	lm.box("Stone", c + r * Vector3(0, h + 6.3, 2.1), Vector3(1.2, 1.0, 0.6), r)
	lm.frustum("Trim", c + r * Vector3(0, h + 6.8, 2.1), 0.15, 0.02, 1.2, 6)

## A corbelled oriel bay window, three-sided (half a hexagon standing
## out of the wall), `h` tall, from `base` on the wall face.
static func _oriel(lm: LandmarkMesh, base: Vector3, r: Basis, h: float) -> void:
	var n := r * Vector3.BACK
	var rot := atan2(n.z, n.x) + PI / 6.0
	var rad := 1.8
	lm.lathe("Trim", base + Vector3(0, -1.2, 0), PackedVector2Array([Vector2(0.3, 0), Vector2(rad, 1.2)]), 6,
		1.0, 1.0, rot, false)
	lm.frustum("Stone", base, rad, rad, h, 6, rot)
	var front := rad * cos(PI / 6.0)
	for k in int(h / FLOOR_M):
		for side in [-1.0, 0.0, 1.0]:
			var fr := r * Basis(Vector3.UP, float(side) * PI / 3.0)
			var c := base + fr * Vector3(0, FLOOR_M * (k + 0.5), front + 0.02)
			lm.box("Windows", c, Vector3(1.0 if side == 0.0 else 0.7, 2.0, 0.06), fr, 0.0)
			lm.box("Trim", c + Vector3(0, -1.1, 0) + fr * Vector3(0, 0, 0.06), Vector3(1.4 if side == 0.0 else 1.0,
				0.2, 0.2), fr, 0.0)
	lm.lathe("Roof", base + Vector3(0, h, 0), PackedVector2Array([Vector2(rad + 0.2, 0), Vector2(0.0, 1.8)]), 6,
		1.0, 1.0, rot, false)

## Porte-cochère on the front: three round arches on piers, a parapet
## with merlons, under which the cars pull in.
static func _porte_cochere(lm: LandmarkMesh) -> void:
	var c := Vector3(0, 0, 13.5)
	for x in [-6.0, -2.0, 2.0, 6.0]:
		lm.box("Stone", c + Vector3(float(x), 2.8, 2.0), Vector3(1.4, 5.6, 1.4))
		lm.box("Stone", c + Vector3(float(x), 2.8, -1.5), Vector3(1.4, 5.6, 1.4))
	for k in 3:
		LandmarkDetail.arch(lm, "Trim", c + Vector3(-4.0 + 4.0 * k, 4.0, 2.7), Vector3(0, 0, 1), 2.6, 0.5, 0.2)
	lm.box("Stone", c + Vector3(0, 6.3, 0.3), Vector3(13.4, 1.4, 5.0))
	lm.box("Trim", c + Vector3(0, 7.15, 0.3), Vector3(13.8, 0.3, 5.4))
	for k in 7:
		lm.box("Stone", c + Vector3(-6.0 + 2.0 * k, 7.75, 2.8), Vector3(1.0, 0.9, 0.5))
