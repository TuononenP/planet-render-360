extends SceneTree

## Headless orientation census for all landmarks in LocationData.landmarks().
## Run via:
##   tools/godot_bg.sh --headless --path . --script tools/audit_landmark_orientation.gd -- \
##     --output=/path/to/landmark_census.tsv

const CORE_TYPES := [
	"eiffel", "tokyo", "big_ben", "colosseum", "sagrada", "pyramid",
	"statue_liberty", "sydney_opera", "turku_cathedral", "helsinki_cathedral",
	"burj_khalifa", "one_wtc", "empire_state", "salute", "monte_carlo_casino",
	"gwanghwamun", "banff_springs", "stockholm_city_hall", "riddarholmen",
	"golden_gate", "brooklyn_bridge", "tower_bridge", "sydney_harbour_bridge",
	"bixby_creek_bridge"
]

func _init() -> void:
	_run()

func _run() -> void:
	var output := "user://landmark-orientation-census.tsv"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.substr(9)

	var header := "\t".join([
		"type", "name", "kind", "category", "lat", "lon",
		"has_yaw", "yaw_deg", "clear_m", "span_m", "height_m",
		"width_x_m", "depth_z_m", "mesh_h_m", "aspect_ratio", "long_axis"
	])
	var rows := PackedStringArray([header])
	var count := 0
	var handbuilt_count := 0

	for entry in LocationData.landmarks():
		var type := str(entry["type"])
		var is_core := type in CORE_TYPES
		var is_bespoke := LandmarkBuilder.is_bespoke(type)
		var arch := str(entry.get("archetype", ""))
		var category := "core" if is_core else ("bespoke" if is_bespoke else ("bridge_param" if entry.has("span_m") else ("archetype:" + arch if not arch.is_empty() else "fallback")))
		if is_core or is_bespoke:
			handbuilt_count += 1

		var hero := LandmarkBuilder.build(type)
		var model := hero.get_node_or_null("Model") as Node3D
		var ref_node: Node3D = model if model != null else hero
		var lo := Vector3(INF, INF, INF)
		var hi := Vector3(-INF, -INF, -INF)
		var parts := LandmarkBuilder.parts(hero)
		for part in parts:
			var transform := part.transform
			var parent := part.get_parent() as Node3D
			while parent != null and parent != ref_node:
				transform = parent.transform * transform
				parent = parent.get_parent() as Node3D
			var box: AABB = transform * part.mesh.get_aabb()
			lo = lo.min(box.position)
			hi = hi.max(box.end)

		var wx := 0.0 if lo.x == INF else (hi.x - lo.x)
		var dz := 0.0 if lo.z == INF else (hi.z - lo.z)
		var hy := 0.0 if lo.y == INF else (hi.y - lo.y)
		var mn := minf(wx, dz)
		var mx := maxf(wx, dz)
		var aspect := (mx / mn) if mn > 0.01 else 1.0
		var long_axis := "square"
		if aspect >= 1.15:
			long_axis = "X" if wx >= dz else "Z"

		var has_yaw := "1" if entry.has("yaw_deg") else "0"
		var yaw_deg := float(entry.get("yaw_deg", 0.0))
		rows.append("%s\t%s\t%s\t%s\t%.7f\t%.7f\t%s\t%.3f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%s" % [
			type,
			str(entry.get("name", "")).replace("\t", " "),
			str(entry.get("kind", "")).replace("\t", " "),
			category,
			float(entry.get("lat", 0.0)),
			float(entry.get("lon", 0.0)),
			has_yaw,
			yaw_deg,
			LandmarkSites.clear_m(entry),
			float(entry.get("span_m", 0.0)),
			float(entry.get("height_m", 0.0)),
			wx, dz, hy, aspect, long_axis
		])
		hero.free()
		count += 1

	var abs_out := ProjectSettings.globalize_path(output) if output.begins_with("res://") or output.begins_with("user://") else output
	DirAccess.make_dir_recursive_absolute(abs_out.get_base_dir())
	var file := FileAccess.open(abs_out, FileAccess.WRITE)
	if file == null:
		printerr("ORIENTATION CENSUS FAIL: cannot write ", abs_out)
		quit(1)
		return
	file.store_string("\n".join(rows) + "\n")
	print("ORIENTATION CENSUS OK: total=", count, " handbuilt=", handbuilt_count, " output=", abs_out)
	quit(0)
