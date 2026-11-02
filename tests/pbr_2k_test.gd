extends SceneTree

## Headless: godot --headless --script tests/pbr_2k_test.gd
## Desktop Ultra's 2K photo sets (Phase 6): PbrTextures.map_path picks
## assets/textures/2k/ only on a hi-res build and only where the 2K file is
## bundled (the terrain sets stay 1K), and a 2K image really is 2048 px.

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	for s in ["limestone", "stone", "render", "brick", "concrete", "wood", "slate",
			"terracotta", "membrane", "asphalt", "pavement"]:
		for map_name in ["diff", "nor", "rough"]:
			if not PbrTextures.map_path(s, map_name, true).contains("/2k/"):
				failures.append("%s_%s should resolve to its 2K file on Ultra" % [s, map_name])
			if PbrTextures.map_path(s, map_name, false).contains("/2k/"):
				failures.append("%s_%s should stay 1K off Ultra" % [s, map_name])
	if PbrTextures.map_path("lawn", "diff", true).contains("/2k/"):
		failures.append("a set with no 2K file should fall back to 1K")
	MaterialLibrary.hi_res = true
	var hi := PbrTextures._set_image("brick", "diff")
	MaterialLibrary.hi_res = false
	var lo := PbrTextures._set_image("brick", "diff")
	if hi.get_width() != 2048 or lo.get_width() != 1024:
		failures.append("brick photo sizes %d (Ultra) / %d (else), want 2048 / 1024" % [hi.get_width(), lo.get_width()])
	failures.erase(failures[0])
	if failures.is_empty():
		print("PBR 2K OK: 2K sets on Ultra builds only, 1K fallback, real 2048 px")
		quit(0)
	else:
		for f in failures:
			printerr("PBR 2K FAIL: ", f)
		quit(1)
