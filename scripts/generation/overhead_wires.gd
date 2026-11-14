class_name OverheadWires
extends RefCounted

## Desktop Ultra contact and suspension wires, merged into four spatial
## chunks (at most twelve surfaces). Track tags select electrification;
## Finnish urban roads also carry a luminaire on a sagging span wire.
const RADIUS_M := 600.0
const SPACING_M := 30.0
const CONTACT_M := 5.7
const MAX_SPANS := 400
const MAX_DRAW_CALLS := 12
## A pole keeps this clear of any other wired track's centreline, and
## one already standing this close carries the new span too.
const TRACK_CLEAR_M := 2.6
const POLE_MERGE_M := 9.0
const _CELL_M := 20.0

static func plan(data: LocationData, ground: GroundTruth) -> Array:
	if not RenderQuality.ultra_desktop(data.quality_preset):
		return []
	var m := WorldScale.metres_to_units()
	var centre := View360.spawn_xz(data)
	var spans: Array = []
	var lines: Array = []
	for rail in data.railways:
		if str(rail.get("electrified", "")) == "contact_line" and not bool(rail.get("tunnel", false)):
			lines.append([rail, true, false])
	for road in data.roads:
		# A paved square's outline is no street to hang lamps across.
		if not (road is Dictionary) or bool(road.get("tunnel", false)) or bool(road.get("bridge", false)) \
				or bool(road.get("area", false)):
			continue
		# Pedestrian streets keep their lampposts (StreetProps) instead.
		var cls := str(road.get("class", ""))
		var hung := data.country.to_upper() in ["FI", "SE"] and cls in StreetProps.LIT and cls != "pedestrian"
		if hung or bool(road.get("trolley_wire", false)):
			lines.append([road, bool(road.get("trolley_wire", false)), hung])
	var tracks := _track_grid(lines, m)
	var centres := _centre_grid(data, 35.0 * m)
	var rings := _ring_grid(data, 12.0 * m)
	var poles := {}
	# Every candidate span first, nearest the eye first, so the cap drops
	# the far ones rather than whichever ways the data lists last.
	var candidates: Array = []
	for entry in lines:
		var way: Dictionary = entry[0]
		var pts: PackedVector2Array = way.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var sampled := RoadBuilder._resample(pts, SPACING_M * m)
		for i in sampled.size() - 1:
			var a := sampled[i]
			var b := sampled[i + 1]
			var mid := (a + b) * 0.5
			if mid.distance_to(centre) > RADIUS_M * m or a.distance_to(b) < 2.0 * m:
				continue
			if bool(entry[2]) and not _built(mid, centres, 35.0 * m):
				continue
			candidates.append([mid.distance_squared_to(centre), a, b, entry])
	candidates.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
	for c in candidates:
		var a: Vector2 = c[1]
		var b: Vector2 = c[2]
		var entry: Array = c[3]
		var way: Dictionary = entry[0]
		var n := Vector2((b - a).y, -(b - a).x).normalized()
		var half := maxf(4.0, float(way.get("width_m", 6.0)) * 0.5 + 1.0) * m
		var supports: Array = []
		for side in [-1.0, 1.0]:
			var p: Vector2 = a + n * half * float(side)
			var anchor := _anchor(p, data, rings, 12.0 * m)
			var at: Vector2 = anchor[0]
			if not anchor[1]:
				at = _pole_spot(at, a, n * float(side), half, tracks, poles, m)
			var y := ground.height_at_world(at.x, at.y)
			supports.append([Vector3(at.x, y + (CONTACT_M + 0.8) * m, at.y), bool(anchor[1]), y])
		spans.append({"a": a, "b": b, "supports": supports, "contact": bool(entry[1]),
			"lamp": bool(entry[2]), "ya": ground.height_at_world(a.x, a.y) + CONTACT_M * m,
			"yb": ground.height_at_world(b.x, b.y) + CONTACT_M * m})
		if spans.size() >= MAX_SPANS:
			break
	return spans

## Segments of the wired tracks bucketed by cell, so a pole can stay off
## a neighbouring track bed (a terminus loop holds a dozen ways).
static func _track_grid(lines: Array, m: float) -> Dictionary:
	var grid := {}
	var cell := _CELL_M * m
	for entry in lines:
		if not bool(entry[1]):
			continue
		var pts: PackedVector2Array = (entry[0] as Dictionary).get("points", PackedVector2Array())
		for i in pts.size() - 1:
			# Every cell a long straight run passes through, walked at half
			# a cell; _on_track's 3×3 search covers the clearance.
			var steps := ceili(pts[i].distance_to(pts[i + 1]) / (cell * 0.5))
			var seen := {}
			for k in steps + 1:
				var q := pts[i].lerp(pts[i + 1], float(k) / float(maxi(steps, 1)))
				var key := Vector2i(floori(q.x / cell), floori(q.y / cell))
				if seen.has(key):
					continue
				seen[key] = true
				if not grid.has(key):
					grid[key] = []
				(grid[key] as Array).append([pts[i], pts[i + 1]])
	return grid

static func _on_track(p: Vector2, grid: Dictionary, m: float) -> bool:
	var cell := _CELL_M * m
	var c := Vector2i(floori(p.x / cell), floori(p.y / cell))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for seg in grid.get(Vector2i(c.x + dx, c.y + dz), []):
				if p.distance_to(Geometry2D.get_closest_point_to_segment(p, seg[0], seg[1])) < TRACK_CLEAR_M * m:
					return true
	return false

## A free-standing pole: shared with one already near and at least this
## span's own reach (`half`) out from the line through `a` (never one in
## its carriageway), else stepped outward (`out`) to the first spot off
## every wired track's bed, then recorded in the `poles` cell buckets.
static func _pole_spot(p: Vector2, a: Vector2, out: Vector2, half: float,
		grid: Dictionary, poles: Dictionary, m: float) -> Vector2:
	var shared := _near_pole(p, a, out, half, poles, m)
	if shared.x != INF:
		return shared
	var at := p
	for step in 13:
		at = p + out * float(step) * m
		if not _on_track(at, grid, m):
			break
	shared = _near_pole(at, a, out, half, poles, m)
	if shared.x != INF:
		return shared
	var key := Vector2i(floori(at.x / (_CELL_M * m)), floori(at.y / (_CELL_M * m)))
	if not poles.has(key):
		poles[key] = []
	(poles[key] as Array).append(at)
	return at

## A recorded pole within POLE_MERGE_M of `p` standing `half` (less a
## metre) or more out along `out` from `a`; (INF, INF) when none.
static func _near_pole(p: Vector2, a: Vector2, out: Vector2, half: float,
		poles: Dictionary, m: float) -> Vector2:
	var c := Vector2i(floori(p.x / (_CELL_M * m)), floori(p.y / (_CELL_M * m)))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for q in poles.get(Vector2i(c.x + dx, c.y + dz), []):
				if p.distance_to(q) < POLE_MERGE_M * m and (q - a).dot(out) >= half - 1.0 * m:
					return q
	return Vector2(INF, INF)

## Building centres bucketed in `radius` cells: a span asks whether any
## stands within `radius` of it, and scanning every building for each of
## 400 spans took over a second in Helsinki.
static func _centre_grid(data: LocationData, radius: float) -> Dictionary:
	var grid := {}
	for b in data.buildings:
		var c := Vector2(float(b.get("x", 0)), float(b.get("z", 0)))
		var cell := Vector2i(floori(c.x / radius), floori(c.y / radius))
		if not grid.has(cell):
			grid[cell] = []
		(grid[cell] as Array).append(c)
	return grid

static func _built(p: Vector2, centres: Dictionary, radius: float) -> bool:
	var c := Vector2i(floori(p.x / radius), floori(p.y / radius))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for q: Vector2 in centres.get(Vector2i(c.x + dx, c.y + dz), []):
				if p.distance_to(q) < radius:
					return true
	return false

## Indices into data.buildings (ascending) by `radius` cell, for every
## cell a footprint's bounds grown by `radius` touch: a point's cell then
## lists every building with wall within `radius` of it.
static func _ring_grid(data: LocationData, radius: float) -> Dictionary:
	var grid := {}
	for i in data.buildings.size():
		var ring: PackedVector2Array = data.buildings[i].get("footprint", PackedVector2Array())
		if ring.is_empty():
			continue
		var lo := ring[0]
		var hi := ring[0]
		for q in ring:
			lo = lo.min(q)
			hi = hi.max(q)
		for cx in range(floori((lo.x - radius) / radius), floori((hi.x + radius) / radius) + 1):
			for cz in range(floori((lo.y - radius) / radius), floori((hi.y + radius) / radius) + 1):
				var cell := Vector2i(cx, cz)
				if not grid.has(cell):
					grid[cell] = []
				(grid[cell] as Array).append(i)
	return grid

## Facade attachment nearest to the nominal pole; no building means pole.
static func _anchor(p: Vector2, data: LocationData, rings: Dictionary, radius: float) -> Array:
	var best := radius
	var at := p
	var found := false
	for i: int in rings.get(Vector2i(floori(p.x / radius), floori(p.y / radius)), []):
		var b: Dictionary = data.buildings[i]
		var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
		for j in ring.size():
			var q := Geometry2D.get_closest_point_to_segment(p, ring[j], ring[(j + 1) % ring.size()])
			if p.distance_to(q) < best and float(b.get("height", 0.0)) >= CONTACT_M + 1.0:
				best = p.distance_to(q)
				at = q
				found = true
	return [at, found]

static func build(root: Node3D, data: LocationData, ground: GroundTruth) -> Dictionary:
	var spans := plan(data, ground)
	var chunks := {}
	var poles := {}
	var m := WorldScale.metres_to_units()
	# Each span luminaire also gets a real light (StreetLights), sharing
	# the lampposts' budget.
	var heads: Array = []
	for span in spans:
		var a: Vector2 = span["a"]
		var key := Vector2i(1 if a.x >= 0 else 0, 1 if a.y >= 0 else 0)
		if not chunks.has(key):
			chunks[key] = [TreeMeshLibrary.Buf.new(), TreeMeshLibrary.Buf.new(), TreeMeshLibrary.Buf.new()]
		var buffers: Array = chunks[key]
		if span["contact"]:
			var b: Vector2 = span["b"]
			_tube(buffers[0], Vector3(a.x, span["ya"], a.y), Vector3(b.x, span["yb"], b.y), 0.012 * m)
		var supports: Array = span["supports"]
		var left: Vector3 = supports[0][0]
		var right: Vector3 = supports[1][0]
		var mid := (left + right) * 0.5 - Vector3.UP * 0.55 * m
		_tube(buffers[0], left, mid, 0.009 * m)
		_tube(buffers[0], mid, right, 0.009 * m)
		for support in supports:
			var p: Vector3 = support[0]
			var snap := Vector2i(roundi(p.x / (3.0 * m)), roundi(p.z / (3.0 * m)))
			if not support[1] and not poles.has(snap):
				_tube(buffers[1], Vector3(p.x, support[2], p.z), p, 0.065 * m)
				poles[snap] = true
		if span["lamp"]:
			StreetProps._box(buffers[1], mid - Vector3.UP * 0.18 * m, Vector3(0.65, 0.18, 0.3) * m)
			StreetProps._box(buffers[2], mid - Vector3.UP * 0.28 * m, Vector3(0.55, 0.025, 0.25) * m)
			heads.append(Transform3D(Basis().scaled(Vector3(m, m, m)), mid - Vector3.UP * 0.30 * m))
	var calls := 0
	for key in chunks:
		var mesh := ArrayMesh.new()
		for j in 3:
			var buf: TreeMeshLibrary.Buf = chunks[key][j]
			var arr := buf.arrays()
			if (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():
				continue
			arr[Mesh.ARRAY_INDEX] = ParkedCars.front_faces(arr[Mesh.ARRAY_INDEX])
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.045, 0.05, 0.045) if j == 0 else Color(0.26, 0.28, 0.26)
			mat.roughness = 0.65
			if j == 2:
				mat.albedo_color = Color(0.9, 0.88, 0.75)
				mat.emission_enabled = true
				mat.emission = mat.albedo_color
				CityLights.mark_glow(mat, 0.55)
			mesh.surface_set_material(mesh.get_surface_count() - 1, mat)
			calls += 1
		var mi := MeshInstance3D.new()
		mi.name = "OverheadWires_%d_%d" % [key.x, key.y]
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	if not heads.is_empty():
		var region := ArchitectureStyle.country_region_for(data.latitude, data.longitude, data.country)
		StreetLights.add(root, {"span": heads}, region, m, View360.spawn_xz(data))
	return {"spans": spans.size(), "poles": poles.size(), "draw_calls": calls}

static func _tube(buf: TreeMeshLibrary.Buf, a: Vector3, b: Vector3, radius: float) -> void:
	TreeMeshLibrary._tube(buf, [a, b], [radius, radius], 4, 1.0, 1.0)
