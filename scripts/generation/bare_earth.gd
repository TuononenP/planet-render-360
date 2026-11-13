class_name BareEarth
extends RefCounted

## Bare-earth filter for GroundTruth. North of 60°N the Terrarium tiles
## are ArcticDEM, a 2 m surface model: roofs and tree crowns are in the
## heights (Helsinki: 24 m street, 45–54 m blocks either side), so every
## city block became a 20–30 m hill the streets ran between. Posts under
## mapped buildings (plus the DSM's blur halo) and tree-sized bumps near
## them are refilled from the open ground around them and only ever
## lowered, so real hills with streets on them keep their height.
## Elsewhere Terrarium is SRTM / EU-DEM class data, a surface model too
## (Shibuya: +10 m on average, blocks 20–30 m up), so the filter runs on
## every registered DEM except the US lidar coverage, where the tiles are
## bare earth already. A national bare-earth model (GroundModel,
## HelsinkiDem) replaces the heights before this runs and is left alone.

## ArcticDEM coverage starts at 60°N; worlds reaching it are filtered.
const MIN_LATITUDE := 59.95
## Opening radius (posts) for unmapped bumps: about 19 m at 9.4 m posts,
## so a tree crown or a building missing from OSM goes, a 40 m+ rock
## outcrop stays.
const OPEN_RADIUS := 2
## Height (metres) a post must stand above its opening to count as an
## object rather than ground.
const OBJECT_M := 3.0
## Unmapped bumps are only removed this many posts from a mapped
## building: a sharp natural ridge also stands above its opening.
const URBAN_REACH := 5
## Relaxation sweeps over the masked posts after the row/column seed.
const SWEEPS := 30
## Unmapped roofs (a hall missing from OSM) are 40–120 m wide, too big
## for the opening above. A bump LARGE_OBJECT_M over a wider opening
## counts as a roof only when its edges are walls, not slopes: a
## post-to-post slope of CLIFF_SLOPE on at least CLIFF_SHARE of its posts
## (a natural hill rises 0.1–0.2), it is under LARGE_MAX_AREA_M2, and a
## mapped building is within LARGE_REACH_M. Sizes are metres, so the
## filter does not depend on the post spacing.
const LARGE_RADIUS_M := 38.0
const LARGE_OBJECT_M := 6.0
const LARGE_REACH_M := 376.0
const LARGE_MAX_AREA_M2 := 16000.0
const LARGE_MIN_POSTS := 3
const CLIFF_SLOPE := 0.32
const CLIFF_SHARE := 0.2

## US areas whose Terrarium tiles are USGS 3DEP / NED bare earth (lon,
## lat boxes: west, south, east, north), so the filter would only lower
## real terrain there. Coarse on purpose: Canada and Mexico stay filtered
## where the boxes stop short of the border.
const LIDAR_DEM_BOXES := [
	[-125.0, 24.4, -66.9, 44.6], [-124.8, 44.6, -97.5, 49.0],
	[-97.5, 44.6, -89.0, 49.0], [-89.0, 44.6, -82.0, 47.5],
	[-82.0, 44.6, -67.0, 45.0], [-71.5, 45.0, -67.0, 47.4],
	[-170.0, 54.0, -130.0, 60.0], [-160.6, 18.8, -154.7, 22.3],
	[-67.4, 17.8, -64.5, 18.6],
]

## SRTM / EU-DEM posts are 30 m averages: a district's roofs lift the
## whole neighbourhood, and no open ground is left to refill from (Tokyo,
## Paris and Amsterdam against their bare-earth models: the filter alone
## leaves 5–7 m of relief error in dense districts). `lower_canopy`
## takes CANOPY_K times the mean building height over a window of
## +-CANOPY_HALF_M off the surface, at most CANOPY_MAX_M. K was fitted
## on two of those cities and held for the third (0.50–0.68, error
## 6.8 / 5.3 / 2.8 m down to 5.8 / 4.7 / 2.4 m).
const CANOPY_K := 0.55
const CANOPY_HALF_M := 120.0
const CANOPY_MAX_M := 15.0
## The grid filters run natively (GridFilters) when the library is loaded.
static var _native := ClassDB.class_exists("GridFilters")

## True for real geo worlds on a surface-model DEM: ArcticDEM and the
## SRTM / EU-DEM class tiles, unless a bare-earth model replaced them or
## the tiles are US lidar.
static func applies(data: LocationData) -> bool:
	if not DemRegistration.applies(data) or data.dem_source.has("ground_model"):
		return false
	return data.latitude >= MIN_LATITUDE or not lidar_dem(data.latitude, data.longitude)

## True where Terrarium is a bare-earth lidar model: LIDAR_DEM_BOXES and
## England (Environment Agency DTM; the filter there measured 4–5 m worse).
static func lidar_dem(lat: float, lon: float) -> bool:
	if GroundModel.in_england(lat, lon):
		return true
	for box in LIDAR_DEM_BOXES:
		if lon >= box[0] and lat >= box[1] and lon <= box[2] and lat <= box[3]:
			return true
	return false

## True when the Terrarium heights are ArcticDEM (roofs, ellipsoidal sea).
static func surface_model(data: LocationData) -> bool:
	return DemRegistration.applies(data) and data.latitude >= MIN_LATITUDE

## Strips buildings and nearby tree-sized bumps from `surface` (size ×
## size posts in source metres, post (x, z) at ((x - half) * step,
## (z - half) * step) in world units) in place.
static func strip(surface: PackedFloat32Array, size: int, step: float,
		half: float, buildings: Array, land_polygons: Array = []) -> void:
	if size < 3 or (buildings.is_empty() and land_polygons.is_empty()):
		return
	var built := _footprint_mask(size, step, half, buildings)
	var mask := _dilate(built, size, 1)
	var urban := _dilate(built, size, URBAN_REACH)
	for poly in land_polygons:
		if str(poly.get("class", "")) not in ["forest", "grass"]:
			continue
		var ring: PackedVector2Array = poly.get("points", PackedVector2Array())
		if ring.size() < 3:
			continue
		var holes: Array = poly.get("holes", [])
		for i in PolygonIndex.new(ring).posts_inside(size, step, half):
			var p := Vector2(float(i % size) - half, float(i / size) - half) * step
			var in_hole := false
			for hole in holes:
				if Geometry2D.is_point_in_polygon(p, hole):
					in_hole = true
					break
			if not in_hole:
				urban[i] = 1
	var opened := _max_filter(_min_filter(surface, size, OPEN_RADIUS),
		size, OPEN_RADIUS)
	if not buildings.is_empty():
		_mark_roofs(surface, size, step, mask,
			_dilate(built, size, ceili(LARGE_REACH_M / step)))
	var holes := PackedInt32Array()
	for i in surface.size():
		if mask[i] == 0 and urban[i] != 0 \
				and surface[i] - opened[i] > OBJECT_M:
			mask[i] = 1
		if mask[i] != 0:
			holes.append(i)
	if holes.is_empty() or holes.size() == surface.size():
		return
	var filled := _seed(surface, mask, size)
	if _native:
		filled = ClassDB.class_call_static("GridFilters", "relax", filled, holes, size, SWEEPS)
	else:
		for _s in SWEEPS:
			for h in holes.size():
				var i: int = holes[h]
				var x: int = i % size
				@warning_ignore("integer_division")
				var z: int = i / size
				var sum := 0.0
				var n := 0
				if x > 0:
					sum += filled[i - 1]; n += 1
				if x < size - 1:
					sum += filled[i + 1]; n += 1
				if z > 0:
					sum += filled[i - size]; n += 1
				if z < size - 1:
					sum += filled[i + size]; n += 1
				filled[i] = sum / float(n)
	for h in holes.size():
		var i: int = holes[h]
		surface[i] = minf(surface[i], filled[i])

## Lowers `surface` by CANOPY_K times the mean building height around
## each post (see CANOPY_K): the smooth part of the roofs the posts carry
## that the footprint mask cannot reach. Posts as in `strip`.
static func lower_canopy(surface: PackedFloat32Array, size: int, step: float,
		half: float, buildings: Array) -> void:
	var volume := PackedFloat32Array()
	volume.resize(size * size)
	for b in buildings:
		if not (b is Dictionary):
			continue
		var cx := roundi(float(b.get("x", 0.0)) / step + half)
		var cz := roundi(float(b.get("z", 0.0)) / step + half)
		if cx < 0 or cx >= size or cz < 0 or cz >= size:
			continue
		var fp: PackedVector2Array = b.get("footprint", PackedVector2Array())
		var area := 0.0
		for i in fp.size():
			var j := (i + 1) % fp.size()
			area += fp[i].x * fp[j].y - fp[j].x * fp[i].y
		volume[cz * size + cx] += absf(area) * 0.5 * float(b.get("height", 10.0))
	var r := maxi(1, roundi(CANOPY_HALF_M / step))
	var window := float(2 * r + 1) * step
	var summed := _box_sum(_box_sum(volume, size, r, true), size, r, false)
	var per_area := 1.0 / (window * window)
	for i in surface.size():
		surface[i] -= minf(CANOPY_K * summed[i] * per_area, CANOPY_MAX_M)

## Sum of `src` over a (2r+1)-wide window along rows (`rows`) or columns.
static func _box_sum(src: PackedFloat32Array, size: int, r: int,
		rows: bool) -> PackedFloat32Array:
	if _native:
		return ClassDB.class_call_static("GridFilters", "box_sum", src, size, r, rows)
	var out := PackedFloat32Array()
	out.resize(size * size)
	for line in size:
		var acc := 0.0
		var stride := 1 if rows else size
		var base := line * size if rows else line
		for t in range(0, mini(r, size)):
			acc += src[base + t * stride]
		for t in size:
			if t + r < size:
				acc += src[base + (t + r) * stride]
			if t - r - 1 >= 0:
				acc -= src[base + (t - r - 1) * stride]
			out[base + t * stride] = acc
	return out

## Marks (in `mask`) steep-sided bumps in the `near` zone that stand
## LARGE_OBJECT_M over a wide opening: roofs of buildings that are not
## mapped, with a one-post halo for the DEM's edge blur.
static func _mark_roofs(surface: PackedFloat32Array, size: int, step: float,
		mask: PackedByteArray, near: PackedByteArray) -> void:
	var radius := maxi(1, roundi(LARGE_RADIUS_M / step))
	var opened := _max_filter(_min_filter(surface, size, radius), size, radius)
	var cand := PackedByteArray()
	cand.resize(size * size)
	for i in surface.size():
		if near[i] != 0 and mask[i] == 0 and surface[i] - opened[i] > LARGE_OBJECT_M:
			cand[i] = 1
	var seen := PackedByteArray()
	seen.resize(size * size)
	for start in surface.size():
		if cand[start] == 0 or seen[start] != 0:
			continue
		var region := PackedInt32Array([start])
		seen[start] = 1
		var head := 0
		while head < region.size():
			var i := region[head]
			head += 1
			for j in _neighbours(i, size):
				if cand[j] != 0 and seen[j] == 0:
					seen[j] = 1
					region.append(j)
		if region.size() < LARGE_MIN_POSTS \
				or float(region.size()) * step * step > LARGE_MAX_AREA_M2:
			continue
		var steep := 0
		for i in region:
			for j in _neighbours(i, size):
				if absf(surface[i] - surface[j]) >= CLIFF_SLOPE * step:
					steep += 1
					break
		if float(steep) < CLIFF_SHARE * float(region.size()):
			continue
		for i in region:
			mask[i] = 1
			for j in _neighbours(i, size):
				mask[j] = 1

## In-grid 4-neighbours of post `i`.
static func _neighbours(i: int, size: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	var x := i % size
	@warning_ignore("integer_division")
	var z := i / size
	if x > 0:
		out.append(i - 1)
	if x < size - 1:
		out.append(i + 1)
	if z > 0:
		out.append(i - size)
	if z < size - 1:
		out.append(i + size)
	return out

## 1 at posts inside a building footprint or at its centroid (most
## buildings are smaller than a post), else 0.
static func _footprint_mask(size: int, step: float, half: float,
		buildings: Array) -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(size * size)
	for b in buildings:
		if not (b is Dictionary):
			continue
		var cx := roundi(float(b.get("x", 0.0)) / step + half)
		var cz := roundi(float(b.get("z", 0.0)) / step + half)
		if cx >= 0 and cx < size and cz >= 0 and cz < size:
			mask[cz * size + cx] = 1
		var fp: PackedVector2Array = b.get("footprint", PackedVector2Array())
		if fp.size() < 3:
			continue
		for i in PolygonIndex.new(fp).posts_inside(size, step, half):
			mask[i] = 1
	return mask

## Mask grown by `r` posts (square neighbourhood, separable).
static func _dilate(src: PackedByteArray, size: int,
		r: int) -> PackedByteArray:
	if _native:
		return ClassDB.class_call_static("GridFilters", "dilate", src, size, r)
	var row := PackedByteArray()
	row.resize(size * size)
	for z in size:
		var base := z * size
		for x in size:
			if src[base + x] == 0:
				continue
			for dx in range(maxi(x - r, 0), mini(x + r, size - 1) + 1):
				row[base + dx] = 1
	var out := PackedByteArray()
	out.resize(size * size)
	for z in size:
		for x in size:
			if row[z * size + x] == 0:
				continue
			for dz in range(maxi(z - r, 0), mini(z + r, size - 1) + 1):
				out[dz * size + x] = 1
	return out

static func _min_filter(src: PackedFloat32Array, size: int,
		r: int) -> PackedFloat32Array:
	return _rank_filter(src, size, r, true)

static func _max_filter(src: PackedFloat32Array, size: int,
		r: int) -> PackedFloat32Array:
	return _rank_filter(src, size, r, false)

## Separable square min or max filter of radius `r`, clamped at edges.
static func _rank_filter(src: PackedFloat32Array, size: int, r: int,
		lowest: bool) -> PackedFloat32Array:
	if _native:
		return ClassDB.class_call_static("GridFilters", "rank_filter", src, size, r, lowest)
	var tmp := PackedFloat32Array()
	tmp.resize(size * size)
	for z in size:
		var base := z * size
		for x in size:
			var v := src[base + x]
			for dx in range(maxi(x - r, 0), mini(x + r, size - 1) + 1):
				v = minf(v, src[base + dx]) if lowest \
					else maxf(v, src[base + dx])
			tmp[base + x] = v
	var out := PackedFloat32Array()
	out.resize(size * size)
	for z in size:
		for x in size:
			var v := tmp[z * size + x]
			for dz in range(maxi(z - r, 0), mini(z + r, size - 1) + 1):
				v = minf(v, tmp[dz * size + x]) if lowest \
					else maxf(v, tmp[dz * size + x])
			out[z * size + x] = v
	return out

## Starting fill: each masked post gets the mean of the row and column
## lerps between the nearest open posts either side (one side only at
## the grid edge), which the relaxation sweeps then smooth.
static func _seed(surface: PackedFloat32Array, mask: PackedByteArray,
		size: int) -> PackedFloat32Array:
	var filled := surface.duplicate()
	var acc := PackedFloat32Array()
	acc.resize(size * size)
	var cnt := PackedByteArray()
	cnt.resize(size * size)
	for axis in 2:
		for line in size:
			var o := line * size if axis == 0 else line
			var d := 1 if axis == 0 else size
			var t := 0
			while t < size:
				if mask[o + t * d] == 0:
					t += 1
					continue
				var t1 := t
				while t1 < size and mask[o + t1 * d] != 0:
					t1 += 1
				var has_lo := t > 0
				var has_hi := t1 < size
				if has_lo or has_hi:
					var lo := surface[o + (t - 1) * d] if has_lo \
						else surface[o + t1 * d]
					var hi := surface[o + t1 * d] if has_hi else lo
					for k in range(t, t1):
						var f := float(k - t + 1) / float(t1 - t + 1)
						acc[o + k * d] += lerpf(lo, hi, f)
						cnt[o + k * d] += 1
				t = t1
	for i in filled.size():
		if mask[i] != 0 and cnt[i] > 0:
			filled[i] = acc[i] / float(cnt[i])
	return filled
