class_name StationTrains
extends RefCounted

## Passenger trains standing at railway stations (the trams' quality
## gate, TransitVehicles.enabled): a terminus with empty platform tracks
## reads as a model railway.
## * Where, from the track alone (bundled payloads carry no stations or
##   platforms): a terminus is a fan of buffer stops. A dead end is the
##   end of an open heavy-rail way that no other rail way touches within
##   JOIN_M, inside the fetched area (a way cut by the data's edge ends
##   outside it: _reach). FAN_MIN dead ends within FAN_M of one another
##   and facing the same way (FAN_TURN_DEG) are a terminus; so are two
##   beside a mapped station (STATION_M). A lone siding gets no train.
## * On OCCUPIED of a terminus's tracks a train stands with its nose
##   NOSE_MIN_M .. NOSE_MAX_M back from the buffers, on the track walked
##   back from the buffer to the first switch, sharp bend or tunnel,
##   CLEAR_M short of it; a short track takes fewer cars, and one too
##   short for two takes none. Track under a roof (covered=yes: a train
##   shed, a canopy) is not drawn, so where the buffers stand under one
##   the nose stands that far out from the roof's edge instead; a
##   station building or platform roof drawn over the buffers counts
##   as such a roof (both are drawn as blocks), and no train stands
##   inside a building. On a viaduct the train stands on the deck
##   RailBuilder lays.
## * Through stations need mapped platforms (rail_platforms; payloads
##   fetched before the query asked for them carry none): a train stands
##   centred on PLATFORM_OCCUPIED of the tracks that run along a
##   platform within PLATFORM_EDGE_M of its edge, no longer than it.
## * Never two trains overlapping (SIDE_M between bodies), never in a
##   tunnel, the MAX_TRAINS nearest the eye. Everything is
##   hashed from positions, so a station always shows the same trains.
## * Which: TrainSpecs.pick by city, country and track (a pantograph
##   only under overhead line). How: as the trams, a car per instance on
##   TramRoute.place_train with its bogies on the rails, detailed within
##   DETAIL_M and folded beyond (a station is wide, and seen from afar).

const JOIN_M := 0.5
const FAN_M := 80.0
const FAN_MIN := 3
const FAN_TURN_DEG := 40.0
const STATION_M := 150.0
## Dead ends this close to the edge of the fetched area are not trusted.
const EDGE_M := 20.0
const OCCUPIED := 0.6
const NOSE_MIN_M := 6.0
const NOSE_MAX_M := 14.0
const CLEAR_M := 4.0
## A platform track ends where it turns more than this at one point, or
## has swung this far from its line at the buffers.
const BEND_DEG := 12.0
const SWEEP_DEG := 40.0
## No platform track is walked further than this (m).
const RUN_M := 420.0
const PLATFORM_EDGE_M := 4.0
## Half width taken for a platform mapped as a line down its middle (m).
const PLATFORM_LINE_M := 3.0
const PLATFORM_OCCUPIED := 0.5
## A train may overhang its platform by this much in all (m).
const PLATFORM_OVER_M := 6.0
const SIDE_M := 0.5
## Step of the walk that looks for buildings over a terminus track (m).
const SPAN_STEP_M := 2.0
const MAX_TRAINS := 24
const DETAIL_M := 250.0

## The trains of `data`, nearest the eye first: {"kind", "livery",
## "cars", "panto", "route" (TramRoute; a terminus track's starts at its
## buffers), "s" (metres along it to the train's middle), "length",
## "sections" (TrainSpecs.train rows), "poses" (a Transform3D per car,
## scaled to world units), "feet" ([a, b] per car, the ends of its
## centreline in world XZ), "a", "b" (the train's ends), "half_w" (world
## units), "at": "terminus" | "platform", and at a terminus "buffer"
## (world XZ) and "nose_m" (from the buffer, or from the roof over it)}.
static func plan(data: LocationData, ground: GroundTruth, m2u: float) -> Array:
	var all := _rails(data)
	if all.is_empty():
		return []
	var region := CityStyles.region_at(data.latitude, data.longitude)
	var eye := View360.spawn_xz(data)
	var tol := JOIN_M * m2u
	var grid := _vertex_grid(all, tol)
	var runs: Array = []
	# Candidates as [distance² to the eye, kind, route, buffer or middle,
	# metres of track or platform, rail, metres under the buffers' roof].
	var spots: Array = []
	var termini := fans(data, ground, m2u)
	var solids := _solids(data) if not termini.is_empty() or not data.rail_platforms.is_empty() else []
	var ctx := {}
	if not termini.is_empty() and ground != null:
		ctx = {"surf": RoadBuilder._Surface.new(data, ground), "spans": LandmarkSites.bridge_spans(data)}
		ctx["decks"] = RailDecks.of(data, ctx["surf"], m2u)
	for fan: Array in termini:
		for end: Dictionary in fan:
			var run := _run(all, grid, tol, int(end["way"]), bool(end["tail"]), ground, m2u, ctx)
			if run.is_empty():
				continue
			var route: TramRoute = run["route"]
			runs.append(route)
			var p: Vector2 = end["p"]
			if TransitVehicles._hash(p.x, p.y, 1.7) < OCCUPIED:
				var open := _open_span(route, float(run["roof_m"]), solids, m2u)
				# The train takes the track it stands on: the first open rail.
				var on: Dictionary = route.way_at(open.x + 1.0)
				spots.append([p.distance_squared_to(eye), "terminus", route, p, open.y, on, open.x])
	_platform_spots(spots, data, ground, m2u, runs, eye)
	spots.sort_custom(func(a: Array, b: Array) -> bool:
		return float(a[0]) < float(b[0]) if a[0] != b[0] else (a[3] as Vector2) < (b[3] as Vector2))
	var trains: Array = []
	for spot: Array in spots:
		if trains.size() >= MAX_TRAINS:
			break
		var p: Vector2 = spot[3]
		var route: TramRoute = spot[2]
		var pick := TrainSpecs.pick(region, data.country, spot[5], TransitVehicles._hash(p.x, p.y, 4.3))
		if pick.is_empty():
			continue
		var terminus := str(spot[1]) == "terminus"
		var nose := lerpf(NOSE_MIN_M, NOSE_MAX_M, TransitVehicles._hash(p.x, p.y, 2.9))
		if terminus:
			nose += float(spot[6])
		# The longest train that fits the track and stands clear of the others.
		for cars in range(int(pick["cars"]), TrainSpecs.MIN_CARS - 1, -1):
			var length := TrainSpecs.length_m(str(pick["kind"]), cars)
			var s := nose + length * 0.5
			if terminus:
				if nose + length + CLEAR_M > float(spot[4]):
					continue
			else:
				if length > float(spot[4]) + PLATFORM_OVER_M:
					continue
				s = route.nearest(p).x
				if s < length * 0.5 + CLEAR_M or s > route.length_m - length * 0.5 - CLEAR_M \
						or route.bridged(s - length * 0.5, s + length * 0.5):
					continue
			var train := _stand(route, s, pick, cars, ground, m2u)
			if train.is_empty() or not _clear(train, trains, m2u) or (not terminus and _indoors(train, solids)):
				continue
			train["at"] = str(spot[1])
			if terminus:
				train["buffer"] = p
				train["nose_m"] = nose - float(spot[6])
			trains.append(train)
			break
	return trains

## The heavy-rail ways of `data`, tunnels and roofed track included.
static func _rails(data: LocationData) -> Array:
	var out: Array = []
	for r in data.railways:
		if r is Dictionary and TrainSpecs.carries(r) \
				and ((r as Dictionary).get("points", PackedVector2Array()) as PackedVector2Array).size() >= 2:
			out.append(r)
	return out

## The termini of `data`: each a fan of dead ends {"way" (index among
## the heavy-rail ways), "tail" (the way's last point), "p" (world XZ),
## "dir" (the track's heading into the buffer)}.
static func fans(data: LocationData, ground: GroundTruth, m2u: float) -> Array:
	var all := _rails(data)
	var tol := JOIN_M * m2u
	var grid := _vertex_grid(all, tol)
	var reach := _reach(data, m2u)
	var ends: Array = []
	for i in all.size():
		var rail: Dictionary = all[i]
		if _shut(rail):
			continue
		var pts: PackedVector2Array = rail["points"]
		if pts[0].distance_to(pts[pts.size() - 1]) <= tol:
			continue
		for tail: bool in [false, true]:
			var p := pts[pts.size() - 1] if tail else pts[0]
			var before := pts[pts.size() - 2] if tail else pts[1]
			if p.length() > reach or not _touching(all, grid, tol, p, i).is_empty():
				continue
			if ground != null and (absf(p.x) > (ground.extent_m - EDGE_M) * m2u or absf(p.y) > (ground.extent_m - EDGE_M) * m2u):
				continue
			ends.append({"way": i, "tail": tail, "p": p, "dir": (p - before).normalized()})
	# Single linkage: buffers side by side chain into one fan.
	var group := PackedInt32Array()
	for i in ends.size():
		group.append(i)
	var turn := cos(deg_to_rad(FAN_TURN_DEG))
	for i in ends.size():
		for j in range(i + 1, ends.size()):
			if (ends[i]["p"] as Vector2).distance_to(ends[j]["p"]) < FAN_M * m2u \
					and (ends[i]["dir"] as Vector2).dot(ends[j]["dir"]) > turn:
				var from := group[j]
				var to := group[i]
				for k in ends.size():
					if group[k] == from:
						group[k] = to
	var by_group := {}
	for i in ends.size():
		if not by_group.has(group[i]):
			by_group[group[i]] = []
		(by_group[group[i]] as Array).append(ends[i])
	var out: Array = []
	for g: int in by_group:
		var fan: Array = by_group[g]
		if fan.size() >= FAN_MIN or (fan.size() == 2 and _at_station(data, fan, m2u)):
			out.append(fan)
	return out

## Whether a mapped station stands by the dead ends of `fan`.
static func _at_station(data: LocationData, fan: Array, m2u: float) -> bool:
	for st in data.rail_stations:
		if not (st is Dictionary):
			continue
		var at := Vector2(float(st.get("x", 0.0)), float(st.get("z", 0.0)))
		for end: Dictionary in fan:
			if at.distance_to(end["p"]) < STATION_M * m2u:
				return true
	return false

## How far from the data's centre a dead end is trusted (world units).
## Ways arrive whole, so a way that only looks dead because its
## neighbour was not fetched ends outside the fetched disc; the disc is
## no wider than the query's radius, nor (a fallback fetch reaches less)
## than the farthest any fetched railway's nearest point lies.
static func _reach(data: LocationData, m2u: float) -> float:
	var farthest := 0.0
	for r in data.railways:
		if not (r is Dictionary):
			continue
		var pts: PackedVector2Array = (r as Dictionary).get("points", PackedVector2Array())
		var nearest := INF
		for p in pts:
			nearest = minf(nearest, p.length_squared())
		if nearest < INF:
			farthest = maxf(farthest, sqrt(nearest))
	return minf(farthest, float(OsmFetcher.DETAILED_RADIUS_M) * m2u) - EDGE_M * m2u

## Every vertex of `rails` by cell: [way index, vertex index].
static func _vertex_grid(rails: Array, tol: float) -> Dictionary:
	var grid := {}
	for i in rails.size():
		var pts: PackedVector2Array = (rails[i] as Dictionary)["points"]
		for k in pts.size():
			var cell := TramRoute._cell(pts[k], tol)
			if not grid.has(cell):
				grid[cell] = []
			(grid[cell] as Array).append([i, k])
	return grid

## The vertices of other ways than `own` within `tol` of `p`:
## [way index, vertex index] each.
static func _touching(rails: Array, grid: Dictionary, tol: float, p: Vector2, own: int) -> Array:
	var out: Array = []
	var cell := TramRoute._cell(p, tol)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for v: Array in grid.get(cell + Vector2i(dx, dz), []):
				if int(v[0]) != own and ((rails[int(v[0])] as Dictionary)["points"] as PackedVector2Array)[int(v[1])].distance_to(p) <= tol:
					out.append(v)
	return out

## Whether nothing can stand on `rail`: a real tunnel. Track under a
## station's roof is not one.
static func _shut(rail: Dictionary) -> bool:
	return bool(rail.get("tunnel", false)) and not bool(rail.get("covered", false))

## The points of bridge way `rail` as RailBuilder lays its deck, and
## the rail-head height at each: [points, heights], or [] where the deck
## is not one unbroken piece (the data's edge, a landmark bridge's span).
static func _deck(rail: Dictionary, surf: RoadBuilder._Surface, spans: Array, m2u: float,
		decks: RailDecks = null) -> Array:
	var dense := RoadBuilder._resample(rail["points"], surf.step * 0.34)
	var pieces := LandmarkSites.outside_spans(dense, spans)
	if pieces.size() != 1 or (pieces[0] as PackedVector2Array).size() != dense.size():
		return []
	for p in dense:
		if not surf.inside(p):
			return []
	var deck := RoadBuilder.deck_profile(dense, surf, m2u, float(rail.get("width_m", 3.3)) * m2u * 0.5, 0, false)
	if deck.size() != dense.size():
		return []
	if decks != null:
		deck = decks.level(dense, deck)
	for i in deck.size():
		deck[i] += RailBuilder.RAIL_HEIGHT_M * m2u
	return [dense, deck]

## The platform track behind the dead end of way `way`: walked back
## from the buffer (arc length 0) across plain joints between ways, up
## to the first switch (another way meeting the track), sharp bend,
## tunnel or the data's edge: {"route" (TramRoute), "roof_m" (metres of
## it under the roof that covers its buffer end, where no train stands:
## that track is not drawn)}, or {} when nothing is left. `ctx` holds
## the builders' surface and landmark spans for the bridge decks.
static func _run(rails: Array, grid: Dictionary, tol: float, way: int, tail: bool, ground: GroundTruth,
		m2u: float, ctx: Dictionary) -> Dictionary:
	var line := PackedVector2Array()
	var ys := PackedFloat32Array()
	var over: Array = []
	var seen := {way: true}
	var cur := way
	var rev := tail
	var first := Vector2.ZERO
	var walked := 0.0
	var roof := 0.0
	var decked := false
	while true:
		var rail: Dictionary = rails[cur]
		var pts: PackedVector2Array = rail["points"]
		var roofed := bool(rail.get("covered", false))
		# Open track, then a roof again: the track runs on under something else.
		if roofed and walked > roof + 0.01 * m2u:
			break
		var deck := PackedFloat32Array()
		if bool(rail.get("bridge", false)) and not roofed:
			if ctx.is_empty():
				break
			var laid := _deck(rail, ctx["surf"], ctx["spans"], m2u, ctx.get("decks"))
			if laid.is_empty():
				break
			pts = laid[0]
			deck = laid[1]
			decked = true
		if rev:
			pts = pts.duplicate()
			pts.reverse()
			deck = deck.duplicate()
			deck.reverse()
		var stop := false
		for k in pts.size():
			var p := pts[k]
			if not line.is_empty():
				var last := line[line.size() - 1]
				if p.distance_to(last) < 0.01 * m2u:
					if not deck.is_empty():
						ys[ys.size() - 1] = deck[k]
					continue
				var dir := (p - last).normalized()
				if line.size() == 1:
					first = dir
				elif dir.dot((last - line[line.size() - 2]).normalized()) < cos(deg_to_rad(BEND_DEG)) \
						or dir.dot(first) < cos(deg_to_rad(SWEEP_DEG)):
					stop = true
					break
				if ground != null and not ground.is_inside(p.x, p.y):
					stop = true
					break
				walked += p.distance_to(last)
				over.append(rail)
			line.append(p)
			ys.append(NAN if deck.is_empty() else deck[k])
			# Another way at a point inside this one: a switch or a crossing.
			if walked > RUN_M * m2u or (k > 0 and k < pts.size() - 1 and not _touching(rails, grid, tol, p, cur).is_empty()):
				stop = true
				break
		if roofed:
			roof = walked
		if stop:
			break
		# The way's far end: one other way carrying straight on is the same
		# track mapped in two pieces; anything else ends the platform track.
		var end := pts[pts.size() - 1]
		var met := _touching(rails, grid, tol, end, cur)
		if met.size() != 1:
			break
		var next := int(met[0][0])
		var next_rail: Dictionary = rails[next]
		var next_pts: PackedVector2Array = next_rail["points"]
		var at := int(met[0][1])
		if seen.has(next) or (at != 0 and at != next_pts.size() - 1) or _shut(next_rail):
			break
		seen[next] = true
		cur = next
		rev = at != 0
	if line.size() < 2:
		return {}
	return {"route": TramRoute.of(line, over, ground, m2u, ys if decked else PackedFloat32Array()), "roof_m": roof / m2u}

## The footprints a train cannot stand in: [bounds, outline] of every
## building. A station hall is drawn as a block and would swallow the
## train; so is a platform roof (building=roof), which a train's roof
## would poke through.
static func _solids(data: LocationData) -> Array:
	var out: Array = []
	for b in data.buildings:
		if not (b is Dictionary):
			continue
		var outline: PackedVector2Array = (b as Dictionary).get("footprint", PackedVector2Array())
		if outline.size() < 3:
			continue
		var box := Rect2(outline[0], Vector2.ZERO)
		for p in outline:
			box = box.expand(p)
		out.append([box, outline])
	return out

static func _built(solids: Array, p: Vector2) -> bool:
	for solid: Array in solids:
		if (solid[0] as Rect2).has_point(p) and Geometry2D.is_point_in_polygon(p, solid[1]):
			return true
	return false

## Whether any car of `train` stands inside a building.
static func _indoors(train: Dictionary, solids: Array) -> bool:
	for f: Array in train["feet"]:
		for t: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
			if _built(solids, (f[0] as Vector2).lerp(f[1], t)):
				return true
	return false

## The open stretch of a terminus track a train can stand on, in metres
## from the buffers: from where the track leaves the cover over its
## buffer end (the mapped roof, `roof_m`, or a station building drawn
## over it) to where it next runs into a building, or to its end.
static func _open_span(route: TramRoute, roof_m: float, solids: Array, m2u: float) -> Vector2:
	var box := Rect2(route.points[0], Vector2.ZERO)
	for p in route.points:
		box = box.expand(p)
	box = box.grow(2.0 * m2u)
	var near: Array = []
	for solid: Array in solids:
		if (solid[0] as Rect2).intersects(box):
			near.append(solid)
	var from := roof_m
	var to := route.length_m
	if near.is_empty():
		return Vector2(from, to)
	var out := false
	var s := 0.0
	while s <= route.length_m:
		var under := s < roof_m or _built(near, route.xz_at(s))
		if under and out:
			to = s
			break
		if under:
			from = maxf(from, s + SPAN_STEP_M)
		else:
			out = true
		s += SPAN_STEP_M
	return Vector2(from, to)

## Adds a candidate per track running along a mapped platform: the
## point of the track beside the platform's middle and the platform's
## length. Tracks of a terminus (`runs`) have had their draw already.
static func _platform_spots(spots: Array, data: LocationData, ground: GroundTruth, m2u: float, runs: Array,
		eye: Vector2) -> void:
	if data.rail_platforms.is_empty():
		return
	var carries := func(rail: Dictionary) -> bool:
		return TrainSpecs.carries(rail)
	var routes := TramRoute.chains(data, ground, m2u, carries)
	for platform in data.rail_platforms:
		if not (platform is Dictionary):
			continue
		var pts: PackedVector2Array = (platform as Dictionary).get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		# The platform's long axis: its two points farthest apart.
		var a := pts[0]
		var b := pts[0]
		var far := -1.0
		for i in pts.size():
			for j in range(i + 1, pts.size()):
				var d := pts[i].distance_squared_to(pts[j])
				if d > far:
					far = d
					a = pts[i]
					b = pts[j]
		var length := a.distance_to(b) / m2u
		if length < TrainSpecs.length_m("emu", TrainSpecs.MIN_CARS) - PLATFORM_OVER_M:
			continue
		var mid := (a + b) * 0.5
		var axis := (b - a).normalized()
		var closed := pts.size() >= 4 and pts[0].distance_to(pts[pts.size() - 1]) < JOIN_M * m2u
		var edge := (PLATFORM_EDGE_M + (0.0 if closed else PLATFORM_LINE_M)) * m2u
		for route in routes:
			var at := route.nearest(mid)
			if at.y > length * 0.5 + 30.0:
				continue
			var q := route.xz_at(at.x)
			var dir := (route.xz_at(at.x + 2.0) - route.xz_at(at.x - 2.0)).normalized()
			if absf(dir.dot(axis)) < 0.9 or _outline_distance(pts, q) > edge:
				continue
			var taken := false
			for run: TramRoute in runs:
				if run.nearest(q).y < 1.0:
					taken = true
					break
			if not taken and TransitVehicles._hash(q.x, q.y, 6.1) < PLATFORM_OCCUPIED:
				spots.append([q.distance_squared_to(eye), "platform", route, q, length, route.way_at(at.x)])

## Distance from `p` to the nearest side of outline `pts` (world units).
static func _outline_distance(pts: PackedVector2Array, p: Vector2) -> float:
	var best := INF
	for i in pts.size() - 1:
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, pts[i], pts[i + 1])))
	return best

## The `cars`-car train of `pick` with its middle at `s` metres on
## `route`, or {} when it would leave the ground.
static func _stand(route: TramRoute, s: float, pick: Dictionary, cars: int, ground: GroundTruth, m2u: float) -> Dictionary:
	var kind := str(pick["kind"])
	var length := TrainSpecs.length_m(kind, cars)
	var a := route.xz_at(s - length * 0.5)
	var b := route.xz_at(s + length * 0.5)
	if ground != null and not (ground.is_inside(a.x, a.y) and ground.is_inside(b.x, b.y)):
		return {}
	var sections := TrainSpecs.train(kind, cars, bool(pick["panto"]))
	var placed := route.place_train(s, sections)
	var poses: Array[Transform3D] = []
	var feet: Array = []
	for i in sections.size():
		var pose := placed[i]
		var half := float(sections[i]["len"]) * 0.5 * m2u
		var c := Vector2(pose.origin.x, pose.origin.z)
		var along := Vector2(pose.basis.x.x, pose.basis.x.z).normalized()
		feet.append([c - along * half, c + along * half])
		if bool(sections[i]["flip"]):
			pose.basis = pose.basis * Basis(Vector3.UP, PI)
		pose.basis = pose.basis.scaled(Vector3.ONE * m2u)
		poses.append(pose)
	return {"kind": kind, "livery": str(pick["livery"]), "cars": cars, "panto": bool(pick["panto"]), "route": route,
		"s": s, "length": length, "sections": sections, "poses": poses, "feet": feet, "a": a, "b": b,
		"half_w": TrainSpecs.width_m(kind) * 0.5 * m2u}

## Clear distance between the nearest cars of two trains (world units).
static func gap(t: Dictionary, o: Dictionary) -> float:
	var best := INF
	for f: Array in t["feet"]:
		for g: Array in o["feet"]:
			best = minf(best, TransitVehicles._gap({"a": f[0], "b": f[1]}, {"a": g[0], "b": g[1]}))
	return best

static func _clear(train: Dictionary, others: Array, m2u: float) -> bool:
	for other: Dictionary in others:
		if gap(train, other) < float(train["half_w"]) + float(other["half_w"]) + SIDE_M * m2u:
			return false
	return true

## Builds the trains under `root`; returns how many stand.
static func build(root: Node3D, data: LocationData, ground: GroundTruth) -> int:
	if not TransitVehicles.enabled(data.quality_preset) or data.railways.is_empty():
		return 0
	var m2u := WorldScale.metres_to_units()
	var trains := plan(data, ground, m2u)
	if trains.is_empty():
		return 0
	var holder := Node3D.new()
	holder.name = "Trains"
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
			# One box for both, so they switch at one distance (TransitVehicles).
			var bounds := near.get_aabb().merge(far.get_aabb())
			TransitVehicles._instance(holder, "Train%d_%d_near" % [t, i], near, poses[i], bounds, 0.0, DETAIL_M * m2u)
			TransitVehicles._instance(holder, "Train%d_%d_far" % [t, i], far, poses[i], bounds, DETAIL_M * m2u, 0.0)
			var shadow := TransitVehicles._instance(holder, "Train%d_%d_shadow" % [t, i],
				TransitVehicles._shadow(float(sec["len"]), TrainSpecs.width_m(kind)), poses[i], AABB(), 0.0,
				DETAIL_M * 2.0 * m2u)
			shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(holder)
	return trains.size()
