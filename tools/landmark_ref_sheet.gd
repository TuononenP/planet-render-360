extends SceneTree

## Reference-versus-render review pages for the landmarks of one place (Stockholm
## plan S-6). No Python or Pillow needed:
##   tools/godot_bg.sh --headless --path . --script tools/landmark_ref_sheet.gd -- \
##       [--tag=sto_final] [--types=a,b,c | --stockholm] [--per=6]
## Reads visual-plan/captures/<tag>/<type>_sheet.jpg (tools/capture_landmarks.gd,
## four views tiled 2 x 2) and the first documented reference photo of
## visual-plan/refs/landmarks/<type>/ (front.jpg first, then quarter, aerial,
## any other README row; ai_* images never count). Writes, in
## visual-plan/captures/<tag>/compare/:
##   page_NN.jpg   one row per type: reference | render front | render quarter
##   page_NN.txt   the types of that page, top to bottom, with the reference file,
##                 its README row (URL, author, licence) and the model's triangles
##   index.tsv     every type: page, row, reference file, render present
## A type without a render or a reference shows a dark cell, and the index says so.

const CELL := Vector2i(400, 250)
const REFS := "res://visual-plan/refs/landmarks/"
const CAPTURES := "res://visual-plan/captures/"
const PREFERRED := ["front.jpg", "quarter.jpg", "aerial.jpg", "side.jpg", "night.jpg"]

func _init() -> void:
	var tag := "sto_final"
	var per := 6
	var types: Array = []
	var stockholm := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
		elif a.begins_with("--per="):
			per = maxi(1, int(a.substr(6)))
		elif a.begins_with("--types="):
			types = Array(a.substr(8).split(",", false))
		elif a == "--stockholm":
			stockholm = true
	if stockholm or types.is_empty():
		types = _stockholm_types()
	var out_dir := ProjectSettings.globalize_path(CAPTURES + tag + "/compare")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var stats := _stats(tag)
	var index := PackedStringArray(["type\tpage\trow\treference\trender"])
	var page := 0
	for start in range(0, types.size(), per):
		var rows := types.slice(start, start + per)
		var sheet := Image.create(CELL.x * 3, CELL.y * rows.size(), false, Image.FORMAT_RGB8)
		sheet.fill(Color(0.09, 0.09, 0.1))
		var notes := PackedStringArray()
		for r in rows.size():
			var type := str(rows[r])
			var ref := _reference(type)
			var render := _load(CAPTURES + tag + "/" + type + "_sheet.jpg")
			if not ref.is_empty():
				_blit(sheet, _load(str(ref["path"])), Rect2(0, 0, 1, 1), Vector2i(0, r * CELL.y))
			if render != null:
				_blit(sheet, render, Rect2(0.0, 0.0, 0.5, 0.5), Vector2i(CELL.x, r * CELL.y))
				_blit(sheet, render, Rect2(0.5, 0.0, 0.5, 0.5), Vector2i(CELL.x * 2, r * CELL.y))
			notes.append("%d. %s | ref: %s | model: %s triangles | %s" % [r + 1, type,
				str(ref.get("file", "none")), str(stats.get(type, "n/a")), str(ref.get("row", ""))])
			index.append("%s\t%d\t%d\t%s\t%s" % [type, page, r + 1, str(ref.get("file", "none")),
				"yes" if render != null else "missing"])
		sheet.save_jpg("%s/page_%02d.jpg" % [out_dir, page], 0.85)
		var f := FileAccess.open("%s/page_%02d.txt" % [out_dir, page], FileAccess.WRITE)
		f.store_string("\n".join(notes) + "\n")
		f.close()
		page += 1
	var f := FileAccess.open(out_dir + "/index.tsv", FileAccess.WRITE)
	f.store_string("\n".join(index) + "\n")
	f.close()
	print("LANDMARK REF SHEET: %d types, %d pages in %s" % [types.size(), page, out_dir])
	quit(0)

## Every Stockholm registry type plus the primary City Hall and Riddarholmen.
func _stockholm_types() -> Array:
	var out: Array = ["stockholm_city_hall", "riddarholmen", "vasterbron"]
	for e in LandmarkRegistrySwedenStockholm.entries():
		var t := str(e["type"])
		if not out.has(t):
			out.append(t)
	for t in ["djurgardsbron", "skeppsholmsbron"]:
		if not out.has(t):
			out.append(t)
	return out

func _stats(tag: String) -> Dictionary:
	var out := {}
	var path := ProjectSettings.globalize_path(CAPTURES + tag + "/stats.tsv")
	if not FileAccess.file_exists(path):
		return out
	for line in FileAccess.get_file_as_string(path).split("\n").slice(1):
		var c := line.split("\t")
		if c.size() >= 6:
			out[c[0]] = c[5]
	return out

## {path, file, row} of the best documented reference photo, {} when none.
func _reference(type: String) -> Dictionary:
	var dir_path := REFS + type
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return {}
	var readme_path := dir_path + "/README.md"
	var readme := FileAccess.get_file_as_string(readme_path) if FileAccess.file_exists(readme_path) else ""
	var files := Array(dir.get_files()).filter(func(f: String) -> bool:
		return f.get_extension().to_lower() == "jpg" and not f.begins_with("ai_") \
			and readme.contains("`" + f + "`"))
	files.sort_custom(func(a: String, b: String) -> bool:
		var ia := PREFERRED.find(a)
		var ib := PREFERRED.find(b)
		return (ia if ia >= 0 else 99) < (ib if ib >= 0 else 99))
	if files.is_empty():
		return {}
	var file := str(files[0])
	var row := ""
	for line in readme.split("\n"):
		if line.contains("`" + file + "`"):
			row = line.strip_edges().trim_prefix("- ")
	return {"path": dir_path + "/" + file, "file": file, "row": row}

func _load(res_path: String) -> Image:
	var path := ProjectSettings.globalize_path(res_path)
	if not FileAccess.file_exists(path):
		return null
	return Image.load_from_file(path)

## Copies the `part` (fractions) of `src` into one cell at `at`, scaled to fit.
func _blit(dst: Image, src: Image, part: Rect2, at: Vector2i) -> void:
	if src == null:
		return
	var w := src.get_width()
	var h := src.get_height()
	var crop := src.get_region(Rect2i(int(part.position.x * w), int(part.position.y * h),
		int(part.size.x * w), int(part.size.y * h)))
	var k := minf(float(CELL.x) / crop.get_width(), float(CELL.y) / crop.get_height())
	crop.resize(maxi(1, int(crop.get_width() * k)), maxi(1, int(crop.get_height() * k)), Image.INTERPOLATE_BILINEAR)
	var off := Vector2i((CELL.x - crop.get_width()) / 2, (CELL.y - crop.get_height()) / 2)
	dst.blit_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), at + off)
