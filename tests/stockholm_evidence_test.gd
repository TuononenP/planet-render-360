extends SceneTree

## Evidence contract for the Stockholm landmarks (plan round 7). No world/cache build.
## 1. Registry heights with a primary source stay on that source's figure.
## 2. Every Stockholm type's reference README documents its photos (every jpg in the folder has a row): each row names a
##    Wikimedia Commons URL, an author and an allowed licence, never an interior or a
##    Russian-operated host, and the type has a front row.
## The READMEs are local review evidence (visual-plan/refs is not shipped); a checkout
## without them skips part 2.

## type -> [height_m, source]
const SOURCED_HEIGHTS := {
	"nordic_museum": [81.0, "nordiskamuseet.se 'The history of the building' (tower 81 m); OSM way 348345482 tower part 64 m is lower"],
	"kastellet_stockholm": [20.0, "en/sv Wikipedia: 20 m high round stair tower; OSM part 22 m"],
	"hotorgsskraporna": [61.0, "sv Wikipedia 61 m above ground; OSM height=72 is above sea level"],
	"kungstornen": [61.0, "OSM height=60 (north) / 61 (south)"],
	"rosenbad": [38.0, "OSM relation 279566 height=38"],
	"stockholm_stadion": [40.0, "OSM parts 779124619 / 779124622 height=40"],
	"adolf_fredriks_kyrka": [43.5, "OSM way 42038493 height=43.5"],
	"skatteskrapan": [85.5, "OSM way 37046494 height=85.5"],
	"norra_tornen": [125.0, "OSM way 642654235 height=125"],
	"hogalid_church": [68.5, "OSM relation 1257127 height=68.5"],
}
const REFS := "res://visual-plan/refs/landmarks"
const LICENCE := ["CC BY 2.0", "CC BY 2.5", "CC BY 3.0", "CC BY 4.0", "CC BY-SA 2.0", "CC BY-SA 2.5", "CC BY-SA 3.0", "CC BY-SA 4.0",
	"CC0", "Public domain", "PD"]
const BAD_WORDS := ["interior", "interiör", "cabaret", "stage", "scen", "auditorium", "salong", "nave", "map", "karta"]
const BAD_HOSTS := [".ru/", ".su/", ".xn--p1ai", "mail.ru", "yandex", "vk.com"]

func _init() -> void:
	var failures: Array[String] = []
	var heights := {}
	var types: Array[String] = []
	for entry in LandmarkRegistrySwedenStockholm.entries():
		heights[str(entry["type"])] = float(entry.get("height_m", 0.0))
		types.append(str(entry["type"]))
	for type in SOURCED_HEIGHTS:
		var want: float = SOURCED_HEIGHTS[type][0]
		if not heights.has(type):
			failures.append("%s left the registry" % type)
		elif absf(float(heights[type]) - want) > 0.01:
			failures.append("%s height %.1f m, sourced figure %.1f m (%s)" % [type, heights[type], want, SOURCED_HEIGHTS[type][1]])
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(REFS)):
		for type in types:
			_check_readme(type, failures)
	else:
		print("stockholm_evidence_test: no local refs folder, README check skipped")
	if failures.is_empty():
		print("stockholm_evidence_test: OK")
		quit(0)
	else:
		for f in failures:
			printerr("FAIL ", f)
		quit(1)

func _check_readme(type: String, failures: Array[String]) -> void:
	var path := REFS.path_join(type).path_join("README.md")
	var jpgs: Array[String] = []
	for f in DirAccess.get_files_at(REFS.path_join(type)):
		if f.to_lower().ends_with(".jpg"):
			jpgs.append(f)
	if not FileAccess.file_exists(path):
		if not jpgs.is_empty():
			failures.append("%s has photos but no README: %s" % [type, ", ".join(jpgs)])
		return  # types without any collected photo are reported by tools/landmark_ref_inventory.gd
	var rows := 0
	var front := false
	var documented := {}
	for line in FileAccess.get_file_as_string(path).split("\n"):
		if not line.begins_with("- `"):
			continue
		rows += 1
		var parts := line.split(" — ")
		if parts.size() < 4:
			failures.append("%s README row lacks URL, author and licence: %s" % [type, line.left(80)])
			continue
		var file := str(parts[0]).trim_prefix("- `").trim_suffix("`")
		documented[file] = true
		var url := str(parts[1]).to_lower()
		var licence := str(parts[3]).strip_edges()
		if file == "front.jpg":
			front = true
		if not url.begins_with("https://commons.wikimedia.org/wiki/file:"):
			failures.append("%s %s is not a Commons file page: %s" % [type, file, url.left(70)])
		for host in BAD_HOSTS:
			if url.contains(host):
				failures.append("%s %s uses a blocked host %s" % [type, file, host])
		for word in BAD_WORDS:
			if url.get_slice("file:", 1).contains(word):
				failures.append("%s %s looks like an interior or map ('%s' in the title)" % [type, file, word])
		var ok := false
		for l in LICENCE:
			if licence.begins_with(l):
				ok = true
		if not ok:
			failures.append("%s %s licence '%s' is not CC BY / BY-SA / CC0 / PD" % [type, file, licence])
	for f in jpgs:
		if not documented.has(f):
			failures.append("%s/%s has no README row (URL, author, licence)" % [type, f])
	if rows > 0 and not front:
		failures.append("%s README has no front.jpg row" % type)
