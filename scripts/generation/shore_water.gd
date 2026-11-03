class_name ShoreWater
extends RefCounted

## Exact water coverage from the same local subdivision as the terrain.
## No jittered shore vertices or centroid-only triangle rejection.
static func build(root: Node3D, model: ShorelineModel, material: ShaderMaterial,
		abort: BuildAbort = null) -> void:
	var started := Time.get_ticks_msec()
	var dist := PackedFloat32Array()
	dist.resize(model.size * model.size)
	for z in model.size:
		for x in model.size:
			var p := Vector2(x, z) * model.step + Vector2.ONE * model.origin
			dist[z * model.size + x] = 0.0 if model.domains.at(p) < 0 or model.edge_cells.has(Vector2i(x, z)) else 1e9
	WaterSurface._chamfer(dist, model.size, model.step, abort)
	# A second distance field identifies the nearest mapped hard shore so
	# only quays and bulkheads use the short shelf.
	var hard_dist := PackedFloat32Array()
	hard_dist.resize(model.size * model.size)
	hard_dist.fill(1e9)
	if model.hard_count() > 0:
		for cell in model._segment_cells:
			for index in model._segment_cells[cell]:
				if str(model.segments[index].get("kind", "")) == "hard":
					hard_dist[cell.y * model.size + cell.x] = 0.0
					break
		WaterSurface._chamfer(hard_dist, model.size, model.step, abort)
	if not ShoreGeometry.force_script and ClassDB.class_exists("ShoreMesh") and model.domains.native != null:
		var calibration := Vector4(WaterSurface.OPEN_RAMP_M, WaterSurface.SEA_RAMP_SCALE, WaterSurface.SHORE_M, WaterSurface.RIVER_FLOW)
		var packed: Array = ClassDB.class_call_static("ShoreMesh", "water", model.patches, model.size, model.step,
			model.origin, model.domains.bodies, model.domains.native, dist, hard_dist, calibration, abort)
		for index in packed.size():
			var batch: Array = packed[index]
			WaterSurface._commit(root, batch[0], batch[1], batch[2], _batch_material(material, index), batch[3])
		return
	var batches := [{"v": [], "c": [], "i": [], "flow": [], "weld": {}},
		{"v": [], "c": [], "i": [], "flow": [], "weld": {}}]
	for z in model.size - 1:
		if abort != null and abort.requested:
			return
		for x in model.size - 1:
			var key := Vector2i(x, z)
			if model.patches.has(key):
				var patch: Dictionary = model.patches[key]
				var triangles: PackedVector3Array = patch["triangles"]
				for i in range(0, triangles.size(), 3):
					var owner: int = patch["owners"][i / 3]
					if owner >= 0:
						_append(batches, model, dist, hard_dist, owner, PackedVector2Array([
							Vector2(triangles[i].x, triangles[i].z), Vector2(triangles[i + 1].x, triangles[i + 1].z),
							Vector2(triangles[i + 2].x, triangles[i + 2].z)]))
			else:
				var box := model.cell_box(key)
				var owner := model.domains.at(box.get_center())
				if owner >= 0:
					var a := box.position
					var b := Vector2(box.end.x, box.position.y)
					var c := box.end
					var d := Vector2(box.position.x, box.end.y)
					_append(batches, model, dist, hard_dist, owner, PackedVector2Array([a, b, d, b, c, d]))
	for index in batches.size():
		print("SHORE WATER assembly_ms=", Time.get_ticks_msec() - started, " batch=", index, " vertices=", (batches[index]["v"] as Array).size())
		var batch: Dictionary = batches[index]
		var mat := _batch_material(material, index)
		WaterSurface._commit(root, PackedVector3Array(batch["v"]), PackedColorArray(batch["c"]),
			PackedInt32Array(batch["i"]), mat, PackedVector2Array(batch["flow"]))
	print("SHORE WATER total_ms=", Time.get_ticks_msec() - started)

static func _batch_material(material: ShaderMaterial, index: int) -> ShaderMaterial:
	if index == 0:
		return material
	var mat := material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("wave_amp", 0.08)
	mat.set_shader_parameter("near_rough", 0.08)
	mat.set_shader_parameter("far_rough", 0.12)
	return mat

static func _append(batches: Array, model: ShorelineModel, dist: PackedFloat32Array,
		hard_dist: PackedFloat32Array, owner: int, points: PackedVector2Array) -> void:
	var body: Dictionary = model.domains.bodies[owner]
	var batch: Dictionary = batches[1 if bool(body.get("still_pool", false)) else 0]
	for p in points:
		var key := Vector3i(roundi(p.x * 100.0), roundi(p.y * 100.0), owner)
		if not batch["weld"].has(key):
			batch["weld"][key] = (batch["v"] as Array).size()
			var f := ((p - Vector2.ONE * model.origin) / model.step).clamp(Vector2.ZERO, Vector2.ONE * float(model.size - 1))
			var ix := mini(int(f.x), model.size - 2)
			var iz := mini(int(f.y), model.size - 2)
			var k := iz * model.size + ix
			var d := lerpf(lerpf(dist[k], dist[k + 1], f.x - ix),
				lerpf(dist[k + model.size], dist[k + model.size + 1], f.x - ix), f.y - iz)
			var tidal := bool(body.get("tidal", false))
			var hard := lerpf(lerpf(hard_dist[k], hard_dist[k + 1], f.x - ix),
				lerpf(hard_dist[k + model.size], hard_dist[k + model.size + 1], f.x - ix), f.y - iz)
			var ramp := WaterSurface.sea_ramp_m(hard, d, model.step) if tidal else WaterSurface.OPEN_RAMP_M
			(batch["v"] as Array).append(Vector3(p.x, model.domains.level(owner, p) + 0.03, p.y))
			(batch["c"] as Array).append(Color(clampf(d / ramp, 0.0, 1.0), 1.0 if tidal else 0.0,
				clampf(d / WaterSurface.SHORE_M, 0.0, 1.0)))
			var flow := Vector2.ZERO
			if body.has("axis"):
				flow = ((body["axis"][1] as Vector2) - (body["axis"][0] as Vector2)).normalized() * WaterSurface.RIVER_FLOW
			(batch["flow"] as Array).append(flow)
		(batch["i"] as Array).append(batch["weld"][key])
