extends SceneTree

## Headless: godot --headless --script tests/quality_governor_test.gd
## The FPS governor does not flap between two steps, still reacts to a
## real slowdown at once, never passes the user's ceiling, and the first
## preset follows the GPU: Ultra unless the GPU is known to be weak.

var _failures: Array[String] = []

func _init() -> void:
	_test_flap()
	_test_reaction()
	_test_effects()
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
	# Ultra: the effect layer drains first (SSR 64 -> 32), untouching the render scale.
	if governor.adapt(12.0) != 3 or governor.effects_step != 2:
		_failures.append("a slow window should step the effect layer down first (SSR 64 -> 32)")
	governor.adapt(12.0)
	governor.adapt(12.0)
	# Effect layer at its floor: now a slow window steps render scale 3 -> 2.
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

## The Ultra-only effect layer (P1.2): drains after haze and before the
## render scale, climbs back after it, never below its floor, and never
## engages on a non-Ultra ceiling.
func vp_taa_state(governor: QualityGovernor) -> bool:
	if governor.viewport == null:
		return true
	return not governor.viewport.use_taa

func _test_effects() -> void:
	var governor := QualityGovernor.new()
	governor.ceiling_step = 3  # Ultra
	governor.step = 3
	var vp := SubViewport.new()
	var env := Environment.new()
	governor.viewport = vp
	governor.environment = env
	governor._apply()
	if env.ssr_max_steps != 64 or not env.sdfgi_enabled or not env.ssil_enabled:
		_failures.append("healthy Ultra ceiling should be full SSR + SDFGI + SSIL")
	# Slow window: the effect layer drains first (SSR 64 -> 32), no render scale move.
	governor.step = governor.adapt(12.0)
	governor._apply()
	if env.ssr_max_steps != 32 or not env.sdfgi_enabled or governor.effects_step != 2:
		_failures.append("1st slow window: SSR 64 -> 32 (effects_step %d), got ssr=%d sdfgi=%s" % [governor.effects_step, env.ssr_max_steps, str(env.sdfgi_enabled)])
	# 2nd slow window: volume 128 -> 64; SDFGI stays on.
	governor.step = governor.adapt(12.0)
	governor._apply()
	if governor.effects_step != 1 or not env.sdfgi_enabled:
		_failures.append("2nd slow window: volume 128 -> 64 (effects_step %d), got sdfgi=%s" % [governor.effects_step, str(env.sdfgi_enabled)])
	# 3rd slow window: SDFGI + SSIL off, then TAA off (effects_step 1 -> 0).
	governor.step = governor.adapt(12.0)
	governor._apply()
	if governor.effects_step != 0 or env.sdfgi_enabled:
		_failures.append("3rd slow window: SDFGI off (effects_step %d), got sdfgi=%s" % [governor.effects_step, str(env.sdfgi_enabled)])
	if env.ssil_enabled:
		_failures.append("3rd slow window: SSIL off should follow SDFGI off")
	if not vp_taa_state(governor):
		_failures.append("3rd slow window: TAA off should follow SDFGI off")
	# At the layer floor, the render scale takes over the next step.
	governor.step = governor.adapt(12.0)
	if governor.step != 2:
		_failures.append("with the effect layer at its floor, a slow window must step render scale 3 -> 2, got %d" % governor.step)
	# Step 0 is the floor: nothing moves further.
	governor.step = 0
	governor.adapt(12.0)
	if governor.step != 0:
		_failures.append("step 0 is the floor")
	# Recovery against a fresh healthy governor: effects climb back once
	# the render scale has recovered to the ceiling.
	for i in 200:
		governor.step = governor.adapt(90.0)
		if governor.step == 3 and governor.effects_step == 3:
			break
	if governor.step != 3 or governor.effects_step != 3:
		_failures.append("healthy GPU should recover effects_step=3 at ceiling (step=%d effects=%d)" % [governor.step, governor.effects_step])
	# Non-Ultra ceiling: the layer never engages (Ultra-only).
	var other := QualityGovernor.new()
	other.ceiling_step = 2  # High
	other.step = 2
	other.step = other.adapt(12.0)
	if other.effects_step != QualityGovernor.EFFECTS_MAX:
		_failures.append("non-Ultra ceiling must never drain the effect layer, got %d" % other.effects_step)
	if other.step != 1:
		_failures.append("non-Ultra ceiling should step the render scale 2 -> 1, got %d" % other.step)
	governor.free()
	other.free()

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
