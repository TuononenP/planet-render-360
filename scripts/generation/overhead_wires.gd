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
		if not (road is Dictionary) or bool(road.get("tunnel", false)) or bool(road.get("bridge", false)):
			continue
		var hung := data.country.to_upper() in ["FI", "SE"] and str(road.get("class", "")) in StreetProps.LIT
		if hung or bool(road.get("trolley_wire", false)):
			lines.append([road, bool(road.get("trolley_wire", false)), hung])
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
			if bool(entry[2]) and not _built(mid, data, 35.0 * m):
				continue
			var n := Vector2((b - a).y, -(b - a).x).normalized()
			var half := maxf(4.0, float(way.get("width_m", 6.0)) * 0.5 + 1.0) * m
			var supports: Array = []
			for side in [-1.0, 1.0]:
				var p: Vector2 = a + n * half * float(side)
				var anchor := _anchor(p, data, 12.0 * m)
				var at: Vector2 = anchor[0]
				var y := ground.height_at_world(at.x, at.y)
				supports.append([Vector3(at.x, y + (CONTACT_M + 0.8) * m, at.y), bool(anchor[1]), y])
			spans.append({"a": a, "b": b, "supports": supports, "contact": bool(entry[1]),
				"lamp": bool(entry[2]), "ya": ground.height_at_world(a.x, a.y) + CONTACT_M * m,
				"yb": ground.height_at_world(b.x, b.y) + CONTACT_M * m})
			if spans.size() >= MAX_SPANS:
				return spans
	return spans

static func _built(p: Vector2, data: LocationData, radius: float) -> bool:
	for b in data.buildings:
		if p.distance_to(Vector2(float(b.get("x", 0)), float(b.get("z", 0)))) < radius:
			return true
	return false

## Facade attachment nearest to the nominal pole; no building means pole.
static func _anchor(p: Vector2, data: LocationData, radius: float) -> Array:
	var best := radius
	var at := p
	var found := false
	for b in data.buildings:
		var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
		for i in ring.size():
			var q := Geometry2D.get_closest_point_to_segment(p, ring[i], ring[(i + 1) % ring.size()])
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
	return {"spans": spans.size(), "poles": poles.size(), "draw_calls": calls}

static func _tube(buf: TreeMeshLibrary.Buf, a: Vector3, b: Vector3, radius: float) -> void:
	TreeMeshLibrary._tube(buf, [a, b], [radius, radius], 4, 1.0, 1.0)
