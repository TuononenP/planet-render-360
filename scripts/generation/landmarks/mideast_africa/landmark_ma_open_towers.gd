class_name LandmarkMaOpenTowers
extends RefCounted

## Two towers defined by their opening, in true metres: Riyadh's
## Kingdom Centre and the Dubai Frame.

# --- Kingdom Centre ---

const KC_TOP_M := 302.3
## Bottom of the inverted-parabola opening and the sky bridge's level.
const KC_HOLE_Y := 186.0
const KC_BRIDGE_Y := 293.0

## Half-width (x) and half-depth (z) of the almond plan at height y: the
## long faces bow in a little and the tower thins to a blade at the top.
static func _kc_plan(y: float) -> Vector2:
	var t := y / KC_TOP_M
	return Vector2(37.0 - 4.0 * t * t, 17.0 - 12.0 * pow(t, 1.6))

## Half-width of the opening at height y: zero below KC_HOLE_Y, then the
## parabola widening to 56 m at the bridge; the horns keep 3.5 m.
static func _kc_hole(y: float) -> float:
	if y <= KC_HOLE_Y:
		return 0.0
	var h := 28.0 * sqrt((y - KC_HOLE_Y) / (KC_BRIDGE_Y + 2.0 - KC_HOLE_Y))
	return minf(h, _kc_plan(y).x - 3.5)

## Ring points of the leg on side s at height y: the plan ellipse from
## the opening's edge round the outer end and back.
static func _kc_arc(y: float, s: float, n: int) -> PackedVector3Array:
	var pl := _kc_plan(y)
	var h := _kc_hole(y)
	var phi0 := acos(clampf(h / pl.x, 0.0, 1.0))
	var row := PackedVector3Array()
	for i in n + 1:
		var phi := lerpf(phi0, -phi0, float(i) / float(n))
		row.append(Vector3(s * pl.x * cos(phi), y, pl.y * sin(phi)))
	return row

## 302 m tower (2002): an almond-plan silver glass tower whose upper third
## is cut by the inverted-parabola opening ("bottle opener"), the 300 t
## steel sky bridge across its top at about 293 m, floor lines on the
## glass, and the two podium wings (the mall east, the events halls
## west).
static func kingdom_centre(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#3D5F7A"))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E2DDD2", 6.0))
	lm.use("Steel", LandmarkMaterials.paint("#8E979E", 0.35, 0.6))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#C2B8A6", 6.0))
	lm.box("Podium", Vector3(0, 0.3, 0), Vector3(320, 0.6, 110))
	var ys := PackedFloat32Array()
	for k in 16:
		ys.append(12.0 * float(k))
	for k in 31:
		ys.append(KC_HOLE_Y + (KC_TOP_M - KC_HOLE_Y) * pow(float(k) / 30.0, 1.6))
	var seg := 16
	for s in [-1.0, 1.0]:
		var outer: Array = []
		var inner: Array = []
		for y in ys:
			outer.append(_kc_arc(y, s, seg))
			if y >= KC_HOLE_Y:
				var pl := _kc_plan(y)
				var h := _kc_hole(y)
				var zc := pl.y * sqrt(maxf(1.0 - pow(h / pl.x, 2.0), 0.0))
				inner.append(PackedVector3Array([Vector3(s * h, y, zc), Vector3(s * h, y, 0), Vector3(s * h, y, -zc)]))
		lm.grid("Glass", outer, Vector3(0, 150, 0), true)
		lm.grid("Glass", inner, Vector3(s * 1000.0, 240, 0), true)
		# Cap on the horn.
		var top := _kc_arc(KC_TOP_M, s, seg)
		var c := (top[0] + top[seg]) * 0.5 * 0.5 + top[int(seg * 0.5)] * 0.5
		for i in seg:
			lm.tri("Steel", c, top[i], top[i + 1], Vector3.UP, Vector3.UP, Vector3.UP, Vector2.ZERO,
				Vector2(top[i].x, top[i].z), Vector2(top[i + 1].x, top[i + 1].z))
		lm.tri("Steel", c, top[seg], top[0], Vector3.UP, Vector3.UP, Vector3.UP, Vector2.ZERO, Vector2.ONE, Vector2.RIGHT)
		# Floor lines every third storey on the glass.
		var fy := 9.0
		while fy < KC_TOP_M - 4.0:
			var arc := _kc_arc(fy, s, seg)
			for i in seg:
				var o0 := Vector3(arc[i].x, 0, arc[i].z).normalized() * 0.18
				var o1 := Vector3(arc[i + 1].x, 0, arc[i + 1].z).normalized() * 0.18
				lm.beam("Steel", arc[i] + o0, arc[i + 1] + o1, 0.35, 0.2)
			fy += 10.5 if fy < KC_HOLE_Y else 7.5
	# Base of the opening: a steel lip round its rounded bottom.
	lm.beam("Steel", Vector3(0, KC_HOLE_Y + 0.2, _kc_plan(KC_HOLE_Y).y), Vector3(0, KC_HOLE_Y + 0.2,
		-_kc_plan(KC_HOLE_Y).y), 1.2, 0.6)
	_kc_bridge(lm)
	for s in [-1.0, 1.0]:
		_kc_podium(lm, s)
	lm.commit(model)

## Sky bridge: a glazed tube on a Warren truss spanning the opening.
static func _kc_bridge(lm: LandmarkMesh) -> void:
	var y := KC_BRIDGE_Y
	var half := _kc_hole(y + 2.0) + 1.0
	lm.box("Glass", Vector3(0, y + 2.4, 0), Vector3(half * 2.0, 4.0, 4.6))
	lm.box("Steel", Vector3(0, y + 4.6, 0), Vector3(half * 2.0, 0.5, 5.4))
	lm.box("Steel", Vector3(0, y + 0.2, 0), Vector3(half * 2.0, 0.4, 5.4))
	var n := 14
	for s in [-1.0, 1.0]:
		var z: float = s * 2.6
		lm.beam("Steel", Vector3(-half, y - 2.6, z), Vector3(half, y - 2.6, z), 0.5, 0.5)
		for i in n:
			var x0 := -half + 2.0 * half * float(i) / float(n)
			var x1 := -half + 2.0 * half * float(i + 1) / float(n)
			var yt := y if i % 2 == 0 else y - 2.6
			var yb := y - 2.6 if i % 2 == 0 else y
			lm.beam("Steel", Vector3(x0, yt, z), Vector3(x1, yb, z), 0.35, 0.35)
		for i in n + 1:
			var x := -half + 2.0 * half * float(i) / float(n)
			lm.beam("Steel", Vector3(x, y + 0.4, z), Vector3(x, y + 4.4, z), 0.25, 0.25)

## Podium wing on side s: a long rounded block, glazed clerestory and a
## shallow vaulted roof, its colonnaded entrance front.
static func _kc_podium(lm: LandmarkMesh, s: float) -> void:
	var cx := s * 95.0
	var poly := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		var c := cos(a)
		poly.append(Vector2(cx + 56.0 * signf(c) * pow(absf(c), 0.4), 30.0 * sin(a)))
	lm.poly_prism("Podium", poly, 0.6, 16.0)
	var inner := PackedVector2Array()
	for p in poly:
		inner.append(Vector2(cx + (p.x - cx) * 0.94, p.y * 0.9))
	lm.poly_prism("Glass", inner, 16.0, 19.0)
	lm.lathe("Stone", Vector3(cx, 19.0, 0), PackedVector2Array([Vector2(1.0, 0), Vector2(0.8, 2.0),
		Vector2(0.4, 3.2), Vector2(0.0, 3.5)]), 24, 54.0, 27.5)
	for i in 13:
		var x := cx + (float(i) - 6.0) * 7.0
		lm.frustum("Stone", Vector3(x, 0.6, 31.5), 0.7, 0.7, 12.0, 12)
	lm.box("Stone", Vector3(cx, 13.2, 31.5), Vector3(92, 1.2, 3.0))

# --- Dubai Frame ---

const FRAME_W := 95.53
const FRAME_H := 150.24
const FRAME_LEG := 15.0
const FRAME_D := 20.0

## 150 m picture frame in Zabeel Park (2018): two gold-clad towers 95.5 m
## apart outside, joined at the top by the glass-sided, glass-floored sky
## deck (48 floors up) and at the foot by the museum bar; the cladding
## is pierced in the ring pattern of the Expo 2020 logo, the inner faces
## glazed for the lifts.
static func dubai_frame(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Frame", LandmarkMaterials.pbr("concrete", "#C8A248", 3.0, 0.28, 0.7))
	lm.use("Glass", LandmarkMaterials.glass("#2E3A40"))
	lm.use("Plaza", LandmarkMaterials.pbr("pavement", "#CFC6B2", 5.0))
	var hw := FRAME_W * 0.5
	var lx := hw - FRAME_LEG * 0.5
	lm.box("Plaza", Vector3(0, 0.3, 0), Vector3(170, 0.6, 70))
	var g := 0.6
	var bridge_h := 12.0
	var base_h := 9.0
	for s in [-1.0, 1.0]:
		lm.box("Frame", Vector3(s * lx, (FRAME_H + g) * 0.5, 0), Vector3(FRAME_LEG, FRAME_H - g, FRAME_D))
		# Glazed lift band on the inner face, its gold mullions.
		var ix: float = s * (hw - FRAME_LEG) - s * 0.05
		lm.box("Glass", Vector3(ix, (FRAME_H - bridge_h + base_h) * 0.5, 0),
			Vector3(0.2, FRAME_H - bridge_h - base_h - 2.0, FRAME_D - 6.0), Basis(), 0.0)
		for k in 6:
			var z := -FRAME_D * 0.5 + 3.0 + (FRAME_D - 6.0) * float(k) / 5.0
			lm.box("Frame", Vector3(ix - s * 0.15, (FRAME_H - bridge_h + base_h) * 0.5, z),
				Vector3(0.3, FRAME_H - bridge_h - base_h - 2.0, 0.3), Basis(), 0.0)
		# Ring pattern on both broad faces of the leg.
		for zf in [-1.0, 1.0]:
			_frame_rings(lm, Vector3(s * lx, g, zf * (FRAME_D * 0.5 + 0.02)), Vector3(0, 0, zf),
				FRAME_LEG - 1.6, FRAME_H - g - 1.0)
		# Edge fins at the leg corners.
		for zf in [-1.0, 1.0]:
			for xf in [-1.0, 1.0]:
				lm.box("Frame", Vector3(s * lx + xf * (FRAME_LEG * 0.5 - 0.3), (FRAME_H + g) * 0.5,
					zf * (FRAME_D * 0.5 + 0.2)), Vector3(0.7, FRAME_H - g, 0.5), Basis(), 0.0)
	# Sky deck: gold edges, glass sides set back, the glass floor.
	var by := FRAME_H - bridge_h
	var inner_w := FRAME_W - FRAME_LEG * 2.0
	lm.box("Frame", Vector3(0, FRAME_H - 1.2, 0), Vector3(FRAME_W, 2.4, FRAME_D))
	lm.box("Frame", Vector3(0, by + 1.5, 0), Vector3(inner_w + 0.4, 3.0, FRAME_D))
	lm.box("Glass", Vector3(0, by + 6.0, 0), Vector3(inner_w, 6.0, FRAME_D - 1.6))
	lm.box("Glass", Vector3(0, by - 0.02, 0), Vector3(inner_w - 6.0, 0.1, FRAME_D - 6.0), Basis(), 0.0)
	for k in 13:
		var x := -inner_w * 0.5 + inner_w * float(k) / 12.0
		for zf in [-1.0, 1.0]:
			lm.box("Frame", Vector3(x, by + 6.0, zf * (FRAME_D * 0.5 - 0.6)), Vector3(0.4, 6.0, 0.4), Basis(), 0.0)
	for zf in [-1.0, 1.0]:
		_frame_rings(lm, Vector3(0, FRAME_H - 2.6, zf * (FRAME_D * 0.5 + 0.02)), Vector3(0, 0, zf), inner_w, 2.4)
	# Museum bar at the foot: gold band over a glazed ground floor.
	lm.box("Frame", Vector3(0, g + base_h * 0.5 + 2.5, 0), Vector3(inner_w + 0.4, base_h - 5.0, FRAME_D))
	lm.box("Glass", Vector3(0, g + 2.5, 0), Vector3(inner_w, 5.0, FRAME_D - 2.0))
	for k in 11:
		var x := -inner_w * 0.5 + inner_w * float(k) / 10.0
		for zf in [-1.0, 1.0]:
			lm.box("Frame", Vector3(x, g + 2.5, zf * (FRAME_D * 0.5 - 0.6)), Vector3(0.5, 5.0, 0.5), Basis(), 0.0)
	for zf in [-1.0, 1.0]:
		_frame_rings(lm, Vector3(0, g + 5.2, zf * (FRAME_D * 0.5 + 0.02)), Vector3(0, 0, zf), inner_w, base_h - 5.4)
	lm.commit(model)

## Relief of interlaced rings over a w x h face whose bottom centre is at
## `c`, facing `n`, in staggered rows.
static func _frame_rings(lm: LandmarkMesh, c: Vector3, n: Vector3, w: float, h: float) -> void:
	var r := Vector3.UP.cross(n).normalized()
	var pitch := 3.6
	var rad := 1.9
	var rows := maxi(int(h / (pitch * 0.866)), 1)
	var cols := maxi(int(w / pitch), 1)
	for j in rows:
		var y := (float(j) + 0.5) * h / float(rows)
		var off := 0.5 if j % 2 == 1 else 0.0
		for i in cols:
			var x := -w * 0.5 + (float(i) + 0.5 + off * (1.0 if i < cols - 1 else 0.0)) * w / float(cols)
			_ring(lm, c + r * x + Vector3(0, y, 0), r, n, minf(rad, h * 0.45), 0.35)

## Flat ring (annulus) in the face plane at `c`, outer radius ro, band
## width bw, standing 0.12 m proud of the face.
static func _ring(lm: LandmarkMesh, c: Vector3, r: Vector3, n: Vector3, ro: float, bw: float) -> void:
	var seg := 10
	var ri := ro - bw
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		var d0 := r * cos(a0) + Vector3.UP * sin(a0)
		var d1 := r * cos(a1) + Vector3.UP * sin(a1)
		var p := c + n * 0.12
		lm.quad("Frame", p + d0 * ri, p + d1 * ri, p + d1 * ro, p + d0 * ro, n)
		lm.quad("Frame", c + d0 * ro, c + d1 * ro, p + d1 * ro, p + d0 * ro, (d0 + d1).normalized())
