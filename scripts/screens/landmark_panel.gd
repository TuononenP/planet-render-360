class_name LandmarkPanel
extends PanelContainer

## The landmark sheet over the 360 view (design system Callout: "Tapping
## one opens the landmark in the sheet"). Panel glass holding a
## LandmarkCard with Go there and Get closer, or the LandmarkList of the nearest
## landmarks: a row opens its card, with Back to the list above it. A
## close button and Esc dismiss it. On desktop it is a left side panel
## (the controls inspector holds the right); on phones and tablets a
## bottom sheet that rests at half height while the controls bar steps
## aside. ViewChrome.layout places it.

signal go_requested(site: Dictionary)
## Get closer: Go there from a tighter standoff.
signal closer_requested(site: Dictionary)
signal closed
## Opened, closed, or switched between the list and a card.
signal state_changed
## The content changed height (rows arrived, an article loaded).
signal content_resized

const LIST_TITLE := "Nearby landmarks"

var card: LandmarkCard
var list: LandmarkList
var _top: HBoxContainer
var _back: Button
var _title: Label
var _body: VBoxContainer
var _scroll: ScrollContainer
var _close: Button
var _listing := false
var _list_scroll := 0
## The latest rows and whether more may still arrive: what Back shows.
var _rows: Array = []
var _pending := false

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
	_top = HBoxContainer.new()
	col.add_child(_top)
	_back = UiTheme.quiet_button("Nearby")
	UiIcon.apply(_back, "chevron-left", 20)
	_back.accessibility_name = "Back to nearby landmarks"
	_back.visible = false
	_back.pressed.connect(show_list)
	_top.add_child(_back)
	_title = UiTheme.text(LIST_TITLE, "title")
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_top.add_child(_title)
	_close = UiIcon.button("x", "Close")
	_close.pressed.connect(close)
	_top.add_child(_close)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UiTheme.apply_scroll(_scroll)
	col.add_child(_scroll)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_right", 8)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(pad)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 0)
	_body.minimum_size_changed.connect(func() -> void: content_resized.emit())
	pad.add_child(_body)
	list = LandmarkList.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.site_picked.connect(func(s: Dictionary, distance_m: float) -> void:
		_list_scroll = _scroll.scroll_vertical
		card.show_site(s, distance_m)
		_show(false, true, false)
		_back.grab_focus())
	list.go_requested.connect(_go)
	_body.add_child(list)
	card = LandmarkCard.new(fetcher)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.go_requested.connect(_go)
	card.closer_requested.connect(func(s: Dictionary) -> void:
		close()
		closer_requested.emit(s))
	_body.add_child(card)

## A landmark's card (a tapped callout).
func open(site: Dictionary, distance_m: float = -1.0) -> void:
	card.show_site(site, distance_m)
	_show(false, false, true)

## The nearest landmarks (LandmarkList.rank rows); `pending` while the
## nearby articles that may add more are still on their way.
func open_list(rows: Array, pending: bool = false) -> void:
	_rows = rows
	_pending = pending
	list.set_rows(rows, pending)
	_show(true, false, not visible)

## Back from a card to the list it was opened from, with any rows that
## arrived meanwhile, and focus on the landmark just read.
func show_list() -> void:
	list.set_rows(_rows, _pending)
	_show(true, false, false)
	_scroll.set_deferred("scroll_vertical", _list_scroll)
	list.focus_site(str(card.site.get("id", "")))

## New rows (late nearby articles): shown now when the list is up, else
## when Back returns to it.
func update_list(rows: Array, pending: bool = false) -> void:
	_rows = rows
	_pending = pending
	if is_listing():
		list.set_rows(rows, pending)

## Keyboard focus into the list (opened with L): the nearest landmark.
func focus_list() -> void:
	if is_listing():
		list.focus_row(0)

func _show(listing: bool, from_list: bool, fade: bool) -> void:
	_listing = listing
	list.visible = listing
	card.visible = not listing
	_back.visible = from_list
	_title.text = LIST_TITLE if listing else ""
	_scroll.scroll_vertical = 0
	visible = true
	if fade:
		modulate.a = 0.0
		create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT) \
			.tween_property(self, "modulate:a", 1.0, UiPrefs.motion(0.24))
	state_changed.emit()

func _go(site: Dictionary) -> void:
	close()
	go_requested.emit(site)

## Esc and the close button. Returns false when it was already closed.
func close() -> bool:
	if not visible:
		return false
	visible = false
	_listing = false
	closed.emit()
	state_changed.emit()
	return true

func is_open() -> bool:
	return visible

## Whether the list (not a card) is what the panel shows.
func is_listing() -> bool:
	return visible and _listing

## Place it for the window: `rect` is the room ViewChrome leaves for it;
## the panel takes its content's height up to the rect's.
func place(rect: Rect2, bottom_anchored: bool) -> void:
	size = Vector2(rect.size.x, 0)
	var chrome := get_theme_stylebox("panel").get_minimum_size().y + _top.get_combined_minimum_size().y
	var want := _body.get_combined_minimum_size().y + chrome
	# shadow-3 falls away from the scene: up off a bottom sheet, down
	# under a side panel.
	(get_theme_stylebox("panel") as StyleBoxFlat).shadow_offset = Vector2(0, -12 if bottom_anchored else 10)
	var h := minf(want, rect.size.y)
	_scroll.custom_minimum_size.y = maxf(h - chrome, 0.0)
	size = Vector2(rect.size.x, h)
	position = Vector2(rect.position.x, rect.end.y - h if bottom_anchored else rect.position.y)
