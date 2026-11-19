extends SceneTree

## CityOpenData (offline): godot --headless --script tests/city_open_data_test.gd
## land() merges on a worker; cancel() while it waits on that worker ends
## it next frame without credits (no spin on a forgotten task id), a newer
## land() joins an older one's merge, and the next land() runs normally.
## A test gate holds the merge, so the cancel always lands mid-merge.

var failures: Array[String] = []

func _init() -> void:
	_run()

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)

## Central Helsinki with one building on a bundled LoD2 row: a merge that
## earns a credit when it runs to the end.
func _data() -> LocationData:
	var d := LocationData.new()
	d.latitude = 60.1680
	d.longitude = 24.9450
	var rows := HelsinkiLod2.read_cell("25496_6672")
	var r: Array = rows[0]
	var p := Gk25.frame_xz(Gk25.frame(d.latitude, d.longitude), float(r[1]), float(r[2]))
	d.buildings = [{"footprint": PackedVector2Array([p + Vector2(-6, -6), p + Vector2(6, -6),
		p + Vector2(6, 6), p + Vector2(-6, 6)]), "holes": [], "height": 10.0,
		"height_source": "default", "levels": 0.0, "roof_shape": "", "roof_angle": 0.0, "parts": [], "kind": "yes"}]
	return d

func _run() -> void:
	var city := CityOpenData.new()
	root.add_child(city)
	await process_frame
	city.offline = true
	city.fetch(0.0, 0.0)  # no layer covers it: done at once
	var box := {}
	var run := func(key: String) -> void:
		box[key] = await city.land(_data(), 1.0)
	# 1. Cancel while the merge is held: land() must be waiting on it.
	var gate := Semaphore.new()
	city._merge_gate = gate
	run.call("first")
	await process_frame
	_check(city._land_task >= 0 and not box.has("first"), "land() waits on its merge (precondition)")
	gate.post()  # let the worker finish, or cancel()'s join would wait forever
	city.cancel()
	for i in 5:
		await process_frame
	_check(box.has("first") and (box["first"] as Array).is_empty(), "A cancelled land() returns next frame, without credits")
	_check(city._land_task == -1, "No task is left behind")
	# 2. A newer land() while an older one waits: the older is joined.
	var gate2 := Semaphore.new()
	city._merge_gate = gate2
	run.call("older")
	await process_frame
	_check(not box.has("older"), "The older land() is waiting")
	gate2.post()
	city._merge_gate = null
	run.call("newer")
	for i in 30:
		await process_frame
		if box.has("older") and box.has("newer"):
			break
	_check(box.has("older") and (box["older"] as Array).is_empty(), "The older land() ends without credits")
	_check(box.has("newer") and (box["newer"] as Array).has(HelsinkiLod2.CREDIT), "The newer land() merges and credits")
	_check(city._land_task == -1, "Every merge is joined")
	city.queue_free()
	await process_frame
	if failures.is_empty():
		print("CITY OPEN DATA OK: cancel mid-merge, newer run joins the older, credits")
		quit(0)
	else:
		for f in failures:
			printerr("CITY OPEN DATA FAIL: ", f)
		quit(1)
