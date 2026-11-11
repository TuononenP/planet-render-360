extends SceneTree

## Headless: godot --headless --script tests/bridge_connection_test.gd
## A bridge way mapped shorter than the rendered water it crosses (the
## Katajanokka canal crossings in Helsinki are 11-15 m ways over a wider
## carved channel) must still land on dry ground at both ends: the deck
## is stitched along its connected approach ways until it reaches the
## bank, and an unconnected bridge way is extended straight to the bank.
## Before the fix the deck ended mid-water and the wet approach pieces
## were dropped, leaving a floating slab with a gap at each end.

const HALF := 20.0  # water strip is 2*HALF wide, bridge way is shorter

func _init() -> void:
	var failures: Array[String] = []
	_check(failures, _split_data(), "split ways (connected approaches)", HALF + 20.0)
	_check(failures, _lone_data(), "lone bridge way (straight extension)", HALF + 4.0)
	_check(failures, _linked_data(), "two bridge pieces across a wet link way", HALF + 2.0)
	_check_pier(failures)
	if failures.is_empty():
		print("BRIDGE CONNECTION OK: decks land on both banks, connected and unconnected")
		quit(0)
	else:
		for f in failures:
			printerr("BRIDGE CONNECTION FAIL: ", f)
		quit(1)

## Bridge way spans only the middle half of the channel; its (non-bridge)
## approaches share its end nodes and cross the rest of the water.
func _split_data() -> LocationData:
	var d := _base()
	d.roads = [
		{"class": "secondary", "width_m": 10.0, "lanes": 2, "bridge": false,
			"points": PackedVector2Array([Vector2(-HALF - 80.0, 0.0), Vector2(-HALF + 10.0, 0.0)])},
		{"class": "secondary", "width_m": 10.0, "lanes": 2, "bridge": true,
			"points": PackedVector2Array([Vector2(-HALF + 10.0, 0.0), Vector2(HALF - 10.0, 0.0)])},
		{"class": "secondary", "width_m": 10.0, "lanes": 2, "bridge": false,
			"points": PackedVector2Array([Vector2(HALF - 10.0, 0.0), Vector2(HALF + 80.0, 0.0)])},
	]
	return d

## No approach ways at all: the deck alone must reach both banks.
func _lone_data() -> LocationData:
	var d := _base()
	d.roads = [
		{"class": "secondary", "width_m": 10.0, "lanes": 2, "bridge": true,
			"points": PackedVector2Array([Vector2(-HALF + 10.0, 0.0), Vector2(HALF - 10.0, 0.0)])},
	]
	return d

## Two bridge pieces over one channel, joined only by a non-bridge
## link way over the water: each deck grows along the link until it
## meets the other piece, instead of both ending mid-water.
func _linked_data() -> LocationData:
	var d := _base()
	d.roads = [
		{"class": "footway", "width_m": 4.0, "lanes": 0, "bridge": true,
			"points": PackedVector2Array([Vector2(-HALF + 2.0, 0.0), Vector2(-2.0, 0.0)])},
		{"class": "footway", "width_m": 4.0, "lanes": 0, "bridge": false,
			"points": PackedVector2Array([Vector2(-2.0, 0.0), Vector2(2.0, 0.0)])},
		{"class": "footway", "width_m": 4.0, "lanes": 0, "bridge": true,
			"points": PackedVector2Array([Vector2(2.0, 0.0), Vector2(HALF - 2.0, 0.0)])},
	]
	return d

## A bridge whose far side is open water for hundreds of metres, with
## a pier way just past its end: the deck grows an apron to the pier.
func _pier_data() -> LocationData:
	var d := _base()
	d.land_polygons = [{"class": "water", "holes": [], "points": PackedVector2Array([
		Vector2(-300, -300), Vector2(300, -300), Vector2(300, 300), Vector2(-300, 300)])}]
	d.roads = [
		{"class": "secondary", "width_m": 10.0, "lanes": 2, "bridge": true,
			"points": PackedVector2Array([Vector2(-310.0, 0.0), Vector2(10.0, 0.0)])},
	]
	d.piers = [{"points": PackedVector2Array([Vector2(30.0, -40.0), Vector2(30.0, 40.0)]),
		"floating": false, "width_m": NAN}]
	return d

## The pier fixture's own check: continuous deck from the dry west
## end (x=-310) to the pier line (x=30), where the apron touches it.
func _check_pier(failures: Array[String]) -> void:
	var d := _pier_data()
	var ground := GroundTruth.new(d)
	var roads := RoadBuilder.build_roads(d, ground)
	var tris: Array = []
	for child in roads.get_children():
		if not (child is MeshInstance3D):
			continue
		var arr: Array = (child as MeshInstance3D).mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		for t in range(0, idx.size(), 3):
			tris.append([verts[idx[t]], verts[idx[t + 1]], verts[idx[t + 2]]])
	roads.free()
	var x := -300.0
	while x <= 30.0:
		if _surface_at(tris, Vector2(x, 0.0)) < -1e8:
			failures.append("pier apron: no deck over the centreline at x=%.0f" % x)
			return
		x += 5.0

func _base() -> LocationData:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.HIGH)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(3.0)
	d.water_level = 0.0
	d.seed_value = 7
	d.latitude = 60.168
	d.longitude = 24.953
	d.land_polygons = [{"class": "water", "holes": [], "points": PackedVector2Array([
		Vector2(-HALF, -300), Vector2(HALF, -300), Vector2(HALF, 300), Vector2(-HALF, 300)])}]
	return d

func _check(failures: Array[String], d: LocationData, label: String, cover: float) -> void:
	var ground := GroundTruth.new(d)
	var roads := RoadBuilder.build_roads(d, ground)
	var tris: Array = []
	for child in roads.get_children():
		if not (child is MeshInstance3D):
			continue
		var arr: Array = (child as MeshInstance3D).mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		for t in range(0, idx.size(), 3):
			tris.append([verts[idx[t]], verts[idx[t + 1]], verts[idx[t + 2]]])
	roads.free()
	if tris.is_empty():
		failures.append("%s: no road geometry built" % label)
		return
	# Continuous surface along the centreline, bank to bank and beyond.
	var x := -cover
	while x <= cover:
		var hit := _surface_at(tris, Vector2(x, 0.0))
		if hit < -1e8:
			failures.append("%s: no road surface over the centreline at x=%.0f (gap over water or bank)" % [label, x])
			return
		x += 2.0
	# Both deck ends stand on dry ground, near bank height (no hover).
	for bank_x in [-HALF - 4.0, HALF + 4.0]:
		var y := _surface_at(tris, Vector2(bank_x, 0.0))
		if y < -1e8:
			failures.append("%s: no surface just past the bank at x=%.0f" % [label, bank_x])
		elif y - 3.0 > 1.2:
			failures.append("%s: surface hovers %.2f m over the bank at x=%.0f" % [label, y - 3.0, bank_x])

## Y of the highest road triangle covering XZ, or -INF when none does.
func _surface_at(tris: Array, p: Vector2) -> float:
	var best := -INF
	for tri in tris:
		var a: Vector3 = tri[0]
		var b: Vector3 = tri[1]
		var c: Vector3 = tri[2]
		var d := (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
		if absf(d) < 1e-9:
			continue
		var u := ((b.z - c.z) * (p.x - c.x) + (c.x - b.x) * (p.y - c.z)) / d
		var v := ((c.z - a.z) * (p.x - c.x) + (a.x - c.x) * (p.y - c.z)) / d
		var w := 1.0 - u - v
		if u >= -1e-6 and v >= -1e-6 and w >= -1e-6:
			best = maxf(best, u * a.y + v * b.y + w * c.y)
	return best
