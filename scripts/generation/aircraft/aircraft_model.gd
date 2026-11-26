class_name AircraftModel
extends RefCounted

## Loads and caches the true-scale Blender-exported aircraft and helicopter
## GLBs (`res://assets/aircraft/<kind>.glb`) via `GLTFDocument`, applies
## regional airline or EMS livery material overrides, wires `CityLights` night
## cabin/nav/landing lights, and builds feathered ground contact shadows.

const ASSET_DIR := "res://assets/aircraft/"

static var _glb_cache: Dictionary = {}   # kind -> {part_name -> {surfaces: [{arrays, mat_name}], offset: Vector3}}
static var _mesh_cache: Dictionary = {}  # key -> ArrayMesh
static var _mat_cache: Dictionary = {}   # key -> Material
static var _shadow_cache: Dictionary = {}
static var _disc_mesh: ArrayMesh
static var _prop_disc_meshes: Dictionary = {}
static var _cabin_texs: Dictionary = {}
static var _mutex := Mutex.new()

## Instantiates a ready-to-place aircraft Node3D in true metres (+X nose,
## +Y up, +Z right wing, wheels/skids on y = 0). When `active` is true,
## landing lights glow brighter at night and helicopters/props include
## translucent spinning rotor/propeller blur discs.
static func instantiate(kind: String, livery: Dictionary, active: bool = false,
		with_shadow: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = "Aircraft_" + kind
	var parts := _load_glb(kind)
	if parts.is_empty():
		return root
	for part_name: String in parts:
		var pinfo: Dictionary = parts[part_name]
		var mesh := _build_part_mesh(kind, part_name, pinfo["surfaces"], livery, active)
		if mesh == null:
			continue
		var mi := MeshInstance3D.new()
		mi.name = part_name
		mi.mesh = mesh
		mi.position = pinfo["offset"]
		root.add_child(mi)
	if kind == "helicopter" and active and parts.has("MainRotor"):
		var disc := MeshInstance3D.new()
		disc.name = "RotorDisc"
		disc.mesh = _rotor_disc_mesh()
		disc.position = (parts["MainRotor"] as Dictionary)["offset"]
		disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		disc.visible = false
		root.add_child(disc)
	if active:
		for prop_name: String in ["PropLeft", "PropRight", "PropMain"]:
			if parts.has(prop_name):
				var pdisc := MeshInstance3D.new()
				pdisc.name = prop_name.replace("Prop", "PropDisc")
				var r := 0.94 if prop_name == "PropMain" else 1.95
				pdisc.mesh = _prop_disc_mesh(r)
				pdisc.position = (parts[prop_name] as Dictionary)["offset"]
				pdisc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				root.add_child(pdisc)
	if with_shadow:
		var sh := MeshInstance3D.new()
		sh.name = "Shadow"
		sh.mesh = shadow_mesh(kind)
		sh.position = Vector3(0.0, 0.06, 0.0)
		sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(sh)
	return root

## Merges the upgraded GLB geometry into a `LandmarkMesh` (used by
## `LandmarkAircraft` on the 14 hand-built capital airports). All aircraft
## material keys begin with "Ac" so `LandmarkAirfieldKit.conform()` drapes
## every aircraft surface together without detaching cockpit/cabin glass.
static func merge_into_landmark(lm: LandmarkMesh, kind: String, tail_hex: String,
		xform: Transform3D) -> bool:
	var parts := _load_glb(kind)
	if parts.is_empty():
		return false
	var tail_key := "AcTail" + tail_hex.trim_prefix("#")
	lm.use(tail_key, LandmarkMaterials.paint(tail_hex, 0.30, 0.14))
	lm.use("AcBelly", LandmarkMaterials.paint("#CFD5DC", 0.36, 0.26))
	lm.use("AcEngine", LandmarkMaterials.paint("#EAECEF", 0.28, 0.32))
	lm.use("AcDark", LandmarkMaterials.paint("#1E2024", 0.50, 0.65))
	lm.use("AcChrome", LandmarkMaterials.paint("#D2D7DC", 0.18, 0.88))
	lm.use("AcStrut", LandmarkMaterials.paint("#BCC2C8", 0.40, 0.40))
	lm.use("AcTire", LandmarkMaterials.paint("#1C1E22", 0.86, 0.04))
	lm.use("AcGlass", LandmarkMaterials.glass("#142230"))
	lm.use("AcCabinGlass", _slot_material("CabinGlass", {"id": "lm"}, false))
	for part_name: String in parts:
		var pinfo: Dictionary = parts[part_name]
		var pxf := xform * Transform3D(Basis.IDENTITY, pinfo["offset"])
		var rot := pxf.basis.orthonormalized()
		for surf: Dictionary in pinfo["surfaces"]:
			var mkey := _landmark_mat_key(str(surf["mat_name"]), tail_key)
			var arr: Array = surf["arrays"]
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
			var uvs: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var count := idx.size() if not idx.is_empty() else verts.size()
			for i in range(0, count - 2, 3):
				var i0 := idx[i] if not idx.is_empty() else i
				var i1 := idx[i + 1] if not idx.is_empty() else i + 1
				var i2 := idx[i + 2] if not idx.is_empty() else i + 2
				var v0 := pxf * verts[i0]
				var v1 := pxf * verts[i1]
				var v2 := pxf * verts[i2]
				var n0 := (rot * norms[i0]).normalized() if i0 < norms.size() else Vector3.UP
				var n1 := (rot * norms[i1]).normalized() if i1 < norms.size() else Vector3.UP
				var n2 := (rot * norms[i2]).normalized() if i2 < norms.size() else Vector3.UP
				var uv0 := uvs[i0] if i0 < uvs.size() else Vector2.ZERO
				var uv1 := uvs[i1] if i1 < uvs.size() else Vector2.ZERO
				var uv2 := uvs[i2] if i2 < uvs.size() else Vector2.ZERO
				lm.tri(mkey, v0, v1, v2, n0, n1, n2, uv0, uv1, uv2)
	return true

static func _landmark_mat_key(slot: String, tail_key: String) -> String:
	match slot:
		"Tail", "Accent":
			return tail_key
		"Belly":
			return "AcBelly"
		"Engine":
			return "AcEngine"
		"EngineDark", "PropBlade":
			return "AcDark"
		"Chrome":
			return "AcChrome"
		"Strut":
			return "AcStrut"
		"Tire":
			return "AcTire"
		"Glass":
			return "AcGlass"
		"CabinGlass":
			return "AcCabinGlass"
		"Gear":
			return "AcGear"
		_:
			return "AcBody"

## Feathered dark contact shadow quad under the aircraft footprint.
static func shadow_mesh(kind: String) -> ArrayMesh:
	_mutex.lock()
	if _shadow_cache.has(kind):
		var hit: ArrayMesh = _shadow_cache[kind]
		_mutex.unlock()
		return hit
	_mutex.unlock()

	var sp := AircraftSpecs.spec(kind)
	var hl := float(sp["shadow_l"]) * 0.5
	var hw := float(sp["shadow_w"]) * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(Vector3(-hl, 0.0, -hw))
	st.set_uv(Vector2(1.0, 0.0)); st.add_vertex(Vector3( hl, 0.0, -hw))
	st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(Vector3( hl, 0.0,  hw))
	st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(Vector3(-hl, 0.0, -hw))
	st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(Vector3( hl, 0.0,  hw))
	st.set_uv(Vector2(0.0, 1.0)); st.add_vertex(Vector3(-hl, 0.0,  hw))
	var mesh := st.commit()
	mesh.surface_set_material(0, _shadow_material())

	_mutex.lock()
	_shadow_cache[kind] = mesh
	_mutex.unlock()
	return mesh

static func _shadow_material() -> StandardMaterial3D:
	_mutex.lock()
	if _mat_cache.has("__shadow"):
		var hit: StandardMaterial3D = _mat_cache["__shadow"]
		_mutex.unlock()
		return hit
	_mutex.unlock()

	var sz := 64
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	for y in sz:
		var ny := (float(y) / float(sz - 1)) * 2.0 - 1.0
		for x in sz:
			var nx := (float(x) / float(sz - 1)) * 2.0 - 1.0
			# Cross-shaped soft shadow: fuselage along X + wings along Z
			var fuse := exp(-pow(nx / 0.85, 2.0) - pow(ny / 0.18, 2.0))
			var wing := exp(-pow((nx + 0.05) / 0.24, 2.0) - pow(ny / 0.88, 2.0))
			var alpha := clampf(maxf(fuse, wing * 0.72) * 0.44, 0.0, 0.48)
			img.set_pixel(x, y, Color(0.04, 0.05, 0.06, alpha))
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mutex.lock()
	_mat_cache["__shadow"] = mat
	_mutex.unlock()
	return mat

static func _rotor_disc_mesh() -> ArrayMesh:
	_mutex.lock()
	if _disc_mesh != null:
		var hit := _disc_mesh
		_mutex.unlock()
		return hit
	_mutex.unlock()

	var r := 5.15
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(Vector3(-r, 0.0, -r))
	st.set_uv(Vector2(1.0, 0.0)); st.add_vertex(Vector3( r, 0.0, -r))
	st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(Vector3( r, 0.0,  r))
	st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(Vector3(-r, 0.0, -r))
	st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(Vector3( r, 0.0,  r))
	st.set_uv(Vector2(0.0, 1.0)); st.add_vertex(Vector3(-r, 0.0,  r))
	var mesh := st.commit()
	mesh.surface_set_material(0, _blur_disc_material(true))

	_mutex.lock()
	_disc_mesh = mesh
	_mutex.unlock()
	return mesh

static func _prop_disc_mesh(r: float) -> ArrayMesh:
	var key := "%.2f" % r
	_mutex.lock()
	if _prop_disc_meshes.has(key):
		var hit: ArrayMesh = _prop_disc_meshes[key]
		_mutex.unlock()
		return hit
	_mutex.unlock()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.RIGHT)
	st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(Vector3(0.0, -r, -r))
	st.set_uv(Vector2(1.0, 0.0)); st.add_vertex(Vector3(0.0, -r,  r))
	st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(Vector3(0.0,  r,  r))
	st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(Vector3(0.0, -r, -r))
	st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(Vector3(0.0,  r,  r))
	st.set_uv(Vector2(0.0, 1.0)); st.add_vertex(Vector3(0.0,  r, -r))
	var mesh := st.commit()
	mesh.surface_set_material(0, _blur_disc_material(false))

	_mutex.lock()
	_prop_disc_meshes[key] = mesh
	_mutex.unlock()
	return mesh

static func _blur_disc_material(is_rotor: bool) -> StandardMaterial3D:
	var key := "__rotor_disc" if is_rotor else "__prop_disc"
	_mutex.lock()
	if _mat_cache.has(key):
		var hit: StandardMaterial3D = _mat_cache[key]
		_mutex.unlock()
		return hit
	_mutex.unlock()

	var sz := 128
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var lobes := 4.0 if is_rotor else 6.0
	for y in sz:
		var ny := (float(y) / float(sz - 1)) * 2.0 - 1.0
		for x in sz:
			var nx := (float(x) / float(sz - 1)) * 2.0 - 1.0
			var rr := sqrt(nx * nx + ny * ny)
			if rr > 1.0 or rr < 0.09:
				img.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
				continue
			var ang := atan2(ny, nx)
			var streak := 0.72 + 0.28 * pow(0.5 + 0.5 * cos(ang * lobes), 2.0)
			var edge := smoothstep(1.0, 0.88, rr) * smoothstep(0.09, 0.16, rr)
			var tip_ring := exp(-pow((rr - 0.92) / 0.045, 2.0))
			var base_a := (0.24 if is_rotor else 0.20) * (1.0 - 0.35 * rr) * streak
			var a := clampf((base_a + tip_ring * 0.16) * edge, 0.0, 0.42)
			var col := Color(0.14, 0.16, 0.18).lerp(Color(0.88, 0.78, 0.22), tip_ring * 0.65)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_mutex.lock()
	_mat_cache[key] = mat
	_mutex.unlock()
	return mat

static func _load_glb(kind: String) -> Dictionary:
	_mutex.lock()
	if _glb_cache.has(kind):
		var hit: Dictionary = _glb_cache[kind]
		_mutex.unlock()
		return hit
	_mutex.unlock()

	var path := ASSET_DIR + kind + ".glb"
	var out := {}
	if FileAccess.file_exists(path):
		var bytes := FileAccess.get_file_as_bytes(path)
		if not bytes.is_empty():
			var doc := GLTFDocument.new()
			var state := GLTFState.new()
			if doc.append_from_buffer(bytes, "", state) == OK:
				var scene := doc.generate_scene(state)
				if scene != null:
					_extract_parts(scene, Transform3D.IDENTITY, out)
					scene.free()

	_mutex.lock()
	_glb_cache[kind] = out
	_mutex.unlock()
	return out

static func _extract_parts(node: Node, parent_xf: Transform3D, out: Dictionary) -> void:
	var xf := parent_xf
	if node is Node3D:
		xf = parent_xf * (node as Node3D).transform
	if node is MeshInstance3D:
		var mesh := (node as MeshInstance3D).mesh
		if mesh != null:
			var part_name := str(node.name)
			var keep_offset := part_name in ["MainRotor", "TailRotor", "PropLeft", "PropRight", "PropMain"]
			var offset := xf.origin if keep_offset else Vector3.ZERO
			var bake_xf := Transform3D(xf.basis, Vector3.ZERO) if keep_offset else xf
			var rot := bake_xf.basis.orthonormalized()
			var surfaces: Array = []
			for s in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(s)
				var mat := mesh.surface_get_material(s)
				var mname := str(mat.resource_name) if mat != null else "Body"
				var sv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var sn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
				var tv := PackedVector3Array()
				tv.resize(sv.size())
				for i in sv.size():
					tv[i] = bake_xf * sv[i]
				arr[Mesh.ARRAY_VERTEX] = tv
				if not sn.is_empty():
					var tn := PackedVector3Array()
					tn.resize(sn.size())
					for i in sn.size():
						tn[i] = (rot * sn[i]).normalized()
					arr[Mesh.ARRAY_NORMAL] = tn
				# Preserve Blender-exported CabinGlass UVs; only synthesize fallback if missing
				if mname == "CabinGlass":
					var existing_uv = arr[Mesh.ARRAY_TEX_UV]
					if existing_uv == null or (existing_uv as PackedVector2Array).is_empty():
						var uvs := PackedVector2Array()
						uvs.resize(tv.size())
						for i in tv.size():
							uvs[i] = Vector2(tv[i].x * 0.55, tv[i].y * 0.55)
						arr[Mesh.ARRAY_TEX_UV] = uvs
				surfaces.append({"arrays": arr, "mat_name": mname})
			out[part_name] = {"surfaces": surfaces, "offset": offset}
	for c in node.get_children():
		_extract_parts(c, xf, out)

static func _build_part_mesh(kind: String, part_name: String, surfaces: Array,
		livery: Dictionary, active: bool) -> ArrayMesh:
	var key := "%s|%s|%s|%d" % [kind, part_name, str(livery.get("id", "std")), int(active)]
	_mutex.lock()
	if _mesh_cache.has(key):
		var hit: ArrayMesh = _mesh_cache[key]
		_mutex.unlock()
		return hit
	_mutex.unlock()

	var mesh := ArrayMesh.new()
	for surf: Dictionary in surfaces:
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surf["arrays"])
		var mat := _slot_material(str(surf["mat_name"]), livery, active)
		mesh.surface_set_material(mesh.get_surface_count() - 1, mat)

	_mutex.lock()
	_mesh_cache[key] = mesh
	_mutex.unlock()
	return mesh

static func _slot_material(slot: String, livery: Dictionary, active: bool) -> StandardMaterial3D:
	var key := "%s|%s|%d" % [slot, str(livery.get("id", "std")), int(active)]
	_mutex.lock()
	if _mat_cache.has(key):
		var hit: StandardMaterial3D = _mat_cache[key]
		_mutex.unlock()
		return hit
	_mutex.unlock()

	var m := StandardMaterial3D.new()
	match slot:
		"Body":
			m.albedo_color = Color(str(livery.get("body", "#F3F5F7")))
			m.roughness = 0.30
			m.metallic = 0.14
		"Belly":
			m.albedo_color = Color(str(livery.get("belly", "#CFD5DC")))
			m.roughness = 0.36
			m.metallic = 0.25
		"Tail":
			m.albedo_color = Color(str(livery.get("tail", "#0B245B")))
			m.roughness = 0.32
			m.metallic = 0.12
		"Accent":
			m.albedo_color = Color(str(livery.get("accent", "#0B245B")))
			m.roughness = 0.32
			m.metallic = 0.12
		"Engine":
			m.albedo_color = Color(str(livery.get("engine", "#EAECEF")))
			m.roughness = 0.28
			m.metallic = 0.34
		"EngineDark":
			m.albedo_color = Color("#1A1C20")
			m.roughness = 0.50
			m.metallic = 0.68
		"Chrome":
			m.albedo_color = Color("#D6DBE0")
			m.roughness = 0.16
			m.metallic = 0.88
		"Strut":
			m.albedo_color = Color("#C2C8CE")
			m.roughness = 0.38
			m.metallic = 0.42
		"Tire":
			m.albedo_color = Color("#1B1D21")
			m.roughness = 0.88
			m.metallic = 0.03
		"PropBlade":
			m.albedo_color = Color("#202328")
			m.roughness = 0.42
			m.metallic = 0.24
		"Gear":
			m.albedo_color = Color("#24262A")
			m.roughness = 0.78
			m.metallic = 0.18
		"Glass":
			m.albedo_color = Color("#101B26")
			m.roughness = 0.06
			m.metallic = 0.35
		"CabinGlass":
			var texs := _cabin_window_textures()
			m.albedo_color = Color.WHITE
			m.albedo_texture = texs["albedo"]
			m.roughness = 0.16
			m.metallic = 0.18
			CityLights.mark(m, texs["emit"])
		"NavRed":
			m = _glow_lamp(Color(1.0, 0.10, 0.06), 3.2 if active else 1.4)
		"NavGreen":
			m = _glow_lamp(Color(0.10, 1.0, 0.35), 3.2 if active else 1.4)
		"NavWhite":
			m = _glow_lamp(Color(1.0, 0.98, 0.92), 3.6 if active else 1.6)
		"LandingLight":
			m = _glow_lamp(Color(1.0, 0.97, 0.88), 5.5 if active else 0.5)
		_:
			m.albedo_color = Color("#ECEFEF")
			m.roughness = 0.35

	_mutex.lock()
	_mat_cache[key] = m
	_mutex.unlock()
	return m

static func _glow_lamp(colour: Color, scale: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour.lerp(Color.WHITE, 0.30)
	m.roughness = 0.18
	m.emission_enabled = true
	m.emission = colour
	CityLights.mark_glow(m, scale)
	return m

static func _cabin_window_textures() -> Dictionary:
	_mutex.lock()
	if not _cabin_texs.is_empty():
		var hit := _cabin_texs
		_mutex.unlock()
		return hit
	_mutex.unlock()

	var w := 512
	var h := 64
	var alb := Image.create(w, h, false, Image.FORMAT_RGB8)
	var em := Image.create(w, h, false, Image.FORMAT_RGB8)
	var hull_col := Color("#F2F4F7")
	var frame_col := Color("#C5CCD4")
	alb.fill(hull_col)
	em.fill(Color.BLACK)
	# 16 crisp anti-aliased oval passenger windows along U with metallic frames
	var n_win := 16
	var cell := float(w) / float(n_win)
	for i in n_win:
		var cx := (float(i) + 0.5) * cell
		var cy := float(h) * 0.5
		var rx := cell * 0.24
		var ry := float(h) * 0.30
		var lit := ((i * 7 + 3) % 5) != 0
		var x0 := maxi(0, int(floor(cx - rx - 3.0)))
		var x1 := mini(w - 1, int(ceil(cx + rx + 3.0)))
		var y0 := maxi(0, int(floor(cy - ry - 3.0)))
		var y1 := mini(h - 1, int(ceil(cy + ry + 3.0)))
		for y in range(y0, y1 + 1):
			var dy := (float(y) - cy) / ry
			for x in range(x0, x1 + 1):
				var dx := (float(x) - cx) / rx
				# Superellipse (n=3.5) for authentic rounded-rectangle airliner windows
				var d := pow(absf(dx), 3.5) + pow(absf(dy), 3.5)
				if d <= 1.0:
					# Subtle top-to-bottom interior reflection gradient
					var shade := lerpf(0.75, 1.15, clampf((dy + 1.0) * 0.5, 0.0, 1.0))
					alb.set_pixel(x, y, Color(0.11 * shade, 0.16 * shade, 0.22 * shade))
					if lit:
						var glow := clampf(1.0 - d * 0.35, 0.45, 1.0)
						em.set_pixel(x, y, Color(1.0 * glow, 0.85 * glow, 0.60 * glow))
				elif d <= 1.42:
					var t := smoothstep(1.42, 1.0, d)
					alb.set_pixel(x, y, hull_col.lerp(frame_col, t))
	var out := {
		"albedo": ImageTexture.create_from_image(alb),
		"emit": ImageTexture.create_from_image(em),
	}
	_mutex.lock()
	_cabin_texs = out
	_mutex.unlock()
	return out
