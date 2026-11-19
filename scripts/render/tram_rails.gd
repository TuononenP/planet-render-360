class_name TramRails
extends RefCounted

## Where the tracks of two tram routes come close enough for their trams
## to touch: at a switch (one route runs on to another's rail, or leaves
## it), where two lines cross, or where one rail is mapped twice. Each
## route keeps its own trams apart (VehicleMover follows the one ahead);
## across routes a tram knows nothing of the other's, so VehicleMover lets
## one route at a time into each such zone. A tram claims the zone before
## it is too close to stop for it; one finding a zone another route's tram
## has claimed, or stands in, stops short of it and waits.

## Track centres nearer than this (metres) let two trams touch (the
## widest car is 2.65 m wide); twin tracks lie farther apart.
const CLEAR_M := 2.9
## Sample spacing along the routes (m); zones are padded by it.
const STEP_M := 2.0
## Close stretches of two routes nearer than this along either (m) make
## one zone, so a tram never stands between two it waits for.
const MERGE_M := 40.0
## A tram claims a zone this far (m) beyond its stopping distance, and
## waits this far short of one it may not enter.
const COMMIT_M := 3.0
const WAIT_M := 1.0
## Zones up to this far ahead (m) are looked at (a group of them reaches
## its last zone's end plus a tram's length); a claim beyond lapses.
const LOOK_M := 120.0

## The zones between `routes` (distinct TramRoutes): each [route a,
## Vector2(from, to) along a, route b, Vector2(from, to) along b], arc
## lengths in metres.
static func zones(routes: Array, m2u: float) -> Array:
	var cell := CLEAR_M + STEP_M
	# Samples by cell as [route index, s, point in metres].
	var grid := {}
	for i in routes.size():
		var r: TramRoute = routes[i]
		var s := 0.0
		while true:
			var p := r.xz_at(s) / m2u
			var key := Vector2i(floori(p.x / cell), floori(p.y / cell))
			if not grid.has(key):
				grid[key] = []
			(grid[key] as Array).append([i, s, p])
			if s >= r.length_m:
				break
			s = minf(s + STEP_M, r.length_m)
	# Close sample pairs by route pair (i < j), as Vector2(s on i, s on j).
	var close := {}
	for key: Vector2i in grid:
		for e: Array in grid[key]:
			for dx in range(-1, 2):
				for dz in range(-1, 2):
					for f: Array in grid.get(key + Vector2i(dx, dz), []):
						if int(f[0]) <= int(e[0]) or (e[2] as Vector2).distance_to(f[2]) >= CLEAR_M:
							continue
						var pair := Vector2i(int(e[0]), int(f[0]))
						if not close.has(pair):
							close[pair] = []
						(close[pair] as Array).append(Vector2(float(e[1]), float(f[1])))
	var out: Array = []
	for pair: Vector2i in close:
		var a: TramRoute = routes[pair.x]
		var b: TramRoute = routes[pair.y]
		for span: Rect2 in _clusters(close[pair]):
			out.append([a, Vector2(maxf(span.position.x - STEP_M, 0.0), minf(span.end.x + STEP_M, a.length_m)),
				b, Vector2(maxf(span.position.y - STEP_M, 0.0), minf(span.end.y + STEP_M, b.length_m))])
	return out

## The close sample pairs `hits` (Vector2(s on a, s on b)) gathered into
## spans (Rect2: x along a, y along b), any two within MERGE_M along
## both routes in one.
static func _clusters(hits: Array) -> Array:
	hits.sort()
	var spans: Array = []
	for h: Vector2 in hits:
		var last := spans.size() - 1
		if last >= 0 and (spans[last] as Rect2).grow(MERGE_M).has_point(h):
			spans[last] = (spans[last] as Rect2).expand(h)
		else:
			spans.append(Rect2(h, Vector2.ZERO))
	var merged := true
	while merged:
		merged = false
		var i := 0
		while i < spans.size():
			var j := i + 1
			while j < spans.size():
				var p: Rect2 = spans[i]
				var q: Rect2 = spans[j]
				if p.grow(MERGE_M).intersects(q, true):
					spans[i] = p.merge(q)
					spans.remove_at(j)
					merged = true
				else:
					j += 1
			i += 1
	return spans

## Each zone of `all` that train route `route` is in, from its side:
## [zone index, Vector2 along route, the other route, Vector2 along it].
static func of(route: TramRoute, all: Array) -> Array:
	var out: Array = []
	for k in all.size():
		var z: Array = all[k]
		if z[0] == route:
			out.append([k, z[1], z[2], z[3]])
		elif z[2] == route:
			out.append([k, z[3], z[0], z[1]])
	return out

## Speed limit (m/s) for train `t` (VehicleMover's dict, standing at
## "s" heading "dir" at "v") from the zones ahead of it: claims those it
## is in or about to reach, and stops short of one another route's train
## holds; INF when nothing holds it back. `brake` is the service brake
## (m/s²). Zones closer together than the train is long are claimed
## together, so it never stands in one waiting for the next. `held_to`
## is the speed limit something else (a light, a stop, the tram ahead)
## sets: it claims no zone it would stop short of for that, and standing
## for it lets go of the zones ahead (release()).
static func limit(t: Dictionary, trains: Array, dt: float, brake: float, held_to: float = INF) -> float:
	if (t["zones"] as Array).is_empty():
		return INF
	var v := float(t["v"])
	if held_to < 0.3 and v < 0.1:
		release(t)
		return INF
	var commit := v * v / (2.0 * brake) + v * dt + COMMIT_M
	var claims: Dictionary = t["claims"]
	var ahead := _ahead(t, float(t["s"]), float(t["dir"]), claims)
	var i := 0
	while i < ahead.size():
		var j := _group(ahead, i, float(t["length"]))
		var held := true
		for k in range(i, j + 1):
			held = held and claims.has(int(ahead[k][2][0]))
		if not held:
			var near := float(ahead[i][0])
			for k in range(i, j + 1):
				if not claims.has(int(ahead[k][2][0])) and _taken(t, ahead[k][2], trains):
					# Waiting, it lets go of the zones it can still stop short of;
					# committed to the first, it stops short of the taken one.
					for m in range(i, j + 1):
						if float(ahead[m][0]) > commit:
							claims.erase(int(ahead[m][2][0]))
					var stop_at := near if not claims.has(int(ahead[i][2][0])) else float(ahead[k][0])
					return sqrt(2.0 * brake * maxf(stop_at - WAIT_M, 0.0))
			# Not past the light or stop that holds it, nor near enough yet.
			if near > commit or (held_to < INF and held_to * held_to / (2.0 * brake) < near):
				return INF
			for k in range(i, j + 1):
				claims[int(ahead[k][2][0])] = true
		i = j + 1
	return INF

## Whether train `t`, coming back in at `start` heading `dir` at `v`, is
## clear of every zone it would stand in or be too close to stop for (and
## those claimed together with them); when it is, it claims them, dropping
## its claims from the last run.
static func can_enter(t: Dictionary, trains: Array, start: float, dir: float, v: float, brake: float,
		dt: float) -> bool:
	var claims := {}
	if not (t["zones"] as Array).is_empty():
		var ahead := _ahead(t, start, dir, claims)
		var i := 0
		while i < ahead.size() and float(ahead[i][0]) <= v * v / (2.0 * brake) + v * dt + COMMIT_M:
			var j := _group(ahead, i, float(t["length"]))
			for k in range(i, j + 1):
				if _taken(t, ahead[k][2], trains):
					return false
				claims[int(ahead[k][2][0])] = true
			i = j + 1
	t["claims"] = claims
	return true

## Drops train `t`'s claims on zones it does not stand in (it stands for
## something else: a stop, a light).
## Those claimed with a zone it stands in stay claimed (it may not stand
## in one waiting for the next).
static func release(t: Dictionary) -> void:
	var claims: Dictionary = t["claims"]
	var ahead := _ahead(t, float(t["s"]), float(t["dir"]), claims)
	var keep := -1
	if not ahead.is_empty() and float(ahead[0][0]) <= 0.0:
		keep = _group(ahead, 0, float(t["length"]))
	for k in range(keep + 1, ahead.size()):
		claims.erase(int(ahead[k][2][0]))

## The zones of train `t` ahead of it standing at `s` heading `dir`, as
## [metres from its front to the zone, to the zone's far end, zone],
## nearest first, within LOOK_M (one it stands in at 0). Claims on the
## zones it stands in are set in `claims`, those on zones behind it or out
## of sight dropped.
static func _ahead(t: Dictionary, s: float, dir: float, claims: Dictionary) -> Array:
	var half := float(t["length"]) * 0.5
	var out: Array = []
	for z: Array in t["zones"]:
		var id := int(z[0])
		var mine: Vector2 = z[1]
		if s + half > mine.x and s - half < mine.y:
			# One it stands in counts as just ahead: the next ones close to it
			# are claimed with it.
			claims[id] = true
			out.append([0.0, maxf(mine.y - (s + half) if dir > 0.0 else (s - half) - mine.x, 0.0), z])
			continue
		var ahead := mine.x - (s + half) if dir > 0.0 else (s - half) - mine.y
		if ahead < 0.0 or ahead > LOOK_M:
			claims.erase(id)
			continue
		out.append([ahead, ahead + mine.y - mine.x, z])
	out.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	return out

## The last index of the group of `ahead` starting at `i`: each next zone
## starts before a train `length` long, leaving the one before, would be
## clear of it.
static func _group(ahead: Array, i: int, length: float) -> int:
	var j := i
	var reach := float(ahead[i][1]) + length + WAIT_M
	while j + 1 < ahead.size() and float(ahead[j + 1][0]) <= reach:
		j += 1
		reach = maxf(reach, float(ahead[j][1]) + length + WAIT_M)
	return j

## Whether a train of the other route of zone `z` (as of() gives it to
## `t`) has claimed it or stands in it. A deck tram keeps a timetable
## and claims nothing: it holds every zone ahead of it within twice
## LOOK_M, also while it is out of sight waiting to come back in.
static func _taken(t: Dictionary, z: Array, trains: Array) -> bool:
	var id := int(z[0])
	var other: TramRoute = z[2]
	var theirs: Vector2 = z[3]
	for o: Dictionary in trains:
		var deck := not is_nan(float(o["deck_mid"]))
		if o == t or o["route"] != other or (bool(o["hidden"]) and not deck):
			continue
		var s := float(o["s"])
		var half := float(o["length"]) * 0.5
		var dir := float(o["dir"])
		if bool(o["hidden"]):
			# A deck tram out of sight: past its run's far end it is gone;
			# before its start it is coming, over every zone ahead.
			if s != (float(o["lo"]) if dir > 0.0 else float(o["hi"])):
				continue
			s -= dir * (half + 1.0)
		if (o["claims"] as Dictionary).has(id) or (s + half > theirs.x and s - half < theirs.y):
			return true
		if deck:
			var ahead := theirs.x - (s + half) if dir > 0.0 else (s - half) - theirs.y
			if ahead >= 0.0 and ahead <= 2.0 * LOOK_M:
				return true
	return false
