extends SceneTree

## Headless: godot --headless --script tests/store_readiness_test.gd
## Guards what the store release depends on:
## - every host the code contacts is named in the privacy policy;
## - the licence texts that ship with the fonts and icons exist, reach the
##   About page, and are in every export preset's include list;
## - the published config.json changes nothing until someone edits it;
## - all three platform exports keep the same exclude list for bulky or
##   development-only folders that Android and iOS must not ship.

var _failures: Array[String] = []

func _init() -> void:
	_test_privacy_hosts()
	_test_licences()
	_test_published_config()
	_test_export_presets()
	if _failures.is_empty():
		print("STORE READINESS OK: privacy hosts, licences, published config, export presets")
		quit(0)
	else:
		for f in _failures:
			printerr("STORE READINESS FAIL: ", f)
		quit(1)

static func host_of(url: String) -> String:
	var rest := url.substr(url.find("://") + 3) if url.contains("://") else url
	for stop in ["/", "?", "%"]:
		var at := rest.find(stop)
		if at >= 0:
			rest = rest.substr(0, at)
	return rest

func _test_privacy_hosts() -> void:
	var page := FileAccess.get_file_as_string("res://site/privacy.html")
	if page.is_empty():
		_failures.append("site/privacy.html is missing")
		return
	var urls: Array[String] = []
	urls.append_array(OsmFetcher.ENDPOINTS)
	urls.append_array([SearchFetcher.ENDPOINT, SatelliteFetcher.URL_TEMPLATE,
		WeatherFetcher.URL_TEMPLATE, ClimateFetcher.BASE, ClimateFetcher.FALLBACK_URL,
		DemFetcher.URL_TEMPLATE, LandcoverSource.WORLDCOVER_BASE, LandcoverSource.CANOPY_BASE,
		OsmApiFallback.URL, "https://" + VectorTileFetcher.VECTOR_HOST,
		"https://" + TileConnection.HOST, Brand.CONFIG_URL,
		"https://en.wikipedia.org/", "https://commons.wikimedia.org/"])
	for url in urls:
		var host := host_of(url)
		# Wikipedia is requested per language edition; the page names the domain.
		if host.ends_with(".wikipedia.org"):
			host = "wikipedia.org"
		if not page.contains(host):
			_failures.append("privacy policy does not name %s, which the app contacts" % host)

func _test_licences() -> void:
	for file in SettingsPages.LICENCE_FILES:
		var path: String = SettingsPages.LICENCE_DIR + file
		if FileAccess.get_file_as_string(path).length() < 1000:
			_failures.append("licence text missing or truncated: %s" % path)
	var shown := SettingsPages._font_licence_text()
	for needle in ["Instrument Sans Project Authors", "IBM Corp.", "SIL OPEN FONT LICENSE Version 1.1",
			"ISC License", "Lucide"]:
		if not shown.contains(needle):
			_failures.append("About page licence text lacks \"%s\"" % needle)
	if not FileAccess.file_exists("res://NOTICE.md"):
		_failures.append("NOTICE.md is missing")

func _test_published_config() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://site/config.json"))
	var clean: Variant = RemoteConfig.sanitize(parsed)
	if clean == null:
		_failures.append("site/config.json is not a valid current-schema config")
	elif not (clean as Dictionary).is_empty():
		_failures.append("site/config.json overrides %s; the default file must change nothing" % str((clean as Dictionary).keys()))

func _test_export_presets() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("res://export_presets.cfg") != OK:
		_failures.append("export_presets.cfg did not load")
		return
	var must_exclude := ["generated_images/*", "visual-plan/*", "assets_src/*", "docs/*", "tests/*", "tools/*"]
	for section in cfg.get_sections():
		if section.ends_with(".options"):
			continue
		var preset_name := str(cfg.get_value(section, "name", section))
		if not str(cfg.get_value(section, "include_filter", "")).contains("licenses/*.txt"):
			_failures.append("%s export does not include licenses/*.txt" % preset_name)
		var excluded := str(cfg.get_value(section, "exclude_filter", ""))
		for pattern in must_exclude:
			if not excluded.contains(pattern):
				_failures.append("%s export does not exclude %s" % [preset_name, pattern])
		if preset_name in ["Android", "iOS"] and not excluded.contains("assets/textures/2k/*"):
			_failures.append("%s export should leave out the 2K desktop textures" % preset_name)
