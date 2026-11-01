class_name ViewCallouts
extends Control

## Landmark callouts over the 360 view (design system Callout): when a
## known landmark sits within 8° of the view centre for 400 ms, a float-
## glass label (accent-soft icon tile, display-s name, body-s meta line)
## appears above it, tied to it by a 1px ink leader line. At most two at
## once; the nearer to the centre wins. Esc closes them until they leave
## the view centre. Sites come from the place's curated landmark and its
## named OSM landmark candidates.

const CONE_DEG := 8.0
const DWELL_S := 0.4
const MAX_SHOWN := 2
const LIFT := 72.0

var _view: View360
var _sites: Array = []  # {id, name, kind, icon, pos: Vector3}
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
	if data == null:
		return
	if data.landmark_type != "none":
		var lp := TerrainBuilder.landmark_world_pos(data)
		_sites.append({"id": "curated", "name": LocationData.landmark_name(data.landmark_type),
			"kind": "Landmark", "icon": "landmark", "pos": _site(ground, lp.x, lp.y, 60.0)})
	for i in data.landmark_candidates.size():
		var c: Dictionary = data.landmark_candidates[i]
		var n := str(c.get("name", ""))
		if n == "":
			continue
		var kind := str(c.get("archetype", "landmark")).replace("_", " ").capitalize()
		_sites.append({"id": "osm%d" % i, "name": n, "kind": kind,
			"icon": "mountain" if kind == "Peak" else "building-2",
			"pos": _site(ground, float(c.get("x", 0.0)), float(c.get("z", 0.0)),
				float(c.get("height", 20.0)) * 0.5)})

func _site(ground: GroundTruth, x: float, z: float, lift: float) -> Vector3:
	var y := ground.height_at_world(x, z) if ground != null else 0.0
	return Vector3(x, y + lift, z)

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
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := UiTheme.style(UiTheme.CARD, UiTheme.RADIUS_M, UiTheme.GLASS_EDGE, true)
	st.content_margin_left = 8
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	st.content_margin_right = 16
	card.add_theme_stylebox_override("panel", st)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(36, 36)
	tile.add_theme_stylebox_override("panel", UiTheme.style(UiTheme.TEAL_SOFT, UiTheme.RADIUS_S))
	var icon := UiIcon.rect(str(s["icon"]), 20, UiTheme.TEAL)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tile.add_child(icon)
	row.add_child(tile)
	var col := VBoxContainer.new()
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
