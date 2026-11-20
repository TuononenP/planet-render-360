class_name StockholmGlare
extends RefCounted

## Stockholm's low golden sun lit every polished or grazing surface to white: quay and cliff granite, the
## shore apron, and the curtain glass of the Kulturhuset. The road, paving and ground shaders carry their
## own cap (RoadSurface.STOCKHOLM_GLARE); this is the same cap for the materials built elsewhere (the quay,
## outcrop, apron and landmark builders), applied once to the finished world so none of those classes has
## to know. Stockholm only: every other place returns before touching a node.

## Dry stone: (specular cap, roughness floor). The floor keeps the wet waterline course glossier than dry stone.
const STONE := Vector2(0.15, 0.55)
## Curtain glass: metallic, specular, roughness floor, and the share its albedo keeps (the Kulturhuset's
## bright sky band was the albedo of the white block).
const GLASS := Vector3(0.1, 0.12, 0.5)
const GLASS_KEEP := 0.65
## Marks that a material belongs to the facade and roof pipelines (their tints, snow and shader swaps key on
## the exact instance): never replaced here.
const SKIP_META := ["wall", "roof", "facade_set", "roof_set", "glass_cap"]

## Caps the stone and glass materials under `root`, returning how many surfaces took a capped copy. A copy
## is shared per source material and set as the instance's override, so cached materials other places
## reuse are never changed.
static func apply(root: Node, data: LocationData) -> int:
	if root == null or not ShoreApron.stockholm(data):
		return 0
	var t0 := Time.get_ticks_usec()
	var copies := {}
	var count := 0
	var visited := 0
	var stack: Array = [root]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		stack.append_array(nd.get_children())
		if not (nd is MeshInstance3D):
			continue
		var mi := nd as MeshInstance3D
		visited += 1
		if mi.material_override != null:
			var over := capped(mi.material_override, copies)
			if over != mi.material_override:
				mi.material_override = over
				count += 1
			continue
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var cur: Material = mi.get_surface_override_material(s)
			if cur == null:
				cur = mi.mesh.surface_get_material(s)
			var cap := capped(cur, copies)
			if cap != cur:
				mi.set_surface_override_material(s, cap)
				count += 1
	print("STOCKHOLM GLARE %d surfaces capped on %d mesh instances in %.1f ms" % [count, visited, float(Time.get_ticks_usec() - t0) / 1000.0])
	return count

## `m`, or its capped copy when it is a stone or glass material that sheens (`copies` memoises per source).
static func capped(m: Material, copies: Dictionary) -> Material:
	if m == null:
		return m
	if copies.has(m):
		return copies[m]
	var out: Material = m
	if m is StandardMaterial3D:
		out = _standard(m as StandardMaterial3D)
	elif m is ShaderMaterial and m.has_meta(LandmarkShader.META):
		var sm := m as ShaderMaterial
		if sm.shader != null and sm.shader.code.contains("uniform vec2 glare") and float(sm.get_shader_parameter("metallic")) <= 0.1 \
				and sm.get_shader_parameter("glare") != STONE:
			var d := sm.duplicate() as ShaderMaterial
			d.set_shader_parameter("glare", STONE)
			out = d
	copies[m] = out
	return out

static func _standard(m: StandardMaterial3D) -> Material:
	for k in SKIP_META:
		if m.has_meta(k):
			return m
	if m.emission_enabled or m.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		return m
	if m.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		# Glass: reflective, clear.
		if m.metallic > 0.05 and m.roughness < 0.2 and m.roughness_texture == null:
			var g := m.duplicate() as StandardMaterial3D
			g.metallic = minf(g.metallic, GLASS.x)
			g.metallic_specular = minf(g.metallic_specular, GLASS.y)
			g.roughness = maxf(g.roughness, GLASS.z)
			g.albedo_color = Color(g.albedo_color.r * GLASS_KEEP, g.albedo_color.g * GLASS_KEEP,
				g.albedo_color.b * GLASS_KEEP, g.albedo_color.a)
			return g
		return m
	if m.metallic > 0.05 or m.albedo_texture == null:
		return m
	# Dry stone: a textured dielectric. Mirror-like scalar roughness (water, paint) stays.
	var floor_it := m.roughness_texture == null and m.roughness >= 0.3 and m.roughness < STONE.y
	if m.metallic_specular <= STONE.x + 0.01 and not floor_it:
		return m
	var c := m.duplicate() as StandardMaterial3D
	c.metallic_specular = minf(c.metallic_specular, STONE.x)
	if floor_it:
		c.roughness = STONE.y
	return c
