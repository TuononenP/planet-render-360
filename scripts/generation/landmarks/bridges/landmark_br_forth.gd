class_name LandmarkBrForth
extends RefCounted

## The Forth Bridge in true metres, along +X (north) with y = 0 at the
## firth (LocationData `base: water`), 2467 m in all: from the south
## (Queensferry) end the masonry arches, ten 51 m approach spans on
## granite piers, the Queensferry cantilever (44 m tower), a 107 m
## suspended girder, Inchgarvie (82 m tower), another suspended girder,
## Fife (44 m tower), five approach spans and the north arches. Each
## cantilever is a 110 m tower of four 3.7 m tubular columns on round
## granite piers, 36.6 m apart across the bridge at the foot closing to
## 10 m at the top, X-braced by tubes, with a 207 m arm either side:
## the compression members (bottom booms, columns, struts) are riveted
## tubes, the tension members (top booms, ties) open lattice girders,
## the track running through it all on its internal viaduct 46 m over
## high water; in the bridge's red oxide.

const TOWERS: Array[Vector2] = [Vector2(-450.5, 44.0), Vector2(133.5, 82.0), Vector2(717.5, 44.0)]
const ARM := 207.0
const TOP_M := 110.0
const TRACK_M := 46.0
const GIRDER_TOP_M := 61.0
const FOOT_M := 8.0
const FOOT_Z := 18.3
const TOP_Z := 5.0
const PANELS := 7
const END_X := 1233.5
const SOUTH_APPROACH := -679.5
const NORTH_APPROACH := 946.5
const SOUTH_ARCHES := -1189.5
const NORTH_ARCHES := 1201.5
const APPROACH_END_M := 40.0
const COL_R := 1.83
const STRUT_R := 1.2

static func forth(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#A8412B")
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A89F91", 3.0))
	for t in TOWERS:
		_tower(lm, t.x, t.y * 0.5)
		for dir in [-1.0, 1.0]:
			_arm(lm, t.x + dir * t.y * 0.5, dir)
	# Suspended girders between the arm tips.
	for pair in [[0, 1], [1, 2]]:
		var a: Vector2 = TOWERS[pair[0]]
		var b: Vector2 = TOWERS[pair[1]]
		_girder(lm, a.x + a.y * 0.5 + ARM, b.x - b.y * 0.5 - ARM)
	_approach(lm, SOUTH_APPROACH, SOUTH_ARCHES, 10)
	_approach(lm, NORTH_APPROACH, NORTH_ARCHES, 5)
	# Masonry arches at both ends, track carried on their spandrels.
	LandmarkBrKit.arcade(lm, "Granite", LandmarkBrKit.pier_line(-END_X, SOUTH_ARCHES, 4), 0.0,
		APPROACH_END_M - 0.6, APPROACH_END_M - 16.0, 1.0, 3.2, 5.0, 10)
	LandmarkBrKit.arcade(lm, "Granite", LandmarkBrKit.pier_line(NORTH_ARCHES, END_X, 3), 0.0,
		APPROACH_END_M - 0.6, APPROACH_END_M - 16.0, 1.0, 3.2, 5.0, 10)
	for ends in [[-END_X, SOUTH_ARCHES], [NORTH_ARCHES, END_X]]:
		var a: float = ends[0]
		var b: float = ends[1]
		lm.box("Deck", Vector3((a + b) * 0.5, APPROACH_END_M - 0.3, 0), Vector3(b - a, 0.6, 10.0))
		for z in [-5.3, 5.3]:
			lm.box("Granite", Vector3((a + b) * 0.5, APPROACH_END_M + 0.3, z), Vector3(b - a, 1.2, 0.6))
	lm.commit(model)

## Height of the top boom (centre line) at u along an arm: 108 m at the
## tower top down to the 62 m tip; the bottom boom curving up from the
## 8 m foot to the track girder's underside; the bottom boom's half-
## spacing narrowing from 18.3 m at the piers to 5 m at the tip.
static func _top(u: float) -> float:
	return lerpf(TOP_M - 2.0, GIRDER_TOP_M + 1.0, u / ARM)

static func _bottom(u: float) -> float:
	return FOOT_M + (TRACK_M - 2.0 - FOOT_M) * pow(u / ARM, 1.5)

static func _bz(u: float) -> float:
	return lerpf(FOOT_Z, TOP_Z, pow(u / ARM, 0.8))

## A cantilever tower centred at c, half-length hx along the bridge:
## granite piers, four tubular columns, X tubes in the side faces,
## lattice bracing across the ends, lattice girders tying the tops.
static func _tower(lm: LandmarkMesh, c: float, hx: float) -> void:
	for sx in [-1.0, 1.0]:
		var x: float = c + sx * hx
		for sz in [-1.0, 1.0]:
			var z: float = sz * FOOT_Z
			lm.lathe("Granite", Vector3(x, 0, z), PackedVector2Array([Vector2(8.5, 0), Vector2(8.3, 1.2),
				Vector2(7.2, 6.4), Vector2(7.6, 6.8), Vector2(7.6, 7.2)]), 24)
			lm.frustum("Steel", Vector3(x, 7.2, z), 3.2, 2.6, FOOT_M - 7.2, 12)
			LandmarkCoreBBridgeKit.tube(lm, "Steel", PackedVector3Array([Vector3(x, FOOT_M, z),
				Vector3(x, (FOOT_M + TOP_M) * 0.5, sz * (FOOT_Z + TOP_Z) * 0.5), Vector3(x, TOP_M - 2.0, sz * TOP_Z)]),
				COL_R, 12)
		# End face across the bridge: horizontal lattice girders at the track
		# and the top, lattice X between them.
		var p0 := Vector3(x, TRACK_M - 3.0, -_col_z(TRACK_M - 3.0))
		var p1 := Vector3(x, TRACK_M - 3.0, _col_z(TRACK_M - 3.0))
		var q0 := Vector3(x, TOP_M - 3.0, -TOP_Z)
		var q1 := Vector3(x, TOP_M - 3.0, TOP_Z)
		LandmarkBrKit.lattice_member(lm, "Steel", p0, p1, 2.4, Vector3.UP)
		LandmarkBrKit.lattice_member(lm, "Steel", q0, q1, 2.4, Vector3.UP)
		LandmarkBrKit.lattice_member(lm, "Steel", p0, q1, 1.8, Vector3.RIGHT)
		LandmarkBrKit.lattice_member(lm, "Steel", p1, q0, 1.8, Vector3.RIGHT)
		var f0 := Vector3(x, FOOT_M + 1.0, -FOOT_Z)
		var f1 := Vector3(x, FOOT_M + 1.0, FOOT_Z)
		LandmarkBrKit.lattice_member(lm, "Steel", f0, p1, 1.8, Vector3.RIGHT)
		LandmarkBrKit.lattice_member(lm, "Steel", f1, p0, 1.8, Vector3.RIGHT)
	# Side faces: the great X of tubular struts, foot to opposite top.
	for sz in [-1.0, 1.0]:
		var fz: float = sz * FOOT_Z
		var tz: float = sz * TOP_Z
		for sx in [-1.0, 1.0]:
			LandmarkCoreBBridgeKit.tube(lm, "Steel", PackedVector3Array([Vector3(c + sx * hx, FOOT_M + 1.0, fz),
				Vector3(c - sx * hx, TOP_M - 4.0, tz)]), STRUT_R, 12)
		LandmarkBrKit.lattice_member(lm, "Steel", Vector3(c - hx, TOP_M - 2.0, tz), Vector3(c + hx, TOP_M - 2.0, tz),
			3.0, Vector3.UP)
		LandmarkBrKit.lattice_member(lm, "Steel", Vector3(c - hx, TRACK_M - 3.0, sz * _col_z(TRACK_M - 3.0)),
			Vector3(c + hx, TRACK_M - 3.0, sz * _col_z(TRACK_M - 3.0)), 2.0, Vector3.UP)
		# Bottom tie between the column feet.
		LandmarkCoreBBridgeKit.tube(lm, "Steel", PackedVector3Array([Vector3(c - hx, FOOT_M + 0.5, fz),
			Vector3(c + hx, FOOT_M + 0.5, fz)]), STRUT_R, 12)
	_track(lm, c - hx, c + hx, TRACK_M)

## Half-spacing of a tower column at height y.
static func _col_z(y: float) -> float:
	return lerpf(FOOT_Z, TOP_Z, (y - FOOT_M) / (TOP_M - 2.0 - FOOT_M))

## One cantilever arm from the tower column line at x0 outward along dir.
static func _arm(lm: LandmarkMesh, x0: float, dir: float) -> void:
	for sz in [-1.0, 1.0]:
		var bottom := PackedVector3Array()
		for k in PANELS * 2 + 1:
			var u := ARM * float(k) / float(PANELS * 2)
			bottom.append(Vector3(x0 + dir * u, _bottom(u), sz * _bz(u)))
		LandmarkCoreBBridgeKit.tube(lm, "Steel", bottom, COL_R, 12)
		for k in PANELS:
			var ua := ARM * float(k) / PANELS
			var ub := ARM * float(k + 1) / PANELS
			var ta := Vector3(x0 + dir * ua, _top(ua), sz * TOP_Z)
			var tb := Vector3(x0 + dir * ub, _top(ub), sz * TOP_Z)
			var bb := Vector3(x0 + dir * ub, _bottom(ub), sz * _bz(ub))
			# Top boom: a lattice girder; strut: a tube; tie: lattice.
			LandmarkBrKit.lattice_member(lm, "Steel", ta, tb, 3.0, Vector3.UP)
			LandmarkCoreBBridgeKit.tube(lm, "Steel", PackedVector3Array([bb, tb]),
				lerpf(STRUT_R, 0.7, float(k) / PANELS), 12)
			LandmarkBrKit.lattice_member(lm, "Steel", ta, bb, 2.0, Vector3(0, 0, 1))
	# Bracing between the two planes: top struts, bottom wind bracing.
	for k in PANELS:
		var ua := ARM * float(k) / PANELS
		var ub := ARM * float(k + 1) / PANELS
		var tb := _top(ub)
		LandmarkBrKit.lattice_member(lm, "Steel", Vector3(x0 + dir * ub, tb, -TOP_Z), Vector3(x0 + dir * ub, tb, TOP_Z),
			1.6, Vector3.UP)
		var a0 := Vector3(x0 + dir * ua, _bottom(ua), -_bz(ua))
		var a1 := Vector3(x0 + dir * ua, _bottom(ua), _bz(ua))
		var b0 := Vector3(x0 + dir * ub, _bottom(ub), -_bz(ub))
		var b1 := Vector3(x0 + dir * ub, _bottom(ub), _bz(ub))
		lm.beam("Steel", a0, b1, 0.9, 0.9)
		lm.beam("Steel", a1, b0, 0.9, 0.9)
		LandmarkBrKit.lattice_member(lm, "Steel", b0, b1, 1.4, Vector3(1, 0, 0))
		# Internal viaduct posts from the bottom boom up to the track.
		if _bottom(ub) < TRACK_M - 5.0:
			for sz in [-1.0, 1.0]:
				var foot := Vector3(x0 + dir * ub, _bottom(ub) + 1.5, sz * _bz(ub))
				lm.beam("Steel", foot, Vector3(x0 + dir * ub, TRACK_M - 3.5, sz * 3.4), 1.0, 0.8)
	_track(lm, minf(x0, x0 + dir * ARM), maxf(x0, x0 + dir * ARM), TRACK_M)

## Track girders from xa to xb at rail level y: two plate girders with
## stiffeners under the double track, deck, rails and parapet railings.
static func _track(lm: LandmarkMesh, xa: float, xb: float, y: float) -> void:
	var mid := (xa + xb) * 0.5
	var l := xb - xa
	lm.box("Deck", Vector3(mid, y - 0.3, 0), Vector3(l, 0.6, 9.6))
	for z in [-3.4, 3.4]:
		lm.box("Steel", Vector3(mid, y - 2.2, z), Vector3(l, 3.2, 0.6))
	for rz in [-3.0, -1.5, 1.5, 3.0]:
		lm.box("Steel", Vector3(mid, y + 0.1, rz), Vector3(l, 0.2, 0.15), Basis(), 0.0)
	for z in [-4.9, 4.9]:
		LandmarkBrKit.railing(lm, "Steel", Vector3(xa, y, z), Vector3(xb, y, z), 1.1, 3.0)

## Through-truss suspended girder between the arm tips x0 and x1: two
## 15 m Warren trusses, top lateral bracing and portal ends.
static func _girder(lm: LandmarkMesh, x0: float, x1: float) -> void:
	_track(lm, x0, x1, TRACK_M)
	for z in [-5.0, 5.0]:
		LandmarkBrKit.truss_side(lm, "Steel", x0, x1, TRACK_M - 1.0, GIRDER_TOP_M, z, 10.7, 1.4)
	var n := 10
	for k in n:
		var xa := lerpf(x0, x1, float(k) / n)
		var xb := lerpf(x0, x1, float(k + 1) / n)
		lm.beam("Steel", Vector3(xa, GIRDER_TOP_M, -5.0), Vector3(xb, GIRDER_TOP_M, 5.0), 0.6, 0.6)
		lm.beam("Steel", Vector3(xa, GIRDER_TOP_M, 5.0), Vector3(xb, GIRDER_TOP_M, -5.0), 0.6, 0.6)
		lm.beam("Steel", Vector3(xb, GIRDER_TOP_M, -5.0), Vector3(xb, GIRDER_TOP_M, 5.0), 0.8, 0.8)

## Approach viaduct from the cantilever end xa to the arches at xb in n
## 51 m spans: tapered granite piers with moulded caps carrying a pair
## of lattice girders under the track, falling from 46 to 40 m.
static func _approach(lm: LandmarkMesh, xa: float, xb: float, n: int) -> void:
	for k in n + 1:
		var x := lerpf(xa, xb, float(k) / n)
		var h := lerpf(TRACK_M, APPROACH_END_M, float(k) / n) - 7.5
		LandmarkBrKit.tapered_box(lm, "Granite", Vector3(x, 0, 0), 4.2, 7.6, 3.0, 6.0, h - 1.4)
		lm.box("Granite", Vector3(x, h - 0.7, 0), Vector3(7.0, 1.4, 13.0))
		lm.box("Granite", Vector3(x, 1.0, 0), Vector3(9.6, 2.0, 16.4))
		if k == n:
			break
		var x1 := lerpf(xa, xb, float(k + 1) / n)
		var y0 := lerpf(TRACK_M, APPROACH_END_M, float(k) / n)
		var y1 := lerpf(TRACK_M, APPROACH_END_M, float(k + 1) / n)
		var r := Basis(Vector3.BACK, atan2(y1 - y0, x1 - x))
		var c := Vector3((x + x1) * 0.5, (y0 + y1) * 0.5, 0)
		var l := Vector2(x1 - x, y1 - y0).length()
		lm.box("Deck", c + Vector3(0, -0.3, 0), Vector3(l, 0.6, 9.6), r)
		for z in [-3.4, 3.4]:
			var top := PackedVector3Array()
			var bot := PackedVector3Array()
			for j in 9:
				var p := Vector3(lerpf(x, x1, float(j) / 8.0), lerpf(y0, y1, float(j) / 8.0), z)
				top.append(p + Vector3(0, -0.8, 0))
				bot.append(p + Vector3(0, -6.0, 0))
			LandmarkCoreBBridgeKit.truss(lm, "Steel", bot, top, 0.8, 0.5, Vector3(0, 0, 1))
		for z in [-4.9, 4.9]:
			LandmarkBrKit.railing(lm, "Steel", Vector3(x, y0, z), Vector3(x1, y1, z), 1.1, 3.0)
