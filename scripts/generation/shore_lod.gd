class_name ShoreLod
extends RefCounted

## Coarsen only cells whose samples lie within 5 mm of one plane.
## Both the fine and coarse triangles then lie within 1 cm of each
## other everywhere. Shore patches are never simplified. Fine-neighbour
## edges retain every shared grid vertex, preventing T-junction cracks.
static func indices(model: ShorelineModel, preset: int, verts: PackedVector3Array) -> PackedInt32Array:
	var stride: int = [3, 2, 2, 1][RenderSettings.clamp_preset(preset)]
	var tiles := {}
	for z in range(0, model.size - 1, stride):
		for x in range(0, model.size - 1, stride):
			var end := Vector2i(mini(x + stride, model.size - 1), mini(z + stride, model.size - 1))
			var refine := stride == 1 or end.x - x < 2 or end.y - z < 2
			var a := verts[z * model.size + x]
			var b := verts[z * model.size + end.x]
			var c := verts[end.y * model.size + x]
			for iz in range(z, end.y + 1):
				for ix in range(x, end.x + 1):
					var p := verts[iz * model.size + ix]
					var plane := a.y + (b.y - a.y) * (p.x - a.x) / (b.x - a.x) + (c.y - a.y) * (p.z - a.z) / (c.z - a.z)
					if absf(p.y - plane) > 0.005 or model.patches.has(Vector2i(ix, iz)):
						refine = true
			tiles[Vector2i(x / stride, z / stride)] = {"start": Vector2i(x, z), "end": end, "refine": refine}
	var result := PackedInt32Array()
	for key in tiles:
		var tile: Dictionary = tiles[key]
		var start: Vector2i = tile["start"]
		var end: Vector2i = tile["end"]
		if bool(tile["refine"]):
			for z in range(start.y, end.y):
				for x in range(start.x, end.x):
					if model.patches.has(Vector2i(x, z)):
						continue
					var a := z * model.size + x
					result.append_array([a, a + 1, a + model.size, a + 1, a + model.size + 1, a + model.size])
		else:
			var corners := [start, Vector2i(end.x, start.y), end, Vector2i(start.x, end.y)]
			var neighbours := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
			var ring: Array[int] = []
			for edge in 4:
				var a: Vector2i = corners[edge]
				var b: Vector2i = corners[(edge + 1) % 4]
				var next: Dictionary = tiles.get(key + neighbours[edge], {})
				var count := maxi(absi(b.x - a.x), absi(b.y - a.y)) if bool(next.get("refine", false)) else 1
				for i in count:
					var p := Vector2i(Vector2(a).lerp(Vector2(b), float(i) / float(count)))
					ring.append(p.y * model.size + p.x)
			var centre := Vector2i((start.x + end.x) / 2, (start.y + end.y) / 2)
			var ci := centre.y * model.size + centre.x
			for i in ring.size():
				result.append_array([ci, ring[i], ring[(i + 1) % ring.size()]])
	return result

static func compact(source: Array) -> Array:
	var input: PackedInt32Array = source[Mesh.ARRAY_INDEX]
	var map := {}
	var welded := {}
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var tangents := PackedFloat32Array()
	var indices := PackedInt32Array()
	for old in input:
		if not map.has(old):
			var p: Vector3 = source[Mesh.ARRAY_VERTEX][old]
			var bank: Vector2 = source[Mesh.ARRAY_TEX_UV2][old]
			var key := Vector4(p.x, p.y, p.z, bank.y)
			if welded.has(key):
				var existing: int = welded[key]
				map[old] = existing
				normals[existing] += source[Mesh.ARRAY_NORMAL][old]
				indices.append(existing)
				continue
			map[old] = verts.size()
			welded[key] = verts.size()
			verts.append(source[Mesh.ARRAY_VERTEX][old])
			normals.append(source[Mesh.ARRAY_NORMAL][old])
			colors.append(source[Mesh.ARRAY_COLOR][old])
			uv.append(source[Mesh.ARRAY_TEX_UV][old])
			uv2.append(source[Mesh.ARRAY_TEX_UV2][old])
			for i in 4:
				tangents.append(source[Mesh.ARRAY_TANGENT][old * 4 + i])
		indices.append(map[old])
	for i in normals.size():
		normals[i] = normals[i].normalized()
	var out := source.duplicate()
	out[Mesh.ARRAY_VERTEX] = verts
	out[Mesh.ARRAY_NORMAL] = normals
	out[Mesh.ARRAY_COLOR] = colors
	out[Mesh.ARRAY_TEX_UV] = uv
	out[Mesh.ARRAY_TEX_UV2] = uv2
	out[Mesh.ARRAY_TANGENT] = tangents
	out[Mesh.ARRAY_INDEX] = indices
	return out
