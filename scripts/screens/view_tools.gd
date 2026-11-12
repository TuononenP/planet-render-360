class_name ViewTools
extends RefCounted

## The viewer's extra tools and the HUD that carries them (design system
## ViewerControls): the Show chips (horizon labels, mini-map, nearby
## landmarks), the labelled actions (save a photo, copy the view link),
## the day and season sheet opened by the sun arc's day chip, the mini-map
## inset, the horizon-label layer and a toast for their outcomes. Operates
## on the view's controls via `v`, like ViewChrome (which builds the panel
## and calls into here).

const CHIPS := [["labels", "tag", "Labels", "Name peaks, towns and lakes (N)"],
	["map", "map", "Mini-map", "Mini-map (M)"],
	["nearby", "landmark", "Nearby", "Nearby landmarks (L)"]]
const ACTIONS := [["photo", "camera", "Save photo", "Save a photo (P)"],
	["panorama", "rotate-3d", "Save 360°", "Save a 360° photo to look around in (O)"],
	["link", "link", "Copy link", "Copy a link to this view (C)"]]
const DATE_TIP := "Pick a day, season or weather"
const MAP_GAP := 12.0

## Builds the Show chips into `chips`, the actions into `actions` and the
## overlays into the view's HUD. The sun arc's day chip is the date tool.
static func build(v: View360, chips: Container, actions: Container) -> void:
	for c in CHIPS:
		var b := HudParts.chip(str(c[1]), str(c[2]))
		b.tooltip_text = str(c[3])
		b.pressed.connect(_action.bind(v, str(c[0])))
		v._tool_btns[c[0]] = b
		chips.add_child(b)
	v._nearby_btn = v._tool_btns["nearby"]
	for a in ACTIONS:
		var b := HudParts.outline_button(str(a[1]), str(a[2]))
		b.tooltip_text = str(a[3])
		b.pressed.connect(_action.bind(v, str(a[0])))
		v._tool_btns[a[0]] = b
		actions.add_child(b)
	v._tool_btns["date"] = v._sun_arc.day_btn
	v._horizon = HorizonLabels.new(v)
	v._hud.add_child(v._horizon)
	v._hud.move_child(v._horizon, v._fade.get_index())
	v._minimap = MiniMap.new(v)
	v._hud.add_child(v._minimap)
	v._fps = FpsCounter.new()
	v._hud.add_child(v._fps)
	v._date_picker = DatePicker.new()
	v._date_picker.date_picked.connect(func(date: Dictionary) -> void:
		ViewConditions.set_date(v, date))
	v._date_picker.season_requested.connect(func() -> void:
		v._on_season_selected(v._data.season if v._data != null else LocationData.Season.SUMMER))
	v._date_picker.season_picked.connect(func(index: int) -> void: v._on_season_selected(index))
	v._date_picker.weather_picked.connect(func(index: int) -> void: ViewConditions.pick_weather(v, index))
	v._date_picker.select_weather(v._weather_pick)
	# The season segments live in the sheet; the view keeps them in step.
	v._season_btn = v._date_picker.seasons
	v._date_picker.closed.connect(func() -> void:
		sync(v)
		ViewChrome.layout(v))
	v._hud.add_child(v._date_picker)
	# The way-ahead badge first: a toast draws over it.
	v._stream_badge = StreamBadge.new()
	v._hud.add_child(v._stream_badge)
	v._toast = Toast.new()
	v._hud.add_child(v._toast)
	v._horizon.set_enabled(UiPrefs.horizon_labels)
	v._minimap.visible = UiPrefs.minimap
	v._fps.visible = UiPrefs.fps_counter
	sync(v)

static func _action(v: View360, key: String) -> void:
	match key:
		"date":
			toggle_date(v)
		"photo":
			photo(v)
		"panorama":
			panorama(v)
		"link":
			copy_link(v)
		"labels":
			toggle_labels(v)
		"map":
			toggle_minimap(v)
		"nearby":
			ViewChrome.toggle_nearby(v)

## A chip is selected (a check on accent-soft) while its layer is on: the
## labels, the mini-map (which a sheet may hide for the moment; it is still
## on) or the nearby list.
static func sync(v: View360) -> void:
	if v._tool_btns.is_empty():
		return
	HudParts.apply_chip(v._tool_btns["labels"], v._horizon.enabled)
	HudParts.apply_chip(v._tool_btns["map"], UiPrefs.minimap)
	ViewChrome.sync_nearby(v)
	var picked := ViewConditions.date_text(v._date)
	(v._tool_btns["date"] as Button).tooltip_text = "Date: %s" % picked if picked != "" else DATE_TIP

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
		var now := ViewConditions.place_now(v)
		v._date_picker.open_for(v._date, {"year": int(now["year"]), "month": int(now["month"]),
			"day": int(now["day"])}, v._data.season)
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
	var local := ViewConditions.place_now(v)
	if UiPrefs.photo_stamp:
		var lines := PhotoMode.stamp_lines(data.place_name, data.latitude, data.longitude,
			UiTheme.clock(v._time_hour), ViewConditions.date_text(v._date),
			HudParts.short_sources(data.attribution))
		img = await PhotoMode.stamped(v, img, lines)
		if not is_instance_valid(v):
			return
	var bytes := await PhotoMode.encode_png_async(img, v.get_tree())
	if not is_instance_valid(v):
		return
	if bytes.is_empty():
		v._photo_busy = false
		say(v, "Couldn't save the photo", "Check there is space and the folder can be written to, then try again.", "error")
		return
	PhotoMode.save_bytes(bytes, PhotoMode.file_name(data.place_name, local), "png", "PNG image",
		"Save photo", func(path: String, failed: bool) -> void:
			if not is_instance_valid(v):
				return
			v._photo_busy = false
			if failed:
				say(v, "Couldn't save the photo", "Check there is space and the folder can be written to, then try again.", "error")
			elif path != "":
				say(v, "Photo saved", path.get_file() if path.begins_with("user://") else path))

## The whole sphere around the eye as one picture (see PanoramaCapture): six
## faces rendered off-screen, so the view itself does not move. Takes a few
## seconds, during which the toast says so.
static func panorama(v: View360) -> void:
	if v._data == null or v._photo_busy:
		return
	var cam := v._viewport.get_camera_3d()
	if cam == null or DisplayServer.get_name() == "headless":
		say(v, "Couldn't take the 360° photo", "The scene isn't drawn yet. Try again in a moment.", "error")
		return
	v._photo_busy = true
	say(v, "Taking a 360° photo", "This takes a few seconds.")
	var data := v._data
	var local := ViewConditions.place_now(v)
	var lines: Array[String] = []
	if UiPrefs.photo_stamp:
		lines = PhotoMode.stamp_lines(data.place_name, data.latitude, data.longitude,
			UiTheme.clock(v._time_hour), ViewConditions.date_text(v._date),
			HudParts.short_sources(data.attribution))
	var heading := PanoramaCapture.heading_deg(cam)
	# The six faces are drawn one after another: with the view's processing
	# off, the time-lapse, drone, walking, quality governor and streaming
	# hold still, so every face sees the same sun, shadows and geometry.
	var mode := v.process_mode
	v.process_mode = Node.PROCESS_MODE_DISABLED
	var img := await PanoramaCapture.capture(v._viewport, cam, v._quality_preset, PanoramaCapture.face_px(), lines)
	if not is_instance_valid(v):
		return
	v.process_mode = mode
	if img == null:
		v._photo_busy = false
		say(v, "Couldn't take the 360° photo", "The scene didn't draw. Try again.", "error")
		return
	var bytes := await PanoramaCapture.encode_async(img, heading, v.get_tree())
	if not is_instance_valid(v):
		return
	if bytes.is_empty():
		v._photo_busy = false
		say(v, "Couldn't save the 360° photo", "Check there is space and the folder can be written to, then try again.", "error")
		return
	# Gallery copy first: the exported file may land anywhere the dialog
	# puts it, but the in-app Gallery must always be able to list it.
	# If the Gallery write fails the export still runs, so the photo is
	# not lost; the messages below say which copy exists.
	var in_gallery := not PanoramaLibrary.add(bytes, data.place_name, data.latitude, data.longitude,
		heading, local, img).is_empty()
	PhotoMode.save_bytes(bytes, PanoramaCapture.file_name(data.place_name, local), "jpg", "JPEG image",
		"Save 360° photo", func(path: String, failed: bool) -> void:
			if not is_instance_valid(v):
				return
			v._photo_busy = false
			var shown := path.get_file() if path.begins_with("user://") else path
			if not in_gallery:
				if failed:
					say(v, "Couldn't save the 360° photo", "Check there is space and the folder can be written to, then try again.", "error")
				elif path != "":
					say(v, "360° photo saved, but not to Gallery", "Gallery is out of space or can't be written to. " + shown, "caution")
				else:
					say(v, "Couldn't save the 360° photo to Gallery", "Check there is space on this device, then try again.", "error")
			elif failed:
				say(v, "Saved to Gallery, but couldn't export a copy", "Check there is space and the folder can be written to, then export it again from Gallery.", "caution")
			elif path != "":
				say(v, "360° photo saved", "Find it in Gallery · " + shown)
			else:
				say(v, "360° photo saved to Gallery", "No copy was exported. You can export one from Gallery later."))

## A brief white flash over the scene, like a shutter (none under Reduce motion).
static func flash(v: View360) -> void:
	if UiPrefs.reduce_motion:
		return
	var f := ColorRect.new()
	f.color = Color(1, 1, 1, 0.7)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v._hud.add_child(f)
	# Full-bleed: the HUD layer sits inside the safe area on every side.
	f.position = -v._hud.position
	f.size = v.size
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

## Flips the preference, not the inset's visibility: a sheet may be hiding
## the inset for the moment, and the person still means to switch it off.
static func toggle_minimap(v: View360) -> void:
	UiPrefs.minimap = not UiPrefs.minimap
	v._minimap.visible = UiPrefs.minimap
	v.pref_changed.emit("minimap", UiPrefs.minimap)
	sync(v)
	ViewChrome.layout(v)

static func toggle_fps(v: View360) -> void:
	UiPrefs.fps_counter = not UiPrefs.fps_counter
	v._fps.visible = UiPrefs.fps_counter
	v.pref_changed.emit("fps_counter", UiPrefs.fps_counter)
	ViewChrome.layout(v)

# --- Layout ---

## Places the date sheet, the mini-map and the toast. `sheet` is the
## controls bar's rect; `inspector` true when it is the desktop side panel.
static func layout(v: View360, lay: Responsive.Layout, inspector: bool, pad: float,
		w: float, h: float, attr_h: float, sheet: Rect2) -> void:
	if v._minimap == null:
		return  # still being built
	var phone := lay == Responsive.Layout.COMPACT
	# The way-ahead badge: right-aligned under the top-right chips, and
	# under the pill and its heading tape (phones) or the ring where it
	# would reach them. An open inspector runs down that edge, so the
	# badge moves left of it, under the ring.
	var under_right := v._top_right.position.y + v._top_right.size.y + 8.0
	var top_end := v._top.position.y + v._top.size.y + 8.0
	var badge := v._stream_badge
	badge.custom_minimum_size.x = minf(StreamBadge.W, w - pad * 2.0)
	badge.reset_size()
	var badge_at := Vector2(v._top_right.position.x + v._top_right.size.x - badge.size.x, under_right)
	var ring := Rect2(v._compass.position, Vector2(CompassDial.RING, CompassDial.RING))
	var beside_sheet := inspector and v._sheet.visible \
		and Rect2(badge_at, badge.size).intersects(sheet)
	if beside_sheet:
		badge_at = Vector2(sheet.position.x - 8.0 - badge.size.x, maxf(under_right, ring.end.y + 8.0))
	if Rect2(badge_at, badge.size).intersects(Rect2(v._top.position, v._top.size)):
		badge_at.y = maxf(badge_at.y, top_end)
	if not phone and Rect2(badge_at, badge.size).intersects(ring):
		badge_at.y = maxf(badge_at.y, ring.end.y + 8.0)
	badge.position = badge_at
	# FPS counter: under the badge while it shows; else right-aligned under
	# the top-right chips, or, on a short wide window where the inspector
	# tucks in there, under the back button and the pill.
	v._fps.reset_size()
	if badge.visible:
		v._fps.position = Vector2(badge_at.x + badge.size.x - v._fps.size.x, badge_at.y + badge.size.y + 8.0)
	elif inspector and h < 500.0:
		v._fps.position = Vector2(pad, maxf(v._exit_btn.position.y + v._exit_btn.size.y + 8.0, top_end))
	else:
		v._fps.position = Vector2(v._top_right.position.x + v._top_right.size.x - v._fps.size.x,
			under_right)
	# Mini-map: bottom-left above the attribution, over the bar where the
	# two meet; the landmark sheet takes that edge while it is open.
	var panel_open: bool = v._landmark_panel != null and v._landmark_panel.is_open()
	var box := MiniMap.SIZE_PHONE if phone else MiniMap.SIZE_DESKTOP
	v._minimap.set_box(box)
	v._minimap.position = Vector2(pad, h - pad - attr_h - 8.0 - box)
	if v._sheet.visible and Rect2(v._minimap.position, Vector2(box, box)).intersects(sheet.grow(MAP_GAP)):
		v._minimap.position.y = sheet.position.y - MAP_GAP - box
	v._minimap.visible = UiPrefs.minimap and not panel_open
	# A short phone's bar reaches up to the pill and the badge: no room.
	var map_rect := Rect2(v._minimap.position, Vector2(box, box))
	for c: Control in [v._top, v._exit_btn, badge, v._fps]:
		if c.visible and map_rect.intersects(c.get_rect()):
			v._minimap.visible = false
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

## The toast, once the zoom stack has its place. Phones: centred above
## the controls and above the drone button, the round tab and the
## mini-map. Wider windows: bottom-right, ending left of the zoom stack
## and the inspector, and beside the mini-map while that leaves it room.
static func place_toast(v: View360, phone: bool, inspector: bool, pad: float,
		w: float, h: float, attr_h: float) -> void:
	if not v._toast.visible:
		return
	var host := Vector2(w, h)
	var floats: Array[Control] = [v._zoom_stack, v._sheet_tab, v._minimap]
	var bar := v._sheet.get_rect()
	if phone or (not inspector and v._sheet.visible and bar.end.y > h - pad - 96.0 - attr_h):
		# Above the bar and the floating buttons while that leaves room
		# under the top cluster; else over the bar, never off the top.
		var top_clear := v._top.get_rect().end.y + 8.0
		var bottom := bar.position.y if v._sheet.visible else h - pad - attr_h
		var above := bottom
		for c in floats:
			if c.visible:
				above = minf(above, c.position.y + 4.0)  # place() keeps 12 clear
		var toast_h := maxf(v._toast.get_combined_minimum_size().y, 56.0)
		if above - 12.0 - toast_h >= top_clear:
			bottom = above
		elif bottom - 12.0 - toast_h < top_clear:
			bottom = h - pad - attr_h
		v._toast.place(host, pad, bottom, true)
		return
	# The band a toast takes at the bottom edge (two wrapped lines).
	var band := Rect2(0.0, h - pad - 96.0, w, 96.0)
	var right := w - pad
	var left := pad
	for c in floats:
		var r := c.get_rect()
		if not c.visible or not r.intersects(band):
			continue
		if c == v._minimap:
			left = maxf(left, r.end.x + 8.0)
		else:
			right = minf(right, r.position.x - 8.0)
	if inspector and v._sheet.visible and v._sheet.get_rect().intersects(band):
		right = minf(right, v._sheet.position.x - 8.0)
	if right - left < 280.0:
		left = pad  # too narrow beside the mini-map: over it, never the buttons
	v._toast.place(host, pad, h - pad - attr_h, false, right, right - left)
