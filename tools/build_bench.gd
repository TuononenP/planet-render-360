extends SceneTree

## World-build bench + fingerprint (faster-build plan, Step 0).
##
##   snapshot: godot --headless --path . --script tools/build_bench.gd -- snapshot DIR
##     Runs the real GenerationPipeline (cache first) for each golden place
##     × preset and freezes its LocationData into DIR (images included), so
##     every later build, in any checkout, starts from the same input.
##   build:    godot --path . --script tools/build_bench.gd --position 4000,4000 -- build DIR OUT
##     Windowed (the dummy renderer keeps no mesh data). Builds each
##     snapshot serially on the main thread through View360.make_world and
##     writes one line per top-level world child (class, name, SHA-256 of
##     its whole subtree: transforms, metas, mesh arrays, MultiMesh
##     buffers, materials with texture bytes), plus the ground and a total.
##     Compare two OUT files with diff.
##   parallel: same as build, with WorldBuildGraph.force_serial off and
##     the build on a worker thread (the graph runs serially on main).
##
## Uses only APIs that predate the speed work, so it runs on the f022358
## baseline checkout too.

const PLACES := [
	{"key": "paris", "lat": 48.8566, "lon": 2.3522},
	{"key": "venice", "lat": 45.4375, "lon": 12.3358},
	{"key": "zermatt", "lat": 46.0207, "lon": 7.7491},
	{"key": "bigsur", "lat": 36.2704, "lon": -121.8081},
]

var _tex_memo := {}
var _mat_memo := {}
var _mesh_memo := {}

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "snapshot":
		await _snapshot(args[1])
	elif args.size() >= 3 and (args[0] == "build" or args[0] == "parallel"):
		await _build(args[1], args[2], args.slice(3), args[0] == "parallel")
	else:
		printerr("BENCH usage: -- snapshot DIR | -- build DIR OUT [key_preset ...]")
		quit(2)
		return
	quit(0)

# --- snapshot -------------------------------------------------------------

func _snapshot(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	var pipe := GenerationPipeline.new()
	root.add_child(pipe)
	await process_frame
	for place in PLACES:
		for preset in 4:
			var done := [null]
			var cb := func(d: LocationData) -> void: done[0] = d
			pipe.finished.connect(cb)
			pipe.run(float(place["lat"]), float(place["lon"]), "", preset)
			while done[0] == null:
				await process_frame
			pipe.finished.disconnect(cb)
			var f := FileAccess.open("%s/%s_p%d.snap" % [dir, place["key"], preset], FileAccess.WRITE)
			f.store_var(_encode_data(done[0] as LocationData))
			f.close()
			print("BENCH snapshot %s p%d buildings=%d roads=%d sat=%s" % [place["key"], preset,
				(done[0] as LocationData).buildings.size(), (done[0] as LocationData).roads.size(),
				str((done[0] as LocationData).satellite_image != null)])
	pipe.queue_free()

func _encode_data(d: LocationData) -> Dictionary:
	var out := {}
	for p in d.get_property_list():
		if int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			out[p["name"]] = _enc(d.get(p["name"]))
	return out

func _enc(v: Variant) -> Variant:
	if v is Image:
		var img := v as Image
		return {"__img": true, "w": img.get_width(), "h": img.get_height(),
			"mip": img.has_mipmaps(), "fmt": img.get_format(), "data": img.get_data()}
	if v is Texture2D:
		return {"__tex": _enc((v as Texture2D).get_image())}
	if v is Dictionary:
		var o := {}
		for k in v:
			o[k] = _enc(v[k])
		return o
	if v is Array:
		var a: Array = []
		for e in v:
			a.append(_enc(e))
		return a
	if v is Object:
		return null
	return v

func _decode_data(src: Dictionary) -> LocationData:
	var d := LocationData.new()
	var names := {}
	for p in d.get_property_list():
		names[p["name"]] = true
	for k in src:
		if names.has(k):
			d.set(k, _dec(src[k], d.get(k)))
	if d.satellite_image != null:
		d.satellite_texture = ImageTexture.create_from_image(d.satellite_image)
	return d

func _dec(v: Variant, like: Variant = null) -> Variant:
	if v is Dictionary:
		if v.has("__img"):
			return Image.create_from_data(v["w"], v["h"], v["mip"], v["fmt"], v["data"])
		if v.has("__tex"):
			return ImageTexture.create_from_image(_dec(v["__tex"]))
		var o := {}
		for k in v:
			o[k] = _dec(v[k])
		return o
	if v is Array:
		var a: Array = []
		for e in v:
			a.append(_dec(e))
		if like is Array and (like as Array).is_typed():
			var typed: Array = (like as Array).duplicate()
			typed.clear()
			typed.assign(a)
			return typed
		return a
	return v

# --- build + fingerprint --------------------------------------------------

func _build(dir: String, out_path: String, only: Array, parallel: bool) -> void:
	var graph: GDScript = null
	if parallel:
		graph = load("res://scripts/generation/world_build_graph.gd") as GDScript
		graph.set("force_serial", false)
	var lines := PackedStringArray()
	for place in PLACES:
		for preset in 4:
			var tag := "%s_p%d" % [place["key"], preset]
			if not only.is_empty() and not only.has(tag):
				continue
			var path := "%s/%s.snap" % [dir, tag]
			if not FileAccess.file_exists(path):
				printerr("BENCH missing snapshot ", path)
				continue
			var f := FileAccess.open(path, FileAccess.READ)
			var data := _decode_data(f.get_var())
			f.close()
			var t0 := Time.get_ticks_msec()
			var ground := GroundTruth.new(data)
			var t1 := Time.get_ticks_msec()
			var world: Node3D = null
			if parallel:
				var th := Thread.new()
				th.start(func() -> Node3D: return View360.make_world(data, ground, null))
				while th.is_alive():
					await process_frame
				world = th.wait_to_finish()
			else:
				world = View360.make_world(data, ground, null)
			var t2 := Time.get_ticks_msec()
			if world == null or world.get_child_count() == 0:
				lines.append("%s FAIL empty world" % tag)
				continue
			var total := HashingContext.new()
			total.start(HashingContext.HASH_SHA256)
			var gh := _ground_hash(ground)
			lines.append("%s ground %s" % [tag, gh])
			total.update(gh.to_utf8_buffer())
			var dump := OS.get_environment("BENCH_DUMP")
			var i := 0
			for c in world.get_children():
				if dump != "" and str(c.name) == dump:
					_dump(c)
				var h := _node_hash(c)
				var nm := "" if str(c.name).begins_with("@") else str(c.name)
				lines.append("%s %03d %s %s %s" % [tag, i, c.get_class(), nm, h])
				total.update(h.to_utf8_buffer())
				i += 1
			var th := total.finish().hex_encode()
			lines.append("%s TOTAL children=%d %s" % [tag, i, th])
			print("BENCH %s ground=%d ms world=%d ms children=%d total=%s" % [tag,
				t1 - t0, t2 - t1, i, th.substr(0, 16)])
			world.free()
			_mesh_memo.clear()
	var o := FileAccess.open(out_path, FileAccess.WRITE)
	o.store_string("\n".join(lines) + "\n")
	o.close()
	print("BENCH wrote %d lines to %s" % [lines.size(), out_path])

func _ground_hash(g: GroundTruth) -> String:
	var hc := HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	for k in WorldCache.GROUND_FIELDS:
		hc.update(var_to_bytes(g.get(k)))
	return hc.finish().hex_encode()

func _node_hash(n: Node) -> String:
	var hc := HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	_hash_node(n, hc)
	return hc.finish().hex_encode()

func _hash_node(n: Node, hc: HashingContext) -> void:
	var nm := "" if str(n.name).begins_with("@") else str(n.name)
	hc.update(("N|%s|%s|%d" % [n.get_class(), nm, n.get_child_count()]).to_utf8_buffer())
	var metas := n.get_meta_list()
	metas.sort()
	for m in metas:
		hc.update(("M|%s|%s" % [m, var_to_str(n.get_meta(m))]).to_utf8_buffer())
	if n is Node3D:
		hc.update(var_to_bytes((n as Node3D).transform))
		hc.update(var_to_bytes((n as Node3D).visible))
	if n is GeometryInstance3D:
		var gi := n as GeometryInstance3D
		hc.update(var_to_bytes([gi.cast_shadow, gi.visibility_range_begin,
			gi.visibility_range_end, gi.visibility_range_begin_margin,
			gi.visibility_range_end_margin, gi.visibility_range_fade_mode,
			gi.transparency, gi.gi_mode]))
		hc.update(_mat_hash(gi.material_override).to_utf8_buffer())
		hc.update(_mat_hash(gi.material_overlay).to_utf8_buffer())
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		hc.update(_mesh_hash(mi.mesh).to_utf8_buffer())
		if mi.mesh != null:
			for s in mi.mesh.get_surface_count():
				hc.update(_mat_hash(mi.get_surface_override_material(s)).to_utf8_buffer())
	if n is MultiMeshInstance3D:
		var mm := (n as MultiMeshInstance3D).multimesh
		if mm != null:
			hc.update(var_to_bytes([mm.transform_format, mm.use_colors,
				mm.use_custom_data, mm.instance_count, mm.visible_instance_count]))
			hc.update(mm.buffer.to_byte_array())
			hc.update(_mesh_hash(mm.mesh).to_utf8_buffer())
	for c in n.get_children():
		_hash_node(c, hc)

func _mesh_hash(m: Mesh) -> String:
	if m == null:
		return "-"
	var id := m.get_instance_id()
	if _mesh_memo.has(id):
		return _mesh_memo[id]
	var hc := HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(m.get_class().to_utf8_buffer())
	if m is ArrayMesh:
		for s in m.get_surface_count():
			hc.update(var_to_bytes((m as ArrayMesh).surface_get_primitive_type(s)))
			for a in m.surface_get_arrays(s):
				hc.update(var_to_bytes(a))
			hc.update(_mat_hash(m.surface_get_material(s)).to_utf8_buffer())
	else:
		hc.update(_props_bytes(m))
	var h := hc.finish().hex_encode()
	_mesh_memo[id] = h
	return h

func _mat_hash(r: Resource) -> String:
	if r == null:
		return "-"
	var id := r.get_instance_id()
	if _mat_memo.has(id):
		return _mat_memo[id]
	var hc := HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(r.get_class().to_utf8_buffer())
	if r is Shader:
		hc.update((r as Shader).code.to_utf8_buffer())
	elif r is Texture:
		hc.update(_tex_hash(r as Texture).to_utf8_buffer())
	else:
		hc.update(_props_bytes(r))
	var h := hc.finish().hex_encode()
	_mat_memo[id] = h
	return h

func _props_bytes(r: Object) -> PackedByteArray:
	var out := PackedByteArray()
	for p in r.get_property_list():
		var nm: String = p["name"]
		if not (int(p["usage"]) & PROPERTY_USAGE_STORAGE) or nm.begins_with("resource_") \
				or nm == "script":
			continue
		var v: Variant = r.get(nm)
		out.append_array(nm.to_utf8_buffer())
		if v is Resource:
			out.append_array(_mat_hash(v as Resource).to_utf8_buffer())
		elif v is Array:
			for e in v:
				out.append_array(_mat_hash(e).to_utf8_buffer() if e is Resource else var_to_bytes(e))
		else:
			out.append_array(var_to_bytes(v))
	return out

func _tex_hash(t: Texture) -> String:
	var id := t.get_instance_id()
	if _tex_memo.has(id):
		return _tex_memo[id]
	var hc := HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	if t is Texture2D:
		var img := (t as Texture2D).get_image()
		if img != null:
			hc.update(var_to_bytes([img.get_width(), img.get_height(), img.get_format(),
				img.has_mipmaps()]))
			hc.update(img.get_data())
	elif t is TextureLayered:
		var tl := t as TextureLayered
		for i in tl.get_layers():
			var img := tl.get_layer_data(i)
			if img != null:
				hc.update(img.get_data())
	else:
		hc.update(t.get_class().to_utf8_buffer())
	var h := hc.finish().hex_encode()
	_tex_memo[id] = h
	return h

## BENCH_DUMP=<child name>: prints that child's materials, property by property.
func _dump(n: Node) -> void:
	var mats: Array = []
	if n is GeometryInstance3D:
		mats.append((n as GeometryInstance3D).material_override)
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var m := (n as MeshInstance3D).mesh
		print("DUMP %s surfaces=%d aabb=%s" % [n.name, m.get_surface_count(), m.get_aabb()])
		for s in m.get_surface_count():
			mats.append(m.surface_get_material(s))
	for mat in mats:
		if mat == null:
			continue
		for p in (mat as Object).get_property_list():
			if int(p["usage"]) & PROPERTY_USAGE_STORAGE:
				var v: Variant = mat.get(p["name"])
				print("DUMP  %s = %s" % [p["name"], _tex_hash(v).substr(0, 12) if v is Texture else str(v)])
