extends SceneTree

## Tile tests: godot --headless --script tests/tiles_test.gd
## 1) Offline web-mercator roundtrip. 2) Live pool drain: a 3x3 tile grid
## must fully arrive (cached tiles count too) — guards the queue/pump.

var _ready_count := 0

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	for coords in [[48.8566, 2.3522], [46.6863, 7.8632], [-33.8688, 151.2093], [0.0, 0.0]]:
		var px := TileFetcher.global_pixel(coords[0], coords[1], 12)
		var back := TileFetcher.lat_lon_from_pixel(px, 12)
		if absf(back.x - coords[0]) > 0.001 or absf(back.y - coords[1]) > 0.001:
			failures.append("roundtrip drift %s -> %s" % [coords, back])
	if TileFetcher.global_pixel(0, 0, 1) != Vector2(256, 256):
		failures.append("origin pixel at z1 should be (256,256)")
	if not failures.is_empty():
		for f in failures:
			printerr("TILES FAIL: ", f)
		quit(1)
		return

	var fetcher := TileFetcher.new()
	root.add_child(fetcher)
	await process_frame
	fetcher.tile_ready.connect(func(_z: int, _x: int, _y: int, _t: Texture2D) -> void:
		_ready_count += 1)
	var centre := DemFetcher.tile_xy(48.8566, 2.3522, 12)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			fetcher.request_tile(12, centre.x + dx, centre.y + dy)
	var waited := 0.0
	while _ready_count < 9 and waited < 40.0:
		await process_frame
		waited += 1.0 / 60.0
	if _ready_count >= 9:
		print("TILES OK: mercator roundtrip + 3x3 tile pool drain (%d)" % _ready_count)
		quit(0)
	else:
		printerr("TILES FAIL: only %d/9 tiles arrived" % _ready_count)
		quit(1)
