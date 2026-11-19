extends SceneTree

## Headless: godot --headless --script tests/visual_quality_test.gd
## Contracts for the 3-phase visual quality upgrade:
## - Phase 1: AgX tonemapping, clamped Ultra auto-exposure, PhotoMode DoF,
##   near cloud shadows across ground/roads/water/facades, facade wetness /
##   drip-AO / sill-spill, wet-roof overlay, street-furniture contact shadows.
## - Phase 2: shallow-water Beer-Lambert bed/caustics + sun glitter keeping
##   opaque SSR, vessel wakes/collars, 3-slice parallax HG clouds, valley mist.
## - Phase 3: dynamic hero street-lamp shadows + halos, moving vehicle
##   headlights/taillights, unified wind gusts + wet-leaf sheen, ambient
##   birds and winter chimney smoke.

func _init() -> void:
	_run()

func _flat(preset: int) -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, preset)
	var n := data.grid_size
	data.heights.resize(n * n)
	data.heights.fill(5.0)
	data.water_level = 0.0
	data.seed_value = 11
	data.latitude = 60.1699
	data.longitude = 24.9384
	return data

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]

	# --- Phase 1: AgX, clamped eye adaptation, PhotoMode DoF ---
	var env := Environment.new()
	PostGrade.apply(env)
	if env.tonemap_mode != Environment.TONE_MAPPER_AGX:
		failures.append("PostGrade should use AgX tonemapping")
	var ca := CameraAttributesPractical.new()
	RenderQuality.apply_camera_attributes(ca, RenderSettings.Preset.ULTRA, true)
	if not ca.auto_exposure_enabled or ca.auto_exposure_min_sensitivity < 70.0 \
			or ca.auto_exposure_max_sensitivity > 140.0 \
			or ca.auto_exposure_min_sensitivity >= ca.auto_exposure_max_sensitivity:
		failures.append("Ultra Forward+ should clamp auto-exposure to a narrow ISO band (got %.1f..%.1f)" % [
			ca.auto_exposure_min_sensitivity, ca.auto_exposure_max_sensitivity])
	RenderQuality.apply_camera_attributes(ca, RenderSettings.Preset.HIGH, true)
	if ca.auto_exposure_enabled:
		failures.append("High should keep auto-exposure disabled")
	RenderQuality.apply_camera_attributes(ca, RenderSettings.Preset.ULTRA, false)
	if ca.auto_exposure_enabled:
		failures.append("Mobile Ultra should keep auto-exposure disabled")
	PhotoMode.apply_dof(ca, true, 150.0)
	if not ca.dof_blur_far_enabled or ca.dof_blur_amount <= 0.0:
		failures.append("PhotoMode.apply_dof(true) should enable subtle far DoF")
	PhotoMode.apply_dof(ca, false)
	if ca.dof_blur_far_enabled or ca.dof_blur_amount != 0.0:
		failures.append("PhotoMode.apply_dof(false) should restore DoF off")

	# --- Phase 1: Near cloud shadows + facade wetness / drip-AO / sill-spill ---
	var shaders := {
		"ground": GroundMaterial.shader_code(),
		"road_asphalt": RoadSurface.material(Color(0.1, 0.1, 0.1)).shader.code,
		"road_paved": RoadSurface.paved_material("pavement", Color(0.3, 0.3, 0.3), 0.0, true).shader.code,
		"water": WaterSurface.material(RenderSettings.Preset.ULTRA).shader.code,
		"facade": FacadeShader.shader().code,
	}
	for k in shaders:
		var code: String = shaders[k]
		if "// @CLOUD_SHADOW" in code:
			failures.append("%s shader left // @CLOUD_SHADOW unspliced" % k)
		if not ("cloud_shadow_at(" in code or "t_cloud_shadow(" in code):
			failures.append("%s shader should sample drifting cloud shadows" % k)
	var fcode: String = shaders["facade"]
	for token in ["climate_wetness", "climate_rain", "wall_ao", "spill_e"]:
		if not (token in fcode):
			failures.append("FacadeShader missing expected feature token: %s" % token)
	if not ("world_origin_m" in TerrainGlsl.CLOUD_SHADOW_GLSL) or not ("world_origin_m" in TerrainGlsl.CODE):
		failures.append("TerrainGlsl cloud shadows must offset by world_origin_m")
	if fcode.count("global uniform vec2 world_origin_m") != 1:
		failures.append("FacadeShader spliced code must declare world_origin_m exactly once")

	# --- Phase 1: Cache-safe wet-roof overlay ---
	var rworld := Node3D.new()
	var rmat := StandardMaterial3D.new()
	RoofVariety.mark(rmat)
	var rbox := BoxMesh.new()
	rbox.material = rmat
	var rmi := MeshInstance3D.new()
	rmi.mesh = rbox
	rmi.set_meta("lod_layer", "Buildings")
	rworld.add_child(rmi)
	RoofSnow.apply(rworld, false, true)
	if rmi.material_overlay != RoofSnow.wet_overlay():
		failures.append("raining without snow should attach RoofSnow.wet_overlay()")
	RoofSnow.apply(rworld, true, true)
	if rmi.material_overlay != RoofSnow.overlay():
		failures.append("snow should take priority over wet overlay on roofs")
	RoofSnow.apply(rworld, false, false)
	if rmi.material_overlay != null:
		failures.append("dry weather should clear roof material_overlay")
	if rmat.next_pass != null:
		failures.append("roof overlays must never mutate shared roof materials")
	rworld.free()

	# --- Phase 1: StreetFurniture contact shadows ---
	var fdata := _flat(RenderSettings.Preset.ULTRA)
	fdata.buildings = [{"x": 200.0, "z": 200.0, "size_x": 10.0, "size_z": 10.0, "height": 9.0}]
	fdata.street_furniture = [
		{"x": 12.0, "z": 12.0, "kind": "bench"},
		{"x": 16.0, "z": 12.0, "kind": "bin"},
		{"x": 20.0, "z": 12.0, "kind": "bollard"},
	]
	var fground := GroundTruth.new(fdata)
	var fmask := VegetationMask.new(fdata, fground)
	var froot := Node3D.new()
	var fcount := StreetFurniture.build(froot, fdata, fground, fmask, 1.0)
	if fcount < 3 or froot.find_child("FurnitureShadows", true, false) == null:
		failures.append("StreetFurniture should add batched FurnitureShadows contact quads (placed=%d)" % fcount)
	froot.free()

	# --- Phase 2: Water opaque SSR + shallow caustics + sun glitter + wakes ---
	var wcode: String = shaders["water"]
	if not ("depth_draw_opaque" in wcode) or not ("bed_d" in wcode) or not ("caust" in wcode) or not ("glitter_e" in wcode):
		failures.append("WaterShader should keep depth_draw_opaque with shallow bed/caustics and sun glitter")
	if not ("direct_sun" in wcode) or not ("max(harbour, brackish)" in wcode):
		failures.append("WaterShader should gate caustics/glitter on direct_sun and damp shallow bed in harbour/brackish")
	if not ("1.0 - UV.x" in WaterWakes.WAKE_CODE):
		failures.append("WaterWakes.WAKE_CODE should map bow UV.x=1..stern 0 via 1.0 - UV.x")
	var wroot := Node3D.new()
	var wk := WaterWakes.add_wake(wroot, Vector3(10, 0, 10), 0.5, 90.0, 20.0)
	var cl := WaterWakes.add_collar(wroot, Vector3(40, 0, 10), 0.2, 50.0, 12.0)
	if wk == null or cl == null or wk.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF \
			or "// @SNOW" in (wk.material_override as ShaderMaterial).shader.code:
		failures.append("WaterWakes should create shadowless wake and collar meshes with spliced shaders")
	wroot.free()

	# --- Phase 2: Multi-layer parallax HG clouds & valley height mist ---
	if not ("hg_phase(" in SkyShader.CODE) or not ("cloud_proj(" in SkyShader.CODE) or not ("den_top" in SkyShader.CODE):
		failures.append("SkyShader should carry 3-slice parallax cumulus and Henyey-Greenstein scattering")
	var rig := AtmosphereRig.new(RenderSettings.Preset.ULTRA)
	rig.set_season(LocationData.Season.AUTUMN)
	rig.set_time(rig.golden_hour())
	rig.set_weather(0, 25.0)
	rig.set_valley_floor(0.0, false)
	if rig.environment.fog_height_density <= 0.0:
		failures.append("humid valley golden hour should enable gentle height-based mist")
	rig.set_valley_floor(0.0, true)
	if rig.environment.fog_height_density != 0.0:
		failures.append("arid places should disable valley height mist")
	if rig.camera_attributes == null:
		failures.append("AtmosphereRig should attach CameraAttributesPractical")

	# --- Phase 3: Hero street-lamp shadows + halos ---
	var lroot := Node3D.new()
	var placed := {"lantern": [], "modern": []}
	for i in 30:
		(placed["lantern" if i % 2 == 0 else "modern"] as Array).append(
			Transform3D(Basis(), Vector3(float(i) * 3.0, 0.0, 4.0)))
	StreetLights.add(lroot, placed, "haussmann", 1.0)
	CityLights.apply(lroot, 1.0)
	var sh_n := StreetLights.update_shadows(lroot, Vector3(10.0, 2.0, 4.0), 1.0, RenderSettings.Preset.ULTRA, true)
	if sh_n <= 0 or sh_n > StreetLights.HERO_SHADOW_MAX:
		failures.append("Ultra night should enable 1..%d hero street-lamp shadows, got %d" % [
			StreetLights.HERO_SHADOW_MAX, sh_n])
	var halos := lroot.get_node_or_null("StreetLampHalos") as MultiMeshInstance3D
	if halos == null or not halos.visible or halos.multimesh.instance_count != 30:
		failures.append("Ultra night should create visible StreetLampHalos matching lamp count")
	var day_n := StreetLights.update_shadows(lroot, Vector3(10.0, 2.0, 4.0), 0.0, RenderSettings.Preset.ULTRA, true)
	if day_n != 0 or halos.visible:
		failures.append("daytime should disable street-lamp shadows and hide halos")
	lroot.free()
	var halo_host := Node3D.new()
	var city_w := Node3D.new()
	halo_host.add_child(city_w)
	StreetLights.add(city_w, {"lantern": [Transform3D(Basis(), Vector3(2.0, 0.0, 2.0))]}, "haussmann", 1.0)
	StreetLights.update_shadows(city_w, Vector3.ZERO, 1.0, RenderSettings.Preset.ULTRA, true)
	var stale_halos := halo_host.get_node_or_null("StreetLampHalos")
	if stale_halos == null:
		failures.append("city world should attach StreetLampHalos to shared host")
	halo_host.remove_child(city_w)
	city_w.free()
	var wild_w := Node3D.new()
	halo_host.add_child(wild_w)
	StreetLights.update_shadows(wild_w, Vector3.ZERO, 1.0, RenderSettings.Preset.ULTRA, true)
	if halo_host.get_node_or_null("StreetLampHalos") != null \
			or (stale_halos != null and not stale_halos.is_queued_for_deletion()):
		failures.append("switching to wilderness world without StreetLights should remove stale StreetLampHalos")
	if stale_halos != null and is_instance_valid(stale_halos):
		stale_halos.free()
	wild_w.free()
	halo_host.free()

	# --- Phase 3: Unified wind gusts & wet-leaf sheen ---
	if not ("climate_wetness" in TreeMeshLibrary.LEAF_SHADER) or not ("climate_rain" in TreeMeshLibrary.LEAF_SHADER):
		failures.append("TreeMeshLibrary.LEAF_SHADER should respond to rain gusts and wetness sheen")
	if not ("climate_wetness" in GrassCarpet.SHADER) or not ("climate_rain" in GrassCarpet.SHADER):
		failures.append("GrassCarpet.SHADER should respond to rain gusts and wetness sheen")

	# --- Phase 3: Ambient birds and winter chimney smoke ---
	var aroot := Node3D.new()
	var adata := _flat(RenderSettings.Preset.ULTRA)
	adata.season = LocationData.Season.WINTER
	adata.buildings = [
		{"x": 20.0, "z": 20.0, "size_x": 4.0, "size_z": 4.0, "height": 28.0, "chimney": true},
		{"x": 35.0, "z": 15.0, "size_x": 12.0, "size_z": 10.0, "height": 12.0, "kind": "house"},
	]
	var aground := GroundTruth.new(adata)
	rig.set_season(LocationData.Season.WINTER)
	rig.set_time(12.0)
	rig.set_weather(0, 20.0)
	AmbientLife.sync(aroot, adata, aground, rig, RenderSettings.Preset.ULTRA)
	var birds := aroot.get_node_or_null("AmbientBirds") as MultiMeshInstance3D
	var smoke := aroot.get_node_or_null("ChimneySmoke") as MultiMeshInstance3D
	if birds == null or not birds.visible:
		failures.append("clear daytime High/Ultra should show AmbientBirds")
	if smoke == null or not smoke.visible:
		failures.append("winter High/Ultra with chimneys should show ChimneySmoke")
	rig.set_time(0.0)
	AmbientLife.sync(aroot, adata, aground, rig, RenderSettings.Preset.ULTRA)
	if birds.visible:
		failures.append("night should hide AmbientBirds")
	adata.season = LocationData.Season.SUMMER
	rig.set_season(LocationData.Season.SUMMER)
	rig.set_snow_ground(false)
	AmbientLife.sync(aroot, adata, aground, rig, RenderSettings.Preset.ULTRA)
	if smoke.visible:
		failures.append("warm summer should hide ChimneySmoke")
	if not ("world_vertex_coords" in AmbientLife.BIRD_CODE) or not ("dir_sign" in AmbientLife.BIRD_CODE) \
			or not ("ALPHA = alpha_fade" in AmbientLife.BIRD_CODE):
		failures.append("AmbientLife.BIRD_CODE should use world_vertex_coords, dir_sign heading, and ALPHA blend")
	if not ("world_vertex_coords" in AmbientLife.SMOKE_CODE) or "inverse(MODEL_MATRIX)" in AmbientLife.SMOKE_CODE:
		failures.append("AmbientLife.SMOKE_CODE should billboard via world_vertex_coords without inverse(MODEL_MATRIX)")
	aroot.free()
	rig.free()

	failures.erase(failures[0])
	if failures.is_empty():
		print("VISUAL QUALITY OK: all Phase 1, 2 and 3 contracts verified")
		quit(0)
	else:
		for f in failures:
			printerr("VISUAL QUALITY FAIL: ", f)
		quit(1)
