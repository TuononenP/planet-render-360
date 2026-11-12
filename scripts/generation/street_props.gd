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
const UTILITY_COUNTRIES := ["JP", "KR", "TW"]
## Linear colour of free-standing walls: grey-beige weathered masonry.
const WALL_STONE := Color(0.26, 0.24, 0.21)
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

static func build(root: Node3D, data: LocationData, ground: GroundTruth,
		mask: VegetationMask, ctx: Dictionary) -> Dictionary:
	var timings := {}
	var t := Time.get_ticks_msec()
	# Planned before the lamps: a side-street lamp gives way only where a
	# utility pole really stands (the poles stop at their radius and cap).
	var pole_plan := UtilityPoles.plan(data, ground)
	ctx = ctx.duplicate()
	ctx["pole_grid"] = UtilityPoles.pole_grid(pole_plan)
	t = _lap(timings, "pole_plan", t)
	var lamps := _lampposts(root, data, ground, mask, ctx)
	t = _lap(timings, "lamps", t)
	var bar := _barriers(root, data, ground, ctx)
	t = _lap(timings, "barriers", t)
	ShoreRailings.build(root, data, ground)
	t = _lap(timings, "shore_railings", t)
	var furniture := StreetFurniture.build(root, data, ground, mask, float(ctx["m2u"]))
	t = _lap(timings, "furniture", t)
	var boats := MarinaBuilder.build(root, data, ground, mask)
	t = _lap(timings, "marina", t)
	boats += HarbourFerries.build(root, data, ground, mask)
	t = _lap(timings, "ferries", t)
	var quay_bollards := QuayDetails.build(root, data, ground, mask)
	t = _lap(timings, "quay", t)
	var cars := ParkedCars.build(root, data, ground)
	t = _lap(timings, "cars", t)
	var trams := TransitVehicles.build(root, data, ground)
	t = _lap(timings, "trams", t)
	var trains := StationTrains.build(root, data, ground)
	t = _lap(timings, "trains", t)
	var wires := OverheadWires.build(root, data, ground)
	t = _lap(timings, "wires", t)
	var poles := UtilityPoles.build(root, data, ground, pole_plan)
	t = _lap(timings, "utility_poles", t)
	var snowbanks := Snowbanks.build(root, data, ground)
	t = _lap(timings, "snowbanks", t)
	print("PROPS timings ms ", timings)
	return {"lamps": lamps, "barrier_m": bar, "furniture": furniture, "boats": boats, "quay_bollards": quay_bollards, "cars": cars, "trams": trams, "trains": trains, "wires": wires, "utility_poles": poles, "snowbanks": snowbanks}

## Records the ms since `t` under `key`; returns the time now.
static func _lap(timings: Dictionary, key: String, t: int) -> int:
	var now := Time.get_ticks_msec()
	timings[key] = now - t
	return now

# --- Lampposts -----------------------------------------------------------

static func _lampposts(root: Node3D, data: LocationData, ground: GroundTruth,
		mask: VegetationMask, ctx: Dictionary) -> int:
	var radius_m: float = PROP_R[int(ctx["preset"])]
	if radius_m <= 0.0 or data.buildings.is_empty():
		return 0
	var m2u: float = ctx["m2u"]
	var r_u := radius_m * m2u
	var region := ArchitectureStyle.country_region_for(data.latitude, data.longitude, data.country)
	var family := lamp_family(region, data.country, CityStyles.region_at(data.latitude, data.longitude))
	var centre := View360.spawn_xz(data)
	var placed := {"lantern": [], "heritage": [], "cobra": [], "utility": [], "modern": [], "modern_s": [], "post_top": [], "nyc_f": [], "nyc_crook": []}
	var occupied := {}
	var occ_cell := 10.0 * m2u
	var sites := _lamp_sites(data, ground, m2u)
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
		var style := lamp_style(family, region, cls)
		var off := (width_m * 0.5 + 1.1) * m2u
		var step := LAMP_SPACING_M * m2u
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
						| VegetationMask.WATER, 0.0) or ground.water_at(p.x, p.y) > 0.0:
					continue
				if _on_apron(sites["aprons"], p, m2u):
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
	if RenderQuality.ultra_desktop(int(ctx["preset"])):
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

## Lookup grids from the road plan: the junction surfaces no lamp stands
## on, and the signals whose streets take the main-road lamp.
static func _lamp_sites(data: LocationData, ground: GroundTruth, m2u: float) -> Dictionary:
	var plan := RoadMarkings.plan(data, ground)
	var aprons := {}
	for ring: PackedVector2Array in plan.aprons:
		var box := Rect2(ring[0], Vector2.ZERO)
		for q in ring:
			box = box.expand(q)
		RoadMarkings._grid_add(aprons, box.position, box.end, ring, m2u)
	var signals := {}
	for q in plan.signals:
		RoadMarkings._grid_add(signals, q, q, q, m2u)
	return {"aprons": aprons, "signals": signals}

static func _on_apron(aprons: Dictionary, p: Vector2, m2u: float) -> bool:
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

static func _barriers(root: Node3D, data: LocationData, ground: GroundTruth,
		ctx: Dictionary) -> float:
	if data.barriers.is_empty():
		return 0.0
	var m2u: float = ctx["m2u"]
	var bufs := {"wall": TreeMeshLibrary.Buf.new(), "fence": TreeMeshLibrary.Buf.new(),
		"chain_link": TreeMeshLibrary.Buf.new(), "wood_fence": TreeMeshLibrary.Buf.new(),
		"hedge": TreeMeshLibrary.Buf.new(), "hedge_core": TreeMeshLibrary.Buf.new()}
	var total_m := 0.0
	var piece := 3.0 * m2u
	var roads := _road_grid(data, m2u)
	var decks := BridgeStructures.barrier_rings(data, m2u)
	for br in data.barriers:
		if not (br is Dictionary):
			continue
		if bool(br.get("fortress_wall", false)):
			continue  # SuomenlinnaFortress owns this mapped defense.
		var row: Array = BARRIERS.get(str((br as Dictionary).get("class", "")), [])
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
				# A wall mapped across a road runs under its bridge or stops at
				# its edge: drawn on the terrain it stood across the lanes.
				if _on_road((p0 + p1) * 0.5, roads, m2u):
					continue
				# A wall or rail along the bank ends at the bridge's abutment:
				# between its carriageways it stood as a stub on the deck.
				if BridgeStructures.in_rings(p0, decks) or BridgeStructures.in_rings(p1, decks):
					continue
				var y0 := ground.height_at_world(p0.x, p0.y)
				var y1 := ground.height_at_world(p1.x, p1.y)
				total_m += p0.distance_to(p1) / m2u
				match kind:
					"wall":
						_wall_piece(bufs["wall"], p0, p1, y0, y1, hgt, thick, 0.3 * m2u, m2u)
					"fence", "chain_link":
						_fence_piece(bufs[kind], p0, p1, y0, y1, hgt, m2u)
					"wood_fence":
						_wall_piece(bufs[kind], p0, p1, y0, y1, hgt, 0.06 * m2u, 0.0, m2u)
					"hedge":
						_wall_piece(bufs["hedge_core"], p0, p1, y0, y1, hgt * 0.9, thick * 0.8, 0.1 * m2u, m2u)
						_wall_piece(bufs["hedge"], p0, p1, y0, y1, hgt, thick, 0.1 * m2u, m2u)
	var season: int = ctx["season"]
	var mats := {
		# Limestone calibrated to weathered masonry: the "stone" set is an
		# orange sandstone photo too saturated to neutralise (walls read
		# as orange timber boxes).
		"wall": MaterialLibrary.pbr_material("limestone", MaterialLibrary._calib_tint(
			(MaterialLibrary.PBR_SETS["limestone"] as Dictionary)["mean"], WALL_STONE), 1.0),
		"fence": _fence_material(),
		"chain_link": _chainlink_material(),
		"wood_fence": MaterialLibrary.pbr_material("wood", Color.WHITE, 1.0),
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
## [a, b, half width]: barriers stop where they meet one.
const ROAD_CELL_M := 32.0

static func _road_grid(data: LocationData, m2u: float) -> Dictionary:
	var grid := {}
	var cell := ROAD_CELL_M * m2u
	for w: Variant in data.roads:
		if not (w is Dictionary):
			continue
		var d: Dictionary = w
		if bool(d.get("area", false)) or bool(d.get("tunnel", false)):
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

## Draped box piece a→b: two sides + top (+ end caps), UVs in metres/2.
static func _wall_piece(b: TreeMeshLibrary.Buf, p0: Vector2, p1: Vector2, y0: float,
		y1: float, h: float, t: float, sink: float, m2u: float) -> void:
	var d := (p1 - p0)
	var ln := d.length()
	if ln < 0.0001:
		return
	var n2 := Vector2(-d.y, d.x) / ln * t * 0.5
	var n3 := Vector3(n2.x, 0, n2.y).normalized()
	var a := Vector3(p0.x, y0 - sink, p0.y)
	var c := Vector3(p1.x, y1 - sink, p1.y)
	var up := Vector3(0, h + sink, 0)
	var o := Vector3(n2.x, 0, n2.y)
	var u1 := ln / m2u / 2.0
	var v1 := (h + sink) / m2u / 2.0
	var uvs := [Vector2(0, 0), Vector2(u1, 0), Vector2(u1, v1), Vector2(0, v1)]
	TreeMeshLibrary._card(b, [a + o + up, c + o + up, c + o, a + o], [n3, n3, n3, n3], [1.0, 1.0, 0.75, 0.75], uvs)
	TreeMeshLibrary._card(b, [c - o + up, a - o + up, a - o, c - o], [-n3, -n3, -n3, -n3], [1.0, 1.0, 0.75, 0.75], uvs)
	var tu := t / m2u / 2.0
	TreeMeshLibrary._card(b, [a - o + up, c - o + up, c + o + up, a + o + up],
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
