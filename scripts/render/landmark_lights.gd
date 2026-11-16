class_name LandmarkLights
extends RefCounted

## Night floodlighting for the hand-made landmarks (desktop Ultra, Phase 8
## of the Ultra pass): real landmarks are lit at night, and an unlit
## Eiffel Tower or One WTC reads as a black cut-out. Two kinds:
## - lattice towers lit from inside (Eiffel Tower, Tokyo Tower) and
##   supertalls lit by their own façade LEDs (Burj Khalifa, One WTC):
##   their structure glows in its lamp colour, dark by day;
## - everything else: SPOTS ground-mounted spots around the base, aimed
##   up the faces, warm white, shadowless; a long landmark (a palace
##   front, a bridge) gets them spaced down both long sides instead, one
##   every SIDE_STEP_M, so its end towers are lit too. A model whose
##   box says nothing of where it stands (a curved bridge) places its own
##   spots instead (FLOOD_META on its Model node).
## Both follow the night through CityLights.apply (the spots carry
## StreetLights.META, the glow materials CityLights.META). Every hero's
## own lamps (its "Lamp" part: bridge necklaces, lanterns, beacons) go
## dark by day and a little brighter at night. The Eiffel Tower also
## sparkles: SPARKLES white flashes (each kept ~4 px wide at any
## distance) over the iron for the first
## SPARKLE_MIN minutes of every night hour, as the real one does.

const SPOTS := 4
## On a "Lamp" part's material: its emission energy at night, for a part
## built with none (lit cables, which must read plain white by day on
## presets that never dress the hero).
const NIGHT_GLOW_META := "night_glow"
## Model-node meta: [[lamp, aim, cone angle in degrees, energy share], ...]
## in model metres, replacing the spots placed round the bounds. An entry
## may add its own range (m) and light colour: a downlight over a deck
## reaches only the deck, a cool wash differs from the warm default; and
## then its cone falloff (spot_angle_attenuation, low = flat pool).
const FLOOD_META := "flood_spots"
## Model-node meta: [[centre, radius, colour], ...] in model metres: soft
## glows round a landmark's own beacons (aviation lights) at night, the
## halo a bright lamp throws in the night air, which bloom alone cannot.
const HALO_META := "beacon_halos"
## Smallest angular radius of a halo (rad), so a far beacon stays a glow.
const HALO_MIN_RAD := 0.006
const HALO_CODE := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform float night_energy = 0.0;
uniform vec3 colour : source_color = vec3(1.0, 0.05, 0.02);
uniform float quad_u = 1.0;
void vertex() {
	// Grow with distance so the halo never shrinks under HALO_MIN_RAD.
	float dist = length(INV_VIEW_MATRIX[3].xyz - MODEL_MATRIX[3].xyz);
	VERTEX *= max(1.0, dist * %f * 2.0 / quad_u);
	// Billboard: the quad faces the camera at the halo's centre.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
		INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	float r = length(UV - 0.5) * 2.0;
	// A bright core fading into a wide soft glow, zero at the quad's edge.
	float glow = (exp(-r * r * 18.0) * 1.6 + exp(-r * r * 4.0) * 0.35) * (1.0 - smoothstep(0.8, 1.0, r));
	ALBEDO = colour * glow * night_energy;
}
""" % HALO_MIN_RAD
## Footprints longer than ELONGATED × their width line their long sides.
const ELONGATED := 2.0
const SIDE_STEP_M := 45.0
const MAX_PER_SIDE := 10
## Long fronts take more, weaker spots that overlap into an even wash.
const SIDE_ENERGY := 0.75
## Spot energy at full night (Godot units, not physical).
const ENERGY := 7.0
const COLOUR := Color(1.0, 0.87, 0.68)
## Out from the footprint's edge to the lamp, and up off the ground (m).
const SETBACK_M := 10.0
const LAMP_Y_M := 1.0
## Self-lit towers: [lamp colour, CityLights glow scale].
## Night lamp energy against the part's own (always-on) energy.
const LAMP_GAIN := 1.4
const SPARKLES := 3000
const SPARKLE_MIN := 5.0
const SPARKLE_M := 0.9
const SPARKLE_CODE := """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform float night_energy = 0.0;
uniform float city_hour = 20.0;
varying float seed;
uniform float quad_u = 1.0;
void vertex() {
	seed = float(INSTANCE_ID);
	// Seen from across the city a 0.9 m flash is under a pixel: grow it
	// to stay ~4 px wide (0.004 rad) at any distance.
	float dist = length(INV_VIEW_MATRIX[3].xyz - MODEL_MATRIX[3].xyz);
	VERTEX *= max(1.0, dist * 0.004 / quad_u);
	// Billboard: the quad faces the camera at the instance's position.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
		INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	float minute = fract(city_hour) * 60.0;
	float on = step(minute, %f) * step(0.05, night_energy);
	float flash = step(0.7, fract(sin(seed * 12.9898 + floor(TIME * 9.0) * 78.233) * 43758.5453));
	float r = length(UV - 0.5) * 2.0;
	if (on * flash < 0.5 || r > 1.0) {
		discard;
	}
	ALBEDO = vec3(1.0);
	EMISSION = vec3(0.95, 0.97, 1.0) * 12.0 * (1.0 - r * r);
}
""" % SPARKLE_MIN
const GLOW := {
	"eiffel": [Color(1.0, 0.64, 0.26), 0.32],    # the sodium gold lamps
	"tokyo": [Color(1.0, 0.42, 0.14), 0.32],     # Landmark Light, orange
	# Supertalls ground spots cannot reach: their own façade LEDs.
	"burj_khalifa": [Color(0.78, 0.86, 1.0), 0.14],
	"one_wtc": [Color(0.82, 0.88, 1.0), 0.1],
}

## Dresses `hero` (LandmarkBuilder.build, before it is placed) for the
## night. Returns the number of spots added (0 for a glowing lattice).
static func dress(hero: Node3D, type: String) -> int:
	_night_lamps(hero)
	_halos(hero)
	if GLOW.has(type):
		_glow(hero, GLOW[type][0], float(GLOW[type][1]))
		if type == "eiffel":
			_sparkle(hero)
		return 0
	var box := local_aabb(hero)
	if box.size.y <= 0.0:
		return 0
	var m := WorldScale.metres_to_units()
	var c := box.get_center()
	var base_y := box.position.y + LAMP_Y_M * m
	var aim_y := box.position.y + box.size.y * 0.45
	# [lamp, aim point, half-width it must cover, energy share]
	var lamps: Array = []
	var long_x := box.size.x >= box.size.z
	var long_len := maxf(box.size.x, box.size.z)
	var short_half := minf(box.size.x, box.size.z) * 0.5
	var model := hero.get_node_or_null("Model") as Node3D
	if model != null and model.has_meta(FLOOD_META):
		for raw in model.get_meta(FLOOD_META):
			var own: Array = raw
			var lamp := [model.transform * (own[0] as Vector3), model.transform * (own[1] as Vector3), 0.0,
				float(own[3]), float(own[2])]
			if own.size() > 5:
				lamp.append_array([float(own[4]) * m, own[5] as Color])
			if own.size() > 6:
				lamp.append(float(own[6]))
			lamps.append(lamp)
	elif long_len > ELONGATED * short_half * 2.0:
		var along := Vector3.RIGHT if long_x else Vector3.BACK
		var across := Vector3.BACK if long_x else Vector3.RIGHT
		var per_side := clampi(int(ceil(long_len / (SIDE_STEP_M * m))), 2, MAX_PER_SIDE)
		var cover := long_len / float(per_side) * 0.5
		for k in per_side:
			var t := (float(k) + 0.5) / float(per_side) - 0.5
			for side in [-1.0, 1.0]:
				# Back from the face by the depth, so the wash spreads evenly.
				var face: Vector3 = Vector3(c.x, 0.0, c.z) + along * t * long_len + across * side * short_half
				var p: Vector3 = face + across * side * maxf(short_half, SETBACK_M * m)
				lamps.append([Vector3(p.x, base_y, p.z), Vector3(face.x, aim_y, face.z), cover, SIDE_ENERGY])
	else:
		var half := maxf(box.size.x, box.size.z) * 0.5
		var dist := half + SETBACK_M * m
		for k in SPOTS:
			var a := TAU * (float(k) + 0.5) / float(SPOTS)
			lamps.append([Vector3(c.x + cos(a) * dist, base_y, c.z + sin(a) * dist),
				Vector3(c.x, aim_y, c.z), half, 1.0])
	var holder := Node3D.new()
	holder.name = "LandmarkLights"
	for lamp in lamps:
		var p: Vector3 = lamp[0]
		var aim: Vector3 = lamp[1]
		var dist := Vector2(aim.x - p.x, aim.z - p.z).length()
		var spot := SpotLight3D.new()
		spot.spot_range = p.distance_to(Vector3(aim.x, box.end.y, aim.z)) * 1.15
		# Wide, soft-edged cones that overlap their neighbours: an even
		# wash, not a row of rings.
		spot.spot_angle = clampf(rad_to_deg(atan2(maxf(box.size.y * 0.55, float(lamp[2]) * 1.6), dist)), 25.0, 75.0)
		spot.light_color = COLOUR
		if (lamp as Array).size() > 4:
			spot.spot_angle = float(lamp[4])
		if (lamp as Array).size() > 6:
			spot.spot_range = float(lamp[5])
			spot.light_color = lamp[6] as Color
		spot.spot_angle_attenuation = float(lamp[7]) if (lamp as Array).size() > 7 else 2.5
		spot.spot_attenuation = 0.35
		spot.light_energy = 0.0
		spot.shadow_enabled = false
		spot.visible = false
		spot.set_meta(StreetLights.META, ENERGY * float(lamp[3]))
		holder.add_child(spot)
		# SpotLight3D shines down its -Z.
		spot.transform = Transform3D(Basis.looking_at(aim - p, Vector3.UP), p)
	hero.add_child(holder)
	return lamps.size()

## The lattice's own materials (glass aside) glow in `colour` at night.
static func _glow(hero: Node3D, colour: Color, scale: float) -> void:
	var done := {}
	for mi in LandmarkBuilder.parts(hero):
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s) as StandardMaterial3D
			if mat == null or mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED \
					or mi.get_surface_override_material(s) != null:
				continue
			if not done.has(mat):
				var lit := mat.duplicate() as StandardMaterial3D
				lit.emission_enabled = true
				lit.emission = colour
				CityLights.mark_glow(lit, scale)
				done[mat] = lit
			mi.set_surface_override_material(s, done[mat])

## The hero's own lamps follow the night instead of glowing by day.
static func _night_lamps(hero: Node3D) -> void:
	for mi in LandmarkBuilder.parts(hero):
		if mi.mesh == null or not str(mi.name).ends_with("Lamp"):
			continue
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s) as StandardMaterial3D
			if mat == null or not mat.emission_enabled:
				continue
			# A part that only glows at night (NIGHT_GLOW_META) is built
			# dark, so it stays dark by day where nothing follows the night.
			var energy := float(mat.get_meta(NIGHT_GLOW_META, mat.emission_energy_multiplier))
			var lamp := mat.duplicate() as StandardMaterial3D
			CityLights.mark_glow(lamp, energy * LAMP_GAIN / CityLights.NIGHT_ENERGY)
			mi.set_surface_override_material(s, lamp)

## Night halos round the model's beacons (HALO_META): one billboard each,
## additive, dark by day (CityLights drives night_energy).
static func _halos(hero: Node3D) -> void:
	var model := hero.get_node_or_null("Model") as Node3D
	if model == null or not model.has_meta(HALO_META):
		return
	var m := WorldScale.metres_to_units()
	var holder := Node3D.new()
	holder.name = "BeaconHalos"
	for raw in model.get_meta(HALO_META):
		var own: Array = raw
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * float(own[1]) * 2.0 * m
		var mat := ShaderMaterial.new()
		mat.shader = SharedShader.of(HALO_CODE)
		mat.set_meta(CityLights.META, 1.0)
		mat.set_shader_parameter("quad_u", quad.size.x)
		mat.set_shader_parameter("colour", own[2] as Color)
		quad.material = mat
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = model.transform * (own[0] as Vector3)
		holder.add_child(mi)
	hero.add_child(holder)

## SPARKLES flash points spread over the hero's structure (its mesh
## vertices, evenly strided), as one billboard MultiMesh.
static func _sparkle(hero: Node3D) -> void:
	var pts := PackedVector3Array()
	for mi in LandmarkBuilder.parts(hero):
		if mi.mesh == null or str(mi.name).ends_with("Lamp"):
			continue
		var xf := _local_xform(hero, mi)
		for s in mi.mesh.get_surface_count():
			var v: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for i in range(0, v.size(), maxi(1, v.size() / SPARKLES)):
				pts.append(xf * v[i])
	if pts.is_empty():
		return
	var step := maxi(1, pts.size() / SPARKLES)
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * SPARKLE_M * WorldScale.metres_to_units()
	var sh := SharedShader.of(SPARKLE_CODE)
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_meta(CityLights.META, 1.0)
	mat.set_shader_parameter("quad_u", quad.size.x)
	quad.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = quad
	mm.instance_count = pts.size() / step
	for k in mm.instance_count:
		mm.set_instance_transform(k, Transform3D(Basis(), pts[k * step]))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Sparkle"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hero.add_child(mmi)

static func _local_xform(hero: Node3D, mi: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var n: Node = mi
	while n != hero and n is Node3D:
		xf = (n as Node3D).transform * xf
		n = n.get_parent()
	return xf

## Bounds of `hero`'s meshes in its own frame.
static func local_aabb(hero: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for mi in LandmarkBuilder.parts(hero):
		if mi.mesh == null:
			continue
		var b := _local_xform(hero, mi) * mi.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out
