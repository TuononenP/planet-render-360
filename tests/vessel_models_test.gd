extends SceneTree

## Headless: every vessel model builds at its length with an immersed hull,
## stays inside a triangle budget, and its far prototype is cheaper.
var failures: Array[String] = []

func _init() -> void:
	MaterialLibrary.hi_res = true
	var hull := VesselMaterials.paint("#2d3b4a")
	# model, length, beam, height, Ultra cap (4x original budget after the requested extra detail pass), far baseline, variant
	for c in [["liner", 250.0, 31.0, 50.0, 160000, 936, ""], ["passenger", 50.0, 8.0, 12.0, 32000, 636, ""],
			["tall_ship", 60.0, 9.5, 32.0, 24000, 638, ""], ["houseboat", 14.0, 4.2, 4.5, 8000, 274, ""],
			["motor_yacht", 24.0, 0.0, 0.0, 12000, 390, "flybridge"], ["motor_yacht", 11.0, 0.0, 0.0, 10000, 332, "sport"],
			["sail_yacht", 12.0, 0.0, 0.0, 12000, 480, ""], ["runabout", 7.0, 0.0, 0.0, 8000, 404, "runabout"],
			["runabout", 7.0, 0.0, 0.0, 8000, 432, "console"], ["runabout", 7.0, 0.0, 0.0, 8000, 720, "rib"], ["catamaran", 12.0, 0.0, 0.0, 16000, 1500, ""]]:
		var near := VesselPrototypes.geometry(c[0], c[1], c[2], c[3], hull, true, true, 0.9, c[6])
		var far := VesselPrototypes.geometry(c[0], c[1], c[2], c[3], hull, false, true, 0.9, c[6])
		_check(near.triangle_count() > 200 and near.triangle_count() <= int(c[4]), "%s %s m: %d triangles outside budget" % [c[0], c[1], near.triangle_count()])
		_check(far.triangle_count() <= int(c[5]), "%s far exceeds recorded baseline" % c[0])
		_check(far.triangle_count() < near.triangle_count(), "%s far geometry must be cheaper" % c[0])
		var root := Node3D.new()
		var box := AABB()
		for part in near.commit(root):
			box = box.merge(part.mesh.get_aabb()) if box.size != Vector3.ZERO else part.mesh.get_aabb()
			_normals(part.mesh, str(c[0]) + str(c[6]))
		_check(box.position.y < -0.05, "%s must have an immersed hull" % c[0])
		_check(absf(box.size.x - float(c[1])) / float(c[1]) < 0.02 or box.size.x >= float(c[1]) * 0.98, "%s length %.1f vs %.1f" % [c[0], box.size.x, c[1]])
		root.free()
	var surfaces := 1 # pontoon
	var far_baselines := {"motor": 332, "yacht": 390, "sail": 480, "day": 404, "rib": 720, "steam": 556, "houseboat": 274, "catamaran": 1500}
	for kind in VesselPrototypes.KINDS:
		var near_mesh := VesselPrototypes.mesh(kind)
		var far_mesh := VesselPrototypes.mesh(kind + "_far")
		_check(near_mesh.get_surface_count() >= 3 and far_mesh.get_surface_count() <= near_mesh.get_surface_count(), "%s prototype surfaces" % kind)
		surfaces += near_mesh.get_surface_count() + far_mesh.get_surface_count()
		var far_triangles := 0
		for s in far_mesh.get_surface_count():
			far_triangles += far_mesh.surface_get_array_len(s) / 3
		_check(far_triangles <= int(far_baselines[kind]), "%s far prototype grew" % kind)
		var painted := 0
		for s in near_mesh.get_surface_count():
			var material := near_mesh.surface_get_material(s)
			if material is StandardMaterial3D and material.vertex_color_use_as_albedo:
				painted += 1
			if material is ShaderMaterial:
				_check(not material.get_shader_parameter("use_vertex"), "snow must preserve unpainted decks")
		if kind in VesselPrototypes.STERN_ORIGIN:
			_check(painted == 1, "%s must have one instance-painted topside material" % kind)
	_check(surfaces <= MarinaBuilder.MAX_DRAW_CALLS, "all near/far kinds plus pontoon: %d surfaces" % surfaces)
	MaterialLibrary.hi_res = false
	var high := VesselPrototypes.geometry("motor_yacht", 11, 0, 0, hull, true, true, 0.9, "sport")
	MaterialLibrary.hi_res = true
	var ultra := VesselPrototypes.geometry("motor_yacht", 11, 0, 0, hull, true, true, 0.9, "sport")
	_check(ultra.triangle_count() > high.triangle_count() * 1.5, "Ultra must add substantial detail beyond High")
	var cat := VesselPrototypes.geometry("catamaran", 12, 0, 0, hull, true, true)
	var cat_root := Node3D.new()
	var cat_bounds := AABB()
	for part in cat.commit(cat_root):
		cat_bounds = cat_bounds.merge(part.mesh.get_aabb())
		var vertices: PackedVector3Array = part.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for p in vertices:
			if p.y < 0.0:
				_check(absf(p.z) > 1.2, "catamaran underwater tunnel must remain open")
	_check(cat_bounds.size.z <= 12.0 * CatamaranModel.BERTH_BEAM_SHARE, "catamaran fittings must stay inside the reserved beam")
	cat_root.free()
	_hull_boundaries()
	var ferry_root := Node3D.new()
	for part in HarbourFerries.model().commit(ferry_root):
		_normals(part.mesh, "ferry")
	ferry_root.free()
	if failures.is_empty():
		print("VESSEL MODELS OK: all variants, normals, smooth boundaries, open cockpit, budgets (%d surfaces), far prototypes" % surfaces)
		quit(0)
	else:
		for f in failures:
			printerr("VESSEL MODELS FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)

func _normals(mesh: ArrayMesh, label: String) -> void:
	var arrays := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	for i in range(0, v.size(), 3):
		_check(v[i].is_finite() and n[i].is_finite() and n[i + 1].is_finite() and n[i + 2].is_finite(), label + " finite geometry")
		_check(n[i].length_squared() > 0.9, label + " unit normals")
		_check((v[i + 2] - v[i]).cross(v[i + 1] - v[i]).dot(n[i] + n[i + 1] + n[i + 2]) >= -0.0001,
			label + " outward triangle winding")

func _hull_boundaries() -> void:
	var spec := {"length": 10.0, "beam": 3.0, "freeboard": 1.0, "draft": 0.7,
		"cockpit": Rect2(-2, 0, 4, 0.7), "cockpit_y": 0.4}
	var lm := LandmarkMesh.new()
	VesselMaterials.register(lm, false, VesselMaterials.get_mat("navy", false))
	HullLoft.loft(lm, spec, {"hull": "Hull", "boot": "Boot", "bottom": "Bottom", "deck": "Deck"})
	var holder := Node3D.new()
	var at_boundary := {}
	var closest := -INF
	for part in lm.commit(holder):
		var arrays := part.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		if part.name in ["Hull", "Boot", "Bottom"]:
			for i in vertices.size():
				var p := vertices[i]
				if absf(p.x) < 3.0 and p.y <= 0.25 and p.y >= 0.0:
					if not at_boundary.has(p):
						at_boundary[p] = {}
					at_boundary[p][str(part.name)] = normals[i]
		for i in range(0, vertices.size(), 3):
			var hit = Geometry3D.ray_intersects_triangle(Vector3(0, 10, 0), Vector3.DOWN, vertices[i], vertices[i + 1], vertices[i + 2])
			if hit != null:
				closest = maxf(closest, (hit as Vector3).y)
	var shared := 0
	for p in at_boundary:
		var values: Array = at_boundary[p].values()
		if values.size() > 1:
			shared += 1
			_check((values[0] as Vector3).dot(values[1]) > 0.9999, "paint boundary must not create a shading crease")
	_check(shared > 8, "fixture must exercise shared hull/boot/bottom boundaries")
	_check(absf(closest - 0.4) < 0.001, "the cockpit opening must expose its recessed sole")
	holder.free()
