extends SceneTree

## Headless: godot --headless --script tests/quality_governor_test.gd
## The FPS governor does not flap between two steps, still reacts to a
## real slowdown at once, never passes the user's ceiling, and the first
## preset follows the GPU: Ultra unless the GPU is known to be weak.

var _failures: Array[String] = []

func _init() -> void:
	_test_flap()
	_test_reaction()
	_test_preset()
	if _failures.is_empty():
		print("QUALITY GOVERNOR OK: hold after a step down, ceiling, GPU-aware first preset")
		quit(0)
	else:
		for f in _failures:
			printerr("QUALITY GOVERNOR FAIL: ", f)
		quit(1)

## A scene that needs the lower step: 20 fps on step 3, 60 fps on step 2.
static func scene_fps(step: int) -> float:
	return 20.0 if step >= 3 else 60.0

func _flips(seconds: float, hold: bool) -> int:
	var governor := QualityGovernor.new()
	governor.ceiling_step = 3
	governor.step = 3
	var flips := 0
	var t := 0.0
	while t < seconds:
		var before := governor.step
		var next := governor.adapt(scene_fps(before)) if hold else _unheld(before)
		if next != before:
			flips += 1
		governor.step = next
		t += QualityGovernor.WINDOW_S
	governor.free()
	return flips

## The old rule, for comparison: no hold, no dwell.
func _unheld(step: int) -> int:
	var fps := scene_fps(step)
	if fps < 28.0:
		return maxi(step - 1, 0)
	if fps > 55.0:
		return mini(step + 1, 3)
	return step

func _test_flap() -> void:
	var old := _flips(300.0, false)
	var held := _flips(300.0, true)
	if old < 50:
		_failures.append("the comparison scene should flap under the old rule, got %d flips in 5 minutes" % old)
	if held > 12:
		_failures.append("with the hold the step should settle: %d flips in 5 minutes (old rule %d)" % [held, old])
	# The pause grows: each wait is at least as long as the one before.
	var governor := QualityGovernor.new()
	governor.ceiling_step = 3
	governor.step = 3
	var waits: Array[float] = []
	var down_at := 0.0
	var t := 0.0
	for i in 400:
		var before := governor.step
		governor.step = governor.adapt(scene_fps(before))
		t += QualityGovernor.WINDOW_S
		if before == 3 and governor.step == 2:
			down_at = t
		elif before == 2 and governor.step == 3 and down_at > 0.0:
			waits.append(t - down_at)
	for i in range(1, waits.size()):
		if waits[i] < waits[i - 1]:
			_failures.append("the wait before retrying a step should not shrink: %s" % str(waits))
			break
	if waits.is_empty():
		_failures.append("the governor should retry the higher step eventually")
	governor.free()

func _test_reaction() -> void:
	var governor := QualityGovernor.new()
	governor.ceiling_step = 3
	governor.step = 3
	if governor.adapt(12.0) != 2:
		_failures.append("a slow window should step down at once")
	governor.step = 2
	if governor.adapt(12.0) != 1:
		_failures.append("a second slow window should step down again, whatever the hold")
	governor.step = 0
	if governor.adapt(5.0) != 0:
		_failures.append("step 0 is the floor")
	# Never above the ceiling, even when healthy for a long time.
	governor.ceiling_step = 1
	governor.step = 1
	for i in 100:
		governor.step = governor.adapt(120.0)
	if governor.step != 1:
		_failures.append("the governor passed the user's ceiling: step %d" % governor.step)
	# Between the thresholds nothing moves and the healthy count restarts.
	governor.ceiling_step = 3
	governor.step = 2
	governor.set_preset(RenderSettings.Preset.HIGH)
	governor.step = 1
	governor.adapt(60.0)
	governor.adapt(40.0)
	if governor.adapt(60.0) != 1:
		_failures.append("one healthy window after a middling one is not enough to step up")
	governor.free()

func _test_preset() -> void:
	var apple := "Apple M2 Pro"
	var cases := [
		[true, RenderingDevice.DEVICE_TYPE_DISCRETE_GPU, "NVIDIA GeForce RTX 4070", RenderSettings.Preset.ULTRA],
		[true, RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU, apple, RenderSettings.Preset.ULTRA],
		[true, RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU, "Intel(R) UHD Graphics 620", RenderSettings.Preset.HIGH],
		[true, RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU, "AMD Radeon Graphics", RenderSettings.Preset.HIGH],
		[true, RenderingDevice.DEVICE_TYPE_CPU, "llvmpipe (LLVM 15.0.7, 256 bits)", RenderSettings.Preset.HIGH],
		[true, RenderingDevice.DEVICE_TYPE_VIRTUAL_GPU, "Virtio GPU", RenderSettings.Preset.HIGH],
		[true, RenderingDevice.DEVICE_TYPE_OTHER, "Dummy", RenderSettings.Preset.ULTRA],
		[false, RenderingDevice.DEVICE_TYPE_DISCRETE_GPU, "Adreno", RenderSettings.Preset.HIGH],
		[false, RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU, apple, RenderSettings.Preset.HIGH],
	]
	for c in cases:
		var got := RenderSettings.preset_for_adapter(c[0], c[1], c[2])
		if got != c[3]:
			_failures.append("%s (pc=%s, type %d): preset %d, wanted %d" % [c[2], str(c[0]), c[1], got, c[3]])
	var live := RenderSettings.default_preset()
	if live != RenderSettings.clamp_preset(live):
		_failures.append("the live default is not a valid preset")
