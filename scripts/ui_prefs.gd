class_name UiPrefs
extends RefCounted

## The person's Appearance, accessibility, Units and Cache choices
## (RenderSettings.prefs) applied to the app: units for UiTheme's data
## formats, the cache size cap, and the accessibility switches every
## screen reads. Reduce motion, Solid panels and Increase contrast follow
## the OS (macOS / iOS / Android settings) until the person sets them in
## Settings.

## Motion: springs, glides and morphs become cross-fades or steps.
static var reduce_motion := false
## Reduce transparency / "Solid panels": glass becomes sky-200.
static var solid_panels := false
## Increase contrast: ink-muted reads as ink, line as line-strong, and
## the glass edge thickens.
static var high_contrast := false
## The 360 viewer's own switches: names along the skyline, the mini-map
## inset, the stamp on saved photos, the FPS counter and the size of
## recorded videos (VideoRecorder.QUALITY_LONG index), and the folder
## they save to with no dialog ("" asks every time; PhotoMode.chosen_video_dir).
static var horizon_labels := false
static var minimap := false
static var photo_stamp := true
static var fps_counter := false
static var haze := true
static var video_quality := 1
static var video_dir := ""

static func apply(s: RenderSettings) -> void:
	UiTheme.units_imperial = bool(s.pref("imperial"))
	UiTheme.units_dms = bool(s.pref("dms"))
	UiTheme.units_12h = bool(s.pref("clock_12h"))
	reduce_motion = _or_os(s.pref("reduce_motion"), "accessibility_should_reduce_animation")
	solid_panels = _or_os(s.pref("solid_panels"), "accessibility_should_reduce_transparency")
	high_contrast = _or_os(s.pref("high_contrast"), "accessibility_should_increase_contrast")
	horizon_labels = bool(s.pref("horizon_labels"))
	minimap = bool(s.pref("minimap"))
	photo_stamp = bool(s.pref("photo_stamp"))
	fps_counter = bool(s.pref("fps_counter"))
	haze = s.haze_pref()
	video_quality = clampi(int(s.pref("video_quality")), 0, VideoRecorder.QUALITY_LONG.size() - 1)
	var vd: Variant = s.pref("video_dir")
	video_dir = vd if vd is String else ""
	LoadingScreen.reduce_motion = reduce_motion
	UiTheme.text_scale = clampf(float(s.pref("text_scale")), 0.85, 2.0)
	UiTheme.apply_mode(int(s.pref("theme")))

## A set choice wins; unset (null) asks the OS when it can tell.
static func _or_os(value: Variant, os_query: String) -> bool:
	if value != null:
		return bool(value)
	if DisplayServer.has_method(os_query):
		return bool(DisplayServer.call(os_query))
	return false

## Seconds for a motion token, or 0 under reduced motion.
static func motion(seconds: float) -> float:
	return 0.0 if reduce_motion else seconds
