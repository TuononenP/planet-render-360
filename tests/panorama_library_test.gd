extends SceneTree

## Headless: godot --headless --script tests/panorama_library_test.gd
## PanoramaLibrary: index round-trip, ordering, dedupe import, heading
## parsing, pruning, corrupt index, delete. All in a temp dir_override.

var _failures: Array[String] = []
const DIR := "user://panorama-library-test"

func _init() -> void:
	_run()

func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)

func _bytes(color: Color, heading: float) -> PackedByteArray:
	var img := Image.create(64, 32, false, Image.FORMAT_RGB8)
	img.fill(color)
	return PanoramaCapture.encode(img, heading)

func _clean() -> void:
	if not DirAccess.dir_exists_absolute(DIR):
		return
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))
	if DirAccess.dir_exists_absolute(DIR.path_join("thumbs")):
		for f in DirAccess.get_files_at(DIR.path_join("thumbs")):
			DirAccess.remove_absolute(DIR.path_join("thumbs").path_join(f))
		DirAccess.remove_absolute(DIR.path_join("thumbs"))
	DirAccess.remove_absolute(DIR)

func _run() -> void:
	PanoramaLibrary.dir_override = DIR
	PhotoMode.dir_override = DIR + "-fallback"
	_clean()
	DirAccess.make_dir_recursive_absolute(DIR)

	# Heading reader: round-trip, wrap, junk.
	_check(is_equal_approx(PanoramaCapture.heading_from_jpeg(_bytes(Color.RED, -90.0)), 270.0), "heading -90 wraps to 270")
	_check(is_equal_approx(PanoramaCapture.heading_from_jpeg(_bytes(Color.RED, 42.5)), 42.5), "heading round-trip")
	_check(PanoramaCapture.heading_from_jpeg(PackedByteArray([1, 2, 3])) == 0.0, "heading junk is 0")
	# Attribute-form XMP (other writers), no XMP, non-float value.
	var plain := Image.create(16, 8, false, Image.FORMAT_RGB8)
	plain.fill(Color.WHITE)
	var plain_jpg := plain.save_jpg_to_buffer(0.9)
	_check(PanoramaCapture.heading_from_jpeg(plain_jpg) == 0.0, "heading no XMP is 0")
	var attr_jpg := PanoramaCapture.with_xmp(plain_jpg,
		'<x:xmpmeta><rdf:Description GPano:PoseHeadingDegrees="123.5"/></x:xmpmeta>')
	_check(is_equal_approx(PanoramaCapture.heading_from_jpeg(attr_jpg), 123.5), "heading attribute form")
	var bad_jpg := PanoramaCapture.with_xmp(plain_jpg,
		'<x:xmpmeta><rdf:Description GPano:PoseHeadingDegrees="abc"/></x:xmpmeta>')
	_check(PanoramaCapture.heading_from_jpeg(bad_jpg) == 0.0, "heading non-float is 0")

	# Empty library / invalid inputs on a fresh dir.
	_check(PanoramaLibrary.entries().is_empty(), "fresh entries empty")
	_check(PanoramaLibrary.add(PackedByteArray(), "X", 0, 0, 0, {}).is_empty(), "add empty bytes fails")
	_check(not PanoramaLibrary.remove({}), "remove empty fails")
	_check(PanoramaLibrary.texture_for({"file": "nope.jpg"}) == null, "texture missing is null")

	# Add two, newest first.
	var older := PanoramaLibrary.add(_bytes(Color.RED, 10.0), "Paris, France", 48.85, 2.35, 10.0,
		{"year": 2026, "month": 11, "day": 1, "hour": 17, "minute": 30})
	var newer := PanoramaLibrary.add(_bytes(Color.BLUE, 20.0), "Rome, Italy", 41.9, 12.5, 20.0,
		{"year": 2026, "month": 11, "day": 2, "hour": 9, "minute": 15})
	_check(not older.is_empty() and not newer.is_empty(), "add returns entries")
	var rows := PanoramaLibrary.entries()
	_check(rows.size() == 2, "two entries, got %d" % rows.size())
	if rows.size() == 2:
		_check(str(rows[0].get("place", "")) == "Rome, Italy", "newest first")
		_check(int(rows[0].get("width", 0)) == 64 and int(rows[0].get("bytes", 0)) > 0, "size recorded")
	_check(FileAccess.file_exists(PanoramaLibrary.path_for(older)), "jpeg on disk")
	_check(FileAccess.file_exists(PanoramaLibrary.thumb_path_for(older)), "thumb on disk")
	# A missing thumb is not replaced by a full decode; rebuild_thumb restores it.
	DirAccess.remove_absolute(PanoramaLibrary.thumb_path_for(older))
	_check(PanoramaLibrary.thumb_texture(older) == null and not PanoramaLibrary.has_thumb(older),
		"missing thumb gives null, not the full panorama")
	_check(PanoramaLibrary.rebuild_thumb(older) and PanoramaLibrary.thumb_texture(older) != null,
		"rebuild_thumb restores the thumbnail")
	_check(not PanoramaLibrary.rebuild_thumb({"file": "gone.jpg"}), "rebuild_thumb on a missing file fails")

	# Index round-trip: exact stored fields, read from index.json itself.
	var idx: Variant = JSON.parse_string(FileAccess.get_file_as_string(PanoramaLibrary.index_path()))
	_check(idx is Dictionary and (idx as Dictionary).get("entries") is Array, "index.json parses")
	if idx is Dictionary:
		var paris: Array = (idx["entries"] as Array).filter(
			func(e: Dictionary) -> bool: return str(e.get("place", "")) == "Paris, France")
		if paris.size() == 1:
			_check(is_equal_approx(float(paris[0].get("lat", 0.0)), 48.85)
				and is_equal_approx(float(paris[0].get("lon", 0.0)), 2.35)
				and is_equal_approx(float(paris[0].get("heading_deg", 0.0)), 10.0)
				and int(paris[0].get("height", 0)) == 32
				and float(paris[0].get("timestamp", 0.0)) > 0.0, "index fields exact")

	# Re-adding identical bytes is idempotent; different bytes in the
	# same minute are kept under a disambiguated name, not overwritten.
	PanoramaLibrary.add(_bytes(Color.RED, 10.0), "Paris, France", 48.85, 2.35, 10.0,
		{"year": 2026, "month": 11, "day": 1, "hour": 17, "minute": 30})
	_check(PanoramaLibrary.entries().size() == 2, "identical re-add idempotent")
	var second_shot := PanoramaLibrary.add(_bytes(Color.GREEN, 33.0), "Paris, France", 48.85, 2.35, 33.0,
		{"year": 2026, "month": 11, "day": 1, "hour": 17, "minute": 30})
	_check(not second_shot.is_empty() and str(second_shot.get("file", "")) != str(older.get("file", "")),
		"same-minute collision disambiguated: %s" % second_shot.get("file", ""))
	_check(PanoramaLibrary.entries().size() == 3, "collision keeps both")
	_check(FileAccess.get_file_as_bytes(PanoramaLibrary.path_for(older)) == _bytes(Color.RED, 10.0),
		"first capture not overwritten")

	# Parse file name.
	var meta := PanoramaLibrary.parse_file_name("planet-render-360_paris-france_360_20261101-1730.jpg")
	_check(str(meta.get("place", "")) == "Paris France", "parse place: %s" % meta)
	_check(float(meta.get("timestamp", 0.0)) > 0.0, "parse timestamp")

	# Import from fallback dir: one new, then dedupe.
	DirAccess.make_dir_recursive_absolute(PhotoMode.dir_override)
	var f := FileAccess.open(PhotoMode.fallback_dir().path_join(
		"planet-render-360_kyoto-japan_360_20261001-0800.jpg"), FileAccess.WRITE)
	f.store_buffer(_bytes(Color.YELLOW, 99.0))
	f.close()
	_check(PanoramaLibrary.import_existing() == 1, "import one")
	_check(PanoramaLibrary.import_existing() == 0, "import dedupe")
	var imported: Array = PanoramaLibrary.entries().filter(
		func(e: Dictionary) -> bool: return str(e.get("place", "")).contains("Kyoto"))
	_check(imported.size() == 1, "imported row present")
	if imported.size() == 1:
		_check(is_equal_approx(float(imported[0].get("heading_deg", 0.0)), 99.0), "imported heading from XMP")

	# Prune a missing file: count drops by exactly one, victim gone.
	var all_before := PanoramaLibrary.entries()
	var victim: Dictionary = all_before[0]
	var victim_file := str(victim.get("file", ""))
	DirAccess.remove_absolute(PanoramaLibrary.path_for(victim))
	var pruned := PanoramaLibrary.entries()
	_check(pruned.size() == all_before.size() - 1, "prune drops one: %d -> %d" % [all_before.size(), pruned.size()])
	_check(pruned.filter(func(e: Dictionary) -> bool: return str(e.get("file", "")) == victim_file).is_empty(),
		"pruned victim absent")

	# Corrupt index degrades to scan: exact remaining set, backup kept,
	# and the rebuilt index is persisted (self-repair).
	var expected_files := {}
	for e in pruned:
		expected_files[str(e.get("file", ""))] = true
	AtomicFile.write_text(PanoramaLibrary.index_path(), "{not json")
	var scanned := PanoramaLibrary.entries()
	_check(scanned.size() == expected_files.size(), "corrupt scan count: %d vs %d" % [scanned.size(), expected_files.size()])
	_check(scanned.all(func(e: Dictionary) -> bool: return expected_files.has(str(e.get("file", "")))),
		"corrupt scan identities")
	_check(FileAccess.file_exists(PanoramaLibrary.index_path() + ".bak"), "corrupt index backed up")
	var repaired: Variant = JSON.parse_string(FileAccess.get_file_as_string(PanoramaLibrary.index_path()))
	_check(repaired is Dictionary and (repaired as Dictionary).get("entries") is Array,
		"rebuilt index persisted")

	# Deleting an imported photo must not resurrect it on re-import.
	var kyoto: Array = PanoramaLibrary.entries().filter(
		func(e: Dictionary) -> bool: return str(e.get("place", "")).contains("Kyoto"))
	_check(kyoto.size() == 1, "kyoto present before delete")
	if kyoto.size() == 1:
		_check(PanoramaLibrary.remove(kyoto[0]), "remove imported")
		_check(PanoramaLibrary.import_existing() == 0, "deleted import not resurrected")
		_check(PanoramaLibrary.entries().filter(
			func(e: Dictionary) -> bool: return str(e.get("place", "")).contains("Kyoto")).is_empty(),
			"kyoto stays gone")

	# Remove deletes file + thumb + row.
	var target: Dictionary = PanoramaLibrary.entries()[0]
	var tp := PanoramaLibrary.path_for(target)
	var tt := PanoramaLibrary.thumb_path_for(target)
	_check(PanoramaLibrary.remove(target), "remove true")
	_check(not FileAccess.file_exists(tp) and not FileAccess.file_exists(tt), "remove deletes files")
	_check(not PanoramaLibrary.remove(target), "remove again false")

	PanoramaLibrary.dir_override = ""
	PhotoMode.dir_override = ""
	_clean()
	if DirAccess.dir_exists_absolute(DIR + "-fallback"):
		for fn in DirAccess.get_files_at(DIR + "-fallback"):
			DirAccess.remove_absolute((DIR + "-fallback").path_join(fn))
		DirAccess.remove_absolute(DIR + "-fallback")
	if _failures.is_empty():
		print("PANORAMA LIBRARY OK: index, ordering, import, heading, prune, corrupt, delete")
		quit(0)
	else:
		for f2 in _failures:
			printerr("PANORAMA LIBRARY FAIL: ", f2)
		quit(1)
