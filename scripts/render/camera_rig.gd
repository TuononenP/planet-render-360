class_name CameraRig
extends Node3D

## Drag-to-look 360 camera. Yaw wraps fully; pitch is clamped.

var yaw: float = 0.6
var pitch: float = -0.08
var zoom_factor := 1.0  # 1.0 = base FOV, >1 zooms in
var _dragging := false

## Active WorldScale render origin in metres (contract §1.3, T1.2).
## The world root carries the −origin offset so metre-scale geometry
## sits near the float sweet spot; the rig keeps its viewpoint-local
## position and records the origin so spawn/look math stays in the
## same frame. Zero (v1 equivalence): no behaviour change.
var render_origin := Vector3.ZERO

func set_render_origin(metre_origin: Vector3) -> void:
	render_origin = metre_origin

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

## Gyro look rates (yaw, pitch in rad/s) from the device's rotation rate
## and gravity, both in screen axes: turning is the spin about the true
## vertical, tilting the spin about the screen's level right edge, so a
## tablet held tilted back (or flat) turns the view as far as it turns.
## Without gravity it falls back to the screen's own axes.
static func gyro_rates(rate: Vector3, gravity: Vector3) -> Vector2:
	if gravity.length() < 0.1:
		return Vector2(rate.y, rate.x)
	var up := -gravity.normalized()
	var right := Vector3.RIGHT - up * up.x
	if right.length() < 0.1:
		# Standing on its side edge: up is the screen's X, so tilting is
		# the spin about the level axis across the screen (±Y).
		return Vector2(rate.dot(up), rate.dot(up.cross(Vector3.BACK).normalized()))
	return Vector2(rate.dot(up), rate.dot(right.normalized()))

## Multiply zoom (wheel step ~1.12, pinch by distance ratio).
func handle_zoom(factor: float) -> void:
	zoom_factor = clampf(zoom_factor * factor, 0.7, 2.8)
	_apply()

func set_zoom(factor: float) -> void:
	zoom_factor = clampf(factor, 0.7, 2.8)
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
