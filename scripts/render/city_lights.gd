class_name CityLights
extends RefCounted

## Lit rooms at dusk and night. Facade materials carry an emission map of
## their lit panes (FacadePaint) at zero energy by day; the view raises
## the energy as the sky darkens. Lit panes were orange paint before,
## so they also showed at noon and stayed dark at night.

## Emission energy of a lit pane in full night (HDR: above the glow
## threshold, so windows halo softly).
const NIGHT_ENERGY := 2.6
const META := "city_lit"
## Scene clock (AtmosphereRig.set_time): the Ultra facade shader lights
## rooms by the hour (FacadeShader).
static var hour := 20.0

## Gives `m` its lit-pane map (off until apply()).
static func mark(m: StandardMaterial3D, emit: Variant) -> void:
	if not (emit is Texture2D):
		return
	m.emission_enabled = true
	m.emission = Color.WHITE
	m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	m.emission_texture = emit as Texture2D
	m.emission_energy_multiplier = 0.0
	m.set_meta(META, 1.0)

## Lets `m`'s own emission follow the night at `scale` × the pane energy
## (shop signs and other emissive colour, dark by day).
static func mark_glow(m: StandardMaterial3D, scale: float) -> void:
	m.emission_energy_multiplier = 0.0
	m.set_meta(META, scale)

## Night share (0 day .. 1 night) from the rig's sky state: rooms light
## up through dusk, before full darkness.
static func amount_for(night_amount: float, twilight: float) -> float:
	return clampf(night_amount * 1.15 + twilight * 0.35, 0.0, 1.0)

## Sets every marked material under `world` to `amount` of night light.
static func apply(world: Node, amount: float) -> void:
	if world == null:
		return
	StreetGlow.set_night(amount)
	var energy := NIGHT_ENERGY * amount
	var seen := {}
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is Light3D and n.has_meta(StreetLights.META):
			StreetLights.apply(n as Light3D, amount)
			continue
		var mesh: Mesh = null
		if n is MeshInstance3D:
			mesh = (n as MeshInstance3D).mesh
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
			mesh = (n as MultiMeshInstance3D).multimesh.mesh  # lampposts
		else:
			continue
		var mats: Array = [(n as GeometryInstance3D).material_override]
		for s in (mesh.get_surface_count() if mesh != null else 0):
			mats.append(mesh.surface_get_material(s))
			if n is MeshInstance3D:
				mats.append((n as MeshInstance3D).get_surface_override_material(s))  # LandmarkLights glow
		for m in mats:
			if not (m is Material) or seen.has(m) or not (m as Material).has_meta(META):
				continue
			seen[m] = true
			if m is StandardMaterial3D:
				(m as StandardMaterial3D).emission_energy_multiplier = energy * float(m.get_meta(META))
			elif m is ShaderMaterial:
				(m as ShaderMaterial).set_shader_parameter("night_energy", energy * float(m.get_meta(META)))
				(m as ShaderMaterial).set_shader_parameter("city_hour", hour)
