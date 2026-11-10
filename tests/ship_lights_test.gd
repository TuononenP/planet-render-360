extends SceneTree

## Headless: large ships light their cabins and navigation lights with the
## city's night cycle (CityLights), stay dark by day, never mark the yachts'
## shared glass, and carry red to port (-Z) and green to starboard (+Z).
var failures: Array[String] = []

func _init() -> void:
	MaterialLibrary.hi_res = true
	var hull := VesselMaterials.paint("#2d3b4a")
	var holder := Node3D.new()
	holder.name = "Marina"
	var cases := [["liner", 250.0, 31.0, 50.0], ["passenger", 50.0, 8.0, 12.0]]
	var lit_keys := {}
	for c in cases:
		var lm := VesselPrototypes.geometry(c[0], c[1], c[2], c[3], hull, true, true, 0.9)
		for part in lm.commit(holder, "%s_" % c[0]):
			var key := str(part.name).trim_prefix("%s_" % c[0])
			if key.begins_with("Cabin") or key.begins_with("Nav") or key == "Lamp":
				lit_keys[str(part.name)] = part
			if key in ["NavRed", "NavGreen"]:
				var z := _mean_z(part.mesh)
				if key == "NavRed":
					_check(z < 0.0, "%s red sidelight must be to port (-Z)" % c[0])
				else:
					_check(z > 0.0, "%s green sidelight must be to starboard (+Z)" % c[0])
		_check(lit_keys.keys().any(func(k: String) -> bool: return k.begins_with(c[0] + "_Cabin")), "%s needs lit cabin glass" % c[0])
		_check(lit_keys.has(c[0] + "_NavRed") and lit_keys.has(c[0] + "_NavGreen"), "%s needs sidelights" % c[0])
	# The 10 m quay steamer prototype (a MultiMesh) lights its cabins too.
	var steam := MultiMeshInstance3D.new()
	steam.multimesh = MultiMesh.new()
	steam.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	steam.multimesh.mesh = VesselPrototypes.mesh("steam_far")
	holder.add_child(steam)
	var steam_cabins := 0
	for s in steam.multimesh.mesh.get_surface_count():
		if steam.multimesh.mesh.surface_get_material(s).has_meta(CityLights.META):
			steam_cabins += 1
	_check(steam_cabins > 0, "distant quay steamers must light their cabins")
	CityLights.apply(holder, 0.0)
	for k in lit_keys:
		_check(_energy(lit_keys[k]) == 0.0, "%s must be dark by day" % k)
	CityLights.apply(holder, 1.0)
	for k in lit_keys:
		_check(_energy(lit_keys[k]) > 0.5, "%s must light at night" % k)
	_check(not VesselMaterials.get_mat("glass").has_meta(CityLights.META), "yacht glass must stay unlit")
	_check(VesselMaterials.get_mat("glass").emission_energy_multiplier == 0.0 or not VesselMaterials.get_mat("glass").emission_enabled,
		"shared glass must not glow")
	CityLights.apply(holder, 0.0)
	holder.free()
	if failures.is_empty():
		print("SHIP LIGHTS OK: cabins, lamps and sidelights follow the night; yachts untouched")
		quit(0)
	else:
		for f in failures:
			printerr("SHIP LIGHTS FAIL: ", f)
		quit(1)

func _energy(part: MeshInstance3D) -> float:
	var m := part.mesh.surface_get_material(0) as StandardMaterial3D
	return m.emission_energy_multiplier if m != null else -1.0

func _mean_z(mesh: Mesh) -> float:
	var v: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var z := 0.0
	for p in v:
		z += p.z
	return z / maxf(float(v.size()), 1.0)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)
