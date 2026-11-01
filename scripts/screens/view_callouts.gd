class_name ViewCallouts
extends Control

## Landmark callouts over the 360 view (design system Callout): when a
## known landmark sits within 8° of the view centre for 400 ms, a float-
## glass label (accent-soft icon tile, display-s name, body-s meta line)
## appears above it, tied to it by a 1px ink leader line. At most two at
## once; the nearer to the centre wins. Esc closes them until they leave
## the view centre. Sites come from the place's curated landmark, its
## named OSM landmark candidates, nearby articles (add_sites) and the
## landmark the viewer came to see (LocationData.focus). Each site is a
## LandmarkVisit site plus its world `pos`; tapping a callout opens it in
## the landmark panel (site_tapped).

signal site_tapped(site: Dictionary)

const CONE_DEG := 8.0
const DWELL_S := 0.4
const MAX_SHOWN := 2
const LIFT := 72.0
const TAP_MAX_PX := 14.0
## Two sites this close (metres) are one place: the first one wins.
const SAME_SITE_M := 60.0

var _view: View360
var _data: LocationData
var _ground: GroundTruth
var _sites: Array = []  # LandmarkVisit site + {pos: Vector3}
var _since := {}  # id -> seconds inside the cone
var _dismissed := {}  # id -> true until it leaves the cone
var _cards := {}  # id -> PanelContainer
var _anchors := {}  # id -> screen point

func _init(view: View360) -> void:
	_view = view
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

## New place: collect its sites (world metres; WorldScale is 1 unit/m).
func set_place(data: LocationData, ground: GroundTruth) -> void:
	clear()
	_sites.clear()
	_data = data
	_ground = ground
	if data == null:
		return
	if data.landmark_type != "none":
		var lp := TerrainBuilder.landmark_world_pos(data)
		var entry := LocationData.landmark_entry(data.landmark_lat, data.landmark_lon,
			LocationData.landmark_name(data.landmark_type))
		var s := LandmarkVisit.from_registry(entry) if not entry.is_empty() \
			else LandmarkVisit.site(LocationData.landmark_name(data.landmark_type), 0.0, 0.0, "Landmark", "curated")
		_add(s, lp, 60.0)
	for i in data.landmark_candidates.size():
		var c: Dictionary = data.landmark_candidates[i]
		var n := str(c.get("name", ""))
		if n == "":
			continue
		var xz := Vector2(float(c.get("x", 0.0)), float(c.get("z", 0.0)))
		if not _find(n, xz).is_empty():
			continue  # "Tour Eiffel" is the curated Eiffel Tower
		if c.has("type"):
			var reg := LocationData.entry_for_type(str(c["type"]))
			if not reg.is_empty():
				_add(LandmarkVisit.from_registry(reg), xz, float(c.get("height", 20.0)) * 0.5)
				continue
		var kind := str(c.get("archetype", "landmark")).replace("_", " ").capitalize()
		var s := LandmarkVisit.site(n, 0.0, 0.0, kind, "osm", float(c.get("height", 0.0)))
		s["kind"] = kind
		s["wikipedia"] = str(c.get("wikipedia", ""))
		_add(s, xz, float(c.get("height", 20.0)) * 0.5)
	if not data.focus.is_empty():
		add_sites([data.focus])

## More sites by lat/lon (nearby articles, the focus): placed on the
## ground out to the far rings; a site already shown (same name or
## within SAME_SITE_M) only lends it its article.
func add_sites(sites: Array) -> void:
	if _data == null:
		return
	for s in sites:
		var xz := WorldScale.xz_from_latlon(float(s["lat"]), float(s["lon"]), _data.latitude, _data.longitude)
		if xz.length() > TerrainBuilder.LANDMARK_MAX_M:
			continue
		var known := _find(str(s["name"]), xz)
		if not known.is_empty():
			if str(known.get("wiki_title", "")) == "" and str(known.get("wikipedia", "")) == "":
				known["wiki_title"] = str(s.get("wiki_title", ""))
				known["wiki_lang"] = str(s.get("wiki_lang", ""))
				if str(known.get("description", "")) in ["", known.get("kind", "")]:
					known["description"] = str(s.get("description", ""))
			continue
		var lift := 0.0 if str(s.get("kind", "")) == "Peak" else maxf(float(s.get("height_m", 0.0)) * 0.5, 20.0)
		_add(s.duplicate(), xz, lift)

func _find(name: String, xz: Vector2) -> Dictionary:
	var by_name := WikiParse.match_name(name, _sites)
	if not by_name.is_empty():
		return by_name
	for s in _sites:
		var p: Vector3 = s["pos"]
		if Vector2(p.x, p.z).distance_to(xz) < SAME_SITE_M:
			return s
	return {}

func _add(s: Dictionary, xz: Vector2, lift: float) -> void:
	if float(s.get("lat", 0.0)) == 0.0 and float(s.get("lon", 0.0)) == 0.0 and _data != null:
		var ll := WorldScale.latlon_from_xz(xz.x, xz.y, _data.latitude, _data.longitude)
		s["lat"] = ll.x
		s["lon"] = ll.y
	var y := 0.0
	if _ground != null:
		y = TerrainBuilder.site_ground_y(_data, _ground, xz.x, xz.y) \
			if not _ground.is_inside(xz.x, xz.y) else _ground.height_at_world(xz.x, xz.y)
	s["pos"] = Vector3(xz.x, y + lift, xz.y)
	_sites.append(s)

func sites() -> Array:
	return _sites

func clear() -> void:
	for id in _cards:
		(_cards[id] as Node).queue_free()
	_cards.clear()
	_anchors.clear()
	_since.clear()
	_dismissed.clear()
	queue_redraw()

## Esc: close the open callouts. Returns false when none were open.
func dismiss() -> bool:
	if _cards.is_empty():
		return false
	for id in _cards:
		_dismissed[id] = true
	for id in _cards.keys():
		(_cards[id] as Node).queue_free()
	_cards.clear()
	_anchors.clear()
	queue_redraw()
	return true

func _process(delta: float) -> void:
	if not is_visible_in_tree() or _sites.is_empty() or _view._rig == null:
		return
	var cam := _view._rig.camera
	if cam == null:
		return
	var origin := cam.global_position
	var forward := -cam.global_transform.basis.z
	var inside: Array = []
	for s in _sites:
		var to: Vector3 = (s["pos"] as Vector3) - origin
		var ang := rad_to_deg(forward.angle_to(to.normalized()))
		var id: String = s["id"]
		if ang <= CONE_DEG:
			_since[id] = float(_since.get(id, 0.0)) + delta
			if float(_since[id]) >= DWELL_S and not _dismissed.has(id):
				inside.append([ang, s, to.length()])
		else:
			_since.erase(id)
			_dismissed.erase(id)
	inside.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var want := {}
	for item in inside.slice(0, MAX_SHOWN):
		var s: Dictionary = item[1]
		want[s["id"]] = true
		if not _cards.has(s["id"]):
			_cards[s["id"]] = _make_card(s, float(item[2]))
			ViewChrome.announce(_view, str(s["name"]))
		var pt := cam.unproject_position(s["pos"])
		_anchors[s["id"]] = pt
		var card := _cards[s["id"]] as PanelContainer
		card.reset_size()
		card.position = Vector2(clampf(pt.x - card.size.x / 2.0, 8.0, size.x - card.size.x - 8.0),
			clampf(pt.y - LIFT - card.size.y, 8.0, size.y - card.size.y - 8.0))
	for id in _cards.keys():
		if not want.has(id):
			(_cards[id] as Node).queue_free()
			_cards.erase(id)
			_anchors.erase(id)
	queue_redraw()

func _make_card(s: Dictionary, distance_m: float) -> PanelContainer:
	var card := PanelContainer.new()
	# A tap opens the landmark (design system Callout); a drag that
	# starts on the card still looks around.
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.tooltip_text = "Show details"
	# The whole card is the button: reachable by keyboard and named for
	# screen readers, with the focus ring on keyboard focus.
	card.focus_mode = Control.FOCUS_ALL
	card.accessibility_name = "%s, %s. Show details" % [s["name"], s["kind"]]
	card.focus_entered.connect(card.queue_redraw)
	card.focus_exited.connect(card.queue_redraw)
	card.draw.connect(func() -> void:
		if card.has_focus():
			card.draw_style_box(UiTheme._focus_ring(UiTheme.RADIUS_M), Rect2(Vector2.ZERO, card.size)))
	card.gui_input.connect(func(e: InputEvent) -> void: _card_input(card, s, e))
	var st := UiTheme.style(UiTheme.CARD, UiTheme.RADIUS_M, UiTheme.GLASS_EDGE, true)
	st.content_margin_left = 8
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	st.content_margin_right = 16
	card.add_theme_stylebox_override("panel", st)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(36, 36)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE  # the icon taps through to the card
	tile.add_theme_stylebox_override("panel", UiTheme.style(UiTheme.TEAL_SOFT, UiTheme.RADIUS_S))
	var icon := UiIcon.rect(str(s["icon"]), 20, UiTheme.TEAL)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tile.add_child(icon)
	row.add_child(tile)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	col.add_child(UiTheme.display_label(str(s["name"]), 22))
	col.add_child(UiTheme.label("%s · %s" % [s["kind"], distance_text(distance_m)], 14, UiTheme.MUTED))
	card.modulate.a = 0.0
	add_child(card)
	# Enters with ease-enter over duration-standard.
	create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT) \
		.tween_property(card, "modulate:a", 1.0, UiPrefs.motion(0.24))
	return card

func _card_input(card: Control, s: Dictionary, e: InputEvent) -> void:
	if e is InputEventKey and (e as InputEventKey).pressed and not (e as InputEventKey).echo \
			and (e as InputEventKey).keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		site_tapped.emit(s)
		card.accept_event()
		return
	var press := e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	if not press and not e is InputEventScreenTouch:
		if e is InputEventMouseMotion or e is InputEventScreenDrag:
			_view._gui_input(e)  # keep looking around across the card
		return
	var pos: Vector2 = e.position
	if e.is_pressed():
		card.set_meta("down", pos)
	elif card.has_meta("down"):
		var moved := (card.get_meta("down") as Vector2).distance_to(pos)
		card.remove_meta("down")
		if moved <= TAP_MAX_PX:
			site_tapped.emit(s)
	card.accept_event()

## Metres from the camera to a site.
func distance_to(s: Dictionary) -> float:
	if _view._rig == null or not s.has("pos"):
		return -1.0
	return (s["pos"] as Vector3).distance_to(_view._rig.global_position)

## "450 m" below a kilometre, "6.2 km" above.
static func distance_text(m: float) -> String:
	if m < 1000.0:
		return "%d m" % roundi(m)
	return "%.1f km" % (m / 1000.0)

func _draw() -> void:
	for id in _cards:
		if not _anchors.has(id):
			continue
		var card := _cards[id] as PanelContainer
		var from := card.position + Vector2(card.size.x / 2.0, card.size.y)
		draw_line(from, _anchors[id], Color(UiTheme.INK, card.modulate.a), 1.0, true)
