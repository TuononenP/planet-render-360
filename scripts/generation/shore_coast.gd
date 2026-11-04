class_name ShoreCoast
extends RefCounted

## Close directed coastline runs only at the detailed-extent boundary.
## In XZ (Z south), OSM's water side is the positive 90-degree normal.
static func domains(waterways: Array, box: Rect2, diagnostics: Array) -> Array:
	var edges: Array = []
	for w in waterways:
		if str(w.get("class", "")) != "coastline":
			continue
		var line: PackedVector2Array = w.get("points", PackedVector2Array())
		for i in line.size() - 1:
			var cut := ShoreGeometry.clip_segment(line[i], line[i + 1], box)
			if cut.size() == 2:
				edges.append(cut)
	var starts := {}
	for i in edges.size():
		if not starts.has(edges[i][0]):
			starts[edges[i][0]] = []
		(starts[edges[i][0]] as Array).append(i)
	var used := {}
	var chains: Array = []
	# Border starts first: otherwise an arbitrary middle segment leaves an
	# artificial dangling chain when it encounters an already-used prefix.
	var order: Array[int] = []
	for i in edges.size():
		if _on_border(edges[i][0], box):
			order.append(i)
	for i in edges.size():
		if not _on_border(edges[i][0], box):
			order.append(i)
	for i in order:
		if used.has(i):
			continue
		var chain := PackedVector2Array([edges[i][0]])
		var next := i
		while next >= 0 and not used.has(next):
			used[next] = true
			chain.append(edges[next][1])
			next = -1
			for candidate in starts.get(chain[-1], []):
				if not used.has(candidate):
					next = candidate
					break
		chains.append(chain)
	# Boundary intervals are shared by ALL open runs. Closing each run
	# independently and unioning them can flood a peninsula or an island.
	var events: Array = []
	var paths: Array = []
	var incomplete := false
	for chain in chains:
		if chain.size() < 2:
			continue
		if chain[0].distance_to(chain[-1]) < 0.02 and chain.size() >= 4:
			paths.append(chain)
		elif _on_border(chain[0], box) and _on_border(chain[-1], box):
			paths.append(chain)
			events.append({"p": chain[0], "dir": (chain[1] - chain[0]).normalized(), "t": _perimeter(chain[0], box)})
			events.append({"p": chain[-1], "dir": (chain[-1] - chain[-2]).normalized(), "t": _perimeter(chain[-1], box)})
		else:
			incomplete = true
			diagnostics.append({"kind": "open_coastline", "start": chain[0], "end": chain[-1]})
	# A missing mainland fragment makes even apparently closed sea rings
	# ambiguous. Keep mapped water polygons, but do not invent a coast
	# domain until all coastline runs in the extent can be resolved.
	if incomplete:
		return []
	events.sort_custom(func(a, b) -> bool: return a["t"] < b["t"])
	for i in events.size():
		var event: Dictionary = events[i]
		var d: Vector2 = event["dir"]
		var water := Vector2(-d.y, d.x)
		var t := fposmod(float(event["t"]) + 0.001, 2.0 * (box.size.x + box.size.y))
		var tangent := Vector2.RIGHT if t < box.size.x else Vector2.DOWN if t < box.size.x + box.size.y \
			else Vector2.LEFT if t < box.size.x * 2.0 + box.size.y else Vector2.UP
		if water.dot(tangent) > 0.00001:
			paths.append(_border_path(event["p"], events[(i + 1) % events.size()]["p"], box))
	var outgoing := {}
	for i in paths.size():
		if not outgoing.has(paths[i][0]):
			outgoing[paths[i][0]] = []
		(outgoing[paths[i][0]] as Array).append(i)
	var joined := {}
	var outers: Array = []
	var islands: Array = []
	for i in paths.size():
		if joined.has(i):
			continue
		var ring := PackedVector2Array(paths[i])
		joined[i] = true
		while ring[0].distance_to(ring[-1]) > 0.02:
			var next := -1
			for candidate in outgoing.get(ring[-1], []):
				if not joined.has(candidate):
					next = candidate
					break
			if next < 0:
				break
			joined[next] = true
			ring.append_array((paths[next] as PackedVector2Array).slice(1))
		if ring[0].distance_to(ring[-1]) > 0.02:
			diagnostics.append({"kind": "unclosed_coast_domain", "start": ring[0], "end": ring[-1]})
			continue
		ring.resize(ring.size() - 1)
		if ring.size() >= 3:
			if RingGeometry.signed_area(ring) > 0.0:
				outers.append(ring)
			else:
				islands.append(ring)
	# Closed islands alone imply an all-sea extent only when no coastline
	# is missing. A partial extract can also contain an unfinished mainland;
	# filling the rectangle in that case floods the entire city.
	if outers.is_empty() and not islands.is_empty():
		outers.append(_rectangle(box))
	var result: Array = []
	for outer in outers:
		result.append({"points": outer, "holes": islands})
	return result

static func _border_path(a: Vector2, b: Vector2, box: Rect2) -> PackedVector2Array:
	var ring := PackedVector2Array([a])
	var total := 2.0 * (box.size.x + box.size.y)
	var start := _perimeter(a, box)
	var span := fposmod(_perimeter(b, box) - start, total)
	var candidates: Array = []
	for p in _rectangle(box):
		var distance := fposmod(_perimeter(p, box) - start, total)
		if distance > 0.001 and distance < span - 0.001:
			candidates.append([distance, p])
	candidates.sort_custom(func(x, y) -> bool: return x[0] < y[0])
	for entry in candidates:
		ring.append(entry[1])
	ring.append(b)
	return ring

static func _rectangle(box: Rect2) -> PackedVector2Array:
	return PackedVector2Array([box.position, Vector2(box.end.x, box.position.y), box.end,
		Vector2(box.position.x, box.end.y)])

static func _on_border(p: Vector2, box: Rect2) -> bool:
	return absf(p.x - box.position.x) < 0.02 or absf(p.x - box.end.x) < 0.02 \
		or absf(p.y - box.position.y) < 0.02 or absf(p.y - box.end.y) < 0.02

static func _perimeter(p: Vector2, box: Rect2) -> float:
	if absf(p.y - box.position.y) < 0.02:
		return p.x - box.position.x
	if absf(p.x - box.end.x) < 0.02:
		return box.size.x + p.y - box.position.y
	if absf(p.y - box.end.y) < 0.02:
		return box.size.x + box.size.y + box.end.x - p.x
	return 2.0 * box.size.x + box.size.y + box.end.y - p.y

