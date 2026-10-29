class_name ViewChrome
extends RefCounted

## HUD chrome for View360: theme refresh, place pill, hint and
## resize handling. Operates on the view's controls via `v`.
static func refresh_theme(v: View360) -> void:
	if v._top == null:
		return
	var place := v._place_pill.text
	var attribution := v._attribution_label.text
	var weather := v._weather_label.text
	var weather_shown := v._weather_label.visible
	var quality := v._quality_label.text
	var compass := v._compass.text
	var season := v._season_btn.selected
	var hint_shown := v._hint.visible
	for node in [v._top, v._bottom_root, v._hint_timer]:
		v.remove_child(node)
		node.queue_free()
	v._build_hud()
	v._place_pill.text = place
	v._attribution_label.text = attribution
	v._weather_label.text = weather
	v._weather_label.visible = weather_shown
	v._quality_label.text = quality
	v._compass.text = compass
	v._season_btn.select(season)
	v._hint.visible = hint_shown
	_fit_place_pill(v)
	_on_resized(v)
	v._sync_time_ui()

static func _dismiss_hint(v: View360) -> void:
	if v._hint == null or not v._hint.visible or v._hint.modulate.a < 1.0:
		return
	var tw := v.create_tween()
	tw.tween_property(v._hint, "modulate:a", 0.0, 0.5)
	tw.tween_callback(v._hint.hide)

static func _show_hint(v: View360) -> void:
	if v._hint == null:
		return
	v._hint.modulate.a = 1.0
	v._hint.show()
	if v._hint_timer.is_inside_tree():
		v._hint_timer.start()

## Long place names ellipsize instead of pushing the compass off
## screen; short ones keep the pill hugging the text.
static func _fit_place_pill(v: View360) -> void:
	if v._place_pill == null:
		return
	var font := v._place_pill.get_theme_font("font")
	var font_size := v._place_pill.get_theme_font_size("font_size")
	var text_w := font.get_string_size(v._place_pill.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var room := v.size.x - v._top.offset_left + v._top.offset_right - 96 - 56 - 36 - 30
	v._place_pill.custom_minimum_size.x = clampf(ceilf(text_w) + 2, 40.0, maxf(room, 40.0))

static func _on_look_changed(v: View360) -> void:
	v._compass.text = v._rig.compass_text()
	_dismiss_hint(v)

static func _on_resized(v: View360) -> void:
	if v._top == null:
		return
	var layout := Responsive.layout_for_width(v.size.x)
	var pad := Responsive.page_padding(layout)
	v._top.offset_left = pad
	v._top.offset_right = -pad
	v._top.offset_top = pad
	v._bottom_root.offset_left = pad
	v._bottom_root.offset_right = -pad
	v._bottom_root.offset_bottom = -pad
	var sheet_width := int(v.size.x) - pad * 2
	if Responsive.is_split(layout):
		sheet_width = mini(sheet_width, 640)
	v._sheet.custom_minimum_size = Vector2(maxi(sheet_width, 280), 0)
	v._sun_icon.visible = Responsive.is_split(layout)
	_fit_place_pill(v)

