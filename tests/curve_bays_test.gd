extends SceneTree

## Headless: godot --headless --script tests/curve_bays_test.gd
## Curved walls (many short OSM edges) carry window bays across their edges
## instead of restarting them on each: whole bays over the run, continuous U,
## straight walls and party walls untouched, no relief on curved edges.

const BAY := 3.0
var failures: Array[String] = []

func _init() -> void:
	_round_tower()
	_rounded_end()
	_rectangle_and_party()
	_built_uvs()
	if failures.is_empty():
		print("CURVE BAYS OK: whole bays along curves, continuous U, straight and party walls untouched")
		quit(0)
	else:
		for f in failures:
			printerr("CURVE BAYS FAIL: ", f)
		quit(1)

func _m() -> float:
	return WorldScale.metres_to_units()

func _circle(c: Vector2, r_m: float, n: int, a0: float = 0.0, a1: float = TAU) -> PackedVector2Array:
	var out := PackedVector2Array()
	var full := is_equal_approx(a1 - a0, TAU)
	var k := n if full else n + 1
	for i in k:
		var t := a0 + (a1 - a0) * float(i) / float(n)
		out.append(c + Vector2(cos(t), sin(t)) * r_m * _m())
	return out

func _continuous(curve: Dictionary, ring: PackedVector2Array, edges: Array) -> bool:
	for k in edges.size() - 1:
		if not is_equal_approx((curve[edges[k]] as Vector2).y, (curve[edges[k + 1]] as Vector2).x):
			return false
	return true

func _round_tower() -> void:
	var ring := _circle(Vector2.ZERO, 10.0, 24)
	var curve := BuildingWalls.curve_bays(ring, [], BAY)
	if curve.size() != 24:
		failures.append("a round tower is one curve all round, got %d edges" % curve.size())
		return
	var total := 0.0
	for i in 24:
		total += ring[i].distance_to(ring[(i + 1) % 24]) / _m()
	var bays := roundf(total / BAY)
	var order: Array = []
	var i0 := 0
	for i in 24:
		if is_zero_approx((curve[i] as Vector2).x):
			i0 = i
	for k in 24:
		order.append((i0 + k) % 24)
	if not _continuous(curve, ring, order):
		failures.append("U must run on from edge to edge")
	if not is_equal_approx((curve[order[-1]] as Vector2).y, bays):
		failures.append("the run should hold whole bays: %s, want %s" % [(curve[order[-1]] as Vector2).y, bays])

func _rounded_end() -> void:
	# A 30 m block with a half-round end of 8 short edges.
	var ring := PackedVector2Array([Vector2(-30.0, -6.0) * _m()])
	ring.append_array(_circle(Vector2.ZERO, 6.0, 8, -PI / 2.0, PI / 2.0))
	ring.append(Vector2(-30.0, 6.0) * _m())
	var curve := BuildingWalls.curve_bays(ring, [], BAY)
	if curve.size() != 8:
		failures.append("only the half-round end chains: %d edges" % curve.size())
	for i in [0, ring.size() - 2, ring.size() - 1]:
		if curve.has(i):
			failures.append("straight edge %d must keep its own bays" % i)
	if curve.size() == 8 and not _continuous(curve, ring, range(1, 9)):
		failures.append("the rounded end's U must run on")

func _rectangle_and_party() -> void:
	var rect := PackedVector2Array([Vector2(0, 0), Vector2(20, 0), Vector2(20, 10), Vector2(0, 10)])
	for i in rect.size():
		rect[i] *= _m()
	if not BuildingWalls.curve_bays(rect, [], BAY).is_empty():
		failures.append("a rectangle has no curve")
	# A neighbour against two edges in the middle splits the tower's curve.
	var ring := _circle(Vector2.ZERO, 10.0, 24)
	var cover: Array = []
	for i in 24:
		cover.append([[0.0, 1.0, 5.0 * _m()] if i in [6, 7] else [0.0, 1.0, PartyWalls.OPEN]])
	var curve := BuildingWalls.curve_bays(ring, cover, BAY)
	if curve.has(6) or curve.has(7) or curve.size() != 22:
		failures.append("party edges stay out of the curve: %d edges" % curve.size())
	if not BuildingWalls.curve_bays(ring, [], BAY, {3: true}).has(2) \
			or BuildingWalls.curve_bays(ring, [], BAY, {3: true}).has(3):
		failures.append("an edge of another material breaks the run")

func _built_uvs() -> void:
	var mat := StandardMaterial3D.new()
	mat.set_meta("fc_uv", Vector3(BAY, 4.0, 3.2))
	var root := Node3D.new()
	var ring := _circle(Vector2.ZERO, 10.0, 24)
	BuildingWalls._walls(root, ring, 0.0, 10.0 * _m(), mat, 3.0)
	var mi := root.get_child(0) as MeshInstance3D
	var arrays := MeshArrays.surface(mi.mesh, 0)
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var starts := {}
	for q in uvs.size() / 4:
		starts[snappedf(uvs[q * 4].x, 0.001)] = true
	# Restarting bays put every quad's U at 0; a run starts there once.
	if starts.size() < 20:
		failures.append("wall quads should start along the run, %d distinct starts" % starts.size())
	root.free()
