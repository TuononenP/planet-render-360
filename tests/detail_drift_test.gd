extends SceneTree

## Headless: godot --headless --script tests/detail_drift_test.gd
## Near detail follows the camera: DetailDrift asks for a world centred on
## a camera that stopped off the detail rings (still long enough, far
## enough for the preset), never on a moving or nearby one; a streamed
## world's detail eye is its centre, not a landmark's framing eye; and a
## centre built right where the camera stands is a swap the streamer takes.

var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

func _run() -> void:
	var m := WorldScale.metres_to_units()
	var ultra := int(RenderSettings.Preset.ULTRA)
	var high := int(RenderSettings.Preset.HIGH)
	var eye := Vector2(-631.0, 491.0) * m
	_check(DetailDrift.drift_m(high) >= DetailDrift.MIN_DRIFT_M, "High never rebuilds under MIN_DRIFT_M")
	_check(DetailDrift.drift_m(ultra) < FacadeRelief.radius_m(ultra),
		"Ultra rebuilds before the camera's neighbours leave the relief ring")
	var far := eye + Vector2(800.0, 0.0) * m
	_check(DetailDrift.wanted(far, eye, DetailDrift.STILL_S, ultra), "a camera stopped 800 m off the eye wants detail")
	_check(not DetailDrift.wanted(far, eye, DetailDrift.STILL_S - 0.5, ultra), "a camera still moving does not")
	_check(not DetailDrift.wanted(eye + Vector2(100.0, 0.0) * m, eye, 10.0, ultra), "a camera inside the rings does not")
	var mid := eye + Vector2(DetailDrift.drift_m(high) + 20.0, 0.0) * m
	_check(DetailDrift.wanted(mid, eye, 10.0, high) and not DetailDrift.wanted(mid, eye, 10.0, ultra),
		"the drift follows the preset's relief ring")
	# A streamed world centres its detail on itself even beside a landmark.
	var data := LocationData.new()
	data.latitude = 48.8566
	data.longitude = 2.3522
	data.landmark_type = "eiffel"
	var framed := View360.spawn_xz(data)
	data.detail_at_centre = true
	_check(View360.spawn_xz(data) == Vector2.ZERO, "a streamed world's detail eye is its centre")
	_check(framed != Vector2.ZERO, "a landmark visit still frames its landmark (got %s)" % framed)
	# A centre built where the camera stands is wanted at once, even at
	# the live centre itself.
	var s := WorldStreamer.new()
	for at in [far, Vector2.ZERO]:
		s.begin(Vector2(48.0, 2.0), at)
		s.mark_ready(s.generation)
		_check(s.swap_wanted(at), "a centre built at the camera (%s) should swap in" % at)
	if failures.is_empty():
		print("DETAIL DRIFT OK: still-and-far trigger per preset, streamed eye at the centre, swap at the camera")
		quit(0)
	else:
		for f in failures:
			printerr("DETAIL DRIFT FAIL: ", f)
		quit(1)
