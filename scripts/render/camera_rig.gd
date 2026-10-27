class_name CameraRig
extends Node3D

## Drag-to-look 360 camera. Yaw wraps fully; pitch is clamped.

var yaw: float = 0.6
var pitch: float = -0.08
var zoom_factor := 1.0  # 1.0 = base FOV, >1 zooms in
var _dragging := false

const BASE_FOV := 70.0

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	_apply()

func set_look(new_yaw: float, new_pitch: float) -> void:
	yaw = new_yaw
	pitch = clampf(new_pitch, -1.2, 1.2)
	_apply()

func handle_drag(relative: Vector2) -> void:
	yaw -= relative.x * 0.005
	pitch = clampf(pitch - relative.y * 0.005, -1.2, 1.2)
	_apply()

## Multiply zoom (wheel step ~1.12, pinch by distance ratio).
func handle_zoom(factor: float) -> void:
	zoom_factor = clampf(zoom_factor * factor, 0.7, 2.8)
	_apply()

func reset_zoom() -> void:
	zoom_factor = 1.0
	_apply()

func compass_text() -> String:
	var dirs: Array[String] = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	var deg := wrapf(rad_to_deg(-yaw), 0.0, 360.0)
	return dirs[int(round(deg / 45.0)) % 8]

func _apply() -> void:
	rotation = Vector3(pitch, yaw, 0)
	if camera != null:
		camera.fov = clampf(BASE_FOV / zoom_factor, 25.0, 95.0)
