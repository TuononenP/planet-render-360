extends SceneTree

## Packs downloaded tiles into the bundled MapPack files; run by
## tools/build_map_pack.sh:
##   godot --headless --path . --script tools/pack_map_tiles.gd -- SRC OMT_MAX DEM_MAX GLOBE_ZOOM
## SRC holds omt/, dem/ and osm/ files named z_x_y. A tile that is missing
## is left out of the pack (it streams at run time); prints the size of
## each zoom level.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 4:
		printerr("usage: -- SRC OMT_MAX DEM_MAX GLOBE_ZOOM")
		quit(2)
		return
	var src := args[0]
	var ok := _pack(src + "/omt", MapPack.OMT, 0, int(args[1]))
	ok = _pack(src + "/dem", MapPack.DEM, 0, int(args[2])) and ok
	ok = _pack(src + "/osm", MapPack.OSM, int(args[3]), int(args[3])) and ok
	quit(0 if ok else 1)

func _pack(dir: String, out: String, z_min: int, z_max: int) -> bool:
	var tiles := {}
	var missing := 0
	for z in range(z_min, z_max + 1):
		var bytes := 0
		var count := 0
		for x in 1 << z:
			for y in 1 << z:
				var path := "%s/%d_%d_%d" % [dir, z, x, y]
				if not FileAccess.file_exists(path):
					missing += 1
					continue
				var body := FileAccess.get_file_as_bytes(path)
				tiles[Vector3i(z, x, y)] = body
				bytes += body.size()
				count += 1
		print("%s z%d: %d tiles, %.1f MB" % [out.get_file(), z, count, bytes / 1048576.0])
	if missing > 0:
		push_warning("%s: %d tiles missing, they will stream" % [out.get_file(), missing])
	var err := MapPack.write(ProjectSettings.globalize_path(out), tiles)
	if err != OK:
		printerr("could not write %s: %s" % [out, error_string(err)])
		return false
	return true
