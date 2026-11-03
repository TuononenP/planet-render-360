extends SceneTree

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	var pipeline := GenerationPipeline.new()
	root.add_child(pipeline)
	await process_frame
	var cover := Image.create_from_data(1, 1, false, Image.FORMAT_L8, PackedByteArray([50]))
	var canopy := Image.create_from_data(1, 1, false, Image.FORMAT_L8, PackedByteArray([12]))
	pipeline._sat_done = true
	pipeline._inner_done = true
	pipeline._landcover_done = true
	pipeline._landcover_image = cover
	pipeline._canopy_image = canopy
	var data := LocationData.new()
	await pipeline._await_satellite(data)
	if data.landcover_image != cover or data.canopy_image != canopy:
		failures.append("Imagery stage must carry both optional raster images")
	pipeline._landcover.fetch(48.8566, 2.3522)
	pipeline.cancel()
	if not pipeline._cancelled or pipeline._landcover._generation < 2:
		failures.append("pipeline cancellation must cancel raster requests")
	pipeline.queue_free()
	await process_frame
	if failures.is_empty():
		print("LANDCOVER PIPELINE OK: imagery handoff and cancellation")
		quit(0)
	else:
		for failure in failures:
			printerr("LANDCOVER PIPELINE FAIL: ", failure)
		quit(1)
