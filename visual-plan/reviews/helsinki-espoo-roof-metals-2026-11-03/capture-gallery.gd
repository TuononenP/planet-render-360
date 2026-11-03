extends SceneTree

func _init() -> void:
 _run.call_deferred()

func _run() -> void:
 root.size = Vector2i(1600, 1000)
 var scene := Node3D.new()
 root.add_child(scene)
 var atmos := AtmosphereRig.new()
 scene.add_child(atmos)
 atmos.set_quality(RenderSettings.Preset.ULTRA)
 atmos.set_place(60.168, 24.953)
 atmos.set_utc_offset(3.0)
 atmos.set_season(LocationData.Season.SUMMER)
 atmos.set_weather(0, 0.0)
 atmos.set_time(17.0, 60.168, {"year":2026,"month":6,"day":21})
 var camera := Camera3D.new()
 scene.add_child(camera)
 camera.position = Vector3(25, 27, 37)
 camera.look_at(Vector3(0, 1, 0))
 camera.fov = 48.0
 camera.current = true
 var ground := MeshInstance3D.new()
 var plane := PlaneMesh.new()
 plane.size = Vector2(70, 55)
 ground.mesh = plane
 var paving := StandardMaterial3D.new()
 paving.albedo_color = Color("#8b8f8c")
 paving.roughness = 0.9
 ground.material_override = paving
 scene.add_child(ground)
 MaterialLibrary.hi_res = true
 FacadeMaterials.begin_build()
 var roofs := Node3D.new()
 scene.add_child(roofs)
 var paints := ["#538472", "#3a3e44", "#85898c", "#6a3028"]
 var names := ["Copper", "Charcoal", "Grey", "Falu red"]
 var ring := PackedVector2Array([Vector2(-3,-5),Vector2(3,-5),Vector2(3,5),Vector2(-3,5)])
 for row in 2:
  for col in 4:
   var at := Vector3((col - 1.5) * 9.0,0,(row - 0.5) * 15.0)
   var roof := MeshInstance3D.new()
   roof.mesh = RoofGeometry.form_mesh(ring, 2.5, 2.6, "gabled")
   roof.position = at
   roof.set_meta("lod_layer", "Buildings")
   var set_name := "copper" if col == 0 else "sheet_metal"
   var paint := MaterialLibrary.parse_colour_tag(paints[col])
   if row == 0:
    set_name = "terracotta" if col == 0 else "slate"
   var tint := FacadeMaterials.roof_base_tint(set_name) if row == 0 and col == 0 else FacadeMaterials._roof_floor(set_name, FacadeMaterials._keep_chroma(set_name, FacadeMaterials._calib(set_name, paint)))
   roof.material_override = FacadeMaterials.roof_set_material(set_name, tint)
   roofs.add_child(roof)
   var block := MeshInstance3D.new()
   var box := BoxMesh.new()
   box.size = Vector3(6,2.5,10)
   block.mesh = box
   block.position = at + Vector3.UP * 1.25
   var wall := StandardMaterial3D.new()
   wall.albedo_color = Color("#ded5c5")
   wall.roughness = 0.9
   block.material_override = wall
   scene.add_child(block)
   var label := Label3D.new()
   label.text = ("Previous: " if row == 0 else "Corrected: ") + names[col]
   label.font = load("res://assets/fonts/InstrumentSans-Variable.ttf")
   label.font_size = 42
   label.pixel_size = 0.012
   label.modulate = Color("#172325")
   label.outline_size = 0
   label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
   label.position = at + Vector3(0,0.6,6.3)
   scene.add_child(label)
 var out := ProjectSettings.globalize_path("res://visual-plan/reviews/roof-metals-gallery-2026-11-03")
 DirAccess.make_dir_recursive_absolute(out)
 for winter in [false,true]:
  RenderingServer.global_shader_parameter_set("climate_snow_on",1.0 if winter else 0.0)
  RenderingServer.global_shader_parameter_set("climate_snow_y",-1000.0)
  RenderingServer.global_shader_parameter_set("climate_snow_band",150.0)
  RoofSnow.apply(roofs,winter)
  for frame in 120:
   await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(out.path_join("winter.png" if winter else "summer.png"))
 print("ROOF GALLERY DONE ",out)
 quit()
