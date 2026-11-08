class_name QualityGovernor
extends Node

## FPS-driven quality steps for the 360 view. Mobile budgets win:
## below 28 fps step down (render scale, then shadows off), above
## 55 fps step back up. Emits the current step for the HUD pill.
##
## A step down is held: the step it left is not tried again until a hold
## has passed (HOLD_S, doubling with each further step down, up to
## HOLD_MAX_S), and stepping up needs UP_WINDOWS healthy windows in a row.
## Without that, a scene that runs at 20 fps on one step and 60 on the
## next flips between them every few seconds, with the render scale
## visibly pumping.

signal quality_changed(step_name: String, fps: float)

const WINDOW_S := 2.0
const DOWN_FPS := 28.0
const UP_FPS := 55.0
const UP_WINDOWS := 2
const HOLD_S := 10.0
const HOLD_MAX_S := 160.0

## Render scale per step lives in RenderSettings.render_scale_for, so
## the settings screen's summary and the governor cannot drift apart.
## The governor never changes the tier (T7.4): its label is the user's
## tier, plus the reduced render scale while it is stepping down.
static func step_label(ceiling: int, current: int) -> String:
	var label := RenderSettings.preset_name(ceiling)
	if current < ceiling:
		label += " · %d%% res%s" % [roundi(RenderSettings.render_scale_for(current) * 100.0),
			"" if RenderSettings.shadows_for(current) else ", no shadows"]
	return label

var step := 3  # start at the user's ceiling, adapt down if needed
## Highest step the user's RenderSettings preset allows (0..3). The
## governor still steps down under low FPS, but never back above this.
var ceiling_step := 3
var viewport: SubViewport
var sun: DirectionalLight3D

func set_preset(preset_value: int) -> void:
	ceiling_step = RenderSettings.clamp_preset(preset_value)
	# Snap to the new ceiling: an explicit preset choice (settings
	# screen, or a freshly opened place) applies straight away, in
	# both directions. FPS adaptation still steps down from here.
	step = ceiling_step
	_hold_until = 0.0
	_hold_s = HOLD_S
	_healthy = 0
	_apply()

## The step to be on after a window of `window_s` seconds that averaged
## `fps`. Pure state-machine: _process feeds it, tests drive it directly.
func adapt(fps: float, window_s: float = WINDOW_S) -> int:
	_clock += window_s
	if fps < DOWN_FPS:
		_healthy = 0
		if step > 0:
			_hold_until = _clock + _hold_s
			_hold_s = minf(_hold_s * 2.0, HOLD_MAX_S)
			return step - 1
	elif fps > UP_FPS:
		_healthy += 1
		if _healthy >= UP_WINDOWS and _clock >= _hold_until and step < ceiling_step:
			_healthy = 0
			return step + 1
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

func _process(delta: float) -> void:
	if viewport == null:
		return
	_frames += 1
	_elapsed += delta
	if _elapsed < WINDOW_S:
		return
	current_fps = _frames / _elapsed
	var new_step := adapt(current_fps, _elapsed)
	_frames = 0
	_elapsed = 0.0
	if new_step != step:
		step = new_step
		_apply()
	quality_changed.emit(step_label(ceiling_step, step), current_fps)

func _apply() -> void:
	if viewport != null:
		viewport.scaling_3d_scale = RenderSettings.render_scale_for(step)
	if sun != null:
		sun.shadow_enabled = RenderSettings.shadows_for(step)
