extends SceneTree

## Landmark markers, details and visits: godot --headless --script tests/landmark_info_test.gd
## Offline: parsers run on fixtures trimmed from live answers (2026-11-01),
## the fetcher answers from a seeded temp cache only.

const NEARBY := """{"batchcomplete":true,"query":{"pages":[
{"pageid":1,"title":"Gornergrat Railway","length":11820,"description":"Mountain rack railway, located in the Swiss canton of Valais","coordinates":[{"lat":46.0236,"lon":7.7497}]},
{"pageid":2,"title":"Matterhorn","length":111349,"description":"Mountain in the Swiss and Italian Alps","coordinates":[{"lat":45.9764,"lon":7.6586}]},
{"pageid":3,"title":"Zermatt railway station","length":6408,"description":"Railway station in Zermatt, Switzerland","coordinates":[{"lat":46.0244,"lon":7.7475}]},
{"pageid":4,"title":"Weisshorn","length":20442,"description":"Mountain in the Pennine Alps","coordinates":[{"lat":46.1017,"lon":7.7161}]},
{"pageid":5,"title":"Hörnli Hut","length":5013,"description":"Mountain hut on the Matterhorn","coordinates":[{"lat":45.9822,"lon":7.6847}]},
{"pageid":6,"title":"Alpine Research Station","length":9000,"description":"Research institute in Zermatt","coordinates":[{"lat":46.02,"lon":7.75}]},
{"pageid":7,"title":"Matterhorn Museum","length":2925,"description":"Museum in Zermatt","coordinates":[{"lat":46.0197,"lon":7.7461}]},
{"pageid":8,"title":"No coordinates","length":99999,"description":"Mountain in nowhere"}]}}"""

const SUMMARY := """{"type":"standard","title":"Matterhorn","description":"Mountain in the Swiss and Italian Alps",
"extract":"The Matterhorn is a mountain of the Alps, straddling the main watershed and border between Switzerland and Italy.",
"originalimage":{"source":"https://upload.wikimedia.org/wikipedia/commons/6/60/Matterhorn_from_Domh%C3%BCtte_-_2.jpg?utm_source=en.wikipedia.org","width":1610,"height":1073},
"content_urls":{"desktop":{"page":"https://en.wikipedia.org/wiki/Matterhorn"}}}"""

const IMAGEINFO := """{"query":{"pages":[{"title":"File:Matterhorn from Domhütte - 2.jpg","imageinfo":[{
"thumburl":"https://thumb.wikimedia.org/wikipedia/commons/thumb/6/60/Matterhorn_from_Domh%C3%BCtte_-_2.jpg/960px-Matterhorn_from_Domh%C3%BCtte_-_2.jpg",
"extmetadata":{"Artist":{"value":"<ul><li>Photo: chil, on Camptocamp.org</li>\\n<li>Derivative work:<a href=\\"//commons.wikimedia.org/wiki/User:Z\\">Zacharie Grossen</a></li></ul>"},
"LicenseShortName":{"value":"CC BY-SA 3.0"}}}]}]}}"""

const CACHE := "user://landmark_info_test_cache"

var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

func _run() -> void:
	_parsers()
	_visit_math()
	_view_aim()
	await _map_markers()
	await _card_states()
	_osm_tag()
	await _callout_icon_tap()
	DirAccess.remove_absolute(CACHE)
	if failures.is_empty():
		print("LANDMARK INFO OK: parsers, standoff, aim, map markers, card states, OSM tag")
		quit(0)
	else:
		for f in failures:
			printerr("LANDMARK INFO FAIL: ", f)
		quit(1)

func _parsers() -> void:
	var sites := WikiParse.parse_nearby(NEARBY)
	var names := sites.map(func(s: Dictionary) -> String: return str(s["name"]))
	_check(names == ["Matterhorn", "Weisshorn", "Matterhorn Museum"],
		"nearby keeps places, longest first, drops stations/huts/railways/research: %s" % [names])
	if not sites.is_empty():
		_check(sites[0]["kind"] == "Peak" and sites[0]["icon"] == "mountain", "Matterhorn is a peak")
		_check(sites[0]["wiki_title"] == "Matterhorn" and sites[0]["wiki_lang"] == "en", "nearby site carries its article")
	_check(WikiParse.is_place("Tower in Paris, France"), "a tower is a place")
	_check(not WikiParse.is_place("Research institute"), "\"research\" is not \"arch\"")
	_check(WikiParse.parse_nearby("{\"query\":{}}").is_empty(), "empty payload -> no sites")

	var info := WikiParse.parse_summary(SUMMARY)
	_check(info.get("title") == "Matterhorn" and str(info.get("extract", "")).begins_with("The Matterhorn"), "summary parses")
	_check(info.get("url") == "https://en.wikipedia.org/wiki/Matterhorn", "summary page url")
	_check(WikiParse.parse_summary('{"type":"disambiguation","extract":"x"}').is_empty(), "disambiguation -> no article")

	var img := str(info.get("image", ""))
	_check(WikiParse.image_file(img) == "Matterhorn_from_Domhütte_-_2.jpg", "commons file from original: " + WikiParse.image_file(img))
	_check(WikiParse.image_file("https://thumb.wikimedia.org/wikipedia/commons/thumb/6/60/A_b.jpg/330px-A_b.jpg?x=1") == "A_b.jpg",
		"commons file from thumbnail")
	_check(WikiParse.image_file("https://upload.wikimedia.org/wikipedia/en/b/ba/Eiffel_Tower_logo.svg") == "",
		"non-Commons image is not used")
	var photo := WikiParse.parse_imageinfo(IMAGEINFO)
	var credit := str(photo.get("credit", ""))
	_check(str(photo.get("url", "")).contains("960px-"), "photo uses the returned thumburl")
	_check(credit.ends_with("CC BY-SA 3.0") and credit.begins_with("Photo: chil") and not credit.contains("<"),
		"photo credit is plain text: " + credit)

	_check(WikiParse.summary_url("en", "Sagrada Família") == "https://en.wikipedia.org/api/rest_v1/page/summary/Sagrada_Fam%C3%ADlia",
		"summary url encodes: " + WikiParse.summary_url("en", "Sagrada Família"))
	_check(WikiParse.summary_url("fr", "Notre-Dame de Paris").ends_with("/summary/Notre-Dame_de_Paris"), "summary url spaces")
	_check(WikiParse.nearby_url(46.0207, 7.7491, 20000).contains("ggsradius=10000"), "radius capped at 10 km")
	_check(WikiParse.split_tag("fi:Turun tuomiokirkko") == ["fi", "Turun tuomiokirkko"], "OSM wikipedia tag splits")
	_check(WikiParse.match_name("Turun Tuomiokirkko", [{"name": "Turun tuomiokirkko"}]).size() == 1, "name match ignores case")
	_check(WikiParse.match_name("Tower", [{"name": "Eiffel Tower"}]).is_empty(), "a bare word is not a match")
	_check(WikiParse.match_name("The Turku Cathedral", [{"name": "Turku Cathedral"}]).size() == 1, "near-full containment matches")

func _visit_math() -> void:
	var eiffel := LandmarkVisit.from_registry(LocationData.landmarks()[2])
	_check(eiffel["name"] == "Eiffel Tower" and eiffel["wiki_title"] == "Eiffel Tower", "registry -> site")
	_check(is_equal_approx(LandmarkVisit.standoff_m(eiffel), LandmarkVisit.MAX_M), "a 330 m tower is seen from the max standoff")
	_check(is_equal_approx(LandmarkVisit.standoff_m({"kind": "Peak"}), LandmarkVisit.PEAK_M), "peak standoff")
	_check(is_equal_approx(LandmarkVisit.standoff_m({"kind": "Building"}), LandmarkVisit.DEFAULT_M), "unknown height standoff")
	var vp := LandmarkVisit.viewpoint(eiffel, LandmarkVisit.default_bearing(48.8584))
	var d := LocationData.distance_m(float(eiffel["lat"]), float(eiffel["lon"]), vp.x, vp.y)
	_check(absf(d - LandmarkVisit.MAX_M) < LandmarkVisit.MAX_M * 0.02, "viewpoint at the standoff: %.1f m" % d)
	_check(vp.y < float(eiffel["lon"]) and vp.x < float(eiffel["lat"]), "north of the equator the viewer stands WSW")
	var off := WorldScale.xz_from_latlon(vp.x, vp.y, float(eiffel["lat"]), float(eiffel["lon"]))
	_check(absf(LandmarkVisit.bearing_of(off) - 250.0) < 1.0, "bearing of the viewpoint: %.1f" % LandmarkVisit.bearing_of(off))

func _view_aim() -> void:
	var data := LocationData.new()
	data.latitude = 48.8558
	data.longitude = 2.2860
	data.landmark_type = "eiffel"
	data.has_landmark_site = true
	data.landmark_lat = 48.8584
	data.landmark_lon = 2.2945
	data.focus = LandmarkVisit.from_registry(LocationData.landmarks()[2])
	data.heights.resize(data.grid_size * data.grid_size)
	_check(View360.spawn_xz(data) == Vector2.ZERO, "a landmark visit spawns at its standoff, no extra back-off")
	var north := View360.aim(Vector3.ZERO, Vector3(0, 0, -100))
	_check(absf(north.x) < 0.001 and absf(north.y) < 0.001, "aim north is yaw 0, level")
	var east := View360.aim(Vector3.ZERO, Vector3(100, 100, 0))
	_check(absf(east.x + PI / 2.0) < 0.001, "aim east is yaw -90°")
	_check(is_equal_approx(east.y, 0.6), "aim up is clamped gentle")
	var ground := GroundTruth.new(data)
	_check(View360.can_move_in_place(Vector2(300, 0), ground), "300 m from centre moves in place")
	_check(not View360.can_move_in_place(Vector2(2000, 0), ground), "2 km from centre re-renders")
	_check(not View360.can_move_in_place(Vector2(100, 0), null), "no ground, no move")

func _map_markers() -> void:
	var map := MapTileView.new()
	map.size = Vector2(800, 600)
	root.add_child(map)
	map.zoom_level = 14
	map.centre_lat = 48.8584
	map.centre_lon = 2.2945
	await process_frame
	var hit := map.landmarks.hit_at(map._focus() + Vector2(6, -4))
	_check(str(hit.get("name", "")) == "Eiffel Tower", "a tap on the marker hits the Eiffel Tower")
	_check(map.landmarks.hit_at(map._focus() + Vector2(120, 0)).is_empty(), "a tap beside it misses")
	var got := {"landmark": {}, "picked": false}
	map.landmark_picked.connect(func(s: Dictionary) -> void: got["landmark"] = s)
	map.picked.connect(func(_a: float, _b: float) -> void: got["picked"] = true)
	map._tap(map._focus())
	_check(not (got["landmark"] as Dictionary).is_empty() and not got["picked"], "marker tap selects the landmark, not a point")
	map.landmarks.set_sites(WikiParse.parse_nearby(NEARBY))
	map.zoom_level = 10
	_check(map.landmarks.sites().size() == LocationData.landmarks().size(), "articles wait for zoom 11")
	map.zoom_level = 5
	_check(map.landmarks.sites().is_empty(), "no markers at world zoom")
	_check(MapLandmarkHome.search_radius_m(48.85, 14, Vector2(800, 600)) == 4000, "search radius follows the view (3.1 km corner)")
	_check(MapLandmarkHome.search_radius_m(48.85, 11, Vector2(2400, 1600)) == 10000, "search radius capped")
	map.queue_free()
	await process_frame

func _card_states() -> void:
	CacheStore.dir_override = CACHE
	DirAccess.make_dir_recursive_absolute(CACHE)
	var f := FileAccess.open(CacheStore.wiki_summary_path("en", "Matterhorn"), FileAccess.WRITE)
	f.store_string(SUMMARY)
	f.close()
	var wiki := WikiFetcher.new()
	wiki.offline_mode = true
	root.add_child(wiki)
	var card := LandmarkCard.new(wiki)
	card.size = Vector2(360, 0)
	root.add_child(card)
	var peak := LandmarkVisit.site("Matterhorn", 45.9764, 7.6586, "Mountain in the Swiss and Italian Alps")
	peak["wiki_lang"] = "en"
	peak["wiki_title"] = "Matterhorn"
	card.show_site(peak, 8200.0)
	_check(card.status_text() == LandmarkCard.LOADING or card.status_text() == "", "loading line first")
	for i in 4:
		await process_frame
	_check(card.status_text() == "", "cached article fills the card: " + card.status_text())
	_check(card._extract.text.begins_with("The Matterhorn") and card._attribution.visible, "extract with its licence line")
	_check(card._distance.value_text() == "8.2 km", "distance readout: " + card._distance.value_text())
	card.show_site(LandmarkVisit.site("Old mill", 46.0, 7.7, "", "osm"))
	await process_frame
	_check(card.status_text() == WikiFetcher.NO_ARTICLE and not card._attribution.visible,
		"no article: plain line, no licence: " + card.status_text())
	var uncached := LandmarkVisit.site("Weisshorn", 46.1017, 7.7161, "Mountain")
	uncached["wiki_title"] = "Weisshorn"
	card.show_site(uncached)
	for i in 3:
		await process_frame
	_check(card.status_text() == WikiFetcher.OFFLINE, "offline, uncached: " + card.status_text())
	for t in [LandmarkCard.LOADING, WikiFetcher.NO_ARTICLE, WikiFetcher.OFFLINE, WikiFetcher.UNREACHABLE]:
		_check(not t.contains("!") and not t.to_lower().contains("error"), "calm copy: " + t)
	card.queue_free()
	wiki.queue_free()
	await process_frame
	for name in DirAccess.get_files_at(CACHE):
		DirAccess.remove_absolute(CACHE.path_join(name))
	CacheStore.dir_override = ""

func _osm_tag() -> void:
	var text := """{"elements":[{"type":"node","id":1,"lat":60.4524,"lon":22.2781,
		"tags":{"man_made":"tower","name":"Tower","wikipedia":"fi:Torni"}}]}"""
	var parsed := OsmParser.parse_features(text, 60.4524, 22.2781)
	var lm: Array = parsed.get("landmarks", [])
	_check(lm.size() == 1 and str(lm[0].get("wikipedia", "")) == "fi:Torni", "OSM landmark keeps its wikipedia tag")

## The callout's icon tile must not swallow a tap meant for the card.
func _callout_icon_tap() -> void:
	var view := Control.new()
	var callouts := ViewCallouts.new(null)
	root.add_child(view)
	view.add_child(callouts)
	var site := LandmarkVisit.site("Eiffel Tower", 48.8584, 2.2945, "Tower", "curated")
	var card := callouts._make_card(site, 700.0)
	card.position = Vector2(20, 20)
	await process_frame
	await process_frame
	var tapped := []
	callouts.site_tapped.connect(func(s: Dictionary) -> void: tapped.append(s))
	var tile := card.get_child(0).get_child(0) as Control
	_check(tile.mouse_filter == Control.MOUSE_FILTER_IGNORE, "icon tile ignores the mouse so the card gets the tap")
	var at := tile.get_global_rect().get_center()
	_check(callouts.get_viewport().gui_get_hovered_control() != tile, "icon tile is never the hovered control")
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = at - card.get_global_rect().position
		card.gui_input.emit(e)
	_check(tapped.size() == 1, "tapping the icon opens the landmark")
	# Anywhere on the card, including its padding and the text.
	for pt in [Vector2(3, 3), card.size - Vector2(3, 3), card.size / 2.0 + Vector2(40, 0)]:
		for pressed in [true, false]:
			var e2 := InputEventMouseButton.new()
			e2.button_index = MOUSE_BUTTON_LEFT
			e2.pressed = pressed
			e2.position = pt
			card.gui_input.emit(e2)
	_check(tapped.size() == 4, "tapping the padding and the text opens it too: %d" % tapped.size())
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	card.gui_input.emit(key)
	_check(tapped.size() == 5 and card.focus_mode == Control.FOCUS_ALL, "Enter on the focused card opens it")
	_check(str(card.accessibility_name).contains("Show details"), "card is named for screen readers")
	view.queue_free()
	await process_frame
