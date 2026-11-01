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

## Runs on a WorkerThreadPool thread; every cache it touches is locked.
static func run(preset: int) -> void:
	TerrainTextures.arrays(TerrainTextures.size_for(preset))
	# Fast keeps its prewarm small (albedo only); other maps load on demand.
	var maps: Array[String] = ["diff"]
	if preset > RenderSettings.Preset.FAST:
		maps.append_array(["nor", "rough"])
	for set_name in SETS:
		for map_name in maps:
			PbrTextures._set_image(set_name, map_name)
