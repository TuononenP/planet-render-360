class_name QualityGovernor
extends Node

## FPS-driven quality steps for the 360 view. Mobile budgets win:
## below 28 fps step down (render scale, then shadows off), above
## 55 fps step back up. Emits the current step for the HUD pill.

signal quality_changed(step_name: String, fps: float)

const STEP_NAMES: Array[String] = ["Low", "Medium", "High"]
const STEP_SCALES: Array[float] = [0.6, 0.8, 1.0]

var step := 2  # start High, adapt down if the device struggles
var viewport: SubViewport
var sun: DirectionalLight3D

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
		new_step = mini(step + 1, 2)
	if new_step != step:
		step = new_step
		_apply()
	quality_changed.emit(STEP_NAMES[step], current_fps)

func _apply() -> void:
	if viewport != null:
		viewport.scaling_3d_scale = STEP_SCALES[step]
	if sun != null:
		sun.shadow_enabled = step > 0
