extends SceneTree

const OUT := "res://visual-plan/reviews/placement-audit-2026-11-03/"
const TYPES := ["itsukushima_torii"]

func _init() -> void:
	_run()

func _settle(frames: int = 40) -> void:
	for i in frames:
		await process_frame
		RenderingServer.force_draw(false)

func _snap(v: View360, name: String) -> void:
	await _settle()
	v.snapshot().save_jpg(OUT + name + ".jpg", 0.93)
	print("PLACEMENT CAPTURE ",name)

func _extent(hero: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for part in LandmarkBuilder.parts(hero):
		var b: AABB = part.global_transform * part.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size = Vector2i(1280,800)
	var p := GenerationPipeline.new()
	root.add_child(p)
	var v := View360.new()
	root.add_child(v)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	v._governor.set_process(false)
	UiPrefs.reduce_motion = true
	var rows: Array = []
	for type in TYPES:
		var e := LocationData.entry_for_type(type)
		p.run(float(e["lat"]),float(e["lon"]),str(e["name"]),RenderSettings.Preset.HIGH)
		var data: LocationData = await p.finished
		var g: GroundTruth = await p.ground_for(data)
		var th := Thread.new()
		th.start(func() -> Node3D: return View360.make_world(data,g))
		while th.is_alive(): await process_frame
		var world: Node3D = th.wait_to_finish()
		v.show_location(data,[g,world])
		v._live_time = false
		v._atmos.set_weather(0,15.0)
		await _settle(90)
		var hero := world.get_node("Landmark_"+type) as Node3D
		rows.append({"type":type,"base_asl":g.asl_y(hero.position.y),"arrival_asl":g.asl_y(v._rig.position.y),"dem":p.used_real_dem,"osm":p.used_osm,"parts":LandmarkBuilder.parts(hero).size()})
		print("PLACEMENT LIVE ",JSON.stringify(rows.back()))
		await _snap(v,type+"_arrival")
		var box := _extent(hero)
		var target := box.get_center()
		var length := maxf(box.size.x,maxf(box.size.y,box.size.z))
		var basis := Basis(Vector3.UP,-deg_to_rad(float(e.get("yaw_deg",0))))
		var direction := basis * Vector3(0.65,0.45,1.0).normalized()
		if type == "hoover_dam":
			direction = Vector3(sin(deg_to_rad(195.0)),0.45,-cos(deg_to_rad(195.0))).normalized()
		var eye := target + direction * maxf(length*1.6,70.0)
		eye.y = maxf(eye.y,LandmarkTerrain.floor_y(data,g,Vector2(eye.x,eye.z))+30.0)
		v._rig.position = eye
		var look := View360.aim(eye,target)
		v._rig.set_look(look.x,look.y)
		v._rig.get_node("Camera3D").fov=45.0
		v._atmos.set_probe_origin(eye)
		await _snap(v,type+"_overview")
		var shrine := WorldScale.xz_from_latlon(34.2961,132.3198,data.latitude,data.longitude)
		var shrine_target := Vector3(shrine.x,g.render_y(7.0),shrine.y)
		var shrine_eye := shrine_target + Basis(Vector3.UP,-deg_to_rad(30.0)) * Vector3(0.65,0.45,1.0).normalized()*70.0
		shrine_eye.y = maxf(shrine_eye.y,LandmarkTerrain.floor_y(data,g,Vector2(shrine_eye.x,shrine_eye.z))+30.0)
		v._rig.position = shrine_eye
		var shrine_look := View360.aim(shrine_eye,shrine_target)
		v._rig.set_look(shrine_look.x,shrine_look.y)
		v._atmos.set_probe_origin(shrine_eye)
		await _snap(v,"itsukushima_shrine_waterfront")
		var hall := shrine + Vector2(19.15,27.6)
		for approach in [Vector2(-1,-1), Vector2(-1,0), Vector2(0,-1), Vector2(0,1)]:
			var boat: Vector2 = hall + approach.normalized()*38.0
			if g.water_at(boat.x,boat.y) <= 0.0:
				continue
			v._rig.position = Vector3(boat.x,g.render_y(8.0),boat.y)
			var boat_look := View360.aim(v._rig.position,Vector3(hall.x,g.render_y(4.5),hall.y))
			v._rig.set_look(boat_look.x,boat_look.y)
			v._rig.get_node("Camera3D").fov=55.0
			v._atmos.set_probe_origin(v._rig.position)
			await _snap(v,"itsukushima_shrine_platform")
			break
		v._rig.get_node("Camera3D").fov=75.0
	p.run(37.8040, -122.4195, "San Francisco, United States", RenderSettings.Preset.HIGH)
	var city: LocationData = await p.finished
	var cg: GroundTruth = await p.ground_for(city)
	var pier_reports: Array = []
	var pier_ctx := BuildingBuilder._height_context(city)
	for building in city.buildings:
		if str(building.get("name","")) not in ["Shed A","Shed B","Shed D"]: continue
		var masses: Array = []
		for mass in BuildingMasses.plan(building,pier_ctx):
			var footing := BuildingFoundation.sample(cg,mass["ring"],mass["centre"],cg.render_y(WaterBuilder.SEA_LEVEL_M))
			masses.append({"floor_asl":cg.asl_y(footing["floor"]),"water_asl":cg.asl_y(footing["water"]),"raised":footing["raised"],"wall_m":mass["wall_m"]})
		pier_reports.append({"name":building["name"],"masses":masses})
	print("PIER CLEARANCE ",JSON.stringify(pier_reports))
	FileAccess.open(OUT+"sf-pier-clearance.json",FileAccess.WRITE).store_string(JSON.stringify(pier_reports,"\t"))
	var city_th := Thread.new()
	city_th.start(func() -> Node3D: return View360.make_world(city, cg))
	while city_th.is_alive():
		await process_frame
	var cw: Node3D = city_th.wait_to_finish()
	v.show_location(city, [cg, cw])
	v._atmos.set_weather(0, 15.0)
	var island := WorldScale.xz_from_latlon(37.82680,-122.42322,city.latitude,city.longitude)
	v._rig.position = Vector3(0,cg.render_y(115.0),0)
	var city_look := View360.aim(v._rig.position, Vector3(island.x,cg.render_y(35.0),island.y))
	v._rig.set_look(city_look.x,city_look.y)
	v._rig.get_node("Camera3D").fov = 18.0
	v._atmos.set_probe_origin(v._rig.position)
	await _snap(v,"from_sf")
	for building in city.buildings:
		if str(building.get("name","")) not in ["Shed A","Shed B","Shed D"]: continue
		var ring: PackedVector2Array = building["footprint"]
		var centre := Vector2(building["x"],building["z"])
		var target := Vector3(centre.x,cg.render_y(6.0),centre.y)
		var span := maxf(RingGeometry.aabb(ring).size.x,RingGeometry.aabb(ring).size.y)
		for approach in [Vector2(0,-1),Vector2(-1,-1),Vector2(-1,0),Vector2(1,0)]:
			var boat: Vector2 = centre+approach.normalized()*span*1.1
			if cg.water_at(boat.x,boat.y)<=0: continue
			v._rig.position=Vector3(boat.x,cg.render_y(7.0),boat.y)
			var detail_look := View360.aim(v._rig.position,target)
			v._rig.set_look(detail_look.x,detail_look.y)
			v._rig.get_node("Camera3D").fov=55.0
			v._atmos.set_probe_origin(v._rig.position)
			await _snap(v,"sf_"+str(building["name"]).to_lower().replace(" ","_")+"_clearance")
			break
		if str(building["name"])!="Shed D": continue
		var winding := signf(RingGeometry.signed_area(ring))
		var candidates: Array = []
		for i in ring.size():
			var a2 := ring[i]
			var b2 := ring[(i+1)%ring.size()]
			var edge := b2-a2
			var normal := Vector2(edge.y,-edge.x).normalized()*winding
			var boat := (a2+b2)*0.5+normal*55.0
			if cg.water_at(boat.x,boat.y)>0:
				candidates.append({"boat":boat,"at":(a2+b2)*0.5,"length":edge.length()})
		candidates.sort_custom(func(a,b)->bool:return a["length"]>b["length"])
		if not candidates.is_empty():
			var chosen: Dictionary = candidates[0]
			var boat: Vector2 = chosen["boat"]
			var at: Vector2 = chosen["at"]
			v._rig.position=Vector3(boat.x,cg.render_y(4.5),boat.y)
			var detail_look := View360.aim(v._rig.position,Vector3(at.x,cg.render_y(3.0),at.y))
			v._rig.set_look(detail_look.x,detail_look.y)
			v._rig.get_node("Camera3D").fov=55.0
			v._atmos.set_probe_origin(v._rig.position)
			await _snap(v,"sf_pier45_waterline")
	print("ALCATRAZ MAINLAND primary=", city.landmark_type, " candidates=", city.landmark_candidates.size())
	FileAccess.open(OUT+"waterfront-live.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"\t"))
	p.queue_free()
	v.queue_free()
	await process_frame
	while CacheStore.busy(): await process_frame
	CacheStore.finish()
	print("PLACEMENT CAPTURES DONE ",rows.size())
	quit(0)
