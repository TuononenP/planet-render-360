extends SceneTree

## Degraded-data notices: godot --headless --script tests/data_notes_test.gd
## When live data does not arrive the user must be told, in plain words
## and without naming any provider: the loading line, the DataNotice card
## (Dismiss -> "Partial data" badge -> reopen, Try again) and the
## pipeline's once-per-layer record that feeds them.

const BANNED := ["overpass", "osm", "openstreetmap", "esri", "aws", "terrain tiles",
	"nominatim", "api", "http", "502", "timeout", "endpoint"]

func _init() -> void:
	_run()

func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text.contains(text):
		return node as Button
	for c in node.get_children():
		var hit := _find_button(c, text)
		if hit != null:
			return hit
	return null

func _all_text(node: Node) -> String:
	var out := ""
	if node is Label:
		out += (node as Label).text + " "
	elif node is Button:
		out += (node as Button).text + " " + (node as Button).tooltip_text + " "
	for c in node.get_children():
		out += _all_text(c)
	return out

func _run() -> void:
	var failures: Array[String] = []
	_wording_checks(failures)
	_pipeline_checks(failures)
	await _notice_checks(failures)
	await _loading_checks(failures)
	if failures.is_empty():
		print("DATA NOTES OK: plain wording, once-per-layer record, notice card + badge, loading line")
		quit(0)
	else:
		for f in failures:
			printerr("DATA NOTES FAIL: ", f)
		quit(1)

func _wording_checks(failures: Array[String]) -> void:
	var rows := DataNotes.describe(["map", "bogus", "elevation"])
	if rows.size() != 2 or rows[0]["layer"] != "Elevation" or rows[1]["layer"] != "Map details":
		failures.append("describe should keep LAYERS order and drop unknown keys: %s" % [rows])
	if DataNotes.is_error(rows) or not DataNotes.is_error(DataNotes.describe(["elevation", "imagery", "map"])):
		failures.append("only all three layers missing is an error")
	# Fast never fetches imagery: elevation + map missing is fully offline.
	if not DataNotes.is_error(DataNotes.describe(["elevation", "map"], false)) \
			or DataNotes.is_error(DataNotes.describe(["map"], false)):
		failures.append("on Fast, elevation + map missing is the error state")
	var texts: Array[String] = [DataNotes.loading_line(["map", "imagery"])]
	for keys in [["map"], ["elevation", "imagery", "map"]]:
		var notes := DataNotes.describe(keys)
		texts.append(DataNotes.title(notes))
		texts.append(DataNotes.message(notes))
		for n in notes:
			texts.append("%s %s" % [n["layer"], n["effect"]])
	for t in texts:
		for word in BANNED:
			if t.to_lower().contains(word):
				failures.append("notice wording must not name a provider/code: '%s' has '%s'" % [t, word])
	if DataNotes.loading_line([]) != "":
		failures.append("no degraded layer, no loading line")
	if DataNotes.osm_outage("Overpass returned no buildings; OSM API returned no buildings (tried 5 endpoint(s))"):
		failures.append("an empty place (valid empty answers) is not an outage")
	if not DataNotes.osm_outage("Overpass failed (result=0 code=502); OSM API failed (result=0 code=0) (tried 5 endpoint(s))"):
		failures.append("failed requests are an outage")

func _pipeline_checks(failures: Array[String]) -> void:
	var p := GenerationPipeline.new()
	var seen: Array[String] = []
	p.degraded_layer.connect(func(l: String) -> void: seen.append(l))
	p._note("map")
	p._note("map")
	p._note("imagery")
	if seen != ["map", "imagery"] or p.degraded != ["map", "imagery"]:
		failures.append("a layer should be recorded and announced once, got %s / %s" % [seen, p.degraded])
	p.free()

func _notice_checks(failures: Array[String]) -> void:
	var host := Control.new()
	host.size = Vector2(1000, 700)
	root.add_child(host)
	var n := DataNotice.new()
	host.add_child(n)
	n.size = Vector2(1000, 700)
	var retries := [0]
	n.retry_requested.connect(func() -> void: retries[0] += 1)
	await process_frame
	n.show_notes([])
	n.set_on_screen(true)
	if n.visible:
		failures.append("nothing degraded: the notice must stay hidden")
	n.show_notes(DataNotes.describe(["map", "imagery"]))
	await process_frame
	await process_frame
	if not n.visible or not n.is_open():
		failures.append("degraded data: the card should open on arrival")
	var text := _all_text(n)
	for want in ["Some data is unavailable", "Map details", "Imagery", "Try again", "Dismiss"]:
		if not text.contains(want):
			failures.append("card should say '%s', got: %s" % [want, text])
	for word in BANNED:
		if text.to_lower().contains(word):
			failures.append("card names a provider/code: %s" % word)
	var card := n.get_child(0) as Control
	if card.size.x < 280.0 or card.size.x > 380.0 or card.position.y < 60.0:
		failures.append("card should be 280-380 wide below the top bar, got %s at %s" % [card.size, card.position])
	if card.size.y < card.get_combined_minimum_size().y - 1.0:
		failures.append("card must be tall enough for its wrapped text")
	_find_button(n, "Dismiss").pressed.emit()
	if n.is_open() or not (n.get_child(1) as Control).visible or card.visible:
		failures.append("Dismiss should fold the card into the Partial data badge")
	if not _all_text(n).contains("Partial data"):
		failures.append("the badge should read Partial data")
	_find_button(n, "Partial data").pressed.emit()
	if not n.is_open():
		failures.append("the badge should reopen the card")
	_find_button(n, "Try again").pressed.emit()
	if retries[0] != 1:
		failures.append("Try again should request a new generation once")
	n.show_notes(DataNotes.describe(["elevation", "imagery", "map"]))
	if not _all_text(n).contains("No live data came back"):
		failures.append("all layers missing should read as an error title")
	n.set_on_screen(false)
	if n.visible:
		failures.append("the notice belongs to the 360 view only")
	host.free()

func _loading_checks(failures: Array[String]) -> void:
	var ls := LoadingScreen.new()
	ls.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(ls)
	await process_frame
	ls.add_degraded("map")
	ls.add_degraded("map")
	ls.add_degraded("imagery")
	var line := ls._note_label
	if not line.visible or line.text.count("map details") != 1 or not line.text.contains("imagery"):
		failures.append("loading screen should list each unresponsive layer once, got '%s'" % line.text)
	ls.begin("Elsewhere")
	if line.visible:
		failures.append("a new run starts with no warning line")
	ls.free()
