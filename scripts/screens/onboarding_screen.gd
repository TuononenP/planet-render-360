class_name OnboardingScreen
extends Control

## First-launch onboarding (design system Layout → Onboarding): at most
## three screens, each the live globe slowly turning behind a display-xl
## headline and one body sentence. Skip is always top-right; the last
## screen ends on the map with the search field focused (`finished`).

signal finished

const PAGES := [
	["Any point on Earth.", "Pick a place and we'll build it around you from real terrain, imagery and weather."],
	["Look around.", "Drag to turn. Scrub the sun to move through the day and the seasons."],
	["Your atlas remembers.", "Places you visit stay on this device for a quick return. Choose Save for offline to keep one for when you have no connection."],
]

var _page := 0
var _title: Label
var _body: Label
var _next: Button
var _dots: HBoxContainer
var _globe: GlobeView

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = UiTheme.SKY_000
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_globe = GlobeView.new()
	_globe.set_anchors_preset(Control.PRESET_FULL_RECT)
	_globe.spin = 0.0 if UiPrefs.reduce_motion else 4.0
	_globe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_globe)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var fit_margin := func() -> void: Responsive.apply_safe_margins(margin, self, [24, 24, 24, 24])
	fit_margin.call()
	resized.connect(fit_margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	margin.add_child(col)
	var top := HBoxContainer.new()
	col.add_child(top)
	top.add_child(Brand.rect(Brand.mark(), 32))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(gap)
	var skip := UiTheme.quiet_button("Skip")
	skip.pressed.connect(func() -> void: finished.emit())
	top.add_child(skip)
	var push := Control.new()
	push.size_flags_vertical = Control.SIZE_EXPAND_FILL
	push.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(push)
	_title = UiTheme.display_label("", 48)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_title)
	_body = UiTheme.label("", 15, UiTheme.MUTED)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size.x = 280
	col.add_child(_body)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	col.add_child(foot)
	_dots = HBoxContainer.new()
	_dots.add_theme_constant_override("separation", 8)
	_dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dots.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(_dots)
	for i in PAGES.size():
		var dot := TextureRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		_dots.add_child(dot)
	_next = UiTheme.primary_button("Next")
	_next.custom_minimum_size.x = 180
	_next.pressed.connect(func() -> void:
		if _page >= PAGES.size() - 1:
			finished.emit()
		else:
			show_page(_page + 1))
	foot.add_child(_next)
	show_page(0)

func show_page(index: int) -> void:
	_page = clampi(index, 0, PAGES.size() - 1)
	_title.text = PAGES[_page][0]
	_body.text = PAGES[_page][1]
	_next.text = "Start exploring" if _page == PAGES.size() - 1 else "Next"
	for i in _dots.get_child_count():
		var d := _dots.get_child(i) as TextureRect
		d.texture = UiTheme.dot(UiTheme.TEAL if i == _page else UiTheme.LINE_STRONG, 8)
	if not UiPrefs.reduce_motion:
		for l: Control in [_title, _body]:
			l.modulate.a = 0.0
			create_tween().tween_property(l, "modulate:a", 1.0, 0.24)

func page() -> int:
	return _page
