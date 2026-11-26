class_name StreetProps
extends RefCounted

## Street furniture + linear barriers (T5.1/T7.2, PRD §3.4 props).
## * Lampposts: only along real OSM carriageways in built-up blocks
##   (lit streets), every 25 m alternating sides on the verge, never in
##   a footprint / carriageway / junction surface / water, nor along a
##   paved square's outline. Finland's lit park paths add lamps only
##   where they cross green cover. Regional style:
##   cast-iron lantern
##   (Paris + historic European cores), black heritage post (British and
##   Irish side streets), galvanised cobra-head (North America), concrete
##   utility pole with a bracket lamp (Japanese and Korean side streets,
##   clear of signalled junctions) or modern arm luminaire. Instanced
##   (MultiMesh per style). Radius per preset: Fast none, Balanced
##   120 m, High 220 m, Ultra 600 m.
## * Barriers: real OSM barrier=wall/city_wall/retaining_wall (stone
##   PBR), fence/railing/guard_rail (alpha-tested picket panels on
##   posts), hedge (leaf-textured clipped hedge) — draped on GroundTruth,
##   merged into one mesh per kind. Absent in data → absent in the world.
## * Benches, bins, bollards, signals and bus stops: StreetFurniture
##   (desktop Ultra).

const LAMP_SPACING_M := 25.0
## A lit park path's lanterns stand closer (Esplanadi's alleys carry one
## every 15 m or so on alternating sides).
const PARK_LAMP_SPACING_M := 16.0
## A signal this near makes a utility-pole street a main-road lamp's.
const SIGNAL_LAMP_M := 40.0
const PROP_R := [0.0, 120.0, 220.0, 600.0]
const LIT := ["primary", "secondary", "tertiary", "residential", "unclassified",
	"living_street", "pedestrian", "trunk", "primary_link", "secondary_link",
	"tertiary_link"]
const MAJOR := ["primary", "secondary", "trunk", "primary_link", "secondary_link"]
const LANTERN_REGIONS := ["haussmann", "france", "central_europe", "west_europe_brick", "alpine"]
const HERITAGE_COUNTRIES := ["GB", "IE", "IM", "JE", "GG"]
const COBRA_COUNTRIES := ["US", "CA"]
const UTILITY_COUNTRIES := ["JP", "KR", "TW", "TH"]
## Linear colour of free-standing walls: grey-beige weathered masonry.
const WALL_STONE := Color(0.26, 0.24, 0.21)
## A mapped wall this close to a low quay's upper wall (ShorelineModel
## .quays) is that wall, metres.
const QUAY_WALL_REACH_M := 1.5
## barrier class → [kind, height m, thickness m]
const BARRIERS := {
	"wall": ["wall", 1.8, 0.4], "city_wall": ["wall", 6.0, 1.6],
	"retaining_wall": ["wall", 1.2, 0.5], "fence": ["fence", 1.5, 0.05],
	"railing": ["fence", 1.1, 0.05], "guard_rail": ["fence", 0.8, 0.05],
	"handrail": ["fence", 1.0, 0.05], "hedge": ["hedge", 1.4, 0.9],
}

static var _lamp_meshes: Dictionary = {}
static var _fence_tex: Texture2D
static var _chainlink_tex: Texture2D
static var _mats: Dictionary = {}
static var _native_props := ClassDB.class_exists("PropKernels")

const BARRIER_CHUNKS := 2

static func build(root: Node3D, data: LocationData, ground: GroundTruth,
		mask: VegetationMask, ctx: Dictionary) -> Dictionary:
	var timings := {}
	var t := Time.get_ticks_msec()
	# A streamed stretch dropped while its detail builds stops between the
	# slower kinds (its result is freed, never shown).
	var abort: BuildAbort = ctx.get("abort")
	# Planned before the lamps: a side-street lamp gives way only where a
	# utility pole really stands (the poles stop at their radius and cap).
	var pole_plan := UtilityPoles.plan(data, ground, mask)
	var marking_plan := RoadMarkings.shared_plan(data, ground)
	ctx = ctx.duplicate()
	ctx["pole_grid"] = UtilityPoles.pole_grid(pole_plan)
	ctx["marking_plan"] = marking_plan
	# Pre-warm shared shaders/materials before fanning out across workers.
	StreetGlow.set_place_for(data)
	CarPaint.shader()
	CarPaint.shadow_material()
	StreetSnow.material(StandardMaterial3D.new())
	t = _lap(timings, "pole_plan", t)
	if abort != null and abort.requested:
		return {}
	# 12 ordered holders preserve exact AC-12 child order, executed in 4 balanced
	# worker lanes so StreetProps does not oversubscribe WorkerThreadPool beside
	# Buildings and Roads.
	const SLOTS := 12
	var holders: Array[Node3D] = []
	holders.resize(SLOTS)
	for s in SLOTS:
		holders[s] = Node3D.new()
	var counts: Array = []
	counts.resize(SLOTS)
	var slot_ms: Array[int] = []
	slot_ms.resize(SLOTS)
	var m2u := float(ctx["m2u"])
	var transit_plan := TransitVehicles.plan_all(data, ground, m2u)
	var run_slot := func(slot: int) -> void:
		if abort != null and abort.requested:
			return
		var ts := Time.get_ticks_msec()
		var h: Node3D = holders[slot]
		match slot:
			0: counts[0] = _lampposts(h, data, ground, mask, ctx)
			1: counts[1] = _barriers(h, data, ground, ctx)
			2:
				ShoreRailings.build(h, data, ground)
				counts[2] = 0
			3: counts[3] = StreetFurniture.build(h, data, ground, mask, m2u, marking_plan)
			4:
				var p := PlazaLife.build(h, data, ground, mask, ctx)
				p += BangkokStreetLife.build(h, data, ground, mask, m2u)
				p += AmsterdamStreetLife.build(h, data, ground, mask, m2u)
				counts[4] = p
			5:
				var b := MarinaBuilder.build(h, data, ground, mask)
				b += HarbourFerries.build(h, data, ground, mask)
				WaterWakes.build_mapped_collars(h, data, ground)
				counts[5] = b
			6: counts[6] = QuayDetails.build(h, data, ground, mask)
			7: counts[7] = ParkedCars.build(h, data, ground, marking_plan.junctions, transit_plan["footprints"])
			8: counts[8] = TransitVehicles.build(h, data, ground, transit_plan)
			9: counts[9] = StationTrains.build(h, data, ground)
			10: counts[10] = AirportPlanes.build(h, data, ground)
			11:
				var w := OverheadWires.build(h, data, ground, mask, marking_plan)
				var u := UtilityPoles.build(h, data, ground, pole_plan)
				var sn := Snowbanks.build(h, data, ground)
				var be := BeachDressing.build(h, data, ground, mask)
				counts[11] = [w, u, sn, be]
		slot_ms[slot] = Time.get_ticks_msec() - ts
	var lanes: Array = [[1, 7, 10, 11], [0, 2, 3, 4, 5, 6, 8, 9]]
	var lane_job := func(lane: int) -> void:
		for slot: int in lanes[lane]:
			run_slot.call(slot)
	var group := WorkerThreadPool.add_group_task(lane_job, lanes.size(), -1, false, "StreetProps")
	WorkerThreadPool.wait_for_group_task_completion(group)
	if abort != null and abort.requested:
		for h in holders:
			h.free()
		return {}
	# Attach children in exact original slot order for AC-12 determinism.
	for h in holders:
		for ch in h.get_children():
			h.remove_child(ch)
			root.add_child(ch)
		h.free()
	var names := ["lamps", "barriers", "shore_railings", "furniture", "plazas",
		"marina_ferries", "quay", "cars", "trams", "trains", "aircraft", "wires_rest"]
	for s in SLOTS:
		timings[names[s]] = slot_ms[s]
	timings["wall_ms"] = Time.get_ticks_msec() - t
	print("PROPS timings ms ", timings)
	var rest: Array = counts[11] if counts[11] is Array else [0, 0, 0, 0]
	return {
		"lamps": counts[0], "barrier_m": counts[1],
		"furniture": counts[3], "plazas": counts[4],
		"boats": counts[5], "quay_bollards": counts[6],
		"cars": counts[7], "trams": counts[8],
		"trains": counts[9], "aircraft": counts[10],
		"wires": rest[0], "utility_poles": rest[1],
		"snowbanks": rest[2], "beach": rest[3],
	}

## Records the ms since `t` under `key`; returns the time now.
static func _lap(timings: Dictionary, key: String, t: int) -> int:
	var now := Time.get_ticks_msec()
	timings[key] = now - t
	return now

# --- Lampposts -----------------------------------------------------------

static func _lampposts(root: Node3D, data: LocationData, ground: GroundTruth,
		mask: VegetationMask, ctx: Dictionary) -> int:
	var m2u: float = ctx["m2u"]
	var region := ArchitectureStyle.country_region_for(data.latitude, data.longitude, data.country)
	var family := lamp_family(region, data.country, CityStyles.region_at(data.latitude, data.longitude))
	# The road surface's painted lamp pools (StreetGlow), on every tier:
	# the street lamps' colour, faint where real lamp lights burn.
	StreetGlow.set_place_for(data)
	var real := RenderQuality.ultra_desktop(int(ctx["preset"]))
	var radius_m: float = PROP_R[int(ctx["preset"])]
	if radius_m <= 0.0 or data.buildings.is_empty():
		return 0
	var r_u := radius_m * m2u
	var centre := View360.spawn_xz(data)
	var placed := {"lantern": [], "heritage": [], "cobra": [], "utility": [], "modern": [], "modern_s": [], "post_top": [], "nyc_f": [], "nyc_crook": []}
	var occupied := {}
	var occ_cell := 10.0 * m2u
	var sites := _lamp_sites(data, ground, m2u, ctx.get("marking_plan"))
	var models := LandmarkSites.model_rect_sites(data)
	var pole_grid: Dictionary = ctx.get("pole_grid", {})
	for r in data.roads:
		var pts: PackedVector2Array
		var cls := "residential"
		var width_m := 6.0
		if r is Dictionary:
			var rd: Dictionary = r
			# A paved square's outline is no street to line with lamps.
			if bool(rd.get("tunnel", false)) or bool(rd.get("bridge", false)) or bool(rd.get("area", false)):
				continue
			pts = rd.get("points", PackedVector2Array())
			cls = str(rd.get("class", "residential"))
			width_m = float(rd.get("width_m", 6.0))
		elif r is PackedVector2Array:
			pts = r
		else:
			continue
		# Lit park paths only: Helsinki tags its sidewalks, crossings and
		# square footways lit too, and those take no lamps of their own.
		var park_path := family == "span" and cls in ["footway", "path"] and r is Dictionary and bool(r.get("lit", false)) \
				and not bool(r.get("kerb_line", false)) and not bool(r.get("crossing", false))
		if (cls not in LIT and not park_path) or pts.size() < 2:
			continue
		if family == "span" and RenderQuality.ultra_desktop(data.quality_preset) and cls != "pedestrian" and not park_path:
			continue
		# Finland's park paths take the cast-iron lantern, not the span-wire post (Stockholm's keep it).
		var lantern := park_path and FinnishGranite.applies(data)
		var style := "lantern" if lantern else lamp_style(family, region, cls)
		var off := (width_m * 0.5 + 1.1) * m2u
		var step := (PARK_LAMP_SPACING_M if lantern else LAMP_SPACING_M) * m2u
		var carry := step * 0.5
		var side := 1.0
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var seg := a.distance_to(b)
			if seg < 0.001:
				continue
			var dir := (b - a) / seg
			var nrm := Vector2(-dir.y, dir.x)
			var t := carry
			while t < seg:
				var c := a + dir * t
				t += step
				side = -side
				var p := c + nrm * off * side
				if (p - centre).length() > r_u or mask.built_fraction(p.x, p.y) < 0.04:
					continue
				if park_path and mask.cover_at(p.x, p.y) < 0:
					continue
				if mask.blocked(p.x, p.y, VegetationMask.BUILDING | VegetationMask.ROAD
						| VegetationMask.WATER, 0.0) or ground.water_at(p.x, p.y) > 0.0 \
						or LandmarkSites.in_model_rects(p, models):
					continue
				if _on_apron(sites["aprons"], p, m2u) or on_crossing(sites["crossings"], p, m2u):
					continue
				# A utility pole (with its own bracket lamp) already stands here.
				if style == "utility" and UtilityPoles.near_pole(pole_grid, p):
					continue
				var ok := Vector2i(int(floor(p.x / occ_cell)), int(floor(p.y / occ_cell)))
				if occupied.has(ok):
					continue
				occupied[ok] = true
				var lamp := "modern" if style == "utility" and _signal_near(sites["signals"], p, m2u) else style
				var toward := -nrm * side
				var yaw := atan2(-toward.y, toward.x)
				var h := 0.75 if lamp == "modern_s" or (lamp == "cobra" and cls not in MAJOR) else 1.0
				var basis := Basis(Vector3.UP, yaw).scaled(Vector3(m2u, m2u * h, m2u))
				(placed[lamp] as Array).append(Transform3D(basis,
					Vector3(p.x, ground.height_at_world(p.x, p.y), p.y)))
			carry = t - seg
	if real:
		StreetLights.add(root, placed, region, m2u, centre)
	var total := 0
	for style in placed:
		var xf: Array = placed[style]
		if xf.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _lamp_mesh("modern" if style == "modern_s" else style)
		mm.instance_count = xf.size()
		for k in xf.size():
			mm.set_instance_transform(k, xf[k])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.name = "Prop_lamp_%s" % style
		root.add_child(mmi)
		total += xf.size()
	return total

## Lookup grids from the road plan: junction aprons, pedestrian crossings
## no pole stands on, and signals whose streets take the main-road lamp.
static func _lamp_sites(data: LocationData, ground: GroundTruth, m2u: float,
		marking_plan: RoadMarkings.Plan = null) -> Dictionary:
	var plan := marking_plan if marking_plan != null else RoadMarkings.shared_plan(data, ground)
	var signals := {}
	for q in plan.signals:
		RoadMarkings._grid_add(signals, q, q, q, m2u)
	return {"aprons": apron_grid(plan, m2u), "signals": signals,
		"crossings": crossing_grid(data, plan, m2u)}

static func apron_grid(plan: RoadMarkings.Plan, m2u: float) -> Dictionary:
	var aprons := {}
	if plan == null:
		return aprons
	for ring: PackedVector2Array in plan.aprons:
		var box := Rect2(ring[0], Vector2.ZERO)
		for q in ring:
			box = box.expand(q)
		RoadMarkings._grid_add(aprons, box.position, box.end, ring, m2u)
	return aprons

static func crossing_grid(data: LocationData, plan: RoadMarkings.Plan, m2u: float) -> Dictionary:
	var grid := {}
	for raw in data.roads:
		if not (raw is Dictionary):
			continue
		var rd: Dictionary = raw
		if bool(rd.get("tunnel", false)) or bool(rd.get("bridge", false)):
			continue
		if not bool(rd.get("crossing", false)) and str(rd.get("crossing_style", "")) == "":
			continue
		var pts: PackedVector2Array = rd.get("points", PackedVector2Array())
		var clear := (maxf(float(rd.get("width_m", 3.0)) * 0.5, 1.8) + 0.9) * m2u
		for j in pts.size() - 1:
			RoadMarkings._grid_add(grid, pts[j], pts[j + 1], [pts[j], pts[j + 1], clear], m2u)
	if plan != null:
		var inf_clear := (RoadMarkings.INFERRED_DEPTH_M * 0.5 + 0.9) * m2u
		for c: PackedVector2Array in plan.inferred:
			for j in c.size() - 1:
				RoadMarkings._grid_add(grid, c[j], c[j + 1], [c[j], c[j + 1], inf_clear], m2u)
	return grid

static func on_crossing(grid: Dictionary, p: Vector2, m2u: float) -> bool:
	if grid.is_empty():
		return false
	for seg: Array in RoadMarkings._grid_near(grid, p, 4.5 * m2u, m2u):
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, seg[0], seg[1])) <= float(seg[2]):
			return true
	return false

static func _on_apron(aprons: Dictionary, p: Vector2, m2u: float) -> bool:
	if aprons.is_empty():
		return false
	for ring: PackedVector2Array in RoadMarkings._grid_near(aprons, p, 0.0, m2u):
		if Geometry2D.is_point_in_polygon(p, ring):
			return true
	return false

static func _signal_near(signals: Dictionary, p: Vector2, m2u: float) -> bool:
	var reach := SIGNAL_LAMP_M * m2u
	for q: Vector2 in RoadMarkings._grid_near(signals, p, reach, m2u):
		if q.distance_to(p) <= reach:
			return true
	return false

## The place's lamp family: "lantern", "heritage", "cobra", "utility" or
## "modern" (by ISO country first, then the country region).
static func lamp_family(region: String, country: String, city: String = "") -> String:
	if city == "new_york":
		return "nyc"
	var iso := country.to_upper()
	if iso in ["FI", "SE"]:
		return "span"
	if iso in HERITAGE_COUNTRIES:
		return "heritage"
	if iso in COBRA_COUNTRIES or (iso == "" and region == "north_america"):
		return "cobra"
	if iso in UTILITY_COUNTRIES or (iso == "" and region == "japan"):
		return "utility"
	if region in LANTERN_REGIONS:
		return "lantern"
	return "modern"

## Lamp style for one road of class `cls` in `family`: the period styles
## line side streets (all of Paris), main roads take the arm luminaire.
static func lamp_style(family: String, region: String, cls: String) -> String:
	var major := cls in MAJOR
	match family:
		"span":
			return "post_top"
		"nyc":
			return "nyc_f" if major else "nyc_crook"
		"cobra":
			return "cobra"
		"lantern":
			if region == "haussmann" or not major:
				return "lantern"
		"heritage", "utility":
			if not major:
				return family
	return "modern" if major else "modern_s"

## Lamp meshes in metres: metal surface + emissive glass surface.
static func _lamp_mesh(style: String) -> ArrayMesh:
	if _lamp_meshes.has(style):
		return _lamp_meshes[style]
	var metal := TreeMeshLibrary.Buf.new()
	var glass := TreeMeshLibrary.Buf.new()
	var metal_col: Color
	var glass_col: Color
	if style == "lantern" or style == "heritage":
		# Paris green-black cast iron; the British post is gloss black.
		metal_col = Color(0.11, 0.14, 0.12) if style == "lantern" else Color(0.03, 0.03, 0.035)
		glass_col = Color(1.0, 0.86, 0.62)
		# Plinth, fluted shaft, collar, lantern housing + cap + finial.
		TreeMeshLibrary._tube(metal, [Vector3(0, -0.3, 0), Vector3(0, 0.55, 0)], [0.2, 0.17], 8, 0.8, 1.0)
		TreeMeshLibrary._tube(metal, [Vector3(0, 0.55, 0), Vector3(0, 0.75, 0)], [0.17, 0.08], 8, 0.9, 1.0)
		TreeMeshLibrary._tube(metal, [Vector3(0, 0.75, 0), Vector3(0, 3.7, 0)], [0.075, 0.055], 8, 0.9, 1.0)
		TreeMeshLibrary._tube(metal, [Vector3(0, 3.7, 0), Vector3(0, 3.85, 0)], [0.1, 0.12], 8, 1.0, 1.0)
		TreeMeshLibrary._tube(glass, [Vector3(0, 3.85, 0), Vector3(0, 4.45, 0)], [0.13, 0.27], 4, 1.0, 1.0)
		TreeMeshLibrary._tube(metal, [Vector3(0, 4.45, 0), Vector3(0, 4.7, 0)], [0.32, 0.05], 4, 1.0, 1.0)
		TreeMeshLibrary._tube(metal, [Vector3(0, 4.7, 0), Vector3(0, 4.9, 0)], [0.04, 0.01], 6, 1.0, 1.0)
	elif style == "post_top":
		metal_col = Color(0.18, 0.22, 0.19)
		glass_col = Color(1.0, 0.95, 0.8)
		TreeMeshLibrary._tube(metal, [Vector3.ZERO, Vector3(0, 4.2, 0)], [0.07, 0.045], 8, 1.0, 1.0)
		TreeMeshLibrary._tube(glass, [Vector3(0, 4.2, 0), Vector3(0, 4.55, 0)], [0.16, 0.26], 8, 1.0, 1.0)
		_box(metal, Vector3(0, 4.58, 0), Vector3(0.6, 0.08, 0.6))
	elif style in ["nyc_f", "nyc_crook"]:
		# NYC cast-iron Type F and Bishop's crook: tapered dark shaft,
		# curved arm and a pendant teardrop luminaire.
		metal_col = Color(0.09, 0.12, 0.11)
		glass_col = Color(1.0, 0.90, 0.70)
		var h := 6.8 if style == "nyc_f" else 5.0
		TreeMeshLibrary._tube(metal, [Vector3(0, -0.2, 0), Vector3(0, 0.6, 0), Vector3(0, h, 0)],
			[0.18, 0.14, 0.07], 8, 0.8, 1.0)
		var arm := TreeMeshLibrary._bezier(Vector3(0, h - 0.15, 0), Vector3(0.05, h + 1.05, 0),
			Vector3(1.45, h + 0.8, 0), 6)
		TreeMeshLibrary._tube(metal, arm, [0.08, 0.075, 0.07, 0.065, 0.06, 0.055, 0.05], 6, 1.0, 1.0)
		TreeMeshLibrary._tube(metal, [Vector3(1.45, h + 0.8, 0), Vector3(1.45, h + 0.40, 0)], [0.05, 0.05], 6, 1.0, 1.0)
		TreeMeshLibrary._tube(glass, [Vector3(1.45, h + 0.4, 0), Vector3(1.45, h + 0.18, 0),
			Vector3(1.45, h - 0.15, 0)], [0.11, 0.24, 0.08], 8, 1.0, 1.0)
	elif style == "cobra":
		# Galvanised tapered pole, an upswept arm, the cobra head tipped up.
		metal_col = Color(0.50, 0.51, 0.50)
		glass_col = Color(1.0, 0.95, 0.85)
		TreeMeshLibrary._tube(metal, [Vector3(0, -0.3, 0), Vector3(0, 0.5, 0)], [0.2, 0.19], 8, 0.8, 1.0)
		TreeMeshLibrary._tube(metal, [Vector3(0, 0.5, 0), Vector3(0, 8.6, 0)], [0.12, 0.07], 8, 0.9, 1.0)
		var carm: Array = TreeMeshLibrary._bezier(Vector3(0, 8.0, 0), Vector3(0.2, 9.0, 0), Vector3(2.2, 9.05, 0), 6)
		TreeMeshLibrary._tube(metal, carm, [0.06, 0.055, 0.05, 0.05, 0.045, 0.045, 0.04], 6, 1.0, 1.0)
		TreeMeshLibrary._tube(metal, [Vector3(2.1, 9.05, 0), Vector3(2.45, 9.08, 0), Vector3(2.85, 9.05, 0),
			Vector3(3.05, 8.98, 0)], [0.1, 0.19, 0.17, 0.06], 8, 1.0, 1.0)
		_box(glass, Vector3(2.6, 8.9, 0), Vector3(0.5, 0.04, 0.24))
	elif style == "utility":
		# Concrete utility pole: crossarm and insulators up top, a small
		# bracket lamp over the street at 5.5 m.
		metal_col = Color(0.47, 0.46, 0.43)
		glass_col = Color(1.0, 0.97, 0.92)
		TreeMeshLibrary._tube(metal, [Vector3(0, -0.3, 0), Vector3(0, 11.0, 0)], [0.17, 0.11], 8, 0.9, 1.0)
		_box(metal, Vector3(0, 10.2, 0), Vector3(0.12, 0.12, 1.8))
		for z in [-0.75, -0.25, 0.25, 0.75]:
			_box(metal, Vector3(0, 10.33, z), Vector3(0.07, 0.14, 0.07))
		_box(metal, Vector3(0, 8.6, 0), Vector3(0.12, 0.12, 1.2))
		TreeMeshLibrary._tube(metal, [Vector3(0, 5.3, 0), Vector3(0.6, 5.65, 0), Vector3(1.05, 5.7, 0)],
			[0.035, 0.03, 0.03], 6, 1.0, 1.0)
		_box(metal, Vector3(1.15, 5.68, 0), Vector3(0.42, 0.09, 0.2))
		_box(glass, Vector3(1.15, 5.62, 0), Vector3(0.34, 0.03, 0.15))
	else:
		metal_col = Color(0.42, 0.44, 0.46)
		glass_col = Color(1.0, 0.97, 0.9)
		TreeMeshLibrary._tube(metal, [Vector3(0, -0.3, 0), Vector3(0, 0.4, 0)], [0.13, 0.12], 8, 0.8, 1.0)
		TreeMeshLibrary._tube(metal, [Vector3(0, 0.4, 0), Vector3(0, 7.6, 0)], [0.1, 0.06], 8, 0.9, 1.0)
		var arm: Array = TreeMeshLibrary._bezier(Vector3(0, 7.5, 0), Vector3(0.1, 8.2, 0), Vector3(1.6, 8.15, 0), 5)
		TreeMeshLibrary._tube(metal, arm, [0.06, 0.055, 0.05, 0.05, 0.045, 0.045], 6, 1.0, 1.0)
		_box(metal, Vector3(1.85, 8.2, 0), Vector3(0.75, 0.12, 0.3))
		_box(glass, Vector3(1.85, 8.12, 0), Vector3(0.62, 0.04, 0.22))
	var m := ArrayMesh.new()
	var metal_arrays := metal.arrays()
	if style == "post_top":
		metal_arrays[Mesh.ARRAY_INDEX] = ParkedCars.front_faces(metal_arrays[Mesh.ARRAY_INDEX])
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, metal_arrays)
	var mm := StandardMaterial3D.new()
	mm.albedo_color = metal_col
	mm.metallic = 0.55
	mm.roughness = 0.42
	mm.vertex_color_use_as_albedo = true
	m.surface_set_material(0, mm)
	var glass_arrays := glass.arrays()
	if style == "post_top":
		glass_arrays[Mesh.ARRAY_INDEX] = ParkedCars.front_faces(glass_arrays[Mesh.ARRAY_INDEX])
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, glass_arrays)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = glass_col
	gm.emission_enabled = true
	gm.emission = glass_col
	CityLights.mark_glow(gm, 0.55)  # lit from dusk, dark by day
	gm.roughness = 0.15
	m.surface_set_material(1, gm)
	_lamp_meshes[style] = m
	return m

## Axis-aligned box (6 outward faces, clockwise-front).
static func _box(b: TreeMeshLibrary.Buf, c: Vector3, size: Vector3) -> void:
	var h := size * 0.5
	var faces := [
		[Vector3.UP, Vector3(1, 0, 0), Vector3(0, 0, 1)],
		[Vector3.DOWN, Vector3(1, 0, 0), Vector3(0, 0, -1)],
		[Vector3.RIGHT, Vector3(0, 0, 1), Vector3(0, 1, 0)],
		[Vector3.LEFT, Vector3(0, 0, -1), Vector3(0, 1, 0)],
		[Vector3.BACK, Vector3(-1, 0, 0), Vector3(0, 1, 0)],
		[Vector3.FORWARD, Vector3(1, 0, 0), Vector3(0, 1, 0)],
	]
	for f in faces:
		var n: Vector3 = f[0]
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		var fc := c + n * h
		var uu := u * h
		var vv := v * h
		var cs := [fc - uu + vv, fc + uu + vv, fc + uu - vv, fc - uu - vv]
		TreeMeshLibrary._card(b, cs, [n, n, n, n], [1.0, 1.0, 1.0, 1.0])

# --- Barriers ------------------------------------------------------------

static func _barrier_chunk(barriers: Array, start: int, stop: int, ground: GroundTruth,
		m2u: float, piece: float, roads: Dictionary, decks: Array, shore: ShorelineModel,
		has_quays: bool, models: Array, stairs: Array, statues: PackedVector2Array) -> Array:
	var bufs := {"wall": TreeMeshLibrary.Buf.new(), "fence": TreeMeshLibrary.Buf.new(),
		"chain_link": TreeMeshLibrary.Buf.new(), "wood_fence": TreeMeshLibrary.Buf.new(),
		"hedge": TreeMeshLibrary.Buf.new(), "hedge_core": TreeMeshLibrary.Buf.new()}
	var total_m := 0.0
	for bi in range(start, stop):
		var br: Variant = barriers[bi]
		if not (br is Dictionary):
			continue
		if bool(br.get("fortress_wall", false)):
			continue  # SuomenlinnaFortress owns this mapped defense.
		var cls := str((br as Dictionary).get("class", ""))
		var row: Array = BARRIERS.get(cls, [])
		if row.is_empty():
			continue
		var kind: String = row[0]
		if kind == "fence":
			var material := str((br as Dictionary).get("material", "")).to_lower()
			var fence_type := str((br as Dictionary).get("fence_type", "")).to_lower()
			if fence_type in ["chain_link", "chainlink", "wire"]:
				kind = "chain_link"
			elif material in ["wood", "timber"] and fence_type in ["", "board", "boards", "close_board", "panel"]:
				kind = "wood_fence"
		var tagged_height := float((br as Dictionary).get("height_m", NAN))
		var hgt := (tagged_height if is_finite(tagged_height) and tagged_height >= 0.1 and tagged_height <= 30.0 else float(row[1])) * m2u
		var thick := float(row[2]) * m2u
		var pts: PackedVector2Array = (br as Dictionary).get("points", PackedVector2Array())
		if cls == "fence" and kind == "fence" and not is_finite(tagged_height) and _rings_statue(pts, statues):
			hgt = float(BARRIERS["railing"][1]) * m2u
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var seg := a.distance_to(b)
			var nseg := maxi(int(ceil(seg / piece)), 1)
			for k in nseg:
				var p0 := a.lerp(b, float(k) / float(nseg))
				var p1 := a.lerp(b, float(k + 1) / float(nseg))
				if not ground.is_inside(p0.x, p0.y) or ground.water_at(p0.x, p0.y) > 0.0 \
						or ground.water_at(p1.x, p1.y) > 0.0:
					continue
				var mid := (p0 + p1) * 0.5
				if _on_road(mid, roads, m2u) or StairBuilder.covers(mid, stairs):
					continue
				if LandmarkSites.in_model_rects(mid, models):
					continue
				if BridgeStructures.in_rings(p0, decks) or BridgeStructures.in_rings(p1, decks):
					continue
				if has_quays and shore.near_quay_wall(mid, QUAY_WALL_REACH_M * m2u):
					continue
				if cls == "retaining_wall" and shore != null:
					var near_hard := shore.nearest(mid, 1)
					if not near_hard.is_empty() and float(near_hard["distance"]) <= 3.0 * m2u:
						continue
				var y0 := ground.height_at_world(p0.x, p0.y)
				var y1 := ground.height_at_world(p1.x, p1.y)
				if kind == "fence" or kind == "chain_link":
					var edge := _edge_base(ground, p0, p1, y0, y1, m2u)
					y0 = edge.x
					y1 = edge.y
				var h1 := -1.0
				if cls == "retaining_wall" and not is_finite(tagged_height):
					var rise := _retained(ground, p0, p1, m2u)
					if not rise.is_empty():
						y0 = rise[0]
						y1 = rise[1]
						hgt = rise[2]
						h1 = rise[3]
				total_m += p0.distance_to(p1) / m2u
				match kind:
					"wall":
						_wall_piece(bufs["wall"], p0, p1, y0, y1, hgt, thick, 0.3 * m2u, m2u, h1)
					"fence", "chain_link":
						_fence_piece(bufs[kind], p0, p1, y0, y1, hgt, m2u)
					"wood_fence":
						_wall_piece(bufs[kind], p0, p1, y0, y1, hgt, 0.06 * m2u, 0.0, m2u)
					"hedge":
						_wall_piece(bufs["hedge_core"], p0, p1, y0, y1, hgt * 0.9, thick * 0.8, 0.1 * m2u, m2u)
						_wall_piece(bufs["hedge"], p0, p1, y0, y1, hgt, thick, 0.1 * m2u, m2u)
	return [bufs, total_m]

static func _join_buf(dst: TreeMeshLibrary.Buf, src: TreeMeshLibrary.Buf) -> void:
	if src.idx.is_empty():
		return
	var base := dst.verts.size()
	dst.verts.append_array(src.verts)
	dst.normals.append_array(src.normals)
	dst.uvs.append_array(src.uvs)
	dst.colors.append_array(src.colors)
	var old_n := dst.idx.size()
	var add_n := src.idx.size()
	dst.idx.resize(old_n + add_n)
	for i in add_n:
		dst.idx[old_n + i] = src.idx[i] + base

static func _barriers_native(root: Node3D, data: LocationData, ground: GroundTruth,
		ctx: Dictionary, m2u: float) -> float:
	var statues := _statue_centres(data)
	const KIND_ID := {"wall": 0, "fence": 1, "chain_link": 2, "wood_fence": 3, "hedge": 4}
	const KIND_NAMES := ["wall", "fence", "chain_link", "wood_fence", "hedge", "hedge_core"]
	var barr_in: Array = []
	for br in data.barriers:
		if not (br is Dictionary) or bool(br.get("fortress_wall", false)):
			continue
		var cls := str((br as Dictionary).get("class", ""))
		var row: Array = BARRIERS.get(cls, [])
		if row.is_empty():
			continue
		var kind: String = row[0]
		if kind == "fence":
			var material := str((br as Dictionary).get("material", "")).to_lower()
			var fence_type := str((br as Dictionary).get("fence_type", "")).to_lower()
			if fence_type in ["chain_link", "chainlink", "wire"]:
				kind = "chain_link"
			elif material in ["wood", "timber"] and fence_type in ["", "board", "boards", "close_board", "panel"]:
				kind = "wood_fence"
		var tagged_height := float((br as Dictionary).get("height_m", NAN))
		var hgt := (tagged_height if is_finite(tagged_height) and tagged_height >= 0.1 and tagged_height <= 30.0 else float(row[1])) * m2u
		var thick := float(row[2]) * m2u
		var pts: PackedVector2Array = (br as Dictionary).get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		if cls == "fence" and kind == "fence" and not is_finite(tagged_height) and _rings_statue(pts, statues):
			hgt = float(BARRIERS["railing"][1]) * m2u
		barr_in.append([pts, int(KIND_ID[kind]), hgt, thick, cls == "retaining_wall", is_finite(tagged_height)])
	if barr_in.is_empty():
		return 0.0
	var road_segs := PackedFloat32Array()
	for w: Variant in data.roads:
		if not (w is Dictionary):
			continue
		var d: Dictionary = w
		if bool(d.get("area", false)) or bool(d.get("tunnel", false)):
			continue
		var rpts: PackedVector2Array = d.get("points", PackedVector2Array())
		var half := float(d.get("width_m", 4.0)) * 0.5 * m2u
		for j in range(1, rpts.size()):
			road_segs.push_back(rpts[j - 1].x); road_segs.push_back(rpts[j - 1].y)
			road_segs.push_back(rpts[j].x); road_segs.push_back(rpts[j].y); road_segs.push_back(half)
	var stair_rings: Array = []
	for fp: Array in StairBuilder.footprints(ground, m2u):
		stair_rings.append(fp[0])
	var deck_rings: Array = []
	for dr: Array in BridgeStructures.barrier_rings(data, m2u):
		deck_rings.append(dr[0])
	var mrects := PackedFloat32Array()
	for site: Array in LandmarkSites.model_rect_sites(data):
		var at: Vector2 = site[0]
		var entry: Dictionary = site[1]
		var a := LandmarkSites.axis(entry)
		var cr := Vector2(-a.y, a.x)
		for raw in entry.get("model_rects_m", []):
			if raw is Array and (raw as Array).size() >= 4:
				var c := at + (a * float(raw[0]) + cr * float(raw[1])) * m2u
				mrects.push_back(c.x); mrects.push_back(c.y); mrects.push_back(a.x); mrects.push_back(a.y)
				mrects.push_back(float(raw[2]) * m2u); mrects.push_back(float(raw[3]) * m2u)
	var shore: ShorelineModel = ground.shoreline if ground.shoreline is ShorelineModel and (ground.shoreline as ShorelineModel).ready else null
	var quay_segs := PackedFloat32Array()
	if shore != null:
		for q: Dictionary in shore.quays:
			var wall: PackedVector2Array = q["wall"]
			for i in wall.size() - 1:
				quay_segs.push_back(wall[i].x); quay_segs.push_back(wall[i].y)
				quay_segs.push_back(wall[i + 1].x); quay_segs.push_back(wall[i + 1].y)
	var shore_ready: bool = shore != null and shore.sampler != null
	var params := {
		"barriers": barr_in, "road_segs": road_segs,
		"stair_rings": stair_rings, "deck_rings": deck_rings,
		"model_rects": mrects, "quay_segs": quay_segs, "m2u": m2u,
		"shore_sampler": shore.sampler if shore_ready else null,
		"shore_domains": shore.domains.native if shore_ready and shore.domains != null else null,
		"shore_bounds": shore.bounds if shore_ready else Rect2(),
		"shore_empty": ground.shoreline != null and ground.shoreline.empty(),
		"body_levels": ParkedCars._shore_body_levels(ground),
		"surface": ground._surface, "level": ground._level,
		"grid_size": ground._size, "step_units": ground._step_units,
		"half_units": ground._half_units, "water_level_m": ground.water_level_m,
	}
	var res: Dictionary = ClassDB.class_call_static("PropKernels", "barriers_build", params)
	var season: int = ctx["season"]
	var mats := {
		"wall": StreetSnow.material(MaterialLibrary.pbr_material("limestone", MaterialLibrary._calib_tint(
			(MaterialLibrary.PBR_SETS["limestone"] as Dictionary)["mean"], WALL_STONE), 1.0) as StandardMaterial3D, 0.25),
		"fence": _fence_material(),
		"chain_link": _chainlink_material(),
		"wood_fence": StreetSnow.material(MaterialLibrary.pbr_material("wood", Color.WHITE, 1.0) as StandardMaterial3D, 0.25),
		"hedge": TreeMeshLibrary.leaf_material("broad", TreeSpecies.tint("oak", mini(season, 2)) * 0.85, 0.0, 0.0, true),
		"hedge_core": _core_material(),
	}
	var meshes: Array = res.get("meshes", [])
	for k in mini(meshes.size(), KIND_NAMES.size()):
		var arr: Array = meshes[k]
		if arr.is_empty():
			continue
		var a: Array = []
		a.resize(Mesh.ARRAY_MAX)
		a[Mesh.ARRAY_VERTEX] = arr[0]
		a[Mesh.ARRAY_NORMAL] = arr[1]
		a[Mesh.ARRAY_TEX_UV] = arr[2]
		a[Mesh.ARRAY_COLOR] = arr[3]
		a[Mesh.ARRAY_INDEX] = arr[4]
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.material_override = mats[KIND_NAMES[k]]
		mi.name = "Prop_barrier_%s" % KIND_NAMES[k]
		root.add_child(mi)
	return float(res.get("total_m", 0.0))

static func _barriers(root: Node3D, data: LocationData, ground: GroundTruth,
		ctx: Dictionary) -> float:
	if data.barriers.is_empty():
		return 0.0
	var m2u: float = ctx["m2u"]
	if _native_props:
		return _barriers_native(root, data, ground, ctx, m2u)
	var piece := 3.0 * m2u
	var roads := _road_grid(data, m2u)
	var decks := BridgeStructures.barrier_rings(data, m2u)
	var shore: ShorelineModel = ground.shoreline if ground.shoreline is ShorelineModel and (ground.shoreline as ShorelineModel).ready else null
	var has_quays := shore != null and not shore.quays.is_empty()
	var models := LandmarkSites.model_rect_sites(data)
	var stairs := StairBuilder.footprints(ground, m2u)
	var statues := _statue_centres(data)
	var n := data.barriers.size()
	var bufs: Dictionary
	var total_m := 0.0
	if n >= 64:
		var parts: Array = []
		parts.resize(BARRIER_CHUNKS)
		var cjob := func(c: int) -> void:
			parts[c] = _barrier_chunk(data.barriers, n * c / BARRIER_CHUNKS, n * (c + 1) / BARRIER_CHUNKS,
				ground, m2u, piece, roads, decks, shore, has_quays, models, stairs, statues)
		var g := WorkerThreadPool.add_group_task(cjob, BARRIER_CHUNKS, -1, false, "Barriers")
		WorkerThreadPool.wait_for_group_task_completion(g)
		bufs = parts[0][0]
		total_m = float(parts[0][1])
		for c in range(1, BARRIER_CHUNKS):
			var pbufs: Dictionary = parts[c][0]
			total_m += float(parts[c][1])
			for kind in bufs:
				_join_buf(bufs[kind], pbufs[kind])
	else:
		var single := _barrier_chunk(data.barriers, 0, n, ground, m2u, piece, roads, decks,
			shore, has_quays, models, stairs, statues)
		bufs = single[0]
		total_m = float(single[1])
	var season: int = ctx["season"]
	var mats := {
		# Limestone calibrated to weathered masonry: the "stone" set is an
		# orange sandstone photo too saturated to neutralise (walls read
		# as orange timber boxes).
		# Through StreetSnow: in winter the copings hold snow and the
		# street's slush and salt climb their feet (ClimateModel.snow_splash).
		"wall": StreetSnow.material(MaterialLibrary.pbr_material("limestone", MaterialLibrary._calib_tint(
			(MaterialLibrary.PBR_SETS["limestone"] as Dictionary)["mean"], WALL_STONE), 1.0) as StandardMaterial3D, 0.25),
		"fence": _fence_material(),
		"chain_link": _chainlink_material(),
		"wood_fence": StreetSnow.material(MaterialLibrary.pbr_material("wood", Color.WHITE, 1.0) as StandardMaterial3D, 0.25),
		"hedge": TreeMeshLibrary.leaf_material("broad", TreeSpecies.tint("oak", mini(season, 2)) * 0.85, 0.0, 0.0, true),
		"hedge_core": _core_material(),
	}
	for kind in bufs:
		var buf: TreeMeshLibrary.Buf = bufs[kind]
		if buf.idx.is_empty():
			continue
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, buf.arrays())
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.material_override = mats[kind]
		mi.name = "Prop_barrier_%s" % kind
		root.add_child(mi)
	return total_m

## Grid (ROAD_CELL_M cells) of linear road ways' segments as
## [a, b, half width]: barriers stop where they meet one. `on_ground`
## leaves out bridges (the roads a pier must not stand on).
const ROAD_CELL_M := 32.0

static func _road_grid(data: LocationData, m2u: float, on_ground := false) -> Dictionary:
	var grid := {}
	var cell := ROAD_CELL_M * m2u
	for w: Variant in data.roads:
		if not (w is Dictionary):
			continue
		var d: Dictionary = w
		if bool(d.get("area", false)) or bool(d.get("tunnel", false)) or (on_ground and bool(d.get("bridge", false))):
			continue
		var pts: PackedVector2Array = d.get("points", PackedVector2Array())
		var half := float(d.get("width_m", 4.0)) * 0.5 * m2u
		for j in range(1, pts.size()):
			var lo := pts[j - 1].min(pts[j]) - Vector2(half, half)
			var hi := pts[j - 1].max(pts[j]) + Vector2(half, half)
			for cx in range(floori(lo.x / cell), floori(hi.x / cell) + 1):
				for cz in range(floori(lo.y / cell), floori(hi.y / cell) + 1):
					var key := Vector2i(cx, cz)
					if not grid.has(key):
						grid[key] = []
					(grid[key] as Array).append([pts[j - 1], pts[j], half])
	return grid

## True where `p` lies on a road way's carriageway (within its half width).
static func _on_road(p: Vector2, grid: Dictionary, m2u: float) -> bool:
	var cell := ROAD_CELL_M * m2u
	for seg: Array in (grid.get(Vector2i(floori(p.x / cell), floori(p.y / cell)), []) as Array):
		var a: Vector2 = seg[0]
		var ab: Vector2 = (seg[1] as Vector2) - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
		if p.distance_to(a + ab * t) < float(seg[2]):
			return true
	return false

## Where a fence or railing a→b stands: on the higher of the ground either
## side of it, EDGE_PROBE_M out, when they differ by more than EDGE_STEP_M
## (it guards a drop, so it stands on the edge, not halfway down the slope);
## else on the ground under it. Returns the base at a and at b.
const EDGE_PROBE_M := 1.5
const EDGE_STEP_M := 0.4

static func _edge_base(ground: GroundTruth, a: Vector2, b: Vector2, y0: float, y1: float,
		m2u: float) -> Vector2:
	var side := (b - a).orthogonal().normalized() * EDGE_PROBE_M * m2u
	var l0 := ground.height_at_world(a.x + side.x, a.y + side.y)
	var r0 := ground.height_at_world(a.x - side.x, a.y - side.y)
	var l1 := ground.height_at_world(b.x + side.x, b.y + side.y)
	var r1 := ground.height_at_world(b.x - side.x, b.y - side.y)
	if maxf(absf(l0 - r0), absf(l1 - r1)) <= EDGE_STEP_M * m2u:
		return Vector2(y0, y1)
	return Vector2(maxf(maxf(l0, r0), y0), maxf(maxf(l1, r1), y1))

## Centres of the statues StatueBuilder stands (a mapped statue's footprint).
static func _statue_centres(data: LocationData) -> PackedVector2Array:
	var out := PackedVector2Array()
	for b: Variant in data.buildings:
		if b is Dictionary and (b as Dictionary).has("statue") and StatueBuilder.accepts(b):
			out.append(Vector2(float((b as Dictionary).get("x", 0.0)), float((b as Dictionary).get("z", 0.0))))
	return out

## True when the closed line `pts` goes round one of `centres`.
static func _rings_statue(pts: PackedVector2Array, centres: PackedVector2Array) -> bool:
	if centres.is_empty() or pts.size() < 4 or pts[0].distance_to(pts[pts.size() - 1]) > 0.5 * WorldScale.metres_to_units():
		return false
	for c in centres:
		if Geometry2D.is_point_in_polygon(c, pts):
			return true
	return false

## What a retaining wall a→b holds back: [base at a, base at b, height at
## a, height at b] from the ground RETAIN_PROBE_M either side of it (the
## lower side to the higher, plus the coping), or [] when both sides are
## level (the wall keeps its table height) or the drop is not a wall's.
const RETAIN_PROBE_M := 2.0
const RETAIN_MIN_M := 0.3
const RETAIN_MAX_M := 8.0
const COPING_M := 0.15

static func _retained(ground: GroundTruth, a: Vector2, b: Vector2, m2u: float) -> Array:
	var side := (b - a).orthogonal().normalized() * RETAIN_PROBE_M * m2u
	var base: Array[float] = []
	var top: Array[float] = []
	for p in [a, b]:
		var l := ground.height_at_world(p.x + side.x, p.y + side.y)
		var r := ground.height_at_world(p.x - side.x, p.y - side.y)
		base.append(minf(l, r))
		top.append(maxf(l, r) + COPING_M * m2u)
	var drop := maxf(top[0] - base[0], top[1] - base[1]) / m2u - COPING_M
	if drop < RETAIN_MIN_M or drop > RETAIN_MAX_M:
		return []
	return [base[0], base[1], top[0] - base[0], top[1] - base[1]]

## Draped box piece a→b: two sides + top (+ end caps), UVs in metres/2.
## `h1` is the height at b when it differs from `h` at a (a retaining wall).
static func _wall_piece(b: TreeMeshLibrary.Buf, p0: Vector2, p1: Vector2, y0: float,
		y1: float, h: float, t: float, sink: float, m2u: float, h1: float = -1.0) -> void:
	var d := (p1 - p0)
	var ln := d.length()
	if ln < 0.0001:
		return
	var n2 := Vector2(-d.y, d.x) / ln * t * 0.5
	var n3 := Vector3(n2.x, 0, n2.y).normalized()
	var a := Vector3(p0.x, y0 - sink, p0.y)
	var c := Vector3(p1.x, y1 - sink, p1.y)
	var up := Vector3(0, h + sink, 0)
	var up1 := up if h1 < 0.0 else Vector3(0, h1 + sink, 0)
	var o := Vector3(n2.x, 0, n2.y)
	var u1 := ln / m2u / 2.0
	var v1 := (h + sink) / m2u / 2.0
	var v2 := v1 if h1 < 0.0 else (h1 + sink) / m2u / 2.0
	var uvs := [Vector2(0, 0), Vector2(u1, 0), Vector2(u1, v2), Vector2(0, v1)]
	TreeMeshLibrary._card(b, [a + o + up, c + o + up1, c + o, a + o], [n3, n3, n3, n3], [1.0, 1.0, 0.75, 0.75], uvs)
	TreeMeshLibrary._card(b, [c - o + up1, a - o + up, a - o, c - o], [-n3, -n3, -n3, -n3], [1.0, 1.0, 0.75, 0.75], uvs)
	var tu := t / m2u / 2.0
	TreeMeshLibrary._card(b, [a - o + up, c - o + up1, c + o + up1, a + o + up],
		[Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP], [1.0, 1.0, 1.0, 1.0],
		[Vector2(0, 0), Vector2(u1, 0), Vector2(u1, tu), Vector2(0, tu)])

## Fence piece: one double-sided picket panel card + a post at p0.
static func _fence_piece(b: TreeMeshLibrary.Buf, p0: Vector2, p1: Vector2, y0: float,
		y1: float, h: float, m2u: float) -> void:
	var ln := p0.distance_to(p1)
	if ln < 0.0001:
		return
	var d := (p1 - p0) / ln
	var n3 := Vector3(-d.y, 0, d.x)
	var a := Vector3(p0.x, y0, p0.y)
	var c := Vector3(p1.x, y1, p1.y)
	var up := Vector3(0, h, 0)
	var u1 := ln / m2u / 1.5
	TreeMeshLibrary._card(b, [a + up, c + up, c, a], [n3, n3, n3, n3], [1.0, 1.0, 0.8, 0.8],
		[Vector2(0, 0), Vector2(u1, 0), Vector2(u1, 1), Vector2(0, 1)])

static func _core_material() -> StandardMaterial3D:
	if not _mats.has("core"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.12, 0.18, 0.08)
		m.roughness = 0.95
		_mats["core"] = m
	return _mats["core"]

static func _fence_material() -> StandardMaterial3D:
	if _mats.has("fence"):
		return _mats["fence"]
	if _fence_tex == null:
		# 1.5 m panel: top + bottom rail, a post, pickets every ~12 cm.
		var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var col := Color(0.16, 0.17, 0.17, 1.0)
		img.fill_rect(Rect2i(0, 6, 128, 7), col)
		img.fill_rect(Rect2i(0, 112, 128, 7), col)
		img.fill_rect(Rect2i(0, 0, 9, 128), col)
		for x in range(15, 128, 11):
			img.fill_rect(Rect2i(x, 2, 3, 124), col)
		img.generate_mipmaps()
		_fence_tex = ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = _fence_tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.4
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Painted iron: a half-metallic picket mirrored the sky and read as a
	# pale slatted wall from across a canal.
	m.metallic = 0.0
	m.roughness = 0.75
	_mats["fence"] = m
	return m

## One shared alpha-cut mesh pattern per place, rather than per-barrier materials.
static func _chainlink_material() -> StandardMaterial3D:
	if _mats.has("chain_link"):
		return _mats["chain_link"]
	if _chainlink_tex == null:
		var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var wire := Color(0.28, 0.29, 0.28, 1.0)
		for y in 128:
			for x in 128:
				if (x + y) % 16 < 2 or posmod(x - y, 16) < 2:
					img.set_pixel(x, y, wire)
		img.generate_mipmaps()
		_chainlink_tex = ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = _chainlink_tex
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.4
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.8
	_mats["chain_link"] = m
	return m
