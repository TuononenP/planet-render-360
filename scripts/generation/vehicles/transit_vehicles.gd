class_name TransitVehicles
extends RefCounted

## Trams standing on the mapped tram track and buses at their stops (desktop High and Ultra,
## phones on Ultra): a tram city with bare rails reads as a model.
## * Which: TramSpecs.pick by city and track (Helsinki's green cars,
##   Lisbon's and Porto's two-axle cars, San Francisco's cable cars,
##   streamliners and light rail, a white articulated car elsewhere).
## * Where: at a mapped tram stop, snapped to the nearest track within
##   SNAP_M, OCCUPIED of them taken; and one at a hashed spot in every
##   BLOCK_M of route without a stop (bundled and older payloads carry
##   no stops, so there every block gets its tram). Never on a bridge,
##   in a tunnel or within TUNNEL_CLEAR_M of a tunnel mouth, SPACING_M
##   apart, the MAX_TRAINS nearest the eye. Positions are hashed, so a
##   street always shows the same trams.
## * How: each body section is its own instance on TramRoute.place_train
##   (bogies on the rails, the body along their chord), the detailed
##   mesh within DETAIL_M and the folded one beyond.
## Trams do not move yet; a train is an arc length on its route, so a
## mover only has to advance it (TramRoute).
## * Buses: a city bus (CarModel "bus") stands at BUS_OCCUPIED of the
##   mapped bus stops within BUS_RADIUS_M of the eye, at the kerb of the
##   nearest street within BUS_SNAP_M on the stop's side, facing with
##   the traffic, clear of trams and of each other; lit at night like
##   the trams. Parked cars keep clear of both (footprints()).

const SNAP_M := 25.0
const OCCUPIED := 0.5
const BLOCK_M := 500.0
const SPACING_M := 60.0
const TUNNEL_CLEAR_M := 30.0
const MAX_TRAINS := 30
const DETAIL_M := 200.0
const BUS_SNAP_M := 20.0
const BUS_OCCUPIED := 0.5
const BUS_RADIUS_M := 800.0
const MAX_BUSES := 20
const BUS_CLEAR_M := 14.0
## Bus centreline inside the kerb (m).
const BUS_KERB_IN_M := 1.6
const BUS_CLASSES: Array[String] = ["primary", "secondary", "tertiary", "residential", "unclassified", "trunk"]
## The city's bus colour; elsewhere one of BUS_PALETTE by country.
const BUS_PAINT := {
	"london": Color(0.5, 0.03, 0.03), "helsinki": Color(0.05, 0.18, 0.45), "espoo": Color(0.05, 0.18, 0.45),
	"stockholm": Color(0.5, 0.04, 0.04), "lisbon": Color(0.85, 0.62, 0.04), "berlin": Color(0.85, 0.66, 0.05),
	"new_york": Color(0.78, 0.8, 0.84), "san_francisco": Color(0.72, 0.72, 0.7), "paris": Color(0.35, 0.62, 0.52),
}
const BUS_PALETTE := [Color(0.82, 0.82, 0.8), Color(0.5, 0.04, 0.04), Color(0.05, 0.2, 0.45),
	Color(0.85, 0.64, 0.05), Color(0.08, 0.36, 0.2)]

## Desktop High and Ultra; on the Mobile renderer Ultra only.
static func enabled(preset: int, forward_plus: bool = RenderQuality.is_forward_plus()) -> bool:
	var p := RenderSettings.clamp_preset(preset)
	return p == RenderSettings.Preset.ULTRA or (forward_plus and p == RenderSettings.Preset.HIGH)

## The trams of `data`, nearest the eye first: {"kind", "livery",
## "route" (TramRoute), "s" (metres along it), "length", "sections"
## (TramSpecs.train rows), "poses" (a Transform3D per section, scaled to
## world units), "a", "b" (the ends on the ground, world XZ) and
## "half_w" (world units): the footprint parked cars and buses keep
## clear of}.
static func plan(data: LocationData, ground: GroundTruth, m2u: float) -> Array:
	var region := CityStyles.region_at(data.latitude, data.longitude)
	var carries := func(rail: Dictionary) -> bool:
		return TramSpecs.carries(region, rail)
	var routes := TramRoute.chains(data, ground, m2u, carries)
	if routes.is_empty():
		return []
	var mouths := TramRoute.mouths(data, carries)
	var centre := View360.spawn_xz(data)
	# Candidates as [route, s, distance² to the eye].
	var spots: Array = []
	var stopped := {}
	for stop in data.tram_stops:
		if not (stop is Dictionary):
			continue
		var p := Vector2(float(stop.get("x", 0.0)), float(stop.get("z", 0.0)))
		var best := -1
		var best_at := Vector2(0.0, SNAP_M)
		for i in routes.size():
			var at := routes[i].nearest(p)
			if at.y < best_at.y:
				best_at = at
				best = i
		if best < 0:
			continue
		stopped["%d_%d" % [best, int(best_at.x / _block_m(routes[best]))]] = true
		if _hash(p.x, p.y, 3.1) < OCCUPIED:
			spots.append([routes[best], best_at.x, p.distance_squared_to(centre)])
	for i in routes.size():
		var route := routes[i]
		var span := _block_m(route)
		var first := route.points[0]
		for k in roundi(route.length_m / span):
			if stopped.has("%d_%d" % [i, k]):
				continue
			# A stub of track shorter than a block carries its share of a tram.
			if route.length_m < BLOCK_M and _hash(first.x, first.y, 5.7) > route.length_m / BLOCK_M:
				continue
			var s := (float(k) + 0.15 + 0.7 * _hash(first.x, first.y, 7.9 + float(k))) * span
			spots.append([route, s, route.xz_at(s).distance_squared_to(centre)])
	spots.sort_custom(func(a: Array, b: Array) -> bool:
		return float(a[2]) < float(b[2]))
	var trains: Array = []
	for spot: Array in spots:
		if trains.size() >= MAX_TRAINS:
			break
		var train := _train(spot[0], float(spot[1]), region, data.country, mouths, ground, m2u)
		if train.is_empty():
			continue
		var clear := true
		for other: Dictionary in trains:
			if _gap(train, other) < SPACING_M * m2u:
				clear = false
				break
		if clear:
			trains.append(train)
	return trains

## Length of the equal blocks a route is cut into (about BLOCK_M each).
static func _block_m(route: TramRoute) -> float:
	return route.length_m / float(maxi(int(route.length_m / BLOCK_M), 1))

## The train standing with its middle near `s` on `route`, or {} when
## that spot cannot take it.
static func _train(route: TramRoute, s_in: float, region: String, country: String,
		mouths: PackedVector2Array, ground: GroundTruth, m2u: float) -> Dictionary:
	var at := route.xz_at(s_in)
	var pick := TramSpecs.pick(region, country, route.way_at(s_in), _hash(at.x, at.y, 11.3))
	if pick.is_empty():
		return {}
	var kind := str(pick["kind"])
	var length := TramSpecs.length_m(kind)
	var reach := length * 0.5 + 1.0
	if route.length_m < 2.0 * reach:
		return {}
	var s := clampf(s_in, reach, route.length_m - reach)
	if route.bridged(s - reach, s + reach):
		return {}
	var a := route.xz_at(s - length * 0.5)
	var b := route.xz_at(s + length * 0.5)
	var mid := route.xz_at(s)
	for p: Vector2 in [a, mid, b]:
		if ground != null and not ground.is_inside(p.x, p.y):
			return {}
		for m in mouths:
			if m.distance_to(p) < TUNNEL_CLEAR_M * m2u:
				return {}
	var sections := TramSpecs.train(kind)
	var poses: Array[Transform3D] = []
	var placed := route.place_train(s, sections)
	for i in sections.size():
		var pose := placed[i]
		if bool(sections[i]["flip"]):
			pose.basis = pose.basis * Basis(Vector3.UP, PI)
		pose.basis = pose.basis.scaled(Vector3.ONE * m2u)
		poses.append(pose)
	return {"kind": kind, "livery": str(pick["livery"]), "route": route, "s": s, "length": length,
		"sections": sections, "poses": poses, "a": a, "b": b,
		"half_w": TramSpecs.width_m(kind) * 0.5 * m2u}

## Clear distance between two trains' centrelines (world units).
static func _gap(t: Dictionary, o: Dictionary) -> float:
	var a: Vector2 = t["a"]
	var b: Vector2 = t["b"]
	var c: Vector2 = o["a"]
	var d: Vector2 = o["b"]
	if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
		return 0.0
	return minf(minf(a.distance_to(Geometry2D.get_closest_point_to_segment(a, c, d)),
			b.distance_to(Geometry2D.get_closest_point_to_segment(b, c, d))),
		minf(c.distance_to(Geometry2D.get_closest_point_to_segment(c, a, b)),
			d.distance_to(Geometry2D.get_closest_point_to_segment(d, a, b))))

static func _hash(x: float, z: float, salt: float) -> float:
	return fposmod(sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453, 1.0)

## The buses of `data`, nearest the eye first: ParkedCars car rows
## [position, basis, "bus", colour, distance², finish] with the
## footprint ends appended (a, b in world XZ). `trains` is plan().
static func plan_buses(data: LocationData, ground: GroundTruth, m2u: float, trains: Array) -> Array:
	var buses: Array = []
	var centre := View360.spawn_xz(data)
	var left_traffic := RoadSurface.left_traffic(data)
	var region := CityStyles.region_at(data.latitude, data.longitude)
	var colour: Color = BUS_PAINT.get(region, BUS_PALETTE[absi(hash(data.country + region)) % BUS_PALETTE.size()])
	var length := CarSpecs.length_m("bus") * m2u
	var spots: Array = []
	for stop in data.bus_stops:
		if not (stop is Dictionary):
			continue
		var p := Vector2(float(stop.get("x", 0.0)), float(stop.get("z", 0.0)))
		var d2 := p.distance_squared_to(centre)
		if d2 < pow(BUS_RADIUS_M * m2u, 2.0) and _hash(p.x, p.y, 2.3) < BUS_OCCUPIED:
			spots.append([p, d2])
	spots.sort_custom(func(a: Array, b: Array) -> bool:
		return float(a[1]) < float(b[1]))
	for spot: Array in spots:
		if buses.size() >= MAX_BUSES:
			break
		var p: Vector2 = spot[0]
		var best := BUS_SNAP_M * m2u
		var at := Vector2.ZERO
		var dir := Vector2.ZERO
		var road := {}
		for r in data.roads:
			if not (r is Dictionary) or not str(r.get("class", "")) in BUS_CLASSES or bool(r.get("tunnel", false)) \
					or bool(r.get("bridge", false)) or bool(r.get("area", false)):
				continue
			var pts: PackedVector2Array = r.get("points", PackedVector2Array())
			for i in pts.size() - 1:
				var q := Geometry2D.get_closest_point_to_segment(p, pts[i], pts[i + 1])
				if q.distance_to(p) < best and pts[i].distance_to(pts[i + 1]) > 0.001:
					best = q.distance_to(p)
					at = q
					dir = (pts[i + 1] - pts[i]).normalized()
					road = r
		var half := float(road.get("width_m", 0.0)) * 0.5
		if road.is_empty() or half < 3.0:
			continue
		# The stop's own side; a stop mapped on the carriageway takes the
		# side its traffic keeps to.
		var left := Vector2(dir.y, -dir.x)
		var side := signf((p - at).dot(left))
		if best < 0.5 * m2u or side == 0.0:
			side = 1.0 if left_traffic else -1.0
		var off := (half - BUS_KERB_IN_M) * side * m2u
		var fw := ParkedCars.facing(dir, off, int(road.get("oneway", 0)), left_traffic)
		var c := at + left * off
		var a := c - fw * length * 0.5
		var b := c + fw * length * 0.5
		var foot := {"a": a, "b": b}
		var clear := ground == null or (ground.is_inside(a.x, a.y) and ground.is_inside(b.x, b.y))
		for t: Dictionary in trains:
			if _gap(foot, t) < BUS_CLEAR_M * 0.3 * m2u:
				clear = false
		for other: Array in buses:
			if _gap(foot, {"a": other[6], "b": other[7]}) < BUS_CLEAR_M * m2u:
				clear = false
		if not clear:
			continue
		var front := c + fw * length * 0.4
		var back := c - fw * length * 0.4
		var yf := ground.height_at_world(front.x, front.y)
		var yb := ground.height_at_world(back.x, back.y)
		var forward := Vector3(fw.x * length * 0.8, yf - yb, fw.y * length * 0.8).normalized()
		var up := forward.cross(Vector3.UP).normalized().cross(forward).normalized()
		buses.append([Vector3(c.x, (yf + yb) * 0.5 + 0.04 * m2u, c.y),
			Basis(forward, up, forward.cross(up)).scaled(Vector3.ONE * m2u), "bus", colour, float(spot[1]),
			Color(0.0, 0.15 + 0.3 * _hash(p.x, p.y, 4.4), 0.0, 0.0), a, b])
	return buses

## Where trams and buses stand, as ParkedCars obstacle rows [a, b, radius].
static func footprints(data: LocationData, ground: GroundTruth, m2u: float) -> Array:
	var out: Array = []
	if not enabled(data.quality_preset):
		return out
	var trains := plan(data, ground, m2u)
	for t: Dictionary in trains:
		out.append([t["a"], t["b"], float(t["half_w"]) + 1.0 * m2u])
	for bus: Array in plan_buses(data, ground, m2u, trains):
		out.append([bus[6], bus[7], (CarSpecs.width_m("bus") * 0.5 + 1.2) * m2u])
	return out

static var _bus_meshes := {}

## The bus mesh, its windows and destination sign lit at night like a tram's.
static func bus_mesh(far: bool) -> ArrayMesh:
	if not _bus_meshes.has(far):
		var m := CarModel.mesh("bus", far).duplicate() as ArrayMesh
		for i in m.get_surface_count():
			if m.surface_get_name(i) in ["Glass", "HeadLamp", "TailLamp", "Board"]:
				m.surface_set_material(i, TramModel.material(m.surface_get_name(i)))
		_bus_meshes[far] = m
	return _bus_meshes[far]

## Builds the trams and buses under `root`; returns how many trains stand.
static func build(root: Node3D, data: LocationData, ground: GroundTruth) -> int:
	if not enabled(data.quality_preset):
		return 0
	var m2u := WorldScale.metres_to_units()
	var trains := plan(data, ground, m2u) if not data.railways.is_empty() else []
	var buses := plan_buses(data, ground, m2u, trains)
	if not buses.is_empty():
		var depot := Node3D.new()
		depot.name = "Buses"
		for i in buses.size():
			var one: Array = [buses[i]]
			var near := ParkedCars._add_batch(depot, one, bus_mesh(false), "Bus%d_near" % i, 0.0, DETAIL_M)
			var far := ParkedCars._add_batch(depot, one, bus_mesh(true), "Bus%d_far" % i, DETAIL_M, 0.0)
			var bounds := ParkedCars._batch_bounds(one, bus_mesh(false).get_aabb().merge(bus_mesh(true).get_aabb()))
			near.custom_aabb = bounds
			far.custom_aabb = bounds
			ParkedCars._add_batch(depot, one, _shadow(CarSpecs.length_m("bus"), CarSpecs.width_m("bus")),
				"Bus%d_shadow" % i, 0.0, DETAIL_M * 2.0)
		root.add_child(depot)
	if trains.is_empty():
		return 0
	var holder := Node3D.new()
	holder.name = "Trams"
	for t in trains.size():
		var train: Dictionary = trains[t]
		var kind := str(train["kind"])
		var livery := str(train["livery"])
		var sections: Array = train["sections"]
		var poses: Array = train["poses"]
		for i in sections.size():
			var sec: Dictionary = sections[i]
			var near := TramModel.mesh(kind, str(sec["id"]), livery, bool(sec["tail"]))
			var far := TramModel.mesh(kind, str(sec["id"]), livery, bool(sec["tail"]), true)
			# Visibility ranges measure from the AABB centre: one box for
			# both, or the switch leaves a gap or an overlap.
			var bounds := near.get_aabb().merge(far.get_aabb())
			_instance(holder, "Tram%d_%d_near" % [t, i], near, poses[i], bounds, 0.0, DETAIL_M * m2u)
			_instance(holder, "Tram%d_%d_far" % [t, i], far, poses[i], bounds, DETAIL_M * m2u, 0.0)
			var shadow := _instance(holder, "Tram%d_%d_shadow" % [t, i],
				_shadow(float(sec["len"]), TramSpecs.width_m(kind)), poses[i], AABB(), 0.0, DETAIL_M * 2.0 * m2u)
			shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(holder)
	return trains.size()

static func _instance(holder: Node3D, node_name: String, section: Mesh, pose: Transform3D, bounds: AABB,
		begin: float, end: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = section
	mi.transform = pose
	if bounds.has_volume():
		mi.custom_aabb = bounds
	# LodRing would clear the ranges and draw both meshes at every distance.
	mi.set_meta("lod_own", true)
	mi.visibility_range_begin = begin
	mi.visibility_range_end = end
	holder.add_child(mi)
	return mi

static var _shadows := {}

## The contact shadow under a body section: a ground quad a little past
## its footprint (CarPaint's, as under the parked cars), over the road
## the rails are set in.
static func _shadow(length: float, width: float) -> PlaneMesh:
	var key := "%.2f_%.2f" % [length, width]
	if not _shadows.has(key):
		var plane := PlaneMesh.new()
		plane.size = Vector2(length * 1.06, width * 1.3)
		plane.center_offset = Vector3(0.0, 0.02, 0.0)
		plane.material = CarPaint.shadow_material()
		_shadows[key] = plane
	return _shadows[key]
