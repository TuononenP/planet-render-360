class_name LandmarkPanel
extends PanelContainer

## The landmark sheet over the 360 view (design system Callout: "Tapping
## one opens the landmark in the sheet"). Panel glass holding a
## LandmarkCard with Go there and Get closer; a close button and Esc
## dismiss it. On desktop it is a left side panel (the controls inspector
## holds the right); on phones and tablets a bottom sheet that rests at
## half height while the controls bar steps aside. ViewChrome.layout
## places it.

signal go_requested(site: Dictionary)
## Get closer: Go there from a tighter standoff.
signal closer_requested(site: Dictionary)
signal closed

var card: LandmarkCard
var _scroll: ScrollContainer
var _close: Button

func _init(fetcher: WikiFetcher) -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	var st := UiTheme.glass_panel(UiTheme.RADIUS_L)
	st.content_margin_left = 20
	st.content_margin_right = 12
	st.content_margin_top = 12
	st.content_margin_bottom = 20
	add_theme_stylebox_override("panel", st)
	UiTheme.add_sheen(self, UiTheme.RADIUS_L)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	add_child(col)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(top)
	_close = UiIcon.button("x", "Close")
	_close.pressed.connect(close)
	top.add_child(_close)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UiTheme.apply_scroll(_scroll)
	col.add_child(_scroll)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_right", 8)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(pad)
	card = LandmarkCard.new(fetcher)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.go_requested.connect(func(s: Dictionary) -> void:
		close()
		go_requested.emit(s))
	card.closer_requested.connect(func(s: Dictionary) -> void:
		close()
		closer_requested.emit(s))
	pad.add_child(card)

func open(site: Dictionary, distance_m: float = -1.0) -> void:
	card.show_site(site, distance_m)
	_scroll.scroll_vertical = 0
	visible = true
	modulate.a = 0.0
	create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT) \
		.tween_property(self, "modulate:a", 1.0, UiPrefs.motion(0.24))

## Esc and the close button. Returns false when it was already closed.
func close() -> bool:
	if not visible:
		return false
	visible = false
	closed.emit()
	return true

func is_open() -> bool:
	return visible

## Place it for the window: `rect` is the room ViewChrome leaves for it;
## the panel takes its content's height up to the rect's.
func place(rect: Rect2, bottom_anchored: bool) -> void:
	size = Vector2(rect.size.x, 0)
	var chrome := get_theme_stylebox("panel").get_minimum_size().y + _close.get_combined_minimum_size().y
	var want := card.get_combined_minimum_size().y + chrome
	# shadow-3 falls away from the scene: up off a bottom sheet, down
	# under a side panel.
	(get_theme_stylebox("panel") as StyleBoxFlat).shadow_offset = Vector2(0, -12 if bottom_anchored else 10)
	var h := minf(want, rect.size.y)
	_scroll.custom_minimum_size.y = maxf(h - chrome, 0.0)
	size = Vector2(rect.size.x, h)
	position = Vector2(rect.position.x, rect.end.y - h if bottom_anchored else rect.position.y)
