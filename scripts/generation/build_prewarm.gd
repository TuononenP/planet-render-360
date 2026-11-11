class_name BuildPrewarm
extends RefCounted

## Fills the process-wide texture caches every world build reads, while
## the pipeline still waits on the network (GenerationPipeline starts it
## with the fetches and waits for it before emitting `finished`). Only
## content-keyed caches the build would fill itself, so the world is
## unchanged; only where the time is spent moves.

## PBR sets the build requests on every place, from code constants: road
## paving and decks, trims, roofline details, street props, slate.
const SETS: Array[String] = ["pavement", "concrete", "limestone", "brick",
	"terracotta", "slate"]

## What the last world build read, kept between sessions: the first
## build after a launch spent 5-6 s of its buildings stage loading 2K
## PBR maps and composing facades (Paris and Helsinki on Ultra).
const REMEMBERED := "user://build_prewarm.var"
const VERSION := 1

## Runs on a WorkerThreadPool thread; every cache it touches is locked.
static func run(preset: int) -> void:
	TerrainTextures.arrays(TerrainTextures.size_for(preset))
	# Fast keeps its prewarm small (albedo only); other maps load on demand.
	var maps: Array[String] = ["diff"]
	if preset > RenderSettings.Preset.FAST:
		maps.append_array(["nor", "rough"])
	# The size this build will ask for: MaterialLibrary.hi_res still holds
	# the last build's (the first Ultra build warmed the 1K files).
	var hi_res := RenderQuality.ultra_desktop(preset)
	var last := _remembered()
	var jobs := {}  # "set:map" -> also as a texture
	for set_name in SETS:
		for map_name in maps:
			jobs[set_name + ":" + map_name] = false
	for key: String in last.get("images", PackedStringArray()):
		if key.get_slice(":", 1) in maps and MaterialLibrary.PBR_SETS.has(key.get_slice(":", 0)):
			jobs[key] = false
	for key: String in last.get("textures", PackedStringArray()):
		if jobs.has(key):
			jobs[key] = true
	var keys := jobs.keys()
	var group := WorkerThreadPool.add_group_task(func(i: int) -> void:
		var set_name := str(keys[i]).get_slice(":", 0)
		var map_name := str(keys[i]).get_slice(":", 1)
		if jobs[keys[i]]:
			PbrTextures._set_tex(set_name, map_name, hi_res)
		else:
			PbrTextures._set_image(set_name, map_name, hi_res), keys.size(), -1, true, "BuildPrewarm")
	WorkerThreadPool.wait_for_group_task_completion(group)
	if preset > RenderSettings.Preset.FAST:
		FacadeTextures.prewarm(last.get("recipes", PackedStringArray()),
			func(set_name: String, map_name: String) -> Image:
				return PbrTextures._set_image(set_name, map_name, hi_res))

## Records what the build that just finished read, for the next launch.
## Not in headless runs (tests, tools), which keep no built world either.
static func remember() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var images := PackedStringArray()
	for key: String in MaterialLibrary._set_images:
		if not key.begins_with("warned:"):
			images.append(key.get_slice(":", 0) + ":" + key.get_slice(":", 1))
	var textures := PackedStringArray()
	for key: String in MaterialLibrary._set_texs:
		textures.append(key.get_slice(":", 1) + ":" + key.get_slice(":", 2))
	var f := FileAccess.open(REMEMBERED, FileAccess.WRITE)
	if f != null:
		f.store_var({"version": VERSION, "images": images, "textures": textures,
			"recipes": FacadeTextures.recipes()})

static func _remembered() -> Dictionary:
	if not FileAccess.file_exists(REMEMBERED):
		return {}
	var f := FileAccess.open(REMEMBERED, FileAccess.READ)
	var v: Variant = f.get_var() if f != null else null
	return v if v is Dictionary and int((v as Dictionary).get("version", 0)) == VERSION else {}
