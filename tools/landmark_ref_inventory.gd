extends SceneTree

## Audit local reference evidence against the live landmark registry.
##   godot --headless --path . --script tools/landmark_ref_inventory.gd
## The inventory reports files and documentation, not whether a photograph
## depicts the right subject or has a suitable viewpoint. AI images are
## counted separately and never satisfy the two-photo target.

const REFS := "res://visual-plan/refs/landmarks"

func _init() -> void:
	var entries := LocationData.landmarks().duplicate()
	entries.sort_custom(func(a, b): return str(a["type"]) < str(b["type"]))
	var rows := PackedStringArray(["type\tname\tlocal_photos\tdocumented_photos\tai_images\tviewpoint"])
	var missing := PackedStringArray()
	var photo_types := 0
	var two_photos := 0
	for entry in entries:
		var type := str(entry["type"])
		var dir_path := REFS.path_join(type)
		var readme_path := dir_path.path_join("README.md")
		var readme := FileAccess.get_file_as_string(readme_path) if FileAccess.file_exists(readme_path) else ""
		var photos := 0
		var documented := 0
		var ai := 0
		var dir := DirAccess.open(dir_path)
		if dir:
			for file in dir.get_files():
				var ext := file.get_extension().to_lower()
				if ext not in ["jpg", "jpeg", "png", "webp"]:
					continue
				if file.begins_with("ai_"):
					ai += 1
				else:
					photos += 1
					if readme.contains("`" + file + "`"):
						documented += 1
		if photos > 0:
			photo_types += 1
		if documented >= 2:
			two_photos += 1
		if photos == 0 and ai == 0:
			missing.append(type)
		# No current README records verified camera coordinates or bearing.
		rows.append("%s\t%s\t%d\t%d\t%d\tunknown" % [type, str(entry["name"]).replace("\t", " "), photos, documented, ai])
	var inventory := FileAccess.open(REFS.path_join("INVENTORY.tsv"), FileAccess.WRITE)
	inventory.store_string("\n".join(rows) + "\n")
	var missing_file := FileAccess.open(REFS.path_join("MISSING.txt"), FileAccess.WRITE)
	missing_file.store_string("\n".join(missing) + "\n")
	print("REFERENCE INVENTORY: %d registry types, %d with local photos, %d with two documented photos, %d without images" % [
		entries.size(), photo_types, two_photos, missing.size()])
	quit(0)
