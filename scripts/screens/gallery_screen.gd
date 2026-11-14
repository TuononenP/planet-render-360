class_name GalleryScreen
extends Control

## Gallery of what the viewer saved, in three tabs: Photos and Videos
## (MediaLibrary) and 360° photos (PanoramaLibrary, PLAN-gallery-360.md),
## newest-first as cards (grid) or rows (list), like History. Tap opens a
## 360° photo in PanoramaViewer and a photo or video in MediaViewer.
## Deleting a 360° photo removes only the in-app library copy, never an
## exported file elsewhere; deleting a photo or video removes its file.

signal panorama_selected(entry: Dictionary)
## A photo or video (a MediaLibrary entry).
signal media_selected(entry: Dictionary)
signal back_requested

enum Category { PHOTOS, VIDEOS, PANORAMAS }

const SWIPE := 80.0
## Each tab's empty card: icon, title, body.
const EMPTY := [
	["camera", "No photos yet", "Open a place and tap Save photo. The photo waits for you here."],
	["video", "No videos yet", "Open a place and tap Record. When you stop, the video waits for you here to play back."],
	["rotate-3d", "No 360° photos yet", "Open a place, tap Save 360°, and the photo waits for you here to look around in. "
		+ "Photos saved before Gallery arrived may live in your Pictures folder."],
]

var _list: GridContainer
var _margin: MarginContainer
var _count_label: Label
var _view_seg: SegmentedControl
var _kind_seg: SegmentedControl
## The tab shown (-1 until the first refresh picks one that has saves).
var _category := -1
var _grid_mode := true
var _touch := OS.has_feature("mobile")
var _current_layout: int = Responsive.Layout.COMPACT
var _stale_cards := false
var _col: VBoxContainer
var _menu: PopupMenu
var _menu_entry: Dictionary = {}
var _toast: Toast
## Older saves are adopted from the photo folder once per session: every
## new save registers in the library directly, so later scans find nothing.
var _imported := false
## Background rebuild of missing thumbnails (-1 none).
var _thumb_task := -1
## [entry, fields] pairs the rebuild learnt, for MediaLibrary.update.
var _learnt: Array = []

## Brief message at the bottom (e.g. a photo that could not be opened).
func toast(title: String, message: String = "", tone: String = "neutral") -> void:
	if _toast == null:
		return
	_toast.show_message(title, message, tone)
	_toast.place(size, 16.0, size.y - 16.0, size.x < 700.0)

func _ready() -> void:
	set_process(false)  # only while a thumbnail rebuild runs
	visibility_changed.connect(func() -> void:
		if visible and _stale_cards:
			refresh())
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
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	col.add_child(header)
	var back := UiTheme.icon_button("")
	UiIcon.apply(back, "arrow-left", 22)
	back.tooltip_text = "Back to map"
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 2)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	titles.add_child(UiTheme.display_label("Gallery", 28))
	_count_label = UiTheme.label("", 14, UiTheme.MUTED)
	_count_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titles.add_child(_count_label)
	_view_seg = SegmentedControl.new(["Grid", "List"], ["layout-grid", "list"])
	_view_seg.set_icon_only(true)
	_view_seg.select(0)
	_view_seg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_view_seg.item_selected.connect(func(i: int) -> void:
		_grid_mode = i == 0
		_on_resized()
		refresh())
	header.add_child(_view_seg)
	_kind_seg = SegmentedControl.new(["Photos", "Videos", "360°"], ["camera", "video", "rotate-3d"])
	_kind_seg.item_selected.connect(func(i: int) -> void:
		_category = i
		refresh())
	col.add_child(_kind_seg)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 16)
	_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_col)
	_list = GridContainer.new()
	_list.columns = 1
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("h_separation", 16)
	_list.add_theme_constant_override("v_separation", 16)
	_col.add_child(_list)
	_menu = PopupMenu.new()
	_menu.add_item("Open", 0)
	_menu.add_item("Delete from Gallery", 1)
	_menu.id_pressed.connect(func(id: int) -> void:
		if id == 0:
			_open(_menu_entry)
		else:
			_confirm_delete(_menu_entry))
	add_child(_menu)
	_toast = Toast.new()
	add_child(_toast)
	resized.connect(_on_resized)
	_on_resized()

func _on_resized() -> void:
	if _count_label == null:
		return
	var layout := Responsive.layout_for_width(size.x)
	if (layout == Responsive.Layout.COMPACT) != (_current_layout == Responsive.Layout.COMPACT):
		if is_visible_in_tree():
			call_deferred("refresh")
		else:
			_stale_cards = true
	_current_layout = layout
	var pad := Responsive.page_padding(layout)
	Responsive.apply_safe_margins(_margin, self, [pad, pad + 8, pad, pad])
	if _list != null:
		_list.columns = Responsive.history_columns(layout) if _grid_mode else 1
	# Phones: the tabs span the width; wider screens keep them compact.
	if _kind_seg != null:
		var compact := layout == Responsive.Layout.COMPACT
		_kind_seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_SHRINK_BEGIN
		_kind_seg.custom_minimum_size.x = 0.0 if compact else 340.0

func refresh() -> void:
	if _list == null:
		return
	_stale_cards = false
	if not _imported:
		_imported = true
		PanoramaLibrary.import_existing()
		MediaLibrary.import_existing()
	for child in _list.get_children():
		child.queue_free()
	if _category < 0:
		_category = _first_with_saves()
	_kind_seg.select(_category)
	var rows := _rows(_category)
	var noun: String = ["photo", "video", "360° photo"][_category]
	_count_label.text = "%d %s%s on this device" % [rows.size(), noun, "" if rows.size() == 1 else "s"] \
		if not rows.is_empty() else "%s you save wait here, on this device." % ["Photos", "Videos", "360° photos"][_category]
	_view_seg.visible = not rows.is_empty()
	_on_resized()
	if rows.is_empty():
		_list.columns = 1
		_list.add_child(_empty_card())
		return
	for e in rows:
		_list.add_child(_card(e) if _grid_mode else _row(e))
	_rebuild_missing_thumbs(rows)

## The saves on tab `category`, newest first.
static func _rows(category: int) -> Array:
	match category:
		Category.PHOTOS:
			return MediaLibrary.entries(MediaLibrary.PHOTO)
		Category.VIDEOS:
			return MediaLibrary.entries(MediaLibrary.VIDEO)
	return PanoramaLibrary.entries()

## The first tab, in order, that has anything saved (Photos when none has).
static func _first_with_saves() -> int:
	for c in [Category.PHOTOS, Category.VIDEOS, Category.PANORAMAS]:
		if not _rows(c).is_empty():
			return c
	return Category.PHOTOS

## A photo or video row (MediaLibrary) rather than a 360° photo.
static func _is_media(e: Dictionary) -> bool:
	return e.has("kind")

func _open(e: Dictionary) -> void:
	if _is_media(e):
		media_selected.emit(e)
	else:
		panorama_selected.emit(e)

## Theme/accent changed: rebuild now if showing, else on next show.
func refresh_theme() -> void:
	if is_visible_in_tree():
		refresh()
	else:
		_stale_cards = true

func _rebuild_missing_thumbs(rows: Array) -> void:
	if _thumb_task != -1:
		return
	var missing := rows.filter(func(e: Dictionary) -> bool:
		return not (MediaLibrary.has_thumb(e) if _is_media(e) else PanoramaLibrary.has_thumb(e)))
	if missing.is_empty():
		return
	# What a media rebuild learns (a size, a length) is written to the
	# index on the main thread once the task is done.
	_learnt = []
	var learnt := _learnt
	_thumb_task = WorkerThreadPool.add_task(func() -> void:
		for e in missing:
			if _is_media(e):
				var got := MediaLibrary.rebuild_thumb(e)
				got.erase("ok")
				learnt.append([e, got])
			else:
				PanoramaLibrary.rebuild_thumb(e), false, "Gallery thumbnails")
	set_process(true)

func _process(_delta: float) -> void:
	if _thumb_task == -1 or not WorkerThreadPool.is_task_completed(_thumb_task):
		return
	WorkerThreadPool.wait_for_task_completion(_thumb_task)
	_thumb_task = -1
	set_process(false)
	for pair in _learnt:
		MediaLibrary.update(pair[0], pair[1])
	_learnt = []
	# Thumbs that still failed stay placeholders; refresh won't retry
	# them in a loop because only a fresh refresh() starts a task.
	if is_visible_in_tree():
		_refresh_cards_only()
	else:
		_stale_cards = true

## Rebuilds the cards without re-checking for missing thumbs (so a JPEG
## that cannot make a thumbnail is not retried on every completion).
func _refresh_cards_only() -> void:
	var task := _thumb_task
	_thumb_task = -2  # blocks _rebuild_missing_thumbs during this refresh
	refresh()
	_thumb_task = task

func _exit_tree() -> void:
	_join_thumbs()

## The thumbnail task must not outlive the screen, also when it is freed
## without leaving the tree.
func _join_thumbs() -> void:
	if _thumb_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_thumb_task)
		_thumb_task = -1

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_join_thumbs()

func _empty_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 240)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UiTheme.style(UiTheme.SURFACE, UiTheme.RADIUS_L, UiTheme.LINE))
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var copy: Array = EMPTY[_category]
	var icon := UiIcon.rect(str(copy[0]), 40, UiTheme.MUTED)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(icon)
	var title := UiTheme.label(str(copy[1]), 20, UiTheme.INK, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var body := UiTheme.label(str(copy[2]), 15, UiTheme.MUTED)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(body)
	var explore := UiTheme.primary_button("Back to map")
	explore.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	explore.pressed.connect(func() -> void: back_requested.emit())
	col.add_child(explore)
	return card

# --- Cards and rows ---

func _meta(e: Dictionary) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if e.has("timestamp"):
		var when := UiTheme.label(UiTheme.relative_time(float(e["timestamp"])), 14, UiTheme.FAINT)
		when.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(when)
	var bytes := int(e.get("bytes", 0))
	if bytes > 0:
		var sz := UiTheme.data_label(UiTheme.cache_size(bytes), 13, UiTheme.MUTED, true)
		sz.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(sz)
	if e.has("duration_s"):
		var length := UiTheme.data_label(MediaViewer.clock_text(float(e["duration_s"])), 13, UiTheme.MUTED, true)
		length.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(length)
	var dims := "%d×%d" % [int(e.get("width", 0)), int(e.get("height", 0))]
	if int(e.get("width", 0)) > 0:
		var d := UiTheme.data_label(dims, 13, UiTheme.MUTED, true)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(d)
	return row

func _thumb(e: Dictionary, height: float) -> Control:
	var video := str(e.get("kind", "")) == MediaLibrary.VIDEO
	var tex := MediaLibrary.thumb_texture(e) if _is_media(e) else PanoramaLibrary.thumb_texture(e)
	if tex != null:
		var photo := RoundedPhoto.new(tex, UiTheme.RADIUS_S)
		photo.custom_minimum_size = Vector2(0, height)
		if video:
			photo.add_child(_play_mark(height))
		return photo
	var thumb := PanelContainer.new()
	thumb.custom_minimum_size = Vector2(0, height)
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.add_theme_stylebox_override("panel", UiTheme.style(Color("1a2350").darkened(0.55), UiTheme.RADIUS_S))
	var glyph_name := "rotate-3d" if not _is_media(e) else ("video" if video else "camera")
	var glyph := UiIcon.rect(glyph_name, 32, Color(UiTheme.HORIZON_DAY, 0.85))
	glyph.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	thumb.add_child(glyph)
	return thumb

## A round glass play button over a video's thumbnail.
func _play_mark(height: float) -> Control:
	var d := 40.0 if height >= 100.0 else 28.0
	var mark := PanelContainer.new()
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.add_theme_stylebox_override("panel", UiTheme.style(UiTheme.GLASS_FILL, UiTheme.RADIUS_PILL, UiTheme.GLASS_EDGE))
	mark.custom_minimum_size = Vector2(d, d)
	mark.set_anchors_preset(Control.PRESET_CENTER)
	mark.offset_left = -d / 2.0
	mark.offset_top = -d / 2.0
	mark.offset_right = d / 2.0
	mark.offset_bottom = d / 2.0
	var icon := UiIcon.rect("play", int(d / 2.0), UiTheme.INK)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.add_child(icon)
	return mark

func _card(e: Dictionary) -> Button:
	var card := _base_button(e)
	var col := VBoxContainer.new()
	_inset(col)
	col.add_theme_constant_override("separation", 8)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(col)
	col.add_child(_thumb(e, 120.0 if _current_layout == Responsive.Layout.COMPACT else 150.0))
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(head)
	var name_label := UiTheme.display_label(str(e.get("place", "View")), 22)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(name_label)
	head.add_child(_delete_button(e))
	col.add_child(_meta(e))
	_fit(card, col, 0.0)
	return card

func _row(e: Dictionary) -> Button:
	var row := _base_button(e)
	var r := HBoxContainer.new()
	_inset(r)
	r.add_theme_constant_override("separation", 12)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(r)
	var thumb := _thumb(e, 56.0)
	thumb.custom_minimum_size.x = 100
	thumb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(thumb)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_child(texts)
	var title := UiTheme.label(str(e.get("place", "View")), 17, UiTheme.INK, true)
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(title)
	texts.add_child(_meta(e))
	var del := _delete_button(e)
	del.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(del)
	_fit(row, r, 76.0)
	row.gui_input.connect(func(ev: InputEvent) -> void: _swipe(row, e, ev))
	return row

func _delete_button(e: Dictionary) -> Button:
	var trash := Button.new()
	trash.custom_minimum_size = Vector2(44, 44)
	trash.tooltip_text = "Delete from Gallery"
	UiIcon.apply(trash, "trash-2", 20, UiTheme.SIGNAL_ERROR, UiTheme.SIGNAL_ERROR)
	var clear := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_PILL)
	clear.set_content_margin_all(0)
	trash.add_theme_stylebox_override("normal", clear)
	trash.add_theme_stylebox_override("hover", UiTheme.style(UiTheme.LINE, UiTheme.RADIUS_PILL))
	trash.add_theme_stylebox_override("pressed", UiTheme.style(UiTheme.LINE, UiTheme.RADIUS_PILL))
	trash.pressed.connect(func() -> void: _confirm_delete(e))
	return trash

func _confirm_delete(e: Dictionary) -> void:
	if e.is_empty():
		return
	if _is_media(e):
		var video := str(e.get("kind", "")) == MediaLibrary.VIDEO
		SettingsRows.confirm(self, "Delete this video?" if video else "Delete this photo?",
			"“%s” will be deleted from this device." % str(e.get("place", "View")), "Delete",
			func() -> void:
				MediaLibrary.remove(e)
				refresh())
		return
	SettingsRows.confirm(self, "Delete this 360° photo?",
		"“%s” will be removed from Gallery on this device. A copy you exported elsewhere (for example to Pictures) stays."
		% str(e.get("place", "View")), "Delete", func() -> void:
			PanoramaLibrary.remove(e)
			refresh())

func _swipe(row: Button, e: Dictionary, ev: InputEvent) -> void:
	if ev is InputEventScreenDrag:
		if not row.has_meta("rest_x"):
			row.set_meta("rest_x", row.position.x)
		# No clamp before the threshold (HistoryScreen precedent): a
		# clamp at -SWIPE would make `dx < -SWIPE` on release unreachable.
		row.position.x = float(row.get_meta("rest_x")) + minf(
			row.position.x - float(row.get_meta("rest_x")) + (ev as InputEventScreenDrag).relative.x, 0.0)
		row.accept_event()
	elif ev is InputEventScreenTouch and not (ev as InputEventScreenTouch).pressed and row.has_meta("rest_x"):
		var dx := row.position.x - float(row.get_meta("rest_x"))
		row.position.x = float(row.get_meta("rest_x"))
		row.remove_meta("rest_x")
		if dx < -SWIPE:
			_confirm_delete(e)

func _base_button(e: Dictionary) -> Button:
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.tooltip_text = str(e.get("place", ""))
	var st := UiTheme.style(UiTheme.SURFACE, UiTheme.RADIUS_M, UiTheme.LINE)
	st.set_content_margin_all(12)
	var lit := st.duplicate() as StyleBoxFlat
	lit.border_color = UiTheme.LINE_STRONG
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", lit)
	b.add_theme_stylebox_override("pressed", lit)
	b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_M))
	b.pressed.connect(func() -> void:
		if absf(b.position.x - float(b.get_meta("rest_x", b.position.x))) < 4.0:
			_open(e))
	b.gui_input.connect(func(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			_menu_entry = e
			_menu.position = Vector2i(get_screen_position() + get_local_mouse_position())
			_menu.popup())
	return b

func _fit(b: Button, content: Control, floor_h: float) -> void:
	var sync := func() -> void:
		b.custom_minimum_size.y = maxf(floor_h, content.get_combined_minimum_size().y + 24.0)
	content.minimum_size_changed.connect(sync)
	b.ready.connect(sync)

func _inset(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = 12
	c.offset_top = 12
	c.offset_right = -12
	c.offset_bottom = -12
