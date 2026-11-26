class_name HazeRig
extends Control

## Volumetric-haze & screen-space god-ray rig (Ultra on desktop Forward+).
##
## Architecture (zero copy of the 3D scene, exact ACES grade preserved):
##  - View360 keeps its `SubViewportContainer` (`_container`) + `_viewport`
##    (`world_vp`) untouched on screen, so the ACES tonemap/sRGB output is
##    never resampled or gamma-shifted.
##  - HazeRig sits immediately above `_container` and below `_hud`, owning:
##      1. `rays_vp` (half-res `SubViewport`, 48 jittered radial taps in
##         `GodrayShader` marching toward the world camera's projected
##         `sun_uv`, sRGB-decoded and sun-aureole-masked so bright sky
##         emits shafts and silhouetted roofs/trees cast shadow lanes).
##      2. `overlay` (`TextureRect` with `blend_add` `GodrayShader` material)
##         that hardware-blends the bilinearly upsampled shafts onto the
##         world view.
##  - When the pass is OFF (Fast / Balanced / High, non-Forward+, user
##    toggled `haze` off, `View360` is off-screen, or QualityGovernor
##    eased rays down to 0), `HazeRig` is hidden and `rays_vp` is
##    `UPDATE_DISABLED` — zero background GPU work.
##  - Capture parity: `View360.snapshot()` composites the active shaft
##    buffer onto saved 2D photos and thumbnails; 6-face `PanoramaCapture`
##    intentionally uses `AtmosphereRig.set_haziness` alone so cube faces
##    never seam across borders.
##
## Pass cost measured by `tools/haze_spike.gd` on the capture machine
## (2026-11-15, Apple M5 Ultra, Metal 4.0 Forward+, 1280x720, 48 taps,
## sun 8 deg above the horizon):
##  - 0.5x (`RAYS_SCALE`) 640x360 radial pass + additive overlay:
##    base 8.325 ms, +haze 8.333 ms, delta +0.008 ms (inside 120 Hz vblank).

const TAPS := GodrayShader.TAPS
const RAYS_SCALE := 0.5
## Smooth intensity ease per second at 60 fps (~19 frames; slower under
## `UiPrefs.reduce_motion` so atmospheric shifts stay calm).
const EASE_PER_S := 3.0
const EASE_REDUCED_PER_S := 1.2
## True solar altitude window (deg): shafts start just as the disc clears
## the horizon, peak at low golden-hour sun, and taper steeply above ~15 deg.
const RAY_START_ELEV := 0.5
const RAY_PEAK_ELEV := 10.0
const RAY_HIGH_ELEV := 28.0
## Overcast kills direct shafts just as SkyShader hides the solar disc.
const CLOUD_FADE_START := 55.0
const CLOUD_KILL := 90.0
## Visibility (m) below which thick fog scatters shafts into uniform murk
## while keeping `AtmosphereRig`'s thickened haze active.
const FOG_VIS_M := 3000.0

var rays_vp: SubViewport
var overlay: TextureRect

var _rays_cam: Camera3D
var _rays_quad: MeshInstance3D
var _rays_mat: ShaderMaterial
var _overlay_mat: ShaderMaterial

var _world_vp: SubViewport
var _world_container: SubViewportContainer
var _world_cam: Camera3D
var _atmos: AtmosphereRig
var _saved_world_update_mode: int = SubViewport.UPDATE_WHEN_VISIBLE

## Preset + preference gate (`RenderSettings.haze_allowed` and `UiPrefs.haze`).
var enabled := false
## QualityGovernor step for haze: 2 = full rays + haze, 1 = haze only (no
## post pass), 0 = completely off.
var governor_step := 2
## Current eased drivers in [0, 1]. `haziness` drives `AtmosphereRig`;
## `ray_amount` drives the screen-space shaft pass (also gated by camera
## sun-facing weight and `governor_step == 2`).
var haziness := 0.0
var ray_amount := 0.0
var pass_active := false

var _target_haziness := 0.0
var _target_ray_sky := 0.0
var _target_rays := 0.0
var _base_haziness := 0.0
var _base_rays := 0.0
var _sun_dir := Vector3(0.0, 0.2, -0.98)
var _sun_uv := Vector2(0.5, 0.35)
var _sun_facing := 1.0
var _sun_color := Color(1.0, 0.85, 0.64)

static func supported_for(preset: int, forward_plus: bool = RenderQuality.is_forward_plus()) -> bool:
	return RenderSettings.haze_allowed(preset, forward_plus)

func _init() -> void:
	name = "HazeRig"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

## Wire into View360 immediately above `_container` and below `_hud`.
func attach_view(world_vp: SubViewport, world_container: SubViewportContainer,
		world_cam: Camera3D, atmos: AtmosphereRig) -> void:
	if _world_container != null and _world_container != world_container \
			and _world_container.visibility_changed.is_connected(_refresh_pass_state):
		_world_container.visibility_changed.disconnect(_refresh_pass_state)
	_world_vp = world_vp
	_world_container = world_container
	_world_cam = world_cam
	_atmos = atmos
	_saved_world_update_mode = world_vp.render_target_update_mode
	_ensure_viewports()
	if _rays_mat != null:
		_rays_mat.set_shader_parameter("world", _world_vp.get_texture())
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)
	if _world_container != null and not _world_container.visibility_changed.is_connected(_refresh_pass_state):
		_world_container.visibility_changed.connect(_refresh_pass_state)
	_on_resized()
	_set_pass_active(false)

func _view_shown() -> bool:
	return _world_container == null or _world_container.is_visible_in_tree()

func _ensure_viewports() -> void:
	if overlay != null or _world_vp == null:
		return
	var world_rt := _world_vp.get_texture()
	rays_vp = SubViewport.new()
	rays_vp.name = "HazeRays"
	# Its own 3D world: sharing the city's, the ray quad stood in the street
	# at the world origin, a black 3 m panel seen from nearby.
	rays_vp.own_world_3d = true
	rays_vp.transparent_bg = false
	rays_vp.handle_input_locally = false
	rays_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var rays_pair := _build_ortho_quad(GodrayShader.rays_material(world_rt))
	_rays_cam = rays_pair[0]
	_rays_quad = rays_pair[1]
	_rays_mat = _rays_quad.material_override as ShaderMaterial
	rays_vp.add_child(_rays_cam)
	rays_vp.add_child(_rays_quad)
	add_child(rays_vp)

	overlay = TextureRect.new()
	overlay.name = "HazeOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_SCALE
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.texture = rays_vp.get_texture()
	_overlay_mat = GodrayShader.overlay_material()
	overlay.material = _overlay_mat
	overlay.visible = false
	add_child(overlay)

static func _build_ortho_quad(mat: ShaderMaterial) -> Array:
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.0
	cam.near = 0.1
	cam.far = 4.0
	cam.position = Vector3(0.0, 0.0, 1.0)
	cam.current = true
	var quad := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(2.0, 2.0)
	quad.mesh = qm
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	quad.material_override = mat
	return [cam, quad]

func _on_resized() -> void:
	if _world_vp == null or rays_vp == null:
		return
	var base := size
	if base.x < 2.0 or base.y < 2.0:
		base = Vector2(_world_vp.size)
	var w := maxf(base.x, 32.0)
	var h := maxf(base.y, 32.0)
	var aspect := w / h
	rays_vp.size = Vector2i(maxi(32, roundi(w * RAYS_SCALE)), maxi(32, roundi(h * RAYS_SCALE)))
	if _rays_quad != null and _rays_quad.mesh is QuadMesh:
		(_rays_quad.mesh as QuadMesh).size = Vector2(2.0 * aspect, 2.0)
	if _rays_mat != null:
		_rays_mat.set_shader_parameter("aspect", aspect)

## Sync preset + `UiPrefs.haze` + `QualityGovernor` ceiling.
func sync_gate(preset: int, governor: QualityGovernor = null,
		forward_plus: bool = RenderQuality.is_forward_plus()) -> void:
	var want := supported_for(preset, forward_plus) and UiPrefs.haze
	if governor != null:
		governor.set_haze_ceiling(2 if want else 0)
		governor_step = governor.haze_step
	else:
		governor_step = 2 if want else 0
	set_enabled(want)

func set_enabled(on: bool) -> void:
	enabled = on
	if not enabled:
		_target_haziness = 0.0
		_target_ray_sky = 0.0
		_target_rays = 0.0
		haziness = 0.0
		ray_amount = 0.0
		if _atmos != null:
			_atmos.set_haziness(0.0)
		_set_pass_active(false)
		return
	if _atmos != null:
		update_from_atmosphere(_atmos)
	_recompute_targets()
	_refresh_pass_state()

func set_governor_step(step_val: int) -> void:
	governor_step = clampi(step_val, 0, 2)
	_recompute_targets()
	_refresh_pass_state()

## Pure sky/weather intensity curve (testable without a scene tree).
## Returns {"haziness": float, "rays": float} in [0, 1] before governor
## or camera-facing weights.
static func sky_weights(elev_deg: float, cloud_cover: float, visibility_m: float) -> Dictionary:
	var vis := visibility_m if visibility_m > 0.0 else 20000.0
	var up := smoothstep(RAY_START_ELEV, RAY_PEAK_ELEV, elev_deg)
	var low_boost := 1.0 - 0.72 * smoothstep(RAY_PEAK_ELEV, RAY_HIGH_ELEV, elev_deg)
	var clear := 1.0 - smoothstep(CLOUD_FADE_START, CLOUD_KILL, clampf(cloud_cover, 0.0, 100.0))
	var vis_shafts := smoothstep(FOG_VIS_M * 0.15, FOG_VIS_M, vis)
	var rays := clampf(up * low_boost * clear * vis_shafts, 0.0, 1.0)
	var day := smoothstep(-3.0, 10.0, elev_deg)
	var murk := 1.0 - smoothstep(FOG_VIS_M * 0.25, FOG_VIS_M * 2.5, vis)
	var haze := clampf(maxf(rays, day * lerpf(0.35, 0.85, murk) * (1.0 - 0.35 * (1.0 - clear))), 0.0, 1.0)
	return {"haziness": haze, "rays": rays}

## Project world-space `sun_dir` (unit vector toward the sun) into the
## world Camera3D's viewport UV `(0,0)` top-left .. `(1,1)` bottom-right,
## plus a smooth forward-hemisphere weight (`0` when behind the camera).
static func project_sun(cam: Camera3D, aspect: float, sun_dir: Vector3) -> Dictionary:
	if cam == null:
		return {"uv": Vector2(0.5, 0.35), "facing": 0.0}
	var v := cam.global_basis.inverse() * sun_dir.normalized()
	var fwd := -v.z
	if fwd <= 0.02:
		return {"uv": Vector2(0.5, 0.35), "facing": 0.0}
	var facing := smoothstep(0.04, 0.32, fwd)
	var tan_y := maxf(tan(deg_to_rad(cam.fov) * 0.5), 1e-3)
	var tan_x := maxf(tan_y * maxf(aspect, 0.1), 1e-3)
	var denom := maxf(fwd, 0.08)
	var u := clampf(0.5 + 0.5 * (v.x / (denom * tan_x)), -1.25, 2.25)
	var uv_y := clampf(0.5 - 0.5 * (v.y / (denom * tan_y)), -1.25, 2.25)
	return {"uv": Vector2(u, uv_y), "facing": facing}

func update_from_atmosphere(atmos: AtmosphereRig = _atmos) -> void:
	if atmos == null:
		return
	var raw_vis := atmos.effective_visibility_m if atmos.effective_visibility_m > 0.0 \
		else float(atmos.weather_look.get("visibility_m", 0.0))
	var vis_m := raw_vis if raw_vis > 0.0 else 20000.0
	set_conditions(atmos.solar_elevation, atmos.solar_azimuth, atmos.cloud_cover,
		vis_m, atmos.sun.light_color if atmos.sun != null else Color(1.0, 0.85, 0.64))

func set_conditions(elev_deg: float, azimuth_deg: float, cloud_cover: float = 30.0,
		visibility_m: float = 20000.0, sun_col: Color = Color(1.0, 0.85, 0.64)) -> void:
	_sun_dir = SolarPosition.direction(elev_deg, azimuth_deg)
	_sun_color = sun_col
	var w := sky_weights(elev_deg, cloud_cover, visibility_m)
	_base_haziness = float(w["haziness"])
	_base_rays = float(w["rays"])
	_recompute_targets()
	_refresh_pass_state()

func _recompute_targets() -> void:
	if not enabled or governor_step <= 0:
		_target_haziness = 0.0
		_target_ray_sky = 0.0
		_target_rays = 0.0
		return
	_target_haziness = _base_haziness
	_target_ray_sky = _base_rays if governor_step >= 2 else 0.0
	var aspect := float(_world_vp.size.x) / maxf(float(_world_vp.size.y), 1.0) \
		if _world_vp != null else 1.7778
	_sun_facing = float(project_sun(_world_cam, aspect, _sun_dir)["facing"]) if _world_cam != null else 1.0
	_target_rays = _target_ray_sky * _sun_facing

func _process(delta: float) -> void:
	if not _view_shown():
		if pass_active:
			_set_pass_active(false)
		return
	if not enabled and haziness <= 0.0005 and ray_amount <= 0.0005:
		if pass_active:
			_set_pass_active(false)
		return
	if _atmos != null:
		update_from_atmosphere(_atmos)
	var aspect := float(_world_vp.size.x) / maxf(float(_world_vp.size.y), 1.0) \
		if _world_vp != null else 1.7778
	var proj := project_sun(_world_cam, aspect, _sun_dir)
	_sun_uv = proj["uv"]
	_sun_facing = float(proj["facing"])
	var rate := EASE_REDUCED_PER_S if UiPrefs.reduce_motion else EASE_PER_S
	var step_d := clampf(rate * delta, 0.0, 1.0)
	haziness = move_toward(haziness, _target_haziness, step_d)
	_target_rays = _target_ray_sky * _sun_facing
	ray_amount = move_toward(ray_amount, _target_rays, step_d)
	if _atmos != null:
		_atmos.set_haziness(haziness)
	_push_uniforms(aspect)
	_refresh_pass_state()

func _push_uniforms(aspect: float) -> void:
	if _rays_mat != null:
		_rays_mat.set_shader_parameter("sun_uv", _sun_uv)
		_rays_mat.set_shader_parameter("aspect", aspect)
		_rays_mat.set_shader_parameter("ray_amount", ray_amount)
		_rays_mat.set_shader_parameter("sun_color", Vector3(_sun_color.r, _sun_color.g, _sun_color.b))
		var active_rays := governor_step >= 2 or ray_amount > 0.001
		_rays_mat.set_shader_parameter("taps", float(TAPS if active_rays else 0))
	if _overlay_mat != null:
		_overlay_mat.set_shader_parameter("ray_amount", ray_amount)

func _refresh_pass_state() -> void:
	var want_pass := enabled and _view_shown() and (_target_rays > 0.001 or ray_amount > 0.001)
	if want_pass != pass_active:
		_set_pass_active(want_pass)

func _set_pass_active(on: bool) -> void:
	pass_active = on
	if _world_vp == null or _world_container == null or overlay == null or rays_vp == null:
		return
	if on:
		_on_resized()
		if _rays_mat != null:
			_rays_mat.set_shader_parameter("world", _world_vp.get_texture())
		rays_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		overlay.visible = true
		visible = true
	else:
		visible = false
		overlay.visible = false
		rays_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_world_container.visible = true
		_world_vp.render_target_update_mode = _saved_world_update_mode

## Composites the active shaft buffer onto a captured world `Image` (for
## photos, History thumbnails and golden captures) matching `blend_add`.
func composite_onto(world_img: Image) -> Image:
	if world_img == null or world_img.is_empty() or not pass_active or ray_amount <= 0.002 or rays_vp == null:
		return world_img
	var rays_img := rays_vp.get_texture().get_image()
	if rays_img == null or rays_img.is_empty():
		return world_img
	var w := world_img.get_width()
	var h := world_img.get_height()
	var scale := ray_amount * GodrayShader.OVERLAY_GAIN
	rays_img.convert(Image.FORMAT_RGB8)
	if rays_img.get_width() != w or rays_img.get_height() != h:
		rays_img.resize(w, h, Image.INTERPOLATE_BILINEAR)
	var fmt := world_img.get_format()
	if fmt != Image.FORMAT_RGB8 and fmt != Image.FORMAT_RGBA8:
		world_img.convert(Image.FORMAT_RGB8)
		fmt = Image.FORMAT_RGB8
	var stride := 4 if fmt == Image.FORMAT_RGBA8 else 3
	var wb := world_img.get_data()
	var rb := rays_img.get_data()
	var n := w * h
	for i in n:
		var ro := i * 3
		var rr := rb[ro]
		var rg := rb[ro + 1]
		var rb_c := rb[ro + 2]
		if (rr | rg | rb_c) == 0:
			continue
		var wo := i * stride
		wb[wo] = mini(wb[wo] + int(float(rr) * scale), 255)
		wb[wo + 1] = mini(wb[wo + 1] + int(float(rg) * scale), 255)
		wb[wo + 2] = mini(wb[wo + 2] + int(float(rb_c) * scale), 255)
	return Image.create_from_data(w, h, false, fmt, wb)
