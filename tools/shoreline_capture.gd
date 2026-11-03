extends "res://tools/capture_presets.gd"

## Same-input shoreline capture and build benchmark. Run through godot_bg:
## -- --presets=0,1,2,3 --places=venice,amsterdam,paris,stockholm,monaco,helsinki,dubai,big_sur
## --bank-only --tag=shoreline-before|shoreline-after --snapshots=/tmp/shore-inputs
## PR360_DISABLE_WORLD_CACHE=1 forces cold geometry builds, retaining data caches.
func _capture(main: Node, view: View360, place: Dictionary, times: PackedStringArray,
		audit: bool, settle_s: float = SETTLE_S) -> void:
	var args := _args()
	if not args.has("inputs"):
		await super._capture(main, view, place, times, audit, settle_s)
		return
	var id := str(place["id"])
	var path := str(args["inputs"]).path_join(id + ".snap")
	if not FileAccess.file_exists(path):
		printerr("SHORE INPUT MISSING ", path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var saved: Dictionary = file.get_var()
	file.close()
	var data := LocationData.new()
	var properties := {}
	for property in data.get_property_list():
		properties[property["name"]] = true
	for key in saved:
		if properties.has(key):
			data.set(key, _thaw(saved[key], data.get(key)))
	view.set_quality_preset(data.quality_preset)
	var t0 := Time.get_ticks_msec()
	var built: Array = await view.build_location(data, null, BuildAbort.new())
	var elapsed := Time.get_ticks_msec() - t0
	if built.is_empty():
		printerr("SHORE BUILD FAILED ", id)
		return
	print("SHORE BUILD ", id, " ms=", elapsed)
	if OS.get_cmdline_user_args().has("--bench-only"):
		_stats[id] = {"build_ms": elapsed, "static_peak_bytes": OS.get_static_memory_peak_usage(),
			"static_bytes": OS.get_static_memory_usage()}
		(built[1] as Node).free()
		return
	_weather_in = false
	view.show_location(data, built)
	main._show(view)
	main._notice.visible = false
	view._governor.set_process(false)
	var weather_start := Time.get_ticks_msec()
	while not _weather_in and Time.get_ticks_msec() - weather_start < int(WEATHER_WAIT_S * 1000.0):
		await process_frame
	view._atmos.set_weather(0, 15.0)
	ViewConditions._apply_precip(view, 0)
	ViewConditions.apply_surface_state(view)
	ViewConditions.spawn_golden_hour(view)
	await _settle(settle_s, SETTLE_FRAMES)
	await _snap(view, id, "vantage")
	_stats[id + "_vantage"]["build_metrics"]["build_ms"] = elapsed
	var rig := view._rig
	var look := Vector2(rig.yaw, rig.pitch)
	rig.set_look(look.x, look.y - 0.3)
	rig.zoom_factor = 2.0
	rig.handle_zoom(1.0)
	await _snap(view, id, "bank")
	rig.zoom_factor = 1.0
	rig.handle_zoom(1.0)
	rig.set_look(look.x, look.y)
	if OS.get_cmdline_user_args().has("--edge-probe"):
		await _edge_probe(view, id, settle_s)

## A separate inspection camera makes distant retaining faces legible.
## The production opening frame is captured before this temporary pose.
func _edge_probe(view: View360, id: String, settle_s: float) -> void:
	var ground: GroundTruth = view._ground
	var model: ShorelineModel = ground.shoreline
	if model == null or not model.ready or model.segments.is_empty():
		return
	var rig := view._rig
	var position := rig.position
	var look := Vector2(rig.yaw, rig.pitch)
	var zoom := rig.zoom_factor
	var start := Vector2(position.x, position.z)
	var hard_available := model.hard_count() > 0
	var best := INF
	var closest := {}
	for segment in model.segments:
		if hard_available and str(segment["kind"]) != "hard":
			continue
		var q := Geometry2D.get_closest_point_to_segment(start, segment["a"], segment["b"])
		var distance := start.distance_squared_to(q)
		if distance < best:
			best = distance
			closest = segment
	var mid: Vector2 = (closest["a"] + closest["b"]) * 0.5
	var land: Vector2 = closest["land"]
	var direction: Vector2 = (closest["b"] - closest["a"]).normalized()
	var eye := mid - land * 0.25
	for distance in [10.0, 6.0, 3.0, 1.0, 0.25]:
		var p: Vector2 = mid - land * distance + direction * minf(distance * 0.4, 4.0)
		if model.domains.at(p) >= 0:
			eye = p
			break
	var level := model.domains.level(int(closest["body"]), mid)
	var dry := mid + land * 5.0
	var top := maxf(level, ground.height_at_world(dry.x, dry.y))
	rig.position = Vector3(eye.x, top + 2.0, eye.y)
	var aim := View360.aim(rig.position, Vector3(mid.x, lerpf(level, top, 0.5), mid.y))
	rig.set_look(aim.x, aim.y)
	rig.set_zoom(1.0)
	view._atmos.set_probe_origin(rig.position)
	await _settle(settle_s, SETTLE_FRAMES)
	await _snap(view, id, "edge")
	_stats[id + "_edge"]["shore_segment"] = closest
	_stats[id + "_edge"]["target_rule"] = "nearest_hard_or_natural_when_no_hard_bank"
	rig.position = position
	rig.set_look(look.x, look.y)
	rig.set_zoom(zoom)
	view._atmos.set_probe_origin(position)

func _thaw(value: Variant, like: Variant = null) -> Variant:
	if value is Dictionary:
		if value.has("__img"):
			return Image.create_from_data(value["w"], value["h"], value["mip"], value["fmt"], value["data"])
		if value.has("__tex"):
			return ImageTexture.create_from_image(_thaw(value["__tex"]))
		var dict := {}
		for key in value:
			dict[key] = _thaw(value[key])
		return dict
	if value is Array:
		var array: Array = []
		for item in value:
			array.append(_thaw(item))
		if like is Array and like.is_typed():
			var typed: Array = like.duplicate()
			typed.clear()
			typed.assign(array)
			return typed
		return array
	return value

func _snap(view: View360, id: String, shot: String) -> void:
	await super._snap(view, id, shot)
	if shot != "vantage":
		return
	var metrics := {"static_bytes": OS.get_static_memory_usage(), "static_peak_bytes": OS.get_static_memory_peak_usage()}
	var model: Variant = view._ground.get("shoreline")
	if model != null and model.get("ready"):
		metrics["bodies"] = model.domains.bodies.size()
		metrics["patches"] = model.patches.size()
		metrics["hard_segments"] = model.hard_count()
		metrics["diagnostics"] = model.diagnostics
		var reasons := {}
		for segment in model.segments:
			var reason := str(segment["reason"])
			reasons[reason] = int(reasons.get(reason, 0)) + 1
		metrics["bank_reasons"] = reasons
	var ps: Array = []
	OS.execute("/bin/ps", ["-o", "rss=", "-p", str(OS.get_process_id())], ps)
	if not ps.is_empty():
		metrics["rss_bytes"] = int(str(ps[0]).strip_edges()) * 1024
	_stats[id + "_vantage"]["build_metrics"] = metrics
	var args := _args()
	if args.has("snapshots"):
		var dir := str(args["snapshots"])
		DirAccess.make_dir_recursive_absolute(dir)
		var saved := {}
		for property in view._data.get_property_list():
			if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
				saved[property["name"]] = _freeze(view._data.get(property["name"]))
		var file := FileAccess.open(dir.path_join(id + ".snap"), FileAccess.WRITE)
		file.store_var(saved)
	print("SHORE CAPTURE ", id, " ", JSON.stringify(metrics))

func _freeze(value: Variant) -> Variant:
	if value is Image:
		return {"__img": true, "w": value.get_width(), "h": value.get_height(), "mip": value.has_mipmaps(),
			"fmt": value.get_format(), "data": value.get_data()}
	if value is Texture2D:
		return {"__tex": _freeze(value.get_image())}
	if value is Dictionary:
		var dict := {}
		for key in value:
			dict[key] = _freeze(value[key])
		return dict
	if value is Array:
		var array: Array = []
		for item in value:
			array.append(_freeze(item))
		return array
	if value is Object:
		return null
	return value
