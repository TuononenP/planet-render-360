extends SceneTree

## Mapped bare rock stands up as one skin over its own outline: a banana or
## horseshoe of rock (centroid outside it) or one with a hole used to fold its
## shrunk rings over each other and drew as loose ribs you could see through.
## Every triangle must lie on the rock, face upward and wind to show from above.

func _init() -> void:
	var failures: Array[String] = []
	var data := LocationData.new()
	RenderSettings.apply_preset(data, 3)
	data.latitude = 60.1555
	data.longitude = 24.956
	data.heights.resize(data.grid_size * data.grid_size)
	data.heights.fill(10.0)
	# A C-shaped band (outer radius 40 m, inner 22 m, open to the east) and a
	# square slab with a square hole; the C's centroid lies in its notch.
	var band := PackedVector2Array()
	for i in 25:
		var a := deg_to_rad(40.0 + 280.0 * float(i) / 24.0)
		band.append(Vector2(cos(a), sin(a)) * 40.0)
	for i in 25:
		var a := deg_to_rad(320.0 - 280.0 * float(i) / 24.0)
		band.append(Vector2(cos(a), sin(a)) * 22.0)
	var slab := PackedVector2Array([Vector2(100, 0), Vector2(140, 0), Vector2(140, 30), Vector2(100, 30)])
	var hole := PackedVector2Array([Vector2(112, 10), Vector2(128, 10), Vector2(128, 20), Vector2(112, 20)])
	var disc := PackedVector2Array()
	for i in 12:
		disc.append(Vector2(-100, 0) + Vector2(cos(TAU * float(i) / 12.0), sin(TAU * float(i) / 12.0)) * 12.0)
	data.land_polygons = [
		{"class": "rock", "points": band, "holes": []},
		{"class": "rock", "points": slab, "holes": [hole]},
		{"class": "rock", "points": disc, "holes": []},
	]
	var ground := GroundTruth.new(data)
	var root := Node3D.new()
	var n := RockOutcrops.build(root, data, ground)
	if n != 3:
		failures.append("RockOutcrops raised %d outcrops, expected 3" % n)
	var tris := 0
	var bad_place := 0
	var bad_up := 0
	var top := -1e9
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := (mi as MeshInstance3D).mesh
		for s in mesh.get_surface_count():
			var arrays := mesh.surface_get_arrays(s)
			var v := arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
			var idx: Variant = arrays[Mesh.ARRAY_INDEX]
			var order: Array = []
			if idx is PackedInt32Array and not (idx as PackedInt32Array).is_empty():
				order = Array(idx as PackedInt32Array)
			else:
				order = range(v.size())
			for t in range(0, order.size() - 2, 3):
				var a := v[order[t]]
				var b := v[order[t + 1]]
				var c := v[order[t + 2]]
				tris += 1
				top = maxf(top, maxf(a.y, maxf(b.y, c.y)))
				var mid := Vector2(a.x + b.x + c.x, a.z + b.z + c.z) / 3.0
				var on := false
				for poly in data.land_polygons:
					var d := poly as Dictionary
					var inside := Geometry2D.is_point_in_polygon(mid, d["points"])
					for hl in d["holes"]:
						if Geometry2D.is_point_in_polygon(mid, hl):
							inside = false
					on = on or inside
				if not on:
					bad_place += 1
				# Godot front faces wind clockwise: seen from above the
				# geometric normal (b-a) x (c-a) points down.
				if (b - a).cross(c - a).y > 0.0:
					bad_up += 1
	if tris == 0:
		failures.append("no rock triangles built")
	if bad_place > 0:
		failures.append("%d of %d rock triangles lie off the rock (notch or hole bridged)" % [bad_place, tris])
	if bad_up > 0:
		failures.append("%d of %d rock triangles are back-facing from above" % [bad_up, tris])
	var base := ground.height_at_world(0.0, 0.0)
	if top < base + 1.0 or top > base + RockOutcrops.H_RANGE.y * 1.4:
		failures.append("rock tops out %.1f m over the ground, outside its mound range" % (top - base))
	root.free()
	for f in failures:
		printerr("ROCK OUTCROPS FAIL: ", f)
	print("rock_outcrops_test: %s (%d triangles)" % ["FAIL" if not failures.is_empty() else "PASS", tris])
	quit(1 if not failures.is_empty() else 0)
