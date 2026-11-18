extends SceneTree

## Verifies roof realism fixes:
## 1. Glass roofs use a dedicated skylight glazing material (roof-tagged, no
##    facade_set / vertical room shader, no night emission, roof UV scale).
## 2. Concentric-band RoofSkeleton (both GDScript and native RoofKernels) builds
##    exact-area courtyard and complex roofs with zero sawtooth contour jumps,
##    zero holes, zero steep shards, and sloped terrassons past 3.6 m.
## 3. Matte slate (metallic=0, lifted roughness) & HeroLook landmark roofs
##    (real slate / standing-seam sheet_metal instead of smooth concrete).
## 4. Courtyard / >8-corner Haussmann mansard blocks get Parisian chimneys with
##    terracotta pots, all clear of courtyard holes.

var failures: Array[String] = []

func _init() -> void:
	FacadeMaterials.begin_build()
	_check_skylight_glass()
	_check_skeleton_bands()
	_check_materials_and_hero_look()
	_check_courtyard_chimneys()
	if failures.is_empty():
		print("ROOF REALISM OK: skylight glass, concentric-band skeleton (GDScript+native), matte slate/HeroLook, courtyard chimneys")
		quit(0)
	else:
		for f in failures:
			printerr("ROOF REALISM FAIL: ", f)
		quit(1)

func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)

func _rect(x0: float, z0: float, x1: float, z1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1)])

func _check_skylight_glass() -> void:
	var m := FacadeMaterials.roof_set_material("glass", Color.WHITE, 1) as StandardMaterial3D
	_check(m != null, "glass roof material should exist")
	if m == null:
		return
	_check(RoofVariety.is_roof(m), "glass roof should be marked as a roof (snow + tint)")
	_check(not m.has_meta("facade_set"), "glass roof must not carry facade_set (no vertical room shader)")
	_check(not m.emission_enabled, "glass roof must not carry office night-window emission")
	_check(m.uv1_scale.x > 1.2, "glass roof should tile at skylight pane scale, got %s" % m.uv1_scale)
	var fast := FacadeMaterials.roof_set_material("glass", Color.WHITE, 0) as StandardMaterial3D
	_check(fast != null and not fast.normal_enabled, "Fast glass roof stays albedo-only")

func _check_skeleton_bands() -> void:
	var outer := _rect(0, 0, 44, 44)
	var hole := _rect(14, 14, 30, 30)  # 14 m wide courtyard wings
	var l_ring := PackedVector2Array([Vector2(0, 0), Vector2(60, 0), Vector2(60, 14),
		Vector2(14, 14), Vector2(14, 50), Vector2(0, 50)])
	var multi_holes := [_rect(10, 10, 22, 34), _rect(28, 10, 36, 34)]
	var cases := [
		["courtyard_mansard", outer, [hole], 10.0, 4.0, "mansard", 44.0 * 44.0 - 16.0 * 16.0],
		["courtyard_hipped", outer, [hole], 10.0, 3.6, "hipped", 44.0 * 44.0 - 16.0 * 16.0],
		["multi_hole_mansard", _rect(0, 0, 46, 44), multi_holes, 10.0, 3.8, "mansard",
			46.0 * 44.0 - 12.0 * 24.0 - 8.0 * 24.0],
		["l_wing_mansard", l_ring, [], 10.0, 4.0, "mansard", 60.0 * 14.0 + 14.0 * 36.0],
	]
	for mode in ["native", "gdscript"]:
		if mode == "native" and not RoofGeometry._native:
			continue
		for cs in cases:
			var label := "%s/%s" % [mode, cs[0]]
			var ring: PackedVector2Array = cs[1]
			var holes: Array = cs[2]
			var top: float = cs[3]
			var rh: float = cs[4]
			var shape: String = cs[5]
			var expect_area: float = cs[6]
			var mesh: ArrayMesh
			if mode == "native":
				mesh = RoofGeometry._native_mesh(ring, top, rh, shape, PackedByteArray(), false, holes)
			else:
				var prev := RoofGeometry._native
				RoofGeometry._native = false
				mesh = RoofGeometry.form_mesh(ring, top, rh, shape, PackedByteArray(), false, holes)
				RoofGeometry._native = prev
			_check(mesh != null, label + " failed to mesh")
			if mesh == null:
				continue
			var src := MeshArrays.surface(mesh, 0)
			var verts: PackedVector3Array = src[Mesh.ARRAY_VERTEX]
			var norms: PackedVector3Array = src[Mesh.ARRAY_NORMAL]
			var area := 0.0
			var bad_norm := 0
			var bad_pos := 0
			var steep_shard := 0
			var sawtooth_jump := 0
			var slope_beyond_3_6 := false
			for k in range(0, verts.size(), 3):
				var v0 := verts[k]
				var v1 := verts[k + 1]
				var v2 := verts[k + 2]
				var e1 := Vector2(v1.x - v0.x, v1.z - v0.z)
				var e2 := Vector2(v2.x - v0.x, v2.z - v0.z)
				area += absf(e1.cross(e2)) * 0.5
				var n := norms[k]
				if n.y <= 0.0:
					bad_norm += 1
				if absf(n.y) < 0.26:
					steep_shard += 1
				var mid := (v0 + v1 + v2) / 3.0
				var m2 := Vector2(mid.x, mid.z)
				if not Geometry2D.is_point_in_polygon(m2, ring):
					bad_pos += 1
				for h in holes:
					if Geometry2D.is_point_in_polygon(m2, h as PackedVector2Array):
						bad_pos += 1
				# Sawtooth check: on a mansard with a brisis break, no triangle
				# may jump directly from the eave (top) to the full peak (top+rh).
				if shape == "mansard":
					var y_lo := minf(v0.y, minf(v1.y, v2.y))
					var y_hi := maxf(v0.y, maxf(v1.y, v2.y))
					if y_lo < top + 0.05 and y_hi > top + rh * 0.90:
						sawtooth_jump += 1
					# Terrasson should slope past the old 3.6 m cap on wide wings.
					if n.y < 0.995 and m2.x > 8.0 and m2.x < 36.0 and m2.y > 4.0 and m2.y < 8.0:
						slope_beyond_3_6 = true
			_check(absf(area - expect_area) <= expect_area * 0.015,
				"%s area %.1f != expected %.1f" % [label, area, expect_area])
			_check(bad_norm == 0, "%s has %d down-facing normals" % [label, bad_norm])
			_check(bad_pos == 0, "%s has %d triangles outside footprint or inside courtyard" % [label, bad_pos])
			_check(steep_shard == 0, "%s has %d steep shards (abs(n.y) < 0.26)" % [label, steep_shard])
			_check(sawtooth_jump == 0, "%s has %d eave-to-peak sawtooth triangles" % [label, sawtooth_jump])
			if cs[0] == "courtyard_mansard":
				_check(slope_beyond_3_6, label + " terrasson should keep sloping past 3.6 m on 14 m wings")

func _check_materials_and_hero_look() -> void:
	var slate := FacadeMaterials.roof_set_material("slate", Color.WHITE, 1) as StandardMaterial3D
	_check(slate != null and slate.metallic == 0.0, "slate roof must be non-metallic")
	var rimg := MaterialLibrary._set_image("slate", "rough", false)
	var rsum := 0.0
	var rn := 0
	for y in range(0, rimg.get_height(), 16):
		for x in range(0, rimg.get_width(), 16):
			rsum += rimg.get_pixel(x, y).r
			rn += 1
	var rmean := rsum / float(maxi(rn, 1))
	_check(rmean >= 0.74, "slate roughness mean %.2f too glossy (want >= 0.74)" % rmean)
	var hdv := HeroLook.roof({"roof_colour": "#485058"}, null) as StandardMaterial3D
	_check(hdv != null and hdv.albedo_texture == LandmarkMaterials.tex("slate", "diff"),
		"mapped landmark coloured roof should use slate texture, not smooth concrete")
	var zinc := HeroLook.roof({"roof_material": "zinc"}, null) as StandardMaterial3D
	_check(zinc != null and zinc.albedo_texture == LandmarkMaterials.tex("sheet_metal", "diff"),
		"mapped landmark zinc roof should use standing-seam sheet_metal")
	var copper := HeroLook.roof({"roof_material": "copper"}, null) as StandardMaterial3D
	_check(copper != null and copper.albedo_texture == LandmarkMaterials.tex("sheet_metal", "diff")
		and copper.albedo_color.g > copper.albedo_color.r,
		"mapped landmark copper roof should keep standing seams and verdigris tint")

func _check_courtyard_chimneys() -> void:
	# 10-corner chamfered courtyard block (not boxy!) with Paris Haussmann look.
	var ring := PackedVector2Array([
		Vector2(2, 0), Vector2(38, 0), Vector2(40, 2), Vector2(40, 38),
		Vector2(38, 40), Vector2(2, 40), Vector2(0, 38), Vector2(0, 2)])
	var hole := _rect(12, 12, 28, 28)
	var look := ArchitectureStyle.resolve({"levels": 6, "roof_shape": "mansard"}, "haussmann", "dense", 0.37, 1300.0)
	var root := Node3D.new()
	var slate := MaterialLibrary.slate()
	BuildingDetail.add(root, ring, 18.0, 18.0, "mansard", 3.6, look, slate, slate,
		0.37, true, PackedByteArray(), false, true, "FR", true, NAN, [hole])
	var pots := 0
	var in_hole := 0
	for c in root.get_children():
		if not (c is MeshInstance3D):
			continue
		var mesh := (c as MeshInstance3D).mesh as ArrayMesh
		for s in mesh.get_surface_count():
			var sm := mesh.surface_get_material(s)
			var verts: PackedVector3Array = mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			if sm == RooflineDetail._mat("pot"):
				pots += verts.size()
			for v in verts:
				if RingGeometry.point_in_ring(Vector2(v.x, v.z), hole):
					in_hole += 1
	_check(pots > 0, "Haussmann courtyard mansard block should carry chimney stacks with terracotta pots")
	_check(in_hole == 0, "Zero chimney/detail vertices may fall inside the courtyard hole, got %d" % in_hole)
	root.free()
