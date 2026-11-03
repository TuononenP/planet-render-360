extends SceneTree

## Landmark model capture (visual quality plan, L-1.2 first step). Windowed,
## off-screen, never on top:
##   tools/godot_bg.sh --path . --script tools/capture_landmarks.gd --position 4000,4000 \
##     -- [--types=hoover_dam,eiffel] [--all] [--tag=name] [--plain] [--night]
##
## Builds each landmark as the Ultra desktop path does (LandmarkShader, and
## LandmarkLights with --night) on a flat ground disc at y = 0, and shoots
## it from four bearings (front, two quarter views, back) at a distance
## fitted to its size. Output, in visual-plan/captures/<tag>/:
##   <type>_sheet.jpg   the four views tiled 2 x 2
##   stats.tsv          type, width, depth, height, lowest y, triangles
## A registry `base_drop_m` lifts the model as TerrainBuilder._hero_y does.
## The ground disc is not the real terrain: heroes stand on the lowest
## ground of their site, so use this for the model itself (silhouette,
## detail, anything below y = 0 shows as buried under the disc).
## --plain skips the weathering shader (the High-tier look).

const VIEW := Vector2i(640, 400)
const SETTLE_FRAMES := 90
const BEARINGS_DEG := [0.0, 40.0, 130.0, 180.0]
const ELEVATION_DEG := 14.0
const DEFAULT_TYPES := ["eiffel", "statue_liberty", "hoover_dam", "edinburgh_castle", "mont_saint_michel",
	"stockholm_city_hall", "tower_bridge", "sydney_opera"]

var _types: Array = DEFAULT_TYPES
var _plain := false
var _night := false
var _tag := "landmarks"

func _init() -> void:
	_run()

func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--types="):
			_types = a.substr(8).split(",")
		elif a == "--all":
			_types = []
			for e in LocationData.landmarks():
				_types.append(str(e["type"]))
		elif a.begins_with("--tag="):
			_tag = a.substr(6)
		elif a == "--plain":
			_plain = true
		elif a == "--night":
			_night = true
	var out := ProjectSettings.globalize_path("res://visual-plan/captures/%s" % _tag)
	DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var vp := SubViewport.new()
	vp.size = VIEW
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var cam := Camera3D.new()
	cam.fov = 40.0
	vp.add_child(cam)
	vp.add_child(_environment())
	var stats := PackedStringArray(["type\twidth_m\tdepth_m\theight_m\tlowest_y_m\ttriangles"])
	for t in _types:
		var hero := LandmarkBuilder.build(str(t))
		var box := _extent(hero)
		var aabb: AABB = box[0]
		if not _plain:
			LandmarkShader.upgrade(hero)
		if _night:
			LandmarkLights.dress(hero, str(t))
		var ground := _ground(maxf(aabb.size.x, aabb.size.z))
		vp.add_child(ground)
		vp.add_child(hero)
		hero.position.y = float(LocationData.entry_for_type(str(t)).get("base_drop_m", 0.0)) * WorldScale.metres_to_units()
		var sheet := Image.create(VIEW.x * 2, VIEW.y * 2, false, Image.FORMAT_RGB8)
		var u := WorldScale.metres_to_units()
		var centre := Vector3(aabb.get_center().x, aabb.size.y * 0.4 + aabb.position.y * 0.0, aabb.get_center().z) * u
		var dist := maxf(aabb.size.length() * 0.9, 12.0) * u
		for i in BEARINGS_DEG.size():
			var b := deg_to_rad(float(BEARINGS_DEG[i]))
			var el := deg_to_rad(ELEVATION_DEG)
			cam.near = maxf(dist * 0.01, 0.05)
			cam.far = dist * 40.0
			cam.look_at_from_position(centre + Vector3(sin(b) * cos(el), sin(el), cos(b) * cos(el)) * dist, centre)
			for f in SETTLE_FRAMES if i == 0 else 8:
				await process_frame
				RenderingServer.force_draw(false)
			var img := vp.get_texture().get_image()
			img.convert(Image.FORMAT_RGB8)
			sheet.blit_rect(img, Rect2i(Vector2i.ZERO, VIEW), Vector2i((i % 2) * VIEW.x, (i / 2) * VIEW.y))
		sheet.save_jpg(out.path_join("%s_sheet.jpg" % t), 0.88)
		stats.append("%s\t%.1f\t%.1f\t%.1f\t%.2f\t%d" % [t, aabb.size.x, aabb.size.z, aabb.end.y,
			aabb.position.y, int(box[1])])
		print("CAPTURED ", t)
		vp.remove_child(hero)
		vp.remove_child(ground)
		hero.free()
		ground.free()
	var f := FileAccess.open(out.path_join("stats.tsv"), FileAccess.WRITE)
	f.store_string("\n".join(stats) + "\n")
	f.close()
	print("CAPTURES DONE -> ", out)
	quit(0)

## [AABB in metres across all parts, triangle count].
func _extent(hero: Node3D) -> Array:
	var box := AABB()
	var first := true
	var tris := 0
	for m in LandmarkBuilder.parts(hero):
		var b: AABB = m.transform * m.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
		tris += m.mesh.surface_get_array_len(0) / 3
	return [box, tris]

func _ground(span_m: float) -> MeshInstance3D:
	var disc := CylinderMesh.new()
	var r := maxf(span_m * 2.5, 60.0) * WorldScale.metres_to_units()
	disc.top_radius = r
	disc.bottom_radius = r
	disc.height = 0.02
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.38, 0.24)
	mat.roughness = 1.0
	disc.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = disc
	mi.position.y = -0.01
	return mi

func _environment() -> Node3D:
	var n := Node3D.new()
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	if _night:
		(sky.sky_material as ProceduralSkyMaterial).sky_top_color = Color(0.02, 0.03, 0.08)
		(sky.sky_material as ProceduralSkyMaterial).sky_horizon_color = Color(0.06, 0.07, 0.12)
		env.ambient_light_energy = 0.3
	var we := WorldEnvironment.new()
	we.environment = env
	n.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35.0, 35.0, 0.0)
	sun.light_energy = 0.15 if _night else 1.3
	sun.shadow_enabled = true
	n.add_child(sun)
	return n
