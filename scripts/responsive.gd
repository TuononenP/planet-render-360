class_name Responsive
extends RefCounted

## Mobile-first responsive rules shared by every screen.
##
## Layouts are chosen from the logical width (points) of the screen:
##   COMPACT   < 600   phone portrait: single column, map fills the middle
##   MEDIUM    600-1023 tablet / landscape phone / small window: split view
##   EXPANDED  >= 1024 desktop: side panel (size-panel), right inspector
## (design system Layout → Breakpoints; gutters space-4 / space-6).
## Screens rebuild their container arrangement when the layout changes,
## so resizing a macOS window (or rotating a phone) relayouts live.

enum Layout { COMPACT, MEDIUM, EXPANDED }

const MEDIUM_MIN := 600.0
const EXPANDED_MIN := 1024.0

static func layout_for_width(width: float) -> Layout:
	if width >= EXPANDED_MIN:
		return Layout.EXPANDED
	if width >= MEDIUM_MIN:
		return Layout.MEDIUM
	return Layout.COMPACT

## Layout for a whole window: the width decides, except a short
## landscape window (a phone on its side, height < 500), which takes the
## side-panel arrangement so the map keeps its height.
static func layout_for_size(s: Vector2) -> Layout:
	if s.y < 500.0 and s.x > s.y:
		return Layout.EXPANDED
	return layout_for_width(s.x)

## Extra content scale for the window (Window.content_scale_factor).
## canvas_items/expand fits the 390x844 portrait frame, so a short
## landscape window (a phone on its side, a wide desktop strip) drew
## every control at under half size; there points stay at least 1:1.
## Phones and tablets pass their pixels per point (`points`): one logical
## unit is then exactly one device point, so an iPad gets its real width
## (and the tablet layout) and 16pt type is 16pt on every screen.
static func content_scale_factor(win: Vector2, points: float = 0.0) -> float:
	if win.x <= 0.0 or win.y <= 0.0:
		return 1.0
	var fit := minf(win.x / 390.0, win.y / 844.0)
	if points > 0.0:
		return points / fit
	var landscape := minf(1.0, minf(win.x / 844.0, win.y / 390.0))
	return maxf(fit, landscape) / fit

## Device pixels per point on phones and tablets, 0 on desktop (which
## keeps fitting the design frame).
static func points_scale() -> float:
	if not OS.has_feature("mobile"):
		return 0.0
	return points_for(OS.has_feature("android"), DisplayServer.screen_get_scale(), DisplayServer.screen_get_dpi())

## Android caps screen_get_scale() by the display's size, so a phone would
## lay out as a tablet; its true density is the dpi over 160 per point.
static func points_for(android: bool, scale: float, dpi: int) -> float:
	return float(dpi) / 160.0 if android and dpi > 0 else scale

## Stands in for the device's insets in tests and captures.
static var safe_override: Array[float] = []

## Safe-area insets (notch, Dynamic Island, home indicator) in the
## control's own units, as [left, top, right, bottom]. Desktop windows
## have none.
static func safe_insets(c: Control) -> Array[float]:
	if not safe_override.is_empty():
		return safe_override
	if not OS.has_feature("mobile") or not c.is_inside_tree():
		return [0.0, 0.0, 0.0, 0.0]
	var win := Vector2(DisplayServer.window_get_size())
	var safe := DisplayServer.get_display_safe_area()
	if win.x <= 0.0 or win.y <= 0.0:
		return [0.0, 0.0, 0.0, 0.0]
	var k := c.get_viewport_rect().size / win
	return [safe.position.x * k.x, safe.position.y * k.y,
		maxf(win.x - safe.end.x, 0.0) * k.x, maxf(win.y - safe.end.y, 0.0) * k.y]

## Sets a container's margins, given as [left, top, right, bottom], plus
## the safe area on each side.
static func apply_safe_margins(m: MarginContainer, c: Control, margins: Array) -> void:
	var safe := safe_insets(c)
	for i in 4:
		m.add_theme_constant_override("margin_" + ["left", "top", "right", "bottom"][i], int(margins[i]) + int(safe[i]))

static func layout_name(layout: Layout) -> String:
	match layout:
		Layout.COMPACT:
			return "Compact"
		Layout.MEDIUM:
			return "Medium"
		_:
			return "Expanded"

## The Layout override from Settings → Appearance (0 Auto, 1 Compact,
## 2 Wide): the layout it forces, or -1 to follow the window.
static func override_layout(index: int) -> int:
	match index:
		1:
			return Layout.COMPACT
		2:
			return Layout.MEDIUM
	return -1

static func is_split(layout: Layout) -> bool:
	return layout != Layout.COMPACT

static func page_padding(layout: Layout) -> int:
	match layout:
		Layout.COMPACT:
			return 16
		_:
			return 24

static func sidebar_width(layout: Layout) -> int:
	match layout:
		Layout.MEDIUM:
			return 340
		Layout.EXPANDED:
			return 376  # size-panel
		_:
			return 0

static func content_max_width(layout: Layout) -> int:
	# Centered cards (loading) never stretch edge to edge on wide screens.
	match layout:
		Layout.COMPACT:
			return 100000
		Layout.MEDIUM:
			return 560
		_:
			return 640

static func history_columns(layout: Layout) -> int:
	match layout:
		Layout.COMPACT:
			return 2
		Layout.MEDIUM:
			return 3
		_:
			return 4

static func title_size(layout: Layout) -> int:
	return 28 if layout == Layout.COMPACT else 34

static func preview_height(layout: Layout) -> int:
	match layout:
		Layout.COMPACT:
			return 210
		Layout.MEDIUM:
			return 260
		_:
			return 300
