class_name TerrainBuilder
extends RefCounted

## Builds renderable 3D from a LocationData height grid.
## World scale: 1 unit = 4 m (OsmFetcher.WORLD_SCALE 0.25), applied to
## heights as well as footprints so buildings keep real proportions.
## Visual target: visual-plan/PRD.md (warm low-poly city/nature panorama).

const WORLD_SIZE := 220.0
const METRES_TO_WORLD := 0.25
## Fallback cap when data carries no preset; RenderSettings owns the
## per-preset building/tree budgets actually used below.
const MAX_REAL_BUILDINGS := 340
const LANDMARK_POS := Vector2(18, -14)

static var _facade_mats: Array = []
static var _leaf_mats_by_season: Dictionary = {}
static var _unit_box: BoxMesh

static func _range_of(values: PackedFloat32Array) -> Vector2:
	var mn := INF
	var mx := -INF
	for v in values:
		mn = minf(mn, v)
		mx = maxf(mx, v)
	return Vector2(mn, mx)

static func _polys(data: LocationData, classes: Array) -> Array:
	var out: Array = []
	for poly in data.land_polygons:
		if str(poly.get("class", "")) in classes:
			out.append(poly["points"])
	return out

static func _colored_mesh(verts: PackedVector3Array, normals: PackedVector3Array,
		colors: PackedColorArray, indices: PackedInt32Array,
		roughness: float = 1.0, cull_disabled: bool = false,
		uvs: PackedVector2Array = PackedVector2Array(),
		tex: Texture2D = null) -> MeshInstance3D:
	if normals.is_empty():
		for i in verts.size():
			normals.append(Vector3.UP)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	if not uvs.is_empty():
		arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	if tex != null:
		# Imagery carries the albedo; vertex colour becomes a slope
		# shade multiplied over it (see _terrain_mesh).
		mat.albedo_texture = tex
	mat.roughness = roughness
	if cull_disabled:
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _add(null, mesh, mat)

static func _cyl(top_r: float, bottom_r: float, height: float, segments: int = 8) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top_r
	c.bottom_radius = bottom_r
	c.height = height
	c.radial_segments = segments
	return c

static func _add(parent: Node, mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	if parent != null:
		parent.add_child(mi)
	return mi

static func _box_mesh() -> BoxMesh:
	if _unit_box == null:
		_unit_box = BoxMesh.new()
		_unit_box.size = Vector3.ONE
	return _unit_box

static func build_world(data: LocationData) -> Node3D:
	var root := Node3D.new()
	root.name = "GeneratedWorld"
	root.add_child(_far_ground(data))
	root.add_child(_far_terrain(data))
	root.add_child(_terrain_mesh(data))
	root.add_child(_water(data))
	if data.buildings.is_empty():
		_buildings(root, data)
	else:
		_real_buildings(root, data)
		_roads(root, data)
		_city_silhouette(root, data)
	if data.landmark_type != "none":
		root.add_child(_landmark(data))
	_vegetation(root, data)
	return root

static func _mat(color: Color, roughness: float = 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

static func _hash(x: float, z: float) -> float:
	return fmod(absf(sin(x * 12.9898 + z * 78.233) * 43758.5453), 1.0)

# --- Shared facade materials: window-grid texture tinted per material,
# so hundreds of buildings cost a handful of materials, not hundreds.

static func _facades() -> Array:
	if not _facade_mats.is_empty():
		return _facade_mats
	var img := Image.create(96, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.96, 0.95, 0.92))
	for floor_i in 8:
		for col in 8:
			var shade := 0.36 + _hash(col * 3.1, floor_i * 7.7) * 0.20
			var win := Color(shade, shade + 0.04, shade + 0.10)
			if _hash(col * 9.3, floor_i * 3.9) > 0.92:
				win = Color(0.80, 0.62, 0.36)  # a few lit windows
			img.fill_rect(Rect2i(6 + col * 11, 8 + floor_i * 14, 7, 9), win)
	img.fill_rect(Rect2i(0, 120, 96, 8), Color(0.55, 0.52, 0.48))  # ground floor
	var tex := ImageTexture.create_from_image(img)
	for tint in [Color(0.92, 0.87, 0.74), Color(0.86, 0.78, 0.64), Color(0.89, 0.80, 0.71)]:
		var m := StandardMaterial3D.new()
		m.albedo_texture = tex
		m.albedo_color = tint
		m.roughness = 0.92
		_facade_mats.append(m)
	return _facade_mats

static func _leaves(season: int = LocationData.Season.SUMMER) -> Array:
	var key := LocationData.clamp_season(season)
	if _leaf_mats_by_season.has(key):
		return _leaf_mats_by_season[key]
	var palettes: Array = [
		[Color(0.38, 0.55, 0.30), Color(0.45, 0.60, 0.33), Color(0.32, 0.48, 0.27)],  # spring
		[Color(0.30, 0.45, 0.26), Color(0.36, 0.50, 0.28), Color(0.24, 0.38, 0.22)],  # summer
		[Color(0.72, 0.42, 0.20), Color(0.65, 0.35, 0.16), Color(0.55, 0.45, 0.20)],  # autumn
		[Color(0.35, 0.30, 0.24), Color(0.30, 0.36, 0.24), Color(0.38, 0.33, 0.26)],  # winter
	]
	var mats: Array = []
	for c in palettes[key]:
		mats.append(_mat(c, 0.9))
	_leaf_mats_by_season[key] = mats
	return mats

## The one ground truth for the whole world: raw heights smoothed,
## flattened in low-relief cities, and carved under water polygons.
## Mesh, buildings, roads, trees, and landmarks all sample this.
static func _heights(data: LocationData) -> PackedFloat32Array:
	var size := data.grid_size
	if data.display_heights.size() == size * size:
		return data.display_heights
	var raw_range := _range_of(data.heights)
	var hs := PackedFloat32Array()
	hs.resize(size * size)
	for z in size:
		for x in size:
			var sum := data.height_at(x, z) * 2.0
			var n := 2.0
			for dz in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					if dx == 0 and dz == 0:
						continue
					sum += data.height_at(x + dx, z + dz)
					n += 1.0
			hs[z * size + x] = sum / n
	if raw_range.y - raw_range.x < 20.0:
		# Low-relief places (cities) should read flat, not as dunes.
		var centre_h := data.height_at(size / 2, size / 2)
		for i in hs.size():
			hs[i] = lerpf(hs[i], centre_h, 0.45)
	var step := WORLD_SIZE / float(size - 1)
	for pts in _polys(data, ["water"]):
		for z in size:
			for x in size:
				var wx := (x - size / 2.0) * step
				var wz := (z - size / 2.0) * step
				if point_in_polygon(Vector2(wx, wz), pts):
					hs[z * size + x] = minf(hs[z * size + x], data.water_level + 0.35)
	data.display_heights = hs
	return hs

## World XZ -> satellite mosaic UV. World units are metres x 0.25
## with north as -Z (OsmFetcher.local_xz), so the same linear map
## that places buildings also addresses the imagery under them.
static func satellite_uv(data: LocationData, wx: float, wz: float) -> Vector2:
	var east_m := wx / METRES_TO_WORLD
	var north_m := -wz / METRES_TO_WORLD
	var lat := data.latitude + north_m / 110540.0
	var lon := data.longitude + east_m / (111320.0 * cos(deg_to_rad(data.latitude)))
	var px := TileFetcher.global_pixel(lat, lon, data.satellite_zoom)
	var mosaic_px := float(SatelliteFetcher.TILE_PX * SatelliteFetcher.SPAN)
	return (px - data.satellite_origin_px) / mosaic_px

static func _terrain_mesh(data: LocationData) -> MeshInstance3D:
	var size := data.grid_size
	var step := WORLD_SIZE / float(size - 1)
	var hs := _heights(data)
	var rng := _range_of(hs)
	var mn := rng.x
	var mx := rng.y
	var relief := mx - mn
	var urban := not data.buildings.is_empty()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var uvs := PackedVector2Array()
	var has_sat := data.satellite_texture != null
	var grass := Color(0.45, 0.58, 0.36)
	var dry := Color(0.70, 0.63, 0.45)
	var rock := Color(0.48, 0.46, 0.43)
	var urban_ground := Color(0.62, 0.59, 0.53)
	if data.season == LocationData.Season.AUTUMN:
		grass = Color(0.55, 0.52, 0.30)
	elif data.season == LocationData.Season.WINTER:
		grass = Color(0.60, 0.62, 0.55)
	elif data.season == LocationData.Season.SPRING:
		grass = Color(0.48, 0.62, 0.36)
	for z in size:
		for x in size:
			var h := hs[z * size + x]
			var wx := (x - size / 2.0) * step
			var wz := (z - size / 2.0) * step
			verts.append(Vector3(wx, h, wz))
			var hx0 := hs[z * size + maxi(x - 1, 0)]
			var hx1 := hs[z * size + mini(x + 1, size - 1)]
			var hz0 := hs[maxi(z - 1, 0) * size + x]
			var hz1 := hs[mini(z + 1, size - 1) * size + x]
			var slope_x := (hx1 - hx0) / (2.0 * step)
			var slope_z := (hz1 - hz0) / (2.0 * step)
			var normal := Vector3(-slope_x, 1.0, -slope_z).normalized()
			normals.append(normal)
			var t := clampf((h - mn) / maxf(mx - mn, 0.001), 0.0, 1.0)
			var base_color := grass.lerp(dry, clampf(t * 1.4, 0.0, 1.0))
			if t > 0.72:
				base_color = dry.lerp(rock, (t - 0.72) / 0.28)
			var steep := clampf(1.0 - normal.y, 0.0, 1.0) * 3.2
			base_color = base_color.lerp(rock, clampf(steep, 0.0, 0.75))
			if relief > 22.0 and t > 0.84 and steep < 0.35:
				base_color = base_color.lerp(Color(0.90, 0.91, 0.92), 0.6)  # alpine tops only
			elif data.season == LocationData.Season.WINTER \
					and relief > 8.0 and t > 0.50 and steep < 0.40:
				base_color = base_color.lerp(Color(0.88, 0.89, 0.90), 0.55)  # winter snow line
			# Settled ground reads as warm pavement, never bleached:
			# real OSM cities, and any low-relief place in real metres
			# (its procedural dressing is a town too). Alpine valleys
			# keep meadow green even where the floor is flat.
			if urban or data.relief_metres < 120.0:
				base_color = urban_ground.lerp(grass, _hash(x * 0.7, z * 0.7) * 0.25)
			var shade := 0.92 + _hash(x * 1.3, z * 1.7) * 0.14
			# Ground albedo runs dark: sun + sky ambient would otherwise
			# wash mid-tones to near-white at noon (PRD: never bleached).
			base_color = Color(base_color.r * shade * 0.78,
				base_color.g * shade * 0.78, base_color.b * shade * 0.78)
			if has_sat:
				# Imagery is the albedo; vertex colour is only a slope
				# shade so relief still reads under the photograph.
				uvs.append(satellite_uv(data, wx, wz))
				var s := 0.76 + 0.26 * normal.y
				colors.append(Color(s, s, s))
			else:
				var ground_col := land_color(Vector2(wx, wz), data.land_polygons, base_color)
				if ground_col != base_color:  # polygon colour: same darkening
					ground_col = Color(ground_col.r * 0.78, ground_col.g * 0.78, ground_col.b * 0.78)
				colors.append(ground_col)
	for z in size - 1:
		for x in size - 1:
			var a := z * size + x
			var b := a + 1
			var c := a + size
			var d := c + 1
			indices.append_array([a, b, c, b, d, c])
	return _colored_mesh(verts, normals, colors, indices, 0.97, false,
		uvs, data.satellite_texture)

static func _far_ground(data: LocationData) -> MeshInstance3D:
	# A broad, fog-tinted apron so the terrain disc never ends in void.
	var size := data.grid_size
	var hs := _heights(data)
	var edge_sum := 0.0
	var edge_n := 0
	for i in size:
		edge_sum += hs[i] + hs[(size - 1) * size + i] \
			+ hs[i * size] + hs[i * size + size - 1]
		edge_n += 4
	var plane := PlaneMesh.new()
	plane.size = Vector2(3200, 3200)
	var mi := _add(null, plane, _mat(Color(0.47, 0.52, 0.38), 1.0))
	# Buried well under the far mesh so it only fills pinhole gaps;
	# at edge height it read as a flat bleached ring past the town.
	mi.position.y = edge_sum / maxf(float(edge_n), 1.0) - 2.4
	return mi

static func _far_terrain(data: LocationData) -> MeshInstance3D:
	# Real backdrop terrain from the zoom-8 DEM (LocationData.far_*),
	# converted with the detailed grid's centre/scale so the meshes
	# align. Two distance tricks keep the seam invisible: the far mesh
	# is buried near the viewpoint (the detailed terrain covers it) and
	# relief is progressively exaggerated with distance, so real Alps
	# read as Alps at 5 km instead of ripples. Without far data there
	# is only the flat apron from _far_ground.
	var grid := data.far_grid_size
	if data.far_heights.size() != grid * grid:
		return MeshInstance3D.new()
	var extent := data.far_extent
	var step := extent / float(grid - 1)
	var offset := Vector3((0.5 - data.far_centre_frac.x) * extent, -2.2,
		(0.5 - data.far_centre_frac.y) * extent)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var grass := Color(0.42, 0.52, 0.33)
	var dry := Color(0.62, 0.56, 0.40)
	var rock := Color(0.46, 0.44, 0.41)
	for z in grid:
		for x in grid:
			var wx := (float(x) - float(grid - 1) / 2.0) * step
			var wz := (float(z) - float(grid - 1) / 2.0) * step
			var world := Vector3(wx, 0, wz) + offset
			var dist := Vector2(world.x, world.z).length()
			var boost := 1.0 + 1.9 * smoothstep(300.0, 1600.0, dist)
			var bury := lerpf(16.0, 0.0, smoothstep(160.0, 520.0, dist))
			var h := 3.0 + (data.far_heights[z * grid + x] - 3.0) * boost - bury
			verts.append(Vector3(wx, h, wz))
			var hx0 := data.far_heights[z * grid + maxi(x - 1, 0)]
			var hx1 := data.far_heights[z * grid + mini(x + 1, grid - 1)]
			var hz0 := data.far_heights[maxi(z - 1, 0) * grid + x]
			var hz1 := data.far_heights[mini(z + 1, grid - 1) * grid + x]
			var normal := Vector3(-(hx1 - hx0) / (2.0 * step), 1.0,
				-(hz1 - hz0) / (2.0 * step)).normalized()
			normals.append(normal)
			var above := h - 3.0
			var c := grass.lerp(dry, clampf(above / 60.0, 0.0, 1.0))
			c = c.lerp(rock, clampf((1.0 - normal.y) * 3.0 + above / 160.0, 0.0, 0.8))
			if above > 95.0 and normal.y > 0.75:
				c = c.lerp(Color(0.90, 0.91, 0.92), 0.6)
			if h < data.water_level + 1.0:
				c = Color(0.35, 0.48, 0.52)  # distant lakes read as water
			var fshade := 0.92 + _hash(x * 1.3, z * 1.7) * 0.14
			colors.append(Color(c.r * fshade, c.g * fshade, c.b * fshade))
	for z in grid - 1:
		for x in grid - 1:
			var a := z * grid + x
			var b := a + 1
			var c := a + grid
			var d := c + 1
			indices.append_array([a, b, c, b, d, c])
	var mi := _colored_mesh(verts, normals, colors, indices, 1.0)
	mi.position = offset
	return mi

static func point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	var inside := false
	var j := polygon.size() - 1
	for i in polygon.size():
		var pi := polygon[i]
		var pj := polygon[j]
		if (pi.y > point.y) != (pj.y > point.y) \
				and point.x < (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y) + pi.x:
			inside = not inside
		j = i
	return inside

static func land_color(point: Vector2, land: Array, fallback: Color) -> Color:
	for poly in land:
		if point_in_polygon(point, poly["points"]):
			match str(poly["class"]):
				"water": return Color(0.30, 0.50, 0.60)
				"forest": return Color(0.27, 0.41, 0.25)
				"grass": return Color(0.47, 0.60, 0.37)
				"field": return Color(0.70, 0.63, 0.43)
				"urban": return Color(0.64, 0.61, 0.55)
	return fallback

static func _water(data: LocationData) -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = Vector2(WORLD_SIZE, WORLD_SIZE)
	var m := _mat(Color(0.16, 0.36, 0.48, 0.94), 0.16)
	m.metallic = 0.08
	var mi := _add(null, plane, m)
	mi.position.y = data.water_level
	return mi

static func _box_mat(root: Node3D, pos: Vector3, scl: Vector3, mat: Material) -> void:
	var mi := _add(root, _box_mesh(), mat)
	mi.position = pos
	mi.scale = scl

static func _box(root: Node3D, pos: Vector3, scl: Vector3, color: Color) -> void:
	_box_mat(root, pos, scl, _mat(color))

static func _mansard(root: Node3D, cx: float, base_y: float, cz: float,
		size_x: float, size_z: float, roof_h: float, seed_v: float) -> void:
	var slate := Color(0.21, 0.24, 0.30).lerp(Color(0.30, 0.33, 0.38), seed_v)
	var mi := _add(root, _cyl(0.52, 1.0, 1.0, 4), _mat(slate, 0.85))
	mi.rotation.y = PI / 4.0
	mi.position = Vector3(cx, base_y + roof_h / 2.0, cz)
	mi.scale = Vector3(size_x * 0.48, roof_h, size_z * 0.48)

static func _building(root: Node3D, pos: Vector3, size_x: float, size_z: float,
		height_world: float, seed_v: float) -> void:
	var facades := _facades()
	_box_mat(root, pos + Vector3(0, height_world / 2.0, 0),
		Vector3(size_x, height_world, size_z),
		facades[int(seed_v * 2.99) % facades.size()])
	var roof_h := clampf(minf(size_x, size_z) * 0.22, 0.7, 2.0)
	_mansard(root, pos.x, pos.y + height_world, pos.z, size_x, size_z, roof_h, seed_v)

static func _buildings(root: Node3D, data: LocationData) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = data.seed_value + 7
	for i in RenderSettings.procedural_buildings_for(data.quality_preset):
		var angle := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(38.0, 98.0)
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		var ground := _ground_at(data, pos.x, pos.z)
		if ground < data.water_level + 0.5:
			continue
		pos.y = ground - 0.25
		_building(root, pos, rng.randf_range(4.5, 8.0), rng.randf_range(4.5, 8.0),
			rng.randf_range(3.2, 6.2), rng.randf())

static func _ground_at(data: LocationData, world_x: float, world_z: float) -> float:
	var hs := _heights(data)
	var size := data.grid_size
	var gx := clampi(int((world_x / WORLD_SIZE + 0.5) * float(size)), 0, size - 1)
	var gz := clampi(int((world_z / WORLD_SIZE + 0.5) * float(size)), 0, size - 1)
	return hs[gz * size + gx]

static func _real_buildings(root: Node3D, data: LocationData) -> void:
	var sorted := data.buildings.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (float(a["x"]) ** 2 + float(a["z"]) ** 2) \
			< (float(b["x"]) ** 2 + float(b["z"]) ** 2))
	var placed := 0
	var cap := RenderSettings.max_buildings_for(data.quality_preset)
	# The landmark's own OSM footprint (e.g. the cathedral as one beige
	# box) must not duplicate the procedural landmark model.
	var site := landmark_site_xz(data)
	for b in sorted:
		if placed >= cap:
			break
		var pos := Vector3(float(b["x"]), 0, float(b["z"]))
		if data.landmark_type != "none" \
				and Vector2(pos.x, pos.z).distance_to(site) < 17.0:
			continue
		if absf(pos.x) > 105.0 or absf(pos.z) > 105.0:
			continue
		pos.y = _ground_at(data, pos.x, pos.z) - 0.6
		var height_world := clampf(float(b["height"]) * METRES_TO_WORLD, 1.8, 19.0)
		_building(root, pos, float(b["size_x"]), float(b["size_z"]),
			height_world, _hash(pos.x, pos.z))
		placed += 1

static func _city_silhouette(root: Node3D, data: LocationData) -> void:
	# Hazy low blocks beyond the detailed area, so a city reaches the
	# horizon instead of stopping at the terrain edge.
	var rng := RandomNumberGenerator.new()
	rng.seed = data.seed_value + 99
	var haze := _mat(Color(0.58, 0.59, 0.56), 1.0)
	var silhouette_count := RenderSettings.silhouette_count_for(data.quality_preset)
	for i in silhouette_count:
		var angle := TAU * float(i) / float(silhouette_count) + rng.randf_range(-0.05, 0.05)
		var dist := rng.randf_range(125.0, 195.0)
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		pos.y = _ground_at(data, clampf(pos.x, -108.0, 108.0), clampf(pos.z, -108.0, 108.0)) - 0.5
		_box_mat(root, pos + Vector3(0, rng.randf_range(2.0, 4.5), 0),
			Vector3(rng.randf_range(9, 18), rng.randf_range(4.0, 9.0), rng.randf_range(9, 18)), haze)

static func _roads(root: Node3D, data: LocationData) -> void:
	var asphalt := _mat(Color(0.31, 0.31, 0.32), 0.98)
	var water_polys := _polys(data, ["water"])
	for line in data.roads:
		var pts: PackedVector2Array = line
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var mid := (a + b) / 2.0
			if absf(mid.x) > 108.0 or absf(mid.y) > 108.0:
				continue
			var seg := _add(root, _box_mesh(), asphalt)
			var length := a.distance_to(b)
			seg.scale = Vector3(length, 0.06, 1.7)
			var y := _ground_at(data, mid.x, mid.y) + 0.08
			for wp in water_polys:
				if point_in_polygon(mid, wp):
					y = data.water_level + 1.1  # bridge deck over the channel
					break
			seg.position = Vector3(mid.x, y, mid.y)
			seg.rotation.y = -atan2(b.y - a.y, b.x - a.x)

## True offset (world XZ) of the landmark's real site from the
## viewpoint, before clamping. Falls back to the fixed offset when
## the data carries no site (older tests, hand-built LocationData).
static func landmark_site_xz(data: LocationData) -> Vector2:
	if data.has_landmark_site:
		return OsmFetcher.local_xz(data.landmark_lat, data.landmark_lon,
			data.latitude, data.longitude)
	return LANDMARK_POS

## Where the model actually stands: the true bearing from the
## viewpoint, clamped into the detailed terrain (<=95 units) and
## pushed out to reading distance when the viewpoint is at (or very
## near) the site itself, so the camera never starts inside the
## model or underneath a tower that fills the whole frame.
static func landmark_world_pos(data: LocationData) -> Vector2:
	var xz := landmark_site_xz(data)
	var len := xz.length()
	if len > 95.0:
		return xz / len * 95.0
	if len < 34.0:
		var dir := xz / len if len > 0.5 else LANDMARK_POS.normalized()
		return dir * 38.0
	return xz

static func _landmark(data: LocationData) -> Node3D:
	var pos := landmark_world_pos(data)
	var root := LandmarkBuilder.build(data.landmark_type)
	root.position = Vector3(pos.x, _ground_at(data, pos.x, pos.y) - 0.3, pos.y)
	return root

static func _beam(parent: Node3D, from: Vector3, to: Vector3, radius: float, mat: Material) -> void:
	var mi := _add(parent, _cyl(radius * 0.8, radius, 1.0, 6), mat)
	var dir := to - from
	var length := dir.length()
	var y_axis := dir / length
	var x_axis := Vector3.UP.cross(y_axis).normalized()
	if x_axis.length() < 0.01:
		x_axis = Vector3.RIGHT
	var z_axis := x_axis.cross(y_axis).normalized()
	x_axis = y_axis.cross(z_axis).normalized()
	mi.transform = Transform3D(
		Basis(x_axis * radius, y_axis * length, z_axis * radius),
		(from + to) / 2.0)

static func _random_pos(rng: RandomNumberGenerator) -> Vector3:
	var angle := rng.randf_range(0.0, TAU)
	var dist := rng.randf_range(15.0, 102.0)
	return Vector3(cos(angle) * dist, 0, sin(angle) * dist)

static func _broadleaf(root: Node3D, pos: Vector3, rng: RandomNumberGenerator,
		leaves: Array, trunk_mat: Material) -> void:
	var trunk := _add(root, _cyl(0.10, 0.16, 1.1, 6), trunk_mat)
	trunk.position = pos + Vector3(0, 0.55, 0)
	var sphere := SphereMesh.new()
	sphere.radial_segments = 8
	sphere.rings = 5
	sphere.radius = 1.0
	sphere.height = 1.6
	var canopy := _add(root, sphere, leaves[rng.randi_range(0, leaves.size() - 1)])
	var r := rng.randf_range(0.9, 1.5)
	canopy.scale = Vector3(r, r * 0.82, r)
	canopy.position = pos + Vector3(0, 1.1 + r * 0.75, 0)

static func _pine(root: Node3D, pos: Vector3, rng: RandomNumberGenerator, leaves: Array) -> void:
	var h := rng.randf_range(3.2, 5.4)
	var tree := _add(root, _cyl(0.08, rng.randf_range(0.9, 1.5), h, 8),
		leaves[rng.randi_range(0, leaves.size() - 1)])
	tree.position = pos + Vector3(0, h / 2.0, 0)

static func _vegetation(root: Node3D, data: LocationData) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = data.seed_value + 21
	var leaves := _leaves(data.season)
	var trunk_mat := _mat(Color(0.36, 0.28, 0.20), 0.95)
	var urban := not data.buildings.is_empty() or data.relief_metres < 120.0
	var green_polys := _polys(data, ["forest", "grass"])
	var count := RenderSettings.vegetation_count_for(data.quality_preset, urban)
	for i in count:
		var pos := _random_pos(rng)
		# Prefer parks and forests: resample a couple of times to land
		# inside green land cover when the place has any.
		for attempt in 3:
			var inside_green := false
			for gp in green_polys:
				if point_in_polygon(Vector2(pos.x, pos.z), gp):
					inside_green = true
					break
			if inside_green or green_polys.is_empty():
				break
			if attempt == 2 and rng.randf() > 0.35:
				pos = Vector3(9999, 0, 9999)  # skip: cities keep trees in green areas
				break
			pos = _random_pos(rng)
		if absf(pos.x) > 200.0:
			continue
		if data.landmark_type != "none" and Vector2(pos.x, pos.z).distance_to(
				landmark_world_pos(data)) < 12.0:
			continue  # keep the landmark's clearing free of trees
		var ground := _ground_at(data, pos.x, pos.z)
		if ground < data.water_level + 0.4:
			continue
		if urban and _near_building(data, pos):
			continue
		pos.y = ground
		# Cities get street broadleafs; pines belong to the hills.
		if rng.randf() < (0.85 if urban else 0.50):
			_broadleaf(root, pos, rng, leaves, trunk_mat)
		else:
			_pine(root, pos, rng, leaves)

static func _near_building(data: LocationData, pos: Vector3) -> bool:
	for b in data.buildings:
		var dx := pos.x - float(b["x"])
		var dz := pos.z - float(b["z"])
		var reach := maxf(float(b["size_x"]), float(b["size_z"])) * 0.5 + 1.6
		if dx * dx + dz * dz < reach * reach:
			return true
	return false
