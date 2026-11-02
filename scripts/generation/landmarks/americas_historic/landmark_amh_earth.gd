class_name LandmarkAmhEarth
extends RefCounted

## Two landmarks shaped from the ground itself, in true metres: the
## granite cliff of Mount Rushmore with its four colossal heads, and the
## earthen terraces of Monks Mound at Cahokia.

const RUSHMORE_TOP_M := 135.0
const MONKS_TOP_M := 30.0

## Mountain sections, base to summit: [y, half width, front depth (+Z,
## toward the viewers), back depth (-Z)]. Between y 79 and 121 the front
## is a near-vertical cliff, the carved face; below it the talus slope.
const RUSH_RINGS := [[-6.0, 80.0, 50.0, 62.0], [0.0, 80.0, 50.0, 62.0], [11.0, 77.0, 46.0, 59.0],
	[25.0, 74.0, 40.0, 56.0], [41.0, 71.0, 33.0, 53.0], [59.0, 68.0, 26.0, 50.0],
	[79.0, 66.0, 20.0, 46.0], [94.0, 64.0, 18.0, 43.0], [108.0, 62.0, 18.0, 40.0],
	[121.0, 60.0, 18.0, 36.0], [130.0, 52.0, 16.0, 28.0], [135.0, 36.0, 12.0, 18.0]]
const RUSH_SEG := 72
## Head height (chin to crown) in metres.
const HEAD_H := 18.3
## Heads from the viewers' left: [x centre, chin y, set-back (m), kind]
## 0 Washington, 1 Jefferson, 2 Lincoln, 3 Theodore Roosevelt.
const HEADS := [[-32.0, 94.0, 0.0, 0], [-16.0, 91.0, -2.0, 1], [8.0, 92.0, 0.0, 2],
	[26.0, 89.0, -1.0, 3]]

## Mount Rushmore: the granite mountain mass (135 m above the base
## viewing platform at y = 0, superelliptic sections with a rough
## shoulder) and, on its flat southeast-facing cliff, the four 18 m
## heads of Washington, Jefferson, Lincoln and Roosevelt carved in
## relief, the lower slopes under pine forest. Built with the faces toward +Z; yaw turns them southeast.
static func mount_rushmore(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#8F8A84", 8.0))
	lm.use("Forest", LandmarkMaterials.pbr("forest", "#33482C", 6.0))
	lm.use("Face", LandmarkMaterials.pbr("stone", "#B3AEA4", 3.0))
	lm.use("Platform", LandmarkMaterials.pbr("concrete", "#9C978F", 3.0))
	var rows: Array = []
	for ring in RUSH_RINGS:
		var y: float = ring[0]
		var row := PackedVector3Array()
		for k in RUSH_SEG + 1:
			row.append(_rush_point(y, TAU * float(k) / float(RUSH_SEG)))
		rows.append(row)
	# Pine forest on the lower slopes (rings up to y = 59), bare granite above.
	lm.grid("Forest", rows.slice(0, 6), Vector3(0, 70, -10), true)
	lm.grid("Rock", rows.slice(5), Vector3(0, 70, -10), true)
	var top: PackedVector3Array = rows[rows.size() - 1]
	var poly := PackedVector2Array()
	for k in RUSH_SEG:
		poly.append(Vector2(top[k].x, top[k].z))
	var idx := Geometry2D.triangulate_polygon(poly)
	for t in range(0, idx.size(), 3):
		var p0 := poly[idx[t]]
		var p1 := poly[idx[t + 1]]
		var p2 := poly[idx[t + 2]]
		lm.tri("Rock", Vector3(p0.x, RUSHMORE_TOP_M, p0.y), Vector3(p1.x, RUSHMORE_TOP_M, p1.y),
			Vector3(p2.x, RUSHMORE_TOP_M, p2.y), Vector3.UP, Vector3.UP, Vector3.UP, p0, p1, p2)
	for h in HEADS:
		_head(lm, "Face", float(h[0]), float(h[1]), float(h[2]), int(h[3]))
	lm.box("Platform", Vector3(0, -0.1, 63.0), Vector3(60.0, 1.0, 14.0))
	lm.box("Platform", Vector3(0, 0.9, 69.7), Vector3(60.0, 1.2, 0.5))
	lm.commit(model)

## Section half width, front and back depth at height y.
static func _section(y: float) -> Vector3:
	for j in RUSH_RINGS.size() - 1:
		var a: Array = RUSH_RINGS[j]
		var b: Array = RUSH_RINGS[j + 1]
		if y <= float(b[0]):
			var t := clampf((y - float(a[0])) / (float(b[0]) - float(a[0])), 0.0, 1.0)
			return Vector3(lerpf(float(a[1]), float(b[1]), t), lerpf(float(a[2]), float(b[2]), t),
				lerpf(float(a[3]), float(b[3]), t))
	var last: Array = RUSH_RINGS[RUSH_RINGS.size() - 1]
	return Vector3(float(last[1]), float(last[2]), float(last[3]))

## Point of the section at height y and angle a (0 = east, PI/2 = front).
## A superellipse (exponent 4) with a rough shoulder that fades out over
## the carved face so the heads sit on a flat wall.
static func _rush_point(y: float, a: float) -> Vector3:
	var sec := _section(y)
	var c := cos(a)
	var s := sin(a)
	var depth := sec.y if s > 0.0 else sec.z
	var x := sec.x * signf(c) * sqrt(absf(c))
	var z := depth * signf(s) * sqrt(absf(s))
	var amp := 1.0 - smoothstep(0.35, 0.75, s) * smoothstep(70.0, 86.0, y) \
		* (1.0 - smoothstep(0.55, 0.8, absf(c)))
	var n := 0.04 * sin(3.0 * a + 0.05 * y) + 0.025 * sin(7.0 * a - 0.09 * y) \
		+ 0.015 * sin(11.0 * a + 0.17 * y)
	return Vector3(x * (1.0 + n * amp), y, z * (1.0 + n * amp))

## Height of the cliff face at (x, y), just proud of the mountain mesh.
static func _face_z(x: float, y: float) -> float:
	var sec := _section(y)
	return sec.y * pow(maxf(1.0 - pow(absf(x) / sec.x, 4.0), 0.0), 0.25) + 0.12

## One carved head: a relief grid over the cliff, cells with no relief
## skipped, normals from the depth gradient.
static func _head(lm: LandmarkMesh, key: String, cx: float, y0: float, dz: float, kind: int) -> void:
	var nu := 26
	var nv := 38
	var half_w := 5.8
	var y_lo := y0 - 0.6
	var y_hi := y0 + HEAD_H + 0.8
	var pts: Array = []
	var nrm: Array = []
	var dep: Array = []
	var e := 0.02
	for j in nv + 1:
		var prow := PackedVector3Array()
		var nrow := PackedVector3Array()
		var drow := PackedFloat32Array()
		var y := lerpf(y_lo, y_hi, float(j) / float(nv))
		for i in nu + 1:
			var x := cx - half_w + 2.0 * half_w * float(i) / float(nu)
			var u := (x - cx) / half_w
			var v := (y - y0) / HEAD_H
			var d := _face_depth(u, v, kind)
			var du := (_face_depth(u + e, v, kind) - _face_depth(u - e, v, kind)) / (2.0 * e * half_w)
			var dv := (_face_depth(u, v + e, kind) - _face_depth(u, v - e, kind)) / (2.0 * e * HEAD_H)
			prow.append(Vector3(x, y, _face_z(x, y) + dz + d))
			nrow.append(Vector3(-du, -dv, 1.0).normalized())
			drow.append(d)
		pts.append(prow)
		nrm.append(nrow)
		dep.append(drow)
	for j in nv:
		for i in nu:
			var d00: float = (dep[j] as PackedFloat32Array)[i]
			var d10: float = (dep[j] as PackedFloat32Array)[i + 1]
			var d01: float = (dep[j + 1] as PackedFloat32Array)[i]
			var d11: float = (dep[j + 1] as PackedFloat32Array)[i + 1]
			if maxf(maxf(d00, d10), maxf(d01, d11)) < 0.05:
				continue
			var p00: Vector3 = (pts[j] as PackedVector3Array)[i]
			var p10: Vector3 = (pts[j] as PackedVector3Array)[i + 1]
			var p01: Vector3 = (pts[j + 1] as PackedVector3Array)[i]
			var p11: Vector3 = (pts[j + 1] as PackedVector3Array)[i + 1]
			var n00: Vector3 = (nrm[j] as PackedVector3Array)[i]
			var n10: Vector3 = (nrm[j] as PackedVector3Array)[i + 1]
			var n01: Vector3 = (nrm[j + 1] as PackedVector3Array)[i]
			var n11: Vector3 = (nrm[j + 1] as PackedVector3Array)[i + 1]
			lm.tri(key, p00, p10, p11, n00, n10, n11, Vector2(p00.x, p00.y), Vector2(p10.x, p10.y),
				Vector2(p11.x, p11.y))
			lm.tri(key, p00, p11, p01, n00, n11, n01, Vector2(p00.x, p00.y), Vector2(p11.x, p11.y),
				Vector2(p01.x, p01.y))

## Relief depth (m) of a head at x in -1..1 across the face and v in
## 0..1 from chin to crown: an ellipsoid skull with brow, eye sockets,
## nose, cheeks, mouth and chin, then the hair, beard, moustache or
## spectacles of each president.
static func _face_depth(x: float, v: float, kind: int) -> float:
	var y := (v - 0.5) * 2.0
	var body := 1.0 - x * x - y * y
	if body <= 0.0:
		return 0.0
	var f := 2.4 * exp(-pow(x / 0.12, 2.0) - pow(y / 0.30, 2.0))
	f += 0.9 * exp(-pow((y - 0.28) / 0.08, 2.0)) * exp(-pow(x / 0.7, 2.0))
	f -= 1.0 * exp(-pow((absf(x) - 0.36) / 0.14, 2.0) - pow((y - 0.18) / 0.09, 2.0))
	f += 0.8 * exp(-pow((absf(x) - 0.5) / 0.2, 2.0) - pow((y + 0.30) / 0.2, 2.0))
	f -= 0.7 * exp(-pow((y + 0.42) / 0.035, 2.0) - pow(x / 0.35, 2.0))
	f += 0.5 * exp(-pow((y + 0.5) / 0.06, 2.0) - pow(x / 0.3, 2.0))
	f += 0.9 * exp(-pow((y + 0.78) / 0.12, 2.0) - pow(x / 0.3, 2.0))
	match kind:
		0:
			f += 1.0 * smoothstep(0.55, 0.85, y)
			f += 0.8 * exp(-pow((absf(x) - 0.75) / 0.12, 2.0) - pow((y - 0.2) / 0.35, 2.0))
		1:
			f += 0.8 * smoothstep(0.6, 0.9, y)
			f += 0.4 * exp(-pow(x / 0.12, 2.0) - pow((y + 0.1) / 0.3, 2.0))
		2:
			f += 0.6 * smoothstep(0.6, 0.9, y)
			f += 1.5 * exp(-pow(x / 0.5, 2.0) - pow((y + 0.66) / 0.26, 2.0))
			f += 0.3 * exp(-pow((y - 0.28) / 0.08, 2.0))
		_:
			f += 0.6 * smoothstep(0.6, 0.9, y)
			f += 0.8 * exp(-pow((y + 0.3) / 0.07, 2.0) - pow(x / 0.4, 2.0))
			f += 0.6 * exp(-pow((sqrt(pow(absf(x) - 0.38, 2.0) + pow(y - 0.17, 2.0)) - 0.13) / 0.04, 2.0))
	return maxf(6.2 * sqrt(body) + f * smoothstep(0.0, 0.12, body), 0.0)

## Monks Mound: the largest earthwork of the Americas, 30 m high over a
## 286 x 237 m base, four rounded terraces stepping up toward the north
## (the 10 m south terrace, the 20 m main body, the 26 m and 30 m
## summit terraces) under turf, with the modern stair on the south
## face. The south ramp faces +Z; yaw turns the axis onto Cahokia's grid.
static func monks_mound(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Turf", LandmarkMaterials.pbr("lawn", "#869A57", 5.0))
	lm.use("Stair", LandmarkMaterials.pbr("wood", "#8A6E4C", 2.0))
	_mound_tier(lm, "Turf", 0.0, -57.75, -2.0, 22.0, 118.0, 87.75, 88.0, 57.75)
	_mound_tier(lm, "Turf", 0.0, 57.75, -2.0, 12.0, 105.0, 87.75, 90.0, 72.75)
	_mound_tier(lm, "Turf", 0.0, -65.0, 20.0, 6.0, 80.0, 50.0, 71.0, 41.0)
	_mound_tier(lm, "Turf", 0.0, -70.0, 26.0, 4.0, 60.0, 30.0, 54.0, 24.0)
	LandmarkAmhParts.stair(lm, "Stair", Vector3.ZERO, Basis(), 4.5, 15.4, 10.0, 0.4, 20.0, -4.0, 50)
	LandmarkAmhParts.stair(lm, "Stair", Vector3.ZERO, Basis(), 4.5, -14.6, 20.0, -23.6, 26.0, -28.0, 30)
	LandmarkAmhParts.stair(lm, "Stair", Vector3.ZERO, Basis(), 4.5, -39.6, 26.0, -45.6, 30.0, -50.0, 20)
	lm.commit(model)

## Rounded-rectangle tier (superellipse, exponent 5) from half extents
## (hx0, hz0) at y0 to (hx1, hz1) at y0 + h, centred at (cx, cz), with
## its flat top closed.
static func _mound_tier(lm: LandmarkMesh, key: String, cx: float, cz: float, y0: float, h: float,
		hx0: float, hz0: float, hx1: float, hz1: float) -> void:
	var seg := 64
	var base := PackedVector3Array()
	var top := PackedVector3Array()
	var poly := PackedVector2Array()
	for k in seg + 1:
		var a := TAU * float(k) / float(seg)
		var ux := signf(cos(a)) * pow(absf(cos(a)), 0.4)
		var uz := signf(sin(a)) * pow(absf(sin(a)), 0.4)
		base.append(Vector3(cx + hx0 * ux, y0, cz + hz0 * uz))
		top.append(Vector3(cx + hx1 * ux, y0 + h, cz + hz1 * uz))
		if k < seg:
			poly.append(Vector2(cx + hx1 * ux, cz + hz1 * uz))
	lm.grid(key, [base, top], Vector3(cx, y0 + h * 0.5, cz), true)
	var idx := Geometry2D.triangulate_polygon(poly)
	for t in range(0, idx.size(), 3):
		var p0 := poly[idx[t]]
		var p1 := poly[idx[t + 1]]
		var p2 := poly[idx[t + 2]]
		lm.tri(key, Vector3(p0.x, y0 + h, p0.y), Vector3(p1.x, y0 + h, p1.y),
			Vector3(p2.x, y0 + h, p2.y), Vector3.UP, Vector3.UP, Vector3.UP, p0, p1, p2)
