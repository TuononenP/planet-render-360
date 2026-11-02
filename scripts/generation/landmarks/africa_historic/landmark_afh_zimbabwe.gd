class_name LandmarkAfhZimbabwe
extends RefCounted

## Great Zimbabwe in true metres: the Great Enclosure's elliptical
## dry-stone girdle wall (about 250 m round, up to 11 m high and 6 m thick
## at the foot, battered, with the double chevron band along some 80 m of
## its north-eastern crest, monoliths and turrets on top, drains at its
## foot and three entrances with rounded ends and steps), the long
## parallel passage behind the inner wall, the solid conical tower (9 m,
## 5.5 m across) with the small tower and platform beside it, low
## interior walls and the daga hut platforms.

const GZ_A := 44.0
const GZ_B := 38.0
const GZ_SEGS := 192
## Outer wall segments left open for the entrances: north-west (main),
## north-east by the parallel passage, and the narrow south-west gate.
const GATES := [72, 0, 144]

## Wall height at angle t (counterclockwise from east, 0 at +X, north is
## -Z): 11 m in the north-east falling to 5 m in the south-west.
static func _wall_h(t: float, h_mid: float, h_amp: float) -> float:
	return h_mid + h_amp * cos(t - deg_to_rad(45.0))

## Point of the ellipse (a, b) centred on `c` at angle t, pushed `off`
## metres along the outward normal.
static func _pt(a: float, b: float, t: float, off: float, c: Vector3 = Vector3.ZERO) -> Vector3:
	var n := Vector2(cos(t) / a, -sin(t) / b).normalized()
	return c + Vector3(cos(t) * a + n.x * off, 0.0, -sin(t) * b + n.y * off)

static func great_enclosure(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#8E8577", 2.5))
	lm.use("Chevron", LandmarkMaterials.pbr("stone", "#6F675B", 2.0))
	lm.use("Daga", LandmarkMaterials.pbr("gravel", "#A38C6E", 3.0))
	# Outer wall with three entrances (north-west main gate, east, south);
	# the inner wall guards the passage; low enclosures inside.
	_wall(lm, 0.0, TAU, GZ_SEGS, GZ_A, GZ_B, 5.6, 1.8, 8.0, 3.0, GATES, true)
	_wall(lm, deg_to_rad(30.0), deg_to_rad(140.0), 40, GZ_A - 5.2, GZ_B - 5.2, 2.6, 2.0, 4.8, 1.5, [], false)
	_wall(lm, deg_to_rad(200.0), deg_to_rad(340.0), 24, 12.0, 12.0, 2.0, 1.5, 2.8, 0.4, [], false,
		Vector3(-6, 0, 8))
	_wall(lm, deg_to_rad(20.0), deg_to_rad(220.0), 28, 7.0, 7.0, 1.8, 1.4, 2.3, 0.3, [], false,
		Vector3(14, 0, -6))
	_chevron_band(lm)
	_wall_details(lm)
	_conical_tower(lm, Vector3(27, 0, -13))
	# The small conical tower beside it and the platform in front.
	lm.lathe("Wall", Vector3(31.2, 0, -10.6), PackedVector2Array([Vector2(1.25, -0.6), Vector2(1.2, 0.0),
		Vector2(1.05, 1.4), Vector2(0.85, 2.4), Vector2(0.4, 2.8), Vector2(0.0, 2.85)]), 16)
	lm.box("Wall", Vector3(23.0, 0.45, -10.0), Vector3(4.5, 1.3, 3.2))
	for k in 3:
		lm.box("Wall", Vector3(23.0 - 2.25 - 0.3 * float(k) - 0.15, 0.2 + 0.2 * float(2 - k) * 0.5, -10.0),
			Vector3(0.3, 0.4 + 0.4 * float(2 - k) * 0.5, 3.2), Basis(), 0.0)
	for p in [[-14.0, -6.0, 5.0], [10.0, 14.0, 4.5], [-20.0, 10.0, 4.0], [5.0, -18.0, 3.5]]:
		# Daga (clay) hut floor on a stone-faced platform, with the stub of
		# the hut's round wall and its doorway gap.
		lm.frustum("Wall", Vector3(p[0], -0.4, p[1]), p[2], p[2] - 0.3, 1.0, 24)
		lm.frustum("Daga", Vector3(p[0], 0.6, p[1]), p[2] - 0.5, p[2] - 0.6, 0.2, 24)
		var hr: float = float(p[2]) - 1.4
		for k in 14:
			if k == 0:
				continue
			var a0 := TAU * float(k) / 15.0
			var a1 := TAU * float(k + 1) / 15.0
			lm.beam("Daga", Vector3(p[0] + cos(a0) * hr, 1.1, p[1] + sin(a0) * hr),
				Vector3(p[0] + cos(a1) * hr, 1.1, p[1] + sin(a1) * hr), 0.35, 0.5, Vector3.ZERO, true)
	lm.commit(model)

## Battered wall along the ellipse arc t0..t1 in `segs` pieces: th0 thick
## at the foot (buried 1 m), th1 at the top, height from _wall_h. `gaps`
## lists segments left open (their ends are closed with end faces).
static func _wall(lm: LandmarkMesh, t0: float, t1: float, segs: int, a: float, b: float,
		th0: float, th1: float, h_mid: float, h_amp: float, gaps: Array, closed: bool,
		c: Vector3 = Vector3.ZERO) -> void:
	for i in segs:
		if gaps.has(i):
			continue
		var ta := lerpf(t0, t1, float(i) / float(segs))
		var tb := lerpf(t0, t1, float(i + 1) / float(segs))
		var ha := _wall_h(ta, h_mid, h_amp)
		var hb := _wall_h(tb, h_mid, h_amp)
		var down := Vector3(0, -1.0, 0)
		var bo_a := _pt(a, b, ta, th0 * 0.5, c) + down
		var bo_b := _pt(a, b, tb, th0 * 0.5, c) + down
		var bi_a := _pt(a, b, ta, -th0 * 0.5, c) + down
		var bi_b := _pt(a, b, tb, -th0 * 0.5, c) + down
		var to_a := _pt(a, b, ta, th1 * 0.5, c) + Vector3(0, ha, 0)
		var to_b := _pt(a, b, tb, th1 * 0.5, c) + Vector3(0, hb, 0)
		var ti_a := _pt(a, b, ta, -th1 * 0.5, c) + Vector3(0, ha, 0)
		var ti_b := _pt(a, b, tb, -th1 * 0.5, c) + Vector3(0, hb, 0)
		var out := (_pt(a, b, (ta + tb) * 0.5, 1.0, c) - _pt(a, b, (ta + tb) * 0.5, 0.0, c)).normalized()
		LandmarkAfhParts.quad_out(lm, "Wall", bo_a, bo_b, to_b, to_a, out)
		LandmarkAfhParts.quad_out(lm, "Wall", bi_a, bi_b, ti_b, ti_a, -out)
		LandmarkAfhParts.quad_out(lm, "Wall", to_a, to_b, ti_b, ti_a, Vector3.UP)
		var tangent := (_pt(a, b, tb, 0.0, c) - _pt(a, b, ta, 0.0, c)).normalized()
		var prev_open := gaps.has((i - 1 + segs) % segs) if closed else (i == 0 or gaps.has(i - 1))
		var next_open := gaps.has((i + 1) % segs) if closed else (i == segs - 1 or gaps.has(i + 1))
		if prev_open:
			LandmarkAfhParts.quad_out(lm, "Wall", bo_a, bi_a, ti_a, to_a, -tangent)
		if next_open:
			LandmarkAfhParts.quad_out(lm, "Wall", bo_b, bi_b, ti_b, to_b, tangent)

## Two zigzag lines of the chevron frieze on the outer face, about 80 m
## from the east round to the north, a metre or two under the crest.
static func _chevron_band(lm: LandmarkMesh) -> void:
	var t_start := deg_to_rad(-5.0)
	var t_end := deg_to_rad(107.0)
	var cells := 120
	for row in 2:
		for j in cells:
			var ta := lerpf(t_start, t_end, float(j) / float(cells))
			var tb := lerpf(t_start, t_end, float(j + 1) / float(cells))
			var za := 0.45 if j % 2 == 0 else -0.45
			var zb := 0.45 if (j + 1) % 2 == 0 else -0.45
			var ya := _wall_h(ta, 8.0, 3.0) - 1.1 - 1.3 * float(row) + za
			var yb := _wall_h(tb, 8.0, 3.0) - 1.1 - 1.3 * float(row) + zb
			var pa := _pt(GZ_A, GZ_B, ta, _face_off(ya, ta)) + Vector3(0, ya, 0)
			var pb := _pt(GZ_A, GZ_B, tb, _face_off(yb, tb)) + Vector3(0, yb, 0)
			lm.beam("Chevron", pa, pb, 0.28, 0.22)

## Offset of the outer wall face from the centre line at height y and
## angle t (the face batters from 2.8 m at the buried foot to 0.9 m).
static func _face_off(y: float, t: float) -> float:
	return lerpf(2.8, 0.9, (y + 1.0) / (_wall_h(t, 8.0, 3.0) + 1.0)) + 0.1

## Monoliths standing on the wall crest above the chevron band, drains
## through the foot of the outer wall, and stepped thresholds with
## rounded wall ends in the three entrances.
static func _wall_details(lm: LandmarkMesh) -> void:
	for i in 9:
		var t := deg_to_rad(15.0 + 9.0 * float(i))
		var h := _wall_h(t, 8.0, 3.0)
		var p := _pt(GZ_A, GZ_B, t, 0.6) + Vector3(0, h, 0)
		lm.beam("Wall", p - Vector3(0, 0.2, 0), p + Vector3(0, 0.9 + 0.4 * LandmarkAfhParts.hash01(i, 4), 0),
			0.32, 0.26, Vector3.ZERO, true)
		# Small turret beside every other monolith.
		if i % 2 == 0:
			lm.frustum("Wall", _pt(GZ_A, GZ_B, t + 0.04, 0.0) + Vector3(0, h - 0.2, 0), 0.75, 0.6, 1.1, 10)
	for i in 8:
		var t := TAU * (float(i) + 0.3) / 8.0
		var out := (_pt(GZ_A, GZ_B, t, 1.0) - _pt(GZ_A, GZ_B, t, 0.0)).normalized()
		var p := _pt(GZ_A, GZ_B, t, _face_off(0.2, t) - 0.04)
		var right := Vector3.UP.cross(out).normalized()
		lm.quad("Chevron", p - right * 0.25, p + right * 0.25, p + right * 0.25 + Vector3(0, 0.4, 0),
			p - right * 0.25 + Vector3(0, 0.4, 0), out)
	for g in GATES:
		var ta := TAU * float(g) / float(GZ_SEGS)
		var tb := TAU * float(g + 1) / float(GZ_SEGS)
		for e in [ta, tb]:
			var h := _wall_h(float(e), 8.0, 3.0)
			lm.lathe("Wall", _pt(GZ_A, GZ_B, float(e), 0.0) - Vector3(0, 1.0, 0), PackedVector2Array([
				Vector2(2.7, 0), Vector2(1.6, h * 0.6), Vector2(0.95, h + 1.0)]), 12)
		var tm := (ta + tb) * 0.5
		var out := (_pt(GZ_A, GZ_B, tm, 1.0) - _pt(GZ_A, GZ_B, tm, 0.0)).normalized()
		var basis := Basis(Vector3.UP, atan2(out.x, out.z))
		for k in 3:
			lm.box("Wall", _pt(GZ_A, GZ_B, tm, 1.8 - 1.2 * float(k)) + Vector3(0, 0.15 + 0.15 * float(k), 0),
				Vector3(1.6, 0.3 + 0.3 * float(k), 1.2), basis, 0.0)

## The solid conical tower: 9 m high, 5.5 m across at the foot, with a
## chevron ring below its rounded top.
static func _conical_tower(lm: LandmarkMesh, c: Vector3) -> void:
	var prof := PackedVector2Array([Vector2(2.95, -0.8), Vector2(2.8, 0.0), Vector2(2.5, 2.7),
		Vector2(2.15, 5.7), Vector2(1.85, 7.8), Vector2(1.6, 8.5), Vector2(1.1, 8.9),
		Vector2(0.5, 9.1), Vector2(0.0, 9.15)])
	lm.lathe("Wall", c, prof, 24)
	var cells := 16
	for j in cells:
		var a0 := TAU * float(j) / float(cells)
		var a1 := TAU * float(j + 1) / float(cells)
		var y0 := 6.7 + (0.45 if j % 2 == 0 else -0.45)
		var y1 := 6.7 + (0.45 if (j + 1) % 2 == 0 else -0.45)
		lm.beam("Chevron", c + Vector3(cos(a0) * 2.1, y0, sin(a0) * 2.1),
			c + Vector3(cos(a1) * 2.1, y1, sin(a1) * 2.1), 0.26, 0.2)
