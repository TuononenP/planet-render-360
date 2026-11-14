extends SceneTree

## Headless: godot --headless --script tests/host_policy_test.gd
## No Russian-operated service or domain may be contacted. Checks the policy
## itself, then scans the project's own source for any such host, so a
## mirror or endpoint cannot come back unnoticed.

var _failures: Array[String] = []

func _init() -> void:
	_test_policy()
	_test_endpoints()
	_test_source()
	if _failures.is_empty():
		print("HOST POLICY OK: policy, built-in endpoints, project source")
		quit(0)
	else:
		for f in _failures:
			printerr("HOST POLICY FAIL: ", f)
		quit(1)

func _test_policy() -> void:
	for host in ["mail.ru", "maps.mail.ru", "https://maps.mail.ru/osm/tools/overpass/api/interpreter",
			"overpass.example.ru:8443/api", "HTTPS://Example.RU./x", "something.su", "пример.рф",
			"xn--e1afmkfd.xn--p1ai", "yandex.com", "tiles.yandex.net", "vk.com", "api.vk.com",
			"https://user:pw@tiles.example.ru/", "ru"]:
		if not HostPolicy.is_blocked(host):
			_failures.append("should be blocked: %s" % host)
	for host in ["overpass-api.de", "z.overpass-api.de", "overpass.private.coffee",
			"https://nominatim.openstreetmap.org/search", "tile.openstreetmap.org", "ru.wikipedia.org",
			"peru.example", "guru.example.com", "mailru.example", "convk.com", "notvk.com", "", "https://"]:
		# "mailru.example" and friends only look similar: none ends in a Russian domain.
		if HostPolicy.is_blocked(host):
			_failures.append("should not be blocked: %s" % host)
	if HostPolicy.host_of("https://User@Overpass.Example:8443/api?q=1#x") != "overpass.example":
		_failures.append("host_of should drop scheme, user, port, path and case")

func _test_endpoints() -> void:
	var urls: Array[String] = []
	urls.append_array(OsmFetcher.ENDPOINTS)
	urls.append_array([SearchFetcher.ENDPOINT, SatelliteFetcher.URL_TEMPLATE, WeatherFetcher.URL_TEMPLATE,
		ClimateFetcher.BASE, ClimateFetcher.FALLBACK_URL, DemFetcher.URL_TEMPLATE,
		LandcoverSource.WORLDCOVER_BASE, LandcoverSource.CANOPY_BASE, OsmApiFallback.URL, PostpassFallback.URL,
		"https://" + VectorTileFetcher.VECTOR_HOST, "https://" + TileConnection.HOST, Brand.CONFIG_URL])
	for url in urls:
		if HostPolicy.is_blocked(url):
			_failures.append("built-in endpoint is a blocked host: %s" % url)
	for list in [OsmFetcher.ring_endpoints(), FarCityFetcher.endpoints(), HorizonFetcher.endpoints()]:
		for url in list:
			if HostPolicy.is_blocked(url):
				_failures.append("Overpass order lists a blocked host: %s" % url)
	for host_list in [OfflineOsmPack.PRIMARY_HOSTS, OfflineOsmPack.ALTERNATE_HOSTS]:
		for url in OsmFetcher.endpoint_order(host_list).slice(0, 2):
			if HostPolicy.is_blocked(url):
				_failures.append("offline pack mirror pair has a blocked host: %s" % url)

func _test_source() -> void:
	var hosts := RegEx.new()
	hosts.compile("(?i)[a-z0-9-]+\\.(ru|su|xn--p1ai|рф)(?![a-z0-9-])")
	var names := RegEx.new()
	names.compile("(?i)yandex|vkontakte|rambler|2gis")
	var files: Array[String] = []
	_collect("res://scripts", [".gd"], files)
	_collect("res://site", [".html", ".json", ".css"], files)
	files.append_array(["res://export_presets.cfg", "res://project.godot"])
	var scanned := 0
	for path in files:
		if path.ends_with("/host_policy.gd"):
			continue  # the policy itself has to name what it blocks
		var text := FileAccess.get_file_as_string(path)
		scanned += 1
		for pattern in [hosts, names]:
			var hit: RegExMatch = pattern.search(text)
			if hit != null:
				_failures.append("%s mentions a Russian host: %s" % [path, hit.get_string()])
	if scanned < 100:
		_failures.append("the source scan found only %d files; the scan itself is broken" % scanned)

func _collect(dir: String, extensions: Array[String], out: Array[String]) -> void:
	for sub in DirAccess.get_directories_at(dir):
		_collect(dir.path_join(sub), extensions, out)
	for file in DirAccess.get_files_at(dir):
		for ext in extensions:
			if file.ends_with(ext):
				out.append(dir.path_join(file))
				break
