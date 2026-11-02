extends SceneTree

## Headless: godot --headless --script tests/landmark_lights_test.gd
## Landmark floodlighting (LandmarkLights, desktop Ultra): a solid
## landmark gets SPOTS ground spots round its base, aimed up at it,
## shadowless and CityLights-driven; a lattice tower glows in its own
## lamp colour at night instead, without touching the shared mesh.

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	var m := WorldScale.metres_to_units()
	var hero := LandmarkBuilder.build("colosseum")
	var box := LandmarkLights.local_aabb(hero)
	if box.size.y < 45.0 * m:
		failures.append("Colosseum bounds should be its full height, got %f m" % (box.size.y / m))
	if LandmarkLights.dress(hero, "colosseum") != LandmarkLights.SPOTS:
		failures.append("a solid landmark should get %d spots" % LandmarkLights.SPOTS)
	var holder := hero.get_node_or_null("LandmarkLights")
	if holder != null:
		for spot: SpotLight3D in holder.get_children():
			var fwd := -spot.transform.basis.z
			var to_c := Vector3(box.get_center().x, 0.0, box.get_center().z) - spot.position
			if fwd.y <= 0.1 or Vector2(fwd.x, fwd.z).dot(Vector2(to_c.x, to_c.z)) <= 0.0:
				failures.append("each spot should aim up at the landmark: %s" % fwd)
				break
			if spot.shadow_enabled or not spot.has_meta(StreetLights.META) \
					or spot.spot_range < box.size.y:
				failures.append("spots should be shadowless, night-driven and reach the top")
				break
		CityLights.apply(hero, 1.0)
		var s0 := holder.get_child(0) as SpotLight3D
		if not s0.visible or s0.light_energy <= 0.0:
			failures.append("spots should be on at night")
		CityLights.apply(hero, 0.0)
		if s0.visible:
			failures.append("spots should be off by day")
	hero.free()
	# A long palace front is lit down both sides, out to its end towers.
	var palace := LandmarkBuilder.build("big_ben")
	var pbox := LandmarkLights.local_aabb(palace)
	var n := LandmarkLights.dress(palace, "big_ben")
	var long_z := pbox.size.z > pbox.size.x
	var reach_lo := INF
	var reach_hi := -INF
	for spot: SpotLight3D in palace.get_node("LandmarkLights").get_children():
		var along := spot.position.z if long_z else spot.position.x
		reach_lo = minf(reach_lo, along)
		reach_hi = maxf(reach_hi, along)
	var span := pbox.size.z if long_z else pbox.size.x
	if n < 6 or n % 2 != 0 or reach_hi - reach_lo < span * 0.6:
		failures.append("Westminster should get paired spots along its length: %d spots over %.0f of %.0f m"
			% [n, (reach_hi - reach_lo) / m, span / m])
	palace.free()
	# The Eiffel Tower glows gold from within instead.
	var eiffel := LandmarkBuilder.build("eiffel")
	if LandmarkLights.dress(eiffel, "eiffel") != 0 or eiffel.has_node("LandmarkLights"):
		failures.append("the Eiffel Tower should glow, not take spots")
	var glowing := 0
	var shared_dark := true
	for mi in LandmarkBuilder.parts(eiffel):
		var o := mi.get_surface_override_material(0) as StandardMaterial3D
		if o != null and o.has_meta(CityLights.META):
			glowing += 1
		var base := mi.mesh.surface_get_material(0) as StandardMaterial3D
		if base != null and base.has_meta(CityLights.META):
			shared_dark = false
	CityLights.apply(eiffel, 1.0)
	var lit := false
	for mi in LandmarkBuilder.parts(eiffel):
		var o := mi.get_surface_override_material(0) as StandardMaterial3D
		if o != null and o.emission_energy_multiplier > 0.0 and o.emission.r > o.emission.b * 2.0:
			lit = true
	if glowing < 4 or not shared_dark or not lit:
		failures.append("Eiffel iron should glow gold at night via overrides (%d glowing, shared untouched %s, lit %s)"
			% [glowing, shared_dark, lit])
	# The sparkle: night-driven billboards spread up the tower.
	var sp := eiffel.get_node_or_null("Sparkle") as MultiMeshInstance3D
	if sp == null or sp.multimesh.instance_count < LandmarkLights.SPARKLES / 2 \
			or not (sp.multimesh.mesh.surface_get_material(0) as Material).has_meta(CityLights.META):
		failures.append("the Eiffel Tower should carry ~%d night-driven sparkles" % LandmarkLights.SPARKLES)
	elif DisplayServer.get_name() != "headless":
		# (The headless dummy renderer keeps no instance transforms.)
		var top := 0.0
		for k in sp.multimesh.instance_count:
			top = maxf(top, sp.multimesh.get_instance_transform(k).origin.y / m)
		if top < 250.0:
			failures.append("sparkles should climb the tower, highest at %.0f m" % top)
	eiffel.free()
	# A landmark's own lamp (here a lighthouse lantern) is dark by day and
	# lit at night.
	var bridge := LandmarkBuilder.build("lighthouse")
	LandmarkLights.dress(bridge, "lighthouse")
	var lamp: MeshInstance3D = null
	for mi in LandmarkBuilder.parts(bridge):
		if str(mi.name).ends_with("Lamp"):
			lamp = mi
	var lo := lamp.get_surface_override_material(0) as StandardMaterial3D if lamp != null else null
	if lo == null or not lo.has_meta(CityLights.META):
		failures.append("landmark lamps should be night-driven")
	else:
		CityLights.apply(bridge, 0.0)
		var day := lo.emission_energy_multiplier
		CityLights.apply(bridge, 1.0)
		if day != 0.0 or lo.emission_energy_multiplier < 1.2:
			failures.append("landmark lamps: %.2f by day, %.2f at night" % [day, lo.emission_energy_multiplier])
	bridge.free()
	failures.erase(failures[0])
	if failures.is_empty():
		print("LANDMARK LIGHTS OK: spots round solid landmarks aimed up, night-driven; lattice towers glow gold")
		quit(0)
	else:
		for f in failures:
			printerr("LANDMARK LIGHTS FAIL: ", f)
		quit(1)
