class_name BareEarth
extends RefCounted

## Bare-earth filter for GroundTruth. North of 60°N the Terrarium tiles
## are ArcticDEM, a 2 m surface model: roofs and tree crowns are in the
## heights (Helsinki: 24 m street, 45–54 m blocks either side), so every
## city block became a 20–30 m hill the streets ran between. Posts under
## mapped buildings (plus the DSM's blur halo) and tree-sized bumps near
## them are refilled from the open ground around them and only ever
## lowered, so real hills with streets on them keep their height.

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

## True for real geo worlds on a surface-model DEM.
static func applies(data: LocationData) -> bool:
	return DemRegistration.applies(data) and data.latitude >= MIN_LATITUDE

## Strips buildings and nearby tree-sized bumps from `surface` (size ×
## size posts in source metres, post (x, z) at ((x - half) * step,
## (z - half) * step) in world units) in place.
static func strip(surface: PackedFloat32Array, size: int, step: float,
		half: float, buildings: Array) -> void:
	if size < 3 or buildings.is_empty():
		return
	var built := _footprint_mask(size, step, half, buildings)
	var mask := _dilate(built, size, 1)
	var urban := _dilate(built, size, URBAN_REACH)
	var opened := _max_filter(_min_filter(surface, size, OPEN_RADIUS),
		size, OPEN_RADIUS)
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
