class_name HistoryScreen
extends Control

signal place_selected(lat: float, lon: float)
signal back_requested

var _list: GridContainer
var _store: CacheStore
var _margin: MarginContainer
var _title: Label
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
	col.add_theme_constant_override("separation", 8)
	_margin.add_child(col)
	_title = UiTheme.label("History", 34, UiTheme.INK, true)
	col.add_child(_title)
	col.add_child(UiTheme.label("Saved places", 17, UiTheme.MUTED))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	_list = GridContainer.new()
	_list.columns = 1
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("h_separation", 14)
	_list.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_list)
	var back := UiTheme.ghost_button("← Back to map")
	back.pressed.connect(func() -> void: back_requested.emit())
	col.add_child(back)
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
	_title.add_theme_font_size_override("font_size", Responsive.title_size(layout) + 6)

func bind_store(store: CacheStore) -> void:
	_store = store
	refresh()

func refresh() -> void:
	if _list == null:
		return
	for child in _list.get_children():
		child.queue_free()
	if _store == null or _store.entries.is_empty():
		var empty := UiTheme.label(
			"No places yet. Render a location and it will appear here.", 16, UiTheme.MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(empty)
		return
	_list.columns = Responsive.history_columns(_current_layout)
	for entry in _store.entries:
		var lat := float(entry.get("lat", 0.0))
		var lon := float(entry.get("lon", 0.0))
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 118)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel",
			UiTheme.style(UiTheme.CARD, 16, Color.TRANSPARENT, true))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)
		var thumb := PanelContainer.new()
		thumb.custom_minimum_size = Vector2(76, 76)
		thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		thumb.add_theme_stylebox_override("panel", UiTheme.style(Color(0.72, 0.78, 0.72), 12))
		var thumb_label := UiTheme.label("◭", 26, Color.WHITE)
		thumb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		thumb_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		thumb.add_child(thumb_label)
		row.add_child(thumb)
		var texts := VBoxContainer.new()
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texts.add_theme_constant_override("separation", 4)
		row.add_child(texts)
		var name_label := UiTheme.label(str(entry.get("name", "Place")), 18, UiTheme.INK, true)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texts.add_child(name_label)
		texts.add_child(UiTheme.label("⬇ Cached · works offline", 14, UiTheme.TEAL))
		texts.add_child(UiTheme.label("%.4f°, %.4f°" % [lat, lon], 13, UiTheme.MUTED))
		var open_btn := UiTheme.primary_button("Open 360° View")
		open_btn.custom_minimum_size = Vector2(0, 48)
		open_btn.pressed.connect(func() -> void: place_selected.emit(lat, lon))
		texts.add_child(open_btn)
		_list.add_child(card)
