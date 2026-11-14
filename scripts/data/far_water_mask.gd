class_name FarWaterMask
extends RefCounted

## Where the far rings are water: OpenMapTiles' `water` layer (OpenFreeMap,
## the vector map's source) rasterised over the whole ring reach. Heights
## cannot tell: OSM has coastlines, not sea polygons, and surface-model
## DEM tiles put a northern sea 17-35 m up (Helsinki), so the old
## "below 0.5 m" rule painted open sea as land.
##
## The mask is {zoom, origin_px: Vector2 (global px at zoom of its
## top-left corner), size_px: Vector2i (global px it spans), n (raster
## side), bytes: PackedByteArray (n * n), texture: built on first bind}.
## A byte is LAND, INLAND (lakes, rivers) or OCEAN; outside the window
## sample() answers NONE and callers keep their height rule.

const NONE := -1
const LAND := 0
const INLAND := 128
const OCEAN := 255
## Tile zoom: the finest whose pixel is at least this many metres (z10 at
## 60°N, z11 at the equator): water outlines generalised to ~tens of m,
## 4-5 tiles across the 60 km window.
const TARGET_MPP := 60.0
const MAX_ZOOM := 12
## Raster pixels per tile pixel (~20-40 m mask pixels).
const SCALE := 2
## Half-width covered, metres: the ring bands' outer edge.
const REACH_M := 30000.0
const LAYER := "water"

static var _native := ClassDB.class_exists("GroundKernels")
static var _mutex := Mutex.new()

static func zoom_for(lat: float) -> int:
	return FarFieldFetcher.zoom_for(lat, TARGET_MPP, MAX_ZOOM)

## The tiles to fetch: a square block covering +-REACH_M (square so one
## raster pass fills it).
static func tiles_for(lat: float, lon: float, zoom: int) -> Array[Vector2i]:
	var tiles := FarFieldFetcher.window_tiles(FarFieldFetcher.window_px(lat, lon, zoom, REACH_M))
	var out: Array[Vector2i] = []
	if tiles.is_empty():
		return out
	var first: Vector2i = tiles[0]
	var last: Vector2i = tiles[tiles.size() - 1]
	var m := maxi(last.x - first.x, last.y - first.y) + 1
	var limit := 1 << zoom
	for ty in range(first.y, mini(first.y + m, limit)):
		for tx in range(first.x, mini(first.x + m, limit)):
			out.append(Vector2i(tx, ty))
	return out

## The mask from `bodies` (Vector2i tile -> PackedByteArray MVT, gzip or
## not; empty = open sea) over `tiles`. Empty when any tile is missing.
static func build(zoom: int, tiles: Array[Vector2i], bodies: Dictionary) -> Dictionary:
	if tiles.is_empty():
		return {}
	var first := tiles[0]
	var m := 0
	for t in tiles:
		if not bodies.has(t):
			return {}
		m = maxi(m, maxi(t.x - first.x, t.y - first.y) + 1)
	var n := m * FarFieldFetcher.TILE_PX * SCALE
	var half := float(n) * 0.5
	var inland: Array = []
	var ocean: Array = []
	for t in tiles:
		var body: PackedByteArray = bodies[t]
		# Tile origin in raster units, centred (fill_rings' frame).
		var o := Vector2((t.x - first.x) * FarFieldFetcher.TILE_PX * SCALE - half,
			(t.y - first.y) * FarFieldFetcher.TILE_PX * SCALE - half)
		var side := float(FarFieldFetcher.TILE_PX * SCALE)
		if body.is_empty():
			ocean.append([OCEAN, [PackedVector2Array([o, o + Vector2(side, 0), o + Vector2(side, side), o + Vector2(0, side)])]])
			continue
		var layers := MvtReader.read(VectorTileFetcher.inflate(body), {LAYER: ["class", "brunnel"]})
		if not layers.has(LAYER):
			continue
		var layer: Dictionary = layers[LAYER]
		var k := side / float(layer.get("extent", 4096))
		for f: Dictionary in layer["features"]:
			if int(f["type"]) != MvtReader.POLYGON:
				continue
			var tags: Dictionary = f["tags"]
			var cls := str(tags.get("class", ""))
			if cls == "swimming_pool" or str(tags.get("brunnel", "")) == "tunnel":
				continue
			for poly: Array in f["geom"]:
				var rings: Array = []
				for ring: PackedVector2Array in poly:
					rings.append(Transform2D(0.0, Vector2(k, k), 0.0, o) * ring)
				if cls == "ocean":
					ocean.append([OCEAN, rings])
				else:
					inland.append([INLAND, rings])
	# Ocean paints last: it wins where a lake polygon overlaps it.
	var fills := inland + ocean
	var bytes: PackedByteArray
	if _native:
		bytes = ClassDB.class_call_static("GroundKernels", "fill_rings", n, float(n), fills)
	else:
		bytes = _fill_script(n, fills)
	return {"zoom": zoom, "origin_px": Vector2(first * FarFieldFetcher.TILE_PX),
		"size_px": Vector2i(m * FarFieldFetcher.TILE_PX, m * FarFieldFetcher.TILE_PX),
		"n": n, "bytes": bytes}

## GroundKernels.fill_rings without the library: even-odd spans per fill,
## later fills on top, over an n x n raster centred on 0 (unit = 1 px).
static func _fill_script(n: int, fills: Array) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(n * n)
	var half := float(n) * 0.5
	for f: Array in fills:
		var value: int = f[0]
		var rings: Array = f[1]
		var zmin := INF
		var zmax := -INF
		for ring: PackedVector2Array in rings:
			for p in ring:
				zmin = minf(zmin, p.y)
				zmax = maxf(zmax, p.y)
		if zmin == INF:
			continue
		var j0 := maxi(int(ceil(zmin + half - 0.5)), 0)
		var j1 := mini(int(floor(zmax + half - 0.5)), n - 1)
		var xs: Array[float] = []
		for j in range(j0, j1 + 1):
			var wz := float(j) + 0.5 - half
			xs.clear()
			for ring: PackedVector2Array in rings:
				var cnt := ring.size()
				for q in cnt:
					var a := ring[q]
					var b := ring[(q + 1) % cnt]
					if (a.y <= wz and b.y > wz) or (b.y <= wz and a.y > wz):
						xs.append(a.x + (wz - a.y) / (b.y - a.y) * (b.x - a.x))
			xs.sort()
			var k := 0
			while k + 1 < xs.size():
				var i0 := maxi(int(ceil(xs[k] + half - 0.5)), 0)
				var i1 := mini(int(floor(xs[k + 1] + half - 0.5)), n - 1)
				for i in range(i0, i1 + 1):
					out[j * n + i] = value
				k += 2
	return out

## The mask byte at Mercator (u, v) in [0, 1] world fractions, or NONE.
static func sample_uv(mask: Dictionary, u: float, v: float) -> int:
	if mask.is_empty():
		return NONE
	var world := float(1 << int(mask["zoom"])) * float(FarFieldFetcher.TILE_PX)
	var size: Vector2i = mask["size_px"]
	var origin: Vector2 = mask["origin_px"]
	var tx := (u * world - origin.x) / float(size.x)
	var ty := (v * world - origin.y) / float(size.y)
	if tx < 0.0 or ty < 0.0 or tx >= 1.0 or ty >= 1.0:
		return NONE
	var n: int = mask["n"]
	var bytes: PackedByteArray = mask["bytes"]
	return bytes[mini(int(ty * n), n - 1) * n + mini(int(tx * n), n - 1)]

## The mask byte at world XZ (internal units, viewpoint at origin).
static func sample(data: LocationData, x: float, z: float) -> int:
	if data.far_water_mask.is_empty():
		return NONE
	var m2u := WorldScale.metres_to_units()
	var uv := FarSurface.merc_uv(data, x / m2u, z / m2u)
	return sample_uv(data.far_water_mask, uv.x, uv.y)

## The mask as the native kernels read it (far_sampling.h read_far).
static func native_params(mask: Dictionary) -> Dictionary:
	if mask.is_empty():
		return {}
	return {"zoom": mask["zoom"], "origin_px": mask["origin_px"],
		"size_px": Vector2(mask["size_px"]), "n": mask["n"], "bytes": mask["bytes"]}

## The mask texture (built once, mipmapped: distant shores soften instead
## of shimmering).
static func texture(mask: Dictionary) -> Texture2D:
	_mutex.lock()
	if not mask.has("texture"):
		var n: int = mask["n"]
		var img := Image.create_from_data(n, n, false, Image.FORMAT_L8, mask["bytes"])
		img.generate_mipmaps()
		mask["texture"] = ImageTexture.create_from_image(img)
	var tex: Texture2D = mask["texture"]
	_mutex.unlock()
	return tex

## Binds the mask to a ring material, addressed through the UVs of the
## drape showing `fine` (UV), else `coarse` (UV2). Without a drape the
## band keeps its per-vertex water flag.
static func bind(mat: ShaderMaterial, data: LocationData, fine: Texture2D, coarse: Texture2D) -> void:
	if data == null or data.far_water_mask.is_empty():
		return
	var slots := [[fine, 1.0], [coarse, 2.0]]
	for slot: Array in slots:
		if slot[0] == null:
			continue
		for drape: Dictionary in data.far_drapes:
			if drape.get("texture") == slot[0]:
				mat.set_shader_parameter("water_mask", texture(data.far_water_mask))
				mat.set_shader_parameter("water_mask_map", uv_map(drape, data.far_water_mask))
				mat.set_shader_parameter("has_water_mask", slot[1])
				return

## Scale (xy) and offset (zw) taking a drape's UV to the mask's.
static func uv_map(drape: Dictionary, mask: Dictionary) -> Vector4:
	var k := pow(2.0, float(int(mask["zoom"]) - int(drape["zoom"])))
	var size := Vector2(mask["size_px"])
	var d_size := Vector2(drape["size_px"]) * k
	var offset := (Vector2(drape["origin_px"]) * k - Vector2(mask["origin_px"])) / size
	return Vector4(d_size.x / size.x, d_size.y / size.y, offset.x, offset.y)
