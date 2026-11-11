extends SceneTree

## Headless: godot --headless --script tests/bridge_joint_test.gd
## Bridge end rules (BridgeLandings): two decks running side by side are
## separate structures, not a joint, while an end running into another
## deck's side (a T) or meeting it end to end is one; an approach way
## must head on from the bridge end, not along the bank; and an end
## over open water with no dry ground in reach keeps its mapped length
## instead of growing a phantom deck across the water.

func _init() -> void:
	var failures: Array[String] = []
	_joint_checks(failures)
	_approach_checks(failures)
	_open_water_checks(failures)
	if failures.is_empty():
		print("BRIDGE JOINT OK: twin decks, T joints, approaches, open-water ends")
		quit(0)
	else:
		for f in failures:
			printerr("BRIDGE JOINT FAIL: ", f)
		quit(1)

func _base(water: Rect2) -> LocationData:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.HIGH)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(3.0)
	d.water_level = 0.0
	d.seed_value = 7
	d.latitude = 60.168
	d.longitude = 24.953
	d.land_polygons = [{"class": "water", "holes": [], "points": PackedVector2Array([
		water.position, Vector2(water.end.x, water.position.y), water.end,
		Vector2(water.position.x, water.end.y)])}]
	return d

func _way(a: Vector2, b: Vector2, bridge: bool) -> Dictionary:
	return {"class": "secondary", "width_m": 10.0, "lanes": 2, "bridge": bridge,
		"points": PackedVector2Array([a, b])}

func _surface(d: LocationData) -> RoadBuilder._Surface:
	return RoadBuilder._Surface.new(d, GroundTruth.new(d))

func _joint_checks(failures: Array[String]) -> void:
	var d := _base(Rect2(-20, -300, 40, 600))
	d.roads = [
		# Twin decks 12 m apart, the second shorter so its ends project
		# onto the first's middle.
		_way(Vector2(-60, 0), Vector2(60, 0), true),
		_way(Vector2(-40, 12), Vector2(40, 12), true),
		# A ramp running into the first deck's side from the south.
		_way(Vector2(0, -50), Vector2(0, -6), true),
		# A deck continuing the first end to end, 1 m short.
		_way(Vector2(61, 0), Vector2(120, 0), true),
	]
	var surf := _surface(d)
	if BridgeLandings.joint(surf, Vector2(40, 12), Vector2(1, 0)):
		failures.append("a twin deck's end beside the other deck must not be a joint")
	if not BridgeLandings.joint(surf, Vector2(0, -6), Vector2(0, 1)):
		failures.append("an end running into another deck's side must be a joint")
	if not BridgeLandings.joint(surf, Vector2(60, 0), Vector2(1, 0)):
		failures.append("decks meeting end to end must be a joint")

func _approach_checks(failures: Array[String]) -> void:
	var d := _base(Rect2(-20, -300, 40, 600))
	d.roads = [
		_way(Vector2(-10, 0), Vector2(10, 0), true),
		# Only a quay path along the bank leaves the east end.
		_way(Vector2(10, 0), Vector2(10, 80), false),
	]
	var surf := _surface(d)
	if not BridgeLandings.approach_from(surf, Vector2(10, 0), Vector2(1, 0)).is_empty():
		failures.append("a way running along the bank is not the bridge's approach")
	d.roads.append(_way(Vector2(10, 0), Vector2(60, 0), false))
	surf = _surface(d)
	var ahead := BridgeLandings.approach_from(surf, Vector2(10, 0), Vector2(1, 0))
	if ahead.size() < 2 or ahead[ahead.size() - 1] != Vector2(60, 0):
		failures.append("the way heading on from the end is the approach: %s" % ahead)

func _open_water_checks(failures: Array[String]) -> void:
	# Dry land west of x=-1000; the bridge ends 1000 m into open water.
	var d := _base(Rect2(-1000, -1100, 2100, 2200))
	var piece := PackedVector2Array([Vector2(-1080, 0), Vector2(0, 0)])
	d.roads = [{"class": "secondary", "width_m": 10.0, "lanes": 2, "bridge": true, "points": piece}]
	var surf := _surface(d)
	var landed := BridgeLandings.landed(piece, piece, surf, WorldScale.metres_to_units())
	if landed.size() != piece.size() or landed[landed.size() - 1] != piece[piece.size() - 1]:
		failures.append("an end over open water must keep its mapped length, got %d points to %s"
			% [landed.size(), landed[landed.size() - 1]])
