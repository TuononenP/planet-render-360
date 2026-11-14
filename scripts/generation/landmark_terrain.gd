class_name LandmarkTerrain
extends RefCounted

## Authored islands, crags and mounds replace the DEM inside their own
## footprint. Their ground also supplies the camera and saved-view datum.

const ISLANDS := ["alcatraz", "burj_al_arab"]
const RELIEFS := ["mont_saint_michel", "edinburgh_castle", "monks_mound"]

static func islands(data: LocationData) -> Array:
	return _sites(data, ISLANDS)

static func _sites(data: LocationData, types: Array) -> Array:
	var out: Array = []
	if data.landmark_type in types:
		out.append([TerrainBuilder.landmark_world_pos(data), LocationData.entry_for_type(data.landmark_type)])
	for c in data.landmark_candidates:
		var type := str(c.get("type", ""))
		if type in types:
			out.append([Vector2(float(c["x"]), float(c["z"])), LocationData.entry_for_type(type)])
	return out

## Explicit sea-level landmarks also identify the visible ocean when
## OSM is unavailable. Inland river bridges retain their local datum.
static func has_sea(data: LocationData) -> bool:
	if str(LocationData.entry_for_type(data.landmark_type).get("base", "")) == "sea":
		return true
	for c in data.landmark_candidates:
		if str(c.get("base", "")) == "sea":
			return true
	return false

static func local_xz(p: Vector2, site: Array) -> Vector2:
	var d := (p - (site[0] as Vector2)) / WorldScale.metres_to_units()
	var axis := LandmarkSites.axis(site[1])
	return Vector2(d.dot(axis), d.dot(Vector2(-axis.y, axis.x)))

## The authored island ground, or the DEM outside its shoreline.
static func ground_y(data: LocationData, ground: GroundTruth, p: Vector2) -> float:
	for site in islands(data):
		var local := local_xz(p, site)
		var h := LandmarkSfAlcatraz.ground_height(local) if str(site[1]["type"]) == "alcatraz" \
			else (6.0 if local.distance_to(Vector2(0, 2)) <= 60.0 else -1.0)
		if h >= 0.0:
			return ground.render_y(0.0) + h * WorldScale.metres_to_units()
	for site in _sites(data, RELIEFS):
		var h := _relief_height(str(site[1]["type"]), local_xz(p, site))
		if is_finite(h):
			var at: Vector2 = site[0]
			var entry: Dictionary = site[1]
			var half := minf(LandmarkSites.clear_m(entry) * 0.5, 45.0)
			var base := TerrainBuilder._hero_y(data, ground, at.x, at.y, entry, half)
			return maxf(ground.height_at_world(p.x, p.y), base + h * WorldScale.metres_to_units())
	return ground.height_at_world(p.x, p.y)

## The camera and saved-view height share the same dry surface datum.
static func floor_y(data: LocationData, ground: GroundTruth, p: Vector2) -> float:
	var y := maxf(ground_y(data, ground, p), ground.water_level_at(p.x, p.y))
	if WaterBuilder._has_coastline(data) or has_sea(data):
		y = maxf(y, ground.render_y(0.0))
	return y

## Join an authored crag/mound's bottom edge to the real terrain. A
## corrected datum can expose a short gap where the DEM is lower.
static func stitch(root: Node3D, ground: GroundTruth, type: String) -> void:
	if not outline(type).is_empty():
		_plinth(root, ground, type)
		return
	if type not in RELIEFS:
		return
	var model := root.get_node("Model") as Node3D
	var to_world := root.transform * model.transform
	var to_model := to_world.affine_inverse()
	var lm := LandmarkMesh.new()
	var overrides := {}
	for part in LandmarkBuilder.parts(root):
		if str(part.name) != ("Turf" if type == "monks_mound" else "Rock"):
			continue
		var key := "GroundSkirt"
		lm.use(key, part.mesh.surface_get_material(0))
		overrides[key] = part.get_surface_override_material(0)
		var arrays := part.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var floor := part.mesh.get_aabb().position.y
		for i in range(0, verts.size(), 3):
			for j in 3:
				var a := verts[i + j]
				var b := verts[i + (j + 1) % 3]
				if absf(a.y - floor) > 0.01 or absf(b.y - floor) > 0.01:
					continue
				var wa := to_world * a
				var wb := to_world * b
				var ya := minf(wa.y, ground.height_at_world(wa.x, wa.z) - 0.3)
				var yb := minf(wb.y, ground.height_at_world(wb.x, wb.z) - 0.3)
				if wa.y - ya < 0.05 and wb.y - yb < 0.05:
					continue
				var low_a := to_model * Vector3(wa.x, ya, wa.z)
				var low_b := to_model * Vector3(wb.x, yb, wb.z)
				var n := Vector3(a.x + b.x, 0, a.z + b.z).normalized()
				lm.quad(key, a, b, low_b, low_a, n)
	for part in lm.commit(model):
		if overrides.get(str(part.name)) != null:
			part.set_surface_override_material(0, overrides[str(part.name)])

## Model-local outline (metres, before yaw) of a landmark extruded from
## its OSM footprint (the capital-region malls and the Redi podium),
## empty for every other model.
static func outline(type: String) -> PackedVector2Array:
	return LandmarkFhMallFootprints.outline(type)

## Seat of an outline-built model: the median ground along its outline,
## so a long mall on a slope is buried uphill about as much as it stands
## proud downhill, where _plinth closes the gap. Render units.
static func outline_base_y(data: LocationData, ground: GroundTruth, at: Vector2,
		entry: Dictionary) -> float:
	var axis := LandmarkSites.axis(entry)
	var side := Vector2(-axis.y, axis.x)
	var ys: Array[float] = []
	for p in _outline_samples(outline(str(entry.get("type", "")))):
		var w := at + (axis * p.x + side * p.y) * WorldScale.metres_to_units()
		ys.append(TerrainBuilder.site_ground_y(data, ground, w.x, w.y))
	if ys.is_empty():
		return TerrainBuilder.site_ground_y(data, ground, at.x, at.y)
	ys.sort()
	return ys[ys.size() / 2]

## Outline vertices plus points at most PLINTH_STEP_M apart along each edge.
const PLINTH_STEP_M := 8.0
static func _outline_samples(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var n := maxi(ceili(a.distance_to(b) / PLINTH_STEP_M), 1)
		for k in n:
			out.append(a.lerp(b, float(k) / float(n)))
	return out

## The plinth (PlinthStyle) stands this far proud of a landmark's wall
## face, so the base reads as its own course under the walls, and its
## coping is twice a house's: a mall-sized wall needs a heavier cap.
const PLINTH_PROUD_M := 0.12
const COPING_DEPTH_M := PlinthStyle.COPING_DEPTH_M * 2.0

## Carry an outline-built model down to the terrain wherever the ground
## along its outline lies below the model base (a mall's downhill end on
## a slope): a granite plinth with a dressed coping where it is deep
## enough to show one, upgraded alongside the walls on Ultra.
static func _plinth(root: Node3D, ground: GroundTruth, type: String) -> void:
	var model := root.get_node("Model") as Node3D
	var wall: MeshInstance3D = null
	for part in LandmarkBuilder.parts(root):
		if str(part.name) == "Wall":
			wall = part
	if wall == null:
		return
	var to_world := root.transform * model.transform
	var to_model := to_world.affine_inverse()
	var lm := LandmarkMesh.new()
	lm.use("Plinth", LandmarkMaterials.pbr(PlinthStyle.BODY_SET, PlinthStyle.BODY_HEX, 3.0))
	lm.use("Coping", LandmarkMaterials.pbr(PlinthStyle.COPING_SET, PlinthStyle.COPING_HEX, 2.0))
	var pts := _outline_samples(outline(type))
	var turn := 1.0 if LandmarkFhMallFootprints.area_of(pts) > 0.0 else -1.0
	var count := pts.size()
	# Mitred vertex directions, so the proud faces meet at corners.
	var miters := PlinthStyle.miters(pts, turn)
	for i in count:
		var k := (i + 1) % count
		var wa := to_world * Vector3(pts[i].x, 0.0, pts[i].y)
		var wb := to_world * Vector3(pts[k].x, 0.0, pts[k].y)
		var ya := _plinth_floor(ground, wa)
		var yb := _plinth_floor(ground, wb)
		if wa.y - ya < 0.05 and wb.y - yb < 0.05:
			continue
		var e := pts[k] - pts[i]
		var n := Vector3(e.y, 0.0, -e.x).normalized() * turn
		var pa := pts[i] + miters[i] * PLINTH_PROUD_M
		var pb := pts[k] + miters[k] * PLINTH_PROUD_M
		var low_a := to_model * Vector3(wa.x, ya, wa.z)
		var low_b := to_model * Vector3(wb.x, yb, wb.z)
		lm.quad("Plinth", Vector3(pa.x, low_a.y, pa.y), Vector3(pb.x, low_b.y, pb.y),
			Vector3(pb.x, 0.0, pb.y), Vector3(pa.x, 0.0, pa.y), n)
		if wa.y - ya < COPING_DEPTH_M + 0.25 or wb.y - yb < COPING_DEPTH_M + 0.25:
			# Too shallow for coping: close the proud top back to the wall.
			lm.quad("Plinth", Vector3(pts[i].x, 0.0, pts[i].y), Vector3(pts[k].x, 0.0, pts[k].y),
				Vector3(pb.x, 0.0, pb.y), Vector3(pa.x, 0.0, pa.y), Vector3.UP)
			continue
		# Coping: proud face, drip underside and the ledge back to the wall.
		var ca := pts[i] + miters[i] * (PLINTH_PROUD_M + PlinthStyle.COPING_PROUD_M)
		var cb := pts[k] + miters[k] * (PLINTH_PROUD_M + PlinthStyle.COPING_PROUD_M)
		var top := -0.02
		var bot := -COPING_DEPTH_M
		lm.quad("Coping", Vector3(ca.x, bot, ca.y), Vector3(cb.x, bot, cb.y),
			Vector3(cb.x, top, cb.y), Vector3(ca.x, top, ca.y), n)
		lm.quad("Coping", Vector3(pa.x, top, pa.y), Vector3(pb.x, top, pb.y),
			Vector3(cb.x, top, cb.y), Vector3(ca.x, top, ca.y), Vector3.UP)
		lm.quad("Coping", Vector3(ca.x, bot, ca.y), Vector3(cb.x, bot, cb.y),
			Vector3(pb.x, bot, pb.y), Vector3(pa.x, bot, pa.y), Vector3.DOWN)
	var upgraded := wall.get_surface_override_material(0) is ShaderMaterial
	for part in lm.commit(model):
		if upgraded:
			part.set_surface_override_material(0,
				LandmarkShader.swap(part.mesh.surface_get_material(0) as StandardMaterial3D))

## Plinth bottom under world point `w`: just below the detailed ground
## when that lies under the base, else the base (no plinth beyond the
## detailed extent, where haze hides the far terrain's coarse seat).
static func _plinth_floor(ground: GroundTruth, w: Vector3) -> float:
	if not ground.is_inside(w.x, w.z):
		return w.y
	return minf(w.y, ground.height_at_world(w.x, w.z) - 0.3)

## Drop DEM triangles touching the island envelope. A small margin
## keeps coarse edges outside the rock; the sea closes the gap. Test
## intersection: far triangles can cross the island without a vertex
## on it. All input coordinates are render units, local XZ is metres.
static func cut_indices(data: LocationData, verts: PackedVector3Array,
		indices: PackedInt32Array) -> PackedInt32Array:
	var sites := islands(data)
	var out := indices
	for site in sites:
		var bounds := Rect2(-269.0, -122.0, 557.0, 222.0) if str(site[1]["type"]) == "alcatraz" \
			else Rect2(-72.0, -70.0, 144.0, 144.0)
		var corners := PackedVector2Array([bounds.position, Vector2(bounds.end.x, bounds.position.y),
			bounds.end, Vector2(bounds.position.x, bounds.end.y)])
		var axis := LandmarkSites.axis(site[1])
		var side := Vector2(-axis.y, axis.x)
		var world_box := Rect2(site[0], Vector2.ZERO)
		for c in corners:
			world_box = world_box.expand((site[0] as Vector2) + (axis * c.x + side * c.y) * WorldScale.metres_to_units())
		var keep := PackedInt32Array()
		for i in range(0, out.size(), 3):
			var a := Vector2(verts[out[i]].x, verts[out[i]].z)
			var b := Vector2(verts[out[i + 1]].x, verts[out[i + 1]].z)
			var c := Vector2(verts[out[i + 2]].x, verts[out[i + 2]].z)
			var box := Rect2(a, Vector2.ZERO).expand(b).expand(c)
			if box.intersects(world_box, true):
				var tri := PackedVector2Array([local_xz(a, site), local_xz(b, site), local_xz(c, site)])
				if not Geometry2D.intersect_polygons(tri, corners).is_empty():
					continue
			keep.append_array([out[i], out[i + 1], out[i + 2]])
		out = keep
	# On land, remove only fully covered triangles. The authored surface
	# closes the hole; boundary triangles retain the surrounding hillside.
	for site in _sites(data, RELIEFS):
		var type := str(site[1]["type"])
		var inside := PackedByteArray()
		inside.resize(verts.size())
		for i in verts.size():
			var p := local_xz(Vector2(verts[i].x, verts[i].z), site)
			inside[i] = 1 if _relief_contains(type, p) else 0
		var keep := PackedInt32Array()
		for i in range(0, out.size(), 3):
			if inside[out[i]] != 0 and inside[out[i + 1]] != 0 and inside[out[i + 2]] != 0:
				var a := local_xz(Vector2(verts[out[i]].x, verts[out[i]].z), site)
				var b := local_xz(Vector2(verts[out[i + 1]].x, verts[out[i + 1]].z), site)
				var c := local_xz(Vector2(verts[out[i + 2]].x, verts[out[i + 2]].z), site)
				if _relief_contains(type, (a + b) * 0.5) and _relief_contains(type, (b + c) * 0.5) \
						and _relief_contains(type, (c + a) * 0.5):
					continue
			keep.append_array([out[i], out[i + 1], out[i + 2]])
		out = keep
	return out

## Conservative interior of each authored terrain mesh. Profiles mirror
## LandmarkWestEarly, LandmarkEdinburgh and LandmarkAmhEarth; their edge
## jitter stays outside this inset, so there are no gaps around the cut.
static func _relief_contains(type: String, p: Vector2) -> bool:
	return is_finite(_relief_height(type, p / 0.95))

static func _relief_height(type: String, p: Vector2) -> float:
	if absf(p.x) > 165.0 or absf(p.y) > 150.0:
		return -INF
	if type == "mont_saint_michel":
		var r := p.length()
		return _profile(PackedVector2Array([Vector2(50, 0), Vector2(53, -2), Vector2(55, -8),
			Vector2(58, -16), Vector2(62, -25), Vector2(68, -36), Vector2(74, -45)]), r) if r < 68.0 else -INF
	if type == "edinburgh_castle":
		var r := Vector2(p.x / 1.6, p.y).length()
		return _profile(PackedVector2Array([Vector2(68, 0), Vector2(73, -5), Vector2(78, -12),
			Vector2(83, -22), Vector2(88, -35), Vector2(94, -46), Vector2(100, -60)]), r) if r < 90.0 else -INF
	if type != "monks_mound":
		return -INF
	return maxf(maxf(_mound_tier(p - Vector2(0, -57.75), Vector2(118, 87.75), Vector2(88, 57.75), 0, 20),
		_mound_tier(p - Vector2(0, 57.75), Vector2(105, 87.75), Vector2(90, 72.75), 0, 10)),
		maxf(_mound_tier(p - Vector2(0, -65), Vector2(80, 50), Vector2(71, 41), 20, 6),
		_mound_tier(p - Vector2(0, -70), Vector2(60, 30), Vector2(54, 24), 26, 4)))

static func _mound_tier(p: Vector2, bottom: Vector2, top: Vector2, y: float, h: float) -> float:
	if pow(absf(p.x) / bottom.x, 5.0) + pow(absf(p.y) / bottom.y, 5.0) > 1.0:
		return -INF
	var lo := 0.0
	var hi := 1.0
	for i in 10:
		var t := (lo + hi) * 0.5
		var size := bottom.lerp(top, t)
		if pow(absf(p.x) / size.x, 5.0) + pow(absf(p.y) / size.y, 5.0) <= 1.0:
			lo = t
		else:
			hi = t
	return y + h * _profile(PackedVector2Array([Vector2(0, 0), Vector2(0.18, 0.08), Vector2(0.42, 0.3),
		Vector2(0.66, 0.62), Vector2(0.86, 0.88), Vector2(1, 1)]), lo)

static func _profile(points: PackedVector2Array, x: float) -> float:
	for i in range(1, points.size()):
		if x <= points[i].x:
			return lerpf(points[i - 1].y, points[i].y, clampf((x - points[i - 1].x) / (points[i].x - points[i - 1].x), 0, 1))
	return points[points.size() - 1].y
