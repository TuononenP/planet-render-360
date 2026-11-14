extends SceneTree

## Headless: godot --headless --script tests/gable_ring_test.gd
## Many-cornered gabled houses roof a simplified ring with true gables: jogs
## and collinear splits drop out, the roof still covers every wall corner,
## and a real L or T shape keeps its corners (and the old roof).

var failures: Array[String] = []

func _m() -> float:
	return WorldScale.metres_to_units()

func _scaled(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append((p as Vector2) * _m())
	return out

func _init() -> void:
	# A 6 x 14 m house: bay nodes bulging 0.3 m at both ends, split long walls.
	var jog := _scaled([Vector2(0, 0), Vector2(3, -0.3), Vector2(6, 0), Vector2(6, 4), Vector2(6, 8),
		Vector2(6, 14), Vector2(3, 14.3), Vector2(0, 14), Vector2(0, 9), Vector2(0, 4)])
	var g := RoofForms.gable_ring(jog)
	if g.size() != 4:
		failures.append("the jogged house should simplify to 4 corners, got %d" % g.size())
	for p in jog:
		if not Geometry2D.is_point_in_polygon(p, g):
			failures.append("the roof ring must cover wall corner %s" % (p / _m()))
			break
	if not g.is_empty() and absf(RingGeometry.signed_area(g)) > absf(RingGeometry.signed_area(jog)) * 1.15:
		failures.append("the eave growth should stay small")
	# A real gable: the roof over the simplified ring has steep end faces.
	if g.size() == 4:
		var mesh := RoofGeometry.form_mesh(g, 10.0 * _m(), 3.5 * _m(), "gabled")
		var peak := 10.0 * _m()
		var steep := 0
		if mesh != null:
			var arr := MeshArrays.surface(mesh, 0)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			for y in v:
				peak = maxf(peak, y.y)
			for k in range(0, v.size(), 3):
				var n := (v[k + 1] - v[k]).cross(v[k + 2] - v[k]).normalized()
				if absf(n.y) < 0.2:
					steep += 1
		if peak < 13.2 * _m():
			failures.append("the gabled roof should rise ~3.5 m, got %.2f" % ((peak - 10.0 * _m()) / _m()))
		if steep == 0:
			failures.append("a gabled roof needs its vertical gable ends")
	# An L-shaped house: no corner is near-collinear, so nothing changes.
	var ell := _scaled([Vector2(0, 0), Vector2(10, 0), Vector2(10, 4), Vector2(4, 4), Vector2(4, 9),
		Vector2(2, 9), Vector2(2, 11), Vector2(0, 11), Vector2(-1, 6)])
	if not RoofForms.gable_ring(ell).is_empty():
		failures.append("an irregular 9-corner plan keeps its own roof")
	if failures.is_empty():
		print("GABLE RING OK: jogs drop out, walls covered, true gables, real shapes kept")
		quit(0)
	else:
		for f in failures:
			printerr("GABLE RING FAIL: ", f)
		quit(1)
