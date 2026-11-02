class_name LandmarkChPorta
extends RefCounted

## The Porta Nigra of Trier (Roman, about 170 AD) in true metres: 36 m
## long, 21.5 m deep, 29.3 m high, of grey sandstone blackened by age.
## Two gate passages lead into a small courtyard between the field
## (north, -Z) and town (south, +Z) gate walls; the two flanking towers
## are rectangular on the town side and project as near semicircles on
## the field side. Every storey is an arcade of arched windows between
## Tuscan half-columns under an entablature. The west tower (-X) keeps
## its four storeys; the east tower lost its top storey when Napoleon had
## the church removed, leaving the stump of the medieval apse on its
## east side.

const TOP := 29.6
## Storey bases: ground (gates), first, second, third (west tower only).
const LEVELS := [0.0, 7.6, 14.2, 20.8]
const STOREY := 6.6

static func porta_nigra(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#6D645A", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#4F4940", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	_gate_walls(lm)
	for sx in [-1.0, 1.0]:
		_tower(lm, sx)
	_apse(lm)
	lm.commit(model)

## Field and town gate walls of the middle block, with their two
## passages each, and the galleries over them round the courtyard.
static func _gate_walls(lm: LandmarkMesh) -> void:
	var top := LEVELS[3] + 0.6
	for wall in [[-4.0, -0.6, -1.0], [7.2, 10.75, 1.0]]:
		var z0: float = wall[0]
		var z1: float = wall[1]
		var s: float = wall[2]
		var zc := (z0 + z1) * 0.5
		var face := z1 if s > 0.0 else z0
		var n := Vector3(0, 0, s)
		# Piers between and beside the two passages, then the upper wall.
		for x in [-4.6, 0.0, 4.6]:
			lm.box("Stone", Vector3(x, 3.3, zc), Vector3(1.4 if x != 0.0 else 1.8, 6.6, z1 - z0))
		lm.box("Stone", Vector3(0, (6.6 + top) * 0.5, zc), Vector3(10.6, top - 6.6, z1 - z0))
		for sx in [-1.0, 1.0]:
			var pc := Vector3(sx * 2.3, 4.6, face)
			_vault(lm, Vector3(sx * 2.3, 4.6, zc), 3.2, z1 - z0)
			LandmarkChParts.arch_band(lm, "Dark", pc, n, 3.2, 0.5, 0.3, 8)
		_arcade(lm, Vector3(-5.3, 0, face), Vector3.RIGHT, n, 10.6, LEVELS[1], 4)
		_arcade(lm, Vector3(-5.3, 0, face), Vector3.RIGHT, n, 10.6, LEVELS[2], 4)
		lm.box("Dark", Vector3(0, top + 0.3, zc), Vector3(10.8, 0.6, z1 - z0 + 0.6))
	# Courtyard faces of the gate walls.
	for z in [-0.6, 7.2]:
		var n := Vector3(0, 0, 1.0 if z < 0.0 else -1.0)
		for lv in [1, 2]:
			for i in 4:
				LandmarkChParts.arched_window(lm, "Dark", "Windows", Vector3(-3.9 + 2.6 * i, LEVELS[lv] + 1.4, z), n, 1.5,
					3.6, 0.2)

## Barrel vault soffit of a passage `span` wide springing at `c.y`, `d`
## deep, centred at `c`.
static func _vault(lm: LandmarkMesh, c: Vector3, span: float, d: float) -> void:
	var r := span * 0.5
	for i in 8:
		var t0 := PI * float(i) / 8.0
		var t1 := PI * float(i + 1) / 8.0
		var a := c + Vector3(cos(t0) * r, sin(t0) * r, 0)
		var b := c + Vector3(cos(t1) * r, sin(t1) * r, 0)
		var nm := -Vector3(cos((t0 + t1) * 0.5), sin((t0 + t1) * 0.5), 0)
		lm.quad("Dark", a - Vector3(0, 0, d * 0.5), b - Vector3(0, 0, d * 0.5), b + Vector3(0, 0, d * 0.5),
			a + Vector3(0, 0, d * 0.5), nm)

## One storey arcade on a flat face: `count` arched windows between
## Tuscan half-columns, the entablature band above. `o` is the face's
## bottom-left corner (y ignored), `r` along the face, `n` out.
static func _arcade(lm: LandmarkMesh, o: Vector3, r: Vector3, n: Vector3, w: float, y: float, count: int) -> void:
	var pitch := w / float(count)
	for i in count + 1:
		var p := Vector3(o.x, y, o.z) + r * (pitch * float(i))
		LandmarkChParts.half_column(lm, "Stone", p + n * 0.05, n, 0.36, STOREY - 1.0)
	for i in count:
		var p := Vector3(o.x, y, o.z) + r * (pitch * (float(i) + 0.5))
		LandmarkChParts.arched_window(lm, "Dark", "Windows", p + Vector3(0, 1.0, 0), n, minf(pitch * 0.55, 1.7), 3.4, 0.25)
	var mid := Vector3(o.x, y, o.z) + r * w * 0.5 + n * 0.25 + Vector3(0, STOREY - 0.6, 0)
	lm.box("Dark", mid, Vector3(w + 0.4, 0.6, 0.5), Basis(r, Vector3.UP, n), 0.0)
	lm.box("Stone", mid + Vector3(0, 0.45, 0) + n * 0.1, Vector3(w + 0.6, 0.3, 0.7), Basis(r, Vector3.UP, n), 0.0)

## One flanking tower: a rectangle on the town side, a half round on the
## field side; ground storey plain, then the arcaded storeys and the
## crowning cornice. sx -1 is the full west tower, +1 the cut-down east.
static func _tower(lm: LandmarkMesh, sx: float) -> void:
	var cx := sx * 11.5
	var storeys := 4 if sx < 0.0 else 3
	var h := TOP - 0.6 if sx < 0.0 else LEVELS[3] + 0.9
	lm.box("Stone", Vector3(cx, h * 0.5, 3.5), Vector3(13.0, h, 14.5))
	lm.frustum("Stone", Vector3(cx, 0, -3.75), 6.5, 6.5, h, 32)
	lm.box("Dark", Vector3(cx, h + 0.3, 3.5), Vector3(13.6, 0.6, 15.1))
	lm.frustum("Dark", Vector3(cx, h, -3.75), 6.8, 6.8, 0.6, 32)
	LandmarkChParts.band(lm, "Dark", 0.0, 6.5, 7.25, 0.9, 0.25, Vector3(cx, 0, 3.5))
	lm.frustum("Dark", Vector3(cx, 0, -3.75), 6.8, 6.8, 0.9, 32)
	for lv in range(1, storeys):
		var y: float = LEVELS[lv]
		# Town face, the outer end face, and the half round on the field side.
		_arcade(lm, Vector3(cx - 6.5, 0, 10.75), Vector3.RIGHT, Vector3.BACK, 13.0, y, 4)
		_arcade(lm, Vector3(sx * 18.0, 0, 10.75 if sx > 0.0 else -3.75), Vector3(0, 0, -sx), Vector3(sx, 0, 0),
			14.5, y, 5)
		for k in 8:
			var a := deg_to_rad(-180.0 + 22.5 * float(k))
			var d := Vector3(cos(a), 0, sin(a))
			LandmarkChParts.half_column(lm, "Stone", Vector3(cx, y, -3.75) + d * 6.5, d, 0.36, STOREY - 1.0)
			var wa := a + deg_to_rad(11.25)
			var wd := Vector3(cos(wa), 0, sin(wa))
			LandmarkChParts.arched_window(lm, "Dark", "Windows", Vector3(cx, y + 1.0, -3.75) + wd * 6.42, wd, 1.5, 3.4, 0.25)
		lm.frustum("Dark", Vector3(cx, y + STOREY - 0.9, -3.75), 6.75, 6.75, 0.6, 32)
		lm.frustum("Stone", Vector3(cx, y + STOREY - 0.3, -3.75), 6.85, 6.85, 0.3, 32)
	# Ground storey: plain slit windows in the masonry.
	for k in [-1.0, 0.0, 1.0]:
		LandmarkChParts.arched_window(lm, "Dark", "Windows", Vector3(cx + k * 3.6, 2.2, 10.75), Vector3.BACK, 0.8, 2.4, 0.15)

## Stump of the medieval apse against the east tower's east face.
static func _apse(lm: LandmarkMesh) -> void:
	var c := Vector3(18.0, 0, 3.5)
	var prof := PackedVector2Array([Vector2(4.6, 0), Vector2(4.6, 9.5)])
	lm.lathe("Dark", c, prof, 16, 1.0, 1.0, 0.0, true)
	lm.lathe("Dark", c + Vector3(0, 9.5, 0), PackedVector2Array([Vector2(5.0, 0), Vector2(3.0, 1.6), Vector2(0.0, 2.4)]), 16)
	for k in 3:
		var a := -PI * 0.25 + PI * 0.25 * k
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.arched_window(lm, "Stone", "Windows", c + d * 4.55 + Vector3(0, 3.2, 0), d, 1.0, 3.2, 0.2)
		LandmarkChParts.half_column(lm, "Stone", c + Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0)) * 4.6 + Vector3(0, 1.0, 0),
			Vector3(cos(a + PI / 8.0), 0, sin(a + PI / 8.0)), 0.25, 7.5)
