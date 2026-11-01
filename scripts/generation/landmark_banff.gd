class_name LandmarkBanff
extends RefCounted

## Banff Springs Hotel in true metres: the Scottish-baronial "castle in
## the Rockies" — the eleven-storey central tower block (Painter, 1914)
## under a steep copper-green hipped roof with dormers and corner
## turrets (59.5 m), and the two lower wings swept back from it with
## their own steep roofs and round end turrets, all in grey-buff Mount
## Rundle limestone. Front faces +Z, the wings angle back (−Z).

const TOP_M := 59.5
const FLOOR_M := 3.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9A9084", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#C9BFAE", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5C7466", 2.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	# Central tower block: 11 storeys, steep roof, dormers, turrets.
	var walls := 11.0 * FLOOR_M + 1.0
	_block(lm, Vector3.ZERO, 0.0, Vector2(40.0, 22.0), walls, 14.0, 11)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := Vector3(sx * 20.5, 0, sz * 11.5)
			_turret(lm, c, 3.0, walls + 2.0, TOP_M - walls - 2.0)
	# Wings: eight storeys, swept back 30° from each end of the block.
	for s in [-1.0, 1.0]:
		var yaw: float = s * deg_to_rad(30.0)
		var dir := Vector3(s * cos(deg_to_rad(30.0)), 0, -sin(deg_to_rad(30.0)))
		var c := Vector3(s * 20.0, 0, -4.0) + dir * 36.0
		var ww := 8.0 * FLOOR_M + 1.0
		_block(lm, c, yaw, Vector2(70.0, 16.0), ww, 10.0, 8)
		var end := c + dir * 36.0
		_turret(lm, end, 4.2, ww + 3.0, 12.0)
		# A gabled pavilion halfway along each wing.
		var r := Basis(Vector3.UP, yaw)
		lm.box("Stone", c + r * Vector3(0, (ww + 6.0) * 0.5, 9.0), Vector3(12.0, ww + 6.0, 4.0), r)
		lm.gable("Roof", c + r * Vector3(0, ww + 6.0, 9.0), 12.0, 4.0, 6.0, r, 0.4, "Stone")
	# Porte-cochère on the front.
	lm.box("Stone", Vector3(0, 3.5, 13.5), Vector3(12.0, 7.0, 5.0))
	lm.box("Trim", Vector3(0, 7.3, 13.5), Vector3(12.6, 0.6, 5.6))
	lm.commit(model)

## A storeyed block at `c`, turned `yaw`, `size` (length X, depth Z),
## `walls` high under a steep flat-topped hipped roof `rise` high, with
## a row of windows per storey and dormers on the long slopes.
static func _block(lm: LandmarkMesh, c: Vector3, yaw: float, size: Vector2, walls: float,
		rise: float, storeys: int) -> void:
	var r := Basis(Vector3.UP, yaw)
	lm.box("Stone", c + Vector3(0, walls * 0.5, 0), Vector3(size.x, walls, size.y), r)
	lm.box("Trim", c + Vector3(0, walls - 0.4, 0), Vector3(size.x + 0.6, 0.8, size.y + 0.6), r)
	lm.box("Trim", c + Vector3(0, FLOOR_M * 1.5, 0), Vector3(size.x + 0.3, 0.4, size.y + 0.3), r)
	var hx := size.x * 0.5 + 0.8
	var hz := size.y * 0.5 + 0.8
	_hip(lm, c + Vector3(0, walls, 0), r, hx, hz, 0.32, rise)
	var cols := maxi(3, floori(size.x / 4.2))
	for st in storeys:
		var y := FLOOR_M * (st + 0.55)
		for k in cols:
			var x := -size.x * 0.5 + size.x * (k + 0.5) / cols
			for s in [-1.0, 1.0]:
				lm.box("Windows", c + r * Vector3(x, y, s * (size.y * 0.5 + 0.1)), Vector3(1.2, 1.9, 0.2), r)
	# Dormers half way up the long slopes.
	var dz := hz * 0.62
	for k in maxi(2, floori(size.x / 7.0)):
		var x := -size.x * 0.4 + size.x * 0.8 * (k + 0.5) / maxi(2, floori(size.x / 7.0))
		for s in [-1.0, 1.0]:
			var dc := c + r * Vector3(x * 0.8, walls + rise * 0.35, s * dz)
			lm.box("Stone", dc + Vector3(0, 1.2, 0), Vector3(2.4, 2.4, 2.0), r)
			lm.box("Windows", dc + r * Vector3(0, 1.1, s * 1.02), Vector3(1.2, 1.4, 0.1), r)
			lm.gable("Roof", dc + Vector3(0, 2.4, 0), 2.4, 2.0, 1.4, r, 0.2, "Stone")

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
	lm.quad("Roof", top[0], top[1], top[2], top[3], Vector3.UP)

## A round turret: stone shaft `h` high, conical copper cap `cap` high.
static func _turret(lm: LandmarkMesh, c: Vector3, rad: float, h: float, cap: float) -> void:
	lm.lathe("Stone", c, PackedVector2Array([Vector2(rad, 0), Vector2(rad, h)]), 14)
	lm.frustum("Trim", c + Vector3(0, h, 0), rad + 0.3, rad + 0.3, 0.5, 14)
	lm.lathe("Roof", c + Vector3(0, h + 0.5, 0), PackedVector2Array([Vector2(rad + 0.5, 0),
		Vector2(rad * 0.45, cap * 0.55), Vector2(0.0, cap - 0.5)]), 14)
