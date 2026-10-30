class_name VegetationMask
extends RefCounted

## Placement rasters for vegetation and street props (T5.1): one byte
## of exclusion bits + one green-cover polygon id per cell over the
## detailed extent, scan-converted once per build (row-bucketed edges,
## even-odd so holes stay open). Point-in-polygon per candidate would be
## O(points) each — forests carry thousands of vertices.
## Cells are CELL_M metres; XZ inputs are current internal units.

const BUILDING := 1
const ROAD := 2        ## carriageway (width_m / 2)
const WATER := 4
const ROAD_EDGE := 8   ## carriageway + verge margin
const CELL_M := 1.5
const FOOT_CLASSES: Array[String] = ["footway", "path", "steps", "cycleway", "pedestrian",
	"track", "bridleway", "platform", "corridor", "bus_stop", "elevator", "sidewalk"]
const GREEN_CLASSES: Array[String] = ["grass", "forest", "orchard", "cemetery", "wetland"]

var cell := 1.0
var half := 110.0
var n := 1
var bits := PackedByteArray()
var cover := PackedInt32Array()
## Green polygons in cover-id order (id = index + 1):
## {class, points, holes, cells, real_trees}.
var green: Array = []
## Build-time ms per layer (diagnostics for captures/tests).
var timings: Dictionary = {}
var _seg_a := PackedVector2Array()
var _seg_b := PackedVector2Array()
var _seg_core := PackedFloat32Array()
var _seg_edge := PackedFloat32Array()
var _buckets := {}
var _bucket := 24.0
var _built_blocks := PackedInt32Array()
var _block := 16
var _nb := 1

func _init(data: LocationData, ground: GroundTruth) -> void:
	var m2u := WorldScale.metres_to_units()
	cell = CELL_M * m2u
	_bucket = 24.0 * m2u
	half = ground.extent_m * m2u if ground != null else WorldScale.detailed_extent_units() * 0.5
	n = maxi(int(ceil(2.0 * half / cell)), 1)
	bits.resize(n * n)
	cover.resize(n * n)
	_nb = int(ceil(float(n) / float(_block)))
	_built_blocks.resize(_nb * _nb)
	var t0 := Time.get_ticks_msec()
	for b in data.buildings:
		if not (b is Dictionary):
			continue
		var fp: Variant = (b as Dictionary).get("footprint", null)
		if fp is PackedVector2Array and (fp as PackedVector2Array).size() >= 3:
			_fill([fp], BUILDING, 0)
		else:
			var bx := float(b.get("x", 0.0))
			var bz := float(b.get("z", 0.0))
			var hx := float(b.get("size_x", 0.0)) * 0.5
			var hz := float(b.get("size_z", 0.0)) * 0.5
			_fill([PackedVector2Array([Vector2(bx - hx, bz - hz), Vector2(bx + hx, bz - hz),
				Vector2(bx + hx, bz + hz), Vector2(bx - hx, bz + hz)])], BUILDING, 0)
	timings["buildings"] = Time.get_ticks_msec() - t0
	t0 = Time.get_ticks_msec()
	for r in data.roads:
		var pts: PackedVector2Array
		var width_m := 6.0
		var foot := false
		if r is Dictionary:
			if bool((r as Dictionary).get("tunnel", false)):
				continue
			pts = (r as Dictionary).get("points", PackedVector2Array())
			width_m = float((r as Dictionary).get("width_m", 6.0))
			foot = str((r as Dictionary).get("class", "")) in FOOT_CLASSES
		elif r is PackedVector2Array:
			pts = r
		else:
			continue
		for i in pts.size() - 1:
			# Mapped sidewalks/paths are not carriageway: street trees and
			# lamps stand on them, only synthetic planting avoids them.
			var core := -1.0 if foot else width_m * 0.5 * m2u
			var edge := (width_m * 0.5 + (0.4 if foot else 1.2)) * m2u
			_add_segment(pts[i], pts[i + 1], core, edge)
	timings["roads"] = Time.get_ticks_msec() - t0
	t0 = Time.get_ticks_msec()
	# Green cover: grass first so forest/orchard/cemetery polygons drawn
	# over a park keep their own class.
	for pass_cls in [["grass", "wetland"], ["forest"], ["orchard", "cemetery"]]:
		for poly in data.land_polygons:
			var cls := str(poly.get("class", ""))
			if cls not in pass_cls:
				continue
			var rings: Array = [poly.get("points", PackedVector2Array())]
			for hole in poly.get("holes", []):
				rings.append(hole)
			green.append({"class": cls, "points": rings[0], "cells": 0, "real_trees": 0,
				"leaf_type": str(poly.get("leaf_type", ""))})
			green[green.size() - 1]["cells"] = _fill(rings, 0, green.size())
	for poly in data.land_polygons:
		if str(poly.get("class", "")) == "water":
			var rings: Array = [poly.get("points", PackedVector2Array())]
			for hole in poly.get("holes", []):
				rings.append(hole)
			_fill(rings, WATER, 0)
	timings["cover_water"] = Time.get_ticks_msec() - t0

## Cell index of XZ, or -1 outside the extent.
func index_of(x: float, z: float) -> int:
	var cx := int(floor((x + half) / cell))
	var cz := int(floor((z + half) / cell))
	if cx < 0 or cz < 0 or cx >= n or cz >= n:
		return -1
	return cz * n + cx

## True when any cell within `margin_m` of XZ carries one of `mask`.
## Outside the extent counts as blocked.
func blocked(x: float, z: float, mask: int, margin_m: float = 0.0) -> bool:
	var r := int(ceil(margin_m * WorldScale.metres_to_units() / cell))
	var cx := int(floor((x + half) / cell))
	var cz := int(floor((z + half) / cell))
	if cx < 0 or cz < 0 or cx >= n or cz >= n:
		return true
	var m := float(r) * cell
	if mask & ROAD and _near_road(x, z, true, m):
		return true
	if mask & ROAD_EDGE and _near_road(x, z, false, m):
		return true
	for dz in range(-r, r + 1):
		var zz := cz + dz
		if zz < 0 or zz >= n:
			continue
		for dx in range(-r, r + 1):
			var xx := cx + dx
			if xx < 0 or xx >= n:
				continue
			if bits[zz * n + xx] & mask:
				return true
	return false

## Green polygon id (index into `green`) at XZ, or -1.
func cover_at(x: float, z: float) -> int:
	var i := index_of(x, z)
	if i < 0:
		return -1
	return cover[i] - 1

## Fraction of built cells in the block window around XZ (~24 m blocks,
## 3x3 neighbourhood ≈ 72 m): "is this a street / town park".
func built_fraction(x: float, z: float) -> float:
	var bx := clampi(int(floor((x + half) / cell)) / _block, 0, _nb - 1)
	var bz := clampi(int(floor((z + half) / cell)) / _block, 0, _nb - 1)
	var total := 0
	var cells := 0
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var xx := bx + dx
			var zz := bz + dz
			if xx < 0 or zz < 0 or xx >= _nb or zz >= _nb:
				continue
			total += _built_blocks[zz * _nb + xx]
			cells += _block * _block
	return float(total) / float(maxi(cells, 1))


## Even-odd scan conversion of rings (outer + holes). Sets `bit` and/or
## cover id per covered cell; returns the covered cell count.
func _fill(rings: Array, bit: int, cov: int) -> int:
	var outer: PackedVector2Array = rings[0]
	if outer.size() < 3:
		return 0
	var minz := INF
	var maxz := -INF
	for p in outer:
		minz = minf(minz, p.y)
		maxz = maxf(maxz, p.y)
	var r0 := maxi(int(ceil((minz + half) / cell - 0.5)), 0)
	var r1 := mini(int(floor((maxz + half) / cell - 0.5)), n - 1)
	if r1 < r0:
		return 0
	var rows: Array = []
	rows.resize(r1 - r0 + 1)
	for i in rows.size():
		rows[i] = PackedFloat32Array()
	for ring in rings:
		var pts: PackedVector2Array = ring
		var m := pts.size()
		for i in m:
			var a := pts[i]
			var b := pts[(i + 1) % m]
			if is_equal_approx(a.y, b.y):
				continue
			var lo := minf(a.y, b.y)
			var hi := maxf(a.y, b.y)
			var ra := maxi(int(ceil((lo + half) / cell - 0.5)), r0)
			var rb := mini(int(floor((hi + half) / cell - 0.5)), r1)
			for r in range(ra, rb + 1):
				var zc := (float(r) + 0.5) * cell - half
				if (a.y > zc) != (b.y > zc):
					# Packed arrays are values: write the row back.
					var row: PackedFloat32Array = rows[r - r0]
					row.append(a.x + (zc - a.y) * (b.x - a.x) / (b.y - a.y))
					rows[r - r0] = row
	var count := 0
	for ri in rows.size():
		var xs: PackedFloat32Array = rows[ri]
		if xs.size() < 2:
			continue
		xs.sort()
		var base := (r0 + ri) * n
		var k := 0
		while k + 1 < xs.size():
			var c0 := maxi(int(ceil((xs[k] + half) / cell - 0.5)), 0)
			var c1 := mini(int(floor((xs[k + 1] + half) / cell - 0.5)), n - 1)
			if bit == BUILDING and c1 >= c0:
				# Built-density blocks counted as footprints fill (a full
				# raster sweep is ~2.5 M cells at the metre extent).
				var brow := ((r0 + ri) / _block) * _nb
				for c in range(c0, c1 + 1):
					_built_blocks[brow + c / _block] += 1
			for c in range(c0, c1 + 1):
				if bit != 0:
					bits[base + c] |= bit
				if cov != 0:
					cover[base + c] = cov
				count += 1
			k += 2
	return count

## Road segments go into a 24 m spatial hash instead of the raster:
## stamping every cell of ~250 km of Paris ways cost ~1 s in GDScript,
## while candidate queries are only tens of thousands.
func _add_segment(a: Vector2, b: Vector2, core: float, edge: float) -> void:
	if (absf(a.x) > half + edge and absf(b.x) > half + edge and signf(a.x) == signf(b.x)) \
			or (absf(a.y) > half + edge and absf(b.y) > half + edge and signf(a.y) == signf(b.y)):
		return
	var si := _seg_a.size()
	_seg_a.append(a)
	_seg_b.append(b)
	_seg_core.append(core)
	_seg_edge.append(edge)
	var bx0 := int(floor((minf(a.x, b.x) - edge) / _bucket))
	var bx1 := int(floor((maxf(a.x, b.x) + edge) / _bucket))
	var bz0 := int(floor((minf(a.y, b.y) - edge) / _bucket))
	var bz1 := int(floor((maxf(a.y, b.y) + edge) / _bucket))
	for bz in range(bz0, bz1 + 1):
		for bx in range(bx0, bx1 + 1):
			var key := Vector2i(bx, bz)
			if not _buckets.has(key):
				_buckets[key] = []
			(_buckets[key] as Array).append(si)

## Whether XZ lies within a carriageway (want_core) or carriageway +
## verge / any mapped way (else), plus `margin` units.
func _near_road(x: float, z: float, want_core: bool, margin: float) -> bool:
	var key := Vector2i(int(floor(x / _bucket)), int(floor(z / _bucket)))
	if not _buckets.has(key):
		return false
	var p := Vector2(x, z)
	for si in _buckets[key]:
		var lim: float = (_seg_core[si] if want_core else _seg_edge[si])
		if lim < 0.0:
			continue
		lim += margin
		var a := _seg_a[si]
		var ab := _seg_b[si] - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
		if (a + ab * t).distance_squared_to(p) <= lim * lim:
			return true
	return false
