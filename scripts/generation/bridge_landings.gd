class_name BridgeLandings
extends RefCounted

## Landings for bridge decks: a bridge way mapped shorter than the
## rendered water it crosses (Helsinki's Katajanokka canal crossings
## are 11-15 m ways over a wider carved channel) would otherwise end
## mid-water, and the wet ends of its non-bridge approaches are
## dropped, leaving a floating slab with a gap at each end. Here a
## piece end that is the mapped way's own end and still sits over
## water grows along the connected approach way (or straight, when
## none connects) until it stands on dry ground, so the deck meets
## the approach ribbon bank to bank. An end cut by a registry
## bridge's span is not the way's end and keeps the bespoke model's
## deck as its continuation, and an end where another bridge way
## joins continues as that way's deck, wet or not.

## Longest landing a deck grows past a mapped bridge end to reach
## dry ground (a wide river whose far approach is unmapped can need
## most of its width; the seek below never grows past this either).
const LANDING_MAX_M := 260.0
## A pier this far ahead of a wet end counts as its continuation.
const PIER_SNAP_M := 25.0
## An approach way must leave the bridge end within ~60° of its axis.
const APPROACH_MIN_DOT := 0.5

## The non-bridge way leaving node `p` most nearly in `dir`, ordered
## away from `p`; the way may end at `p` or run through it (a T at
## the bridge head). Only a way heading on within APPROACH_MIN_DOT of
## `dir` counts: a quay path along the bank or one doubling back under
## the deck is not the approach. Reads `_Surface._way_nodes`.
static func approach_from(surf: RoadBuilder._Surface, p: Vector2, dir: Vector2) -> PackedVector2Array:
	var best := PackedVector2Array()
	var best_dot := APPROACH_MIN_DOT
	for raw in surf._way_nodes.get(RoadBuilder._Surface._node(p), []):
		var pts: PackedVector2Array = raw[0]
		var at: int = raw[1]
		for sign: int in [1, -1]:
			var nxt: int = at + sign
			if pts.size() < 2 or nxt < 0 or nxt >= pts.size():
				continue
			var d0 := pts[nxt] - pts[at]
			if d0.length() < 0.001 or d0.normalized().dot(dir) <= best_dot:
				continue
			var away := PackedVector2Array([pts[at]])
			var i := nxt
			while i >= 0 and i < pts.size():
				away.append(pts[i])
				i += sign
			best_dot = d0.normalized().dot(dir)
			best = away
	return best

## True where two bridge ways meet: shared node, decks touching end
## to end, or an end heading (`outward`) into another deck's side (a
## T). A deck running alongside (twin carriageways, a rail bridge
## beside a road bridge) is a separate structure, not a joint.
static func joint(surf: RoadBuilder._Surface, p: Vector2, outward: Vector2 = Vector2.ZERO) -> bool:
	if int(surf._bridge_ends.get(RoadBuilder._Surface._node(p), 0)) >= 2:
		return true
	var m2u := WorldScale.metres_to_units()
	var on_lines := 0
	for raw in surf._bridge_lines:
		var pts: PackedVector2Array = raw
		var dist := INF
		var beside := false
		var near := p
		for i in range(1, pts.size()):
			var a := pts[i - 1]
			var ab := pts[i] - a
			var t := (p - a).dot(ab) / maxf(ab.length_squared(), 1e-9)
			var q := a + ab * clampf(t, 0.0, 1.0)
			var d := p.distance_to(q)
			if d < dist:
				dist = d
				near = q
				beside = t > 0.001 and t < 0.999
		if dist <= 0.05 * m2u:
			on_lines += 1
		elif not beside and dist <= 2.0 * m2u:
			return true
		elif beside and (dist <= 0.5 * m2u or (dist < 18.0 * m2u and outward != Vector2.ZERO
				and (near - p).normalized().dot(outward) > 0.7)):
			return true
	return on_lines >= 2

## True where a bridge way ends (any piece of a split crossing).
static func bridge_end_at(surf: RoadBuilder._Surface, p: Vector2) -> bool:
	if int(surf._bridge_ends.get(RoadBuilder._Surface._node(p), 0)) >= 1:
		return true
	for q in surf._bridge_end_pts:
		if q.distance_to(p) < 2.0 * WorldScale.metres_to_units():
			return true
	return false

static func landed(piece: PackedVector2Array, whole: PackedVector2Array,
		surf: RoadBuilder._Surface, m2u: float) -> PackedVector2Array:
	if piece.size() < 2 or whole.size() < 2:
		return piece
	var out := piece.duplicate()
	if piece[0] == whole[0] and not surf.bridge_joint(piece[0], (piece[0] - piece[1]).normalized()) \
			and surf.ground.water_at(piece[0].x, piece[0].y) > 0.0:
		var head := _tail(piece[0], (piece[0] - piece[1]).normalized(), surf, m2u)
		head.reverse()
		head.append_array(out)
		out = head
	if piece[piece.size() - 1] == whole[whole.size() - 1] \
			and not surf.bridge_joint(piece[piece.size() - 1],
				(piece[piece.size() - 1] - piece[piece.size() - 2]).normalized()) \
			and surf.ground.water_at(out[out.size() - 1].x, out[out.size() - 1].y) > 0.0:
		out.append_array(_tail(out[out.size() - 1],
			(out[out.size() - 1] - out[out.size() - 2]).normalized(), surf, m2u))
	return out

## Points past `from_p` in the `dir` direction up to the first dry
## point and one step beyond it, never further than LANDING_MAX_M.
## Tries, in order: the connected approach ways chained node to node,
## a straight line along `dir` (a bank path the ground treats as wet
## all along can strand the chained walk a few metres from the bank),
## and a seek toward the nearest dry ground in the outward cone (an
## end whose continuation is unmapped and whose axis misses the bank).
static func _tail(from_p: Vector2, dir: Vector2, surf: RoadBuilder._Surface, m2u: float) -> PackedVector2Array:
	if dir.length() < 0.001:
		return PackedVector2Array()
	var step_len := maxf(surf.step * 0.34, 1.0)
	var walked := _walk(_approach_line(from_p, dir, surf, step_len), surf, m2u)
	if bool(walked[1]):
		return walked[0]
	var straight := PackedVector2Array([from_p])
	var p := from_p
	while p.distance_to(from_p) < LANDING_MAX_M * m2u:
		p += dir * step_len
		straight.append(p)
	walked = _walk(straight, surf, m2u)
	if bool(walked[1]):
		return walked[0]
	var sought := _walk(_seek_line(from_p, dir, surf, m2u), surf, m2u)
	if bool(sought[1]):
		return sought[0]
	# Last resort: the mapped continuation is a pier a few metres on
	# (a jetty the road bridge runs into): grow an apron to its edge.
	var pier := _pier_line(from_p, dir, surf, m2u)
	if pier.size() >= 2:
		var apron := RoadBuilder._resample(pier, step_len)
		apron.remove_at(0)
		return apron
	# No dry ground within reach: the end really stops over the water (a
	# broken bridge, a ferry ramp, a far bank past the detailed ground),
	# so the deck ends where it is mapped instead of reaching on.
	return PackedVector2Array()

## [from_p, nearest point on a pier] when a pier way passes within
## PIER_SNAP_M ahead of `from_p` (measured to its segments, not only
## its vertices: a pier crossing the deck's line has none near it),
## else an empty line.
static func _pier_line(from_p: Vector2, dir: Vector2, surf: RoadBuilder._Surface, m2u: float) -> PackedVector2Array:
	var best := PackedVector2Array()
	var best_dist := PIER_SNAP_M * m2u
	var near := PackedVector2Array()
	for raw in surf._pier_lines:
		var line: PackedVector2Array = raw
		for i in range(1, line.size()):
			near.append(Geometry2D.get_closest_point_to_segment(from_p, line[i - 1], line[i]))
		if line.size() == 1:
			near.append(line[0])
	for q in near:
		var v: Vector2 = q - from_p
		if v.length() < best_dist and v.length() > 0.001 and v.normalized().dot(dir) > -0.6:
			best = PackedVector2Array([from_p, q])
			best_dist = v.length()
	return best

## Approach ways chained end to end from `from_p`: each way's far node
## hands over to the next way leaving it most nearly along the walk.
## A hop that only leads back over visited nodes ends the chain (two
## bridge pieces linked by one wet way would otherwise bounce forever).
static func _approach_line(from_p: Vector2, dir: Vector2, surf: RoadBuilder._Surface, step_len: float) -> PackedVector2Array:
	var line := PackedVector2Array([from_p])
	var heading := dir
	var visited := {RoadBuilder._Surface._node(from_p): true}
	for hop in 12:
		var path := approach_from(surf, line[line.size() - 1], heading)
		if path.size() < 2:
			break
		var fresh := false
		for q in path:
			if not visited.has(RoadBuilder._Surface._node(q)):
				fresh = true
		if not fresh:
			break
		for q in path:
			if q.distance_to(line[line.size() - 1]) > 0.01:
				line.append(q)
				visited[RoadBuilder._Surface._node(q)] = true
		if line.size() < 2:
			break
		var tail_dir := line[line.size() - 1] - line[line.size() - 2]
		if tail_dir.length() < 0.001:
			break
		heading = tail_dir.normalized()
		if _line_length(line) >= LANDING_MAX_M:
			break
	return RoadBuilder._resample(line, step_len) if line.size() >= 2 else line

static func _line_length(line: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, line.size()):
		total += line[i].distance_to(line[i - 1])
	return total

## A straight line from `from_p` to the nearest dry point in the
## outward cone (±75°), or an empty line when the cone stays wet.
static func _seek_line(from_p: Vector2, dir: Vector2, surf: RoadBuilder._Surface, m2u: float) -> PackedVector2Array:
	var best := PackedVector2Array()
	var best_dist := LANDING_MAX_M * m2u
	var step := 4.0 * m2u
	for deg in range(-75, 76, 5):
		var ray := dir.rotated(deg_to_rad(float(deg)))
		var dist := step
		while dist < best_dist:
			var q: Vector2 = from_p + ray * dist
			if surf.inside(q) and surf.ground.water_at(q.x, q.y) <= 0.0:
				best = PackedVector2Array([from_p, q])
				best_dist = dist
				break
			if not surf.inside(q):
				break
			dist += step
	return best

## [points, reached_end]: `line` walked from its head until the first
## dry point (plus one dry step, so deck and ribbon overlap) or the
## next bridge piece's end (deck meets deck across a wet link way),
## capped at LANDING_MAX_M of travel.
static func _walk(line: PackedVector2Array, surf: RoadBuilder._Surface, m2u: float) -> Array:
	var out := PackedVector2Array()
	if line.size() < 2:
		return [out, false]
	var travelled := 0.0
	for i in range(1, line.size()):
		travelled += line[i].distance_to(line[i - 1])
		out.append(line[i])
		if travelled > 4.0 * m2u and bridge_end_at(surf, line[i]):
			return [out, true]
		if surf.inside(line[i]) and surf.ground.water_at(line[i].x, line[i].y) <= 0.0:
			if i + 1 < line.size() and surf.ground.water_at(line[i + 1].x, line[i + 1].y) <= 0.0:
				out.append(line[i + 1])
			return [out, true]
		if travelled >= LANDING_MAX_M * m2u:
			break
	return [out, false]
