class_name QuayBuilder
extends RefCounted

## Stone quays where OSM implies built waterfront (T3.8, split out of
## WaterBuilder): shoreline runs whose near bank reads urban get a
## solid limestone embankment from just below the water up to the real
## bank (DEM street level), so the bank never reads as a carved cliff
## or a floating slab. Banks standing ≥ TWO_TIER_M above the water
## (Paris: quays 5–8 m over the Seine) step down to a lower walkway
## (bas-port) LOW_WALK_M above the water with a parapet on the upper
## quay — the PRD §4.3 stone quay #8A8274. Natural banks get no stone:
## WaterBuilder's T3.5 shore aprons blend them by land cover.
## Everything merges into one triplanar-textured mesh (one draw call).

const QUAY_STONE := Color(0.541, 0.510, 0.455)  # PRD §4.3 #8A8274
const MAX_SPAN_M := 12.0     # taller banks are natural slopes, not quays
const MIN_SPAN_M := 1.2
const TWO_TIER_M := 4.5
const LOW_WALK_M := 2.4      # bas-port walkway height above the water
const WALK_WIDTH_M := 9.0
const PARAPET_H_M := 0.9
const PARAPET_T_M := 0.5
const UNDERWATER_M := 0.6

static var _stone_mats := {}

## Pale limestone of the Seine quays (linear target for the render set).
const LIMESTONE := Color(0.56, 0.52, 0.44)
# Cool blue-grey: the golden-hour sun warms it to the real granite's tone; a warm
# base read as orange blocks.
const STOCKHOLM_ASHLAR := Color(0.33, 0.35, 0.37)
## Warm pinkish-brown-grey Finnish granite (Aurajoki / Helsinki graniittimuuri).
const FINNISH_ASHLAR := Color(0.54, 0.50, 0.47)

## Ashlar masonry: courses COURSE_M high, staggered rough-hewn blocks with
## recessed joints, beveled edges, normal + roughness maps, and block-to-block
## tone/hue variation; mapped in world space (a tile is TILE_COURSES courses high).
const ASHLAR_COURSE_M := 0.6
const ASHLAR_TILE_COURSES := 4

static func _hash2(ix: int, iy: int, seed_v: float) -> float:
	return fposmod(sin(float(ix) * 127.1 + float(iy) * 311.7 + seed_v * 74.7) * 43758.5453, 1.0)

static func _tile_noise(x: float, y: float, period: int, seed_v: float) -> float:
	var fx := floorf(x)
	var fy := floorf(y)
	var tx := x - fx
	var ty := y - fy
	tx = tx * tx * (3.0 - 2.0 * tx)
	ty = ty * ty * (3.0 - 2.0 * ty)
	var x0 := posmod(int(fx), period)
	var y0 := posmod(int(fy), period)
	var x1 := (x0 + 1) % period
	var y1 := (y0 + 1) % period
	var a := lerpf(_hash2(x0, y0, seed_v), _hash2(x1, y0, seed_v), tx)
	var b := lerpf(_hash2(x0, y1, seed_v), _hash2(x1, y1, seed_v), tx)
	return lerpf(a, b, ty)

static func _ashlar_material(base: Color = Color(0.80, 0.77, 0.69), course_m: float = ASHLAR_COURSE_M,
		variation: float = 0.14, hue_var: float = 0.02, lime_streaks: bool = false) -> StandardMaterial3D:
	var n := 256
	var course := n / ASHLAR_TILE_COURSES
	var shifts := [0, 64, 34, 98]
	var splits := [120, 134, 114, 128]
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var bump := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rough := Image.create(n, n, false, Image.FORMAT_RGB8)
	for y in n:
		var c := y / course
		var shift: int = shifts[c % shifts.size()]
		var split_x: int = splits[c % splits.size()]
		for x in n:
			var wy := (_tile_noise(float(x) * 0.125, float(c) * 2.3, 32, 1.3) - 0.5) * 2.4
			var ly := fposmod(float(y) + wy, float(course))
			var dist_h := minf(ly, float(course) - ly)
			var wx := (_tile_noise(float(c) * 1.9, float(y) * 0.125, 32, 4.1) - 0.5) * 2.2
			var lx := fposmod(float(x + shift) + wx, float(n))
			var bx := 0 if lx < float(split_x) else 1
			var blk_len := float(split_x) if bx == 0 else float(n - split_x)
			var in_blk := lx if bx == 0 else lx - float(split_x)
			var dist_v := minf(in_blk, blk_len - in_blk)
			var edge := minf(dist_h, dist_v)
			var bh := _hash2(bx + c * 3, c * 7 + 1, 2.7)
			var bh2 := _hash2(bx * 5 + 2, c * 11 + 3, 9.1)
			var tone := (1.0 - variation * 0.50) + variation * bh
			if bh2 < 0.18:
				tone *= 0.87
			elif bh2 > 0.84:
				tone *= 1.08
			var coarse := _tile_noise(float(x) * 0.0625, float(y) * 0.0625, 16, 6.2)
			var fine := _tile_noise(float(x) * 0.25, float(y) * 0.25, 64, 11.4)
			var speckle := _hash2(x, y, 17.3)
			tone *= 0.90 + 0.14 * coarse + 0.06 * fine + 0.04 * (speckle - 0.5)
			# Weathering & mineral streaks running down from bed joints.
			var drip := _tile_noise(float(x + shift) * 0.125, float(c) * 1.7, 32, 8.5)
			if ly < 22.0:
				var fade := 1.0 - ly / 22.0
				if drip < 0.30:
					tone *= 1.0 - 0.11 * fade
				elif lime_streaks and drip > 0.84:
					tone *= 1.0 + 0.14 * fade
			var block_rough := 0.80 + 0.08 * bh
			var h_val := 0.78 + (coarse - 0.5) * 0.20 + (fine - 0.5) * 0.08
			var r_val := clampf(block_rough + (fine - 0.5) * 0.10, 0.72, 0.96)
			if edge < 2.6:
				h_val = 0.06
				tone *= 0.34
				r_val = 0.96
			elif edge < 7.5:
				var t := (edge - 2.6) / 4.9
				t = t * t * (3.0 - 2.0 * t)
				h_val = lerpf(0.06, h_val, t)
				tone *= lerpf(0.56, 1.0, t)
				r_val = lerpf(0.95, r_val, t)
			var r_s := 1.0 + hue_var * (bh2 - 0.45)
			var g_s := 1.0 + hue_var * 0.25 * (bh2 - 0.50)
			var b_s := 1.0 - hue_var * 0.85 * (bh2 - 0.45)
			img.set_pixel(x, y, Color(clampf(base.r * tone * r_s, 0.0, 1.0),
				clampf(base.g * tone * g_s, 0.0, 1.0), clampf(base.b * tone * b_s, 0.0, 1.0)))
			var hv := clampf(h_val, 0.0, 1.0)
			bump.set_pixel(x, y, Color(hv, hv, hv))
			rough.set_pixel(x, y, Color(r_val, r_val, r_val))
	bump.bump_map_to_normal_map(4.5)
	img.generate_mipmaps()
	bump.generate_mipmaps()
	rough.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.normal_enabled = true
	m.normal_texture = ImageTexture.create_from_image(bump)
	m.normal_scale = 1.15
	m.roughness_texture = ImageTexture.create_from_image(rough)
	m.roughness = 1.0
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / (course_m * ASHLAR_TILE_COURSES * WorldScale.metres_to_units())
	return m

## True where the quays and bridges are pale limestone (Paris's core).
static func stone_quays(data: LocationData) -> bool:
	return data != null and ArchitectureStyle.country_region_for(data.latitude, data.longitude, data.country) == "haussmann"

## True where quay walls are dressed granite ashlar blocks (Nordic and
## European granite-kerb regions, including Finland) rather than poured concrete.
static func granite_quays(data: LocationData) -> bool:
	if data == null or stone_quays(data):
		return false
	var stone := KerbBuilder.stone_for(data)
	return stone == KerbBuilder.GRANITE or stone == FinnishGranite.KERB

## Fine-grained stone calibrated in linear space to the regional kerb
## colour (granite in Europe, concrete in North America). Cache by
## colour so building another region cannot recolour an existing quay.
## World triplanar mapping keeps long walls at real texture scale.
static func stone_material(data: LocationData = null) -> StandardMaterial3D:
	var target := KerbBuilder.stone_for(data) if data != null else KerbBuilder.GRANITE
	# Paris's quay walls are pale limestone ashlar, not the dark granite of a
	# kerb: a tall wall of it read as a flat lilac-grey slab.
	if stone_quays(data):
		target = LIMESTONE
	var granite := granite_quays(data)
	var stockholm := granite and ShoreApron.stockholm(data)
	var finnish := granite and FinnishGranite.applies(data)
	var key := target.to_html(false) + ("_granite_ashlar" if granite else "") \
		+ ("_stockholm" if stockholm else "") + ("_finnish" if finnish else "")
	if not _stone_mats.has(key):
		if stone_quays(data):
			_stone_mats[key] = _ashlar_material()
			return _stone_mats[key]
		if granite:
			# Weathered Nordic/European dressed granite ashlar blocks:
			# Finnish river/harbour quays (graniittimuuri) use rough-hewn
			# warm pinkish-brown-grey rapakivi granite in ~0.42 m courses;
			# Stockholm's quays are darker, cooler grey granite.
			if finnish:
				_stone_mats[key] = _ashlar_material(FINNISH_ASHLAR, 0.42, 0.24, 0.08, true)
			elif stockholm:
				_stone_mats[key] = _ashlar_material(STOCKHOLM_ASHLAR, 0.45, 0.20, 0.03, false)
			else:
				_stone_mats[key] = _ashlar_material(Color(0.55, 0.53, 0.49), 0.45, 0.20, 0.04, false)
			return _stone_mats[key]
		var row: Dictionary = MaterialLibrary.PBR_SETS["render"]
		# Set means are already linear (a second decode read the stone
		# ~1.6x too bright: pale, textureless quay slabs).
		var mean: Color = row["mean"]
		var tint := Color(target.r / maxf(mean.r, 0.01),
			target.g / maxf(mean.g, 0.01),
			target.b / maxf(mean.b, 0.01))
		# Linear tint: pbr_material sRGB-encodes albedo_color (T4.7).
		var stone := MaterialLibrary.pbr_material("render", tint).duplicate() as StandardMaterial3D
		stone.uv1_triplanar = true
		stone.uv1_world_triplanar = true
		stone.uv1_scale = Vector3.ONE / (3.0 * WorldScale.metres_to_units())
		_stone_mats[key] = stone
	return _stone_mats[key]

## Quays along every water-polygon rim and channel bank (urban banks).
static func build(root: Node3D, data: LocationData, ground: GroundTruth,
		channels: Array, wl: float, levels: Dictionary = {}) -> void:
	if ground.shoreline != null and ground.shoreline.ready:
		ShoreBankMesh.build(root, ground.shoreline, null, data)
		return
	var step := WaterBuilder._post_step(data)
	var bound := WorldScale.detailed_extent_units() * 0.5
	# Plain Arrays (reference types): packed arrays in a Dictionary
	# copy on every append round-trip.
	var st := {"v": [], "n": [], "i": []}
	if levels.is_empty():
		levels = WaterBuilder._poly_levels(data, ground, wl)
	for pi in levels:
		var poly: Dictionary = data.land_polygons[pi]
		var pts: PackedVector2Array = poly.get("points", PackedVector2Array())
		var level := float(levels[pi])
		# Walk the REAL ring, not the clipped parts: clipping invents
		# frame-edge segments at the mesh boundary, and quays along
		# those read as a stone wall encircling the whole city.
		_walk(st, pts, true, true, 0.0, level, ground, step, bound)
		for h in poly.get("holes", []):
			if h is PackedVector2Array \
					and (h as PackedVector2Array).size() >= 3:
				_walk(st, h, true, false, 0.0, level, ground, step, bound)
	for w in channels:
		var cpts: PackedVector2Array = w.get("points", PackedVector2Array())
		var half := float(w.get("width_m", 0.0)) * 0.5 \
			* WorldScale.metres_to_units()
		for run in WaterBuilder._clip_runs(cpts, bound + half + 2.0):
			if run.size() < 2:
				continue
			if WaterBuilder._mostly_in_water_polys(run, ground):
				continue
			var level := WaterBuilder._body_level(ground,
				WaterBuilder._outside_samples(run, maxf(step * 0.75, 1.0),
					half + step * 0.75, false), wl)
			_walk(st, run, false, false, half, level, ground, step, bound)
	var idx := PackedInt32Array(st["i"])
	if idx.is_empty():
		return
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(st["v"])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(st["n"])
	arrays[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := TerrainBuilder._add(root, mesh, stone_material(data))
	mi.name = "Quays"

## Quay stations along a ring (water inside, or an island hole with
## water outside) or along both banks of a channel centreline,
## skipping segments past the mesh.
static func _walk(st: Dictionary, pts: PackedVector2Array, closed: bool,
		water_inside: bool, half: float, level: float, ground: GroundTruth,
		step: float, bound: float) -> void:
	var stride := maxf(step * 1.5, 4.0)
	var segs := pts.size() if closed else pts.size() - 1
	for i in segs:
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		var mid := (a + b) * 0.5
		if absf(mid.x) > bound or absf(mid.y) > bound:
			continue
		var seg_len := a.distance_to(b)
		if seg_len < 0.001:
			continue
		var dir := (b - a) / seg_len
		var n := Vector2(-dir.y, dir.x)
		# Bank samples sit beyond the carve blend (binary polygon
		# carves bleed one post through bilinear sampling; channel
		# carves reach half + 2.5), or siting reads the carve as bank.
		var off := step * 1.5 if closed else half + 2.5 + step
		var steps := maxi(1, int(seg_len / stride))
		var piece := seg_len / float(steps)
		for s in steps:
			var c := a.lerp(b, (float(s) + 0.5) / float(steps))
			var sides: Array = []
			if closed:
				var in_water := Geometry2D.is_point_in_polygon(c + n * off,
					pts)
				sides.append(-n if in_water == water_inside else n)
			else:
				sides.append(n)
				sides.append(-n)
			for land in sides:
				var shore: Vector2 = c + (land as Vector2) * half
				var bank: Vector2 = c + (land as Vector2) * off
				if ground.land_class_at(bank.x, bank.y) != "urban":
					continue
				_station(st, shore, land, dir, piece + 0.3,
					ground.height_at_world(bank.x, bank.y), level, step)

## One quay station: solid embankment block(s) from the shoreline
## landward across the carve ditch (≈1.1 posts), lower walkway notch
## on tall banks, parapet on the upper quay edge.
static func _station(st: Dictionary, shore: Vector2, land: Vector2,
		along: Vector2, length: float, top: float, level: float,
		step: float) -> void:
	var m := WorldScale.metres_to_units()
	var span := top - level
	# Banks taller than any real quay are slopes (or DEM edge/ridge
	# artefacts): a capped wall there floated as a free-standing slab.
	if span < MIN_SPAN_M * m or span > MAX_SPAN_M * m:
		return
	var base := level - UNDERWATER_M * m
	var depth := maxf(step * 1.1, 6.0 * m)
	if span >= TWO_TIER_M * m:
		var walk_w := minf(WALK_WIDTH_M * m, depth * 0.6)
		var low := level + LOW_WALK_M * m
		_box(st, shore, land, along, length, 0.0, depth, base, low)
		_box(st, shore, land, along, length, walk_w, depth, low, top)
		_box(st, shore, land, along, length, walk_w,
			walk_w + PARAPET_T_M * m, top, top + PARAPET_H_M * m)
	else:
		_box(st, shore, land, along, length, 0.0, depth, base, top)
		_box(st, shore, land, along, length, 0.0, PARAPET_T_M * m, top,
			top + PARAPET_H_M * m)

## Oriented box spanning [d0, d1] landward of `shore`, `length` along
## the bank, y0..y1. Faces wind outward (CCW seen from outside).
static func _box(st: Dictionary, shore: Vector2, land: Vector2,
		along: Vector2, length: float, d0: float, d1: float, y0: float,
		y1: float) -> void:
	var h := along * (length * 0.5)
	var p0 := shore + land * d0
	var p1 := shore + land * d1
	var c: Array = [p0 - h, p0 + h, p1 + h, p1 - h]
	var v: Array = st["v"]
	var nn: Array = st["n"]
	var ii: Array = st["i"]
	var lo: Array = []
	var hi: Array = []
	for q in c:
		lo.append(Vector3((q as Vector2).x, y0, (q as Vector2).y))
		hi.append(Vector3((q as Vector2).x, y1, (q as Vector2).y))
	var faces: Array = [
		[hi[0], hi[1], hi[2], hi[3]],
		[lo[3], lo[2], lo[1], lo[0]],
	]
	for e in 4:
		faces.append([lo[e], lo[(e + 1) % 4], hi[(e + 1) % 4], hi[e]])
	var centre := Vector3((p0.x + p1.x) * 0.5, (y0 + y1) * 0.5,
		(p0.y + p1.y) * 0.5)
	for f in faces:
		var a: Vector3 = f[0]
		var b: Vector3 = f[1]
		var d: Vector3 = f[2]
		var fn := (b - a).cross(d - a).normalized()
		var flip := fn.dot((a + d) * 0.5 - centre) < 0.0
		if flip:
			fn = -fn
		var k := v.size()
		for corner in f:
			v.append(corner)
			nn.append(fn)
		# Godot front faces are clockwise seen from the normal side.
		if flip:
			ii.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
		else:
			ii.append_array([k, k + 2, k + 1, k, k + 3, k + 2])
