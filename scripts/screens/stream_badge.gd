class_name StreamBadge
extends PanelContainer

## Endless walk & fly: how far the stretch ahead has come while the
## WorldStreamer prepares it. Float glass (it carries a secondary line),
## radius-m, under the top-right status row: a static loader icon, the
## title with the percent in data-s, the stage it is on and a 4pt accent
## bar. The bar is SaveProgress's steady model: the data stages, then
## the build. It waits SHOW_DELAY_S so a cached stretch never flashes,
## stays while the HUD idles, and says "Way ahead ready" briefly once
## the build lands. The host places it (ViewTools.layout).

const W := 260.0
const SHOW_DELAY_S := 0.6
const READY_HOLD_S := 1.6

var _icon: TextureRect
var _title: Label
var _percent: Label
var _detail: Label
var _bar: ProgressBar
var _model: SaveProgress
var _since := 0.0
var _ready_left := 0.0
var _ready_shown := false
var _leaving := false
## Visibility at the last follow(): the fade-out hides the badge from a
## tween callback, so the next follow() still reports that change.
var _was_visible := false
var _tween: Tween

func _init() -> void:
	visible = false
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(W, 0)
	var st := UiTheme.style(UiTheme.CARD, UiTheme.RADIUS_M, UiTheme.GLASS_EDGE, true)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 10
	st.content_margin_bottom = 12
	add_theme_stylebox_override("panel", st)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(head)
	_icon = UiIcon.rect("loader-circle", 16, UiTheme.TEAL)
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(_icon)
	_title = UiTheme.label("Preparing the way ahead", 14, UiTheme.INK, true)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.clip_text = true
	head.add_child(_title)
	_percent = UiTheme.data_label("", 13, UiTheme.MUTED)
	head.add_child(_percent)
	_detail = UiTheme.label("", 14, UiTheme.MUTED)
	_detail.clip_text = true
	col.add_child(_detail)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.min_value = 0.0
	_bar.max_value = 1.0
	_bar.custom_minimum_size = Vector2(0, 4)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_bar)
	refresh_theme()

## Re-skin after an accent or theme change.
func refresh_theme() -> void:
	var track := UiTheme.style(UiTheme.LINE, UiTheme.RADIUS_PILL)
	track.set_content_margin_all(0)
	var fill := UiTheme.style(UiTheme.TEAL, UiTheme.RADIUS_PILL)
	fill.set_content_margin_all(0)
	_bar.add_theme_stylebox_override("background", track)
	_bar.add_theme_stylebox_override("fill", fill)
	_icon.modulate = UiTheme.TEAL

## Per frame from View360: follows the streamer's generation in flight.
## Returns true when the badge appeared or went away (the HUD re-lays).
func follow(s: WorldStreamer, dt: float) -> bool:
	var was := _was_visible
	if s.enabled and s.state == WorldStreamer.State.FETCHING and s.progress != null:
		if s.progress != _model:
			_model = s.progress  # a new (or redirected) build starts at 0
			_since = 0.0
			_title.text = "Preparing the way ahead"
			_icon.texture = UiIcon.texture("loader-circle", 16)
		_since += dt
		_ready_shown = false
		_model.build_step = s.build_step()
		_model.tick(dt)
		if _since >= SHOW_DELAY_S:
			_show_progress(s)
			_appear()
	elif s.state == WorldStreamer.State.READY and visible and _model == s.progress:
		if not _ready_shown:
			_ready_shown = true
			_ready_left = READY_HOLD_S
			_show_ready()
		_ready_left -= dt
		if _ready_left <= 0.0:
			_disappear()
	else:
		_disappear()
	_was_visible = visible
	return visible != was

func _show_progress(s: WorldStreamer) -> void:
	_percent.text = "%d%%" % _model.percent()
	_bar.value = _model.shown
	if _model.phase == SaveProgress.Phase.DOWNLOAD:
		# The first data stage still on its way, named as the loading
		# screen names it.
		var i := s.stages_done.find(false)
		_detail.text = GenerationPipeline.STAGES[i] if i >= 0 else "Building the scene"
	else:
		_detail.text = "Building the scene · %s" % BuildAbort.label_of(_model.build_step)

func _show_ready() -> void:
	_title.text = "Way ahead ready"
	_icon.texture = UiIcon.texture("check", 16)
	_percent.text = "100%"
	_detail.text = "Detailed ground continues as you go"
	_bar.value = 1.0

func _appear() -> void:
	if visible and not _leaving:
		return
	_leaving = false
	visible = true
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, UiPrefs.motion(0.24))

## Fades out over duration-quick; the next build starts a fresh model.
func _disappear() -> void:
	_model = null
	if not visible or _leaving:
		return
	_leaving = true
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, UiPrefs.motion(0.16))
	_tween.tween_callback(func() -> void:
		_leaving = false
		hide())
