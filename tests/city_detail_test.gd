extends SceneTree

## CityDetail (offline): godot --headless --script tests/city_detail_test.gd
## Which places are detail cities, and that Fast / Balanced keep the
## shared budgets while High / Ultra raise them.

var failures: Array[String] = []

const IN := {
	"kallio": [60.1850, 24.9500, "helsinki"], "toolo": [60.1800, 24.9200, "helsinki"],
	"vuosaari": [60.2090, 25.1440, "helsinki"], "keilaniemi": [60.1755, 24.8310, "espoo"],
	"tapiola": [60.1760, 24.8050, "espoo"],
}
const OUT := {"turku": [60.4518, 22.2666], "tallinn": [59.4370, 24.7536], "paris": [48.8566, 2.3522]}

func _init() -> void:
	for k in IN:
		var r: Array = IN[k]
		_check(CityDetail.city_at(r[0], r[1]) == r[2], "%s must be %s" % [k, r[2]])
	for k in OUT:
		var r: Array = OUT[k]
		_check(CityDetail.city_at(r[0], r[1]) == "", "%s is no detail city" % k)
	var P := RenderSettings.Preset
	for preset in [P.FAST, P.BALANCED]:
		var d := _data(preset, 60.1850, 24.9500)
		_check(not CityDetail.for_data(d), "Fast / Balanced are never boosted")
		_check(CityDetail.max_buildings(d, true) == RenderSettings.max_buildings_for(preset, true),
			"Fast / Balanced keep the building cap")
		_check(CityDetail.terrain_mesh_posts(d) == RenderSettings.terrain_mesh_posts_for(preset),
			"Fast / Balanced keep the terrain mesh")
		_check(CityDetail.near_radius(d, 250.0) == 250.0, "Fast / Balanced keep the roofline ring")
		_check(CityDetail.inner_imagery(preset, 60.1850, 24.9500, true) == Vector2i.ZERO,
			"Fast / Balanced fetch no inner orthophoto")
		_check(not CityDetail.street_extras(d, true), "Fast / Balanced get no street extras")
		_check(not CityDetail.extra_trees(d), "Fast / Balanced plant no register-only trees")
	var high := _data(P.HIGH, 60.1850, 24.9500)
	_check(CityDetail.max_buildings(high, true) > RenderSettings.max_buildings_for(P.HIGH, true),
		"High raises the building cap in Helsinki")
	_check(CityDetail.terrain_mesh_posts(high) == RenderSettings.GROUND_POSTS, "High meshes every ground post")
	_check(CityDetail.street_extras(high, true) and not CityDetail.street_extras(high, false),
		"High desktop gets street extras, phones do not")
	var ultra := _data(P.ULTRA, 60.1755, 24.8310)
	_check(CityDetail.max_buildings(ultra, true) > RenderSettings.max_buildings_for(P.ULTRA, true),
		"Ultra raises the building cap in Espoo")
	_check(CityDetail.near_radius(ultra, 700.0) > 700.0, "Ultra widens the roofline ring")
	var inner := CityDetail.inner_imagery(P.ULTRA, 60.1755, 24.8310, true)
	_check(inner.x == 19 and inner.y <= RenderSettings.SATELLITE_MAX_SPAN, "Ultra desktop: z19 inner orthophoto")
	_check(CityDetail.inner_imagery(P.ULTRA, 48.8566, 2.3522, true) == Vector2i.ZERO, "Paris: no orthophoto")
	var paris := _data(P.ULTRA, 48.8566, 2.3522)
	_check(CityDetail.max_buildings(paris, true) == RenderSettings.max_buildings_for(P.ULTRA, true),
		"Other cities keep the shared cap")
	if failures.is_empty():
		print("CITY DETAIL OK: cities, Fast/Balanced unchanged, High/Ultra raised")
		quit(0)
	else:
		for f in failures:
			printerr("CITY DETAIL FAIL: ", f)
		quit(1)

func _data(preset: int, lat: float, lon: float) -> LocationData:
	var d := LocationData.new()
	d.quality_preset = preset
	d.latitude = lat
	d.longitude = lon
	return d

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)
