class_name ShoreSurface
extends RefCounted

## Canonical local patches: the stored triangles serve rendering and
## GroundTruth queries alike, independent of quality preset.
static func build(model: ShorelineModel, abort: BuildAbort = null) -> void:
	var kernel: Object = null
	if not ShoreGeometry.force_script and ClassDB.class_exists("ShorePatchKernel") and model.sampler != null:
		kernel = ClassDB.instantiate("ShorePatchKernel")
		kernel.setup(model.base, model.land, model.domains.bodies, model.segments,
			Vector4(model.size, model.step, model.origin, model.depth), model.sampler, model.domains.native, model._evidence.native)
	var keys := {}
	for key in model.edge_cells:
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				var k: Vector2i = key + Vector2i(dx, dz)
				if k.x >= 0 and k.y >= 0 and k.x < model.size - 1 and k.y < model.size - 1:
					keys[k] = true
	for key in model.transition_cells:
		keys[key] = true
	if kernel != null:
		_native_cells(model, kernel, keys.keys(), abort)
		return
	for key in keys:
		if abort != null and abort.requested:
			return
		var box := model.cell_box(key)
		var edges: Array = []
		for id in model.transition_cells.get(key, []):
			edges.append(model.transition_edges[id])
		for id in model.edge_cells.get(key, []):
			var raw: Dictionary = model._edges[id]
			var a: Vector2 = raw["a"]
			var b: Vector2 = raw["b"]
			var count := maxi(1, ceili(a.distance_to(b) / 2.0))
			var cut := ShoreGeometry.clip_segment(a, b, box)
			if cut.size() != 2:
				continue
			var d := b - a
			var first := clampi(floori((cut[0] - a).dot(d) / d.length_squared() * count), 0, count - 1)
			var last := clampi(ceili((cut[1] - a).dot(d) / d.length_squared() * count), first + 1, count)
			for i in range(first, last):
				edges.append([a.lerp(b, float(i) / float(count)), a.lerp(b, float(i + 1) / float(count))])
		var pieces := ShoreGeometry.partition(box, edges)
		var coverage := 0.0
		for piece in pieces:
			coverage += absf(RingGeometry.signed_area(piece))
		if absf(coverage - box.get_area()) > maxf(0.02, box.get_area() * 0.001):
			pieces = ShoreGeometry.partition_script(box, edges)
		if kernel != null:
			var patch: Dictionary = kernel.build(pieces)
			var area := float(patch["area"])
			patch.erase("area")
			if absf(area - box.get_area()) > maxf(0.02, box.get_area() * 0.001) or patch["triangles"].is_empty():
				model.diagnostics.append({"kind": "patch_failure", "cell": key, "area": area, "expected": box.get_area()})
			else:
				model.patches[key] = patch
			continue
		var triangles := PackedVector3Array()
		var owners := PackedInt32Array()
		var paving := PackedByteArray()
		var hard_regions := PackedByteArray()
		var area := 0.0
		for piece in pieces:
			var centre := RingGeometry.centroid(piece)
			var body := model.domains.at(centre)
			var near := model.nearest(centre)
			var hard := body < 0 and not near.is_empty() and str(near["segment"]["kind"]) == "hard"
			var natural_cover := model._evidence != null and model._evidence.contains_kind(centre, "natural")
			for i in range(1, piece.size() - 1):
				var points := PackedVector2Array([piece[0], piece[i], piece[i + 1]])
				var tri_area := ShoreGeometry.area(points)
				if tri_area < 0.00001:
					continue
				area += tri_area
				owners.append(body)
				hard_regions.append(1 if hard else 0)
				paving.append(1 if hard and not natural_cover else 0)
				for p in points:
					triangles.append(Vector3(p.x, model.vertex_height(p, body, near), p.y))
		var expected := box.size.x * box.size.y
		if absf(area - expected) > maxf(0.02, expected * 0.001) or triangles.is_empty():
			model.diagnostics.append({"kind": "patch_failure", "cell": key, "area": area, "expected": expected})
			continue
		model.patches[key] = {"triangles": triangles, "owners": owners, "paving": paving, "hard": hard_regions}

## build()'s cells through ShorePatchKernel.cells, in order: a cell the
## native partition left a gap in is partitioned by the script here.
static func _native_cells(model: ShorelineModel, kernel: Object, keys: Array, abort: BuildAbort) -> void:
	var results: Array = kernel.cells(keys, model.edge_cells, model.transition_cells, model._edges,
		model.transition_edges, abort)
	for entry: Array in results:
		var key: Vector2i = entry[0]
		match int(entry[1]):
			0:
				model.patches[key] = entry[2]
			1:
				model.diagnostics.append(entry[2])
			_:
				var box := model.cell_box(key)
				var patch: Dictionary = kernel.build(ShoreGeometry.partition_script(box, entry[2]))
				var area := float(patch["area"])
				patch.erase("area")
				if absf(area - box.get_area()) > maxf(0.02, box.get_area() * 0.001) or patch["triangles"].is_empty():
					model.diagnostics.append({"kind": "patch_failure", "cell": key, "area": area, "expected": box.get_area()})
				else:
					model.patches[key] = patch

## Replace canonical cells with their exact patches, retaining the ground
## material's UVs, far-colour fade and water-level attributes.
static func mesh_arrays(model: ShorelineModel, source: Array, preset: int, abort: BuildAbort = null) -> Array:
	if not ShoreGeometry.force_script and ClassDB.class_exists("ShoreMesh") and model.sampler != null:
		var native_source := source.duplicate()
		native_source[Mesh.ARRAY_INDEX] = ShoreLod.indices(model, preset, source[Mesh.ARRAY_VERTEX])
		return ClassDB.class_call_static("ShoreMesh", "surface", native_source, model.patches, model.size,
			model.step, model.origin, model.domains.bodies, model.sampler, abort)
	var verts: PackedVector3Array = source[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = source[Mesh.ARRAY_NORMAL]
	var colors: PackedColorArray = source[Mesh.ARRAY_COLOR]
	var uvs: PackedVector2Array = source[Mesh.ARRAY_TEX_UV]
	var uv2: PackedVector2Array = source[Mesh.ARRAY_TEX_UV2]
	var tangents: PackedFloat32Array = source[Mesh.ARRAY_TANGENT]
	var indices := ShoreLod.indices(model, preset, verts)
	for key in model.patches:
		if abort != null and abort.requested:
			return []
		var x: int = key.x
		var z: int = key.y
		var a := z * model.size + x
		var patch: Dictionary = model.patches[key]
		var points: PackedVector3Array = patch["triangles"]
		for i in range(0, points.size(), 3):
			var normal := (points[i + 2] - points[i]).cross(points[i + 1] - points[i]).normalized()
			if normal.y < 0.0:
				normal = -normal
			var offset := verts.size()
			var owner: int = patch["owners"][i / 3]
			for j in 3:
				var p := points[i + j]
				var f := (Vector2(p.x, p.z) - Vector2.ONE * model.origin) / model.step - Vector2(x, z)
				f = f.clamp(Vector2.ZERO, Vector2.ONE)
				verts.append(p)
				normals.append(normal)
				colors.append(colors[a].lerp(colors[a + 1], f.x).lerp(colors[a + model.size].lerp(colors[a + model.size + 1], f.x), f.y))
				uvs.append(uvs[a].lerp(uvs[a + 1], f.x).lerp(uvs[a + model.size].lerp(uvs[a + model.size + 1], f.x), f.y))
				var level := model.domains.level(owner, Vector2(p.x, p.z)) if owner >= 0 else uv2[a].x
				var bank := float(patch["paving"][i / 3])
				if owner < 0 and int(patch["hard"][i / 3]) == 0:
					var near := model.nearest(Vector2(p.x, p.z), 2)
					if not near.is_empty():
						bank = -clampf(1.0 - float(near["distance"]) / 1.5, 0.0, 1.0)
				uv2.append(Vector2(level, bank))
				tangents.append_array([1.0, 0.0, 0.0, 1.0])
			# Partition polygons have positive XZ winding (Godot's
			# clockwise front face viewed from the upward normal).
			indices.append_array([offset, offset + 1, offset + 2])
	var out := source.duplicate()
	out[Mesh.ARRAY_VERTEX] = verts
	out[Mesh.ARRAY_NORMAL] = normals
	out[Mesh.ARRAY_COLOR] = colors
	out[Mesh.ARRAY_TEX_UV] = uvs
	out[Mesh.ARRAY_TEX_UV2] = uv2
	out[Mesh.ARRAY_TANGENT] = tangents
	out[Mesh.ARRAY_INDEX] = indices
	return ShoreLod.compact(out)
