extends SceneTree

## Headless test: godot --headless --script tests/privacy_page_test.gd
## The in-app Privacy page (Settings → Privacy) must say what the website's
## privacy policy says: the same services and hosts, the same lists, the same
## opening words. It must reach no blocked host, and the Settings screen must
## build it (hero, figures and every service) and summarise it.

var _failures: Array[String] = []

func _init() -> void:
	RenderSettings.path_override = "user://privacy-page-test-%d.json" % OS.get_process_id()
	_run()

func _run() -> void:
	_test_matches_site()
	await _test_settings_page()
	if _failures.is_empty():
		print("PRIVACY PAGE OK: matches site/privacy.html, %d services, built in Settings" % PrivacyData.SERVICES.size())
		quit(0)
	else:
		for f in _failures:
			printerr("FAIL: " + f)
		quit(1)

func _site_text() -> String:
	var html := FileAccess.get_file_as_string("res://site/privacy.html")
	return html.replace("&amp;", "&")

func _test_matches_site() -> void:
	var html := _site_text()
	if html.is_empty():
		_failures.append("site/privacy.html is missing")
		return
	var chips := RegEx.new()
	chips.compile("<span class=\"host-chip\">([^<]+)</span>")
	var site_hosts: Array[String] = []
	for m in chips.search_all(html):
		var host := m.get_string(1)
		if not site_hosts.has(host):
			site_hosts.append(host)
	var app_hosts := PrivacyData.hosts()
	for host in app_hosts:
		if not site_hosts.has(host):
			_failures.append("the app page names %s, the website does not" % host)
		if HostPolicy.is_blocked(host):
			_failures.append("the app page names a blocked host: %s" % host)
	for host in site_hosts:
		if not app_hosts.has(host):
			_failures.append("the website names %s, the app page does not" % host)
	var sentences: Array[String] = [PrivacyData.LEDE, PrivacyData.BODY, PrivacyData.ON_DEVICE_NOTE,
		PrivacyData.CHILDREN]
	sentences.append_array(PrivacyData.ON_DEVICE)
	sentences.append_array(PrivacyData.NEVER)
	sentences.append_array(PrivacyData.CHOICES)
	for service in PrivacyData.SERVICES:
		sentences.append(service[0])
		sentences.append(service[2])
	for sentence in sentences:
		if not html.contains(sentence):
			_failures.append("the website does not carry this sentence: %s" % sentence.left(60))
	if not html.contains("Updated " + PrivacyData.UPDATED):
		_failures.append("the website's date is not %s" % PrivacyData.UPDATED)
	for stat in PrivacyData.GLANCE:
		if not html.contains("<span>%s</span>" % stat[1]):
			_failures.append("the website lacks the figure caption: %s" % stat[1])

func _test_settings_page() -> void:
	var screen := SettingsScreen.new()
	screen.bind_settings(RenderSettings.new())
	root.add_child(screen)
	await process_frame
	await process_frame
	if not screen._pages.has("privacy"):
		_failures.append("Settings has no privacy page")
		return
	if screen.summary_for("privacy") != PrivacyData.summary():
		_failures.append("the privacy category row has the wrong summary")
	var page: Control = screen._pages["privacy"]
	var heroes := page.find_children("*", "PrivacyHero", true, false)
	if heroes.size() != 1:
		_failures.append("the privacy page should carry one hero, found %d" % heroes.size())
	var all_text := ""
	for node in page.find_children("*", "Label", true, false):
		all_text += (node as Label).text + "\n"
	for host in PrivacyData.hosts():
		if not all_text.contains(host):
			_failures.append("the built page does not show %s" % host)
	for service in PrivacyData.SERVICES:
		if not all_text.contains(str(service[0])):
			_failures.append("the built page does not show %s" % str(service[0]))
	screen.open_category("privacy")
	await process_frame
	if not page.visible:
		_failures.append("open_category('privacy') did not show the page")
	if UiIcon.texture("shield-check", 20) == null:
		_failures.append("the shield-check icon does not load")
	screen.queue_free()
