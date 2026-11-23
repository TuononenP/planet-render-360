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
const MAX_POLE_STEP_M := 24
const MAX_SPAN_M := 42.0
const _CELL_M := 20.0

static func plan(data: LocationData, ground: GroundTruth, mask: VegetationMask = null,
		marking_plan: RoadMarkings.Plan = null) -> Array:
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
	var bridges := LandmarkSites.bridge_spans(data)
	var tracks := _track_grid(lines, m)
	var roads := _road_grid(data, m)
	var crossings := StreetProps.crossing_grid(data, marking_plan, m)
	var aprons := StreetProps.apron_grid(marking_plan, m)
	var keepout := {"tracks": tracks, "roads": roads, "crossings": crossings, "aprons": aprons,
		"ground": ground, "mask": mask}
	var centres := _centre_grid(data, 35.0 * m)
	var replaced := _replaced(data)
	var rings := _ring_grid(data, 12.0 * m, replaced, false)
	var models := _ring_grid(data, 12.0 * m, replaced, true)
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
			# A registry bridge's model carries its own catenary poles on
			# the deck; none stand on the seabed beside it.
			if _on_bridge_model(a, bridges) or _on_bridge_model(b, bridges):
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
			var out := n * float(side)
			var p: Vector2 = a + out * half
			var sup := _resolve_support(p, a, out, half, data, rings, models, keepout, poles, m)
			var at: Vector2 = sup[0]
			if at.x == INF:
				break
			var y := ground.height_at_world(at.x, at.y)
			supports.append([Vector3(at.x, y + (CONTACT_M + 0.8) * m, at.y), bool(sup[1]), y])
		# A pole that cannot clear roads, crossings or buildings drops the span.
		if supports.size() < 2:
			continue
		if (supports[0][0] as Vector3).distance_to(supports[1][0] as Vector3) > MAX_SPAN_M * m:
			continue
		spans.append({"a": a, "b": b, "supports": supports, "contact": bool(entry[1]),
			"lamp": bool(entry[2]), "ya": ground.height_at_world(a.x, a.y) + CONTACT_M * m,
			"yb": ground.height_at_world(b.x, b.y) + CONTACT_M * m})
		if spans.size() >= MAX_SPANS:
			break
	return spans

## Whether a registry bridge's model carries the way at `p`.
static func _on_bridge_model(p: Vector2, bridges: Array) -> bool:
	for sp in bridges:
		if LandmarkSites.on_span(p, sp[0] as Vector2, sp[1] as Dictionary):
			return true
	return false

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

## Drivable road carriageways bucketed by cell so span poles never stand in traffic lanes.
static func _road_grid(data: LocationData, m: float) -> Dictionary:
	var grid := {}
	var cell := _CELL_M * m
	for raw in data.roads:
		if not (raw is Dictionary) or not RoadMarkings._drivable(raw):
			continue
		var rd: Dictionary = raw
		if bool(rd.get("tunnel", false)) or bool(rd.get("bridge", false)) or bool(rd.get("area", false)):
			continue
		var pts: PackedVector2Array = rd.get("points", PackedVector2Array())
		var clear := (float(rd.get("width_m", 6.0)) * 0.5 + 0.65) * m
		for i in pts.size() - 1:
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
				(grid[key] as Array).append([pts[i], pts[i + 1], clear])
	return grid

static func _on_road(p: Vector2, grid: Dictionary, m: float) -> bool:
	var cell := _CELL_M * m
	var c := Vector2i(floori(p.x / cell), floori(p.y / cell))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for seg in grid.get(Vector2i(c.x + dx, c.y + dz), []):
				if p.distance_to(Geometry2D.get_closest_point_to_segment(p, seg[0], seg[1])) < float(seg[2]):
					return true
	return false

static func _pole_blocked(p: Vector2, keepout: Dictionary, data: LocationData,
		rings: Dictionary, models: Dictionary, m: float) -> bool:
	if _on_track(p, keepout["tracks"], m) or _on_road(p, keepout["roads"], m):
		return true
	if StreetProps.on_crossing(keepout["crossings"], p, m) or StreetProps._on_apron(keepout["aprons"], p, m):
		return true
	var ground: GroundTruth = keepout.get("ground")
	if ground != null and (not ground.is_inside(p.x, p.y) or ground.water_at(p.x, p.y) > 0.0):
		return true
	var mask: VegetationMask = keepout.get("mask")
	if mask != null and mask.blocked(p.x, p.y, VegetationMask.ROAD | VegetationMask.BUILDING | VegetationMask.WATER, 0.0):
		return true
	return _inside(p, data, models, 12.0 * m) or _inside(p, data, rings, 12.0 * m)

## Resolves [position, is_wall_anchor] on one side of `a`, stepping outward
## across parallel carriageways, tracks, aprons and crossings to a kerb or
## building facade; returns [(INF, INF), false] when no clear support exists.
static func _resolve_support(p: Vector2, a: Vector2, out: Vector2, half: float,
		data: LocationData, rings: Dictionary, models: Dictionary, keepout: Dictionary,
		poles: Dictionary, m: float) -> Array:
	var anchor := _anchor(p, data, rings, 12.0 * m, a, out, half - 1.0 * m)
	if bool(anchor[1]):
		return anchor
	for step in MAX_POLE_STEP_M + 1:
		var at := p + out * float(step) * m
		var shared := _near_pole(at, a, out, half, poles, m)
		if shared.x != INF:
			return [shared, false]
		if step > 0:
			var wall := _anchor(at, data, rings, 3.5 * m, a, out, half - 1.0 * m)
			if bool(wall[1]):
				return wall
		if not _pole_blocked(at, keepout, data, rings, models, m):
			var key := Vector2i(floori(at.x / (_CELL_M * m)), floori(at.y / (_CELL_M * m)))
			if not poles.has(key):
				poles[key] = []
			(poles[key] as Array).append(at)
			return [at, false]
	return [Vector2(INF, INF), false]

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

## By data.buildings index, 1 for a mapped building a landmark model stands
## in for (BuildingBuilder leaves it unbuilt): its mapped walls are not the
## model's, so no span hangs on them and no pole stands inside them.
static func _replaced(data: LocationData) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(data.buildings.size())
	var site := TerrainBuilder.landmark_site_xz(data)
	for i in data.buildings.size():
		out[i] = 0 if BuildingBuilder._accepted(data, data.buildings[i], site, INF) else 1
	return out

## Indices into data.buildings (ascending) by `radius` cell, for every
## cell a footprint's bounds grown by `radius` touch: a point's cell then
## lists every building with wall within `radius` of it. Only the
## buildings whose `replaced` flag (_replaced; none when empty) matches
## `models` are listed.
static func _ring_grid(data: LocationData, radius: float, replaced := PackedByteArray(),
		models := false) -> Dictionary:
	var grid := {}
	for i in data.buildings.size():
		var ring: PackedVector2Array = data.buildings[i].get("footprint", PackedVector2Array())
		var is_model := not replaced.is_empty() and replaced[i] == 1
		if ring.is_empty() or is_model != models:
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

## Whether `p` lies inside a footprint listed in `grid` (_ring_grid).
static func _inside(p: Vector2, data: LocationData, grid: Dictionary, radius: float) -> bool:
	for i: int in grid.get(Vector2i(floori(p.x / radius), floori(p.y / radius)), []):
		if Geometry2D.is_point_in_polygon(p, data.buildings[i].get("footprint", PackedVector2Array())):
			return true
	return false

## Facade attachment nearest to `p` on the outward side of `a`; no building means pole.
static func _anchor(p: Vector2, data: LocationData, rings: Dictionary, radius: float,
		a: Vector2 = Vector2.ZERO, out: Vector2 = Vector2.ZERO, min_proj: float = -INF) -> Array:
	var best := radius
	var at := p
	var found := false
	var seen := {}
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for i: int in rings.get(Vector2i(floori(p.x / radius) + dx, floori(p.y / radius) + dz), []):
				if seen.has(i):
					continue
				seen[i] = true
				var b: Dictionary = data.buildings[i]
				if float(b.get("height", 0.0)) < CONTACT_M + 1.0:
					continue
				var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
				for j in ring.size():
					var q := Geometry2D.get_closest_point_to_segment(p, ring[j], ring[(j + 1) % ring.size()])
					if min_proj > -INF and (q - a).dot(out) < min_proj:
						continue
					var d := p.distance_to(q)
					if d < best:
						best = d
						at = q
						found = true
	return [at, found]

static func build(root: Node3D, data: LocationData, ground: GroundTruth,
		mask: VegetationMask = null, marking_plan: RoadMarkings.Plan = null) -> Dictionary:
	var spans := plan(data, ground, mask, marking_plan)
	var chunks := {}
	var poles := {}
	var m := WorldScale.metres_to_units()
	# Stockholm's wires and poles are drawn heavier, wire darker with a faint sheen, to read at distance.
	var sto := CityStyles.region_at(data.latitude, data.longitude) == "stockholm"
	var wire_k := 1.8 if sto else 1.0
	var pole_k := 1.4 if sto else 1.0
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
			_tube(buffers[0], Vector3(a.x, span["ya"], a.y), Vector3(b.x, span["yb"], b.y), 0.012 * wire_k * m)
		var supports: Array = span["supports"]
		var left: Vector3 = supports[0][0]
		var right: Vector3 = supports[1][0]
		var mid := (left + right) * 0.5 - Vector3.UP * 0.55 * m
		_tube(buffers[0], left, mid, 0.009 * wire_k * m)
		_tube(buffers[0], mid, right, 0.009 * wire_k * m)
		for support in supports:
			var p: Vector3 = support[0]
			var snap := Vector2i(roundi(p.x / (3.0 * m)), roundi(p.z / (3.0 * m)))
			if not support[1] and not poles.has(snap):
				_tube(buffers[1], Vector3(p.x, support[2], p.z), p, 0.065 * pole_k * m)
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
			if sto and j == 0:
				mat.albedo_color = Color(0.02, 0.022, 0.02)
				mat.metallic = 0.55
				mat.roughness = 0.38
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
