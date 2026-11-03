extends SceneTree

const Source = preload("res://scripts/data/landcover_source.gd")

func _init() -> void:
	var failures: Array[String] = []
	var paris := Source.worldcover(48.8566, 2.3522)
	if paris.get("tile") != "N48E000" or not str(paris.get("url", "")).ends_with("N48E000_Map.tif"):
		failures.append("Paris WorldCover tile: %s" % paris)
	if Source.worldcover(-0.01, -0.01).get("tile") != "S03W003" \
			or Source.worldcover(0.0, 0.0).get("tile") != "N00E000":
		failures.append("WorldCover negative-coordinate tile boundaries")
	var canopy := Source.canopy(48.8566, 2.3522)
	if canopy.get("tile") != "1202200110":
		failures.append("Paris canopy quadkey: %s" % canopy)
	if not Source.canopy(86.0, 0.0).is_empty() or not Source.worldcover(90.0, 0.0).is_empty() \
			or not Source.worldcover(0.0, 180.0).is_empty():
		failures.append("out-of-range coordinates must fail closed")
	for place in [paris, canopy, Source.worldcover(-89.0, -179.0), Source.canopy(0.0, 0.0)]:
		var pixel: Vector2i = place.get("pixel", Vector2i(-1, -1))
		if pixel.x < 0 or pixel.y < 0:
			failures.append("pixel should lie within its source tile: %s" % place)
	if failures.is_empty():
		print("LANDCOVER SOURCE OK: geographic tiles, Mercator quadkeys and boundaries")
		quit(0)
	else:
		for failure in failures:
			printerr("LANDCOVER SOURCE FAIL: ", failure)
		quit(1)
