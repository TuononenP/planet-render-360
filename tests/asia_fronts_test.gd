extends SceneTree

## Headless: godot --headless --script tests/asia_fronts_test.gd
## AsiaFronts: a Seoul danji slab's block number comes from its mapped
## name ("파크팰리스 103동") else the 101–130 range; only a slab's narrow
## end walls carry it; sign bands and the sign stack build on street
## stretches and not on party or back walls.

var _fails := 0

func _init() -> void:
	_run()
	if _fails == 0:
		print("asia_fronts_test: PASS")
	quit(1 if _fails > 0 else 0)

func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails += 1
		printerr("FAIL: ", what)

func _rect(w_m: float, d_m: float) -> PackedVector2Array:
	var m := WorldScale.metres_to_units()
	return PackedVector2Array([Vector2(0, 0), Vector2(w_m * m, 0), Vector2(w_m * m, d_m * m), Vector2(0, d_m * m)])

func _rows(n: int) -> Array:
	var m := WorldScale.metres_to_units()
	var out: Array = []
	for i in n:
		var y0 := float(i) * 2.8 * m
		out.append({"y0": y0, "y1": y0 + 2.8 * m, "storey": i, "ground": i == 0,
			"win0": y0 + 0.9 * m, "win1": y0 + 2.3 * m})
	return out

func _span(a: Vector2, b: Vector2, street: bool) -> Dictionary:
	var m := WorldScale.metres_to_units()
	var dir := (b - a).normalized()
	return {"a": a, "b": b, "dir": dir, "n": Vector2(dir.y, -dir.x), "len_m": a.distance_to(b) / m,
		"street": street, "edge": 0}

func _quads(kit: ReliefKit) -> int:
	var root := Node3D.new()
	kit.flush(root, "Relief")
	var n := 0
	for c in root.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			var mesh: Mesh = (c as MeshInstance3D).mesh
			for s in mesh.get_surface_count():
				n += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	root.free()
	return n

func _run() -> void:
	_check(AsiaFronts.danji_number({"name": "파크팰리스 103동"}, 0.3) == 103, "mapped danji name gives its number")
	_check(AsiaFronts.danji_number({"name": "106동"}, 0.3) == 106, "bare dong name gives its number")
	for s in [0.01, 0.37, 0.82]:
		var k := AsiaFronts.danji_number({}, s)
		_check(k >= 101 and k <= 130, "seeded danji number in 101–130, got %d" % k)
	var slab := _rect(60.0, 13.0)
	_check(AsiaFronts.is_slab_end(slab, 13.0), "13 m end of a 60 m slab is a slab end")
	_check(not AsiaFronts.is_slab_end(slab, 60.0), "the long side is not a slab end")
	_check(not AsiaFronts.is_slab_end(_rect(20.0, 18.0), 18.0), "a squat block has no slab end")
	_check(not AsiaFronts.is_slab_end(slab, 4.0), "a short jog is not a slab end")
	var m := WorldScale.metres_to_units()
	var end_span := _span(Vector2(60.0 * m, 0), Vector2(60.0 * m, 13.0 * m), false)
	var long_span := _span(Vector2(0, 0), Vector2(60.0 * m, 0), false)
	var look := {"relief": {"danji_number": 1.0}}
	var d := {"look": look, "seed": 0.42, "ring": slab, "b": {"name": "101동"}}
	var kit := ReliefKit.new()
	AsiaFronts.add(kit, [end_span], _rows(20), d)
	_check(_quads(kit) > 0, "a 20-storey slab end carries its number")
	kit = ReliefKit.new()
	AsiaFronts.add(kit, [long_span], _rows(20), d)
	_check(_quads(kit) == 0, "the long side carries no number")
	kit = ReliefKit.new()
	AsiaFronts.add(kit, [end_span], _rows(6), d)
	_check(_quads(kit) == 0, "a 6-storey block carries no danji number")
	var street := _span(Vector2(0, 0), Vector2(12.0 * m, 0), true)
	var back := _span(Vector2(0, 0), Vector2(12.0 * m, 0), false)
	var shops := {"look": {"relief": {"sign_bands": 1.0, "sign_stack": 1.0}}, "seed": 0.2,
		"ring": _rect(12.0, 15.0), "b": {}}
	kit = ReliefKit.new()
	AsiaFronts.add(kit, [street], _rows(7), shops)
	_check(_quads(kit) > 0, "a street front gets sign boards and a sign column")
	kit = ReliefKit.new()
	AsiaFronts.add(kit, [back], _rows(7), shops)
	_check(_quads(kit) == 0, "a back wall gets no signs")
	kit = ReliefKit.new()
	AsiaFronts.add(kit, [street], _rows(7), {"look": {"relief": {}}, "seed": 0.2, "ring": _rect(12.0, 15.0)})
	_check(_quads(kit) == 0, "rows without the keys build nothing")
