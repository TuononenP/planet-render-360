class_name AccentSun
extends RefCounted

## Auto accent (design system, Colour > Accents): when Auto is on, the
## accent follows the sun at the place being shown, or at the map's
## selected point when no scene is up. Sun below -6 deg is Aurora,
## rising to +10 deg is Dawn, daylight is Glacier, setting down to
## +6 deg is Dusk. Lichen is manual only; Glacier is the fallback.
## A change cross-fades over duration-slow (0.6 s) in a few steps, so
## scrubbing the sun arc visibly tints the instrument without
## restyling every screen on every frame.

const GLACIER := 0
const AURORA := 1
const DUSK := 2
const DAWN := 3

const FADE_SECONDS := 0.6
const FADE_STEPS := 10

## Set by Main: restyles every screen after the accent colour moved.
static var refresh := Callable()
static var _tween: Tween = null
static var _target := -1

## The accent index (UiTheme.ACCENTS order) for a sun elevation in
## degrees; `rising` is true before solar noon.
static func index_for(elevation: float, rising: bool) -> int:
	if elevation < -6.0:
		return AURORA
	if rising and elevation < 10.0:
		return DAWN
	if not rising and elevation < 6.0:
		return DUSK
	return GLACIER

## Follow the sun at (lat, lon) for a UTC date ({year, month, day}) and hour.
static func follow(lat: float, lon: float, date: Dictionary, utc_hour: float) -> void:
	if not UiTheme.auto_mode:
		return
	var sp := SolarPosition.compute(lat, lon, date, utc_hour)
	go(index_for(float(sp["elevation"]), float(sp["hour_angle"]) < 0.0))

## Follow the sun at (lat, lon) right now (the device clock, in UTC).
static func follow_now(lat: float, lon: float) -> void:
	if not UiTheme.auto_mode:
		return
	var now := Time.get_datetime_dict_from_unix_time(int(Time.get_unix_time_from_system()))
	follow(lat, lon, now, float(now["hour"]) + float(now["minute"]) / 60.0)

## Follow the sun an atmosphere rig sees at its local clock hour.
static func follow_atmos(atmos: AtmosphereRig, hour_f: float) -> void:
	if not UiTheme.auto_mode or atmos == null:
		return
	var sp := atmos.solar_at(hour_f)
	go(index_for(float(sp["elevation"]), float(sp["hour_angle"]) < 0.0))

## Move the live accent to ACCENTS[index], gliding when a scene tree
## is there to run the tween (tests and tools snap instead).
static func go(index: int) -> void:
	if index == _target:
		return
	cancel()
	_target = index
	var from := UiTheme.TEAL
	UiTheme.theme_index = index
	var to := UiTheme.ACCENTS[index]
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or from.is_equal_approx(to):
		_paint(to)
		return
	_tween = tree.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var last := [-1]
	_tween.tween_method(func(t: float) -> void:
		var step := roundi(t * FADE_STEPS)
		if step == last[0]:
			return
		last[0] = step
		_paint(from.lerp(to, float(step) / FADE_STEPS)), 0.0, 1.0, FADE_SECONDS)
	_tween.finished.connect(func() -> void: _tween = null)

## Stop a fade in flight (a manual pick, or Auto turned off).
static func cancel() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	_target = -1

static func _paint(c: Color) -> void:
	UiTheme.set_accent(c)
	if refresh.is_valid():
		refresh.call()
