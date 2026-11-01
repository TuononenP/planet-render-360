class_name LandmarkCard
extends VBoxContainer

## A landmark's details (design system Sheet content), shared by the map
## home's selected place and the 360 view's landmark panel: eyebrow kind,
## name in display-l, description, a free Commons photo with its credit,
## Readouts (distance, height, coordinates), the article's opening lines,
## Read more, and the text licence. Details come from WikiFetcher and
## degrade: without an article the card still shows the name, kind and
## readouts with one plain line saying what is missing.

signal go_requested(site: Dictionary)

const EXTRACT_CHARS := 420
const PHOTO_H := 168.0

const LOADING := "Gathering details…"
const ATTRIBUTION := "Text from Wikipedia · CC BY-SA 4.0"

var site: Dictionary = {}
var _fetcher: WikiFetcher
var _header: VBoxContainer
var _kind: Label
var _name: Label
var _desc: Label
var _photo_box: PanelContainer
var _photo: TextureRect
var _credit: Label
var _readouts: HFlowContainer
var _distance: Readout
var _height: Readout
var _coords: Readout
var _status: Label
var _extract: Label
var _more: Button
var _attribution: Label
var _go: Button
var _url := ""

## `header`: show the eyebrow and name (the map home already names the
## selection). `go`: show the Go there primary (the map keeps Explore).
func _init(fetcher: WikiFetcher, header: bool = true, go: bool = true) -> void:
	_fetcher = fetcher
	add_theme_constant_override("separation", 12)
	_header = VBoxContainer.new()
	_header.add_theme_constant_override("separation", 2)
	_header.visible = header
	add_child(_header)
	_kind = UiTheme.section_label("Landmark")
	_header.add_child(_kind)
	_name = UiTheme.text("", "display-l")
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_header.add_child(_name)
	_desc = _wrapped("", "body-s", UiTheme.MUTED)
	add_child(_desc)
	_photo_box = PanelContainer.new()
	var frame := UiTheme.style(UiTheme.SURFACE, UiTheme.RADIUS_S)
	frame.set_content_margin_all(0)
	_photo_box.add_theme_stylebox_override("panel", frame)
	_photo_box.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_photo_box.custom_minimum_size = Vector2(0, PHOTO_H)
	_photo_box.visible = false
	add_child(_photo_box)
	_photo = TextureRect.new()
	_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_photo_box.add_child(_photo)
	_credit = _wrapped("", "caption", UiTheme.MUTED)
	_credit.visible = false
	add_child(_credit)
	_readouts = HFlowContainer.new()
	_readouts.add_theme_constant_override("h_separation", 24)
	_readouts.add_theme_constant_override("v_separation", 8)
	add_child(_readouts)
	_distance = Readout.new("Distance")
	_readouts.add_child(_distance)
	_height = Readout.new("Height")
	_readouts.add_child(_height)
	_coords = Readout.new("Coordinates")
	_readouts.add_child(_coords)
	_status = _wrapped("", "body-s", UiTheme.MUTED)
	add_child(_status)
	_extract = _wrapped("", "body")
	add_child(_extract)
	_more = UiTheme.quiet_button("Read more")
	_more.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_more.pressed.connect(func() -> void:
		if _url != "":
			OS.shell_open(_url))
	add_child(_more)
	_attribution = _wrapped(ATTRIBUTION, "caption", UiTheme.MUTED)
	add_child(_attribution)
	_go = UiTheme.primary_button("Go there")
	UiIcon.apply(_go, "navigation-2", 22, UiTheme.ON_ACCENT, UiTheme.ON_ACCENT)
	_go.visible = go
	_go.pressed.connect(func() -> void: go_requested.emit(site))
	add_child(_go)
	if _fetcher != null:
		_fetcher.info_ready.connect(_on_info)
		_fetcher.info_failed.connect(_on_failed)
		_fetcher.photo_ready.connect(_on_photo)
	_set_article(false)

func _wrapped(value: String, style_name: String, color: Color = UiTheme.INK) -> Label:
	var l := UiTheme.text(value, style_name, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(120, 0)
	return l

## Show `s` (LandmarkVisit site) and ask for its article. distance_m < 0
## hides the distance readout (the map has no viewer yet).
func show_site(s: Dictionary, distance_m: float = -1.0) -> void:
	site = s
	_kind.text = str(s.get("kind", "Landmark")).to_upper()
	_name.text = str(s.get("name", ""))
	_desc.text = str(s.get("description", ""))
	_desc.visible = _desc.text != "" and _desc.text != "Landmark"
	_distance.visible = distance_m >= 0.0
	if distance_m >= 0.0:
		_distance.set_value(ViewCallouts.distance_text(distance_m))
	var h := float(s.get("height_m", 0.0))
	_height.visible = h > 0.0
	if h > 0.0:
		_height.set_value(UiTheme.elevation(h))
	_coords.set_value(UiTheme.coords(float(s.get("lat", 0.0)), float(s.get("lon", 0.0))))
	_coords.visible = _header.visible  # the map names the point already
	_photo_box.visible = false
	_credit.visible = false
	_photo.texture = null
	_set_article(false)
	_status.text = LOADING
	_status.visible = true
	if _fetcher != null:
		_fetcher.describe(s)

func set_distance(distance_m: float) -> void:
	_distance.visible = distance_m >= 0.0
	if distance_m >= 0.0:
		_distance.set_value(ViewCallouts.distance_text(distance_m))

func status_text() -> String:
	return _status.text if _status.visible else ""

func _set_article(on: bool) -> void:
	_extract.visible = on
	_more.visible = on and _url != ""
	_attribution.visible = on

func _on_info(id: String, info: Dictionary) -> void:
	if id != str(site.get("id", "")):
		return
	_status.visible = false
	if _desc.text == "" or not _desc.visible:
		_desc.text = str(info.get("description", ""))
		_desc.visible = _desc.text != ""
	_extract.text = short_extract(str(info.get("extract", "")))
	_url = str(info.get("url", ""))
	_set_article(true)

func _on_failed(id: String, reason: String) -> void:
	if id != str(site.get("id", "")):
		return
	_url = ""
	_set_article(false)
	_status.text = reason
	_status.visible = true

func _on_photo(id: String, tex: Texture2D, credit: String) -> void:
	if id != str(site.get("id", "")):
		return
	_photo.texture = tex
	_photo_box.visible = true
	_credit.text = "Photo: " + credit if credit != "" else "Photo: Wikimedia Commons"
	_credit.visible = true

## The article's opening, cut at a sentence end before EXTRACT_CHARS.
static func short_extract(text: String) -> String:
	var t := text.strip_edges()
	if t.length() <= EXTRACT_CHARS:
		return t
	var cut := t.substr(0, EXTRACT_CHARS)
	var end := cut.rfind(". ")
	if end > EXTRACT_CHARS / 3:
		return cut.substr(0, end + 1)
	return cut.substr(0, cut.rfind(" ")).strip_edges() + "…"
