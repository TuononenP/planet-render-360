class_name LightningRig
extends Node3D

## Thunderstorm lightning for AtmosphereRig: only while the live weather
## is a thunderstorm (WMO 95/96/99); otherwise idle at no cost.
##
## - Strikes arrive as a Poisson process: mean gap by storm strength,
##   stretched by season (summer convective peak, rare winter storms).
## - Each strike is a return stroke plus 0-2 re-strokes on the same
##   channel within ~1 s. Between strokes the light never dips below
##   40%, so it reads as one flickering flash: at most 3 distinct
##   flashes in any second (photosensitivity guideline).
## - Most strikes stay inside the cloud (a sky glow only); the rest are
##   cloud-to-ground bolts. Winter "thundersnow" is mostly in-cloud with
##   a wider, softer glow and a lower cloud base.
## - The flash lights the scene through one shadowless directional light
##   from the strike, full at night and ~20% by day; the sky shader adds
##   the in-cloud glow (AtmosphereRig pushes `flash` / `flash_dir`).
## - A bolt is a midpoint-displaced channel with dimmer forks, drawn as
##   ribbons facing the viewpoint, additive and HDR so the glow pass
##   blooms it; it fades with the weather's own extinction. No bolt on
##   the lowest tier, no forks on Balanced.

## Mean seconds between strikes: ordinary storm, then hail storms.
const MEAN_GAP_S := 14.0
const MEAN_GAP_HAIL_S := 7.0
const MIN_GAP_S := 1.5
## Strike rate per season (spring, summer, autumn, winter).
const SEASON_RATE := [0.7, 1.0, 0.5, 0.25]
const GROUND_SHARE := 0.35
const GROUND_SHARE_WINTER := 0.15
const FLASH_COLOR := Color(0.80, 0.85, 1.0)
## Peak flash light energy at night for a strike 2 km away.
const FLASH_ENERGY := 2.4
## Flash strength left by full daylight.
const DAY_FLASH := 0.2
const DIP_FLOOR := 0.4
const CLOUD_BASE_M := 1800.0
const CLOUD_BASE_WINTER_M := 1200.0
const STRIKE_NEAR_M := 2000.0
const STRIKE_FAR_M := 9000.0
## Channel subdivision depth (2^n segments) and fork depth.
const MAIN_DEPTH := 7
const FORK_DEPTH := 5
## Bolt HDR brightness (above the glow threshold, PostGrade).
const BOLT_ENERGY := 12.0

const BOLT_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;
uniform vec3 bolt_color : source_color = vec3(0.85, 0.88, 1.0);
uniform float energy = 0.0;
void fragment() {
	// Hot core across the ribbon (UV.x 0..1), soft edges.
	float core = 1.0 - abs(UV.x * 2.0 - 1.0);
	ALBEDO = bolt_color * COLOR.r * energy * (core * core * 0.8 + 0.2);
}
"""

var active := false
## 0..1 envelope of the current strike and the light it puts out.
var flash_level := 0.0
var flash_energy := 0.0
## World direction toward the strike (for the sky glow) and the glow's
## narrowness (1 tight, 0 broad / diffused by rain or snow).
var flash_dir := Vector3.UP
var flash_spread := 1.0
var strike_count := 0
var ground_strikes := 0
var bolt_visible := false
## Most distinct flashes seen in any 1 s window (tests).
var max_flashes_per_s := 0
## Viewpoint the storm is placed around (world).
var centre := Vector3.ZERO
## (x, z) -> ground y; unset = y 0.
var ground_height: Callable
var light: DirectionalLight3D
var bolt: MeshInstance3D

var _rng := RandomNumberGenerator.new()
var _mean_gap := MEAN_GAP_S
var _ground_share := GROUND_SHARE
var _cloud_base := CLOUD_BASE_M
var _day_scale := 1.0
var _diffuse := 0.0
var _fog_per_m := 0.0
var _preset: int = RenderSettings.Preset.HIGH
var _gap := 0.0
var _clock := 0.0
## Current strike: stroke start times (s since strike start) and peaks.
var _strokes: Array = []
var _t := -1.0
var _onsets := 0
var _peak_energy := 0.0
var _bolt_energy := 0.0
var _recent: Array[float] = []
var _bolt_mat: ShaderMaterial

func _init() -> void:
	name = "Lightning"
	light = DirectionalLight3D.new()
	light.name = "Flash"
	light.light_color = FLASH_COLOR
	light.light_energy = 0.0
	light.shadow_enabled = false
	light.visible = false
	add_child(light)
	bolt = MeshInstance3D.new()
	bolt.name = "Bolt"
	bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bolt.visible = false
	var sh := Shader.new()
	sh.code = BOLT_SHADER
	_bolt_mat = ShaderMaterial.new()
	_bolt_mat.shader = sh
	bolt.material_override = _bolt_mat
	add_child(bolt)
	_rng.randomize()

func seed_rng(n: int) -> void:
	_rng.seed = n

## Storm state from the weather look; `daylight` 0 (night) .. 1 (full
## sun), `fog_per_m` the scene's extinction for distant bolts.
func set_conditions(look: Dictionary, season: int, daylight: float, preset: int, fog_per_m: float) -> void:
	var was := active
	active = bool(look.get("storm", false))
	_preset = RenderSettings.clamp_preset(preset)
	var winter := season == LocationData.Season.WINTER
	var rate: float = SEASON_RATE[LocationData.clamp_season(season)]
	_mean_gap = (MEAN_GAP_HAIL_S if bool(look.get("hail", false)) else MEAN_GAP_S) / rate
	_ground_share = GROUND_SHARE_WINTER if winter else GROUND_SHARE
	_cloud_base = CLOUD_BASE_WINTER_M if winter else CLOUD_BASE_M
	_day_scale = lerpf(1.0, DAY_FLASH, clampf(daylight, 0.0, 1.0))
	# Heavy rain and snow scatter the flash: lower peak, broader glow.
	_diffuse = clampf(float(look.get("intensity", 0.0)) * 0.6 + (0.4 if winter else 0.0), 0.0, 1.0)
	flash_spread = 1.0 - 0.6 * _diffuse
	_fog_per_m = fog_per_m
	if active and not was:
		_gap = _next_gap()
	if not active:
		_end_strike()

func _next_gap() -> float:
	return maxf(-_mean_gap * log(1.0 - _rng.randf() * 0.999), MIN_GAP_S)

## Advances the storm by `delta` seconds (AtmosphereRig._process, tests).
func step(delta: float) -> void:
	if not active:
		return
	_clock += delta
	if _t < 0.0:
		_gap -= delta
		if _gap <= 0.0:
			_begin_strike(_rng.randf() < _ground_share)
		return
	_t += delta
	_update_envelope()

## Starts a strike now (tests and the scheduler).
func force_strike(ground: bool) -> void:
	_begin_strike(ground)

func _begin_strike(ground: bool) -> void:
	strike_count += 1
	_t = 0.0
	_onsets = 0
	_strokes = [[0.0, 1.0]]
	var at := 0.0
	for i in _rng.randi_range(0, 2):
		at += _rng.randf_range(0.18, 0.4)
		_strokes.append([at, _rng.randf_range(0.5, 0.9)])
	var az := _rng.randf() * TAU
	var dist := _rng.randf_range(STRIKE_NEAR_M, STRIKE_FAR_M)
	var base := _cloud_base
	if not ground:
		# In-cloud flashes sit higher and anywhere in the deck.
		base *= _rng.randf_range(1.2, 2.2)
		dist *= _rng.randf_range(0.4, 1.0)
	var foot := centre + Vector3(sin(az) * dist, 0.0, -cos(az) * dist)
	foot.y = float(ground_height.call(foot.x, foot.z)) if ground_height.is_valid() else 0.0
	var top := foot + Vector3(0.0, base, 0.0)
	flash_dir = (top - centre).normalized()
	light.basis = Basis.looking_at(-flash_dir, Vector3.UP if absf(flash_dir.y) < 0.99 else Vector3.FORWARD)
	_peak_energy = FLASH_ENERGY * sqrt(STRIKE_NEAR_M / dist) * _day_scale * (1.0 - 0.4 * _diffuse)
	bolt_visible = false
	if ground:
		ground_strikes += 1
		if _preset > RenderSettings.Preset.FAST:
			_build_bolt(top, foot, _preset >= RenderSettings.Preset.HIGH)
			bolt_visible = true
			# The weather's extinction hazes far bolts, but a channel is
			# bright enough to punch through rain long past the visibility
			# of ordinary objects (only a fraction of it applies).
			_bolt_energy = BOLT_ENERGY * exp(-_fog_per_m * dist * 0.15) * lerpf(1.0, 0.5, 1.0 - _day_scale)
	light.visible = true
	bolt.visible = bolt_visible
	_update_envelope()

func _update_envelope() -> void:
	var level := 0.0
	var last_start := 0.0
	var started := 0
	for s in _strokes:
		var t0 := float(s[0])
		if _t < t0:
			continue
		started += 1
		last_start = t0
		level = maxf(level, float(s[1]) * exp(-(_t - t0) / 0.09))
	# Distinct flashes: count each stroke onset once.
	while _onsets < started:
		_onsets += 1
		_recent.append(_clock)
	_count_rate()
	if started < _strokes.size():
		level = maxf(level, DIP_FLOOR)
	flash_level = level
	flash_energy = level * _peak_energy
	light.light_energy = flash_energy
	_bolt_mat.set_shader_parameter("energy", _bolt_energy * level)
	if started == _strokes.size() and _t - last_start > 0.6:
		_end_strike()
		_gap = _next_gap()

func _count_rate() -> void:
	while not _recent.is_empty() and _clock - _recent[0] >= 1.0:
		_recent.pop_front()
	max_flashes_per_s = maxi(max_flashes_per_s, _recent.size())

func _end_strike() -> void:
	_t = -1.0
	_onsets = 0
	_strokes = []
	flash_level = 0.0
	flash_energy = 0.0
	bolt_visible = false
	if light != null:
		light.light_energy = 0.0
		light.visible = false
		bolt.visible = false

# --- Bolt geometry ---

func _build_bolt(top: Vector3, foot: Vector3, forks: bool) -> void:
	var main := _channel(top, foot, MAIN_DEPTH, 0.22)
	var width := 10.0 * clampf(top.distance_to(centre) / 5000.0, 0.6, 2.0)
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	_ribbon(main, width, 1.0, verts, uvs, cols)
	if forks:
		for i in _rng.randi_range(2, 4):
			var k := _rng.randi_range(int(main.size() * 0.1), int(main.size() * 0.7))
			var a: Vector3 = main[k]
			var drop := (foot.y - a.y) * _rng.randf_range(0.15, 0.4)
			var side := Vector3(_rng.randf_range(-1, 1), 0.0, _rng.randf_range(-1, 1)).normalized()
			var b := a + side * absf(drop) * _rng.randf_range(0.5, 1.0) + Vector3(0.0, drop, 0.0)
			_ribbon(_channel(a, b, FORK_DEPTH, 0.28), width * 0.5, 0.45, verts, uvs, cols)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cols
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	bolt.mesh = mesh

## Midpoint displacement: each level splits every segment and kicks the
## midpoint sideways by `rough` of the segment length.
func _channel(a: Vector3, b: Vector3, depth: int, rough: float) -> PackedVector3Array:
	var pts := PackedVector3Array([a, b])
	for _l in depth:
		var next := PackedVector3Array()
		for i in pts.size() - 1:
			var p: Vector3 = pts[i]
			var q: Vector3 = pts[i + 1]
			var seg := p.distance_to(q)
			var off := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.3, 0.3), _rng.randf_range(-1, 1))
			next.append(p)
			next.append((p + q) * 0.5 + off * seg * rough)
		next.append(pts[pts.size() - 1])
		pts = next
	return pts

## Quads along `pts` facing the viewpoint; brightness tapers to the tip.
func _ribbon(pts: PackedVector3Array, width: float, bright: float,
		verts: PackedVector3Array, uvs: PackedVector2Array, cols: PackedColorArray) -> void:
	var n := pts.size()
	for i in n - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var s := (b - a).cross(centre - a).normalized() * width * 0.5
		var ca := Color(bright * (1.0 - 0.5 * float(i) / n), 0, 0)
		var cb := Color(bright * (1.0 - 0.5 * float(i + 1) / n), 0, 0)
		for v in [[a - s, 0.0, ca], [a + s, 1.0, ca], [b + s, 1.0, cb],
				[a - s, 0.0, ca], [b + s, 1.0, cb], [b - s, 0.0, cb]]:
			verts.append(v[0])
			uvs.append(Vector2(v[1], 0.0))
			cols.append(v[2])
