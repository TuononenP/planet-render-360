class_name ShoreStitch
extends RefCounted

## Adjacent local subdivisions may introduce different stations on a
## shared cell edge. Insert their union into both surfaces before sampling
## or rendering, preserving each side of a hard bank independently.
static func build(model: ShorelineModel, abort: BuildAbort = null) -> void:
	if not ShoreGeometry.force_script and ClassDB.class_exists("ShoreMesh"):
		model.patches = ClassDB.class_call_static("ShoreMesh", "stitch", model.patches, model.size, model.step, model.origin, abort)
		return
	var borders := {}
	for key in model.patches:
		if abort != null and abort.requested:
			return
		var box := model.cell_box(key)
		var patch: Dictionary = model.patches[key]
		var points: PackedVector3Array = patch["triangles"]
		for i in points.size():
			var p := points[i]
			var kind := _kind(patch, i / 3)
			for border in _borders(p, box, key):
				if not borders.has(border):
					borders[border] = {}
				var positions: Dictionary = borders[border]
				var xz := Vector2(p.x, p.z)
				if not positions.has(xz):
					positions[xz] = {}
				var heights: Dictionary = positions[xz]
				heights[kind] = minf(float(heights.get(kind, INF)), p.y)
	for key in model.patches:
		if abort != null and abort.requested:
			return
		var box := model.cell_box(key)
		var patch: Dictionary = model.patches[key]
		var points: PackedVector3Array = patch["triangles"]
		var out := {"triangles": [], "owners": [], "hard": [], "paving": []}
		for i in range(0, points.size(), 3):
			var ring := PackedVector3Array()
			var kind := _kind(patch, i / 3)
			for edge in 3:
				var a := points[i + edge]
				var b := points[i + (edge + 1) % 3]
				ring.append(a)
				var shared := _borders(a, box, key)
				var other := _borders(b, box, key)
				for border in shared:
					if not other.has(border):
						continue
					var positions: Dictionary = borders[border]
					var stations: Array = []
					var start := Vector2(a.x, a.z)
					var d := Vector2(b.x, b.z) - start
					if d.length_squared() < 0.000001:
						continue
					for p in positions:
						var t: float = (p - start).dot(d) / d.length_squared()
						if t <= 0.00001 or t >= 0.99999:
							continue
						var y := float(positions[p].get(kind, lerpf(a.y, b.y, t)))
						stations.append([t, Vector3(p.x, y, p.y)])
					stations.sort_custom(func(x, y) -> bool: return x[0] < y[0])
					for station in stations:
						ring.append(station[1])
			if ring.size() == 3:
				_append(out, ring, patch, i / 3)
			else:
				var centre := (points[i] + points[i + 1] + points[i + 2]) / 3.0
				for j in ring.size():
					_append(out, PackedVector3Array([centre, ring[j], ring[(j + 1) % ring.size()]]), patch, i / 3)
		model.patches[key] = {"triangles": PackedVector3Array(out["triangles"]),
			"owners": PackedInt32Array(out["owners"]), "hard": PackedByteArray(out["hard"]),
			"paving": PackedByteArray(out["paving"])}

static func _kind(patch: Dictionary, triangle: int) -> int:
	return 0 if int(patch["owners"][triangle]) >= 0 else 2 if int(patch["hard"][triangle]) != 0 else 1

static func _borders(p: Vector3, box: Rect2, key: Vector2i) -> Array:
	var out: Array = []
	if absf(p.x - box.position.x) < 0.005:
		out.append(Vector3i(0, key.x, key.y))
	if absf(p.x - box.end.x) < 0.005:
		out.append(Vector3i(0, key.x + 1, key.y))
	if absf(p.z - box.position.y) < 0.005:
		out.append(Vector3i(1, key.y, key.x))
	if absf(p.z - box.end.y) < 0.005:
		out.append(Vector3i(1, key.y + 1, key.x))
	return out

static func _append(out: Dictionary, points: PackedVector3Array, patch: Dictionary, triangle: int) -> void:
	(out["triangles"] as Array).append_array(Array(points))
	(out["owners"] as Array).append(int(patch["owners"][triangle]))
	(out["hard"] as Array).append(int(patch["hard"][triangle]))
	(out["paving"] as Array).append(int(patch["paving"][triangle]))
