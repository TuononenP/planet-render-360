class_name ViewTools
extends RefCounted

## The viewer's extra tools and the HUD that carries them: a row of round
## buttons under the zoom row (date, photo, copy view link, horizon labels,
## mini-map), the date picker sheet, the mini-map inset, the horizon-label
## layer and a toast for their outcomes. Operates on the view's controls via
## `v`, like ViewChrome (which builds the rows and calls into here).

const ICONS := {"date": "calendar", "photo": "camera", "link": "link",
	"labels": "tag", "map": "map"}
const TIPS := {"date": "Pick a date", "photo": "Save a photo (P)",
	"link": "Copy a link to this view (C)", "labels": "Name peaks, towns and lakes (N)",
	"map": "Mini-map (M)"}
const MAP_GAP := 12.0

## Builds the tool buttons into `row` and the overlays into the view's HUD.
static func build(v: View360, row: Container) -> void:
	for key in ["date", "photo", "link", "labels", "map"]:
		var b := HudParts.icon_button(str(ICONS[key]), str(TIPS[key]))
		b.tooltip_text = str(TIPS[key])
		b.pressed.connect(_action.bind(v, key))
		v._tool_btns[key] = b
		row.add_child(b)
	v._horizon = HorizonLabels.new(v)
	v._hud.add_child(v._horizon)
	v._hud.move_child(v._horizon, v._fade.get_index())
	v._minimap = MiniMap.new(v)
	v._minimap.open_requested.connect(func() -> void: v.back_requested.emit())
	v._hud.add_child(v._minimap)
	v._date_picker = DatePicker.new()
	v._date_picker.date_picked.connect(func(date: Dictionary) -> void:
		ViewConditions.set_date(v, date))
	v._date_picker.season_requested.connect(func() -> void:
		ViewConditions._on_season_selected(v, v._data.season if v._data != null else 1))
	v._date_picker.closed.connect(func() -> void:
		sync(v)
		ViewChrome.layout(v))
	v._hud.add_child(v._date_picker)
	v._toast = Toast.new()
	v._hud.add_child(v._toast)
	v._horizon.set_enabled(UiPrefs.horizon_labels)
	v._minimap.visible = UiPrefs.minimap
	sync(v)

static func _action(v: View360, key: String) -> void:
	match key:
		"date":
			toggle_date(v)
		"photo":
			photo(v)
		"link":
			copy_link(v)
		"labels":
			toggle_labels(v)
		"map":
			toggle_minimap(v)

## Lit (accent fill) while a tool is on: the date picker is up or a date
## is picked, the labels or the mini-map are showing.
static func sync(v: View360) -> void:
	if v._tool_btns.is_empty():
		return
	var lit := {"date": v._date_picker.visible or not v._date.is_empty(),
		"labels": v._horizon.enabled, "map": v._minimap.visible}
	for key in v._tool_btns:
		HudParts.apply_icon_button(v._tool_btns[key], bool(lit.get(key, false)))
	var picked := ViewConditions.date_text(v._date)
	(v._tool_btns["date"] as Button).tooltip_text = "Date: %s" % picked if picked != "" else str(TIPS["date"])

# --- Toast ---

static func say(v: View360, title: String, message: String = "", tone: String = "good") -> void:
	if v._toast == null:
		return
	v._toast.show_message(title, message, tone)
	ViewChrome.layout(v)

# --- Date ---

static func toggle_date(v: View360) -> void:
	if v._data == null:
		return
	if v._date_picker.visible:
		v._date_picker.close_picker()
	else:
		var now := Time.get_datetime_dict_from_unix_time(
			int(Time.get_unix_time_from_system() + v._atmos.utc_offset_h * 3600.0))
		v._date_picker.open_for(v._date, {"year": int(now["year"]), "month": int(now["month"]),
			"day": int(now["day"])})
	sync(v)
	ViewChrome.layout(v)

# --- Link ---

## The link to the view as it stands: camera, time, season, picked date.
static func current_link(v: View360) -> String:
	if v._data == null or v._ground == null:
		return ""
	return ViewLink.encode(ViewLink.capture(v._data, v._ground, v._rig, true,
		v._time_hour * 60.0, v._date))

static func copy_link(v: View360) -> void:
	var link := current_link(v)
	if link == "":
		return
	DisplayServer.clipboard_set(link)
	say(v, "View link copied", "Paste it into search to reopen this view.")

# --- Photo ---

static func photo(v: View360) -> void:
	if v._data == null or v._photo_busy:
		return
	var img := v.snapshot()
	if img == null:
		say(v, "Couldn't take the photo", "The scene isn't drawn yet. Try again in a moment.", "error")
		return
	v._photo_busy = true
	flash(v)
	var data := v._data
	var local := Time.get_datetime_dict_from_unix_time(
		int(Time.get_unix_time_from_system() + v._atmos.utc_offset_h * 3600.0))
	if UiPrefs.photo_stamp:
		var lines := PhotoMode.stamp_lines(data.place_name, data.latitude, data.longitude,
			UiTheme.clock(v._time_hour), ViewConditions.date_text(v._date),
			HudParts.short_sources(data.attribution))
		img = await PhotoMode.stamped(v, img, lines)
	PhotoMode.save(img, PhotoMode.file_name(data.place_name, local), func(path: String) -> void:
		v._photo_busy = false
		if path == "":
			return
		say(v, "Photo saved", path.get_file() if path.begins_with("user://") else path))

## A brief white flash over the scene, like a shutter (none under Reduce motion).
static func flash(v: View360) -> void:
	if UiPrefs.reduce_motion:
		return
	var f := ColorRect.new()
	f.color = Color(1, 1, 1, 0.7)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.set_anchors_preset(Control.PRESET_FULL_RECT)
	v._hud.add_child(f)
	v._hud.move_child(f, 0)
	var tw := v.create_tween()
	tw.tween_property(f, "color:a", 0.0, 0.3)
	tw.tween_callback(f.queue_free)

# --- Labels and mini-map ---

static func toggle_labels(v: View360) -> void:
	UiPrefs.horizon_labels = not v._horizon.enabled
	v._horizon.set_enabled(UiPrefs.horizon_labels)
	v.pref_changed.emit("horizon_labels", UiPrefs.horizon_labels)
	sync(v)

static func toggle_minimap(v: View360) -> void:
	UiPrefs.minimap = not v._minimap.visible
	v._minimap.visible = UiPrefs.minimap
	v.pref_changed.emit("minimap", UiPrefs.minimap)
	sync(v)
	ViewChrome.layout(v)

# --- Layout ---

## Places the date sheet, the mini-map and the toast. `sheet` is the
## controls bar's rect; `inspector` true when it is the desktop side panel.
static func layout(v: View360, lay: Responsive.Layout, inspector: bool, pad: float,
		w: float, h: float, attr_h: float, sheet: Rect2) -> void:
	if v._minimap == null:
		return  # still being built
	var phone := lay == Responsive.Layout.COMPACT
	# Mini-map: bottom-left above the attribution, over the bar where the
	# two meet; the landmark sheet takes that edge while it is open.
	var panel_open: bool = v._landmark_panel != null and v._landmark_panel.is_open()
	var box := MiniMap.SIZE_PHONE if phone else MiniMap.SIZE_DESKTOP
	v._minimap.set_box(box)
	v._minimap.position = Vector2(pad, h - pad - attr_h - 8.0 - box)
	if v._sheet.visible and Rect2(v._minimap.position, Vector2(box, box)).intersects(sheet.grow(MAP_GAP)):
		v._minimap.position.y = sheet.position.y - MAP_GAP - box
	v._minimap.visible = UiPrefs.minimap and not panel_open
	# Date sheet: beside the inspector, or in the bar's place (the bar
	# steps aside while it is open, like the landmark sheet).
	var picker := v._date_picker
	if picker.visible:
		picker.reset_size()
		var ps := picker.get_combined_minimum_size()
		picker.size = ps
		if inspector:
			picker.position = Vector2(maxf(sheet.position.x - 8.0 - ps.x, pad), sheet.position.y)
		else:
			v._sheet.visible = false
			picker.position = Vector2(roundf((w - ps.x) / 2.0),
				maxf(h - pad - attr_h - 8.0 - ps.y, pad))
			v._minimap.visible = false
	# Toast: above the bar on phones, bottom-right of the free area otherwise.
	if v._toast.visible:
		v._toast.place(v.size, pad, sheet.position.y if v._sheet.visible else h - pad - attr_h, phone)
