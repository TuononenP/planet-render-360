class_name QualityGovernor
extends Node

## FPS-driven quality steps for the 360 view. Mobile budgets win:
## below 28 fps step down (render scale, then shadows off), above
## 55 fps step back up. Emits the current step for the HUD pill.

signal quality_changed(step_name: String, fps: float)

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
	_apply()

var _frames := 0
var _elapsed := 0.0
var current_fps := 60.0

func _process(delta: float) -> void:
	if viewport == null:
		return
	_frames += 1
	_elapsed += delta
	if _elapsed < 2.0:
		return
	current_fps = _frames / _elapsed
	_frames = 0
	_elapsed = 0.0
	var new_step := step
	if current_fps < 28.0:
		new_step = maxi(step - 1, 0)
	elif current_fps > 55.0:
		new_step = mini(step + 1, ceiling_step)
	if new_step != step:
		step = new_step
		_apply()
	quality_changed.emit(step_label(ceiling_step, step), current_fps)

func _apply() -> void:
	if viewport != null:
		viewport.scaling_3d_scale = RenderSettings.render_scale_for(step)
	if sun != null:
		sun.shadow_enabled = RenderSettings.shadows_for(step)
