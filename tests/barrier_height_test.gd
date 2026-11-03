extends SceneTree

func _init() -> void:
	var data := LocationData.new()
	data.grid_size = 8
	data.heights.resize(64)
	data.heights.fill(3.0)
	data.water_level = -3.0
	var ground := GroundTruth.new(data)
	var points := PackedVector2Array([Vector2(0, 0), Vector2(10, 0)])
	var heights: Array[float] = []
	for tagged in [2.75, NAN]:
		data.barriers = [{"class": "fence", "points": points, "height_m": tagged}]
		var holder := Node3D.new()
		StreetProps._barriers(holder, data, ground, {"m2u": 1.0, "season": 0})
		if holder.get_child_count() != 1:
			printerr("BARRIER HEIGHT FAIL: expected a fence mesh")
			quit(1)
			return
		var mesh: Mesh = (holder.get_child(0) as MeshInstance3D).mesh
		heights.append(mesh.get_aabb().size.y)
		holder.free()
	if absf(heights[0] - 2.75) > 0.001 or absf(heights[1] - 1.5) > 0.001:
		printerr("BARRIER HEIGHT FAIL: tagged height and default: ", heights)
		quit(1)
		return
	data.barriers = [
		{"class": "fence", "points": points, "fence_type": "chain_link"},
		{"class": "fence", "points": points, "material": "wood"},
		{"class": "fence", "points": points}]
	var holder := Node3D.new()
	StreetProps._barriers(holder, data, ground, {"m2u": 1.0, "season": 0})
	for name in ["Prop_barrier_chain_link", "Prop_barrier_wood_fence", "Prop_barrier_fence"]:
		if holder.get_node_or_null(name) == null:
			printerr("BARRIER HEIGHT FAIL: missing material batch ", name)
			quit(1)
			return
	holder.free()
	print("BARRIER HEIGHT OK: mapped height and fallback")
	quit(0)
