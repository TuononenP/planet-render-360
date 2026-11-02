class_name LandmarkBrForth
extends RefCounted

## The Forth Bridge in true metres, along +X with y = 0 at the firth
## (LocationData `base: water`): three double cantilevers 521 m apart,
## each a 110 m tower of tubular legs narrowing from a 36 m base with a
## 206 m arm either side (top boom sloping down, lower boom sweeping up
## to the track), 107 m suspended girders between them, the side-span
## girders and the granite-pier approach viaducts, 2467 m in all, in the
## red oxide the bridge is famous for.

const CANTILEVERS: Array[float] = [-521.0, 0.0, 521.0]
const ARM := 206.0
const TOP_M := 110.0
const TRACK_M := 46.0
const GIRDER_TOP_M := 60.0
const FOOT_X := 18.0
const FOOT_Z := 18.0
const END_X := 1233.0

static func forth(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#A8412B")
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A89F91", 3.0))
	for c in CANTILEVERS:
		_cantilever(lm, c)
	# Suspended girders between cantilevers, side-span girders to the
	# abutments, approach viaducts beyond them.
	_girder(lm, -521.0 + ARM, -ARM)
	_girder(lm, ARM, 521.0 - ARM)
	_girder(lm, -934.0, -521.0 - ARM)
	_girder(lm, 521.0 + ARM, 934.0)
	for s in [-1.0, 1.0]:
		for x in [934.0, 984.0, 1034.0, 1084.0, 1134.0, 1184.0, END_X]:
			var h := lerpf(TRACK_M - 1.0, 24.0, (x - 934.0) / (END_X - 934.0))
			lm.box("Granite", Vector3(s * x, (h - 2.0) * 0.5, 0), Vector3(5.0, h + 2.0, 12.0))
		for k in 6:
			var xa := 934.0 + 49.8 * k
			var xb := xa + 49.8
			var y0 := lerpf(TRACK_M, 24.0, (xa - 934.0) / (END_X - 934.0))
			var y1 := lerpf(TRACK_M, 24.0, (xb - 934.0) / (END_X - 934.0))
			var r := Basis(Vector3.BACK, atan2(y1 - y0, (xb - xa) * s))
			var c := Vector3(s * (xa + xb) * 0.5, (y0 + y1) * 0.5, 0)
			var l := Vector2(xb - xa, y1 - y0).length()
			lm.box("Deck", c + Vector3(0, 0.2, 0), Vector3(l, 0.4, 10.0), r)
			lm.box("Steel", c + Vector3(0, -1.6, 0), Vector3(l, 3.0, 8.0), r)
	lm.commit(model)

## Half-width of a cantilever at distance u from its centre: 18 m at
## the tower narrowing to 5.5 m at the arm tips.
static func _half_z(u: float) -> float:
	return lerpf(FOOT_Z, 5.5, u / ARM)

## Centre line of the top boom (110 m at the tower, 62 m at the tip)
## and of the bottom boom (8 m at the foot rising to the track).
static func _top(u: float) -> float:
	return lerpf(TOP_M - 1.8, GIRDER_TOP_M + 1.0, pow(u / ARM, 1.15))

static func _bottom(u: float) -> float:
	return 8.0 + (TRACK_M - 8.0) * pow(u / ARM, 1.4)

static func _cantilever(lm: LandmarkMesh, c: float) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var foot := Vector3(c + sx * FOOT_X, 8.0, sz * FOOT_Z)
			lm.frustum("Granite", Vector3(foot.x, -3.0, foot.z), 9.5, 8.0, 13.0, 16)
			# Tower leg leaning in to the top, 4 m tube.
			lm.beam("Steel", foot, Vector3(c + sx * 3.0, TOP_M - 2.0, sz * 5.0), 4.0, 4.0)
	var n := 14
	for sx in [-1.0, 1.0]:
		for k in n + 1:
			var u := ARM * float(k) / n
			var x: float = c + sx * u
			var top := _top(u)
			var bot := _bottom(u)
			var z := _half_z(u)
			for sz in [-1.0, 1.0]:
				var zz: float = sz * z
				if k > 0:
					var up := ARM * float(k - 1) / n
					var xp: float = c + sx * up
					var zp: float = sz * _half_z(up)
					lm.beam("Steel", Vector3(xp, _top(up), zp), Vector3(x, top, zz), 3.4, 3.4)
					lm.beam("Steel", Vector3(xp, _bottom(up), zp), Vector3(x, bot, zz), 3.8, 3.8)
					var a := Vector3(xp, _bottom(up), zp) if k % 2 == 0 else Vector3(xp, _top(up), zp)
					var b := Vector3(x, top, zz) if k % 2 == 0 else Vector3(x, bot, zz)
					lm.beam("Steel", a, b, 1.6, 1.6)
				lm.beam("Steel", Vector3(x, bot, zz), Vector3(x, top, zz), 1.8, 1.8)
			if k % 2 == 0 and k < n:
				lm.beam("Steel", Vector3(x, top, -z), Vector3(x, top, z), 1.6, 1.6)
				lm.beam("Steel", Vector3(x, bot, -z), Vector3(x, bot, z), 1.8, 1.8)
	lm.box("Deck", Vector3(c, TRACK_M + 0.2, 0), Vector3(2.0 * ARM, 0.4, 10.0))

## Through-truss girder between x0 and x1 at the track, 14 m deep.
static func _girder(lm: LandmarkMesh, x0: float, x1: float) -> void:
	lm.box("Deck", Vector3((x0 + x1) * 0.5, TRACK_M + 0.2, 0), Vector3(x1 - x0, 0.4, 10.0))
	for z in [-5.5, 5.5]:
		LandmarkBrKit.truss_side(lm, "Steel", x0, x1, TRACK_M, GIRDER_TOP_M, z, 13.0, 1.4)
	lm.box("Steel", Vector3((x0 + x1) * 0.5, GIRDER_TOP_M, 0), Vector3(x1 - x0, 0.9, 11.0))
