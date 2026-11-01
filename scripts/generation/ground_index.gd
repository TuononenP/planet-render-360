class_name GroundIndex
extends RefCounted

## Eager spatial grids built from GroundTruth's OSM data so that
## water_at / land_class_at / is_built_at queries avoid scanning every
## polygon or building. Built once in GroundTruth.set_land / _init and
## thereafter read-only and thread-safe (no writes, no statics).

const GRID_M := 64.0
const GRID_CELLS_MAX := 4096

var _land_cells: Dictionary = {}
var _land_grid_origin := Vector2.ZERO
var _land_grid_step := Vector2.ONE
var _land_grid_w := 0
var _land_grid_h := 0
var _land_count := 0
var _land_outside: Array[int] = []

var _built_cells: Dictionary = {}
var _built_grid_origin := Vector2.ZERO
var _built_grid_step := Vector2.ONE
var _built_grid_w := 0
var _built_grid_h := 0


func _init(ground) -> void:
	if ground == null:
		return
	_build_land(ground)
	_build_built(ground)

func _build_land(ground) -> void:
	var polys: Array = ground._land
	if polys.is_empty():
		return
	_land_count = polys.size()
	# Bounds from all polygon outer rings.
	var mn := Vector2(INF, INF)
	var mx := Vector2(-INF, -INF)
	for poly in polys:
		var pts: PackedVector2Array = (poly as Dictionary).get("points", PackedVector2Array())
		for p in pts:
			mn.x = minf(mn.x, p.x)
			mn.y = minf(mn.y, p.y)
			mx.x = maxf(mx.x, p.x)
			mx.y = maxf(mx.y, p.y)
	if mn.x == INF:
		return
	var span := mx - mn
	if span.x <= 0.0 or span.y <= 0.0:
		return
	_land_grid_w = clampi(int(ceil(span.x / GRID_M)), 1, 256)
	_land_grid_h = clampi(int(ceil(span.y / GRID_M)), 1, 256)
	# Clamp to max cells.
	while _land_grid_w * _land_grid_h > GRID_CELLS_MAX:
		_land_grid_w = maxi(_land_grid_w / 2, 1)
		_land_grid_h = maxi(_land_grid_h / 2, 1)
	_land_grid_origin = mn
	_land_grid_step = Vector2(span.x / float(_land_grid_w), span.y / float(_land_grid_h))
	# For each polygon, mark cells its bbox overlaps.
	for idx in polys.size():
		var poly: Dictionary = polys[idx]
		var pts: PackedVector2Array = poly.get("points", PackedVector2Array())
		if pts.is_empty():
			continue
		var bmin := pts[0]
		var bmax := pts[0]
		for p in pts:
			bmin.x = minf(bmin.x, p.x)
			bmin.y = minf(bmin.y, p.y)
			bmax.x = maxf(bmax.x, p.x)
			bmax.y = maxf(bmax.y, p.y)
		var c0 := _cell_of_land(bmin)
		var c1 := _cell_of_land(bmax)
		for cy in range(c0.y, c1.y + 1):
			for cx in range(c0.x, c1.x + 1):
				var key := cy * _land_grid_w + cx
				if not _land_cells.has(key):
					_land_cells[key] = PackedInt32Array()
				var arr: PackedInt32Array = _land_cells[key]
				arr.append(idx)
				_land_cells[key] = arr
		# Also track polygons whose bbox never hits any cell (degenerate).
	# Polygons that extend outside the grid bounds are tested via fallback.
	for idx in polys.size():
		var poly: Dictionary = polys[idx]
		var pts2: PackedVector2Array = poly.get("points", PackedVector2Array())
		if pts2.is_empty():
			continue
		var bmin2 := pts2[0]
		var bmax2 := pts2[0]
		for p in pts2:
			bmin2.x = minf(bmin2.x, p.x)
			bmin2.y = minf(bmin2.y, p.y)
			bmax2.x = maxf(bmax2.x, p.x)
			bmax2.y = maxf(bmax2.y, p.y)
		# If polygon bbox is outside the grid entirely, add to outside list.
		if bmax2.x < _land_grid_origin.x or bmin2.x > _land_grid_origin.x + span.x \
				or bmax2.y < _land_grid_origin.y or bmin2.y > _land_grid_origin.y + span.y:
			_land_outside.append(idx)

func _cell_of_land(p: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(floor((p.x - _land_grid_origin.x) / _land_grid_step.x)), 0, _land_grid_w - 1),
		clampi(int(floor((p.y - _land_grid_origin.y) / _land_grid_step.y)), 0, _land_grid_h - 1))

func _build_built(ground) -> void:
	var buildings: Array = ground._buildings
	if buildings.is_empty():
		return
	var mn := Vector2(INF, INF)
	var mx := Vector2(-INF, -INF)
	for b in buildings:
		if not (b is Dictionary):
			continue
		var x := float((b as Dictionary).get("x", 0.0))
		var z := float((b as Dictionary).get("z", 0.0))
		mn.x = minf(mn.x, x)
		mn.y = minf(mn.y, z)
		mx.x = maxf(mx.x, x)
		mx.y = maxf(mx.y, z)
	if mn.x == INF:
		return
	var span := mx - mn
	# Pad by reach so edge buildings are captured.
	span += Vector2(4.0, 4.0)
	mn -= Vector2(2.0, 2.0)
	_built_grid_w = clampi(int(ceil(span.x / GRID_M)), 1, 256)
	_built_grid_h = clampi(int(ceil(span.y / GRID_M)), 1, 256)
	while _built_grid_w * _built_grid_h > GRID_CELLS_MAX:
		_built_grid_w = maxi(_built_grid_w / 2, 1)
		_built_grid_h = maxi(_built_grid_h / 2, 1)
	_built_grid_origin = mn
	_built_grid_step = Vector2(span.x / float(_built_grid_w), span.y / float(_built_grid_h))
	for b in buildings:
		if not (b is Dictionary):
			continue
		var x2 := float((b as Dictionary).get("x", 0.0))
		var z2 := float((b as Dictionary).get("z", 0.0))
		var reach := maxf(float((b as Dictionary).get("size_x", 0.0)),
			float((b as Dictionary).get("size_z", 0.0))) * 0.5 + 1.6
		var bmin := Vector2(x2 - reach, z2 - reach)
		var bmax := Vector2(x2 + reach, z2 + reach)
		var c0 := _cell_of_built(bmin)
		var c1 := _cell_of_built(bmax)
		for cy in range(c0.y, c1.y + 1):
			for cx in range(c0.x, c1.x + 1):
				var key := cy * _built_grid_w + cx
				if not _built_cells.has(key):
					_built_cells[key] = []
				(_built_cells[key] as Array).append(b)

func _cell_of_built(p: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(floor((p.x - _built_grid_origin.x) / _built_grid_step.x)), 0, _built_grid_w - 1),
		clampi(int(floor((p.y - _built_grid_origin.y) / _built_grid_step.y)), 0, _built_grid_h - 1))

func land_candidates_at(x: float, z: float) -> PackedInt32Array:
	if _land_grid_w == 0:
		# No grid — return all indices in order.
		var all := PackedInt32Array()
		for i in _land_count:
			all.append(i)
		return all
	# Check if outside grid bounds — fallback to full scan.
	if x < _land_grid_origin.x or x > _land_grid_origin.x + float(_land_grid_w) * _land_grid_step.x \
			or z < _land_grid_origin.y or z > _land_grid_origin.y + float(_land_grid_h) * _land_grid_step.y:
		var all2 := PackedInt32Array()
		for i in _land_count:
			all2.append(i)
		return all2
	var c := _cell_of_land(Vector2(x, z))
	var key := c.y * _land_grid_w + c.x
	if _land_cells.has(key):
		return _land_cells[key] as PackedInt32Array
	return PackedInt32Array()

## Candidates for is_built_at at world XZ.
func built_candidates_at(x: float, z: float) -> Array:
	if _built_grid_w == 0:
		return []
	if x < _built_grid_origin.x or x > _built_grid_origin.x + float(_built_grid_w) * _built_grid_step.x \
			or z < _built_grid_origin.y or z > _built_grid_origin.y + float(_built_grid_h) * _built_grid_step.y:
		return []
	var c := _cell_of_built(Vector2(x, z))
	var key := c.y * _built_grid_w + c.x
	if _built_cells.has(key):
		return _built_cells[key] as Array
	return []

## Whether the cell containing XZ is guaranteed dry (water_at will be 0.0).
func is_empty() -> bool:
	return _land_cells.is_empty() and _built_cells.is_empty()
