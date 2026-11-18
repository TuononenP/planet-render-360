extends SceneTree

## HsyCover (offline): godot --headless --script tests/hsy_cover_test.gd
## Band composition and its priority, URLs, the overlay rule, and the
## class map: HSY decides unmapped and landuse-paving ground, and loses
## to mapped parks, roads and footprints; without HSY nothing changes.

const N := 64
var failures: Array[String] = []

func _init() -> void:
	_compose()
	_class_map()
	if failures.is_empty():
		print("HSY COVER OK: compose, overlay, class map precedence")
		quit(0)
	else:
		for f in failures:
			printerr("HSY COVER FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)

func _id(name: String) -> int:
	return int(GroundMaterial.ID[name])

## A band with alpha set on `hits` (texel indices).
func _band(size: int, hits: Array) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for p in hits:
		img.set_pixel(int(p) % size, int(p) / size, Color(0.5, 0.5, 0.5, 1))
	return img

func _compose() -> void:
	var bands: Array = []
	for i in HsyCover.LAYERS.size():
		bands.append(_band(4, []))
	bands[1] = _band(4, [0, 1])      # avokalliot: rock
	bands[7] = _band(4, [1, 2])      # paallystetty_tie: urban, painted last
	bands[5] = _band(4, [3])         # low vegetation: grass
	var img := HsyCover.compose(bands, 4)
	_check(img != null and img.get_format() == Image.FORMAT_R8, "Bands compose to R8")
	if img == null:
		return
	var d := img.get_data()
	_check(d[0] == _id("rock") and d[1] == _id("urban") and d[2] == _id("urban") and d[3] == _id("grass") and d[4] == 0,
		"Ids and paint order (got %s)" % str(d.slice(0, 5)))
	_check(HsyCover.compose(bands.slice(0, 3), 4) == null, "A missing band composes to null")
	for i in HsyCover.LAYERS.size():
		var url := HsyCover.band_url(i, 60.168, 24.953, 1024)
		_check(not HostPolicy.is_blocked(url) and url.contains(HsyCover.layer_name(i)), "Band URLs name their layer")
	# Overlay: only listed base classes take HSY; an empty list takes all.
	var base := Image.create_from_data(2, 1, false, Image.FORMAT_R8, PackedByteArray([_id("urban"), _id("grass")]))
	var top := Image.create_from_data(2, 1, false, Image.FORMAT_R8, PackedByteArray([_id("rock"), _id("rock")]))
	var some := HsyCover.overlay(base, top, [_id("urban")]).get_data()
	_check(some[0] == _id("rock") and some[1] == _id("grass"), "Overlay replaces only the listed classes")
	var all := HsyCover.overlay(base, top, []).get_data()
	_check(all[0] == _id("rock") and all[1] == _id("rock"), "An empty list overlays everywhere")

## The class map with a residential block over the whole extent, a park
## on its west half, a road and a building, under HSY rock everywhere.
func _class_map() -> void:
	var half := WorldScale.detailed_extent_units() * 0.5
	var d := LocationData.new()
	d.quality_preset = RenderSettings.Preset.HIGH
	d.land_polygons = [
		{"class": "grass", "points": PackedVector2Array([Vector2(-half, -half), Vector2(0, -half),
			Vector2(0, half), Vector2(-half, half)]), "holes": []},
		{"class": "urban", "points": PackedVector2Array([Vector2(-half, -half), Vector2(half, -half),
			Vector2(half, half), Vector2(-half, half)]), "holes": []}]
	d.roads = [{"class": "residential", "width_m": 40.0,
		"points": PackedVector2Array([Vector2(half * 0.5, -half), Vector2(half * 0.5, half)])}]
	var plain := GroundMaterial.class_map(d, N)
	var rock := Image.create(N, N, false, Image.FORMAT_R8)
	rock.fill(Color(float(_id("rock")) / 255.0, 0, 0))
	d.hsy_cover_image = rock
	var with := GroundMaterial.class_map(d, N)
	var at := func(img: Image, fx: float, fz: float) -> int:
		return roundi(img.get_pixel(int(fx * N), int(fz * N)).r * 255.0)
	_check(at.call(plain, 0.6, 0.5) == _id("urban"), "Without HSY the block is paving")
	_check(at.call(with, 0.6, 0.5) == _id("rock"), "HSY rock replaces landuse paving")
	_check(at.call(with, 0.25, 0.5) == _id("grass"), "A mapped park keeps its class")
	_check(at.call(with, 0.75, 0.5) == at.call(plain, 0.75, 0.5) and at.call(plain, 0.75, 0.5) != _id("urban"),
		"A road paints over HSY")
	d.quality_preset = RenderSettings.Preset.BALANCED
	_check(GroundMaterial.class_map(d, N).get_data() == plain.get_data(), "Balanced ignores HSY: the map is unchanged")
	d.quality_preset = RenderSettings.Preset.HIGH
	d.hsy_cover_image = null
	_check(GroundMaterial.class_map(d, N).get_data() == plain.get_data(), "No HSY image: the map is unchanged")
