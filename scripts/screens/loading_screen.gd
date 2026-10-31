class_name LoadingScreen
extends Control

## The descent screen (design system: LoadingScreen). No card around
## the content: a full-bleed horizon-night glow centred on the
## TerrainLens, the place set like an arrival title above it, and the
## stage card (StageProgress) beside it on wide windows or under it on
## phones. The lens fills in from real data as each stage lands.

signal cancel_requested

const NOTE := "First visits take a minute or two while we gather the terrain. Next time it opens instantly."
## Degraded layer key (DataNotes) -> the stage row that was waiting on it.
const LAYER_ROW := {"elevation": 0, "imagery": 1, "map": 2}
const BUILD_LABEL := "Building the scene"

var _title: Label
var _region: Label
var _coords: Label
var _eyebrow: Label
var _brand: TextureRect
var _margin: MarginContainer
var _flow: BoxContainer
var _hero: VBoxContainer
var _side: VBoxContainer
var _preview: TerrainLens  # the lens; shrinks, then hides, on short windows
var _card: PanelContainer  # the stage card
var _progress: ProgressBar
var _stage_label: Label
var _percent_label: Label
var _rows: Array = []  # {dot, name, detail, label, started} per pipeline stage
var _build_row: Dictionary = {}
var _eta_label: Label
var _note_row: HBoxContainer  # caution line while a data layer is not responding
var _note_label: Label
var _degraded: Array[String] = []
var _cancel_btn: Button
var _push: Control
var _two_col := false
var _active_index := -1
var _building := false
var _build_started_msec := 0
var _fit_queued := false

func _ready() -> void:
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_margin)
	_flow = BoxContainer.new()
	_flow.alignment = BoxContainer.ALIGNMENT_CENTER
	_margin.add_child(_flow)

	_hero = VBoxContainer.new()
	_hero.alignment = BoxContainer.ALIGNMENT_CENTER
	_hero.add_theme_constant_override("separation", 4)
	_hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_flow.add_child(_hero)
	_eyebrow = UiTheme.section_label("Building your view")
	_hero.add_child(_eyebrow)
	_title = UiTheme.display_label("", 48)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hero.add_child(_title)
	_region = UiTheme.label("", 15, UiTheme.MUTED)
	_hero.add_child(_region)
	_coords = UiTheme.data_label("", 15, UiTheme.MUTED)
	_hero.add_child(_coords)
	for l in [_eyebrow, _title, _region, _coords]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview = TerrainLens.new()
	_preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_preview.item_rect_changed.connect(queue_redraw)
	_hero.add_child(_preview)

	_side = VBoxContainer.new()
	_side.alignment = BoxContainer.ALIGNMENT_CENTER
	_side.add_theme_constant_override("separation", 12)
	_flow.add_child(_side)
	_card = PanelContainer.new()
	_side.add_child(_card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	_card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	_percent_label = UiTheme.data_label("0%", 24, UiTheme.INK, true)
	head.add_child(_percent_label)
	_stage_label = UiTheme.label("Starting…", 15, UiTheme.MUTED)
	_stage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stage_label.clip_text = true
	head.add_child(_stage_label)
	_progress = ProgressBar.new()
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0, 4)
	col.add_child(_progress)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	col.add_child(list)
	for stage in GenerationPipeline.STAGES:
		_rows.append(_make_row(list, stage))
	_build_row = _make_row(list, BUILD_LABEL)
	_eta_label = UiTheme.label(NOTE, 14, UiTheme.MUTED)
	_eta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_eta_label)
	_note_row = HBoxContainer.new()
	_note_row.add_theme_constant_override("separation", 8)
	_note_row.visible = false
	col.add_child(_note_row)
	var note_icon := TextureRect.new()
	note_icon.texture = UiIcon.texture("triangle-alert", 16)
	note_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	note_icon.custom_minimum_size = Vector2(16, 16)
	note_icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	note_icon.modulate = UiTheme.SIGNAL_CAUTION
	_note_row.add_child(note_icon)
	_note_label = UiTheme.label("", 14, UiTheme.SIGNAL_CAUTION)
	_note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_note_label.visible = false
	_note_row.add_child(_note_label)
	_push = Control.new()  # phones: holds Cancel at the bottom-left
	_push.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_push.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_side.add_child(_push)
	_cancel_btn = UiTheme.quiet_button("Cancel")
	_cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_cancel_btn.pressed.connect(func() -> void: cancel_requested.emit())
	_side.add_child(_cancel_btn)

	_brand = Brand.rect(Brand.MARK, 32)
	add_child(_brand)

	# Elapsed time while the scene builds (no byte count to show).
	var tick := Timer.new()
	tick.wait_time = 1.0
	tick.autostart = true
	tick.timeout.connect(_on_pulse)
	add_child(tick)

	_style()
	resized.connect(_on_resized)
	# While hidden no layout runs; refit from clean readings on show.
	visibility_changed.connect(func() -> void:
		if visible:
			_on_resized())
	_on_resized()

func _make_row(list: VBoxContainer, label: String) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(0, 24)
	var dot := StageDot.new()
	row.add_child(dot)
	var name_label := UiTheme.label(label, 15, UiTheme.MUTED)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	row.add_child(name_label)
	var detail := UiTheme.data_label("", 13, UiTheme.MUTED)
	row.add_child(detail)
	list.add_child(row)
	return {"dot": dot, "name": name_label, "detail": detail, "label": label,
		"started": 0, "degraded": false}

## Float glass for the stage card, the accent bar, the quiet Cancel.
func _style() -> void:
	var card := UiTheme.style(UiTheme.CARD, UiTheme.RADIUS_L, UiTheme.GLASS_EDGE, true)
	card.set_content_margin_all(20)
	_card.add_theme_stylebox_override("panel", card)
	var track := UiTheme.style(UiTheme.LINE, UiTheme.RADIUS_PILL)
	track.set_content_margin_all(0)
	var fill := UiTheme.style(UiTheme.TEAL, UiTheme.RADIUS_PILL)
	fill.set_content_margin_all(0)
	_progress.add_theme_stylebox_override("background", track)
	_progress.add_theme_stylebox_override("fill", fill)
	UiTheme.apply_quiet(_cancel_btn)

## Re-skin after an accent change.
func refresh_theme() -> void:
	if _card == null:
		return
	_style()
	_preview.queue_redraw()
	for row in _rows + [_build_row]:
		row["dot"].queue_redraw()

## Backdrop: sky-000 with a radial horizon-night glow and two faint
## rings centred on the lens (on the hero when the lens is hidden).
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiTheme.SKY_000)
	var anchor: Control = _preview if _preview.visible else _hero
	var c := anchor.get_global_rect().get_center() - get_global_position()
	var r := maxf(size.x, size.y) * (0.5 if _two_col else 0.55)
	draw_texture_rect(_preview._glow, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false)
	draw_arc(c, r * 0.52, 0.0, TAU, 128, UiTheme.LINE, 1.0, true)
	draw_arc(c, r * 0.78, 0.0, TAU, 128, Color(UiTheme.LINE, UiTheme.LINE.a * 0.6), 1.0, true)

func _on_resized() -> void:
	if _card == null:
		return
	var phone := size.x < 600.0
	# Two columns on wide windows and short landscape ones.
	_two_col = size.x >= 900.0 or (size.x > size.y and size.y < 600.0)
	_flow.vertical = not _two_col
	_flow.add_theme_constant_override("separation", 64 if _two_col else 16)
	var gutter := 16 if phone else 24
	_margin.add_theme_constant_override("margin_left", 48 if _two_col else gutter)
	_margin.add_theme_constant_override("margin_right", 72 if _two_col else gutter)
	_margin.add_theme_constant_override("margin_top", 64 if _two_col else 60)
	_margin.add_theme_constant_override("margin_bottom", 32 if _two_col else gutter)
	_brand.position = Vector2(gutter, 20 if phone else 24)
	_brand.size = _brand.custom_minimum_size
	_side.custom_minimum_size = Vector2(376 if _two_col else 0, 0)
	_side.size_flags_vertical = Control.SIZE_SHRINK_CENTER if _two_col else Control.SIZE_EXPAND_FILL
	_side.alignment = BoxContainer.ALIGNMENT_CENTER if _two_col else BoxContainer.ALIGNMENT_BEGIN
	_hero.size_flags_vertical = Control.SIZE_SHRINK_CENTER if _two_col else Control.SIZE_SHRINK_BEGIN
	_title.add_theme_font_size_override("font_size", 36 if phone else 48)
	_eta_label.visible = _two_col or size.y >= 900.0
	_push.visible = not _two_col
	_fit_lens()
	if not _fit_queued and size.y > 0.0:
		_fit_queued = true
		call_deferred("_fit_after_layout")
	queue_redraw()

## Lens size from the room left once text, stage card and Cancel have
## theirs: the lens is the only part that gives up height, and hides
## below 120pt so every stage row and Cancel stay on screen.
func _fit_lens() -> void:
	var target := 360.0 if _two_col else (232.0 if size.x < 600.0 else 320.0)
	var m := _margin
	var room_y := size.y - m.get_theme_constant("margin_top") - m.get_theme_constant("margin_bottom")
	# Estimated from type sizes: before layout the wrapping title reports
	# a one-character-wide minimum height, which would hide the lens.
	var text_h := 16.0 + _title.get_theme_font_size("font_size") * 1.15 + 22.0 + 20.0 + 16.0
	var room: float
	if _two_col:
		room = room_y - text_h - 24.0
	else:
		var card_h := maxf(_card.size.y, _card.get_combined_minimum_size().y)
		room = room_y - text_h - card_h - _cancel_btn.custom_minimum_size.y - 3.0 * 16.0
	# Breathing room above and below the dial, inside its own rect.
	var gap := 40.0 if _two_col else 24.0
	var side := minf(target, floorf(minf(room - gap,
		(size.x - 48.0) if not _two_col else (size.x - 376.0 - 184.0))))
	_preview.visible = side >= 120.0
	_preview.custom_minimum_size = Vector2(side, side + gap) if _preview.visible else Vector2.ZERO

func _fit_after_layout() -> void:
	_fit_queued = false
	if _card == null or not visible or size.y <= 0.0:
		return
	_fit_lens()
	queue_redraw()

## A data layer is not responding (DataNotes key): say so now, in plain
## words, rather than leaving the wait unexplained.
func add_degraded(layer: String, detail: String = "Estimated") -> void:
	if _note_label == null or _degraded.has(layer):
		return
	_degraded.append(layer)
	_note_label.text = DataNotes.loading_line(_degraded)
	_note_label.visible = true
	_note_row.visible = true
	_preview.degraded = true
	# The stage that was waiting on it says so too: plain words, caution tone.
	if LAYER_ROW.has(layer):
		var row: Dictionary = _rows[int(LAYER_ROW[layer])]
		row["degraded"] = true
		_paint_row(row, StageDot.State.DEGRADED)
		row["detail"].text = detail

## "Venice, Italy" lands as the name "Venice" over the region "Italy".
func begin(place_name: String, lat: float = NAN, lon: float = NAN) -> void:
	var parts := UiTheme.split_place(place_name)
	_title.text = parts[0]
	_region.text = parts[1]
	_region.visible = _region.text != ""
	_coords.text = "" if is_nan(lat) or is_nan(lon) else UiTheme.coords(lat, lon)
	_coords.visible = _coords.text != ""
	_degraded.clear()
	if _note_label != null:
		_note_label.visible = false
		_note_row.visible = false
	_progress.value = 0
	_active_index = -1
	_building = false
	_percent_label.text = "0%"
	_stage_label.text = "Starting…"
	_preview.clear()
	for row in _rows + [_build_row]:
		row["degraded"] = false
		_paint_row(row, StageDot.State.PENDING)
		row["detail"].text = ""
	_on_resized()

func _paint_row(row: Dictionary, state: StageDot.State) -> void:
	row["dot"].state = state
	var detail_label: Label = row["detail"]
	detail_label.add_theme_color_override("font_color",
		UiTheme.SIGNAL_CAUTION if state == StageDot.State.DEGRADED else UiTheme.MUTED)
	var name_label: Label = row["name"]
	name_label.add_theme_color_override("font_color",
		UiTheme.MUTED if state == StageDot.State.PENDING else UiTheme.INK)
	if state == StageDot.State.ACTIVE:
		name_label.add_theme_font_override("font", UiTheme.sans(600))
	else:
		name_label.remove_theme_font_override("font")

func _on_pulse() -> void:
	if _building and _percent_label != null:
		_percent_label.text = "%d s" % int(
			(Time.get_ticks_msec() - _build_started_msec) / 1000)

func set_stage(index: int, _label: String, state: String) -> void:
	if index < 0 or index >= _rows.size():
		return
	var row: Dictionary = _rows[index]
	if state == "done":
		if _active_index == index:
			_active_index = -1
		if row["degraded"]:
			_paint_row(row, StageDot.State.DEGRADED)  # stays flagged: it finished on estimates
		else:
			_paint_row(row, StageDot.State.DONE)
			# Real detail only: how long the stage actually waited on data
			# (stages with nothing to wait for stay blank).
			var took := (Time.get_ticks_msec() - int(row["started"])) / 1000.0
			if int(row["started"]) > 0 and took >= 0.1:
				row["detail"].text = "%.1f s" % took
	else:
		_active_index = index
		row["started"] = Time.get_ticks_msec()
		_paint_row(row, StageDot.State.ACTIVE)

## The pipeline's data after a stage: draws what landed into the lens.
func show_stage_data(index: int, data: LocationData) -> void:
	var extent := WorldScale.detailed_extent_units()
	if index == 1:
		var tex := data.satellite_texture
		if tex != null and data.satellite_metres_per_px > 0.0:
			var centre := TileFetcher.global_pixel(data.latitude, data.longitude,
				data.satellite_zoom) - data.satellite_origin_px
			var px := Vector2(tex.get_size())
			# The mosaic can stop short of the full extent: frame the lens
			# on what it covers rather than smearing its edge pixels.
			var half := minf(extent * 0.5 / data.satellite_metres_per_px,
				minf(minf(centre.x, centre.y), minf(px.x - centre.x, px.y - centre.y)))
			if half > 8.0:
				_preview.set_view(half * 2.0 * data.satellite_metres_per_px / extent)
				_preview.set_imagery(tex, Rect2((centre - Vector2(half, half)) / px,
					Vector2(half, half) * 2.0 / px))
	elif index == 0:
		if not bool(data.dem_source.get("procedural", false)):
			_preview.set_terrain(data.heights, data.grid_size)
	elif index == 2:
		var boxes: Array[Rect2] = []
		for b in data.buildings:
			if boxes.size() >= 4000:
				break
			var sx := float(b.get("size_x", 0.0))
			var sz := float(b.get("size_z", 0.0))
			var x := float(b.get("x", 0.0)) - sx * 0.5
			var z := float(b.get("z", 0.0)) - sz * 0.5
			boxes.append(Rect2(x / extent + 0.5, z / extent + 0.5, sx / extent, sz / extent))
		_preview.set_buildings(boxes)

func set_progress(fraction: float, label: String) -> void:
	var f := clampf(fraction, 0.0, 1.0)
	_progress.value = f * 100.0
	_stage_label.text = label
	_percent_label.text = "%d%%" % int(round(f * 100.0))
	_preview.progress = f

## Fetch pipeline is done; the threaded world build has no measurable
## fraction, so show elapsed seconds instead of a misleading 100%.
func set_building() -> void:
	_building = true
	_build_started_msec = Time.get_ticks_msec()
	_active_index = -1
	_progress.value = 100.0
	_preview.progress = 1.0
	_stage_label.text = BUILD_LABEL
	_paint_row(_build_row, StageDot.State.ACTIVE)
	_percent_label.text = "0 s"
