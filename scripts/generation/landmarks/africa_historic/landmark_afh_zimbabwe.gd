class_name LandmarkAfhZimbabwe
extends RefCounted

## Great Zimbabwe in true metres: the Great Enclosure's elliptical
## dry-stone wall (up to 11 m high, battered, with the herringbone band on
## its north-eastern face), the long parallel passage behind the inner
## wall, the solid conical tower and a few low interior walls.

const GZ_A := 44.0
const GZ_B := 38.0
const GZ_SEGS := 96

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
	_wall(lm, 0.0, TAU, GZ_SEGS, GZ_A, GZ_B, 5.2, 3.4, 8.0, 3.0, [36, 0, 72], true)
	_wall(lm, deg_to_rad(30.0), deg_to_rad(140.0), 28, GZ_A - 5.2, GZ_B - 5.2, 2.6, 2.0, 4.8, 1.5, [], false)
	_wall(lm, deg_to_rad(200.0), deg_to_rad(340.0), 14, 12.0, 12.0, 2.0, 1.5, 2.8, 0.4, [], false,
		Vector3(-6, 0, 8))
	_wall(lm, deg_to_rad(20.0), deg_to_rad(220.0), 18, 7.0, 7.0, 1.8, 1.4, 2.3, 0.3, [], false,
		Vector3(14, 0, -6))
	_chevron_band(lm)
	_conical_tower(lm, Vector3(27, 0, -13))
	for p in [[-14.0, -6.0, 5.0], [10.0, 14.0, 4.5], [-20.0, 10.0, 4.0], [5.0, -18.0, 3.5]]:
		lm.frustum("Daga", Vector3(p[0], -0.4, p[1]), p[2], p[2] - 0.4, 1.2, 14)
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

## Two zigzag lines of the herringbone frieze on the outer face between
## north-north-east and north-west, ~0.8 of the local wall height.
static func _chevron_band(lm: LandmarkMesh) -> void:
	var t_start := deg_to_rad(10.0)
	var t_end := deg_to_rad(100.0)
	var cells := 90
	for row in 2:
		for j in cells:
			var ta := lerpf(t_start, t_end, float(j) / float(cells))
			var tb := lerpf(t_start, t_end, float(j + 1) / float(cells))
			var za := 0.45 if j % 2 == 0 else -0.45
			var zb := 0.45 if (j + 1) % 2 == 0 else -0.45
			var ya := 0.8 * _wall_h(ta, 8.0, 3.0) - 1.3 * float(row) + za
			var yb := 0.8 * _wall_h(tb, 8.0, 3.0) - 1.3 * float(row) + zb
			var pa := _pt(GZ_A, GZ_B, ta, lerpf(2.6, 1.7, ya / _wall_h(ta, 8.0, 3.0)) + 0.1) + Vector3(0, ya, 0)
			var pb := _pt(GZ_A, GZ_B, tb, lerpf(2.6, 1.7, yb / _wall_h(tb, 8.0, 3.0)) + 0.1) + Vector3(0, yb, 0)
			lm.beam("Chevron", pa, pb, 0.28, 0.22)

## The solid conical tower: 9 m high, 5.5 m across at the foot, with a
## chevron ring below its rounded top.
static func _conical_tower(lm: LandmarkMesh, c: Vector3) -> void:
	var prof := PackedVector2Array([Vector2(2.95, -0.8), Vector2(2.8, 0.0), Vector2(2.5, 2.7),
		Vector2(2.15, 5.7), Vector2(1.85, 7.8), Vector2(1.6, 8.5), Vector2(1.1, 8.9),
		Vector2(0.5, 9.1), Vector2(0.0, 9.15)])
	lm.lathe("Wall", c, prof, 16)
	var cells := 16
	for j in cells:
		var a0 := TAU * float(j) / float(cells)
		var a1 := TAU * float(j + 1) / float(cells)
		var y0 := 6.7 + (0.45 if j % 2 == 0 else -0.45)
		var y1 := 6.7 + (0.45 if (j + 1) % 2 == 0 else -0.45)
		lm.beam("Chevron", c + Vector3(cos(a0) * 2.1, y0, sin(a0) * 2.1),
			c + Vector3(cos(a1) * 2.1, y1, sin(a1) * 2.1), 0.26, 0.2)
