class_name VectorTileBuilder
extends RefCounted

## Turns a decoded vector tile (MvtReader) into draw batches for one style
## zoom, in tile pixels (0..px_size): every fill and every line ends up in a
## triangle mesh batched by draw order and colour (lines meshed by
## LineMesher), plus label candidates. Pure data, so it runs on a worker
## thread next to the decode; VectorTileNode only replays the meshes, one
## canvas_item_add_triangle_array per batch.
##
## Result: { "batches": [{order, points, colors, indices}] sorted by order,
##           "labels": [{text, kind, priority, size, pos, angle, run, sub?}] }

## Holes smaller than this (px²) are invisible; skipping them keeps a lake
## district or an archipelago quick to bridge and triangulate.
const MIN_HOLE_AREA := 4.0
## At most this many holes per polygon, the largest first.
const MAX_HOLES := 48
## How far (px) the retry's bridge seam is opened, see RingGeometry.bridge_holes.
const SEAM_SLIVER := 0.003

## `cancel` is a one-element Array the owner sets to true to stop early
## (the screen is leaving); the result is then {}.
static func build(decoded: Dictionary, zoom: float, colors: Dictionary, px_size: float,
		cancel: Array = [false]) -> Dictionary:
	var fills: Dictionary = {}
	var lines: Dictionary = {}
	var labels: Array = []
	var line_label_seen: Dictionary = {}
	for layer_name in decoded:
		var layer: Dictionary = decoded[layer_name]
		var k := px_size / float(layer["extent"])
		var xf := Transform2D().scaled(Vector2(k, k))
		for f in layer["features"]:
			if cancel[0]:
				return {}
			var feature: Dictionary = f
			var tags: Dictionary = feature["tags"]
			var ftype: int = feature["type"]
			var geom: Array = feature["geom"]
			if ftype == MvtReader.POLYGON:
				var fill := MapStyle.fill_for(layer_name, tags, zoom, colors)
				if not fill.is_empty() and (fill[1] as Color).a > 0.01:
					for poly in geom:
						_add_polygon(fills, fill, poly as Array, xf)
			elif ftype == MvtReader.LINE:
				for spec in MapStyle.lines_for(layer_name, tags, zoom, colors):
					for line in geom:
						_add_line(lines, spec as Array, xf * (line as PackedVector2Array))
			var label := MapStyle.label_for(layer_name, tags, zoom)
			if label.is_empty():
				continue
			if ftype == MvtReader.POINT:
				var pos: Vector2 = xf * (geom[0] as PackedVector2Array)[0]
				if Rect2(0, 0, px_size, px_size).has_point(pos):
					label["pos"] = pos
					label["angle"] = 0.0
					label["run"] = 0.0
					labels.append(label)
			elif ftype == MvtReader.LINE:
				var seg := _longest_run(geom, xf, px_size)
				var text := str(label["text"])
				if seg.is_empty() or (line_label_seen.has(text) and float(line_label_seen[text]) >= float(seg[2])):
					continue
				line_label_seen[text] = seg[2]
				label["pos"] = seg[0]
				label["angle"] = seg[1]
				label["run"] = seg[2]
				labels.append(label)
	# One line label per name per tile: keep the one on the longest run.
	var kept: Array = []
	for l in labels:
		var label: Dictionary = l
		if float(label["run"]) > 0.0 and float(line_label_seen[label["text"]]) > float(label["run"]):
			continue
		kept.append(label)
	kept.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["priority"]) < int(b["priority"]))
	var batches: Array = fills.values()
	for b in lines.values():
		if cancel[0]:
			return {}
		var batch: Dictionary = b
		var mesh := {"order": batch["order"], "points": PackedVector2Array(),
			"colors": PackedColorArray(), "indices": PackedInt32Array()}
		LineMesher.append(mesh, batch["lines"], float(batch["width"]), batch["color"],
			not bool(batch["dashed"]))
		batches.append(mesh)
	batches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["order"]) < float(b["order"]))
	return {"batches": batches, "labels": kept}

static func _box_area(box: Rect2) -> float:
	return box.size.x * box.size.y

static func _add_polygon(fills: Dictionary, fill: Array, rings: Array, xf: Transform2D) -> void:
	if rings.is_empty():
		return
	var outer: PackedVector2Array = xf * (rings[0] as PackedVector2Array)
	if _box_area(RingGeometry.aabb(outer)) < MIN_HOLE_AREA:
		return
	var holes: Array = []
	for i in range(1, rings.size()):
		var hole: PackedVector2Array = xf * (rings[i] as PackedVector2Array)
		if _box_area(RingGeometry.aabb(hole)) >= MIN_HOLE_AREA:
			holes.append(hole)
	if holes.size() > MAX_HOLES:
		holes.sort_custom(func(a: PackedVector2Array, b: PackedVector2Array) -> bool:
			return _box_area(RingGeometry.aabb(a)) > _box_area(RingGeometry.aabb(b)))
		holes.resize(MAX_HOLES)
	var ring := outer
	var idx := PackedInt32Array()
	if not holes.is_empty():
		ring = RingGeometry.bridge_holes(outer, holes)
		idx = _keyhole_triangles(ring, holes)
		if idx.is_empty():
			# Generalised islands that touch the coast, or a seam that doubles
			# a point, leave the ear clipper no ear, and one bad island would
			# cost the whole archipelago (the Bahamas at zoom 7). Retry on a
			# sliver seam without the islands that touch the outline.
			var clear := RingGeometry.holes_clear_of(outer, holes)
			if not clear.is_empty():
				ring = RingGeometry.bridge_holes(outer, clear, SEAM_SLIVER)
				idx = _keyhole_triangles(ring, clear)
	if idx.is_empty():
		# No holes, or the keyhole ring would not triangulate: the outer
		# ring alone beats losing a whole lake or coastline.
		ring = outer
		idx = Geometry2D.triangulate_polygon(ring)
	if idx.is_empty():
		return  # degenerate after clipping at the tile edge
	var color: Color = fill[1]
	var key := "%.2f|%s" % [float(fill[0]), color.to_html(true)]
	if not fills.has(key):
		fills[key] = {"order": float(fill[0]), "points": PackedVector2Array(),
			"colors": PackedColorArray(), "indices": PackedInt32Array()}
	var batch: Dictionary = fills[key]
	# Take the arrays out (leaving empties) so appends don't copy them:
	# packed arrays are copy-on-write while the dictionary still holds one.
	var points: PackedVector2Array = batch["points"]
	var cols: PackedColorArray = batch["colors"]
	var indices: PackedInt32Array = batch["indices"]
	batch["points"] = PackedVector2Array()
	batch["colors"] = PackedColorArray()
	batch["indices"] = PackedInt32Array()
	var offset := points.size()
	points.append_array(ring)
	var start := cols.size()
	cols.resize(start + ring.size())
	for i in ring.size():
		cols[start + i] = color
	for v in idx:
		indices.append(v + offset)
	batch["points"] = points
	batch["colors"] = cols
	batch["indices"] = indices

## Triangles of a keyhole ring with the ones inside a hole dropped, or
## empty when the ring would not triangulate.
static func _keyhole_triangles(ring: PackedVector2Array, holes: Array) -> PackedInt32Array:
	var idx := Geometry2D.triangulate_polygon(ring)
	if idx.is_empty():
		return idx
	return _drop_hole_triangles(ring, idx, holes)

## RingGeometry.drop_hole_triangles with a bounding-box check first, so a
## triangle only runs point-in-ring against holes it could be inside.
static func _drop_hole_triangles(ring: PackedVector2Array, idx: PackedInt32Array, holes: Array) -> PackedInt32Array:
	var boxes: Array[Rect2] = []
	for h in holes:
		boxes.append(RingGeometry.aabb(h))
	var out := PackedInt32Array()
	for t in idx.size() / 3:
		var c := (ring[idx[t * 3]] + ring[idx[t * 3 + 1]] + ring[idx[t * 3 + 2]]) / 3.0
		var in_hole := false
		for i in holes.size():
			if boxes[i].has_point(c) and RingGeometry.point_in_ring(c, holes[i]):
				in_hole = true
				break
		if not in_hole:
			out.append_array(PackedInt32Array([idx[t * 3], idx[t * 3 + 1], idx[t * 3 + 2]]))
	return out

## spec: [order, colour, width, dash] from MapStyle.lines_for. Dashed lines
## are cut here and meshed as separate pieces.
static func _add_line(lines: Dictionary, spec: Array, line: PackedVector2Array) -> void:
	var width: float = spec[2]
	if width <= 0.05 or line.size() < 2:
		return
	var color: Color = spec[1]
	var dash: Array = spec[3]
	var key := "%.2f|%s|%.2f|%s" % [float(spec[0]), color.to_html(true), width, str(dash)]
	if not lines.has(key):
		lines[key] = {"order": float(spec[0]), "color": color, "width": width,
			"dashed": not dash.is_empty(), "lines": []}
	var pieces: Array = lines[key]["lines"]
	if dash.is_empty():
		pieces.append(line)
		return
	var segs := dash_segments(line, float(dash[0]) * width, float(dash[1]) * width)
	for i in range(0, segs.size() - 1, 2):
		pieces.append(PackedVector2Array([segs[i], segs[i + 1]]))

## A polyline cut into on/off dashes, as segment pairs.
## The pattern carries across vertices so corners don't restart it.
static func dash_segments(line: PackedVector2Array, on: float, off: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var period := maxf(on + off, 0.5)
	on = maxf(on, 0.25)
	var phase := 0.0  # distance into the current period
	for i in range(1, line.size()):
		var a := line[i - 1]
		var b := line[i]
		var length := a.distance_to(b)
		var t := 0.0
		while t < length:
			var step: float
			if phase < on:
				step = minf(on - phase, length - t)
				out.append(a.lerp(b, t / length))
				out.append(a.lerp(b, (t + step) / length))
			else:
				step = minf(period - phase, length - t)
			t += step
			phase = fmod(phase + step, period)
	return out

## The straightest long stretch of a line for its label: [midpoint, angle
## (kept upright), length] of the longest segment whose midpoint is inside
## the tile, or [] when there is none.
static func _longest_run(geom: Array, xf: Transform2D, px_size: float) -> Array:
	var best: Array = []
	var bounds := Rect2(0, 0, px_size, px_size)
	for l in geom:
		var line: PackedVector2Array = xf * (l as PackedVector2Array)
		for i in range(1, line.size()):
			var a := line[i - 1]
			var b := line[i]
			var mid := (a + b) * 0.5
			var length := a.distance_to(b)
			if not bounds.has_point(mid) or (not best.is_empty() and length <= float(best[2])):
				continue
			var angle := (b - a).angle()
			if angle > PI / 2.0:
				angle -= PI
			elif angle < -PI / 2.0:
				angle += PI
			best = [mid, angle, length]
	return best
