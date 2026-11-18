extends SceneTree

## ShoreCoast joins (offline): godot --headless --script tests/shore_coast_join_test.gd
## Coastline pieces from two sources (a live detailed layer and a bundled
## ring layer) can disagree by centimetres at a shared node. They must
## still join into one run, or the open sea is dropped and the harbour
## turns to ground (Helsinki, 2026-11-14). A real gap must still be
## refused.

var failures: Array[String] = []
const BOX := Rect2(-100, -100, 200, 200)

func _init() -> void:
	var m := WorldScale.metres_to_units()
	# One straight coast x = 0 running north to south (water to the west),
	# split at z = 0; the second piece starts `offset` metres off.
	for case in [[0.0, true], [0.03, true], [0.06, true], [1.0, false]]:
		var offset: float = case[0]
		var joins: bool = case[1]
		var diagnostics: Array = []
		var coasts := ShoreCoast.domains([
			{"class": "coastline", "points": PackedVector2Array([Vector2(0, -100) * m, Vector2(0, 0)])},
			{"class": "coastline", "points": PackedVector2Array([Vector2(offset, offset) * m, Vector2(0, 100) * m])}],
			Rect2(BOX.position * m, BOX.size * m), diagnostics)
		var open := diagnostics.filter(func(d: Dictionary) -> bool: return d.get("kind", "") == "open_coastline")
		if joins:
			_check(open.is_empty() and not coasts.is_empty(),
				"pieces %.2f m apart must join into one coast (%d open)" % [offset, open.size()])
			var wet := false
			var dry := false
			for coast in coasts:
				var index := PolygonIndex.new(coast["points"], coast["holes"])
				wet = wet or index.contains(Vector2(50, 0) * m) or index.contains(Vector2(-50, 0) * m)
				dry = dry or not (index.contains(Vector2(50, 0) * m) and index.contains(Vector2(-50, 0) * m))
			_check(wet and dry, "a joined coast must divide the extent (%.2f m)" % offset)
		else:
			_check(not open.is_empty() and coasts.is_empty(), "a %.1f m gap must stay an open coastline" % offset)
	# An island ring in two pieces whose closing node is 6 cm apart.
	var ring_diag: Array = []
	var island := ShoreCoast.domains([
		{"class": "coastline", "points": PackedVector2Array([Vector2(-10, -10) * m, Vector2(-10, 10) * m, Vector2(10, 10) * m])},
		{"class": "coastline", "points": PackedVector2Array([Vector2(10, 10) * m, Vector2(10, -10) * m, Vector2(-9.95, -9.97) * m])}],
		Rect2(BOX.position * m, BOX.size * m), ring_diag)
	_check(ring_diag.filter(func(d: Dictionary) -> bool: return d.get("kind", "") == "open_coastline").is_empty()
		and not island.is_empty(), "a ring closing within centimetres must close")
	if failures.is_empty():
		print("SHORE COAST JOIN OK: centimetre mismatches join, real gaps stay open")
		quit(0)
	else:
		for f in failures:
			printerr("SHORE COAST JOIN FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)
