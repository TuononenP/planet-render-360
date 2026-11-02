extends SceneTree

## Capture-and-compare run over the golden set (realism v3, R-1.1).
## Windowed, off-screen, never on top:
##   tools/godot_bg.sh --path . --script tools/capture_presets.gd --position 4000,4000 \
##     -- [--tag=name] [--preset=0..3] [--places=id,id] [--times=golden,noon,night,late,roofs]
##        [--settle=seconds]  (wait after golden hour is set; default SETTLE_S)
##
## Runs the real app flow (Main → pipeline → View360, caches first) for
## every quick-pick preset plus generic controls, under fixed conditions
## (summer, clear weather at the place's local golden hour, reduce-motion,
## FPS governor pinned at the preset), and saves the 3D view itself (the
## HUD is not drawn into it)
## to visual-plan/reviews/<tag>-<date>/:
##   <id>_vantage.jpg            opening look at golden hour
##   <id>_h000/090/180/270.jpg   N, E, S, W at golden hour
##   <id>_close1/2.jpg           narrow-FOV close-ups of the opening look
##   <id>_vantage_noon/night.jpg same opening look at noon and at night
##   <id>_vantage_late.jpg       two hours after sunset (--times=late)
##   <id>_roofs.jpg              from 140 m up, looking down the opening look (--times=roofs)
##   <id>_sheet.jpg              render beside the first reference photo
##   stats.json                  luma, saturation, colourfulness per frame
##                               and band, flagged against the references
## With --audit (R-1.4 look audit, a report only):
##   <id>_unshaded.jpg           opening look, albedo only (no light)
##   <id>_agx.jpg                opening look with AgX instead of ACES
##   audit.json                  per place, every StandardMaterial3D's mean
##                               linear albedo, flagged against ALBEDO_RANGES
## Reference photos live in visual-plan/refs/<id>/ (see its README).
## The user's History is restored afterwards; settings are not saved.

const SIZE := Vector2i(1280, 800)
const PLACE_TIMEOUT_S := 600.0
const SETTLE_S := 2.5
## Frames drawn by a place's first settle: enough for SDFGI to converge
## on Ultra. The settles between its later shots (a new hour, the roofs
## look) start from a converged scene and draw SHOT_SETTLE_FRAMES.
const SETTLE_FRAMES := 240
## Height of the --times=roofs look above the opening eye.
const SHOT_SETTLE_FRAMES := 60
const ROOFS_UP_M := 140.0
const STEP := 4  # stats sample every 4th pixel in x and y
## Upper, middle and lower row bands (sky, skyline, ground at a level look).
const BANDS := {"upper": [0.0, 0.35], "middle": [0.35, 0.65], "lower": [0.65, 1.0]}
## A frame is flagged when a whole-frame stat leaves the references'
## range widened by this fraction.
const REF_SLACK := 0.15
const WEATHER_WAIT_S := 20.0
const HISTORY := "user://history.json"
const HISTORY_BACKUP := "user://history.capture-backup.json"
## Measured mean linear albedo per surface class (the R-1.4 ranges); a
## material is classed by the first keyword its cache key contains.
const ALBEDO_RANGES := {
	"glass": [0.08, 0.15], "brick": [0.20, 0.35], "limestone": [0.45, 0.60],
	"concrete": [0.30, 0.45], "terracotta": [0.25, 0.40], "asphalt": [0.06, 0.12],
	"grass": [0.15, 0.25], "lawn": [0.15, 0.25],
}

## Generic controls beside the presets: the old Paris pin every past
## baseline used, the old Setagaya Tokyo pin, and places with no preset.
const CONTROLS := [
	{"id": "paris_old", "name": "Paris, France", "lat": 48.8566, "lon": 2.3522},
	{"id": "tokyo_setagaya", "name": "Tokyo, Japan", "lat": 35.6762, "lon": 139.6503},
	{"id": "turku", "name": "Turku, Finland", "lat": 60.4518, "lon": 22.2666},
	{"id": "zermatt", "name": "Zermatt, Switzerland", "lat": 46.0207, "lon": 7.7491},
	{"id": "cairo", "name": "Cairo, Egypt", "lat": 30.0444, "lon": 31.2357},
]

var _out := ""
var _stats := {}
var _audit := {}
var _had_history := false
## The place's own weather answered (or failed): its UTC offset is set.
var _weather_in := false

func _init() -> void:
	_run()

func _args() -> Dictionary:
	var a := {"tag": "capture", "preset": 2, "places": "", "times": "golden,noon,night"}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--") and arg.contains("="):
			var kv := arg.substr(2).split("=", true, 1)
			a[kv[0]] = kv[1]
		elif arg == "--audit":
			a["audit"] = true
	return a

func _places(filter: String) -> Array:
	var all: Array = []
	for row in PresetViews.ROWS:
		all.append({"id": row["id"], "name": row["name"], "lat": row["lat"], "lon": row["lon"]})
	all.append_array(CONTROLS)
	if filter == "":
		return all
	var want := filter.split(",")
	return all.filter(func(p: Dictionary) -> bool: return want.has(str(p["id"])))

func _run() -> void:
	var a := _args()
	_out = ProjectSettings.globalize_path("res://").path_join("visual-plan/reviews/%s-%s" % [
		a["tag"], Time.get_date_string_from_system()])
	DirAccess.make_dir_recursive_absolute(_out)
	_backup_history()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	await process_frame
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	root.size = SIZE
	await create_timer(0.5).timeout
	root.size = SIZE  # the first resize can be lost to window creation
	for child in main.get_children():
		if child is OnboardingScreen:
			child.queue_free()
	UiPrefs.reduce_motion = true
	main._settings.preset = int(a["preset"])  # in memory only, never saved
	var view: View360 = main._view
	view._governor.set_process(false)
	# Live weather still lands (it carries the place's UTC offset, so the
	# golden hour is local), then each capture forces clear weather.
	view._weather.succeeded.connect(func(_t: float, _l: String, _c: float, _code: int) -> void:
		_weather_in = true)
	view._weather.failed.connect(func(_r: String) -> void: _weather_in = true)
	var times: PackedStringArray = str(a["times"]).split(",")
	for place in _places(str(a["places"])):
		await _capture(main, view, place, times, a.has("audit"), float(a.get("settle", SETTLE_S)))
	_write_stats()
	if a.has("audit"):
		_write_json("audit.json", _audit)
	_restore_history()
	print("CAPTURE DONE -> ", _out)
	quit(0)

func _capture(main: Node, view: View360, place: Dictionary, times: PackedStringArray,
		audit: bool, settle_s: float = SETTLE_S) -> void:
	var id := str(place["id"])
	main._picker.selected_name = str(place["name"])
	_weather_in = false
	main._start_generation(float(place["lat"]), float(place["lon"]))
	var start := Time.get_ticks_msec()
	while (main._generating or not view.visible) \
			and Time.get_ticks_msec() - start < int(PLACE_TIMEOUT_S * 1000.0):
		await process_frame
	if not view.visible or main._generating:
		printerr("CAPTURE SKIP %s: no view after %d s" % [id, (Time.get_ticks_msec() - start) / 1000])
		return
	print("CAPTURE %s built in %d s" % [id, (Time.get_ticks_msec() - start) / 1000])
	main._notice.visible = false
	view._governor.set_preset(int(main._settings.preset))
	var wait := Time.get_ticks_msec()
	while not _weather_in and Time.get_ticks_msec() - wait < int(WEATHER_WAIT_S * 1000.0):
		await process_frame
	view._atmos.set_weather(0, 15.0)
	ViewConditions._apply_precip(view, 0)
	ViewConditions.apply_surface_state(view)
	ViewConditions.spawn_golden_hour(view)
	await _settle(settle_s, SETTLE_FRAMES)
	var rig := view._rig
	var open := Vector2(rig.yaw, rig.pitch)
	await _snap(view, id, "vantage")
	if audit:
		view._viewport.debug_draw = Viewport.DEBUG_DRAW_UNSHADED
		await _snap(view, id, "unshaded")
		view._viewport.debug_draw = Viewport.DEBUG_DRAW_DISABLED
		var env: Environment = view._atmos.environment
		var tonemap := env.tonemap_mode
		env.tonemap_mode = Environment.TONE_MAPPER_AGX
		await _snap(view, id, "agx")
		env.tonemap_mode = tonemap
		_audit[id] = albedo_audit(view._world_root)
	for bearing in [0, 90, 180, 270]:
		rig.set_look(-deg_to_rad(float(bearing)), -0.06)
		await _snap(view, id, "h%03d" % bearing)
	rig.set_look(open.x, open.y)
	rig.zoom_factor = 2.8
	rig.handle_zoom(1.0)
	await _snap(view, id, "close1")
	rig.set_look(open.x, open.y - 0.3)
	rig.zoom_factor = 2.0
	rig.handle_zoom(1.0)
	await _snap(view, id, "close2")
	rig.reset_zoom()
	rig.set_look(open.x, open.y)
	if times.has("roofs"):
		# Rooftops (clutter, roof forms) are out of sight from the street.
		var eye := rig.position
		rig.position = eye + Vector3(0.0, ROOFS_UP_M, 0.0)
		rig.set_look(open.x, -0.55)
		await _settle(1.0, SHOT_SETTLE_FRAMES)
		await _snap(view, id, "roofs")
		rig.position = eye
		rig.set_look(open.x, open.y)
		await _settle(1.0, SHOT_SETTLE_FRAMES)
	if times.has("noon"):
		ViewConditions.jump_to(view, "noon")
		await _settle(1.0, SHOT_SETTLE_FRAMES)
		await _snap(view, id, "vantage_noon")
	if times.has("night"):
		ViewConditions.jump_to(view, "moon")
		await _settle(1.0, SHOT_SETTLE_FRAMES)
		await _snap(view, id, "vantage_night")
	if times.has("late"):
		# Two hours after sunset: full dark, homes still lit (the moon jump
		# can land in a bright moonlit sky with the windows barely on).
		ViewConditions.set_time_minutes(view, ViewConditions.sun_times(view).y + 120.0)
		await _settle(1.0, SHOT_SETTLE_FRAMES)
		await _snap(view, id, "vantage_late")
	_contact_sheet(id)

## Waits `seconds` while drawing at least `frames` frames. Off-screen,
## macOS stops redrawing the window (two frames in 30 s), so a plain timer
## left Ultra's SDFGI unconverged: the first place lost its sky and bounce
## light and only later places, after the earlier shots' draws, were lit.
func _settle(seconds: float, frames: int) -> void:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	var drawn := 0
	while drawn < frames or Time.get_ticks_msec() < end:
		await process_frame
		RenderingServer.force_draw(false)
		drawn += 1

## The 3D view only: the SubViewport's own texture carries no HUD.
## force_draw renders synchronously, so captures stay fresh even while
## the window sits off-screen.
func _snap(view: View360, id: String, shot: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	var img := view._viewport.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	var path := _out.path_join("%s_%s.jpg" % [id, shot])
	img.save_jpg(path, 0.88)
	var s := frame_stats(img)
	var refs := _ref_ranges(id)
	if not refs.is_empty():
		s["flags"] = _flags(s, refs)
	_stats["%s_%s" % [id, shot]] = s
	print("SHOT %s_%s luma %.3f sat %.3f colourful %.3f" % [id, shot,
		float(s["all"]["luma"]), float(s["all"]["sat"]), float(s["all"]["colourful"])])

## Mean luma (Rec. 709), mean HSV saturation and Hasler–Süsstrunk
## colourfulness (0–1 scale), for the whole frame and per row band.
static func frame_stats(img: Image) -> Dictionary:
	var out := {"all": _band_stats(img, 0.0, 1.0)}
	for band in BANDS:
		var r: Array = BANDS[band]
		out[band] = _band_stats(img, float(r[0]), float(r[1]))
	return out

static func _band_stats(img: Image, top: float, bottom: float) -> Dictionary:
	var y0 := int(top * img.get_height())
	var y1 := int(bottom * img.get_height())
	var n := 0
	var luma := 0.0
	var sat := 0.0
	var rg := 0.0
	var yb := 0.0
	var rg2 := 0.0
	var yb2 := 0.0
	for y in range(y0, y1, STEP):
		for x in range(0, img.get_width(), STEP):
			var c := img.get_pixel(x, y)
			luma += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			var hi := maxf(c.r, maxf(c.g, c.b))
			sat += 0.0 if hi <= 0.0 else (hi - minf(c.r, minf(c.g, c.b))) / hi
			var a := c.r - c.g
			var b := 0.5 * (c.r + c.g) - c.b
			rg += a
			yb += b
			rg2 += a * a
			yb2 += b * b
			n += 1
	if n == 0:
		return {"luma": 0.0, "sat": 0.0, "colourful": 0.0}
	var m_rg := rg / n
	var m_yb := yb / n
	var sd := sqrt(maxf(rg2 / n - m_rg * m_rg, 0.0) + maxf(yb2 / n - m_yb * m_yb, 0.0))
	return {"luma": luma / n, "sat": sat / n,
		"colourful": sd + 0.3 * sqrt(m_rg * m_rg + m_yb * m_yb)}

## Whole-frame stat ranges over the place's reference photos, {} when
## it has none.
func _ref_ranges(id: String) -> Dictionary:
	var out := {}
	for img in _refs(id):
		var s: Dictionary = frame_stats(img)["all"]
		for k in s:
			var r: Vector2 = out.get(k, Vector2(INF, -INF))
			out[k] = Vector2(minf(r.x, float(s[k])), maxf(r.y, float(s[k])))
	return out

func _flags(s: Dictionary, refs: Dictionary) -> Array:
	var flags: Array = []
	for k in refs:
		var r: Vector2 = refs[k]
		var v := float(s["all"][k])
		if v < r.x * (1.0 - REF_SLACK) or v > r.y * (1.0 + REF_SLACK):
			flags.append("%s %.3f outside refs %.3f–%.3f" % [k, v, r.x, r.y])
	return flags

func _refs(id: String) -> Array:
	var dir := ProjectSettings.globalize_path("res://").path_join("visual-plan/refs/%s" % id)
	var out: Array = []
	if not DirAccess.dir_exists_absolute(dir):
		return out
	for f in DirAccess.get_files_at(dir):
		if f.get_extension().to_lower() in ["jpg", "jpeg", "png"]:
			var img := Image.load_from_file(dir.path_join(f))
			if img != null:
				img.convert(Image.FORMAT_RGB8)
				out.append(img)
	return out

## Vantage render beside the first reference photo, both 400 px tall.
func _contact_sheet(id: String) -> void:
	var refs := _refs(id)
	var shot := Image.load_from_file(_out.path_join("%s_vantage.jpg" % id))
	if refs.is_empty() or shot == null:
		return
	var ref: Image = refs[0]
	for img in [shot, ref]:
		var im := img as Image
		im.resize(int(im.get_width() * 400.0 / im.get_height()), 400, Image.INTERPOLATE_BILINEAR)
	var sheet := Image.create(shot.get_width() + ref.get_width() + 8, 400, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.1, 0.1, 0.1))
	sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i.ZERO)
	sheet.blit_rect(ref, Rect2i(Vector2i.ZERO, ref.get_size()), Vector2i(shot.get_width() + 8, 0))
	sheet.save_jpg(_out.path_join("%s_sheet.jpg" % id), 0.88)

func _write_stats() -> void:
	_write_json("stats.json", _stats)

func _write_json(file_name: String, value: Variant) -> void:
	var f := FileAccess.open(_out.path_join(file_name), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(value, "  "))

## Every StandardMaterial3D drawn under `root`: mean linear albedo
## (albedo colour × the albedo texture's mean, Rec.709 luma) and how
## many surfaces or instances use it, most-used first, named from the
## material caches and flagged against ALBEDO_RANGES. Vertex colours
## (WallVariety foot shading) and ShaderMaterials are not included.
static func albedo_audit(root: Node) -> Array:
	var names := _material_names()
	var uses := {}
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		var mesh: Mesh = null
		var weight := 1
		if n is MeshInstance3D:
			mesh = (n as MeshInstance3D).mesh
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
			mesh = (n as MultiMeshInstance3D).multimesh.mesh
			weight = (n as MultiMeshInstance3D).multimesh.instance_count
		if mesh == null:
			continue
		for s in mesh.get_surface_count():
			var m: Material = (n as GeometryInstance3D).material_override
			if m == null and n is MeshInstance3D:
				m = (n as MeshInstance3D).get_surface_override_material(s)
			if m == null:
				m = mesh.surface_get_material(s)
			if m is BaseMaterial3D:
				var id := m.get_instance_id()
				if not uses.has(id):
					uses[id] = [m, 0]
				uses[id][1] = int(uses[id][1]) + weight
	var means := {}
	var rows: Array = []
	for id in uses:
		var m: BaseMaterial3D = uses[id][0]
		var c := m.albedo_color.srgb_to_linear()
		if m.albedo_texture != null:
			var rid := m.albedo_texture.get_rid()
			if not means.has(rid):
				means[rid] = _texture_mean(m.albedo_texture)
			var t: Color = means[rid]
			c = Color(c.r * t.r, c.g * t.g, c.b * t.b)
		var luma := 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
		var label := str(names.get(id, m.resource_name if m.resource_name != "" else "unnamed"))
		var row := {"material": label, "uses": uses[id][1], "albedo": snappedf(luma, 0.001),
			"rgb": [snappedf(c.r, 0.001), snappedf(c.g, 0.001), snappedf(c.b, 0.001)]}
		for cls in ALBEDO_RANGES:
			if label.to_lower().contains(cls):
				var r: Array = ALBEDO_RANGES[cls]
				row["class"] = cls
				if luma < float(r[0]) or luma > float(r[1]):
					row["outlier"] = "%s range %.2f–%.2f" % [cls, float(r[0]), float(r[1])]
				break
		rows.append(row)
	rows.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return int(x["uses"]) > int(y["uses"]))
	return rows

## Material instance id -> "<cache>:<key>" over the shared material
## caches (PBR sets, facades, roofs, glass, ground storeys).
static func _material_names() -> Dictionary:
	var out := {}
	var caches := {"pbr": MaterialLibrary._pbr_mats, "facade": FacadeMaterials._facade_cache, "ground_storey": FacadeMaterials._ground_cache,
		"distant": FacadeMaterials._distant_mats, "distant_roof": FacadeMaterials._distant_roof_mats,
		"glass": FacadeMaterials._glass_mats, "roof": FacadeMaterials._roof_mats}
	for cache in caches:
		var d: Dictionary = caches[cache]
		for k in d:
			var v: Variant = d[k]
			for m in (v as Array if v is Array else [v]):
				if m is Material:
					out[(m as Material).get_instance_id()] = "%s:%s" % [cache, str(k)]
	return out

## Mean linear colour of a texture's pixels (sRGB decoded), sampled on
## a grid of at most 64 × 64.
static func _texture_mean(tex: Texture2D) -> Color:
	var img := tex.get_image()
	if img == null:
		return Color.WHITE
	if img.is_compressed():
		img.decompress()
	var step := maxi(1, maxi(img.get_width(), img.get_height()) / 64)
	var sum := Color(0, 0, 0)
	var n := 0
	for y in range(0, img.get_height(), step):
		for x in range(0, img.get_width(), step):
			var p := img.get_pixel(x, y).srgb_to_linear()
			sum = Color(sum.r + p.r, sum.g + p.g, sum.b + p.b)
			n += 1
	return Color(sum.r / n, sum.g / n, sum.b / n) if n > 0 else Color.WHITE

## The run must not leave its places in the person's History.
func _backup_history() -> void:
	_had_history = FileAccess.file_exists(HISTORY)
	if _had_history:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(HISTORY),
			ProjectSettings.globalize_path(HISTORY_BACKUP))

func _restore_history() -> void:
	if _had_history:
		DirAccess.copy_absolute(ProjectSettings.globalize_path(HISTORY_BACKUP),
			ProjectSettings.globalize_path(HISTORY))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(HISTORY_BACKUP))
	elif FileAccess.file_exists(HISTORY):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(HISTORY))
