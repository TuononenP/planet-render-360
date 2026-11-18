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
