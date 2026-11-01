class_name LineMesher
extends RefCounted

## Map lines as triangles, so a whole batch of roads draws with one
## canvas_item_add_triangle_array instead of one draw_polyline each (a city
## tile has thousands, and Godot does not batch polygon commands). Runs on
## the worker thread with the rest of VectorTileBuilder.
##
## Each segment is a core quad plus a 1px feather either side fading to
## alpha 0 (2D MSAA is off, so this is the antialiasing). Lines 3px and
## wider get round joins and caps: a fan at every vertex, so streets meet
## cleanly at junctions.

const FAN_STEPS := 8
const ROUND_MIN_WIDTH := 3.0

## Appends `lines` (tile pixels) to `mesh` = {points, colors, indices}.
## The arrays are taken out of the dictionary while appending (leaving
## empties) so copy-on-write never copies them, then put back.
static func append(mesh: Dictionary, lines: Array, width: float, color: Color,
		round_ends: bool = true) -> void:
	var points: PackedVector2Array = mesh["points"]
	var colors: PackedColorArray = mesh["colors"]
	var indices: PackedInt32Array = mesh["indices"]
	mesh["points"] = PackedVector2Array()
	mesh["colors"] = PackedColorArray()
	mesh["indices"] = PackedInt32Array()
	if width < 1.0:
		# Hairlines: a 1px line faded by its width reads as thinner.
		color.a *= width
		width = 1.0
	var core := maxf(width / 2.0 - 0.5, 0.0)
	var edge := width / 2.0 + 0.5
	var clear := Color(color, 0.0)
	var fans := round_ends and width >= ROUND_MIN_WIDTH
	for l in lines:
		var line: PackedVector2Array = l
		if line.size() < 2:
			continue
		for i in range(1, line.size()):
			var a := line[i - 1]
			var b := line[i]
			var dir := b - a
			if dir.length_squared() < 1e-6:
				continue
			var n := Vector2(-dir.y, dir.x).normalized()
			var base := points.size()
			points.append_array(PackedVector2Array([a - n * edge, a - n * core, a + n * core, a + n * edge,
				b - n * edge, b - n * core, b + n * core, b + n * edge]))
			colors.append_array(PackedColorArray([clear, color, color, clear, clear, color, color, clear]))
			for k in 3:
				# Strip k joins column k and k + 1 of the a-row and b-row.
				indices.append_array(PackedInt32Array([base + k, base + k + 1, base + 4 + k + 1,
					base + k, base + 4 + k + 1, base + 4 + k]))
		if not fans:
			continue
		for p in line:
			# A disc at every vertex: the round join or cap.
			var centre := points.size()
			points.append(p)
			colors.append(color)
			for s in FAN_STEPS:
				var ang := TAU * float(s) / float(FAN_STEPS)
				points.append(p + Vector2(cos(ang), sin(ang)) * core)
				colors.append(color)
			for s in FAN_STEPS:
				indices.append_array(PackedInt32Array([centre, centre + 1 + s,
					centre + 1 + (s + 1) % FAN_STEPS]))
	mesh["points"] = points
	mesh["colors"] = colors
	mesh["indices"] = indices
