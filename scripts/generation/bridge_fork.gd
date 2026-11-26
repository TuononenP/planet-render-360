class_name BridgeFork
extends RefCounted

## Where a spine end with no road of its own lands: through the structure's
## other members leaving that node, and through the members those go on
## into (a river arm mapped as a chain of short ways, Pont Neuf's), the
## mean of their free ends' approach levels. Without it such an end was a
## joint in mid-air and the deck sagged to the river's clearance between
## its abutments, then ramped up to the island.

## Longest chain of members followed.
const MAX_LINKS := 6
## Minimum dot product for a continuing road member to extend the spine.
const CHAIN_DOT := 0.5

## Chains `spine_li` forward and backward through continuing same-kind
## members of `s` (e.g. a bridge whose undivided approaches split into
## narrower one-way carriageways over the main span) so the spine spans
## abutment to abutment instead of stopping mid-deck.
static func spine_chain(s: BridgeStructures.Structure, spine_li: int,
		index: RoadBridgeDecks.Index, m2u: float) -> PackedVector2Array:
	var pts: PackedVector2Array = (index.lines[spine_li]["points"] as PackedVector2Array).duplicate()
	if pts.size() < 2:
		return pts
	var snap := BridgeStructures.FORK_SNAP_M * m2u
	var used := {spine_li: true}
	for pass_i in 2:
		for _step in MAX_LINKS:
			var tip := pts[pts.size() - 1]
			var dir := (tip - pts[pts.size() - 2]).normalized()
			var best_li := -1
			var best_rev := false
			var best_half := -1.0
			var best_dot := -1.0
			for li in s.members:
				if used.has(li):
					continue
				var line: Dictionary = index.lines[li]
				if not s.path and str(line["cls"]) in RoadBridgeDecks.PATH_CLASSES:
					continue
				var lp: PackedVector2Array = line["points"]
				if lp.size() < 2:
					continue
				var rev := false
				var next_dir := Vector2.ZERO
				if lp[0].distance_to(tip) <= snap:
					next_dir = (lp[1] - lp[0]).normalized()
				elif lp[lp.size() - 1].distance_to(tip) <= snap:
					rev = true
					next_dir = (lp[lp.size() - 2] - lp[lp.size() - 1]).normalized()
				else:
					continue
				var dot := dir.dot(next_dir)
				if dot < CHAIN_DOT:
					continue
				var half := float(line["half"])
				if half > best_half + 1e-4 or (absf(half - best_half) <= 1e-4 and dot > best_dot):
					best_li = li
					best_rev = rev
					best_half = half
					best_dot = dot
			if best_li < 0:
				break
			used[best_li] = true
			var add: PackedVector2Array = index.lines[best_li]["points"]
			if best_rev:
				for k in range(add.size() - 2, -1, -1):
					pts.append(add[k])
			else:
				for k in range(1, add.size()):
					pts.append(add[k])
		pts.reverse()
	return pts

## The landing level (plus the deck's lift) of the free ends reachable from
## `p` through `s`'s members, or NAN when none goes on as a road.
static func landing(s: BridgeStructures.Structure, p: Vector2, index: RoadBridgeDecks.Index,
		surf: RoadBuilder._Surface, m2u: float) -> float:
	var snap := BridgeStructures.FORK_SNAP_M * m2u
	var sum := 0.0
	var count := 0
	var seen := {s.spine_line: true}
	var frontier: Array[Vector2] = [p]
	for link in MAX_LINKS:
		var next: Array[Vector2] = []
		for at in frontier:
			for li in s.members:
				if seen.has(li):
					continue
				var pts: PackedVector2Array = index.lines[li]["points"]
				var n := pts.size()
				if n < 2:
					continue
				var far := -1
				var back := -1
				if pts[0].distance_to(at) <= snap:
					far = n - 1
					back = n - 2
				elif pts[n - 1].distance_to(at) <= snap:
					far = 0
					back = 1
				if far < 0:
					continue
				seen[li] = true
				var q := pts[far]
				var road := BridgeLandings.approach_from(surf, q, (q - pts[back]).normalized())
				if road.is_empty():
					next.append(q)  # It goes on as another bridge way.
					continue
				var y := BridgeStructures._landing(road, q, surf, m2u)
				if not is_nan(y):
					sum += y
					count += 1
		if count > 0 or next.is_empty():
			break
		frontier = next
	return sum / float(count) + 0.05 * m2u if count > 0 else NAN
