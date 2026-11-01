class_name DatePicker
extends PanelContainer

## The day and season sheet: the season (its own mid-month day) or any
## calendar day for the sun's path (solstice, a birthday, "sunset on my
## trip"). A glass sheet over the viewer, opened from the sun arc's day
## chip: "Day and season" with a close button, the four seasons (icon
## over name), then a month and a year stepper, a Monday-first day grid
## and quick picks (Today, the two solstices, Reset to the season's own
## day). A day emits date_picked; the view maps it to its season and
## runs the solar model for it. A season emits season_picked and the sheet
## stays open. Esc (the viewer's key handler) or the close button
## dismisses it.

signal date_picked(date: Dictionary)
## Back to the season's own mid-month day.
signal season_requested
## A season segment: that season's own day (the view rebuilds in it).
signal season_picked(index: int)
signal closed

const CELL := 40
const YEAR_MIN := 1900
const YEAR_MAX := 2200
const WEEKDAYS := ["M", "T", "W", "T", "F", "S", "S"]
const MONTHS := ["January", "February", "March", "April", "May", "June", "July",
	"August", "September", "October", "November", "December"]
const WIDTH := CELL * 7 + 32

var _year := 2026
var _month := 6
var _selected := {}
var _today := {}
var _month_label: Label
var _year_label: Label
var _grid: GridContainer
## The season segments; the view keeps them in step with its season.
var seasons: SegmentedControl

func _init() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", HudStyle.panel(UiTheme.RADIUS_L, 16, 12))
	custom_minimum_size = Vector2(WIDTH, 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	add_child(col)

	var title_row := HBoxContainer.new()
	col.add_child(title_row)
	var title := UiTheme.text("Day and season", "title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(title)
	title_row.add_child(_stepper("x", "Close", close_picker))
	seasons = SegmentedControl.new(LocationData.SEASON_NAMES, SunArc.SEASON_ICONS, true)
	seasons.set_stacked(true)
	seasons.select(LocationData.Season.SUMMER)
	seasons.item_selected.connect(func(index: int) -> void: season_picked.emit(index))
	col.add_child(seasons)
	var rule := ColorRect.new()
	rule.color = UiTheme.LINE
	rule.custom_minimum_size = Vector2(0, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(rule)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 4)
	col.add_child(head)
	head.add_child(_stepper("chevron-left", "Previous month", func() -> void: _step_month(-1)))
	_month_label = UiTheme.label("", 16, UiTheme.INK, true)
	_month_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_month_label.custom_minimum_size.x = 84
	head.add_child(_month_label)
	head.add_child(_stepper("chevron-right", "Next month", func() -> void: _step_month(1)))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(gap)
	head.add_child(_stepper("chevron-left", "Previous year", func() -> void: _step_year(-1)))
	_year_label = UiTheme.data_label("", 15, UiTheme.INK, true)
	_year_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_year_label.custom_minimum_size.x = 48
	head.add_child(_year_label)
	head.add_child(_stepper("chevron-right", "Next year", func() -> void: _step_year(1)))

	var days := GridContainer.new()
	days.columns = 7
	days.add_theme_constant_override("h_separation", 0)
	days.add_theme_constant_override("v_separation", 0)
	col.add_child(days)
	for w in WEEKDAYS:
		var l := UiTheme.label(w, 13, UiTheme.MUTED)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size = Vector2(CELL, 24)
		days.add_child(l)
	_grid = GridContainer.new()
	_grid.columns = 7
	_grid.add_theme_constant_override("h_separation", 0)
	_grid.add_theme_constant_override("v_separation", 0)
	col.add_child(_grid)

	var quick := HBoxContainer.new()
	quick.add_theme_constant_override("separation", 2)
	col.add_child(quick)
	for q in [["Today", "today", "Jump to today"], ["21 Jun", "jun", "June solstice"],
			["21 Dec", "dec", "December solstice"], ["Reset", "season", "Back to the season's own day"]]:
		var b := UiTheme.quiet_button(q[0])
		b.custom_minimum_size.y = 36
		b.tooltip_text = q[2]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 13)
		for state in ["normal", "hover", "pressed"]:
			var st := b.get_theme_stylebox(state).duplicate() as StyleBoxFlat
			st.content_margin_left = 6
			st.content_margin_right = 6
			b.add_theme_stylebox_override(state, st)
		var kind: String = q[1]
		b.pressed.connect(func() -> void: _quick(kind))
		quick.add_child(b)

func _stepper(icon_name: String, tip: String, action: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(36, 36)
	b.tooltip_text = tip
	b.accessibility_name = tip
	var clear := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_PILL)
	clear.set_content_margin_all(0)
	var lit := UiTheme.style(UiTheme.LINE, UiTheme.RADIUS_PILL)
	lit.set_content_margin_all(0)
	b.add_theme_stylebox_override("normal", clear)
	b.add_theme_stylebox_override("hover", lit)
	b.add_theme_stylebox_override("pressed", lit)
	b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_PILL))
	UiIcon.apply(b, icon_name, 18, UiTheme.INK, UiTheme.INK)
	b.pressed.connect(action)
	return b

# --- Calendar arithmetic (static, for tests) ---

## Column (0 = Monday) of the first of `month`.
static func first_column(year: int, month: int) -> int:
	var unix := Time.get_unix_time_from_datetime_dict({"year": year, "month": month, "day": 1,
		"hour": 12, "minute": 0, "second": 0})
	var weekday := int(Time.get_datetime_dict_from_unix_time(unix).get("weekday", 0))  # 0 = Sunday
	return (weekday + 6) % 7

## Grid cells of a month: blanks (0) for the offset, then 1..days.
static func cells(year: int, month: int) -> Array[int]:
	var out: Array[int] = []
	for i in first_column(year, month):
		out.append(0)
	for d in ViewLink.days_in_month(year, month):
		out.append(d + 1)
	return out

# --- State ---

## Opens on `date` (empty: today in `today`), the season segment on
## `season`.
func open_for(date: Dictionary, today: Dictionary, season: int = -1) -> void:
	if season >= 0:
		seasons.select(season)
	_today = today
	_selected = date
	var shown := date if not date.is_empty() else today
	_year = clampi(int(shown.get("year", 2026)), YEAR_MIN, YEAR_MAX)
	_month = clampi(int(shown.get("month", 6)), 1, 12)
	visible = true
	_rebuild()

func close_picker() -> void:
	if visible:
		visible = false
		closed.emit()

func shown_month() -> Vector2i:
	return Vector2i(_year, _month)

func _step_month(by: int) -> void:
	_month += by
	if _month < 1:
		_month = 12
		_year -= 1
	elif _month > 12:
		_month = 1
		_year += 1
	_year = clampi(_year, YEAR_MIN, YEAR_MAX)
	_rebuild()

func _step_year(by: int) -> void:
	_year = clampi(_year + by, YEAR_MIN, YEAR_MAX)
	_rebuild()

func _quick(kind: String) -> void:
	match kind:
		"today":
			if not _today.is_empty():
				_pick(_today)
		"jun":
			_pick({"year": _year, "month": 6, "day": 21})
		"dec":
			_pick({"year": _year, "month": 12, "day": 21})
		_:
			season_requested.emit()
			close_picker()

func _pick(date: Dictionary) -> void:
	_selected = date
	date_picked.emit(date)
	close_picker()

func _rebuild() -> void:
	_month_label.text = MONTHS[_month - 1]
	_year_label.text = str(_year)
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	for d in cells(_year, _month):
		if d == 0:
			var blank := Control.new()
			blank.custom_minimum_size = Vector2(CELL, CELL)
			_grid.add_child(blank)
			continue
		_grid.add_child(_day_button(d))

func _day_button(day: int) -> Button:
	var date := {"year": _year, "month": _month, "day": day}
	var chosen := _same(_selected, date)
	var is_today := _same(_today, date)
	var b := Button.new()
	b.text = str(day)
	b.custom_minimum_size = Vector2(CELL, CELL)
	b.focus_mode = Control.FOCUS_ALL
	b.accessibility_name = "%d %s %d" % [day, MONTHS[_month - 1], _year]
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_font_override("font", UiTheme.sans(600 if chosen or is_today else 500))
	var on := UiTheme.style(UiTheme.TEAL, UiTheme.RADIUS_PILL)
	var ring := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_PILL, UiTheme.TEAL)
	var clear := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_PILL)
	var lit := UiTheme.style(UiTheme.LINE, UiTheme.RADIUS_PILL)
	for st: StyleBoxFlat in [on, ring, clear, lit]:
		st.set_content_margin_all(0)
	b.add_theme_stylebox_override("normal", on if chosen else (ring if is_today else clear))
	b.add_theme_stylebox_override("hover", on if chosen else lit)
	b.add_theme_stylebox_override("pressed", on)
	b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_PILL))
	var ink := UiTheme.ON_ACCENT if chosen else UiTheme.INK
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(key, ink)
	b.pressed.connect(func() -> void: _pick(date))
	return b

static func _same(a: Dictionary, b: Dictionary) -> bool:
	return not a.is_empty() and int(a.get("year", 0)) == int(b["year"]) \
		and int(a.get("month", 0)) == int(b["month"]) and int(a.get("day", 0)) == int(b["day"])
