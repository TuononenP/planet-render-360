class_name QualityGovernor
extends Node

## FPS-driven quality steps for the 360 view. Mobile budgets win:
## below 28 fps step down (Ultra haze sub-steps, then Ultra effect
## sub-steps, then render scale, then shadows off), above 55 fps step
## back up. Emits the current step for the HUD pill.
##
## A step down is held: the step it left is not tried again until a hold
## has passed (HOLD_S, doubling with each further step down, up to
## HOLD_MAX_S), and stepping up needs UP_WINDOWS healthy windows in a row.
## Without that, a scene that runs at 20 fps on one step and 60 on the
## next flips between them every few seconds, with the render scale
## visibly pumping.

signal quality_changed(step_name: String, fps: float)
## Emitted once per Ultra session when FPS stays below DOWN_FPS for
## SLOW_SUGGEST_WINDOWS consecutive windows so the HUD can offer a
## user-confirmed switch to High instead of lowering Ultra automatically.
signal suggest_high

const WINDOW_S := 2.0
const DOWN_FPS := 28.0
const UP_FPS := 55.0
const UP_WINDOWS := 2
const HOLD_S := 10.0
const HOLD_MAX_S := 160.0
const SLOW_SUGGEST_WINDOWS := 4
## Settling cooldown (seconds) after streaming or WorldCache saving finishes
## so CPU/IO hitches never bleed into the next GPU performance window.
const BUSY_SETTLE_S := 2.0

## Render scale per step lives in RenderSettings.render_scale_for, so
## the settings screen's summary and the governor cannot drift apart.
## The governor never changes the tier (T7.4): its label is the user's
## tier, plus the reduced render scale while it is stepping down.

## Ultra-only effect reductions, below the haze sub-steps and above the
## render scale (degradation-only, same hold rule): 3 = none, 2 = SSR
## 64 -> 32 steps, 1 = volumetric volume 128 -> 64, 0 = SDFGI + SSIL
## off, then TAA off (applied in that order). Only an Ultra ceiling enters
## this layer: other presets do not run the effects it reduces.
const EFFECTS_MAX := 3

static func step_label(ceiling: int, current: int,
		cur_haze: int = 2, max_haze: int = 0,
		eff_step: int = EFFECTS_MAX) -> String:
	var label := RenderSettings.preset_name(ceiling)
	if current < ceiling:
		label += " · %d%% res%s" % [roundi(RenderSettings.render_scale_for(current) * 100.0),
			"" if RenderSettings.shadows_for(current) else ", no shadows"]
	elif max_haze > 0 and cur_haze < max_haze:
		label += " · no rays" if cur_haze == 1 else " · no haze"
	if ceiling == RenderSettings.Preset.ULTRA and eff_step < EFFECTS_MAX:
		label += _effects_label(eff_step)
	return label

static func _effects_label(eff_step: int) -> String:
	match eff_step:
		2:
			return " · SSR 32"
		1:
			return " · SSR 32, vol 64"
		_:
			return " · SSR 32, vol 64, no GI/SSIL/TAA"

var step := 3  # start at the user's ceiling, adapt down if needed
## Highest step the user's RenderSettings preset allows (0..3). The
## governor still steps down under low FPS, but never back above this.
var ceiling_step := 3
## Cheapest Ultra step-down before render scale or shadows:
## 2 = god-rays + thickened haze, 1 = thickened haze only (no post pass),
## 0 = haze off. `haze_ceiling == 0` disables the haze sub-steps so all
## non-haze presets and existing step curves behave identically.
var haze_step := 0
var haze_ceiling := 0
var viewport: SubViewport
var sun: DirectionalLight3D
## Effect-layer environment seam (AtmosphereRig's Environment), set by the
## view. Left null in tests, which skips the effect reductions.
var environment: Environment
var haze: HazeRig
## Optional predicate returning true while streaming/building/saving CPU work is
## active; pauses FPS step-downs and High-quality prompts until settled.
var pause_down: Callable
## Effect-layer depth (EFFECTS_MAX = healthy). Healthy whenever the layer
## is inactive, so it never gates haze/scale on other presets.
var effects_step := EFFECTS_MAX

func _effects_active() -> bool:
	return ceiling_step == RenderSettings.Preset.ULTRA

func set_preset(preset_value: int) -> void:
	ceiling_step = RenderSettings.clamp_preset(preset_value)
	# Snap to the new ceiling: an explicit preset choice (settings
	# screen, or a freshly opened place) applies straight away, in
	# both directions. FPS adaptation still steps down from here.
	step = ceiling_step
	haze_step = haze_ceiling
	effects_step = EFFECTS_MAX
	_hold_until = 0.0
	_hold_s = HOLD_S
	_healthy = 0
	_slow_windows = 0
	_suggested_high = false
	_settle_left = 0.0
	_apply()

func set_haze_ceiling(max_haze: int) -> void:
	haze_ceiling = clampi(max_haze, 0, 2)
	haze_step = haze_ceiling if step >= ceiling_step else 0
	_apply()

## True only when neither render scale/shadows nor the Ultra haze/effect
## sub-steps are stepped down below their allowed ceilings.
func at_ceiling() -> bool:
	return step >= ceiling_step and haze_step >= haze_ceiling \
		and (not _effects_active() or effects_step >= EFFECTS_MAX)

## The step to be on after a window of `window_s` seconds that averaged
## `fps`. Pure state-machine: _process feeds it, tests drive it directly.
## When `haze_ceiling > 0`, `haze_step` drops (2 -> 1 -> 0) before the
## Ultra effect layer, which in turn drops (3 -> 0) before `step` touches
## render scale or shadows; they climb back in that order, render scale
## first and haze last.
func adapt(fps: float, window_s: float = WINDOW_S) -> int:
	_clock += window_s
	if ceiling_step == RenderSettings.Preset.ULTRA:
		if fps < DOWN_FPS:
			_slow_windows += 1
			if _slow_windows >= SLOW_SUGGEST_WINDOWS and not _suggested_high:
				_suggested_high = true
				suggest_high.emit()
		else:
			_slow_windows = 0
	if fps < DOWN_FPS:
		_healthy = 0
		if haze_step > 0:
			_hold_until = _clock + _hold_s
			_hold_s = minf(_hold_s * 2.0, HOLD_MAX_S)
			haze_step -= 1
			return step
		if _effects_active() and effects_step > 0:
			_hold_until = _clock + _hold_s
			_hold_s = minf(_hold_s * 2.0, HOLD_MAX_S)
			effects_step -= 1
			return step
		if step > 0:
			_hold_until = _clock + _hold_s
			_hold_s = minf(_hold_s * 2.0, HOLD_MAX_S)
			return step - 1
	elif fps > UP_FPS:
		_healthy += 1
		if _healthy >= UP_WINDOWS and _clock >= _hold_until:
			if step < ceiling_step:
				_healthy = 0
				return step + 1
			if _effects_active() and effects_step < EFFECTS_MAX:
				_healthy = 0
				effects_step += 1
				return step
			if haze_step < haze_ceiling:
				_healthy = 0
				haze_step += 1
				return step
	else:
		_healthy = 0
	return step

var _frames := 0
var _elapsed := 0.0
var current_fps := 60.0
var _clock := 0.0
var _hold_until := 0.0
var _hold_s := HOLD_S
var _healthy := 0
var _slow_windows := 0
var _suggested_high := false
var _settle_left := 0.0

func _process(delta: float) -> void:
	if viewport == null:
		return
	if pause_down.is_valid() and bool(pause_down.call()):
		_frames = 0
		_elapsed = 0.0
		_settle_left = BUSY_SETTLE_S
		return
	if _settle_left > 0.0:
		_settle_left = maxf(_settle_left - delta, 0.0)
		_frames = 0
		_elapsed = 0.0
		return
	_frames += 1
	_elapsed += delta
	if _elapsed < WINDOW_S:
		return
	current_fps = _frames / _elapsed
	var prev_haze := haze_step
	var prev_effects := effects_step
	var new_step := adapt(current_fps, _elapsed)
	if MemoryGuard.level >= MemoryGuard.Level.CRITICAL and not RenderQuality.ultra_desktop(ceiling_step):
		# Memory short on constrained tiers: the lowest step's smaller render
		# targets and no shadow maps, held until MemoryGuard lets go.
		new_step = 0
		haze_step = 0
		if _effects_active():
			effects_step = 0
	_frames = 0
	_elapsed = 0.0
	if new_step != step or haze_step != prev_haze or effects_step != prev_effects:
		step = new_step
		_apply()
	quality_changed.emit(step_label(ceiling_step, step, haze_step, haze_ceiling, effects_step), current_fps)

func _apply() -> void:
	if viewport != null:
		viewport.scaling_3d_scale = RenderSettings.render_scale_for(step)
		if _effects_active():
			viewport.use_taa = effects_step > 0
	if sun != null:
		sun.shadow_enabled = RenderSettings.shadows_for(step)
	if environment != null and _effects_active():
		environment.ssr_max_steps = 32 if effects_step <= 2 else 64
		RenderingServer.environment_set_volumetric_fog_volume_size(
			64 if effects_step <= 1 else 128,
			64 if effects_step <= 1 else 128)
		environment.sdfgi_enabled = effects_step >= 1
		environment.ssil_enabled = effects_step >= 1
	if haze != null:
		haze.set_governor_step(haze_step)
