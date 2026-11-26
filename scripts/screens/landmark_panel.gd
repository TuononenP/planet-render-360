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
const SEARCH_PLACEHOLDER := "Search landmarks"

var card: LandmarkCard
var list: LandmarkList
var _top: HBoxContainer
var _back: Button
var _title: Label
var _search: LineEdit
var _body: VBoxContainer
var _scroll: ScrollContainer
var _close: Button
var _listing := false
var _list_scroll := 0
## The latest rows and whether more may still arrive: what Back shows.
var _rows: Array = []
var _pending := false
## The kind filter under the search: "" for All kinds, else one of
## _kind_options (the kinds in _rows). Both the nearby rows and the
## city-wide provider matches pass through it.
var _kind: OptionButton
var _kind_value := ""
var _kind_options: Array = []
## The current search text, and where city-wide matches come from: a
## Callable taking the query String and returning ranked rows (see
## ViewCallouts.search_rows). Empty until ViewChrome sets it; without
## it a search filters only the nearby rows already shown.
var _query := ""
var _search_provider := Callable()

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
	_search = UiTheme.search_field(SEARCH_PLACEHOLDER)
	_search.clear_button_enabled = true
	_search.tooltip_text = "Search landmarks in this city"
	_search.visible = false
	_search.text_changed.connect(_on_search_changed)
	col.add_child(_search)
	_kind = OptionButton.new()
	_kind.tooltip_text = "Filter by kind"
	_kind.visible = false
	UiTheme.apply_option(_kind)
	_kind.item_selected.connect(_on_kind_selected)
	col.add_child(_kind)
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

## Where city-wide matches come from (ViewChrome sets this to the
## view's callouts): a Callable taking the query String and returning
## ranked rows, nearest first.
func set_search_provider(provider: Callable) -> void:
	_search_provider = provider

func _on_search_changed(text: String) -> void:
	_query = text
	_apply_search()

func _on_kind_selected(index: int) -> void:
	_kind_value = "" if index <= 0 else str(_kind_options[index - 1])
	_apply_search()

## The kinds in the latest rows, offered beside the search. Keeps the
## choice when the rows still carry it, else falls back to All kinds.
func _refresh_kinds() -> void:
	var options := LandmarkList.kinds_in(_rows)
	if options == _kind_options:
		return
	_kind_options = options
	_kind.clear()
	_kind.add_item("All kinds")
	for k in options:
		_kind.add_item(str(k))
	if _kind_value != "" and _kind_value not in options:
		_kind_value = ""
	_kind.select(0 if _kind_value == "" else options.find(_kind_value) + 1)

## Show the nearby rows, or the city-wide matches for `_query`: both
## pass through the kind filter, so Back keeps one filtered list.
func _apply_search() -> void:
	if not is_listing():
		return
	var q := _query.strip_edges()
	if q == "":
		list.set_rows(LandmarkList.filter_kinds(_rows, _kind_value), _pending)
		return
	var base: Array
	if _search_provider.is_valid():
		base = _search_provider.call(q) as Array
	else:
		base = LandmarkList.filter_rows(_rows, q)
	list.set_rows(LandmarkList.filter_kinds(base, _kind_value), false, q)

## The nearest landmarks (LandmarkList.rank rows); `pending` while the
## nearby articles that may add more are still on their way. Opening
## clears any previous search, so the list starts at the nearest.
func open_list(rows: Array, pending: bool = false) -> void:
	_rows = rows
	_pending = pending
	_query = ""
	if _search != null:
		_search.set_block_signals(true)
		_search.text = ""
		_search.set_block_signals(false)
	_refresh_kinds()
	_show(true, false, not visible)
	_apply_search()

## Back from a card to the list it was opened from, with any rows that
## arrived meanwhile, and focus on the landmark just read. A search in
## progress stays applied, so Back returns to the matches.
func show_list() -> void:
	_apply_or_show_all()
	_show(true, false, false)
	_scroll.set_deferred("scroll_vertical", _list_scroll)
	list.focus_site(str(card.site.get("id", "")))

func _apply_or_show_all() -> void:
	if _query.strip_edges() != "":
		_apply_search()
	else:
		list.set_rows(LandmarkList.filter_kinds(_rows, _kind_value), _pending)

## New rows (late nearby articles): shown now when the list is up, else
## when Back returns to it. An active search re-queries, so late rows
## and city matches join the filtered list together.
func update_list(rows: Array, pending: bool = false) -> void:
	_rows = rows
	_pending = pending
	_refresh_kinds()
	if is_listing():
		_apply_search()

## Keyboard focus into the list (opened with L): the nearest landmark.
func focus_list() -> void:
	if is_listing():
		list.focus_row(0)

func _show(listing: bool, from_list: bool, fade: bool) -> void:
	_listing = listing
	list.visible = listing
	card.visible = not listing
	_back.visible = from_list
	_search.visible = listing
	_kind.visible = listing
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
	if _search.visible:
		chrome += _search.get_combined_minimum_size().y + 8.0
		chrome += _kind.get_combined_minimum_size().y + 8.0
	var want := _body.get_combined_minimum_size().y + chrome
	# shadow-3 falls away from the scene: up off a bottom sheet, down
	# under a side panel.
	(get_theme_stylebox("panel") as StyleBoxFlat).shadow_offset = Vector2(0, -12 if bottom_anchored else 10)
	var h := minf(want, rect.size.y)
	_scroll.custom_minimum_size.y = maxf(h - chrome, 0.0)
	size = Vector2(rect.size.x, h)
	position = Vector2(rect.position.x, rect.end.y - h if bottom_anchored else rect.position.y)
