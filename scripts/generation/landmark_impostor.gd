class_name LandmarkImpostor
extends RefCounted

## Build-time octahedral impostor baker for far landmarks (> 3 km).
##
## Landmarks beyond `R_IMPOSTOR_M` from the world centre are baked on the
## CPU from their mesh surface arrays into 4 orthographic cardinal views
## (`SIZE x SIZE` RGBA8, azimuth 0/90/180/270 deg in landmark-local space)
## plus an alpha silhouette mask, and rendered on an 8-face upright
## dihedral octahedron (2 angled wing faces per cardinal view, clockwise
## front-facing, alpha-scissor with mipmap coverage preservation).
##
## Determinism & thread safety:
##  - Reads vertex/normal/index arrays via `MeshArrays.surface` and
##    material base colours from `LandmarkMaterials` metadata / properties
##    on the CPU — no GPU viewport or `RenderingServer` readback.
##  - Same input arrays always produce bit-identical RGBA8 buffers,
##    preserving the `parallel_build_test.gd` serial == parallel invariant.
##  - Between `R_IMPOSTOR_M` (3000 m) and `STRIP_REAL_M` (4200 m), real
##    parts are kept alongside the impostor so `LodRing` alpha-dither
##    cross-fades across the 3000 m threshold if a camera flies closer;
##    past 4200 m (unreachable from the +-1200 m detailed square), real
##    parts are stripped and freed at build time.
##  - Any bake failure falls back cleanly to the real landmark mesh and
##    records a plain-language note in `fallback_notes`.

const R_IMPOSTOR_M := 3000.0
const CROSSFADE_M := 180.0
const STRIP_REAL_M := 4200.0
const SIZE := 256
const ALPHA_CUT := 0.45
## Slight outward dihedral bow of each pair of wing faces so no two planes
## intersect coplanarly along the vertical centreline.
const BOW_FRAC := 0.08
## Fixed midday relief key in landmark-local space (bakes structural facet
## contrast into the albedo while StandardMaterial3D takes live sun/haze/night).
const RELIEF_KEY := Vector3(0.42, 0.78, -0.46)

## Test hook to force a bake failure and verify real-mesh fallback.
static var _fail_bake_test := false
static var _notes_mutex := Mutex.new()
static var fallback_notes: Array[String] = []

static func record_fallback(label: String, reason: String) -> void:
	var msg := "Landmark %s kept full mesh (%s)" % [label if label != "" else "site", reason]
	_notes_mutex.lock()
	fallback_notes.append(msg)
	_notes_mutex.unlock()
	push_warning("LandmarkImpostor: " + msg)

## FarCity-compatible band inner radius for `LodRing` preset culling.
static func band_r0_for(dist_m: float) -> float:
	if dist_m >= 7500.0:
		return 7500.0
	if dist_m >= 4500.0:
		return 4500.0
	return 2500.0

## Applies an octahedral impostor to `root` when `dist_m > R_IMPOSTOR_M`.
## Returns `"stripped"` when real parts were replaced, `"paired"` when
## kept for threshold cross-fade, or `""` when below threshold or fallen back.
static func apply_if_far(root: Node3D, dist_m: float, label: String = "") -> String:
	if root == null or dist_m <= R_IMPOSTOR_M:
		return ""
	var baked := bake(root, rad_to_deg(root.rotation.y))
	if not bool(baked.get("ok", false)):
		record_fallback(label, str(baked.get("note", "impostor bake failed")))
		return ""
	var strip := dist_m > STRIP_REAL_M
	var far_r0 := band_r0_for(dist_m)
	var imp := MeshInstance3D.new()
	imp.name = "Impostor"
	imp.mesh = baked["mesh"]
	imp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	imp.set_meta("lod_layer", "Landmarks")
	imp.set_meta("lod_impostor", true)
	imp.set_meta("impostor_only", strip)
	imp.set_meta("far_r0", far_r0)
	if strip:
		for part in LandmarkBuilder.parts(root):
			if part.get_parent() != null:
				part.get_parent().remove_child(part)
			part.free()
		_strip_lights(root)
	else:
		for part in LandmarkBuilder.parts(root):
			part.set_meta("lod_layer", "Landmarks")
			part.set_meta("lod_near_landmark", true)
	var parent: Node3D = root.get_node_or_null("Model") as Node3D
	if parent != null:
		# `bake` measured vertices in `root` space (already scaled by Model.scale),
		# so undo Model.scale on the child or attach directly under `root`.
		parent = root
	else:
		parent = root
	parent.add_child(imp)
	root.set_meta("lod_impostor", true)
	root.set_meta("impostor_only", strip)
	root.set_meta("lod_r0", R_IMPOSTOR_M)
	root.set_meta("far_r0", far_r0)
	return "stripped" if strip else "paired"

static func _strip_lights(n: Node) -> void:
	for c in n.get_children():
		if c is Light3D:
			n.remove_child(c)
			c.free()
		else:
			_strip_lights(c)

## Re-binds baked CPU `Image` metadata onto `ImageTexture`s after a
## `PackedScene` load when the active renderer dropped GPU texels (headless).
static func restore_cached(world: Node) -> void:
	if world == null:
		return
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and bool(n.get_meta("lod_impostor", false)):
			var mesh := (n as MeshInstance3D).mesh
			if mesh != null:
				for s in mesh.get_surface_count():
					var mat := mesh.surface_get_material(s) as StandardMaterial3D
					if mat == null or mat.albedo_texture == null:
						continue
					var tex := mat.albedo_texture
					var probe := tex.get_image()
					if (probe == null or probe.is_empty()) and tex.has_meta("impostor_image"):
						var img := tex.get_meta("impostor_image") as Image
						if img != null and not img.is_empty():
							var gpu_img := img.duplicate() as Image
							gpu_img.generate_mipmaps()
							FoliageTextures.preserve_coverage(gpu_img, ALPHA_CUT)
							var fresh := ImageTexture.create_from_image(gpu_img)
							fresh.set_meta("view", int(tex.get_meta("view", 0)))
							fresh.set_meta("impostor_image", img)
							mat.albedo_texture = fresh
		stack.append_array(n.get_children())

## CPU bake of `root` in landmark-local space (independent of `root.transform`).
## Returns `{ok, textures: [Image x 4], mask: Image, mesh: ArrayMesh, height, size}`.
static func bake(root: Node3D, _yaw_deg: float = 0.0) -> Dictionary:
	if _fail_bake_test:
		return {"ok": false, "note": "impostor bake failed: forced test failure"}
	if root == null:
		return {"ok": false, "note": "impostor bake failed: null root"}
	var batches := _extract_surfaces(root)
	if batches.is_empty():
		return {"ok": false, "note": "impostor bake failed: no triangle surfaces"}
	var bmin := Vector3(INF, INF, INF)
	var bmax := Vector3(-INF, -INF, -INF)
	for b in batches:
		bmin = bmin.min(b["min"])
		bmax = bmax.max(b["max"])
	var size3 := bmax - bmin
	if size3.y <= 0.05 or (size3.x <= 0.05 and size3.z <= 0.05):
		return {"ok": false, "note": "impostor bake failed: degenerate bounds"}
	var center := (bmin + bmax) * 0.5
	var pad := 1.03
	var wx := maxf(size3.x, 2.0) * pad
	var wz := maxf(size3.z, 2.0) * pad
	var span_y := maxf(size3.y, 2.0) * pad
	var y_mid := (bmin.y + bmax.y) * 0.5
	var y0 := y_mid - span_y * 0.5
	var y1 := y_mid + span_y * 0.5

	# Cardinal views in landmark-local space:
	#   0 North: outward normal (0, 0, -1), viewer right (-1, 0,  0), width wx
	#   1 East:  outward normal (1, 0,  0), viewer right ( 0, 0, -1), width wz
	#   2 South: outward normal (0, 0,  1), viewer right ( 1, 0,  0), width wx
	#   3 West:  outward normal (-1,0,  0), viewer right ( 0, 0,  1), width wz
	var normals: Array[Vector3] = [
		Vector3(0.0, 0.0, -1.0), Vector3(1.0, 0.0, 0.0),
		Vector3(0.0, 0.0, 1.0), Vector3(-1.0, 0.0, 0.0)]
	var rights: Array[Vector3] = [
		Vector3(-1.0, 0.0, 0.0), Vector3(0.0, 0.0, -1.0),
		Vector3(1.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0)]
	var widths: Array[float] = [wx, wz, wx, wz]

	var images: Array[Image] = []
	var texs: Array[ImageTexture] = []
	var key_dir := RELIEF_KEY.normalized()
	var headless := DisplayServer.get_name() == "headless"
	for v_idx in 4:
		var bytes := _rasterize_view(batches, center, y1, span_y,
			normals[v_idx], rights[v_idx], widths[v_idx] * 0.5, key_dir)
		var base_img := Image.create_from_data(SIZE, SIZE, false, Image.FORMAT_RGBA8, bytes)
		images.append(base_img)
		var gpu_img := base_img.duplicate() as Image
		gpu_img.generate_mipmaps()
		FoliageTextures.preserve_coverage(gpu_img, ALPHA_CUT)
		var tex := ImageTexture.create_from_image(gpu_img)
		tex.set_meta("view", v_idx)
		# Only attach the CPU fallback image under the headless dummy renderer
		# (which drops GPU texels); real GPU .scn caches embed `tex` directly.
		if headless:
			tex.set_meta("impostor_image", base_img)
		texs.append(tex)

	var mask_bytes := PackedByteArray()
	mask_bytes.resize(SIZE * SIZE * 4)
	var front_bytes := images[0].get_data()
	for i in SIZE * SIZE:
		var a := front_bytes[i * 4 + 3]
		var o := i * 4
		mask_bytes[o] = a
		mask_bytes[o + 1] = a
		mask_bytes[o + 2] = a
		mask_bytes[o + 3] = a
	var mask := Image.create_from_data(SIZE, SIZE, false, Image.FORMAT_RGBA8, mask_bytes)
	var octa := _build_octahedron(Vector2(center.x, center.z), y0, y1, wx, wz, texs)
	return {
		"ok": true,
		"textures": images,
		"mask": mask,
		"mesh": octa,
		"height": size3.y,
		"size": Vector2(size3.x, size3.z),
	}

static func _extract_surfaces(root: Node3D) -> Array:
	var out: Array = []
	for mi in LandmarkBuilder.parts(root):
		if mi.mesh == null or bool(mi.get_meta("lod_impostor", false)):
			continue
		var xf := _transform_in_root(mi, root)
		var sc := MeshArrays.surface_count(mi.mesh)
		for s in sc:
			var arr := MeshArrays.surface(mi.mesh, s)
			if arr.size() <= Mesh.ARRAY_VERTEX or arr[Mesh.ARRAY_VERTEX] == null:
				continue
			var raw_v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			if raw_v.size() < 3:
				continue
			var tv: PackedVector3Array = xf * raw_v
			var tn := PackedVector3Array()
			if arr[Mesh.ARRAY_NORMAL] != null:
				tn = Transform3D(xf.basis, Vector3.ZERO) * (arr[Mesh.ARRAY_NORMAL] as PackedVector3Array)
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] \
				if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			if idx.is_empty() and tv.size() < 3:
				continue
			if not idx.is_empty() and idx.size() < 3:
				continue
			var mat := mi.material_override if mi.material_override != null \
				else mi.mesh.surface_get_material(s)
			var col_info := _surface_color(mat)
			var cols: PackedColorArray = arr[Mesh.ARRAY_COLOR] \
				if bool(col_info["use_vcol"]) and arr[Mesh.ARRAY_COLOR] != null \
				else PackedColorArray()
			var smin := tv[0]
			var smax := tv[0]
			for p in tv:
				smin = smin.min(p)
				smax = smax.max(p)
			out.append({
				"v": tv, "n": tn, "idx": idx,
				"color": col_info["color"], "cols": cols,
				"min": smin, "max": smax,
			})
	return out

static func _transform_in_root(node: Node3D, root: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cur: Node = node
	while cur != null and cur != root:
		if cur is Node3D:
			xf = (cur as Node3D).transform * xf
		cur = cur.get_parent()
	return xf

static func _surface_color(mat: Material) -> Dictionary:
	if mat is StandardMaterial3D:
		var sm := mat as StandardMaterial3D
		if sm.has_meta("landmark_hex"):
			return {"color": Color(str(sm.get_meta("landmark_hex"))),
				"use_vcol": sm.vertex_color_use_as_albedo}
		if sm.has_meta(LandmarkShader.META):
			var set_name := str(sm.get_meta(LandmarkShader.META))
			if MaterialLibrary.PBR_SETS.has(set_name):
				var mean: Color = (MaterialLibrary.PBR_SETS[set_name] as Dictionary)["mean"]
				var lin := sm.albedo_color.srgb_to_linear() * mean
				var srgb := Color(clampf(lin.r, 0.02, 1.0), clampf(lin.g, 0.02, 1.0),
					clampf(lin.b, 0.02, 1.0)).linear_to_srgb()
				return {"color": srgb, "use_vcol": sm.vertex_color_use_as_albedo}
		var c := sm.albedo_color
		if sm.albedo_texture != null and c.is_equal_approx(Color.WHITE):
			c = Color(0.68, 0.65, 0.60)
		return {"color": Color(clampf(c.r, 0.04, 0.96), clampf(c.g, 0.04, 0.96),
			clampf(c.b, 0.04, 0.96)), "use_vcol": sm.vertex_color_use_as_albedo}
	return {"color": Color(0.66, 0.63, 0.58), "use_vcol": false}

static func _rasterize_view(batches: Array, center: Vector3, y_top: float, span_y: float,
		out_normal: Vector3, right_axis: Vector3, half_w: float, key_dir: Vector3) -> PackedByteArray:
	var px := PackedByteArray()
	px.resize(SIZE * SIZE * 4)
	var zbuf := PackedFloat32Array()
	zbuf.resize(SIZE * SIZE)
	zbuf.fill(-INF)
	var inv_w := float(SIZE - 1) / maxf(2.0 * half_w, 1e-3)
	var inv_h := float(SIZE - 1) / maxf(span_y, 1e-3)

	for b in batches:
		var verts: PackedVector3Array = b["v"]
		var norms: PackedVector3Array = b["n"]
		var idx: PackedInt32Array = b["idx"]
		var base_col: Color = b["color"]
		var vcols: PackedColorArray = b["cols"]
		var has_n := norms.size() == verts.size()
		var has_vc := vcols.size() == verts.size()
		var count := idx.size() if not idx.is_empty() else verts.size()
		var use_idx := not idx.is_empty()
		var t := 0
		while t + 2 < count:
			var ia := idx[t] if use_idx else t
			var ib := idx[t + 1] if use_idx else t + 1
			var ic := idx[t + 2] if use_idx else t + 2
			t += 3
			var va := verts[ia]
			var vb := verts[ib]
			var vc := verts[ic]
			var da := va - center
			var db := vb - center
			var dc := vc - center
			var pa := Vector2((da.dot(right_axis) + half_w) * inv_w, (y_top - va.y) * inv_h)
			var pb := Vector2((db.dot(right_axis) + half_w) * inv_w, (y_top - vb.y) * inv_h)
			var pc := Vector2((dc.dot(right_axis) + half_w) * inv_w, (y_top - vc.y) * inv_h)
			var za := da.dot(out_normal)
			var zb := db.dot(out_normal)
			var zc := dc.dot(out_normal)

			var fn: Vector3
			if has_n:
				fn = (norms[ia] + norms[ib] + norms[ic]).normalized()
			else:
				fn = (vc - va).cross(vb - va).normalized()
			if fn.length_squared() < 1e-6:
				fn = out_normal
			var shade := 0.76 + 0.24 * maxf(fn.dot(key_dir), 0.0) + 0.06 * maxf(fn.y, 0.0)
			var c := base_col
			if has_vc:
				var vc_avg := (vcols[ia] + vcols[ib] + vcols[ic]) / 3.0
				c = Color(c.r * vc_avg.r, c.g * vc_avg.g, c.b * vc_avg.b)
			var cr := clampi(roundi(c.r * shade * 255.0), 1, 255)
			var cg := clampi(roundi(c.g * shade * 255.0), 1, 255)
			var cb := clampi(roundi(c.b * shade * 255.0), 1, 255)

			var min_x := maxi(int(floor(minf(pa.x, minf(pb.x, pc.x)))), 0)
			var max_x := mini(int(ceil(maxf(pa.x, maxf(pb.x, pc.x)))), SIZE - 1)
			var min_y := maxi(int(floor(minf(pa.y, minf(pb.y, pc.y)))), 0)
			var max_y := mini(int(ceil(maxf(pa.y, maxf(pb.y, pc.y)))), SIZE - 1)
			if min_x > max_x or min_y > max_y:
				continue

			var area := (pb - pa).cross(pc - pa)
			if absf(area) >= 0.02:
				var inv_area := 1.0 / area
				for y in range(min_y, max_y + 1):
					var py_f := float(y) + 0.5
					for x in range(min_x, max_x + 1):
						var p := Vector2(float(x) + 0.5, py_f)
						var w0 := (pc - pb).cross(p - pb) * inv_area
						var w1 := (pa - pc).cross(p - pc) * inv_area
						var w2 := 1.0 - w0 - w1
						if w0 < -1e-4 or w1 < -1e-4 or w2 < -1e-4:
							continue
						var z := za * w0 + zb * w1 + zc * w2
						var di := y * SIZE + x
						if z > zbuf[di]:
							zbuf[di] = z
							var o := di * 4
							px[o] = cr
							px[o + 1] = cg
							px[o + 2] = cb
							px[o + 3] = 255

			# Sub-pixel girders, cables and spires (< 1.6 px minor span):
			# conservative edge splat so lattice towers stay continuous.
			if minf(max_x - min_x, max_y - min_y) <= 1 or absf(area) < 0.75:
				_splat_segment(px, zbuf, pa, za, pb, zb, cr, cg, cb)
				_splat_segment(px, zbuf, pb, zb, pc, zc, cr, cg, cb)
				_splat_segment(px, zbuf, pc, zc, pa, za, cr, cg, cb)
	return px

static func _splat_segment(px: PackedByteArray, zbuf: PackedFloat32Array,
		a: Vector2, za: float, b: Vector2, zb: float, cr: int, cg: int, cb: int) -> void:
	var steps := mini(maxi(int(ceil(a.distance_to(b))), 1), SIZE * 2)
	for s in range(steps + 1):
		var t := float(s) / float(steps)
		var x := roundi(lerpf(a.x, b.x, t))
		var y := roundi(lerpf(a.y, b.y, t))
		if x < 0 or x >= SIZE or y < 0 or y >= SIZE:
			continue
		var z := lerpf(za, zb, t)
		var di := y * SIZE + x
		if z > zbuf[di]:
			zbuf[di] = z
			var o := di * 4
			px[o] = cr
			px[o + 1] = cg
			px[o + 2] = cb
			px[o + 3] = 255

## 8-face upright dihedral octahedron (8 surfaces, 2 wing quads per view
## `[0, 1, 1, 0, 2, 3, 3, 2]` around the compass so every face carries
## its cardinal view's `StandardMaterial3D` without coplanar crossings).
static func _build_octahedron(center_xz: Vector2, y0: float, y1: float,
		wx: float, wz: float, texs: Array[ImageTexture]) -> ArrayMesh:
	var mats: Array[StandardMaterial3D] = []
	for i in 4:
		var m := StandardMaterial3D.new()
		m.albedo_texture = texs[i]
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = ALPHA_CUT
		m.roughness = 0.92
		m.metallic = 0.0
		m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		mats.append(m)

	var cx := center_xz.x
	var cz := center_xz.y
	var hx := wx * 0.5
	var hz := wz * 0.5
	var bx := wx * BOW_FRAC
	var bz := wz * BOW_FRAC

	# Each entry: [left_xz, right_xz, view_idx, uv_u0, uv_u1, outward_normal_xz]
	# Ordered `[0, 1, 1, 0, 2, 3, 3, 2]` (8 wing faces around N/E/S/W).
	var wings := [
		[Vector2(cx + hx, cz), Vector2(cx, cz - bz), 0, 0.0, 0.5, Vector3(0.0, 0.2, -1.0)],
		[Vector2(cx + bx, cz), Vector2(cx, cz - hz), 1, 0.5, 1.0, Vector3(1.0, 0.2, 0.0)],
		[Vector2(cx, cz + hz), Vector2(cx + bx, cz), 1, 0.0, 0.5, Vector3(1.0, 0.2, 0.0)],
		[Vector2(cx, cz - bz), Vector2(cx - hx, cz), 0, 0.5, 1.0, Vector3(0.0, 0.2, -1.0)],
		[Vector2(cx - hx, cz), Vector2(cx, cz + bz), 2, 0.0, 0.5, Vector3(0.0, 0.2, 1.0)],
		[Vector2(cx - bx, cz), Vector2(cx, cz + hz), 3, 0.5, 1.0, Vector3(-1.0, 0.2, 0.0)],
		[Vector2(cx, cz - hz), Vector2(cx - bx, cz), 3, 0.0, 0.5, Vector3(-1.0, 0.2, 0.0)],
		[Vector2(cx, cz + bz), Vector2(cx + hx, cz), 2, 0.5, 1.0, Vector3(0.0, 0.2, 1.0)],
	]

	var mesh := ArrayMesh.new()
	for s in wings.size():
		var w: Array = wings[s]
		var l_xz: Vector2 = w[0]
		var r_xz: Vector2 = w[1]
		var v_idx: int = w[2]
		var u0: float = w[3]
		var u1: float = w[4]
		var nrm: Vector3 = (w[5] as Vector3).normalized()
		var tl := Vector3(l_xz.x, y1, l_xz.y)
		var tr := Vector3(r_xz.x, y1, r_xz.y)
		var bl := Vector3(l_xz.x, y0, l_xz.y)
		var br := Vector3(r_xz.x, y0, r_xz.y)
		var verts := PackedVector3Array([tl, tr, br, bl])
		var norms := PackedVector3Array([nrm, nrm, nrm, nrm])
		var uvs := PackedVector2Array([
			Vector2(u0, 0.0), Vector2(u1, 0.0),
			Vector2(u1, 1.0), Vector2(u0, 1.0)])
		# Godot front faces are clockwise: check `(c - a).cross(b - a).dot(nrm) > 0`.
		var idx: PackedInt32Array
		if (br - tl).cross(tr - tl).dot(nrm) >= 0.0:
			idx = PackedInt32Array([0, 1, 2, 0, 2, 3])
		else:
			idx = PackedInt32Array([0, 2, 1, 0, 3, 2])
		var arr: Array = []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = verts
		arr[Mesh.ARRAY_NORMAL] = norms
		arr[Mesh.ARRAY_TEX_UV] = uvs
		arr[Mesh.ARRAY_INDEX] = idx
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(s, mats[v_idx])
		MeshArrays.keep_surface(mesh, arr)
	return mesh
