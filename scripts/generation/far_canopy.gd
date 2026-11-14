class_name FarCanopy
extends RefCounted

## Tree crowns past the detailed extent, from the far imagery drape. The
## A 100 m cell is green when SettlementMap calls it vegetation (greener
## than the scene's typical cell), or when it is not water, greener than
## grey by CELL_GREEN and under PARK_SCORE built: a large park's shadowed
## canopy reads busy and only mildly green, so SettlementMap scores it
## 0.2-0.55 built (Central Park from Midtown: 75 of its 672 cells passed
## the stricter test), while Manhattan's real blocks score 0.75 and up.
## Inside such a cell every probe whose pixel is darker than
## the canopy threshold is tree canopy and gets a crown in the photo's own
## colour. The threshold is the brighter of the scene's median cell (crowns
## read darker than the city round them; SettlementMap's Paris calibration:
## forest L 0.28 against a 0.33 median) and the vegetation cells' VEG_SHARE
## quantile (a park's canopy is the darker part of its own green, its
## sunlit lawns and meadows the lighter part, and those stay open). Probes
## thin with distance (STEPS_M) and their crowns widen to match. A distant park reads as a wood with its open
## lawns (Central Park's Sheep Meadow and Great Lawn from Midtown) instead
## of a flat green drape. Nearest cells first, up to a per-preset budget;
## one MultiMesh per FarCityBuilder distance band, tagged "FarCity" with
## far_r0 so LodRing shows the bands the preset reaches.

## Probe spacing (m) by distance: [from_m, step_m], nearest first.
const STEPS_M := [[0.0, 11.0], [3000.0, 16.0], [5000.0, 22.0]]
## Crowns per preset (FAST, BALANCED, HIGH, ULTRA) and their reach.
const MAX_CROWNS: Array[int] = [0, 15000, 40000, 80000]
const REACH_M: Array[float] = [0.0, 2500.0, 4500.0, 7500.0]
## A probe is canopy when its luminance is under this share of the
## scene's median cell luminance, and greener than grey by MIN_GREEN.
const DARK_SHARE := 1.0
const CELL_GREEN := 0.035
const PARK_SCORE := 0.6
const VEG_SHARE := 0.6
const MIN_GREEN := 0.02
## Crown height and radius ranges (m) and the bare trunk under it.
const CROWN_H := Vector2(7.0, 15.0)
const CROWN_R := Vector2(3.5, 6.5)
const TRUNK_M := 2.5

static var _mesh: ArrayMesh
static var _mutex := Mutex.new()

static func build(root: Node3D, data: LocationData, ground: GroundTruth, smap: SettlementMap) -> int:
	var t0 := Time.get_ticks_msec()
	var crowns := plan(data, ground, smap)
	if crowns.is_empty():
		return 0
	var bands: Array = []
	for b in FarCityBuilder.BANDS.size():
		bands.append([])
	for c in crowns:
		var at: Vector3 = (c as Array)[0]
		(bands[_band(Vector2(at.x, at.z).length())] as Array).append(c)
	var meshes := 0
	for b in bands.size():
		if not (bands[b] as Array).is_empty():
			root.add_child(_instances(bands[b], FarCityBuilder.BANDS[b]))
			meshes += 1
	print("FAR-CANOPY %d crowns in %d meshes in %d ms" % [crowns.size(), meshes, Time.get_ticks_msec() - t0])
	return crowns.size()

## The crowns to plant: [base (trunk top), scale (r, h, r), colour] each,
## nearest first, at most the preset's budget.
static func plan(data: LocationData, ground: GroundTruth, smap: SettlementMap) -> Array:
	var out: Array = []
	var preset := clampi(data.quality_preset, 0, MAX_CROWNS.size() - 1)
	var budget := MAX_CROWNS[preset]
	if budget == 0 or smap == null or smap.is_empty() or data.far_drapes.is_empty():
		return out
	var bytes := SettlementMap.drape_bytes(data)
	var cells := _vegetation_cells(data, bytes, smap, REACH_M[preset])
	if cells.is_empty():
		return out
	var dark := maxf(scene_luminance(data, bytes, smap, REACH_M[preset]) * DARK_SHARE,
		_quantile(data, bytes, cells, VEG_SHARE))
	var far_ok := data.far_grid_size >= 2 and data.far_heights.size() == data.far_grid_size * data.far_grid_size
	var surf := FarTerrainBuilder._surface(data) if far_ok else {}
	var winter := data.season == LocationData.Season.WINTER
	for c in cells:
		var centre: Vector2 = c[0]
		var step := step_at(float(c[1]))
		var per_cell := int(SettlementMap.CELL_M / step)
		var widen := step / float(STEPS_M[0][1])
		for sj in per_cell:
			for si in per_cell:
				if out.size() >= budget:
					return out
				var x := centre.x + (float(si) + 0.5) * step - SettlementMap.CELL_M * 0.5
				var z := centre.y + (float(sj) + 0.5) * step - SettlementMap.CELL_M * 0.5
				x += (_hash(x, z, 1.0) - 0.5) * step * 0.8
				z += (_hash(x, z, 2.0) - 0.5) * step * 0.8
				var px := pixel(data, bytes, x, z)
				if px.a <= 0.0:
					continue
				var l := 0.299 * px.r + 0.587 * px.g + 0.114 * px.b
				if l >= dark or px.g - (px.r + px.b) * 0.5 < MIN_GREEN:
					continue
				var y := FarTerrainBuilder._blend_height(data, ground, surf, x, z) if far_ok \
					else ground.height_at_world(x, z)
				var h := lerpf(CROWN_H.x, CROWN_H.y, _hash(x, z, 3.0))
				var r := lerpf(CROWN_R.x, CROWN_R.y, _hash(x, z, 4.0)) * widen
				out.append([Vector3(x, y + TRUNK_M, z), Vector3(r, h, r), crown_colour(px, winter)])
	return out

## Probe spacing at distance `d`.
static func step_at(d: float) -> float:
	var step := float(STEPS_M[0][1])
	for row in STEPS_M:
		if d >= float(row[0]):
			step = float(row[1])
	return step

## The `share` quantile of the vegetation cells' mean luminance.
static func _quantile(data: LocationData, bytes: Array, cells: Array, share: float) -> float:
	var lums: Array = []
	for k in range(0, cells.size(), maxi(1, cells.size() / 400)):
		var c: Vector2 = cells[k][0]
		var probe := SettlementMap.probe(data, bytes, c.x, c.y, SettlementMap.CELL_M)
		if not probe.is_empty():
			lums.append(float(probe["l"]))
	if lums.is_empty():
		return 0.0
	lums.sort()
	return float(lums[mini(int(float(lums.size()) * share), lums.size() - 1)])

## [centre, distance] of every vegetation cell from the
## extent edge to `reach`, nearest first.
static func _vegetation_cells(data: LocationData, bytes: Array, smap: SettlementMap, reach: float) -> Array:
	var out: Array = []
	var r_in := FarCityBuilder.R_IN
	for j in smap.n:
		for i in smap.n:
			var k := smap.index(i, j)
			var blocked := smap.blocked[k]
			if blocked == 2 or (blocked == 0 and smap.score[k] >= PARK_SCORE):
				continue
			var c := smap.centre(i, j)
			var d := c.length()
			if d < r_in or d > reach:
				continue
			if blocked == 0:
				var probe := SettlementMap.probe(data, bytes, c.x, c.y, SettlementMap.CELL_M)
				if probe.is_empty() or float(probe["g"]) < CELL_GREEN or float(probe["br"]) > 0.03:
					continue
			out.append([c, d])
	out.sort_custom(func(a: Array, b: Array) -> bool: return float(a[1]) < float(b[1]))
	return out

## Median luminance of every third cell (any cover) out to `reach`: the
## scene's typical tone, which canopy is darker than and lawn lighter.
static func scene_luminance(data: LocationData, bytes: Array, smap: SettlementMap, reach: float) -> float:
	var lums: Array = []
	for j in range(0, smap.n, 3):
		for i in range(0, smap.n, 3):
			var c := smap.centre(i, j)
			if c.length() > reach:
				continue
			var probe := SettlementMap.probe(data, bytes, c.x, c.y, SettlementMap.CELL_M)
			if not probe.is_empty():
				lums.append(float(probe["l"]))
	if lums.is_empty():
		return 0.0
	lums.sort()
	return float(lums[lums.size() / 2])

## The finest drape's pixel at metre XZ (alpha 0 where none covers it).
static func pixel(data: LocationData, bytes: Array, x: float, z: float) -> Color:
	for di in data.far_drapes.size():
		var d: Dictionary = data.far_drapes[di]
		var img: Variant = d.get("image", null)
		if not (img is Image) or (bytes[di] as PackedByteArray).is_empty():
			continue
		var uv := FarSurface.drape_uv(data, d, x, z)
		if uv.x <= 0.0 or uv.y <= 0.0 or uv.x >= 1.0 or uv.y >= 1.0:
			continue
		var w := (img as Image).get_width()
		var h := (img as Image).get_height()
		var o := (clampi(int(uv.y * float(h)), 0, h - 1) * w + clampi(int(uv.x * float(w)), 0, w - 1)) * 3
		var buf: PackedByteArray = bytes[di]
		return Color(float(buf[o]) / 255.0, float(buf[o + 1]) / 255.0, float(buf[o + 2]) / 255.0, 1.0)
	return Color(0, 0, 0, 0)

## A crown's colour from its photo pixel, deepened toward green (the photo
## is already sunlit and hazed, and the crown is lit again in the scene, so
## the plain pixel reads pale sage from Midtown), and grey-brown bare twigs
## in winter.
static func crown_colour(px: Color, winter: bool) -> Color:
	if winter:
		return Color(0.30, 0.27, 0.24).lerp(Color(px.r, px.g, px.b), 0.2)
	return Color(px.r * 0.5, px.g * 0.62, px.b * 0.42)

static func _band(r: float) -> int:
	var band := 0
	while band < FarCityBuilder.BANDS.size() - 2 and r >= FarCityBuilder.BANDS[band + 1]:
		band += 1
	return band

static func _instances(list: Array, r0: float) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = crown_mesh()
	mm.instance_count = list.size()
	for k in list.size():
		var t: Array = list[k]
		var s: Vector3 = t[1]
		mm.set_instance_transform(k, Transform3D(Basis.from_scale(s), t[0]))
		mm.set_instance_color(k, t[2])
	var mi := MultiMeshInstance3D.new()
	mi.name = "FarCanopy"
	mi.multimesh = mm
	# The instance colours reach the albedo only through an override
	# material that reads vertex colour (MultiMesh.use_colors).
	mi.material_override = mm.mesh.surface_get_material(0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta("lod_layer", "FarCity")
	mi.set_meta("far_r0", r0)
	return mi

## A unit crown: a faceted ellipsoid 1 m in radius from y 0 to 1, its
## colour from the instance.
static func crown_mesh() -> ArrayMesh:
	_mutex.lock()
	if _mesh == null:
		var prof := PackedVector2Array()
		for i in 4:
			var a := float(i) / 3.0 * PI
			prof.append(Vector2(sin(a), 0.5 - cos(a) * 0.5))
		var lm := LandmarkMesh.new()
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.roughness = 0.95
		lm.use("Crown", mat)
		lm.lathe("Crown", Vector3.ZERO, prof, 6)
		_mesh = lm.to_array_mesh(false)
	var out := _mesh
	_mutex.unlock()
	return out

static func _hash(x: float, z: float, salt: float) -> float:
	return fposmod(sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453, 1.0)
