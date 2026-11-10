class_name NearGroundWindow
extends RefCounted

## Keeps the fine land-cover map (GroundMaterial.near_class_map) under the
## eye as it walks or flies low. The map is drawn once around the
## viewpoint; when the eye has moved far enough it is rasterised again on a
## worker and swapped into the ground material when ready, so the frame
## only pays for the texture upload.
##
## The new centre snaps to whole texels of the old one, so texels the two
## maps share hold the same values and borders do not shift at the swap.

## The eye may move this far from the centre before the map follows: well
## inside the half side (600 m) less the hand-over band (60 m).
const REFRESH_M := 200.0
## Above this height the extent map's detail is all the eye can see.
const MAX_AGL_M := 150.0

var _mat: ShaderMaterial
var _data: LocationData
var _tex: ImageTexture
var _raster: Callable
var _n := 0
var _size_u := 0.0
var _centre := Vector2.ZERO
var _task := -1
var _box := {}

## A window over the ground of `root`'s "Terrain" node; null when this
## world has no near map to move.
static func attach(root: Node, data: LocationData, raster: Callable = GroundMaterial.near_class_map) -> NearGroundWindow:
	if root == null or data == null:
		return null
	var terrain := root.find_child("Terrain", true, false) as MeshInstance3D
	if terrain == null or not (terrain.material_override is ShaderMaterial):
		return null
	var mat := terrain.material_override as ShaderMaterial
	var n_value: Variant = mat.get_shader_parameter("near_n")
	var tex := mat.get_shader_parameter("near_class") as ImageTexture
	if n_value == null or float(n_value) < 1.0 or tex == null:
		return null
	var w := NearGroundWindow.new()
	var rect: Vector4 = mat.get_shader_parameter("near_rect")
	w._mat = mat
	w._data = data
	w._tex = tex
	w._raster = raster
	w._n = int(n_value)
	w._size_u = rect.z * 2.0
	w._centre = Vector2(rect.x, rect.y)
	return w

## The map's centre (world units).
func centre() -> Vector2:
	return _centre

## True while a new map is being drawn.
func busy() -> bool:
	return _task >= 0

## Whether an eye at `eye` has left the part of the map it should stay in.
func needs_refresh(eye: Vector2) -> bool:
	var d := (eye - _centre).abs()
	return maxf(d.x, d.y) > REFRESH_M * WorldScale.metres_to_units()

## The centre for an eye at `eye`, on the current map's texel grid.
func snapped_centre(eye: Vector2) -> Vector2:
	var texel := _size_u / float(_n)
	return _centre + ((eye - _centre) / texel).round() * texel

## Once a frame: finishes a drawn map, or starts one if the eye has moved on.
## `agl_u` is the eye's height over the ground.
func tick(eye: Vector2, agl_u: float) -> void:
	if _task >= 0:
		if WorkerThreadPool.is_task_completed(_task):
			WorkerThreadPool.wait_for_task_completion(_task)
			_task = -1
			_apply()
		return
	if agl_u > MAX_AGL_M * WorldScale.metres_to_units() or not needs_refresh(eye):
		return
	_box = {"centre": snapped_centre(eye)}
	_task = WorkerThreadPool.add_task(_draw.bind(_raster, _data, _n, _box, _size_u), false, "NearGroundWindow")

## Waits for a map in progress (a new place is about to replace this one).
func stop() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1

## Static, so a running job holds nothing of a window that has gone away.
static func _draw(raster: Callable, data: LocationData, n: int, box: Dictionary, size_u: float) -> void:
	box["image"] = raster.call(data, n, box["centre"], size_u)

func _apply() -> void:
	var img: Image = _box.get("image", null)
	if img == null or img.get_width() != _n:
		return
	_tex.update(img)
	_centre = _box["centre"]
	var rect: Vector4 = _mat.get_shader_parameter("near_rect")
	_mat.set_shader_parameter("near_rect", Vector4(_centre.x, _centre.y, rect.z, rect.w))
	print("NEAR-CLASS window moved to (%.0f, %.0f)" % [_centre.x, _centre.y])
