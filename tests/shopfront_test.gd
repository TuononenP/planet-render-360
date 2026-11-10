extends SceneTree

## Headless: godot --headless --script tests/shopfront_test.gd
## Shopfront frames stand on the columns the shop paint draws: mullions on the
## pane edges and centre, door jambs on the door, a riser only under a window.

const STEP := 3.2
const HEIGHT := 3.8
const C := 128.0

var failures: Array[String] = []

func _init() -> void:
	_window_bay()
	_door_bay()
	_inside_the_bay()
	if failures.is_empty():
		print("SHOPFRONT OK: frames on painted columns, doors, risers, inside the bay")
		quit(0)
	else:
		for f in failures:
			printerr("SHOPFRONT FAIL: ", f)
		quit(1)

## Pieces whose x span (in paint pixels) starts at `px`.
func _at(pieces: Array, px: float) -> Array:
	return pieces.filter(func(p: Array) -> bool: return absf(float(p[0]) / STEP * C - px) < 0.5)

func _window_bay() -> void:
	var pieces := StreetFront.shopfront_pieces(STEP, HEIGHT, false, 16)
	if _at(pieces, 6.0).is_empty() or _at(pieces, 119.0).is_empty() or _at(pieces, 63.0).is_empty():
		failures.append("a window bay needs its painted jambs and centre mullion")
	var riser := pieces.filter(func(p: Array) -> bool: return float(p[2]) < 0.001 and float(p[1]) - float(p[0]) > STEP * 0.8)
	if riser.size() != 1:
		failures.append("a window bay needs one stall riser at the pavement, got %d" % riser.size())
	# The fascia is 16 px deep under its cornice at 10 px from the top.
	var cornice := pieces.filter(func(p: Array) -> bool: return absf(float(p[3]) - (C - 8.0) / C * HEIGHT) < 0.01)
	if cornice.is_empty():
		failures.append("the fascia cornice must sit at the painted fascia top")

func _door_bay() -> void:
	var pieces := StreetFront.shopfront_pieces(STEP, HEIGHT, true, 16)
	if _at(pieces, 40.0).is_empty() or _at(pieces, 84.0).is_empty():
		failures.append("a door bay needs its painted jambs")
	if pieces.any(func(p: Array) -> bool: return float(p[2]) < 0.001 and float(p[1]) - float(p[0]) > STEP * 0.8):
		failures.append("a door has no stall riser across it")
	if _at(pieces, 40.0)[0][2] > 0.001:
		failures.append("door jambs reach the pavement")

func _inside_the_bay() -> void:
	for door in [false, true]:
		for p: Array in StreetFront.shopfront_pieces(STEP, HEIGHT, door, 30):
			if float(p[0]) < 0.0 or float(p[1]) > STEP or float(p[2]) < 0.0 or float(p[3]) > HEIGHT:
				failures.append("a frame leaves its bay: %s" % [p])
			if float(p[1]) <= float(p[0]) or float(p[3]) <= float(p[2]):
				failures.append("a frame has no size: %s" % [p])
