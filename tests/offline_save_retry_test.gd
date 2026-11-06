extends SceneTree

class TestMain extends "res://scripts/main.gd":
	var saved_data: LocationData
	func _save_world(data: LocationData) -> void:
		saved_data = data

class FakePipeline extends GenerationPipeline:
	var runs := 0
	var retry_result: LocationData
	var retry_degraded: Array[String] = []
	func _ready() -> void:
		pass
	func run(_lat: float, _lon: float, _name: String = "", _quality: int = 2,
			_focus: Dictionary = {}, _view: Dictionary = {}) -> void:
		runs += 1
		degraded = retry_degraded.duplicate()
		finished.emit(retry_result)

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var failures: Array[String] = []
	CacheStore.history_override = "user://save-retry-history-%d.json" % OS.get_process_id()
	RenderSettings.path_override = "user://save-retry-settings-%d.json" % OS.get_process_id()
	CacheStore.eviction_suppressed = true
	var main := TestMain.new()
	main.size = Vector2(1280, 800)
	root.add_child(main)
	await process_frame
	var old := main._pipeline
	main.remove_child(old)
	old.queue_free()
	var fake := FakePipeline.new()
	main.add_child(fake)
	main._pipeline = fake
	fake.finished.connect(main._on_generation_finished)
	var first := LocationData.new()
	first.latitude = 10.0
	first.longitude = 20.0
	first.place_name = "Test"
	var recovered := LocationData.new()
	fake.retry_result = recovered
	main._saving = true
	main._generation_deadline_ms = Time.get_ticks_msec() + 600000
	fake.degraded = ["map"]
	main._on_generation_finished(first)
	await process_frame
	await process_frame
	if fake.runs != 1 or main.saved_data != recovered or not main._save_degraded.is_empty():
		failures.append("a recovered layer should retry once and save the recovered result")
	# A worse retry must not replace the more complete initial result.
	main.saved_data = null
	main._save_retry_done = false
	fake.degraded = ["map"]
	fake.retry_degraded = ["map", "imagery"]
	main._on_generation_finished(first)
	await process_frame
	await process_frame
	if fake.runs != 2 or main.saved_data != first or main._save_degraded != ["map"]:
		failures.append("a worse retry should retain the more complete first result")
	# A successful fallback can still leave requested tiles missing.
	main.saved_data = null
	main._save_retry_done = false
	fake.degraded.clear()
	fake.retry_degraded.clear()
	if not main._save_missing_data(first):
		failures.append("fixture should have missing requested data")
	main._on_generation_finished(first)
	await process_frame
	await process_frame
	if fake.runs != 3 or main.saved_data != recovered:
		failures.append("missing requested tiles should trigger a retry even without a degraded layer")
	# Do not start a retry when there is not enough time to build the world.
	main.saved_data = null
	main._save_retry_done = false
	main._generation_deadline_ms = Time.get_ticks_msec() + 1000
	fake.degraded = ["map"]
	main._on_generation_finished(first)
	if fake.runs != 3 or main.saved_data != first:
		failures.append("retry should respect the remaining save budget")
	# Cancellation before the deferred retry must not restart networking.
	main.saved_data = null
	main._save_retry_done = false
	main._generation_deadline_ms = Time.get_ticks_msec() + 600000
	main._on_generation_finished(first)
	main._gen_id += 1
	await process_frame
	await process_frame
	if fake.runs != 3 or main.saved_data != null:
		failures.append("cancelled save should not start a deferred retry")
	main._saving = false
	main.queue_free()
	await process_frame
	CacheStore.eviction_suppressed = false
	CacheStore.history_override = ""
	RenderSettings.path_override = ""
	if failures.is_empty():
		print("OFFLINE SAVE RETRY OK: recovery, preserve better result, bounded retry")
		quit(0)
	else:
		for failure in failures:
			printerr("OFFLINE SAVE RETRY FAIL: ", failure)
		quit(1)
