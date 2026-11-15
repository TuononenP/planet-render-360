extends SceneTree

## Headless: godot --headless --script tests/far_city_origin_test.gd
## Two streamed worlds a swap apart must agree on the far city: the
## SettlementMap grid's cell edges fall on the continuous map's whole
## 100 m (LocationData.origin_m), a point's cell is the same cell counted
## on that map from either world (FarCityBuilder.grid_cell0), and its lot
## hashes (FarCityBuilder._at) match. ShaderOrigin carries the origin a
## build stood on into the shaders at the swap.

var _fails := 0

func _init() -> void:
	var o1 := Vector2(1234.567, 2987.183)
	var step := Vector2(-640.37, 905.61)
	var o2 := ShaderOrigin.ahead(null, step)  # from an origin of zero
	_check(o2.is_equal_approx(ShaderOrigin.wrapped(step)), "ahead() of no world steps from zero")
	o2 = ShaderOrigin.wrapped(o1 + step)
	var m1 := _map(o1)
	var m2 := _map(o2)
	for p: Vector2 in [Vector2(10, 20), Vector2(-1500, 3300), Vector2(4200, -4100)]:
		var c1 := m1.cell_of(p.x, p.y)
		var mid := m1.centre(c1.x, c1.y) + o1
		_check(is_equal_approx(fposmod(mid.x, 100.0), 50.0) and is_equal_approx(fposmod(mid.y, 100.0), 50.0),
			"cell centres sit mid-cell on the continuous map (%s)" % mid)
		# The same ground seen from the next world, whose centre is `step` on.
		var q := p - step
		var c2 := m2.cell_of(q.x, q.y)
		if c1.x < 0 or c2.x < 0:
			continue
		_check(c1 + FarCityBuilder.grid_cell0(m1, o1) == c2 + FarCityBuilder.grid_cell0(m2, o2),
			"one ground, one cell from both worlds (%s)" % p)
		var b1 := FarCityBuilder.new()
		b1.data = LocationData.new()
		b1.data.origin_m = o1
		var b2 := FarCityBuilder.new()
		b2.data = LocationData.new()
		b2.data.origin_m = o2
		var lc1 := m1.centre(c1.x, c1.y)
		var lc2 := m2.centre(c2.x, c2.y)
		_check(absf(b1._at(lc1.x, lc1.y, 2.0) - b2._at(lc2.x, lc2.y, 2.0)) < 1e-3,
			"a lot hashes alike from both worlds (%s)" % p)
	# A built world brings its own origin into the shaders at the swap.
	var live := Node3D.new()
	live.set_meta(ShaderOrigin.META, o1)
	var next := Node3D.new()
	next.set_meta(ShaderOrigin.META, o2)
	_check(ShaderOrigin.carry(live, next, -step) == o2, "the swap shows the origin the build stood on")
	var bare := Node3D.new()
	_check(ShaderOrigin.carry(live, bare, -step).is_equal_approx(o2)
		and (bare.get_meta(ShaderOrigin.META) as Vector2).is_equal_approx(o2), "a world without one takes the carried origin")
	live.free()
	next.free()
	bare.free()
	if _fails == 0:
		print("far_city_origin_test: PASS")
	quit(1 if _fails > 0 else 0)

func _map(origin: Vector2) -> SettlementMap:
	var m := SettlementMap.new()
	m.half = int(ceil(SettlementMap.RADIUS_M / SettlementMap.CELL_M))
	m.n = m.half * 2
	m.shift = Vector2(fposmod(origin.x, SettlementMap.CELL_M), fposmod(origin.y, SettlementMap.CELL_M))
	return m

func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails += 1
		printerr("FAIL: ", what)
