class_name LandmarkTsShibuyaCrossing
extends RefCounted

## The two fronts that frame Shibuya Crossing, in true metres on
## LandmarkMesh, built north-up (no yaw) about the area centroid of their
## OSM footprints. Signs and screens are generic emissive panels: no logo
## or brand text.

## Shibuya 109 (1979, Minoru Takeyama): the silver department store on the
## wedge between Dogenzaka and Bunkamura-dori. The OSM outline (way
## 55895868, simplified) rises in banded aluminium to 30 m; the round
## corner tower at its east tip, facing the crossing, carries the tall
## vertical sign column and tops out at the OSM 33.6 m.
static func shibuya_109(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Metal", LandmarkMaterials.paint("#C3C7CA", 0.35, 0.7))
	lm.use("Glass", LandmarkMaterials.glass("#2C3640"))
	lm.use("Stone", LandmarkMaterials.pbr("concrete", "#8F8D88", 3.0))
	lm.use("Sign", LandmarkMaterials.lit("#F1EDE4", 0.6))
	lm.use("SignDark", LandmarkMaterials.paint("#26282B", 0.5, 0.3))
	lm.use("Accent", LandmarkMaterials.lit("#E9506E", 0.6))
	var plan := PackedVector2Array([Vector2(-16.8, -26.6), Vector2(-18.9, -25.5), Vector2(-22.7, -17.4),
		Vector2(-24.7, -18.3), Vector2(-27.7, -11.9), Vector2(-24.3, -10.2), Vector2(-26.9, -5.2),
		Vector2(-17.3, 10.1), Vector2(-14.2, 16.5), Vector2(-11.5, 24.2), Vector2(29.0, 10.6),
		Vector2(25.7, -6.9), Vector2(17.8, -1.2), Vector2(6.8, -14.2), Vector2(7.2, -15.3)])
	# Ground-floor shopfronts, then silver walls banded by window strips.
	lm.poly_prism("Glass", plan, 0.0, 4.5)
	lm.poly_prism("Metal", plan, 4.5, 30.0)
	for i in plan.size():
		var a := plan[i]
		var b := plan[(i + 1) % plan.size()]
		if a.distance_to(b) < 2.0:
			continue
		var d := Vector3(b.x - a.x, 0, b.y - a.y).normalized()
		var basis := Basis(d, Vector3.UP, d.cross(Vector3.UP).normalized())
		for k in 7:
			lm.box("Glass", Vector3((a.x + b.x) * 0.5, 6.2 + 3.4 * k, (a.y + b.y) * 0.5),
				Vector3(a.distance_to(b) - 0.6, 1.1, 0.3), basis, 0.0)
	lm.poly_prism("Metal", _grow(plan, 0.3), 29.4, 30.4)
	# The round corner tower at the fork, its crown ring and cap.
	var c := Vector3(29.0, 0, 4.3)
	lm.lathe("Glass", c, PackedVector2Array([Vector2(6.4, 0.0), Vector2(6.4, 4.5)]), 32, 1.0, 1.0, 0.0, true, false)
	lm.lathe("Metal", c + Vector3(0, 4.5, 0), PackedVector2Array([Vector2(6.4, 0.0), Vector2(6.4, 27.4),
		Vector2(6.7, 27.6), Vector2(6.7, 28.4), Vector2(6.0, 28.6), Vector2(6.0, 29.1)]), 32)
	for k in 8:
		lm.lathe("Glass", c + Vector3(0, 6.0 + 3.4 * k, 0), PackedVector2Array([Vector2(6.45, 0.0), Vector2(6.45, 1.1)]),
			32, 1.0, 1.0, 0.0, true, false)
	# Sign column on the crossing (east) face: lit panels in a dark frame,
	# and a lit accent ring under the crown.
	var face := c + Vector3(6.9, 0, 0)
	lm.box("SignDark", face + Vector3(0, 21.0, 0), Vector3(0.8, 24.0, 3.2))
	for k in 6:
		lm.box("Sign", face + Vector3(0.42, 10.6 + 3.8 * k, 0), Vector3(0.1, 3.3, 2.6), Basis(), 0.0)
	lm.box("Accent", face + Vector3(0.42, 32.2, 0), Vector3(0.1, 1.2, 2.6), Basis(), 0.0)
	lm.lathe("Accent", c + Vector3(0, 30.4, 0), PackedVector2Array([Vector2(6.75, 0.0), Vector2(6.75, 0.8)]),
		32, 1.0, 1.0, 0.0, true, false)
	lm.commit(model)

## QFRONT (1999): the glass front on the crossing's north side. The OSM
## outline (way 136691386) in grey glass with floor bands to 45.9 m, and
## the full-height LED screen across its curved south-east corner, facing
## the scramble.
static func qfront(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkTsShibuyaTowers.glass("#8A93A3"))
	lm.use("Frame", LandmarkMaterials.paint("#9BA1B1", 0.45, 0.5))
	# The street screens' poster atlas, lit like an LED wall day and night.
	lm.use("Screen", ReliefKit.screen())
	lm.use("ScreenFrame", LandmarkMaterials.paint("#1D1F22", 0.5, 0.4))
	lm.use("Stone", LandmarkMaterials.pbr("concrete", "#8D8B86", 3.0))
	var plan := PackedVector2Array([Vector2(-12.4, -14.1), Vector2(17.5, -5.6), Vector2(13.4, 10.9),
		Vector2(7.8, 12.3), Vector2(1.6, 13.2), Vector2(-4.3, 12.5), Vector2(-17.8, -0.8)])
	lm.poly_prism("Stone", plan, 0.0, 0.6)
	LandmarkTsShibuyaTowers.curtain(lm, "Glass", "Frame", plan, 0.6, 44.9, 5.4, 2.4)
	lm.poly_prism("Frame", _grow(plan, 0.2), 44.9, 45.9)
	# The screen: a curved band of panels on the crossing face, 9 to 39 m.
	var arc := [Vector2(15.9, 0.8), Vector2(13.4, 10.9), Vector2(7.8, 12.3), Vector2(1.6, 13.2)]
	# One poster tile spans the whole band (u along the arc, v top to bottom).
	var arc_len := 0.0
	for i in arc.size() - 1:
		arc_len += (arc[i] as Vector2).distance_to(arc[i + 1])
	var tile := 3
	var u0 := float(tile % 2) * 0.5
	var v_top := float(tile / 2) * 0.25
	var run := 0.0
	for i in arc.size() - 1:
		var a: Vector2 = arc[i]
		var b: Vector2 = arc[i + 1]
		var n := _out(a, b)
		var a3 := Vector3(a.x, 0, a.y) + n * 0.45
		var b3 := Vector3(b.x, 0, b.y) + n * 0.45
		var ua := u0 + 0.5 * run / arc_len
		run += a.distance_to(b)
		var ub := u0 + 0.5 * run / arc_len
		var lo := v_top + 0.25
		lm.tri("Screen", a3 + Vector3(0, 9.0, 0), b3 + Vector3(0, 9.0, 0), b3 + Vector3(0, 39.0, 0), n, n, n,
			Vector2(ua, lo), Vector2(ub, lo), Vector2(ub, v_top))
		lm.tri("Screen", a3 + Vector3(0, 9.0, 0), b3 + Vector3(0, 39.0, 0), a3 + Vector3(0, 39.0, 0), n, n, n,
			Vector2(ua, lo), Vector2(ub, v_top), Vector2(ua, v_top))
		var d := (b3 - a3).normalized()
		var basis := Basis(d, Vector3.UP, d.cross(Vector3.UP).normalized())
		var mid := (a3 + b3) * 0.5 - n * 0.2
		lm.box("ScreenFrame", mid + Vector3(0, 8.6, 0), Vector3(a.distance_to(b) + 0.4, 0.8, 0.5), basis, 0.0)
		lm.box("ScreenFrame", mid + Vector3(0, 39.4, 0), Vector3(a.distance_to(b) + 0.4, 0.8, 0.5), basis, 0.0)
		lm.box("ScreenFrame", a3 - n * 0.2 + Vector3(0, 24.0, 0), Vector3(0.5, 31.6, 0.5), basis, 0.0)
	var last: Vector2 = arc[arc.size() - 1]
	lm.box("ScreenFrame", Vector3(last.x, 24.0, last.y) + _out(arc[arc.size() - 2], last) * 0.25,
		Vector3(0.5, 31.6, 0.5))
	lm.commit(model)

## Outward horizontal normal of a counter-clockwise-or-not plan edge a -> b,
## taken as the side away from the plan's centroid (the origin).
static func _out(a: Vector2, b: Vector2) -> Vector3:
	var n := Vector2(b.y - a.y, a.x - b.x).normalized()
	if n.dot((a + b) * 0.5) < 0.0:
		n = -n
	return Vector3(n.x, 0, n.y)

## `poly` pushed out by `d` metres from the origin (a roof-edge lip).
static func _grow(poly: PackedVector2Array, d: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(p + p.normalized() * d)
	return out
