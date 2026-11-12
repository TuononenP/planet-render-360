class_name StreetFurniture
extends RefCounted

## Street furniture (desktop Ultra, Phase 7 of the Ultra pass): benches,
## litter bins, bollards, traffic signals and bus stops near the eye.
## * From OSM nodes (LocationData.street_furniture: amenity=bench /
##   waste_basket, highway=traffic_signals / bus_stop, barrier=bollard).
##   Signals and stops are mapped on the carriageway: each signal node
##   gets a pole on both kerbs, each stop a shelter (shelter=yes) or a
##   sign pole on its own kerb. A bench or bin mapped in the road moves
##   to the kerb; benches face the street.
## * With no furniture mapped (older cached data, unmapped towns): a
##   sparse fill, a bin every BIN_STEP_M along lit urban streets (none in
##   Japan, which has almost no street bins) and signals where two main
##   roads meet.
## * Regional kit (furniture_family): North American mast-arm signals
##   and drum bins, Japanese/Korean horizontal signal heads, British
##   black bins, Dutch red-brown bollards, European post bins elsewhere.
## True-metre meshes, instanced (one MultiMesh per kind), skipped inside
## buildings and water. Signal lenses glow day and night.

const RADIUS_M := 400.0
const MAX_ITEMS := 1500
const BIN_STEP_M := 70.0
## Out from the carriageway edge to the furniture line (m).
const KERB_OUT_M := 0.6
## A road farther than this from a node does not orient it (m).
const SNAP_M := 25.0
## A spot in another way's carriageway slides along its street this far
## (m), a metre at a time, to the first clear ground (a signal pole stops
## short of the crossing road, at its corner).
const SLIDE_M := 14
## A bridge kerb counts this much further (m) than a street's, so a node
## where a bridge meets its street snaps to the street.
const BRIDGE_BIAS_M := 1.0
const LENS := {"r": Color(1.0, 0.08, 0.03), "g": Color(0.1, 1.0, 0.45)}

static var _meshes: Dictionary = {}

## The place's furniture kit: "na", "japan", "uk", "nl" or "europe".
static func furniture_family(region: String, country: String, city: String = "") -> String:
	if city == "new_york":
		return "nyc"
	var iso := country.to_upper()
	if iso == "FI":
		return "nordic"
	if iso == "SE":
		return "nordic_se"
	if iso in ["US", "CA"] or (iso == "" and region == "north_america"):
		return "na"
	if iso in ["JP", "KR", "TW"] or (iso == "" and region == "japan"):
		return "japan"
	if iso in StreetProps.HERITAGE_COUNTRIES:
		return "uk"
	if iso == "NL":
		return "nl"
	return "europe"

## Mesh key for one item of `kind` in `family`.
static func mesh_key(kind: String, family: String) -> String:
	match kind:
		"bench":
			return "bench_stone" if family == "japan" else "bench_wood"
		"bin":
			return {"na": "bin_drum", "nyc": "bin_nyc", "uk": "bin_black"}.get(family, "bin_post")
		"bollard":
			return "bollard_red" if family == "nl" else "bollard_black"
		"signals":
			return {"na": "signals_na", "nyc": "signals_na", "japan": "signals_jp"}.get(family, "signals_post")
	return kind

## Adds the furniture under one "StreetFurniture" node of `root` on
## desktop Ultra. Returns the number of items placed.
static func build(root: Node3D, data: LocationData, ground: GroundTruth,
		mask: VegetationMask, m2u: float) -> int:
	if not RenderQuality.ultra_desktop(data.quality_preset) or data.buildings.is_empty():
		return 0
	var region := ArchitectureStyle.country_region_for(data.latitude, data.longitude, data.country)
	var family := furniture_family(region, data.country, CityStyles.region_at(data.latitude, data.longitude))
	var centre := View360.spawn_xz(data)
	var roads := RoadIndex.new(data, m2u, (RADIUS_M + SNAP_M) * m2u, centre)
	var items: Array = data.street_furniture
	if items.is_empty():
		items = fill(data, roads, family, m2u)
	var r2 := pow(RADIUS_M * m2u, 2.0)
	var near: Array = []
	for it in items:
		var p := Vector2(float(it["x"]), float(it["z"]))
		if str(it.get("kind", "")) == "subway_entrance" and family != "nyc":
			continue
		if (p - centre).length_squared() <= r2:
			near.append([(p - centre).length_squared(), it])
	near.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var placed := {}  # mesh key -> Array[Transform3D]
	var count := 0
	for e in near:
		if count >= MAX_ITEMS:
			break
		for spot in spots(e[1], roads, family, m2u):
			var p := _clear_of_lanes(spot[0], spot[1], str(spot[2]).begins_with("signals"), mask, m2u)
			if p.x == INF or mask.blocked(p.x, p.y, VegetationMask.BUILDING | VegetationMask.WATER, 0.0) \
					or ground.water_at(p.x, p.y) > 0.0:
				continue
			var basis := Basis(Vector3.UP, _yaw(spot[1])).scaled(Vector3.ONE * m2u)
			if not placed.has(spot[2]):
				placed[spot[2]] = []
			(placed[spot[2]] as Array).append(Transform3D(basis,
				Vector3(p.x, ground.height_at_world(p.x, p.y), p.y)))
			count += 1
	if placed.is_empty():
		return 0
	var holder := Node3D.new()
	holder.name = "StreetFurniture"
	for key in placed:
		var xf: Array = placed[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh(str(key))
		mm.instance_count = xf.size()
		for k in xf.size():
			mm.set_instance_transform(k, xf[k])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.name = "Furniture_%s" % key
		holder.add_child(mmi)
	root.add_child(holder)
	return count

## `p`, or the nearest point along its street (a signal faces along it,
## anything else faces across it) out of every carriageway; INF when
## there is none within SLIDE_M.
static func _clear_of_lanes(p: Vector2, facing: Vector2, is_signal: bool, mask: VegetationMask,
		m2u: float) -> Vector2:
	if not mask.blocked(p.x, p.y, VegetationMask.ROAD, 0.0):
		return p
	var along := facing if is_signal else Vector2(-facing.y, facing.x)
	for k in range(1, SLIDE_M + 1):
		for sgn in [1.0, -1.0]:
			var q: Vector2 = p + along * sgn * float(k) * m2u
			if not mask.blocked(q.x, q.y, VegetationMask.ROAD, 0.0):
				return q
	return Vector2(INF, INF)

## [position, facing direction, mesh key] for one item: signals become a
## pole on each kerb facing its oncoming lane, stops and road-bound
## items move to the kerb, benches face the street.
static func spots(it: Dictionary, roads: RoadIndex, family: String, m2u: float) -> Array:
	var p := Vector2(float(it["x"]), float(it["z"]))
	var kind := str(it["kind"])
	var key := mesh_key(kind, family)
	var r := roads.nearest(p, SNAP_M * m2u)
	if r.is_empty():
		return [] if kind in ["signals", "bus_stop"] else [[p, Vector2.RIGHT, key]]
	# An item on a bridge belongs on its deck, not on the ground under it.
	if bool(r.get("bridge", false)):
		return []
	var c: Vector2 = r["point"]
	var dir: Vector2 = r["dir"]
	var nrm := Vector2(-dir.y, dir.x)
	var half: float = r["half"]
	var kerb := half + KERB_OUT_M * m2u
	var side := 1.0 if (p - c).dot(nrm) >= 0.0 else -1.0
	match kind:
		"subway_entrance":
			return [[p, -nrm * side, key]]
		"signals":
			# One state per junction: both poles show the same aspect.
			var lit := "r" if _hash(p) < 0.5 else "g"
			return [[c + nrm * kerb, -dir, key + "_" + lit], [c - nrm * kerb, dir, key + "_" + lit]]
		"bus_stop":
			var stop := "shelter" if bool(it.get("shelter", false)) else ("stop_hsl" if family == "nordic" else ("stop_sl" if family == "nordic_se" else "stop_pole"))
			return [[c + nrm * side * (kerb + (0.9 if stop == "shelter" else 0.0) * m2u), -nrm * side, stop]]
	var at := p
	if (p - c).length() < kerb:
		at = c + nrm * side * kerb
	return [[at, -nrm * side, key]]

## Sparse fill for a place with no furniture mapped.
static func fill(data: LocationData, roads: RoadIndex, family: String, m2u: float) -> Array:
	var out: Array = []
	var r2 := pow(RADIUS_M * m2u, 2.0)
	var centre := View360.spawn_xz(data)
	var majors := {}  # snapped node -> directions major roads leave it in
	for i in data.roads.size():
		var rd: Variant = data.roads[i]
		# A paved square's outline is no street.
		if not (rd is Dictionary) or bool((rd as Dictionary).get("tunnel", false)) \
				or bool((rd as Dictionary).get("area", false)):
			continue
		var cls := str((rd as Dictionary).get("class", ""))
		var pts: PackedVector2Array = (rd as Dictionary).get("points", PackedVector2Array())
		if cls in StreetProps.MAJOR:
			for j in pts.size():
				var q := pts[j]
				if (q - centre).length_squared() <= r2:
					var k := Vector2i(roundi(q.x * 2.0), roundi(q.y * 2.0))
					if not majors.has(k):
						majors[k] = []
					if j > 0:
						(majors[k] as Array).append((pts[j - 1] - q).normalized())
					if j < pts.size() - 1:
						(majors[k] as Array).append((pts[j + 1] - q).normalized())
		# A bridge still meets its streets (above), but no bin stands on
		# the ground under it.
		if family == "japan" or cls not in StreetProps.LIT or pts.size() < 2 \
				or bool((rd as Dictionary).get("bridge", false)):
			continue
		# A bin every BIN_STEP_M, alternating kerbs.
		var w := float((rd as Dictionary).get("width_m", 6.0)) * 0.5 * m2u + KERB_OUT_M * m2u
		var t := BIN_STEP_M * 0.5 * m2u
		var side := 1.0
		for s in pts.size() - 1:
			var a := pts[s]
			var seg := a.distance_to(pts[s + 1])
			if seg < 0.001:
				continue
			var dir := (pts[s + 1] - a) / seg
			while t < seg:
				var q := a + dir * t + Vector2(-dir.y, dir.x) * side * w
				side = -side
				t += BIN_STEP_M * m2u
				if (q - centre).length_squared() <= r2:
					out.append({"x": q.x, "z": q.y, "kind": "bin"})
			t -= seg
	for k in majors:
		if RoadSurface.arms(majors[k]) >= 3:
			out.append({"x": float(k.x) / 2.0, "z": float(k.y) / 2.0, "kind": "signals"})
	return out

static func _yaw(facing: Vector2) -> float:
	return atan2(-facing.y, facing.x)

static func _hash(p: Vector2) -> float:
	return fmod(absf(sin(p.x * 12.9898 + p.y * 78.233) * 43758.5453), 1.0)

# --- Meshes (metres; local +X faces the street / oncoming traffic) -------

static func mesh(key: String) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key]
	var surf := {}  # material name -> Buf
	var buf := func(mat: String) -> TreeMeshLibrary.Buf:
		if not surf.has(mat):
			surf[mat] = TreeMeshLibrary.Buf.new()
		return surf[mat]
	var lit := key.substr(key.length() - 1) if key.begins_with("signals") else ""
	match key.trim_suffix("_" + lit) if lit != "" else key:
		"bench_wood":
			for x in [-0.12, 0.0, 0.12]:
				StreetProps._box(buf.call("wood"), Vector3(x, 0.45, 0), Vector3(0.1, 0.04, 1.8))
			for y in [0.62, 0.75]:
				StreetProps._box(buf.call("wood"), Vector3(-0.21, y, 0), Vector3(0.04, 0.1, 1.8))
			for z in [-0.75, 0.75]:
				StreetProps._box(buf.call("iron"), Vector3(0, 0.22, z), Vector3(0.4, 0.44, 0.05))
				StreetProps._box(buf.call("iron"), Vector3(-0.22, 0.62, z), Vector3(0.04, 0.4, 0.05))
		"bench_stone":
			StreetProps._box(buf.call("concrete"), Vector3(0, 0.22, 0), Vector3(0.45, 0.44, 1.8))
		"bin_post":
			TreeMeshLibrary._tube(buf.call("green"), [Vector3(0, 0, 0), Vector3(0, 1.0, 0)], [0.035, 0.035], 6, 1.0, 1.0)
			TreeMeshLibrary._tube(buf.call("green"), [Vector3(0.24, 0.35, 0), Vector3(0.24, 0.95, 0)], [0.21, 0.22], 10, 1.0, 1.0)
		"bin_drum":
			TreeMeshLibrary._tube(buf.call("green"), [Vector3(0, 0, 0), Vector3(0, 0.85, 0)], [0.29, 0.31], 12, 1.0, 1.0)
			TreeMeshLibrary._tube(buf.call("iron"), [Vector3(0, 0.85, 0), Vector3(0, 0.92, 0)], [0.33, 0.2], 12, 1.0, 1.0)
		"bin_nyc":
			# Open wire litter basket, rather than a solid drum.
			for k in 12:
				var a := TAU * float(k) / 12.0
				var at := Vector3(cos(a) * 0.29, 0, sin(a) * 0.29)
				TreeMeshLibrary._tube(buf.call("iron"), [at, at + Vector3(0, 0.83, 0)], [0.015, 0.015], 4, 1.0, 1.0)
			for y in [0.08, 0.42, 0.82]:
				for k in 12:
					var a := TAU * float(k) / 12.0
					var b := TAU * float(k + 1) / 12.0
					TreeMeshLibrary._tube(buf.call("iron"), [Vector3(cos(a) * 0.30, y, sin(a) * 0.30),
						Vector3(cos(b) * 0.30, y, sin(b) * 0.30)], [0.018, 0.018], 4, 1.0, 1.0)
		"subway_entrance":
			# The visible stairwell rim, handrails, sign and the two green globes.
			for k in 6:
				StreetProps._box(buf.call("concrete"), Vector3(-1.3 + float(k) * 0.48, 0.03 + float(k) * 0.04, 0),
					Vector3(0.48, 0.08, 2.1))
			for z in [-1.15, 1.15]:
				for x in [-1.5, 1.5]:
					var post_top := 1.13 if x > 0.0 else 1.05
					TreeMeshLibrary._tube(buf.call("iron"), [Vector3(x, 0, z), Vector3(x, post_top, z)], [0.045, 0.045], 6, 1.0, 1.0)
				TreeMeshLibrary._tube(buf.call("iron"), [Vector3(-1.5, 1.0, z), Vector3(1.5, 1.0, z)], [0.04, 0.04], 6, 1.0, 1.0)
				for k in range(1, 20):
					var x := -1.5 + float(k) * 0.15
					TreeMeshLibrary._tube(buf.call("iron"), [Vector3(x, 0.1, z), Vector3(x, 1.0, z)], [0.012, 0.012], 4, 1.0, 1.0)
				# Split white/green globe; a lamp diffuser is less emissive than a traffic lens.
				TreeMeshLibrary._tube(buf.call("globe_white"), [Vector3(1.5, 1.12, z), Vector3(1.5, 1.16, z),
					Vector3(1.5, 1.22, z), Vector3(1.5, 1.30, z)], [0.0, 0.113, 0.161, 0.18], 12, 1.0, 1.0)
				TreeMeshLibrary._tube(buf.call("globe_green"), [Vector3(1.5, 1.30, z), Vector3(1.5, 1.38, z),
					Vector3(1.5, 1.44, z), Vector3(1.5, 1.48, z)], [0.18, 0.161, 0.113, 0.0], 12, 1.0, 1.0)
			StreetProps._box(buf.call("iron"), Vector3(-1.5, 0.76, 0), Vector3(0.08, 0.34, 2.3))
		"bin_black":
			TreeMeshLibrary._tube(buf.call("iron"), [Vector3(0, 0, 0), Vector3(0, 0.95, 0)], [0.26, 0.28], 12, 1.0, 1.0)
			TreeMeshLibrary._tube(buf.call("gold"), [Vector3(0, 0.78, 0), Vector3(0, 0.84, 0)], [0.285, 0.285], 12, 1.0, 1.0)
		"bollard_black":
			TreeMeshLibrary._tube(buf.call("iron"), [Vector3(0, 0, 0), Vector3(0, 0.9, 0), Vector3(0, 0.97, 0)], [0.09, 0.08, 0.04], 8, 1.0, 1.0)
		"bollard_red":
			TreeMeshLibrary._tube(buf.call("oxide"), [Vector3(0, 0, 0), Vector3(0, 0.8, 0), Vector3(0, 0.86, 0)], [0.07, 0.06, 0.04], 8, 1.0, 1.0)
		"signals_post":
			TreeMeshLibrary._tube(buf.call("iron"), [Vector3(0, 0, 0), Vector3(0, 3.0, 0)], [0.06, 0.05], 8, 1.0, 1.0)
			_head(buf, Vector3(0.12, 2.6, 0), false, lit)
		"signals_na":
			# Mast arm out over the lanes (local +Z), heads hung from it.
			TreeMeshLibrary._tube(buf.call("galv"), [Vector3(0, 0, 0), Vector3(0, 6.2, 0)], [0.14, 0.1], 8, 1.0, 1.0)
			TreeMeshLibrary._tube(buf.call("galv"), [Vector3(0, 5.6, 0), Vector3(0, 5.75, 3.0), Vector3(0, 5.85, 6.0)], [0.08, 0.06, 0.05], 6, 1.0, 1.0)
			for z in [3.2, 5.6]:
				_head(buf, Vector3(0.12, 5.1, z), false, lit)
		"signals_jp":
			TreeMeshLibrary._tube(buf.call("galv"), [Vector3(0, 0, 0), Vector3(0, 5.8, 0)], [0.12, 0.09], 8, 1.0, 1.0)
			TreeMeshLibrary._tube(buf.call("galv"), [Vector3(0, 5.3, 0), Vector3(0, 5.35, 3.4)], [0.05, 0.045], 6, 1.0, 1.0)
			_head(buf, Vector3(0.12, 5.35, 3.0), true, lit)
		"shelter":
			for x in [-0.7, 0.7]:
				for z in [-1.5, 1.5]:
					StreetProps._box(buf.call("galv"), Vector3(x, 1.25, z), Vector3(0.06, 2.5, 0.06))
			StreetProps._box(buf.call("galv"), Vector3(0, 2.55, 0), Vector3(1.7, 0.1, 3.3))
			StreetProps._box(buf.call("glass"), Vector3(-0.7, 1.3, 0), Vector3(0.02, 2.1, 2.9))
			for z in [-1.5, 1.5]:
				StreetProps._box(buf.call("glass"), Vector3(0, 1.3, z), Vector3(1.3, 2.1, 0.02))
			StreetProps._box(buf.call("galv"), Vector3(-0.45, 0.45, 0), Vector3(0.35, 0.05, 2.0))
		"stop_pole", "stop_hsl", "stop_sl":
			TreeMeshLibrary._tube(buf.call("galv"), [Vector3(0, 0, 0), Vector3(0, 2.7, 0)], [0.04, 0.035], 6, 1.0, 1.0)
			StreetProps._box(buf.call("blue" if key in ["stop_hsl", "stop_sl"] else "sign"), Vector3(0.05, 2.45, 0), Vector3(0.04, 0.55, 0.45))
			if key == "stop_sl":
				StreetProps._box(buf.call("sign"), Vector3(0.078, 2.47, 0), Vector3(0.015, 0.16, 0.28))
			if key == "stop_hsl":
				StreetProps._box(buf.call("gold"), Vector3(0.078, 2.47, 0), Vector3(0.015, 0.27, 0.3))
				StreetProps._box(buf.call("blue"), Vector3(0.09, 2.47, 0), Vector3(0.015, 0.1, 0.2))
	var m := ArrayMesh.new()
	for mat in surf:
		var arrays := (surf[mat] as TreeMeshLibrary.Buf).arrays()
		if key in ["stop_hsl", "stop_sl"]:
			arrays[Mesh.ARRAY_INDEX] = ParkedCars.front_faces(arrays[Mesh.ARRAY_INDEX])
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		m.surface_set_material(m.get_surface_count() - 1, _material(str(mat)))
	_meshes[key] = m
	return m

## A three-lens signal head at `c` facing +X, vertical or horizontal
## (Japan), with lens `lit` ("r" or "g") glowing.
static func _head(buf: Callable, c: Vector3, horizontal: bool, lit: String) -> void:
	var size := Vector3(0.25, 0.3, 0.9) if horizontal else Vector3(0.25, 0.9, 0.3)
	StreetProps._box(buf.call("iron"), c, size)
	var names := PackedStringArray(["g", "a", "r"] if horizontal else ["r", "a", "g"])
	for k in 3:
		var off := (float(k) - 1.0) * 0.28
		var at := c + Vector3(0.13, 0.0, off) if horizontal else c + Vector3(0.13, -off, 0.0)
		var lens: String = ("lens_" + names[k]) if names[k] == lit else "lens_off"
		StreetProps._box(buf.call(lens), at, Vector3(0.02, 0.2, 0.2))

static func _material(name: String) -> Material:
	var m := StandardMaterial3D.new()
	var col: Color = {
		"wood": Color(0.30, 0.20, 0.12), "iron": Color(0.04, 0.045, 0.045),
		"concrete": Color(0.48, 0.47, 0.44), "green": Color(0.05, 0.12, 0.07),
		"gold": Color(0.55, 0.42, 0.12), "oxide": Color(0.22, 0.07, 0.04),
		"galv": Color(0.46, 0.47, 0.46), "glass": Color(0.6, 0.7, 0.72, 0.25),
		"blue": Color(0.015, 0.19, 0.5), "sign": Color(0.82, 0.80, 0.74), "lens_off": Color(0.03, 0.03, 0.03),
	}.get(name, Color(0.03, 0.03, 0.03))
	m.albedo_color = col
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.75 if name in ["wood", "concrete"] else 0.4
	m.metallic = 0.5 if name in ["iron", "galv", "gold", "oxide", "green"] else 0.0
	if name == "glass":
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.05
	if name.begins_with("lens_") and name != "lens_off":
		var lc: Color = LENS[name.substr(5)]
		m.albedo_color = lc
		m.emission_enabled = true
		m.emission = lc
		m.emission_energy_multiplier = 3.0
	if name.begins_with("globe_"):
		m.albedo_color = Color(0.035, 0.32, 0.09) if name == "globe_green" else Color(0.75, 0.77, 0.72)
		m.emission_enabled = true
		m.emission = m.albedo_color
		m.emission_energy_multiplier = 0.25
	return StreetSnow.material(m) if name in ["wood", "iron", "concrete", "green", "galv"] else m

## Road segments near the eye on a coarse grid, for nearest-kerb lookups.
class RoadIndex:
	var _cells := {}
	var _cell := 20.0
	var _m2u := 1.0

	func _init(data: LocationData, m2u: float, reach_u: float, centre: Vector2 = Vector2.ZERO) -> void:
		_cell = 20.0 * m2u
		_m2u = m2u
		var r2 := reach_u * reach_u
		for rd in data.roads:
			if not (rd is Dictionary):
				continue
			var d: Dictionary = rd
			if bool(d.get("tunnel", false)) or bool(d.get("area", false)):
				continue
			if str(d.get("class", "")) not in StreetProps.LIT:
				continue
			var pts: PackedVector2Array = d.get("points", PackedVector2Array())
			var half := float(d.get("width_m", 6.0)) * 0.5 * m2u
			var bridge := bool(d.get("bridge", false))
			for i in pts.size() - 1:
				var a := pts[i]
				var b := pts[i + 1]
				if Geometry2D.get_closest_point_to_segment(centre, a, b).distance_squared_to(centre) > r2:
					continue
				var lo := Vector2i(floori(minf(a.x, b.x) / _cell), floori(minf(a.y, b.y) / _cell))
				var hi := Vector2i(floori(maxf(a.x, b.x) / _cell), floori(maxf(a.y, b.y) / _cell))
				for cx in range(lo.x, hi.x + 1):
					for cz in range(lo.y, hi.y + 1):
						var k := Vector2i(cx, cz)
						if not _cells.has(k):
							_cells[k] = []
						(_cells[k] as Array).append([a, b, half, bridge])

	## {point, dir, half, bridge} of the nearest segment within `max_d`, or {}.
	func nearest(p: Vector2, max_d: float) -> Dictionary:
		var best := {}
		var best_d := max_d
		var c := Vector2i(floori(p.x / _cell), floori(p.y / _cell))
		var reach := int(ceil(max_d / _cell))
		for cx in range(c.x - reach, c.x + reach + 1):
			for cz in range(c.y - reach, c.y + reach + 1):
				for s in _cells.get(Vector2i(cx, cz), []):
					var a: Vector2 = s[0]
					var b: Vector2 = s[1]
					var q := Geometry2D.get_closest_point_to_segment(p, a, b)
					var d := q.distance_to(p) + (BRIDGE_BIAS_M * _m2u if bool(s[3]) else 0.0)
					if d < best_d and a.distance_to(b) > 0.001:
						best_d = d
						best = {"point": q, "dir": (b - a).normalized(), "half": float(s[2]), "bridge": bool(s[3])}
		return best
