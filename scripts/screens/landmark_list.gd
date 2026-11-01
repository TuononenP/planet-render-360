class_name LandmarkList
extends VBoxContainer

## "Nearby landmarks" over the 360 view (design system Sheet content,
## list rows): the landmarks around the viewer, nearest first. A row is
## {site, distance_m, bearing_deg}, built by rank() from the view's
## sites. It names the landmark with its kind, the distance from where
## the camera stands and the compass direction. Tapping a row opens the
## landmark in the panel (details, photo, distance) before anyone goes;
## the trailing Go there button visits it straight away.

signal site_picked(site: Dictionary, distance_m: float)
signal go_requested(site: Dictionary)

const MAX_ROWS := 12
const ROW_H := 56.0
const EMPTY := "No landmarks found near here."
## While the nearby articles are still on their way (a calm "not yet",
## not the final "none").
const PENDING := "Looking for landmarks…"

var _key: Array = []
var _built := false

func _init() -> void:
	add_theme_constant_override("separation", 2)
	set_rows([])

## The `limit` sites (LandmarkVisit shape plus a world `pos`) nearest
## `from`, nearest first, as rows. The distance is the one ViewCallouts
## shows on a callout and in the panel.
static func rank(sites: Array, from: Vector3, limit: int = MAX_ROWS) -> Array:
	var rows: Array = []
	for s in sites:
		if not s.has("pos"):
			continue
		var to: Vector3 = (s["pos"] as Vector3) - from
		rows.append({"site": s, "distance_m": to.length(),
			"bearing_deg": LandmarkVisit.bearing_of(Vector2(to.x, to.z))})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["distance_m"]) < float(b["distance_m"]))
	return rows.slice(0, limit)

## The compass point a bearing falls on ("NE"), as the compass reads it.
static func direction(bearing_deg: float) -> String:
	return CompassDial.CARDINALS[roundi(fposmod(bearing_deg, 360.0) / 45.0) % 8]

## "450 m NE": how far, and which way from the camera.
static func distance_text(row: Dictionary) -> String:
	return "%s %s" % [ViewCallouts.distance_text(float(row["distance_m"])),
		direction(float(row["bearing_deg"]))]

func row_count() -> int:
	return get_children().filter(func(c: Node) -> bool: return c is HBoxContainer).size()

## Replace the rows; none reads as one plain line, not an error
## (`pending`: the articles that may fill it have not arrived). Rows that
## come out the same (landmark, distance, direction, order) are left as
## they are, so a late answer that adds nothing does not shift a row
## under the pointer or drop keyboard focus.
func set_rows(rows: Array, pending: bool = false) -> void:
	var key: Array = rows.map(func(r: Dictionary) -> String:
		return "%s|%s" % [(r["site"] as Dictionary).get("id", ""), distance_text(r)])
	if rows.is_empty():
		key.append("pending" if pending else "none")
	if _built and key == _key:
		return
	_built = true
	_key = key
	for c in get_children():
		remove_child(c)
		c.queue_free()
	if rows.is_empty():
		var empty := UiTheme.text(PENDING if pending else EMPTY, "body-s", UiTheme.MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(120, 0)
		add_child(empty)
		return
	for r in rows:
		add_child(_row(r as Dictionary))

func _row(r: Dictionary) -> HBoxContainer:
	var s: Dictionary = r["site"]
	var site_name := str(s["name"])
	var kind := str(s.get("kind", "Landmark"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)

	var open := Button.new()
	open.focus_mode = Control.FOCUS_ALL
	open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open.custom_minimum_size = Vector2(0, ROW_H)
	open.tooltip_text = "Show details"
	open.accessibility_name = "%s, %s, %s. Show details" % [site_name, kind, distance_text(r)]
	_skin(open)
	open.pressed.connect(func() -> void: site_picked.emit(s, float(r["distance_m"])))
	row.add_child(open)

	var pad := MarginContainer.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["margin_left", "margin_right"]:
		pad.add_theme_constant_override(side, 8)
	for side in ["margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(side, 6)
	open.add_child(pad)
	var inner := HBoxContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("separation", 12)
	pad.add_child(inner)

	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(40, 40)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_theme_stylebox_override("panel", UiTheme.style(UiTheme.TEAL_SOFT, UiTheme.RADIUS_S))
	var icon := UiIcon.rect(str(s.get("icon", "landmark")), 20, UiTheme.TEAL)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tile.add_child(icon)
	inner.add_child(tile)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	inner.add_child(col)
	var title := UiTheme.text(site_name, "headline")
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(title)
	var meta := HBoxContainer.new()
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta.add_theme_constant_override("separation", 6)
	col.add_child(meta)
	var kind_label := UiTheme.text(kind, "body-s", UiTheme.MUTED)
	kind_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kind_label.clip_text = true
	kind_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	kind_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(kind_label)
	var far := UiTheme.text(distance_text(r), "data-s")
	far.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta.add_child(far)

	# A row is 56 pt, taller when its text is (Text size up to 200%). The
	# labels only know their size once the row is in the tree, so it re-fits
	# whenever the content's minimum size changes.
	var fit := func() -> void:
		open.custom_minimum_size.y = maxf(ROW_H, pad.get_combined_minimum_size().y)
	pad.minimum_size_changed.connect(fit)
	fit.call()

	var go := UiIcon.button("navigation-2", "Go there", 20)
	go.accessibility_name = "Go to %s" % site_name
	go.pressed.connect(func() -> void: go_requested.emit(s))
	row.add_child(go)
	return row

## Move keyboard focus to row `i`, or to the row of site `id`.
func focus_row(i: int = 0) -> void:
	var b := _open_button(i)
	if b != null:
		b.grab_focus()

func focus_site(id: String) -> void:
	var i := _key.find_custom(func(k: String) -> bool: return k.begins_with(id + "|"))
	focus_row(maxi(i, 0))

func _open_button(i: int) -> Button:
	if i < 0 or i >= get_child_count() or not get_child(i) is HBoxContainer:
		return null
	return (get_child(i) as HBoxContainer).get_child(0) as Button

## Quiet row: clear until hovered, then an ink wash; the focus ring on
## keyboard focus.
static func _skin(b: Button) -> void:
	var flat := UiTheme.style(Color.TRANSPARENT, UiTheme.RADIUS_M)
	var wash := UiTheme.style(Color(UiTheme.INK, 0.08), UiTheme.RADIUS_M)
	b.add_theme_stylebox_override("normal", flat)
	for state in ["hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(state, wash)
	b.add_theme_stylebox_override("focus", UiTheme._focus_ring(UiTheme.RADIUS_M))
