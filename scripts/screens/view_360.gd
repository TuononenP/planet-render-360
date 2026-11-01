class_name View360
extends Control

signal back_requested
## Attribution tapped: open Settings → Data sources.
signal data_sources_requested
## Data-quality badge tapped: reopen the DataNotice.
signal data_quality_requested
## Go there for a landmark outside the built area: render a new scene
## at (lat, lon), its standoff, facing `site` (main runs the pipeline).
signal visit_requested(site: Dictionary, lat: float, lon: float)

var _viewport: SubViewport
var _container: SubViewportContainer
var _rig: CameraRig
var _world_root: Node3D
var _sun: DirectionalLight3D
var _atmos: AtmosphereRig
var _governor: QualityGovernor
var _weather: WeatherFetcher
## Landmark details (callout taps) and nearby articles for callouts.
var _wiki: WikiFetcher
var _landmark_panel: LandmarkPanel
var _visit_tween: Tween
# HUD (built and laid out by ViewChrome).
var _hud: Control
var _fade: Control
var _callouts: ViewCallouts
var _top: VBoxContainer
var _top_right: HBoxContainer
var _place_box: PanelContainer
var _place_pill: Label
var _place_coords: Label
var _compass: CompassDial
var _weather_chip: PanelContainer
var _weather_icon: TextureRect
var _weather_value: Label
var _weather_label: Label
var _quality_badge: Button
var _quality_label: Label
var _sheet: PanelContainer
var _sun_arc: SunArc
var _time_label: Label
var _fullscreen_btn: Button
var _gyro_btn: Button
var _gyro_on := false
var _exit_btn: Button
var _attribution: Button
var _hint: PanelContainer
var _hint_timer: Timer
var _idle_timer: Timer
var _fade_tween: Tween
var _hud_hidden := false
var _announcer: Announcer
var _scrims: Array = []
var _inspector_open := true
var _sun_times_key: Array = []
var _sun_times := Vector2(390.0, 1170.0)
var _live_time := true
var _time_hour := 12.0
## Still on the spawn's golden hour (no hour picked since opening).
var _spawn_golden := false
var _touches: Dictionary = {}
var _quality_preset: int = RenderSettings.Preset.HIGH
var _data: LocationData
var _generated: Node3D
var _ground: GroundTruth
## Season rebuild in flight on its thread / another season picked
## meanwhile (coalesced into one follow-up build).
var _season_building := false
var _season_dirty := false
## Live build_location threads, joined before the view is freed.
var _threads: Array[Thread] = []
var _season_btn: SegmentedControl
var _precip: GPUParticles3D
var _pinch_base := 0.0
var _magnify_accum := 1.0

## Eye height above ground in metres (PRD §3.3: 25–35 m, ≈8 m above the
## mean roofline). v1's 9.5 units were ≈38 m on the 4 m-unit world.
const EYE_HEIGHT_M := 30.0
## T5.2 framing: a viewpoint closer than FRAME_MIN_M to its landmark
## (e.g. picked on the Eiffel itself) spawns FRAME_READ_M back from it
## (PRD §4.1: the tower is judged from ≈700–900 m), so the camera moves
## — never the landmark.
const FRAME_MIN_M := 400.0
const FRAME_READ_M := 800.0
## Generic eye clearance: the eye stays CLEAR_ABOVE_M over every roof
## within CLEAR_RADIUS_M (CLEAR_REACH_M bounds a footprint's centroid-
## to-edge span for the pre-check).
const CLEAR_RADIUS_M := 25.0
const CLEAR_ABOVE_M := 6.0
const CLEAR_REACH_M := 400.0
## Opening-look clearance: within VIEW_CLEAR_M and VIEW_WEDGE (radians
## either side of the look), no roof or mapped forest canopy (CANOPY_M
## tall) may rise above the look line; the eye lifts until none does,
## at most VIEW_LIFT_MAX_M over its ground.
const VIEW_CLEAR_M := 80.0
const VIEW_WEDGE := 0.3
const CANOPY_M := 25.0
const VIEW_LIFT_MAX_M := 150.0
## Generic opening heading: built mass within this radius, in sectors.
const HEADING_RADIUS_M := 600.0
const HEADING_SECTORS := 16
## Far plane past the 30 km outer terrain ring's corners.
const CAMERA_FAR_M := 45000.0
## Go there moves the camera within the built world while its target is
## this close to the centre (half the ±1200 m detailed extent: the
## buildings and trees still surround it); past it a new scene is built.
const IN_PLACE_M := 600.0
const NEARBY_RADIUS_M := 10000

func _ready() -> void:
	_container = SubViewportContainer.new()
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	# With stretch enabled the container owns the SubViewport size and
	# resizes it with the window. Setting _viewport.size manually is
	# exactly what triggers the engine warning, so it is never done here.
	_container.stretch = true
	add_child(_container)
	_viewport = SubViewport.new()
	_container.add_child(_viewport)
	_build_3d()
	_governor = QualityGovernor.new()
	add_child(_governor)
	_governor.viewport = _viewport
	_governor.sun = _sun
	_governor.set_preset(_quality_preset)
	_governor.quality_changed.connect(func(step_name: String, fps: float) -> void:
		if _quality_label != null:
			_quality_label.text = "%s · %d fps" % [step_name, int(round(fps))])
	_weather = WeatherFetcher.new()
	add_child(_weather)
	_weather.succeeded.connect(_on_weather)
	_weather.failed.connect(func(_r: String) -> void: ViewChrome.weather_failed(self))
	_wiki = WikiFetcher.new()
	add_child(_wiki)
	_wiki.nearby_ready.connect(func(lat: float, lon: float, _r: int, sites: Array) -> void:
		if _data != null and is_equal_approx(lat, _data.latitude) and is_equal_approx(lon, _data.longitude):
			_callouts.add_sites(sites))

	_build_hud()

	var clock := Timer.new()
	clock.wait_time = 15.0
	clock.autostart = true
	clock.timeout.connect(func() -> void:
		if _live_time:
			_apply_current_time())
	add_child(clock)
	use_live_time()

	resized.connect(_on_resized)
	_on_resized()

## Heads-up layer: the design system's viewer HUD (see ViewChrome).
func _build_hud() -> void:
	ViewChrome.build(self)

# --- Delegators: implementation in ViewChrome / ViewConditions. ---
func refresh_theme() -> void:
	ViewChrome.refresh_theme(self)

func _dismiss_hint() -> void:
	ViewChrome._dismiss_hint(self)

func _show_hint() -> void:
	ViewChrome._show_hint(self)

func _on_look_changed() -> void:
	ViewChrome._on_look_changed(self)

func _on_resized() -> void:
	ViewChrome._on_resized(self)

func _on_season_selected(index: int) -> void:
	ViewConditions._on_season_selected(self, index)

func _build_precip() -> void:
	ViewConditions._build_precip(self)

func _apply_precip(code: int) -> void:
	ViewConditions._apply_precip(self, code)

func _on_weather(temp_c: float, label: String, cloud_cover: float, code: int) -> void:
	ViewConditions._on_weather(self, temp_c, label, cloud_cover, code)

func set_time_of_day(hour: int) -> void:
	ViewConditions.set_time_of_day(self, hour)

func use_live_time() -> void:
	ViewConditions.use_live_time(self)

func _apply_current_time() -> void:
	ViewConditions._apply_current_time(self)

func _sync_time_ui() -> void:
	ViewConditions._sync_time_ui(self)

func _apply_time(hour_f: float) -> void:
	ViewConditions._apply_time(self, hour_f)

func _build_3d() -> void:
	_world_root = Node3D.new()
	_viewport.add_child(_world_root)
	# Sun, sky, haze and clouds live in the AtmosphereRig (T6.1); the
	# view only feeds it time, weather, season and quality.
	_atmos = AtmosphereRig.new(_quality_preset)
	_world_root.add_child(_atmos)
	_sun = _atmos.sun
	_rig = CameraRig.new()
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.far = CAMERA_FAR_M
	cam.near = 0.25
	_rig.add_child(cam)
	_rig.position = Vector3(0, EYE_HEIGHT_M, 0)
	_world_root.add_child(_rig)
	_build_precip()

## Caps the FPS governor at the user's preset; terrain accuracy for a
## place is fixed when it was generated, so this only moves the live
## render scale / shadow ceiling.
func set_quality_preset(preset_value: int) -> void:
	_quality_preset = RenderSettings.clamp_preset(preset_value)
	if _atmos != null:
		_atmos.set_quality(_quality_preset)
	if _governor != null:
		_governor.set_preset(_quality_preset)
	# LOD rings re-range in place: nothing rebuilds or moves (AC-12).
	if _generated != null and is_instance_valid(_generated):
		LodRing.apply(_generated, _quality_preset)

## Replace the generated world in place. The old world is tracked by
## reference: same-named siblings get auto-renamed by the engine, so
## the previous name-based cleanup leaked a world per place visited.
func _rebuild_world(prebuilt: Node3D = null) -> void:
	if _data == null or _world_root == null:
		return
	if _generated != null and is_instance_valid(_generated):
		_world_root.remove_child(_generated)
		_generated.queue_free()
	if prebuilt != null:
		_generated = prebuilt
	else:
		if _ground == null:
			_ground = GroundTruth.new(_data)
		_generated = make_world(_data, _ground)
	# Range the near/mid rings for the current preset.
	LodRing.apply(_generated, _quality_preset)
	_world_root.add_child(_generated)
	ViewConditions.apply_surface_state(self)  # climate snow, rain, ice

## Detached world build: touches no scene tree, so it may run off the
## main thread (see build_location).
static func make_world(data: LocationData, ground: GroundTruth,
		abort: BuildAbort = null) -> Node3D:
	var world := TerrainBuilder.build_world(data, ground, abort)
	# T7.1: merge building masses per material/cell (preset-independent).
	BuildAbort.mark(abort, BuildAbort.Step.MERGE)
	LodRing.merge_buildings(world)
	return world

## Builds [ground, world] for `data` on a worker thread. The build takes
## seconds on dense cities; run on the main thread it froze the loading
## screen (macOS beachball), so the caller's screen keeps drawing here.
## Pass the result to show_location. A known `ground` is reused.
## Returns [] when `abort` was requested (timeout / cancel).
func build_location(data: LocationData, ground: GroundTruth = null,
		abort: BuildAbort = null) -> Array:
	var cached := await WorldCache.load_world(self, data, ground)
	if not cached.is_empty():
		return cached
	var thread := Thread.new()
	_threads.append(thread)
	thread.start(func() -> Array:
		var g := ground if ground != null else GroundTruth.new(data)
		return [g, make_world(data, g, abort)])
	while thread.is_alive():
		await get_tree().process_frame
	_threads.erase(thread)
	var built: Array = thread.wait_to_finish()
	if abort != null and abort.requested:
		# Stopped part-way (timeout / cancel): never show or cache it.
		if built.size() > 1 and built[1] is Node3D:
			(built[1] as Node3D).free()
		return []
	WorldCache.save_async(self, _threads, data, built)
	return built

func _notification(what: int) -> void:
	# A thread outliving its owner aborts the engine on free/quit. The
	# builders make RenderingServer read-backs (surface_get_arrays,
	# get_image) that wait on the main thread, so service them while
	# joining or this deadlocks.
	if what == NOTIFICATION_PREDELETE:
		for t in _threads:
			while t.is_alive():
				RenderingServer.force_sync()
				OS.delay_msec(1)
			if t.is_started():
				var built: Array = t.wait_to_finish()
				if built.size() > 1 and built[1] is Node3D:
					(built[1] as Node3D).free()
		_threads.clear()

func show_location(data: LocationData, prebuilt: Array = []) -> void:
	set_quality_preset(data.quality_preset)
	_data = data
	if _season_btn != null:
		_season_btn.select(data.season)
	_atmos.set_season(data.season)
	_atmos.set_place(data.latitude, data.longitude)
	_show_hint()
	if prebuilt.is_empty():
		_ground = GroundTruth.new(data)
		_rebuild_world()
	else:
		_ground = prebuilt[0]
		_rebuild_world(prebuilt[1])
	ViewChrome.show_place(self, data)
	# Spawn at golden hour (PRD §3.3): the judged condition for every
	# place, now the place's own (T6.2: the hour the true afternoon sun
	# sits at the reference elevation). The slider still leaves it.
	ViewConditions.spawn_golden_hour(self)
	var spawn := spawn_xz(data)
	_rig.position = Vector3(spawn.x, eye_y(data, _ground, spawn), spawn.y)
	var look: Vector2
	if not data.focus.is_empty():
		# Came to see a landmark: face it, its middle at the view centre.
		look = aim(_rig.position, focus_point(data, _ground, data.focus))
	elif not data.view.is_empty():
		# A quick-pick preset: its curated bearing and pitch.
		look = Vector2(-deg_to_rad(float(data.view["bearing"])),
			deg_to_rad(float(data.view.get("pitch", 0.0))))
	elif data.landmark_type != "none":
		# Open with the landmark left-of-centre (PRD §4.1: 0.36 W),
		# not dead ahead, so the river/city sweep fills the right. The
		# landmark stands at its true site (T5.2); the look aims at it.
		look = Vector2(landmark_yaw(data, spawn) - 0.12, -0.08)
	else:
		look = Vector2(default_yaw(data, _ground, spawn), -0.10)
	# Nothing right in front may block the opening look.
	var lift := view_clearance_y(data, _ground, spawn, look.x, look.y)
	if lift > _rig.position.y:
		_rig.position.y = lift
		if not data.focus.is_empty():
			look = aim(_rig.position, focus_point(data, _ground, data.focus))
	_atmos.set_probe_origin(_rig.position)
	_rig.set_look(look.x, look.y)
	if _landmark_panel != null:
		_landmark_panel.close()
	if _weather != null:
		_weather.fetch(data.latitude, data.longitude)
	if _wiki != null:
		_wiki.nearby(data.latitude, data.longitude, NEARBY_RADIUS_M)

## Camera ground position (metres): the viewpoint itself, unless the
## viewpoint sits on its landmark — then FRAME_READ_M back along the v1
## framing direction (landmark ENE of the camera), inside the extent.
static func spawn_xz(data: LocationData) -> Vector2:
	# A preset's curated eye (PresetViews) needs no framing step-back.
	if not data.view.is_empty():
		return PresetViews.eye_xz(data.view, data.latitude, data.longitude)
	# A landmark visit already stands off from its focus (LandmarkVisit).
	if data.landmark_type == "none" or not data.focus.is_empty():
		return Vector2.ZERO
	var lp := TerrainBuilder.landmark_world_pos(data)
	if lp.length() >= FRAME_MIN_M:
		return Vector2.ZERO
	return lp - TerrainBuilder.LANDMARK_POS.normalized() * FRAME_READ_M

## Camera Y over metre position `xz`. A preset's curated eye stands
## eye_m over the ground, never below its ASL floor (decks, clifftops).
## Anywhere else the eye is EYE_HEIGHT_M over the ground, lifted
## CLEAR_ABOVE_M over every roof within CLEAR_RADIUS_M, so a pin inside
## or beside a tower opens above it rather than inside its walls.
## `curated` false (Go there) ignores the preset eye.
static func eye_y(data: LocationData, ground: GroundTruth, xz: Vector2,
		curated: bool = true) -> float:
	var y := ground.height_at_world(xz.x, xz.y)
	if curated and not data.view.is_empty():
		y += float(data.view.get("eye_m", EYE_HEIGHT_M))
		if data.view.has("asl_m"):
			y = maxf(y, ground.render_y(float(data.view["asl_m"])))
		return y
	return maxf(y + EYE_HEIGHT_M, roof_clearance_y(data, ground, xz))

## Highest roof within CLEAR_RADIUS_M of `xz` (render Y) plus
## CLEAR_ABOVE_M, -INF when none. Uses the data-level heights (tag,
## levels or the parser default, parts included), measured to the
## footprint itself, not its centroid.
static func roof_clearance_y(data: LocationData, ground: GroundTruth, xz: Vector2) -> float:
	var top := -INF
	for b in data.buildings:
		var fp: PackedVector2Array = b.get("footprint", PackedVector2Array())
		var c := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
		if fp.size() < 3 or c.distance_to(xz) > CLEAR_RADIUS_M + CLEAR_REACH_M:
			continue
		if _ring_distance(xz, fp) > CLEAR_RADIUS_M:
			continue
		var h := float(b.get("height", 0.0))
		for part in b.get("parts", []):
			h = maxf(h, float((part as Dictionary).get("height", 0.0)))
		top = maxf(top, ground.height_at_world(c.x, c.y) + h)
	return top + CLEAR_ABOVE_M

## Lowest eye Y (render) at `xz` from which the look (`yaw`, `pitch`)
## passes CLEAR_ABOVE_M over every roof, and over the canopy of mapped
## forest, within VIEW_CLEAR_M inside ±VIEW_WEDGE of it; capped at
## VIEW_LIFT_MAX_M over the ground. -INF when nothing is in front.
## Roofs use the data-level heights, as roof_clearance_y.
static func view_clearance_y(data: LocationData, ground: GroundTruth, xz: Vector2,
		yaw: float, pitch: float) -> float:
	# A preset row may opt out ("clear": false) where buildings beside
	# the look frame the view rather than block it (a canal's banks).
	if not bool(data.view.get("clear", true)):
		return -INF
	var bearing := -yaw
	var dir := Vector2(sin(bearing), -cos(bearing))
	var drop := tan(clampf(pitch, -1.2, 1.2))
	var need := -INF
	for b in data.buildings:
		var fp: PackedVector2Array = b.get("footprint", PackedVector2Array())
		var c := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
		if fp.size() < 3 or c.distance_to(xz) > VIEW_CLEAR_M + CLEAR_REACH_M:
			continue
		var d := _wedge_distance(xz, dir, fp)
		if d > VIEW_CLEAR_M:
			continue
		var h := float(b.get("height", 0.0))
		for part in b.get("parts", []):
			h = maxf(h, float((part as Dictionary).get("height", 0.0)))
		need = maxf(need, ground.height_at_world(c.x, c.y) + h + CLEAR_ABOVE_M - d * drop)
	for k in range(-2, 3):
		var ray := dir.rotated(VIEW_WEDGE * float(k) / 2.0)
		for step in range(1, 9):
			var d := VIEW_CLEAR_M * float(step) / 8.0
			var p := xz + ray * d
			if ground.is_inside(p.x, p.y) and ground.land_class_at(p.x, p.y) == "forest":
				need = maxf(need, ground.height_at_world(p.x, p.y) + CANOPY_M + CLEAR_ABOVE_M - d * drop)
	if need == -INF:
		return need
	return minf(need, ground.height_at_world(xz.x, xz.y) + VIEW_LIFT_MAX_M)

## Nearest distance from `p` to the part of a closed ring that lies
## within ±VIEW_WEDGE of `dir`, INF when none does. Checks the ring's
## vertices, its closest point and where the look's centre line
## crosses it.
static func _wedge_distance(p: Vector2, dir: Vector2, ring: PackedVector2Array) -> float:
	if Geometry2D.is_point_in_polygon(p, ring):
		return 0.0
	var best := INF
	var tip := p + dir * VIEW_CLEAR_M
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var hit: Variant = Geometry2D.segment_intersects_segment(p, tip, a, b)
		var pts: Array[Vector2] = [a, Geometry2D.get_closest_point_to_segment(p, a, b)]
		if hit != null:
			pts.append(hit as Vector2)
		for q in pts:
			var v := q - p
			if v.length() < best and absf(dir.angle_to(v)) <= VIEW_WEDGE:
				best = v.length()
	return best

## Distance from `p` to a closed ring, 0 inside it.
static func _ring_distance(p: Vector2, ring: PackedVector2Array) -> float:
	if Geometry2D.is_point_in_polygon(p, ring):
		return 0.0
	var best := INF
	for i in ring.size():
		var q := Geometry2D.get_closest_point_to_segment(p, ring[i], ring[(i + 1) % ring.size()])
		best = minf(best, p.distance_to(q))
	return best

## Opening yaw where there is no preset view and no landmark: toward the
## most built mass (footprint × height) within HEADING_RADIUS_M, else
## toward the most water, else the v1 default. Neighbouring sectors
## count half, so a district outweighs one lone tower.
static func default_yaw(data: LocationData, ground: GroundTruth, xz: Vector2) -> float:
	var mass := PackedFloat32Array()
	mass.resize(HEADING_SECTORS)
	for b in data.buildings:
		var d := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0))) - xz
		if d.length() < 1.0 or d.length() > HEADING_RADIUS_M:
			continue
		mass[_sector(d)] += float(b.get("size_x", 0.0)) * float(b.get("size_z", 0.0)) \
			* float(b.get("height", 0.0))
	var best := _best_sector(mass)
	if best < 0 and ground != null:
		for s in HEADING_SECTORS:
			var bearing := float(s) * TAU / HEADING_SECTORS
			for k in range(1, 7):
				var p := xz + Vector2(sin(bearing), -cos(bearing)) * HEADING_RADIUS_M * k / 6.0
				if ground.is_inside(p.x, p.y) and ground.water_at(p.x, p.y) > 0.0:
					mass[s] += 1.0
		best = _best_sector(mass)
	if best < 0:
		return 0.6
	return -float(best) * TAU / HEADING_SECTORS

## Sector index of a metre direction (sector 0 faces north, clockwise).
static func _sector(d: Vector2) -> int:
	var bearing := wrapf(atan2(d.x, -d.y), 0.0, TAU)
	return int(round(bearing / TAU * HEADING_SECTORS)) % HEADING_SECTORS

## Sector holding the most (its neighbours at half weight), -1 when
## all are empty.
static func _best_sector(mass: PackedFloat32Array) -> int:
	var best := -1
	var best_sum := 0.0
	for s in HEADING_SECTORS:
		var sum := mass[s] + 0.5 * (mass[(s + HEADING_SECTORS - 1) % HEADING_SECTORS]
			+ mass[(s + 1) % HEADING_SECTORS])
		if sum > best_sum:
			best_sum = sum
			best = s
	return best

## Yaw that faces the landmark's true site from `from` (CameraRig:
## forward is -Z rotated by yaw; north = -Z).
static func landmark_yaw(data: LocationData, from: Vector2) -> float:
	var d := TerrainBuilder.landmark_world_pos(data) - from
	return atan2(-d.x, -d.y)

## World point to aim at for a landmark site: its middle, or the summit
## of a peak (the terrain carries it).
static func focus_point(data: LocationData, ground: GroundTruth, site: Dictionary) -> Vector3:
	var xz := WorldScale.xz_from_latlon(float(site["lat"]), float(site["lon"]),
		data.latitude, data.longitude)
	var y := 0.0
	if ground != null:
		y = ground.height_at_world(xz.x, xz.y) if ground.is_inside(xz.x, xz.y) \
			else TerrainBuilder.site_ground_y(data, ground, xz.x, xz.y)
	if str(site.get("kind", "")) != "Peak":
		y += maxf(float(site.get("height_m", 0.0)), 30.0) * 0.5
	return Vector3(xz.x, y, xz.y)

## (yaw, pitch) that looks from `from` at `to` (CameraRig: forward is -Z
## rotated by yaw, positive pitch looks up), pitch kept gentle.
static func aim(from: Vector3, to: Vector3) -> Vector2:
	var d := to - from
	var flat := Vector2(d.x, d.z).length()
	return Vector2(atan2(-d.x, -d.z), clampf(atan2(d.y, maxf(flat, 1.0)), -0.35, 0.6))

## Whether the camera can walk to `t` (metres from the scene centre)
## without leaving the built neighbourhood.
static func can_move_in_place(t: Vector2, ground: GroundTruth) -> bool:
	return t.length() <= IN_PLACE_M and ground != null and ground.is_inside(t.x, t.y)

## Callout tapped: the landmark panel with its details.
func open_landmark(site: Dictionary) -> void:
	if _landmark_panel != null:
		_landmark_panel.open(site, _callouts.distance_to(site))

## Go there: stand off from the landmark on the line from the camera to
## it (the heading holds), and face it. Inside the built area the camera
## glides there; farther, a new scene is built around the standoff.
func visit(site: Dictionary) -> void:
	if _data == null or _rig == null:
		return
	var lp := WorldScale.xz_from_latlon(float(site["lat"]), float(site["lon"]),
		_data.latitude, _data.longitude)
	var cam := Vector2(_rig.position.x, _rig.position.z)
	var dir := (lp - cam).normalized()
	if (lp - cam).length() < 1.0:
		var b := deg_to_rad(LandmarkVisit.default_bearing(_data.latitude))
		dir = -Vector2(sin(b), -cos(b))
	var t := lp - dir * LandmarkVisit.standoff_m(site)
	if not can_move_in_place(t, _ground):
		var ll := WorldScale.latlon_from_xz(t.x, t.y, _data.latitude, _data.longitude)
		visit_requested.emit(site, ll.x, ll.y)
		return
	var to := Vector3(t.x, eye_y(_data, _ground, t, false), t.y)
	var look := aim(to, focus_point(_data, _ground, site))
	var yaw_to := _rig.yaw + wrapf(look.x - _rig.yaw, -PI, PI)
	if _visit_tween != null:
		_visit_tween.kill()
	var from := _rig.position
	var yaw_from := _rig.yaw
	var pitch_from := _rig.pitch
	_visit_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_visit_tween.tween_method(func(k: float) -> void:
		_rig.position = from.lerp(to, k)
		_rig.set_look(lerpf(yaw_from, yaw_to, k), lerpf(pitch_from, look.y, k))
		_on_look_changed(), 0.0, 1.0, maxf(UiPrefs.motion(1.6), 0.01))
	_visit_tween.tween_callback(func() -> void: _atmos.set_probe_origin(_rig.position))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_rig.handle_zoom(1.12)
			accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_rig.handle_zoom(1.0 / 1.12)
			accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and mb.double_click:
			_rig.reset_zoom()
			accept_event()
	elif event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		_magnify_accum *= mg.factor
		if _magnify_accum > 1.15:
			_magnify_accum = 1.0
			_rig.handle_zoom(1.18)
		elif _magnify_accum < 0.87:
			_magnify_accum = 1.0
			_rig.handle_zoom(1.0 / 1.18)
		accept_event()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_touches[st.index] = st.position
			if _touches.size() == 2:
				_pinch_base = _touch_distance()
		else:
			_touches.erase(st.index)
		accept_event()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if _touches.has(sd.index):
			_touches[sd.index] = sd.position
		if _touches.size() >= 2:
			var dist := _touch_distance()
			if _pinch_base > 1.0 and dist > 1.0:
				_rig.handle_zoom(dist / _pinch_base)
				_pinch_base = dist
		else:
			_rig.handle_drag(sd.relative)
			_on_look_changed()
		accept_event()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_rig.handle_drag(event.relative)
		_on_look_changed()

## Any input while the view is up brings the HUD back (ViewChrome.wake).
func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and (event is InputEventMouseMotion or event is InputEventMouseButton \
			or event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventKey):
		ViewChrome.wake(self)

## Viewer keys (arrows, +/−, [ ], 1–4, H, F, I, Esc for callouts).
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or not is_visible_in_tree():
		return
	if ViewChrome.handle_key(self, key):
		get_viewport().set_input_as_handled()

## Gyro look on mobile: pauses while a finger is on the scene.
func _process(delta: float) -> void:
	if _gyro_on and _touches.is_empty() and is_visible_in_tree():
		var g := Input.get_gyroscope()
		if g.length() > 0.01:
			_rig.set_look(_rig.yaw + g.y * delta, _rig.pitch + g.x * delta)
			_on_look_changed()

func _touch_distance() -> float:
	if _touches.size() < 2:
		return 0.0
	var pts: Array = _touches.values()
	return (pts[0] as Vector2).distance_to(pts[1])
