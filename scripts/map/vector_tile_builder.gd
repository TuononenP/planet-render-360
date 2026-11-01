class_name VectorTileBuilder
extends RefCounted

## Turns a decoded vector tile (MvtReader) into draw batches for one style
## zoom, in tile pixels (0..px_size): triangulated fills batched by order
## and colour, polylines (dashes pre-cut into segments) batched the same
## way, and label candidates. Pure data, so it runs on a worker thread
## next to the decode; VectorTileNode only replays the batches.
##
## Result: { "fills": [{order, color, points, indices}],
##           "lines": [{order, color, width, polylines, segments}],
##           "labels": [{text, kind, priority, size, pos, angle, run, sub?}] }
## each list sorted by order (labels by priority).

static func build(decoded: Dictionary, zoom: float, colors: Dictionary, px_size: float) -> Dictionary:
	var fills: Dictionary = {}
	var lines: Dictionary = {}
	var labels: Array = []
	var line_label_seen: Dictionary = {}
	for layer_name in decoded:
		var layer: Dictionary = decoded[layer_name]
		var k := px_size / float(layer["extent"])
		var xf := Transform2D().scaled(Vector2(k, k))
		for f in layer["features"]:
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
	return {"fills": _sorted(fills), "lines": _sorted(lines), "labels": kept}

static func _sorted(batches: Dictionary) -> Array:
	var out: Array = batches.values()
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["order"]) < float(b["order"]))
	return out

static func _add_polygon(fills: Dictionary, fill: Array, rings: Array, xf: Transform2D) -> void:
	if rings.is_empty():
		return
	var outer: PackedVector2Array = xf * (rings[0] as PackedVector2Array)
	if _sub_pixel(outer):
		return
	# Sub-pixel holes are invisible; skipping them keeps continental tiles
	# (an ocean with hundreds of islets) quick to bridge and triangulate.
	var holes: Array = []
	for i in range(1, rings.size()):
		var hole: PackedVector2Array = xf * (rings[i] as PackedVector2Array)
		if not _sub_pixel(hole):
			holes.append(hole)
	var ring := outer
	if not holes.is_empty():
		ring = RingGeometry.bridge_holes(outer, holes)
	var idx := Geometry2D.triangulate_polygon(ring)
	if idx.is_empty():
		return  # degenerate after clipping at the tile edge
	if not holes.is_empty():
		idx = RingGeometry.drop_hole_triangles(ring, idx, holes)
	var color: Color = fill[1]
	var key := "%.2f|%s" % [float(fill[0]), color.to_html(true)]
	if not fills.has(key):
		fills[key] = {"order": float(fill[0]), "color": color,
			"points": PackedVector2Array(), "indices": PackedInt32Array()}
	var batch: Dictionary = fills[key]
	# Take the arrays out (leaving empties) so appends don't copy them:
	# packed arrays are copy-on-write while the dictionary still holds one.
	var points: PackedVector2Array = batch["points"]
	var indices: PackedInt32Array = batch["indices"]
	batch["points"] = PackedVector2Array()
	batch["indices"] = PackedInt32Array()
	var offset := points.size()
	points.append_array(ring)
	for v in idx:
		indices.append(v + offset)
	batch["points"] = points
	batch["indices"] = indices

static func _sub_pixel(ring: PackedVector2Array) -> bool:
	var box := RingGeometry.aabb(ring)
	return box.size.x < 1.0 and box.size.y < 1.0

## spec: [order, colour, width, dash] from MapStyle.lines_for.
static func _add_line(lines: Dictionary, spec: Array, line: PackedVector2Array) -> void:
	var width: float = spec[2]
	if width <= 0.05 or line.size() < 2:
		return
	var color: Color = spec[1]
	var dash: Array = spec[3]
	var key := "%.2f|%s|%.2f|%s" % [float(spec[0]), color.to_html(true), width, str(dash)]
	if not lines.has(key):
		lines[key] = {"order": float(spec[0]), "color": color, "width": width,
			"polylines": [], "segments": PackedVector2Array()}
	var batch: Dictionary = lines[key]
	if dash.is_empty():
		(batch["polylines"] as Array).append(line)
	else:
		var segments: PackedVector2Array = batch["segments"]
		batch["segments"] = PackedVector2Array()  # no copy-on-write while appending
		segments.append_array(dash_segments(line, float(dash[0]) * width, float(dash[1]) * width))
		batch["segments"] = segments

## A polyline cut into on/off dashes, as segment pairs for draw_multiline.
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
