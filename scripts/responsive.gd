class_name Responsive
extends RefCounted

## Mobile-first responsive rules shared by every screen.
##
## Layouts are chosen from the logical width (points) of the screen:
##   COMPACT   < 640   phone portrait: single column, map fills the middle
##   MEDIUM    640-1099 tablet / landscape phone / small window: split view
##   EXPANDED  >= 1100 desktop: split view, wider sidebar, 3-col history
## Screens rebuild their container arrangement when the layout changes,
## so resizing a macOS window (or rotating a phone) relayouts live.

enum Layout { COMPACT, MEDIUM, EXPANDED }

const MEDIUM_MIN := 640.0
const EXPANDED_MIN := 1100.0

static func layout_for_width(width: float) -> Layout:
	if width >= EXPANDED_MIN:
		return Layout.EXPANDED
	if width >= MEDIUM_MIN:
		return Layout.MEDIUM
	return Layout.COMPACT

static func layout_name(layout: Layout) -> String:
	match layout:
		Layout.COMPACT:
			return "Compact"
		Layout.MEDIUM:
			return "Medium"
		_:
			return "Expanded"

static func is_split(layout: Layout) -> bool:
	return layout != Layout.COMPACT

static func page_padding(layout: Layout) -> int:
	match layout:
		Layout.COMPACT:
			return 16
		Layout.MEDIUM:
			return 24
		_:
			return 32

static func sidebar_width(layout: Layout) -> int:
	match layout:
		Layout.MEDIUM:
			return 340
		Layout.EXPANDED:
			return 400
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
			return 1
		Layout.MEDIUM:
			return 2
		_:
			return 3

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
