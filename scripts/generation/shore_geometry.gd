class_name ShoreGeometry
extends RefCounted

## Local planar subdivision. Every edge crossing becomes a slab boundary;
## trapezoids therefore cannot cross a shoreline, including island holes.
## This is also the hole-aware fallback when the native earcut is absent.
const EPS := 0.00001
const SNAP := 0.01
static var force_script := false

static func snap(p: Vector2) -> Vector2:
	return p.snapped(Vector2.ONE * SNAP)

static func clip_segment(a: Vector2, b: Vector2, box: Rect2) -> PackedVector2Array:
	var d := b - a
	var lo := 0.0
	var hi := 1.0
	for axis in 2:
		if absf(d[axis]) < EPS:
			if a[axis] < box.position[axis] - EPS or a[axis] > box.end[axis] + EPS:
				return PackedVector2Array()
		else:
			var t0 := (box.position[axis] - a[axis]) / d[axis]
			var t1 := (box.end[axis] - a[axis]) / d[axis]
			lo = maxf(lo, minf(t0, t1))
			hi = minf(hi, maxf(t0, t1))
		if lo > hi:
			return PackedVector2Array()
	if (hi - lo) * d.length() < EPS:
		return PackedVector2Array()
	return PackedVector2Array([snap(a + d * lo), snap(a + d * hi)])

static func partition(box: Rect2, segments: Array) -> Array:
	if not force_script and ClassDB.class_exists("ShoreKernels"):
		return ClassDB.class_call_static("ShoreKernels", "partition", box, segments)
	return partition_script(box, segments)

static func partition_script(box: Rect2, segments: Array) -> Array:
	var edges: Array = []
	var xs: Array[float] = [box.position.x, box.end.x]
	for segment in segments:
		var cut := clip_segment(segment[0], segment[1], box)
		if cut.size() == 2:
			edges.append(cut)
			xs.append(cut[0].x)
			xs.append(cut[1].x)
	for i in edges.size():
		for j in range(i + 1, edges.size()):
			var hit: Variant = Geometry2D.segment_intersects_segment(edges[i][0], edges[i][1], edges[j][0], edges[j][1])
			if hit is Vector2:
				xs.append(snap(hit).x)
	xs.sort()
	var unique: Array[float] = []
	for x in xs:
		x = clampf(x, box.position.x, box.end.x)
		if unique.is_empty() or x - unique[-1] > EPS:
			unique.append(x)
	var out: Array = []
	for i in range(unique.size() - 1):
		var left := unique[i]
		var right := unique[i + 1]
		var mid := (left + right) * 0.5
		var active: Array = [PackedVector2Array([box.position, Vector2(box.end.x, box.position.y)]),
			PackedVector2Array([Vector2(box.position.x, box.end.y), box.end])]
		for edge in edges:
			if mid > minf(edge[0].x, edge[1].x) and mid < maxf(edge[0].x, edge[1].x):
				active.append(edge)
		active.sort_custom(func(a, b) -> bool: return _line_y(a, mid) < _line_y(b, mid))
		for j in range(active.size() - 1):
			if _line_y(active[j + 1], mid) - _line_y(active[j], mid) < EPS:
				continue
			var ring := PackedVector2Array([
				Vector2(left, _line_y(active[j], left)), Vector2(right, _line_y(active[j], right)),
				Vector2(right, _line_y(active[j + 1], right)), Vector2(left, _line_y(active[j + 1], left))])
			var clean := PackedVector2Array()
			for p in ring:
				p = snap(p)
				if clean.is_empty() or p.distance_squared_to(clean[-1]) > EPS * EPS:
					clean.append(p)
			if clean.size() > 2 and clean[0].distance_squared_to(clean[-1]) < EPS * EPS:
				clean.resize(clean.size() - 1)
			if clean.size() >= 3 and absf(RingGeometry.signed_area(clean)) > EPS:
				out.append(clean)
	return out

static func _line_y(edge, x: float) -> float:
	var a: Vector2 = edge[0]
	var b: Vector2 = edge[1]
	return lerpf(a.y, b.y, (x - a.x) / (b.x - a.x))

## Returns triangles as independent XZ vertices, including all holes.
static func triangulate(outer: PackedVector2Array, holes: Array = []) -> PackedVector2Array:
	var points := PackedVector2Array(outer)
	for hole in holes:
		points.append_array(hole)
	if not force_script and ClassDB.class_exists("EarcutKernels"):
		var idx: PackedInt32Array = ClassDB.class_call_static("EarcutKernels", "triangulate", outer, holes)
		var native := PackedVector2Array()
		for i in idx:
			native.append(points[i])
		var expected := absf(RingGeometry.signed_area(outer))
		for hole in holes:
			expected -= absf(RingGeometry.signed_area(hole))
		if absf(area(native) - expected) <= maxf(0.001, expected * 0.00001):
			return native
	var segments: Array = []
	var rings: Array = [outer]
	rings.append_array(holes)
	for ring in rings:
		for i in ring.size():
			segments.append([ring[i], ring[(i + 1) % ring.size()]])
	var result := PackedVector2Array()
	for piece in partition(RingGeometry.aabb(outer), segments):
		var centre := RingGeometry.centroid(piece)
		if not Geometry2D.is_point_in_polygon(centre, outer):
			continue
		var in_hole := false
		for hole in holes:
			if Geometry2D.is_point_in_polygon(centre, hole):
				in_hole = true
		if not in_hole:
			for i in range(1, piece.size() - 1):
				result.append_array([piece[0], piece[i], piece[i + 1]])
	return result

static func area(triangles: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(0, triangles.size(), 3):
		total += absf((triangles[i + 1] - triangles[i]).cross(triangles[i + 2] - triangles[i])) * 0.5
	return total

static func triangle_height(p: Vector2, a: Vector3, b: Vector3, c: Vector3) -> float:
	var v0 := Vector2(b.x - a.x, b.z - a.z)
	var v1 := Vector2(c.x - a.x, c.z - a.z)
	var v2 := p - Vector2(a.x, a.z)
	var det := v0.cross(v1)
	if absf(det) < EPS:
		return NAN
	var u := v2.cross(v1) / det
	var v := v0.cross(v2) / det
	if u < -0.0001 or v < -0.0001 or u + v > 1.0001:
		return NAN
	return a.y + u * (b.y - a.y) + v * (c.y - a.y)
