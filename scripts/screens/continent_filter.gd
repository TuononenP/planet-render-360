class_name ContinentFilter
extends VBoxContainer

## One row of chips that filters the "Around the world" shelf by continent
## (design system: Chip, one selected at a time). Phones and tablets get a
## single sideways row, so it costs one line of the sheet; the side panel
## has the width to wrap it onto two. The selected chip is the accent fill.

signal selected(key: String)

const CHIP_PAD := 14
const GAP := 8

var key := CapitalContinents.FEATURED
var _scroll: ScrollContainer
var _row: HBoxContainer
var _flow: HFlowContainer
var _buttons: Array[Button] = []
var _keys: Array[String] = []

func _init() -> void:
	_scroll = ScrollContainer.new()
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# No bar: the chips running off the edge say the row scrolls.
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	add_child(_scroll)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", GAP)
	_scroll.add_child(_row)
	_flow = HFlowContainer.new()
	_flow.add_theme_constant_override("h_separation", GAP)
	_flow.add_theme_constant_override("v_separation", GAP)
	_flow.visible = false
	add_child(_flow)
	for filter in CapitalContinents.FILTERS:
		var b := UiTheme.chip_button(str(filter[1]))
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		b.clip_text = false
		b.focus_mode = Control.FOCUS_ALL
		var chip_key := str(filter[0])
		b.pressed.connect(func() -> void: select(chip_key, true))
		_row.add_child(b)
		_buttons.append(b)
		_keys.append(chip_key)
	restyle()

## Choose a chip. `emit` is false for a change that came from code.
func select(new_key: String, emit := false) -> void:
	if new_key not in _keys:
		return
	var changed := new_key != key
	key = new_key
	restyle()
	if emit and changed:
		selected.emit(key)

## A chip for a continent with no places is not offered.
func set_available(keys: Array) -> void:
	for i in _buttons.size():
		_buttons[i].visible = _keys[i] == CapitalContinents.FEATURED or _keys[i] in keys

## Side panel: wrap onto rows. Sheet: one scrolling row.
func set_wrapped(on: bool) -> void:
	if _flow.visible == on:
		return
	_scroll.visible = not on
	_flow.visible = on
	var to: Container = _flow if on else _row
	for b in _buttons:
		b.get_parent().remove_child(b)
		to.add_child(b)
	# The row restarts at its left edge: keep the chosen chip in view.
	_reveal_selected.call_deferred()

## Re-skin after an accent change; also applies the selection.
func restyle() -> void:
	for i in _buttons.size():
		var on := _keys[i] == key
		UiTheme.apply_chip(_buttons[i], on, CHIP_PAD)
		_buttons[i].set_pressed_no_signal(on)
	_reveal_selected.call_deferred()

func _reveal_selected() -> void:
	var at := _keys.find(key)
	if at >= 0 and _scroll.visible and is_inside_tree():
		_scroll.ensure_control_visible(_buttons[at])
