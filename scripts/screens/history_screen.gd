class_name HistoryScreen
extends Control

signal place_selected(lat: float, lon: float)
signal back_requested

var _list: GridContainer
var _store: CacheStore
var _margin: MarginContainer
var _title: Label
var _count_label: Label
var _current_layout: int = Responsive.Layout.COMPACT

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	_margin.add_child(col)

	# Header: round back button, title + count, quiet "Clear all".
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	col.add_child(header)
	var back := UiTheme.icon_button("←")
	back.tooltip_text = "Back to map"
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 2)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	_title = UiTheme.label("Saved places", 34, UiTheme.INK, true)
	titles.add_child(_title)
	_count_label = UiTheme.label("", 14, UiTheme.MUTED)
	_count_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(_count_label)
	var clear_btn := UiTheme.ghost_button("Clear all")
	clear_btn.custom_minimum_size = Vector2(0, 44)
	clear_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	clear_btn.pressed.connect(func() -> void:
		if _store != null:
			_store.clear()
		refresh())
	header.add_child(clear_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_list = GridContainer.new()
	_list.columns = 1
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("h_separation", 20)
	_list.add_theme_constant_override("v_separation", 20)
	scroll.add_child(_list)
	resized.connect(_on_resized)
	_on_resized()
	if _store != null:
		refresh()

func _on_resized() -> void:
	if _title == null:
		return
	var layout := Responsive.layout_for_width(size.x)
	_current_layout = layout
	var pad := Responsive.page_padding(layout)
	_margin.add_theme_constant_override("margin_left", pad)
	_margin.add_theme_constant_override("margin_right", pad)
	_margin.add_theme_constant_override("margin_top", pad + 8)
	_margin.add_theme_constant_override("margin_bottom", pad)
	if _list != null:
		_list.columns = Responsive.history_columns(layout)
	_title.add_theme_font_size_override("font_size",
		Responsive.title_size(layout) + (0 if layout == Responsive.Layout.COMPACT else 6))

func bind_store(store: CacheStore) -> void:
	_store = store
	refresh()

func _card_style() -> StyleBoxFlat:
	var st := UiTheme.style(UiTheme.SURFACE, 24, Color(1, 1, 1, 0.08))
	st.set_content_margin_all(0)
	return st

func _chip(text: String) -> PanelContainer:
	var chip := PanelContainer.new()
	var st := UiTheme.style(Color(1, 1, 1, 0.06), 12)
	st.content_margin_left = 10
	st.content_margin_right = 10
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	chip.add_theme_stylebox_override("panel", st)
	chip.add_child(UiTheme.label(text, 12, Color(UiTheme.INK, 0.8)))
	return chip

func refresh() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		child.queue_free()
	var count := 0 if _store == null else _store.entries.size()
	_count_label.text = "%d place%s · stored on this device · open offline" \
		% [count, "" if count == 1 else "s"] if count > 0 \
		else "Places you render wait here, saved on this device."
	if count == 0:
		var empty_card := PanelContainer.new()
		empty_card.custom_minimum_size = Vector2(0, 240)
		empty_card.add_theme_stylebox_override("panel", UiTheme.glass_panel(28))
		var empty_col := VBoxContainer.new()
		empty_col.alignment = BoxContainer.ALIGNMENT_CENTER
		empty_col.add_theme_constant_override("separation", 8)
		empty_card.add_child(empty_col)
		var empty_icon := UiTheme.label("◭", 40, UiTheme.AMBER, true)
		empty_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_col.add_child(empty_icon)
		var empty_title := UiTheme.label("No places yet", 20, UiTheme.INK, true)
		empty_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_col.add_child(empty_title)
		var empty := UiTheme.label(
			"Pick a spot on the map, render it in 360°, and it will wait for you here.", 15, UiTheme.MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_col.add_child(empty)
		var explore := UiTheme.primary_button("Explore the map  →")
		explore.pressed.connect(func() -> void: back_requested.emit())
		empty_col.add_child(explore)
		_list.add_child(empty_card)
		return
	_list.columns = Responsive.history_columns(_current_layout)
	for entry in _store.entries:
		var lat := float(entry.get("lat", 0.0))
		var lon := float(entry.get("lon", 0.0))
		var place := str(entry.get("name", "Place"))
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _card_style())
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		card.add_child(col)
		# Preview band: a deep tint per place (stable hash) with a soft
		# horizon glow, so the list scans as places, not rows.
		var tints := [Color(0.13, 0.25, 0.30), Color(0.16, 0.22, 0.31), Color(0.27, 0.22, 0.17), Color(0.17, 0.27, 0.21)]
		var tint: Color = tints[abs(place.hash()) % tints.size()]
		var thumb := PanelContainer.new()
		thumb.custom_minimum_size = Vector2(0, 150 if _current_layout != Responsive.Layout.COMPACT else 120)
		var thumb_style := UiTheme.style(tint, 24)
		thumb_style.corner_radius_bottom_left = 0
		thumb_style.corner_radius_bottom_right = 0
		thumb.add_theme_stylebox_override("panel", thumb_style)
		var thumb_label := UiTheme.label("◭", 44, Color(UiTheme.AMBER, 0.85))
		thumb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		thumb_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		thumb.add_child(thumb_label)
		col.add_child(thumb)
		var body := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			body.add_theme_constant_override("margin_" + side, 18)
		col.add_child(body)
		var texts := VBoxContainer.new()
		texts.add_theme_constant_override("separation", 10)
		body.add_child(texts)
		var name_label := UiTheme.label(place, 22, UiTheme.INK, true)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texts.add_child(name_label)
		texts.add_child(UiTheme.label("%.4f° N · %.4f° E" % [lat, lon], 13, UiTheme.MUTED))
		var tags := HBoxContainer.new()
		tags.add_theme_constant_override("separation", 6)
		tags.add_child(_chip("⬇ Cached"))
		tags.add_child(_chip("Works offline"))
		texts.add_child(tags)
		var open_btn := UiTheme.primary_button("Open 360° view")
		open_btn.clip_text = true
		open_btn.custom_minimum_size = Vector2(0, 52)
		open_btn.pressed.connect(func() -> void: place_selected.emit(lat, lon))
		texts.add_child(open_btn)
		_list.add_child(card)
	# Shortcut tile: render another place without going back first.
	var add := Button.new()
	add.text = "+   Render a new place"
	add.custom_minimum_size = Vector2(0, 120)
	add.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add.add_theme_font_size_override("font_size", 16)
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		add.add_theme_color_override(key, UiTheme.TEAL)
	var dashed := UiTheme.style(Color.TRANSPARENT, 24, Color(UiTheme.TEAL, 0.4))
	add.add_theme_stylebox_override("normal", dashed)
	add.add_theme_stylebox_override("hover", UiTheme.style(UiTheme.TEAL_SOFT, 24, UiTheme.TEAL))
	add.add_theme_stylebox_override("pressed", UiTheme.style(UiTheme.TEAL_SOFT, 24, UiTheme.TEAL))
	add.pressed.connect(func() -> void: back_requested.emit())
	_list.add_child(add)
