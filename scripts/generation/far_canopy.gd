class_name FarCanopy
extends RefCounted

## Trees past the detailed extent, from the far imagery drape. A 100 m
## cell is green when SettlementMap calls it vegetation (greener than the
## scene's typical cell), or when it is not water, greener than grey by
## CELL_GREEN and under PARK_SCORE built: a large park's shadowed canopy
## reads busy and only mildly green, so SettlementMap scores it 0.2-0.55
## built (Central Park from Midtown: 75 of its 672 cells passed the stricter
## test), while Manhattan's real blocks score 0.75 and up. Inside such a
## cell every probe whose pixel is darker than the canopy threshold gets a
## tree. The threshold is the brighter of the scene's median cell (crowns
## read darker than the city round them; SettlementMap's Paris calibration:
## forest L 0.28 against a 0.33 median) and the vegetation cells' VEG_SHARE
## quantile (a park's canopy is the darker part of its own green, its sunlit
## lawns and meadows the lighter part, and those stay open). Each tree is
## its species' impostor (the near trees' own crossed cards, from the
## place's park mix or its HeritageZones tree_mix), sized by stand and by
## tree, jittered a full probe step and tinted by its photo pixel, so a
## distant park reads as woodland with its open lawns (Central Park from
## Midtown) instead of a flat green drape. Probes thin with distance
## (STEPS_M) and trees widen to match. Nearest cells first, up to a
## per-preset budget; one MultiMesh per species and FarCityBuilder distance
## band, tagged "FarCity" with far_r0 so LodRing shows the bands the preset
## reaches. Built in the vegetation stage: TreeMeshLibrary's caches are not
## shared across build threads.

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
## Tree size: a low-frequency stand factor (whole groves taller or lower)
## times a per-tree one, so the canopy reads as stands, not a lattice of
## equal balls.
const STAND_SIZE := Vector2(0.75, 1.25)
const TREE_SIZE := Vector2(0.8, 1.2)
## A far tree is its species' impostor (TreeMeshLibrary LOD 2: the near
## trees' own crossed cards), widened with the probe spacing so
## neighbours overlap into one canopy.
const IMPOSTOR_LOD := 2

static func build(root: Node3D, data: LocationData, ground: GroundTruth, smap: SettlementMap) -> int:
	var t0 := Time.get_ticks_msec()
	var crowns := plan(data, ground, smap)
	if crowns.is_empty():
		return 0
	# One MultiMesh per species and distance band.
	var groups := {}
	for c in crowns:
		var at: Vector3 = (c as Array)[0]
		var key := "%s|%d" % [str((c as Array)[3]), _band(Vector2(at.x, at.z).length())]
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(c)
	var meshes := 0
	for key in groups:
		var band := int(str(key).get_slice("|", 1))
		root.add_child(_instances(groups[key], FarCityBuilder.BANDS[band], str(key).get_slice("|", 0), data.season))
		meshes += 1
	print("FAR-CANOPY %d crowns in %d meshes in %d ms" % [crowns.size(), meshes, Time.get_ticks_msec() - t0])
	return crowns.size()

## The trees to plant: [base on the ground, scale (wide, tall, wide),
## colour, species] each, nearest first, at most the preset's budget.
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
	var biome := TreeSpecies.biome_for_data(data)
	var mix := TreeSpecies.mix(biome, "park")
	var zoned := HeritageZones.near(data.latitude, data.longitude, REACH_M[preset])
	var stand := FastNoiseLite.new()
	stand.frequency = 1.0 / 180.0
	stand.seed = 7
	var hits: Dictionary = _probes_native(data, bytes, cells, dark, budget) if _native \
		else _probes_script(data, bytes, cells, dark, budget)
	var xs: PackedFloat64Array = hits["x"]
	var zs: PackedFloat64Array = hits["z"]
	var rgb: PackedFloat32Array = hits["rgb"]
	var widens: PackedFloat64Array = hits["widen"]
	var m2u := WorldScale.metres_to_units()
	var has_wmask := not data.far_water_mask.is_empty()
	for k in xs.size():
		var x := xs[k]
		var z := zs[k]
		if has_wmask and FarWaterMask.sample(data, x * m2u, z * m2u) > FarWaterMask.LAND:
			continue
		var px := Color(rgb[k * 3], rgb[k * 3 + 1], rgb[k * 3 + 2], 1.0)
		var widen := widens[k]
		var y := FarTerrainBuilder._blend_height(data, ground, surf, x, z) if far_ok \
			else ground.height_at_world(x, z)
		var rows := mix
		if zoned:
			var zone_mix := str(HeritageZones.rule_at_xz(data, x, z).get("tree_mix", ""))
			if zone_mix != "":
				rows = TreeSpecies.mix(zone_mix, "park")
		var sp := TreeSpecies.pick(rows, _hash(x, z, 5.0) * 0.999)
		var size := lerpf(STAND_SIZE.x, STAND_SIZE.y, clampf(0.5 + stand.get_noise_2d(x, z) * 0.9, 0.0, 1.0)) \
			* lerpf(TREE_SIZE.x, TREE_SIZE.y, _hash(x, z, 4.0))
		out.append([Vector3(x, y, z), Vector3(size * widen, size, size * widen), crown_colour(px, winter, _hash(x, z, 7.0)), sp])
	return out

## Whether the probe pass runs natively (CanopyKernels); tests turn it off.
static var _native := ClassDB.class_exists("CanopyKernels")

## The probes that find canopy, in cell order, up to `budget`: {x, z:
## PackedFloat64Array, rgb: PackedFloat32Array (the pixel, 3 each), widen:
## PackedFloat64Array (the cell's step against the finest)}. A probe is
## jittered a full step (the second jitter reads the first's x), takes the
## finest drape's pixel and is canopy when darker than `dark` and greener
## than grey by MIN_GREEN.
static func _probes_script(data: LocationData, bytes: Array, cells: Array, dark: float, budget: int) -> Dictionary:
	var xs := PackedFloat64Array()
	var zs := PackedFloat64Array()
	var rgb := PackedFloat32Array()
	var widens := PackedFloat64Array()
	for c in cells:
		var centre: Vector2 = c[0]
		var step := step_at(float(c[1]))
		var per_cell := int(SettlementMap.CELL_M / step)
		var widen := step / float(STEPS_M[0][1])
		for sj in per_cell:
			for si in per_cell:
				if xs.size() >= budget:
					return {"x": xs, "z": zs, "rgb": rgb, "widen": widens}
				var x := centre.x + (float(si) + 0.5) * step - SettlementMap.CELL_M * 0.5
				var z := centre.y + (float(sj) + 0.5) * step - SettlementMap.CELL_M * 0.5
				x += (_hash(x, z, 1.0) - 0.5) * step
				z += (_hash(x, z, 2.0) - 0.5) * step
				var px := pixel(data, bytes, x, z)
				if px.a <= 0.0:
					continue
				var l := 0.299 * px.r + 0.587 * px.g + 0.114 * px.b
				if l >= dark or px.g - (px.r + px.b) * 0.5 < MIN_GREEN:
					continue
				xs.append(x)
				zs.append(z)
				rgb.append(px.r)
				rgb.append(px.g)
				rgb.append(px.b)
				widens.append(widen)
	return {"x": xs, "z": zs, "rgb": rgb, "widen": widens}

static func _probes_native(data: LocationData, bytes: Array, cells: Array, dark: float, budget: int) -> Dictionary:
	var centres := PackedVector2Array()
	var dists := PackedFloat64Array()
	for c in cells:
		centres.append(c[0])
		dists.append(float(c[1]))
	var steps := PackedFloat64Array()
	for row in STEPS_M:
		steps.append(float(row[0]))
		steps.append(float(row[1]))
	var drapes: Array = []
	for di in data.far_drapes.size():
		var d: Dictionary = data.far_drapes[di]
		var img: Variant = d.get("image", null)
		if not (img is Image) or (bytes[di] as PackedByteArray).is_empty():
			continue
		drapes.append({"bytes": bytes[di], "w": (img as Image).get_width(), "h": (img as Image).get_height(),
			"zoom": int(d["zoom"]), "origin": d["origin_px"] as Vector2, "size": Vector2(d["size_px"] as Vector2i)})
	return ClassDB.class_call_static("CanopyKernels", "probes", centres, dists, steps, drapes,
		data.latitude, data.longitude, dark, MIN_GREEN, SettlementMap.CELL_M, budget)

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
	var m2u := WorldScale.metres_to_units()
	var has_wmask := not data.far_water_mask.is_empty()
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
			if has_wmask and FarWaterMask.sample(data, c.x * m2u, c.y * m2u) > FarWaterMask.LAND:
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

## A tree's tint multiplier from its photo pixel: the impostor shader
## already paints the species' colour, so the photo only shifts it, lighter
## or darker with the pixel's luminance and warmer where the pixel is
## yellower, each tree a little off its neighbours (`jitter` 0..1) so a
## stand is not one flat tone. Dark tropical canopy (photo L ~0.12) reads
## dark, not at a pale floor. Bare winter trees keep the brightness shift only.
static func crown_colour(px: Color, winter: bool, jitter: float = 0.5) -> Color:
	var l := 0.299 * px.r + 0.587 * px.g + 0.114 * px.b
	var v := clampf(l / 0.3, 0.5, 1.25) * (0.88 + 0.24 * jitter)
	if winter:
		return Color(v, v, v)
	var warm := clampf((px.r - px.b) * 2.0, -0.3, 0.3)
	return Color(v * (1.0 + warm * 0.25), v, v * (1.0 - warm * 0.3))

static func _band(r: float) -> int:
	var band := 0
	while band < FarCityBuilder.BANDS.size() - 2 and r >= FarCityBuilder.BANDS[band + 1]:
		band += 1
	return band

## One MultiMesh of species `sp`'s impostor for the trees in `list`, each
## turned at random about its trunk, on the FarCity band from `r0`.
## Writes a single PackedFloat32Array directly to MultiMesh.buffer (16 floats
## per instance: 3x4 transform + RGBA) to avoid 2*N GDScript->C++ calls.
static func _instances(list: Array, r0: float, sp: String, season: int) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = TreeMeshLibrary.mesh(sp, IMPOSTOR_LOD, season, 0.0)
	var n := list.size()
	mm.instance_count = n
	var buf := PackedFloat32Array()
	buf.resize(n * 16)
	for k in n:
		var t: Array = list[k]
		var at: Vector3 = t[0]
		var sc: Vector3 = t[1]
		var col: Color = t[2]
		var ang := _hash(at.x, at.z, 6.0) * TAU
		var cs := cos(ang)
		var sn := sin(ang)
		var o := k * 16
		buf[o] = cs * sc.x
		buf[o + 1] = 0.0
		buf[o + 2] = sn * sc.z
		buf[o + 3] = at.x
		buf[o + 4] = 0.0
		buf[o + 5] = sc.y
		buf[o + 6] = 0.0
		buf[o + 7] = at.y
		buf[o + 8] = -sn * sc.x
		buf[o + 9] = 0.0
		buf[o + 10] = cs * sc.z
		buf[o + 11] = at.z
		buf[o + 12] = col.r
		buf[o + 13] = col.g
		buf[o + 14] = col.b
		buf[o + 15] = col.a
	mm.buffer = buf
	var mi := MultiMeshInstance3D.new()
	mi.name = "FarCanopy_" + sp
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta("lod_layer", "FarCity")
	mi.set_meta("far_r0", r0)
	return mi

static func _hash(x: float, z: float, salt: float) -> float:
	return fposmod(sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453, 1.0)
