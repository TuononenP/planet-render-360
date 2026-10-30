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

## Gives `m` its lit-pane map (off until apply()).
static func mark(m: StandardMaterial3D, emit: Variant) -> void:
	if not (emit is Texture2D):
		return
	m.emission_enabled = true
	m.emission = Color.WHITE
	m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	m.emission_texture = emit as Texture2D
	m.emission_energy_multiplier = 0.0
	m.set_meta(META, true)

## Night share (0 day .. 1 night) from the rig's sky state: rooms light
## up through dusk, before full darkness.
static func amount_for(night_amount: float, twilight: float) -> float:
	return clampf(night_amount * 1.15 + twilight * 0.35, 0.0, 1.0)

## Sets every marked material under `world` to `amount` of night light.
static func apply(world: Node, amount: float) -> void:
	if world == null:
		return
	var energy := NIGHT_ENERGY * amount
	var seen := {}
	var stack: Array[Node] = [world]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if not (n is MeshInstance3D):
			continue
		var mi := n as MeshInstance3D
		var mats: Array = [mi.material_override]
		for s in (mi.mesh.get_surface_count() if mi.mesh != null else 0):
			mats.append(mi.mesh.surface_get_material(s))
		for m in mats:
			if m is StandardMaterial3D and not seen.has(m) and (m as Material).has_meta(META):
				seen[m] = true
				(m as StandardMaterial3D).emission_energy_multiplier = energy
