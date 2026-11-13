class_name InnerImagery
extends Node

## The sharper inner ground mosaic round the viewpoint, over the main
## satellite mosaic (GroundMaterial.inner_map, ground_shader photo_inner):
##  - in a detail city on High / Ultra (CityDetail.inner_imagery) the
##    city orthophoto (OrthoSource, OrthoFetcher), up to z19;
##  - else, or when that fails, desktop Ultra's Esri z18 mosaic
##    (RenderSettings.SATELLITE_INNER_*), as before;
##  - else none.
## `land` hands the result to LocationData with a colour match against
## the main mosaic, so the photo blends in at its edge.

var done := true
var texture: Texture2D
var origin := Vector2.ZERO
## {src, zoom, span, metres_per_px}; {} when none.
var source: Dictionary = {}

var _esri: SatelliteFetcher
var _ortho: OrthoFetcher
var _lat := 0.0
var _lon := 0.0
var _esri_fallback := false
var _thumb: Image

func _ready() -> void:
	_esri = SatelliteFetcher.new()
	add_child(_esri)
	_esri.succeeded.connect(func(tex: Texture2D, _img: Image, o: Vector2, zoom: int) -> void:
		# A lower-zoom fallback adds nothing over the main mosaic.
		if zoom == RenderSettings.SATELLITE_INNER_ZOOM:
			_take(tex, o, {"src": "esri", "zoom": zoom, "span": RenderSettings.SATELLITE_INNER_SPAN},
				null)
		done = true)
	_esri.failed.connect(func(_reason: String) -> void:
		done = true)
	_ortho = OrthoFetcher.new()
	add_child(_ortho)
	_ortho.succeeded.connect(func(tex: Texture2D, _img: Image, o: Vector2, _zoom: int) -> void:
		_take(tex, o, _ortho.source, _ortho.thumbnail)
		done = true)
	_ortho.failed.connect(func(reason: String) -> void:
		print("%s; inner imagery falls back" % reason)
		_start_esri())

func set_textures(on: bool) -> void:
	_esri.textures = on
	_ortho.textures = on

## Test hook (screenshot runs): cached orthophoto parts only.
func set_offline(on: bool) -> void:
	_ortho.offline = on

func fetch(lat: float, lon: float, preset: int) -> void:
	_ortho.cancel()
	_lat = lat
	_lon = lon
	texture = null
	origin = Vector2.ZERO
	source = {}
	_thumb = null
	_esri_fallback = RenderQuality.ultra_desktop(preset)
	var want := CityDetail.inner_imagery(preset, lat, lon)
	var src := OrthoSource.source_for(lat, lon, want.x, want.y) if want != Vector2i.ZERO else ""
	if src != "":
		done = false
		_ortho.fetch(src, lat, lon, want.x, want.y)
		return
	_start_esri()

func _start_esri() -> void:
	done = not _esri_fallback
	if not done:
		_esri.fetch(_lat, _lon, RenderSettings.SATELLITE_INNER_ZOOM, RenderSettings.SATELLITE_INNER_SPAN)

func _take(tex: Texture2D, o: Vector2, src: Dictionary, thumb: Image) -> void:
	texture = tex
	origin = o
	source = src.duplicate()
	_thumb = thumb

## Lands the inner mosaic on `data` (after its main mosaic): texture,
## origin and source, with a colour match for a non-Esri photo.
func land(data: LocationData) -> void:
	data.satellite_inner_texture = texture
	data.satellite_inner_origin_px = origin
	data.satellite_inner_source = source.duplicate()
	if texture == null or _thumb == null or data.satellite_image == null:
		return
	var ref := main_crop(data, origin, int(source["zoom"]), int(source["span"]))
	if ref == null:
		return
	var m := OrthoSource.colour_match(_thumb, ref)
	data.satellite_inner_source["gain"] = m["gain"]
	data.satellite_inner_source["bias"] = m["bias"]

## The main mosaic over the inner mosaic's ground, THUMB_PX a side; null
## when it does not lie inside the main one.
static func main_crop(data: LocationData, inner_origin: Vector2, zoom: int, span: int) -> Image:
	var main_zoom := int(data.satellite_source.get("source_zoom", data.satellite_zoom))
	var k := pow(2.0, float(zoom - main_zoom))
	var size := float(span * SatelliteFetcher.TILE_PX) / k
	var at := inner_origin / k - data.satellite_origin_px
	var img := data.satellite_image
	var rect := Rect2i(Vector2i(at.floor()), Vector2i(ceili(size), ceili(size)))
	if rect.position.x < 0 or rect.position.y < 0 or rect.end.x > img.get_width() or rect.end.y > img.get_height() \
			or rect.size.x < 4:
		return null
	var crop := img.get_region(rect)
	crop.resize(OrthoFetcher.THUMB_PX, OrthoFetcher.THUMB_PX, Image.INTERPOLATE_BILINEAR)
	return crop
