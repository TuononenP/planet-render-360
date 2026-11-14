class_name UtilityPoles
extends RefCounted

## Japanese and Korean street utility poles (denchū) with their sagging
## overhead cables: the strongest Tokyo street signature.
## * Where: JP and KR streets of CLASSES within RADIUS_M of the eye (no
##   tunnel, bridge or paved square's outline), one pole every SPACING_M
##   along ONE side of each street, just past the kerb (RoadWidths'
##   `width_m`), JUNCTION_CUT_M clear of junctions and off footprints,
##   trees, furniture, tram beds and water.
## * Poles: tapered grey concrete, 10–11.5 m, one or two crossarms; every
##   third or fourth carries a pole transformer, some a bracket lamp.
##   High and up, instanced (a MultiMesh per part).
## * Cables: 3–6 per street at slightly different heights, sagging from
##   pole to pole, plus a service drop to a wall within DROP_M from some
##   poles; desktop Ultra only, merged into at most four spatial chunks.
const COUNTRIES := ["JP", "KR"]
const CLASSES := ["residential", "tertiary", "unclassified", "service", "living_street", "secondary"]
const RADIUS_M := 600.0
const SPACING_M := 30.0
const JUNCTION_CUT_M := 6.0
## Pole axis past the carriageway edge (m).
const KERB_OUT_M := 0.3
const MAX_POLES := 600
const MAX_DRAW_CALLS := 12
## Two poles further apart than this along a street carry no span.
const SPAN_MAX_M := SPACING_M * 2.1
const DROP_M := 15.0
const DROP_SHARE := 0.35
## Nominal pole height of the meshes (m); instances scale to their own.
const MESH_H := 11.0
const ARM1_Y := 10.1
const ARM2_Y := 8.9
const INSULATOR_M := 0.15
## Cable attachments [across the road (m), level]: levels 0 top crossarm,
## 1 second crossarm, 2/3 telecom clamps (all scale with the pole). A street with
## n cables takes the first n; five or more need the second crossarm.
const SLOTS := [[-0.6, 0], [0.6, 0], [0.14, 2], [0.0, 0], [-0.45, 1], [0.14, 3]]
const TELECOM_Y := [7.2, 7.6]
const _BUILD_CELL_M := 15.0

static var _meshes: Dictionary = {}
static var _mats: Dictionary = {}

## Whether `data`'s place and quality get poles at all.
static func enabled(data: LocationData) -> bool:
	return data.country.to_upper() in COUNTRIES \
		and RenderSettings.clamp_preset(data.quality_preset) >= RenderSettings.Preset.HIGH

## Whether a road entry carries a pole line.
static func carries(road: Variant) -> bool:
	if not (road is Dictionary):
		return false
	var r: Dictionary = road
	return str(r.get("class", "")) in CLASSES and not bool(r.get("tunnel", false)) \
		and not bool(r.get("bridge", false)) and not bool(r.get("area", false)) \
		and (r.get("points", PackedVector2Array()) as PackedVector2Array).size() >= 2

## {"poles": [{pos (ground, world units), toward (unit, to the road), h
## (m), arms, transformer, lamp, road, d2, drop ([from, to] or [])}],
## "spans": [{a, b (pole indices, consecutive on one street), cables
## ([[from, to], ...] attachment points)}]}.
## `mask` (StreetProps') keeps poles out of every carriageway and track,
## not only clear of their own street's junctions.
static func plan(data: LocationData, ground: GroundTruth, mask: VegetationMask = null) -> Dictionary:
	var out := {"poles": [], "spans": []}
	if not enabled(data) or data.roads.is_empty():
		return out
	var m := WorldScale.metres_to_units()
	var centre := View360.spawn_xz(data)
	var r2 := pow(RADIUS_M * m, 2.0)
	var junc := RoadSurface.junctions(data)
	var obstacles := ParkedCars.obstacle_grid(data, m)
	var rings := OverheadWires._ring_grid(data, _BUILD_CELL_M * m)
	var lines: Array = []
	var d2s: Array = []
	for ri in data.roads.size():
		var road: Variant = data.roads[ri]
		if not carries(road):
			continue
		var line := _stations(road, ri, data, ground, centre, r2, junc, obstacles, rings, m, mask)
		for p: Dictionary in line:
			d2s.append(float(p["d2"]))
		lines.append(line)
	# The cap drops the poles furthest from the eye, whatever the way order.
	var cutoff := INF
	if d2s.size() > MAX_POLES:
		d2s.sort()
		cutoff = float(d2s[MAX_POLES - 1])
	var poles: Array = out["poles"]
	var drops := RenderQuality.ultra_desktop(data.quality_preset)
	for line: Array in lines:
		var prev := -1
		for p: Dictionary in line:
			if float(p["d2"]) > cutoff or poles.size() >= MAX_POLES:
				prev = -1
				continue
			var i := poles.size()
			p["drop"] = _drop(p, p["drop"], data, ground, rings, m) if drops and p["drop"] is Vector2 else []
			poles.append(p)
			if prev >= 0:
				var a: Dictionary = poles[prev]
				var pa: Vector3 = a["pos"]
				var pb: Vector3 = p["pos"]
				if Vector2(pa.x, pa.z).distance_to(Vector2(pb.x, pb.z)) <= SPAN_MAX_M * m:
					(out["spans"] as Array).append({"a": prev, "b": i, "cables": _cables(a, p, m)})
			prev = i
	return out

## A side-street lamp this close (m) to a planned pole gives way to it.
const LAMP_CLEAR_M := 15.0

## Planned pole positions bucketed by LAMP_CLEAR_M cells (world x/z).
static func pole_grid(plan_out: Dictionary) -> Dictionary:
	var grid := {}
	var cell := LAMP_CLEAR_M * WorldScale.metres_to_units()
	for p: Dictionary in (plan_out.get("poles", []) as Array):
		var pos: Vector3 = p["pos"]
		var key := Vector2i(floori(pos.x / cell), floori(pos.z / cell))
		if not grid.has(key):
			grid[key] = []
		(grid[key] as Array).append(Vector2(pos.x, pos.z))
	return grid

## Whether a planned pole stands within LAMP_CLEAR_M of `p` (world x/z).
static func near_pole(grid: Dictionary, p: Vector2) -> bool:
	if grid.is_empty():
		return false
	var cell := LAMP_CLEAR_M * WorldScale.metres_to_units()
	var c := Vector2i(floori(p.x / cell), floori(p.y / cell))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for q: Vector2 in (grid.get(c + Vector2i(dx, dz), []) as Array):
				if q.distance_to(p) <= cell:
					return true
	return false

## One street's poles in order along it.
static func _stations(road: Dictionary, ri: int, data: LocationData, ground: GroundTruth,
		centre: Vector2, r2: float, junc: Dictionary, obstacles: Dictionary, rings: Dictionary,
		m: float, mask: VegetationMask = null) -> Array:
	var pts: PackedVector2Array = road["points"]
	var cls := str(road.get("class", ""))
	var half := float(road.get("width_m", OsmTags.road_class_width(cls))) * 0.5
	var off := (half + KERB_OUT_M) * m
	var side := 1.0 if _hash(pts[0].x, pts[0].y, 2.7) < 0.5 else -1.0
	var cables := 3 + int(_hash(pts[0].x, pts[0].y, 5.1) * 3.999)
	var transformer_every := 3 + int(_hash(pts[0].x, pts[0].y, 8.3) * 1.999)
	var step := SPACING_M * m
	var t := step * 0.5
	# The nudge reaches 8 m and the kerb offset `off`: past this the spot is out.
	var reach2 := pow(sqrt(r2) + 8.0 * m + off, 2.0)
	var line: Array = []
	var k := 0
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var seg := a.distance_to(b)
		if seg < 0.001:
			continue
		var dir := (b - a) / seg
		var nrm := Vector2(dir.y, -dir.x) * side
		while t < seg:
			if (a + dir * t).distance_squared_to(centre) > reach2:
				t += step
				continue
			var spot := Vector2(INF, INF)
			# Nudged along the street up to 8 m when the spot is taken.
			for shift: float in [0.0, 4.0, -4.0, 8.0, -8.0]:
				var tt := clampf(t + shift * m, 0.0, seg)
				var p := a + dir * tt + nrm * off
				if _free(p, ground, junc, obstacles, rings, data, m, mask):
					spot = p
					break
			t += step
			if spot.x == INF:
				continue
			var d2 := spot.distance_squared_to(centre)
			if d2 > r2:
				continue
			line.append({"pos": Vector3(spot.x, ground.height_at_world(spot.x, spot.y), spot.y),
				"toward": -nrm, "h": 10.0 + 1.5 * _hash(spot.x, spot.y, 1.9), "arms": 2 if cables >= 5 else 1,
				"transformer": k % transformer_every == 1, "lamp": _hash(spot.x, spot.y, 4.4) < 0.3,
				"road": ri, "d2": d2, "cables": cables,
				"drop": spot if _hash(spot.x, spot.y, 6.6) < DROP_SHARE else []})
			k += 1
		t -= seg
	return line

static func _free(p: Vector2, ground: GroundTruth, junc: Dictionary, obstacles: Dictionary,
		rings: Dictionary, data: LocationData, m: float, mask: VegetationMask = null) -> bool:
	if ParkedCars._near_junction(p, junc, JUNCTION_CUT_M * m) or ParkedCars.blocked(p, obstacles, m):
		return false
	if ground.water_at(p.x, p.y) > 0.0:
		return false
	if mask != null and mask.blocked(p.x, p.y, VegetationMask.ROAD, 0.0):
		return false
	var cell := _BUILD_CELL_M * m
	for bi: int in rings.get(Vector2i(floori(p.x / cell), floori(p.y / cell)), []):
		var ring: PackedVector2Array = data.buildings[bi].get("footprint", PackedVector2Array())
		if ring.size() >= 3 and Geometry2D.is_point_in_polygon(p, ring):
			return false
	return true

## World point of pole `p`'s cable `slot` (an entry of SLOTS).
static func attach(p: Dictionary, slot: Array, m: float) -> Vector3:
	var level := int(slot[1])
	var h := float(p["h"])
	var y: float
	if level >= 2:
		y = float(TELECOM_Y[level - 2]) * h / MESH_H
	else:
		y = ((ARM1_Y if level == 0 else ARM2_Y) + INSULATOR_M) * h / MESH_H
	var toward: Vector2 = p["toward"]
	var across := toward * float(slot[0]) * m
	return (p["pos"] as Vector3) + Vector3(across.x, y * m, across.y)

static func _cables(a: Dictionary, b: Dictionary, m: float) -> Array:
	var out: Array = []
	for c in mini(int(a["cables"]), int(b["cables"])):
		out.append([attach(a, SLOTS[c], m), attach(b, SLOTS[c], m)])
	return out

## A service drop from pole `p`'s telecom clamp to the nearest wall
## within DROP_M of `at`, or [] when none stands that near.
static func _drop(p: Dictionary, at: Vector2, data: LocationData, ground: GroundTruth,
		rings: Dictionary, m: float) -> Array:
	var best := DROP_M * m
	var hit := Vector2(INF, INF)
	var wall_h := 0.0
	var cell := _BUILD_CELL_M * m
	# _BUILD_CELL_M is DROP_M: the point's cell lists every wall in reach.
	for bi: int in rings.get(Vector2i(floori(at.x / cell), floori(at.y / cell)), []):
		var b: Dictionary = data.buildings[bi]
		var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
		for j in ring.size():
			var q := Geometry2D.get_closest_point_to_segment(at, ring[j], ring[(j + 1) % ring.size()])
			if at.distance_to(q) < best and float(b.get("height", 0.0)) >= 3.0:
				best = at.distance_to(q)
				hit = q
				wall_h = float(b.get("height", 0.0))
	if hit.x == INF or best < 1.0 * m:
		return []
	var to := Vector3(hit.x, ground.height_at_world(hit.x, hit.y) + minf(wall_h * 0.8, 4.5) * m, hit.y)
	return [attach(p, SLOTS[2], m), to]

## `planned`: a plan() result to reuse (StreetProps plans before its lamps).
static func build(root: Node3D, data: LocationData, ground: GroundTruth,
		planned: Dictionary = {}) -> Dictionary:
	var stats := {"poles": 0, "spans": 0, "cables": 0, "draw_calls": 0}
	var plan_out := planned if planned.has("poles") else plan(data, ground)
	var poles: Array = plan_out["poles"]
	if poles.is_empty():
		return stats
	var m := WorldScale.metres_to_units()
	var holder := Node3D.new()
	holder.name = "UtilityPoles"
	var parts := {"pole": [], "arm2": [], "transformer": [], "lamp": []}
	for p: Dictionary in poles:
		var toward: Vector2 = p["toward"]
		var yaw := atan2(-toward.y, toward.x)
		var pos: Vector3 = p["pos"]
		var s := float(p["h"]) / MESH_H
		var basis := Basis(Vector3.UP, yaw)
		(parts["pole"] as Array).append(Transform3D(basis.scaled(Vector3(m, m * s, m)), pos))
		if int(p["arms"]) >= 2:
			(parts["arm2"] as Array).append(Transform3D(basis.scaled(Vector3(m, m * s, m)), pos))
		if p["transformer"]:
			(parts["transformer"] as Array).append(Transform3D(basis.scaled(Vector3.ONE * m),
				pos + Vector3.UP * 0.72 * float(p["h"]) * m))
		if p["lamp"]:
			(parts["lamp"] as Array).append(Transform3D(basis.scaled(Vector3.ONE * m), pos + Vector3.UP * 5.4 * m))
	var calls := 0
	for part in parts:
		var xf: Array = parts[part]
		if xf.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _mesh(part)
		mm.instance_count = xf.size()
		for i in xf.size():
			mm.set_instance_transform(i, xf[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "UtilityPoles_%s" % part
		mmi.multimesh = mm
		holder.add_child(mmi)
		calls += mm.mesh.get_surface_count()
	if RenderQuality.ultra_desktop(data.quality_preset):
		var cable_stats := _build_cables(holder, plan_out, View360.spawn_xz(data), m)
		calls += int(cable_stats["draw_calls"])
		stats["cables"] = cable_stats["cables"]
	root.add_child(holder)
	stats["poles"] = poles.size()
	stats["spans"] = (plan_out["spans"] as Array).size()
	stats["draw_calls"] = calls
	return stats

## Every span's cables and the service drops as thin sagging tubes, one
## mesh per quadrant around the eye (at most four draw calls).
static func _build_cables(holder: Node3D, plan_out: Dictionary, centre: Vector2, m: float) -> Dictionary:
	var chunks := {}
	var count := 0
	var lines: Array = []
	for span: Dictionary in plan_out["spans"]:
		for c: Array in span["cables"]:
			lines.append([c[0], c[1], 0.02 * (c[0] as Vector3).distance_to(c[1]) + 0.15 * m])
	for p: Dictionary in plan_out["poles"]:
		var drop: Array = p["drop"] if p["drop"] is Array else []
		if not drop.is_empty():
			lines.append([drop[0], drop[1], 0.3 * m])
	for line: Array in lines:
		var a: Vector3 = line[0]
		var b: Vector3 = line[1]
		var key := Vector2i(1 if (a.x + b.x) * 0.5 >= centre.x else 0, 1 if (a.z + b.z) * 0.5 >= centre.y else 0)
		if not chunks.has(key):
			chunks[key] = TreeMeshLibrary.Buf.new()
		_cable(chunks[key], sag(a, b, float(line[2]), 6), 0.016 * m)
		count += 1
	for key in chunks:
		var arr := (chunks[key] as TreeMeshLibrary.Buf).arrays()
		arr[Mesh.ARRAY_INDEX] = ParkedCars.front_faces(arr[Mesh.ARRAY_INDEX])
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(0, _material("cable"))
		var mi := MeshInstance3D.new()
		mi.name = "UtilityCables_%d_%d" % [key.x, key.y]
		mi.mesh = mesh
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(mi)
	return {"cables": count, "draw_calls": chunks.size()}

## A catenary-ish polyline from `a` to `b` hanging `drop` at mid-span.
static func sag(a: Vector3, b: Vector3, drop: float, segments: int) -> Array:
	var out: Array = []
	for i in segments + 1:
		var t := float(i) / float(segments)
		out.append(a.lerp(b, t) - Vector3.UP * drop * 4.0 * t * (1.0 - t))
	return out

static func _cable(buf: TreeMeshLibrary.Buf, pts: Array, radius: float) -> void:
	var radii: Array = []
	radii.resize(pts.size())
	radii.fill(radius)
	TreeMeshLibrary._tube(buf, pts, radii, 4, 1.0, 1.0)

## Part meshes in metres about the pole axis, +X toward the street.
static func _mesh(part: String) -> ArrayMesh:
	if _meshes.has(part):
		return _meshes[part]
	var body := TreeMeshLibrary.Buf.new()
	var glass := TreeMeshLibrary.Buf.new()
	match part:
		"pole":
			TreeMeshLibrary._tube(body, [Vector3(0, -0.3, 0), Vector3(0, MESH_H, 0)], [0.16, 0.1], 8, 0.85, 1.0)
			_arm(body, ARM1_Y, 0.95, [-0.6, 0.0, 0.6])
			# Telecom clamps on the street side.
			for y: float in TELECOM_Y:
				TreeMeshLibrary._tube(body, [Vector3(0.0, y, 0), Vector3(0.18, y, 0)], [0.03, 0.03], 4, 1.0, 1.0)
		"arm2":
			_arm(body, ARM2_Y, 0.75, [-0.45, 0.45])
		"transformer":
			# A grey can on two brackets on the far side of the pole.
			TreeMeshLibrary._tube(body, [Vector3(-0.45, 0.0, 0), Vector3(-0.45, 1.05, 0)], [0.26, 0.26], 10, 0.8, 1.0)
			TreeMeshLibrary._tube(body, [Vector3(-0.45, 1.05, 0), Vector3(-0.45, 1.13, 0)], [0.26, 0.12], 10, 1.0, 1.0)
			for y in [0.2, 0.85]:
				TreeMeshLibrary._tube(body, [Vector3(-0.08, y, 0), Vector3(-0.3, y, 0)], [0.035, 0.035], 4, 1.0, 1.0)
			for z in [-0.08, 0.08]:
				TreeMeshLibrary._tube(body, [Vector3(-0.45, 1.13, z), Vector3(-0.45, 1.35, z)], [0.03, 0.03], 4, 1.0, 1.0)
		"lamp":
			TreeMeshLibrary._tube(body, [Vector3(0.08, 0.0, 0), Vector3(0.6, 0.32, 0), Vector3(1.0, 0.38, 0)],
				[0.035, 0.03, 0.03], 6, 1.0, 1.0)
			TreeMeshLibrary._tube(body, [Vector3(0.9, 0.36, 0), Vector3(1.38, 0.36, 0)], [0.09, 0.07], 8, 1.0, 1.0)
			TreeMeshLibrary._tube(glass, [Vector3(1.16, 0.3, 0), Vector3(1.16, 0.27, 0)], [0.08, 0.08], 8, 1.0, 1.0)
	var mesh := ArrayMesh.new()
	for pair in [[body, part], [glass, "glass"]]:
		var arr := (pair[0] as TreeMeshLibrary.Buf).arrays()
		if (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():
			continue
		arr[Mesh.ARRAY_INDEX] = ParkedCars.front_faces(arr[Mesh.ARRAY_INDEX])
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(mesh.get_surface_count() - 1,
			_material("glass" if pair[1] == "glass" else ("metal" if pair[1] == "lamp" else "concrete")))
	_meshes[part] = mesh
	return mesh

## A crossarm across the street at `y` (half length `reach`) with an
## insulator under each cable.
static func _arm(buf: TreeMeshLibrary.Buf, y: float, reach: float, insulators: Array) -> void:
	TreeMeshLibrary._tube(buf, [Vector3(-reach, y, 0), Vector3(reach, y, 0)], [0.055, 0.055], 4, 1.0, 1.0)
	for x: float in insulators:
		TreeMeshLibrary._tube(buf, [Vector3(x, y + 0.04, 0), Vector3(x, y + INSULATOR_M, 0)], [0.045, 0.03], 6, 1.0, 1.0)

static func _material(kind: String) -> StandardMaterial3D:
	if _mats.has(kind):
		return _mats[kind]
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	match kind:
		"concrete":
			mat.albedo_color = Color(0.5, 0.5, 0.48)
			mat.roughness = 0.9
		"metal":
			mat.albedo_color = Color(0.42, 0.43, 0.43)
			mat.metallic = 0.5
			mat.roughness = 0.45
		"cable":
			mat.albedo_color = Color(0.035, 0.035, 0.04)
			mat.roughness = 0.6
		"glass":
			mat.albedo_color = Color(1.0, 0.97, 0.92)
			mat.emission_enabled = true
			mat.emission = mat.albedo_color
			mat.roughness = 0.15
			CityLights.mark_glow(mat, 0.55)  # lit from dusk, dark by day
	_mats[kind] = mat
	return mat

static func _hash(x: float, z: float, salt: float) -> float:
	return ParkedCars._hash(x, z, salt)
