class_name Announcer
extends Label

## Screen-reader announcements (design system Accessibility): a polite
## live region. Text set here is read out by the OS screen reader;
## `min_gap` throttles how often (the viewer: at most every 2 s).

var min_gap := 0.0
var _last := -1000.0
var _pending := ""

func _init(gap: float = 0.0) -> void:
	min_gap = gap
	accessibility_live = 1  # Polite
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(1, 1)
	size = Vector2(1, 1)
	clip_text = true

func say(message: String) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last < min_gap:
		_pending = message
		return
	_last = now
	_pending = ""
	text = message

func _process(_delta: float) -> void:
	if _pending != "" and Time.get_ticks_msec() / 1000.0 - _last >= min_gap:
		say(_pending)
