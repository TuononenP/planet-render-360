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
##   every SIDE_STEP_M, so its end towers are lit too.
## Both follow the night through CityLights.apply (the spots carry
## StreetLights.META, the glow materials CityLights.META). Every hero's
## own lamps (its "Lamp" part: bridge necklaces, lanterns, beacons) go
## dark by day and a little brighter at night. The Eiffel Tower also
## sparkles: SPARKLES white flashes over the iron for the first
## SPARKLE_MIN minutes of every night hour, as the real one does.

const SPOTS := 4
## Footprints longer than ELONGATED × their width line their long sides.
const ELONGATED := 2.0
const SIDE_STEP_M := 70.0
const MAX_PER_SIDE := 6
## Spot energy at full night (Godot units, not physical).
const ENERGY := 7.0
const COLOUR := Color(1.0, 0.87, 0.68)
## Out from the footprint's edge to the lamp, and up off the ground (m).
const SETBACK_M := 10.0
const LAMP_Y_M := 1.0
## Self-lit towers: [lamp colour, CityLights glow scale].
## Night lamp energy against the part's own (always-on) energy.
const LAMP_GAIN := 1.4
const SPARKLES := 1500
const SPARKLE_MIN := 5.0
const SPARKLE_M := 0.9
const SPARKLE_CODE := """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform float night_energy = 0.0;
uniform float city_hour = 20.0;
varying float seed;
void vertex() {
	seed = float(INSTANCE_ID);
	// Billboard: the quad faces the camera at the instance's position.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1],
		INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	float minute = fract(city_hour) * 60.0;
	float on = step(minute, %f) * step(0.05, night_energy);
	float flash = step(0.82, fract(sin(seed * 12.9898 + floor(TIME * 9.0) * 78.233) * 43758.5453));
	float r = length(UV - 0.5) * 2.0;
	if (on * flash < 0.5 || r > 1.0) {
		discard;
	}
	ALBEDO = vec3(1.0);
	EMISSION = vec3(1.0, 0.97, 0.9) * 6.0 * (1.0 - r * r);
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
	# [lamp, aim point, half-width it must cover]
	var lamps: Array = []
	var long_x := box.size.x >= box.size.z
	var long_len := maxf(box.size.x, box.size.z)
	var short_half := minf(box.size.x, box.size.z) * 0.5
	if long_len > ELONGATED * short_half * 2.0:
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
				lamps.append([Vector3(p.x, base_y, p.z), Vector3(face.x, aim_y, face.z), cover])
	else:
		var half := maxf(box.size.x, box.size.z) * 0.5
		var dist := half + SETBACK_M * m
		for k in SPOTS:
			var a := TAU * (float(k) + 0.5) / float(SPOTS)
			lamps.append([Vector3(c.x + cos(a) * dist, base_y, c.z + sin(a) * dist),
				Vector3(c.x, aim_y, c.z), half])
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
		spot.spot_angle_attenuation = 2.5
		spot.spot_attenuation = 0.35
		spot.light_color = COLOUR
		spot.light_energy = 0.0
		spot.shadow_enabled = false
		spot.visible = false
		spot.set_meta(StreetLights.META, ENERGY)
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
			var lamp := mat.duplicate() as StandardMaterial3D
			CityLights.mark_glow(lamp, mat.emission_energy_multiplier * LAMP_GAIN / CityLights.NIGHT_ENERGY)
			mi.set_surface_override_material(s, lamp)

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
	var sh := Shader.new()
	sh.code = SPARKLE_CODE
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_meta(CityLights.META, 1.0)
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
