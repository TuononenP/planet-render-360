extends SceneTree

## Headless: godot --headless --script tests/dem_despike_test.gd
## DEM spike removal: a walled tower goes and meets the ground around it, while
## a real peak, a real cliff and places outside the ArcticDEM source stay.

const SIZE := 240
const MPP := 30.0

var failures: Array[String] = []

func _init() -> void:
	_tower_removed()
	_ramped_rim_removed()
	_real_peak_kept()
	_cliff_kept()
	_broad_massif_kept()
	_south_untouched()
	if failures.is_empty():
		print("DEM DESPIKE OK: spikes removed, peaks, cliffs and southern places kept")
		quit(0)
	else:
		for f in failures:
			printerr("DEM DESPIKE FAIL: ", f)
		quit(1)

func _ring(height: Callable) -> Dictionary:
	var heights := PackedFloat32Array()
	heights.resize(SIZE * SIZE)
	for y in SIZE:
		for x in SIZE:
			heights[y * SIZE + x] = height.call(float(x), float(y))
	return {"zoom": 12, "origin_px": Vector2(4000, 4000), "width": SIZE, "height": SIZE, "heights": heights}

## Rolling ground, about 100 m.
func _ground(x: float, y: float) -> float:
	return 100.0 + 6.0 * sin(x * 0.03) + 4.0 * cos(y * 0.04)

func _at(ring: Dictionary, x: int, y: int) -> float:
	return (ring["heights"] as PackedFloat32Array)[y * SIZE + x]

func _changed(ring: Dictionary, height: Callable) -> int:
	var n := 0
	for y in SIZE:
		for x in SIZE:
			if absf(_at(ring, x, y) - float(height.call(float(x), float(y)))) > 0.01:
				n += 1
	return n

func _tower(x: float, y: float) -> float:
	return _ground(x, y) + (700.0 if Vector2(x, y).distance_to(Vector2(120, 120)) < 8.0 else 0.0)

func _tower_removed() -> void:
	var ring := _ring(_tower)
	var replaced := DemDespike.clean(ring, MPP)
	if replaced < 150:
		failures.append("a walled tower should be replaced, got %d pixels" % replaced)
	if absf(_at(ring, 120, 120) - _ground(120, 120)) > 12.0:
		failures.append("a spike should meet the ground, got %.1f m" % _at(ring, 120, 120))
	if not is_equal_approx(_at(ring, 40, 40), _ground(40, 40)):
		failures.append("ground away from the spike must not change")

## Resampling ramps a spike's rim over a pixel or two: those go as well.
func _ramped_rim_removed() -> void:
	var ramped := func(x: float, y: float) -> float:
		var d := Vector2(x, y).distance_to(Vector2(120, 120))
		return _ground(x, y) + 700.0 * clampf((9.0 - d) / 2.0, 0.0, 1.0)
	var ring := _ring(ramped)
	DemDespike.clean(ring, MPP)
	for x in range(108, 133):
		if _at(ring, x, 120) > _ground(float(x), 120.0) + 40.0:
			failures.append("a ramped rim must not survive at x=%d: %.1f m" % [x, _at(ring, x, 120)])
			break

## A peak climbs over many pixels and has no step to start from.
func _real_peak_kept() -> void:
	var peak := func(x: float, y: float) -> float:
		var d := Vector2(x, y).distance_to(Vector2(120, 120))
		return _ground(x, y) + 800.0 * exp(-d * d / 400.0)
	if DemDespike.clean(_ring(peak), MPP) != 0:
		failures.append("a real peak must be kept")

## A cliff's high side runs on into the land.
func _cliff_kept() -> void:
	var cliff := func(x: float, y: float) -> float:
		return _ground(x, y) + (400.0 if x > 120.0 else 0.0)
	var ring := _ring(cliff)
	DemDespike.clean(ring, MPP)
	if _changed(ring, cliff) != 0:
		failures.append("a one-sided cliff must be kept")

## Steep on all sides but far wider than it is tall: a massif, not a spike.
func _broad_massif_kept() -> void:
	var massif := func(x: float, y: float) -> float:
		return _ground(x, y) + (300.0 if Vector2(x, y).distance_to(Vector2(120, 120)) < 14.0 else 0.0)
	var ring := _ring(massif)
	DemDespike.clean(ring, MPP)
	if _changed(ring, massif) != 0:
		failures.append("a broad massif must be kept")

func _south_untouched() -> void:
	if DemDespike.clean_rings([_ring(_tower)], 46.7) != 0:
		failures.append("places outside the ArcticDEM source must be left alone")
