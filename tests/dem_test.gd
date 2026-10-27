extends SceneTree

## Headless live-source test: godot --headless --script tests/dem_test.gd
## Requires network on first run; afterwards the tile cache serves it.
## Asserts the Terrarium decode yields plausible Paris elevations.

var _done := false
var _ok := false
var _reason := ""

func _init() -> void:
	_run()

func _run() -> void:
	# Tile math is pure and runs offline.
	var tile := DemFetcher.tile_xy(48.8566, 2.3522, 12)
	if tile != Vector2i(2074, 1409):
		printerr("DEM FAIL: unexpected Paris tile ", tile)
		quit(1)
		return

	var fetcher := DemFetcher.new()
	root.add_child(fetcher)
	await process_frame
	fetcher.succeeded.connect(func(heights: PackedFloat32Array, grid: int) -> void:
		var mn := heights[0]
		var mx := heights[0]
		for h in heights:
			mn = minf(mn, h)
			mx = maxf(mx, h)
		_ok = grid == 48 and heights.size() == 48 * 48 \
			and mn > -50.0 and mx < 600.0 and mx - mn > 5.0
		_reason = "range %.1f..%.1f m" % [mn, mx]
		_done = true)
	fetcher.failed.connect(func(reason: String) -> void:
		_reason = reason
		_done = true)
	fetcher.fetch(48.8566, 2.3522, 48)

	var waited := 0.0
	while not _done and waited < 20.0:
		await process_frame
		waited += 1.0 / 60.0

	if _ok:
		print("DEM OK: Paris tile decoded, ", _reason)
		quit(0)
	else:
		printerr("DEM FAIL: ", _reason if _reason != "" else "timeout")
		quit(1)
