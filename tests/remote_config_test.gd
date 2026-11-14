extends SceneTree

## Headless: godot --headless --script tests/remote_config_test.gd
## The service-address overrides: strict validation, built-in defaults when
## a key is missing or invalid, a fetched file replacing earlier overrides,
## and the cached copy that is applied at launch. No network.

var _failures: Array[String] = []

func _init() -> void:
	var cache := "user://remote-config-test-%d.json" % OS.get_process_id()
	RemoteConfig.cache_path_override = cache
	RemoteConfig.clear()
	_test_defaults()
	_test_validation()
	_test_replace_and_clear()
	_test_cache(cache)
	RemoteConfig.clear()
	RemoteConfig.cache_path_override = ""
	DirAccess.remove_absolute(ProjectSettings.globalize_path(cache))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(cache))
	if _failures.is_empty():
		print("REMOTE CONFIG OK: defaults, validation, replace/clear, cache")
		quit(0)
	else:
		for f in _failures:
			printerr("REMOTE CONFIG FAIL: ", f)
		quit(1)

func _test_defaults() -> void:
	if OsmFetcher.active_endpoints() != OsmFetcher.ENDPOINTS:
		_failures.append("with no config the Overpass instances should be the built-in list")
	if SatelliteFetcher.url_template() != SatelliteFetcher.URL_TEMPLATE:
		_failures.append("with no config the imagery address should be the built-in one")
	if not SearchFetcher.build_url("a b").begins_with(SearchFetcher.ENDPOINT + "?"):
		_failures.append("with no config search should use the built-in Nominatim address")

func _test_validation() -> void:
	if RemoteConfig.apply("not a dictionary") or RemoteConfig.apply(null) \
			or RemoteConfig.apply({"nominatim_endpoint": "https://x.test/search"}):
		_failures.append("a file that is not a current-schema object should be refused")
	if RemoteConfig.apply({"version": 99}):
		_failures.append("another schema version should be refused")
	for version in [[1], "1", {"v": 1}, null, true]:
		if RemoteConfig.apply({"version": version}):
			_failures.append("a version that is not the number %d should be refused: %s" % [RemoteConfig.SCHEMA, str(version)])
	var good := {
		"version": RemoteConfig.SCHEMA,
		"nominatim_endpoint": "https://geocode.example/search",
		"overpass_endpoints": ["https://a.example/api/interpreter", "https://b.example/api/interpreter"],
		"satellite_url_template": "https://tiles.example/{x}/%d/%d/%d",
		"unknown_key": "ignored",
	}
	var clean: Variant = RemoteConfig.sanitize(good)
	if clean == null or (clean as Dictionary).size() != 3 or (clean as Dictionary).has("unknown_key"):
		_failures.append("a good file should keep exactly its three known keys, got %s" % str(clean))
	# Each bad value is dropped on its own; the good ones next to it stay.
	var bad := {
		"version": RemoteConfig.SCHEMA,
		"nominatim_endpoint": "http://insecure.example/search",
		"overpass_endpoints": ["https://a.example/api", "ftp://b.example/api"],
		"satellite_url_template": "https://tiles.example/%d/%d",
	}
	var kept: Variant = RemoteConfig.sanitize(bad)
	if kept == null or not (kept as Dictionary).is_empty():
		_failures.append("http, mixed-scheme and wrong-placeholder values should all be dropped, got %s" % str(kept))
	for url in ["https://", "https:///path", "https://has space.example/", "https://a.example/\n",
			"https://" + "a".repeat(RemoteConfig.MAX_URL_LENGTH), 42, null, ["x"]]:
		if RemoteConfig.is_https_url(url):
			_failures.append("should not be accepted as an https URL: %s" % str(url))
	for url in ["https://overpass.example.ru/api/interpreter", "https://x.su/", "https://yandex.com/maps",
			"https://tiles.yandex.net/%d/%d/%d", "https://vk.com/", "https://geocode.example.xn--p1ai/"]:
		if RemoteConfig.is_https_url(url):
			_failures.append("a Russian host must never be accepted: %s" % url)
	var russian := {"version": RemoteConfig.SCHEMA,
		"nominatim_endpoint": "https://geocode.example.ru/search",
		"overpass_endpoints": ["https://a.example/api", "https://mirror.example.ru/api"],
		"satellite_url_template": "https://tiles.example.su/%d/%d/%d"}
	var refused: Variant = RemoteConfig.sanitize(russian)
	if refused == null or not (refused as Dictionary).is_empty():
		_failures.append("a file naming Russian hosts should keep none of them, got %s" % str(refused))
	if not RemoteConfig.is_https_url("https://tile.example/a/b?x=1%20y"):
		_failures.append("an ordinary https URL should be accepted")
	for template in ["https://t.example/%d/%d/%d", "https://t.example/{z}/%d/%d/%d.jpg"]:
		if not RemoteConfig.is_tile_template(template):
			_failures.append("tile template should be accepted: %s" % template)
	for template in ["https://t.example/%d/%d", "https://t.example/%d/%d/%d/%d",
			"https://t.example/%s/%d/%d", "https://t.example/%d/%d/%d%"]:
		if RemoteConfig.is_tile_template(template):
			_failures.append("tile template should be refused: %s" % template)
	var too_many: Array = []
	for i in RemoteConfig.MAX_OVERPASS_ENDPOINTS + 1:
		too_many.append("https://m%d.example/api" % i)
	var capped: Variant = RemoteConfig.sanitize({"version": RemoteConfig.SCHEMA, "overpass_endpoints": too_many})
	if capped == null or (capped as Dictionary).has("overpass_endpoints"):
		_failures.append("an oversized instance list should be dropped")
	var repeated: Variant = RemoteConfig.sanitize({"version": RemoteConfig.SCHEMA,
		"overpass_endpoints": ["https://a.example/api", "https://a.example/api"]})
	if repeated == null or (repeated as Dictionary).has("overpass_endpoints"):
		_failures.append("a repeated mirror should void the endpoint list")
	var empty_list: Variant = RemoteConfig.sanitize({"version": RemoteConfig.SCHEMA, "overpass_endpoints": []})
	if empty_list == null or (empty_list as Dictionary).has("overpass_endpoints"):
		_failures.append("an empty instance list must not leave the app with no Overpass instance")

func _test_replace_and_clear() -> void:
	var good := {
		"version": RemoteConfig.SCHEMA,
		"nominatim_endpoint": "https://geocode.example/search",
		"overpass_endpoints": ["https://a.example/api/interpreter", "https://b.example/api/interpreter"],
		"satellite_url_template": "https://tiles.example/%d/%d/%d",
	}
	if not RemoteConfig.apply(good):
		_failures.append("a good file should apply")
	if OsmFetcher.active_endpoints() != ["https://a.example/api/interpreter", "https://b.example/api/interpreter"]:
		_failures.append("Overpass instances should come from the file")
	if OsmFetcher.endpoint_order(["b.example"])[0] != "https://b.example/api/interpreter":
		_failures.append("endpoint_order should work on the file's instances")
	if SatelliteFetcher.url_template() % [16, 5, 6] != "https://tiles.example/16/5/6":
		_failures.append("imagery address should come from the file")
	if not SearchFetcher.build_url("a b").begins_with("https://geocode.example/search?"):
		_failures.append("search should use the file's Nominatim address")
	# A refused file changes nothing.
	if RemoteConfig.apply("garbage") or OsmFetcher.active_endpoints().size() != 2:
		_failures.append("a refused file should leave the earlier overrides in force")
	# An empty current-schema file clears them all.
	if not RemoteConfig.apply({"version": RemoteConfig.SCHEMA}):
		_failures.append("an empty current-schema file should apply")
	if OsmFetcher.active_endpoints() != OsmFetcher.ENDPOINTS \
			or SatelliteFetcher.url_template() != SatelliteFetcher.URL_TEMPLATE:
		_failures.append("an empty file should restore every built-in default")

func _test_cache(cache: String) -> void:
	RemoteConfig.clear()
	if RemoteConfig.load_cached():
		_failures.append("with no cached file nothing should load")
	var text := JSON.stringify({"version": RemoteConfig.SCHEMA,
		"nominatim_endpoint": "https://cached.example/search"})
	AtomicFile.write_text(cache, text)
	if not RemoteConfig.load_cached() \
			or not SearchFetcher.build_url("x").begins_with("https://cached.example/search?"):
		_failures.append("the cached file should apply at launch")
	RemoteConfig.clear()
	AtomicFile.write_text(cache, "{ broken")
	if RemoteConfig.load_cached():
		_failures.append("a damaged cached file should be ignored")
	if SearchFetcher.build_url("x").begins_with("https://cached.example"):
		_failures.append("a damaged cached file must not leave old overrides behind")
