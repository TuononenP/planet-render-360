extends SceneTree

## Offline catalog census. Run headlessly in the background:
## godot --headless --path . --script tools/audit_landmark_placement.gd -- \
##   --output=res://visual-plan/reviews/placement-audit/catalog.tsv

func _init() -> void:
	_run()

func _run() -> void:
	var output := "user://landmark-placement.tsv"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.substr(9)
	var rows := PackedStringArray(["type\tname\tbase\tmin_y_m\tmax_y_m\tbase_drop_m\tbase_asl_m\tbase_half_m\tclear_m\tspan_m\twidth_m\tdepth_m\tparts\ttriangles"])
	var below: Array = []
	var bases := {}
	for entry in LocationData.landmarks():
		var type := str(entry["type"])
		var hero := LandmarkBuilder.build(type)
		var lo := Vector3(INF, INF, INF)
		var hi := Vector3(-INF, -INF, -INF)
		var parts := LandmarkBuilder.parts(hero)
		var tris := 0
		for part in parts:
			var transform := part.transform
			var parent := part.get_parent() as Node3D
			while parent != null and parent != hero:
				transform = parent.transform * transform
				parent = parent.get_parent() as Node3D
			var box: AABB = transform * part.mesh.get_aabb()
			lo = lo.min(box.position)
			hi = hi.max(box.end)
			tris += part.mesh.surface_get_array_len(0) / 3
		var base := str(entry.get("base", "ground"))
		bases[base] = int(bases.get(base, 0)) + 1
		if lo.y < -5.0:
			below.append([type, lo.y, entry.get("base_drop_m", 0.0)])
		rows.append("%s\t%s\t%s\t%.2f\t%.2f\t%.2f\t%s\t%s\t%.2f\t%.2f\t%.2f\t%.2f\t%d\t%d" % [
			type, entry["name"], base, lo.y, hi.y, float(entry.get("base_drop_m", 0)),
			str(entry.get("base_asl_m", "")), str(entry.get("base_half_m", "")), LandmarkSites.clear_m(entry),
			float(entry.get("span_m", 0)), hi.x - lo.x, hi.z - lo.z, parts.size(), tris])
		hero.free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output).get_base_dir())
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		printerr("PLACEMENT CENSUS FAIL: cannot write ", output)
		quit(1)
		return
	file.store_string("\n".join(rows) + "\n")
	print("PLACEMENT CENSUS: ", rows.size() - 1, " landmarks, bases=", bases,
		", below_origin=", below, ", output=", output)
	quit(0)
