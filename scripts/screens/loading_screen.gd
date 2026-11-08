class_name LoadingScreen
extends Control

## The descent screen (design system: LoadingScreen). No card around
## the content: a full-bleed horizon-night glow centred on the
## TerrainLens, the place set like an arrival title above it, and the
## stage card (StageProgress) beside it on wide windows or under it on
## phones. The lens fills in from real data as each stage lands.

signal cancel_requested
## Error state actions (show_error): only when nothing could be built.
signal retry_requested
signal back_requested

const NOTE := "First visits take a minute or two while we gather the terrain. Next time it opens faster."
## Degraded layer key (DataNotes) -> the stage row that was waiting on it.
const LAYER_ROW := {"elevation": 0, "imagery": 1, "map": 2, "weather": 3}
const BUILD_LABEL := "Building the scene"

var _title: Label
var _region: Label
var _coords: Label
var _quality_row: HBoxContainer  # gauge + "Quality · High": the preset being built
var _quality_label: Label
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
var _rows: Array = []  # {dot, name, detail, label, started, active, done} per pipeline stage
var _build_row: Dictionary = {}
var _eta_label: Label
var _note_row: HBoxContainer  # caution line while a data layer is not responding
var _note_label: Label
var _degraded: Array[String] = []
var _took := {}  # stage index -> fetch seconds from set_stage_took
var _stage_frac := {}  # stage index -> furthest set_stage_progress fraction
var _details := {}  # layer -> {"text", "partial"} from set_layer_detail
var _cancel_btn: Button
var _error_row: HBoxContainer  # Try again + Back to map (show_error)
var _failed := false
var _announcer: Announcer  # StageProgress announces each completed stage
## Reduced motion swaps the build shimmer for a static striped fill.
static var reduce_motion := false
var _push: Control
var _two_col := false
const NOT_STARTED := -(1 << 40)
var _run_started_msec := NOT_STARTED  # the fetches all start with stage 0; the row counters read from here
var _building := false
var _build_started_msec := 0
var _build_source: BuildAbort  # the world build's phase, polled while building
var _build_shown := 0.0  # eased 0..1 fraction of the build on the bar
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
	_quality_row = HBoxContainer.new()
	_quality_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_quality_row.add_theme_constant_override("separation", 6)
	_quality_row.visible = false
	_hero.add_child(_quality_row)
	var quality_icon := TextureRect.new()
	quality_icon.texture = UiIcon.texture("gauge", 14)
	quality_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	quality_icon.custom_minimum_size = Vector2(14, 14)
	quality_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	quality_icon.modulate = UiTheme.MUTED
	_quality_row.add_child(quality_icon)
	_quality_label = UiTheme.label("", 14, UiTheme.MUTED)
	_quality_row.add_child(_quality_label)
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
	_error_row = HBoxContainer.new()
	_error_row.add_theme_constant_override("separation", 8)
	_error_row.visible = false
	_side.add_child(_error_row)
	var retry := UiTheme.primary_button("Try again")
	UiIcon.apply(retry, "rotate-ccw", 20, UiTheme.ON_ACCENT, UiTheme.ON_ACCENT)
	retry.pressed.connect(func() -> void: retry_requested.emit())
	_error_row.add_child(retry)
	var back := UiTheme.quiet_button("Back to map")
	back.pressed.connect(func() -> void: back_requested.emit())
	_error_row.add_child(back)
	# The indeterminate shimmer over the bar while the scene builds.
	_progress.draw.connect(_draw_build_fill)

	_announcer = Announcer.new()
	add_child(_announcer)
	_brand = Brand.rect(Brand.mark(), 44)
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
		"started": 0, "degraded": false, "ticking": false, "active": false, "done": false}

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
	# A phone on its side spends its margins on the stage card.
	var tight := _two_col and size.y < 500.0
	_flow.add_theme_constant_override("separation", 24 if tight else (64 if _two_col else 16))
	var gutter := 16 if phone else 24
	var safe := Responsive.safe_insets(self)
	var margins := [24, 16, 24, 12] if tight else ([48, 64, 72, 32] if _two_col else [gutter, 60, gutter, gutter])
	Responsive.apply_safe_margins(_margin, self, margins)
	_brand.position = Vector2(gutter + safe[0], (16 if phone else 24) + safe[1])
	_brand.size = _brand.custom_minimum_size
	_side.custom_minimum_size = Vector2(376 if _two_col else 0, 0)
	_side.size_flags_vertical = Control.SIZE_SHRINK_CENTER if _two_col else Control.SIZE_EXPAND_FILL
	_side.alignment = BoxContainer.ALIGNMENT_CENTER if _two_col else BoxContainer.ALIGNMENT_BEGIN
	_hero.size_flags_vertical = Control.SIZE_SHRINK_CENTER if _two_col else Control.SIZE_SHRINK_BEGIN
	_title.add_theme_font_size_override("font_size", 36 if phone or tight else 48)
	_eta_label.visible = size.y >= 440.0  # the stage rows and Cancel come first
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
	if _quality_row.visible:
		text_h += 24.0
	var room: float
	if _two_col:
		room = room_y - text_h - 24.0
	else:
		var card_h := maxf(_card.size.y, _card.get_combined_minimum_size().y)
		room = room_y - text_h - card_h - 48.0 - 3.0 * 16.0
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
	_refresh_note()
	_note_label.visible = true
	_note_row.visible = true
	_preview.degraded = true
	# The stage that was waiting on it says so too: plain words, caution tone.
	if LAYER_ROW.has(layer):
		var row: Dictionary = _rows[int(LAYER_ROW[layer])]
		row["degraded"] = true
		_paint_row(row, StageDot.State.DEGRADED)
		row["detail"].text = str(_details[layer]["text"]) if _details.has(layer) else detail
		row["ticking"] = false

## A layer is arriving from a saved or reduced source ("Nearby · 450 m",
## "Offline copy"): its row says where from instead of how long it took.
## Partial layers are also passed to add_degraded by the pipeline, which
## then shows the same text in caution tone; a complete one stays done.
func set_layer_detail(layer: String, detail: String, partial: bool) -> void:
	if not LAYER_ROW.has(layer) or _rows.is_empty():
		return
	_details[layer] = {"text": detail, "partial": partial}
	var row: Dictionary = _rows[int(LAYER_ROW[layer])]
	row["detail"].text = detail
	row["ticking"] = false

## The caution line: layers on estimates, then layers on partial data.
func _refresh_note() -> void:
	var estimated: Array = []
	for layer in _degraded:
		if not _details.has(layer):
			estimated.append(layer)
	var lines: Array[String] = []
	if not estimated.is_empty():
		lines.append(DataNotes.loading_line(estimated))
	for layer in _degraded:
		if _details.has(layer):
			lines.append(DataNotes.partial_line(str(_details[layer]["text"])))
	_note_label.text = " ".join(lines)

## "Venice, Italy" lands as the name "Venice" over the region "Italy".
## `preset` is the RenderSettings quality being built; named under the
## coordinates ("Quality · High") so the wait says what it is for.
func begin(place_name: String, lat: float = NAN, lon: float = NAN, preset: int = -1) -> void:
	var parts := UiTheme.split_place(place_name)
	_title.text = parts[0]
	_region.text = parts[1]
	_region.visible = _region.text != ""
	_coords.text = "" if is_nan(lat) or is_nan(lon) else UiTheme.coords(lat, lon)
	_coords.visible = _coords.text != ""
	_quality_row.visible = preset >= 0
	if preset >= 0:
		_quality_label.text = "Quality · %s" % RenderSettings.preset_name(preset)
	_run_started_msec = NOT_STARTED
	_degraded.clear()
	_details.clear()
	_stage_frac.clear()
	_took.clear()
	if _note_label != null:
		_note_label.visible = false
		_note_row.visible = false
	_progress.value = 0
	_building = false
	_build_source = null
	_build_shown = 0.0
	_percent_label.text = "0%"
	_stage_label.text = "Starting…"
	_preview.clear()
	_preview.failed = false
	_failed = false
	_cancel_btn.visible = true
	_error_row.visible = false
	_style()
	# StageProgress rises in (ease-enter, duration-standard).
	if not reduce_motion and is_inside_tree():
		_card.modulate.a = 0.0
		create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT) \
			.tween_property(_card, "modulate:a", 1.0, 0.24)
	for row in _rows + [_build_row]:
		row["degraded"] = false
		row["ticking"] = false
		row["active"] = false
		row["done"] = false
		_paint_row(row, StageDot.State.PENDING)
		row["detail"].text = ""
	_on_resized()

## True when set_layer_detail named where this stage's layer came from.
func _has_detail(index: int) -> bool:
	for layer in _details:
		if int(LAYER_ROW[layer]) == index:
			return true
	return false

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

## The seconds the build has taken, beside the phase it is in; before
## it, the seconds each active stage's layer has been fetching.
func _on_pulse() -> void:
	if _failed or _percent_label == null:
		return
	if _building:
		_build_row["detail"].text = "%d s" % roundi(
			(Time.get_ticks_msec() - _build_started_msec) / 1000.0)
	else:
		for row in _rows:
			_tick_row(row)

## A running count on an active stage while it has nothing better to
## say (tiles, "Nearby · 450 m"). The layers are all fetched from the
## run's start, so each counts from it: the same clock the finished row
## reports.
func _tick_row(row: Dictionary) -> void:
	if not row["active"] or _run_started_msec == NOT_STARTED:
		return
	if row["detail"].text != "" and not row["ticking"]:
		return
	var seconds := roundi((Time.get_ticks_msec() - _run_started_msec) / 1000.0)
	row["ticking"] = seconds >= 1
	row["detail"].text = "%d s" % seconds if seconds >= 1 else ""

## The fetch bar while the layers arrive side by side: a finished stage
## counts whole, an active one by its own units (imagery tiles). Named
## after the first layer still arriving; never goes backwards.
func _refresh_fetch_bar() -> void:
	var sum := 0.0
	var waiting := ""
	for i in _rows.size():
		var row: Dictionary = _rows[i]
		if row["done"]:
			sum += 1.0
			continue
		sum += float(_stage_frac.get(i, 0.0))
		if waiting == "" and row["active"]:
			waiting = row["label"]
	set_progress(maxf(sum / _rows.size(), _progress.value / 100.0),
		waiting if waiting != "" else _stage_label.text)

func _process(delta: float) -> void:
	if not _building or _failed or not visible:
		return
	_advance_build(delta)
	if not reduce_motion:
		_progress.queue_redraw()

## The build thread reports phases, not a fraction, so the bar eases
## toward the phase it is in: quickly to the start of a new phase, then
## slowly through it (never past 90% of it), so a long phase keeps moving
## and the bar can't read as done before the world is.
func _advance_build(delta: float) -> void:
	var index := _build_source.step if _build_source != null else 0
	var lo := BuildAbort.fraction_before(index)
	var hi := BuildAbort.fraction_before(index + 1)
	var rate := 6.0 if _build_shown < lo - 0.001 else 0.35
	_build_shown += (lerpf(lo, hi, 0.9) - _build_shown) * (1.0 - exp(-delta * rate))
	_progress.value = _build_shown * 100.0
	_percent_label.text = "%d%%" % int(_build_shown * 100.0)
	_stage_label.text = "%s · %s" % [BUILD_LABEL, BuildAbort.label_of(index)]

## A soft light sweeping the filled part of the bar (duration-slow pace),
## or static stripes under reduced motion. Only while the scene builds.
func _draw_build_fill() -> void:
	if not _building or _failed:
		return
	var r := Rect2(Vector2.ZERO, Vector2(_progress.size.x * _build_shown, _progress.size.y))
	if reduce_motion:
		var x := -r.size.y
		while x < r.size.x:
			_progress.draw_line(Vector2(x, r.size.y), Vector2(x + r.size.y, 0.0),
				Color(UiTheme.ON_ACCENT, 0.35), 2.0)
			x += 8.0
		return
	var t := fmod(Time.get_ticks_msec() / 1600.0, 1.0)
	var band := r.size.x * 0.25
	var cx := -band + t * (r.size.x + band * 2.0)
	var steps := 12
	for i in steps:
		var a := float(i) / steps
		var x0 := cx - band / 2.0 + a * band
		var glow := sin(a * PI) * 0.45
		_progress.draw_rect(Rect2(x0, 0.0, band / steps + 0.5, r.size.y).intersection(r),
			Color(UiTheme.INK, glow))

## Nothing could be built: the failed stage turns signal-error with its
## reason, completed stages keep their tick, the lens and bar turn
## error, and Cancel gives way to Try again with Back to map beside it.
func show_error(reason: String) -> void:
	_failed = true
	_building = false
	var row := _build_row
	for r in _rows:
		if r["active"]:
			row = r
			break
	_paint_row(row, StageDot.State.ERROR)
	row["detail"].text = reason
	row["detail"].add_theme_color_override("font_color", UiTheme.SIGNAL_ERROR)
	_stage_label.text = reason
	_preview.failed = true
	var fill := UiTheme.style(UiTheme.SIGNAL_ERROR, UiTheme.RADIUS_PILL)
	fill.set_content_margin_all(0)
	_progress.add_theme_stylebox_override("fill", fill)
	_cancel_btn.visible = false
	_error_row.visible = true

func is_failed() -> bool:
	return _failed

func set_stage(index: int, _label: String, state: String) -> void:
	if index < 0 or index >= _rows.size():
		return
	var row: Dictionary = _rows[index]
	if state == "done":
		row["active"] = false
		row["done"] = true
		if row["ticking"]:  # the running count gives way to the real time, or nothing
			row["detail"].text = ""
			row["ticking"] = false
		_announcer.say("%s %s" % [row["label"], "estimated" if row["degraded"] else "done"])
		if row["degraded"]:
			_paint_row(row, StageDot.State.DEGRADED)  # stays flagged: it finished on estimates
		else:
			_paint_row(row, StageDot.State.DONE)
			# Real detail only: how long the stage actually waited on data
			# (stages with nothing to wait for stay blank).
			var took := (Time.get_ticks_msec() - int(row["started"])) / 1000.0
			# Layers fetched alongside earlier stages report their own time.
			if _took.has(index):
				took = float(_took[index])
			elif int(row["started"]) <= 0:
				took = 0.0
			if took >= 0.1 and not _has_detail(index):
				row["detail"].text = "%.1f s" % took
		_refresh_fetch_bar()
	else:
		row["active"] = true
		row["started"] = Time.get_ticks_msec()
		if index == 0 or _run_started_msec == NOT_STARTED:
			_run_started_msec = int(row["started"])
		_paint_row(row, StageDot.State.ACTIVE)
		_tick_row(row)
		_refresh_fetch_bar()

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

## Units done inside an active stage (imagery tiles): the row counts
## them and the bar moves with them instead of waiting for the whole
## layer. Never goes backwards (a lower-zoom retry restarts the count).
func set_stage_progress(index: int, done: int, total: int) -> void:
	if index < 0 or index >= _rows.size() or total <= 0 or not _rows[index]["active"]:
		return
	var frac := clampf(float(done) / total, 0.0, 1.0)
	if frac < float(_stage_frac.get(index, 0.0)):
		return
	_stage_frac[index] = frac
	_rows[index]["detail"].text = "%d / %d tiles" % [done, total]
	_rows[index]["ticking"] = false
	_refresh_fetch_bar()

## The real fetch time of a layer that ran alongside earlier stages, so
## its row shows it even when nothing was left to wait for.
func set_stage_took(index: int, seconds: float) -> void:
	_took[index] = seconds

func set_progress(fraction: float, label: String) -> void:
	var f := clampf(fraction, 0.0, 1.0)
	_progress.value = f * 100.0
	_stage_label.text = label
	_percent_label.text = "%d%%" % int(round(f * 100.0))
	_preview.progress = f

## Fetch pipeline is done; the threaded world build reports the phase it
## is in through `source`, and the bar restarts at 0 for it.
func set_building(source: BuildAbort) -> void:
	_building = true
	_build_source = source
	_build_shown = 0.0
	_build_started_msec = Time.get_ticks_msec()
	for row in _rows:
		row["active"] = false
	_progress.value = 0.0
	_preview.progress = 1.0
	_stage_label.text = "%s · %s" % [BUILD_LABEL, BuildAbort.label_of(0)]
	_paint_row(_build_row, StageDot.State.ACTIVE)
	_percent_label.text = "0%"
