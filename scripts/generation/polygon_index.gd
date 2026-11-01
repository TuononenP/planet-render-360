class_name PolygonIndex
extends RefCounted

## Point-in-polygon for big rings with holes (a lagoon with a thousand
## islands, a sea polygon): edges are bucketed into horizontal bands, so
## a test only walks the edges near the point's row instead of every
## vertex. Same crossing rule as WorldScale.point_in_polygon, so answers
## are identical: inside the outer ring and in no hole.

const EDGES_PER_BAND := 8
const MAX_BANDS := 2048

var _rings: Array = []  # [outer, hole, hole, ...] PackedVector2Array
var _box := Rect2()
var _y0 := 0.0
var _band_h := 1.0
var _bands: Array = []  # per band: Array of (ring << 32 | edge) codes

func _init(outer: PackedVector2Array, holes: Array = []) -> void:
	if outer.size() < 3:
		return
	_rings.append(outer)
	for h in holes:
		if h is PackedVector2Array and (h as PackedVector2Array).size() >= 3:
			_rings.append(h)
	_box = Rect2(outer[0], Vector2.ZERO)
	var edges := 0
	for p in outer:
		_box = _box.expand(p)
	for r in _rings:
		edges += (r as PackedVector2Array).size()
	var n := clampi(edges / EDGES_PER_BAND, 1, MAX_BANDS)
	_y0 = _box.position.y
	_band_h = maxf(_box.size.y / float(n), 1e-4)
	_bands.resize(n)
	for b in n:
		_bands[b] = []
	for ri in _rings.size():
		var ring: PackedVector2Array = _rings[ri]
		var j := ring.size() - 1
		for i in ring.size():
			var lo := minf(ring[i].y, ring[j].y)
			var hi := maxf(ring[i].y, ring[j].y)
			var b0 := clampi(int(floor((lo - _y0) / _band_h)), 0, n - 1)
			var b1 := clampi(int(floor((hi - _y0) / _band_h)), 0, n - 1)
			for b in range(b0, b1 + 1):
				(_bands[b] as Array).append((ri << 32) | i)
			j = i

func is_empty() -> bool:
	return _rings.is_empty()

func bounds() -> Rect2:
	return _box

## Inside the outer ring and in none of the holes.
func contains(p: Vector2) -> bool:
	if _rings.is_empty() or not _box.has_point(p):
		return false
	var band := clampi(int(floor((p.y - _y0) / _band_h)), 0, _bands.size() - 1)
	# Single-ring fast path — no PackedByteArray alloc.
	if _rings.size() == 1:
		var parity2 := 0
		for code in (_bands[band] as Array):
			var ring2: PackedVector2Array = _rings[0]
			var i2: int = code & 0xFFFFFFFF
			var pi2 := ring2[i2]
			var pj2 := ring2[i2 - 1 if i2 > 0 else ring2.size() - 1]
			if (pi2.y > p.y) != (pj2.y > p.y) \
					and p.x < (pj2.x - pi2.x) * (p.y - pi2.y) / (pj2.y - pi2.y) + pi2.x:
				parity2 ^= 1
		return parity2 == 1
	var parity := PackedByteArray()
	parity.resize(_rings.size())
	for code in (_bands[band] as Array):
		var ri: int = code >> 32
		var ring: PackedVector2Array = _rings[ri]
		var i: int = code & 0xFFFFFFFF
		var pi := ring[i]
		var pj := ring[i - 1 if i > 0 else ring.size() - 1]
		if (pi.y > p.y) != (pj.y > p.y) \
				and p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x:
			parity[ri] ^= 1
	if parity[0] == 0:
		return false
	for k in range(1, parity.size()):
		if parity[k] == 1:
			return false
	return true

## Grid posts inside the polygon, as indices z * size + x. Post (x, z)
## sits at ((x - half) * step, (z - half) * step). One sweep per row over
## that row's crossings sorted by x, flipping each crossed ring's parity,
## so a polygon covering the grid costs rows x (posts + crossings), not
## posts x rings (a 1100-island lagoon took 6.6 s walking every ring).
func posts_inside(size: int, step: float, half: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	if _rings.is_empty():
		return out
	var z0 := clampi(int(ceil(_box.position.y / step + half)), 0, size - 1)
	var z1 := clampi(int(floor(_box.end.y / step + half)), 0, size - 1)
	var x0 := clampi(int(ceil(_box.position.x / step + half)), 0, size - 1)
	var x1 := clampi(int(floor(_box.end.x / step + half)), 0, size - 1)
	for z in range(z0, z1 + 1):
		var y := (float(z) - half) * step
		if y < _box.position.y or y > _box.end.y:
			continue
		var b := clampi(int(floor((y - _y0) / _band_h)), 0, _bands.size() - 1)
		# [x, ring] per crossing on this row; only rings the row crosses.
		var events: Array = []
		var outer_hits := 0
		for code in (_bands[b] as Array):
			var ri: int = code >> 32
			var ring: PackedVector2Array = _rings[ri]
			var i: int = code & 0xFFFFFFFF
			var pi := ring[i]
			var pj := ring[i - 1 if i > 0 else ring.size() - 1]
			if (pi.y > y) != (pj.y > y):
				events.append([(pj.x - pi.x) * (y - pi.y) / (pj.y - pi.y) + pi.x, ri])
				if ri == 0:
					outer_hits += 1
		if outer_hits == 0:
			continue
		events.sort_custom(func(e1: Array, e2: Array) -> bool: return e1[0] < e2[0])
		# A ring is odd (point inside it) when an odd number of its
		# crossings lie strictly to the right. Left of every crossing that
		# is the ring's total count; passing a crossing flips it.
		var odd: Dictionary = {}
		for e in events:
			odd[e[1]] = not bool(odd.get(e[1], false))
		var holes_odd := 0
		for ri in odd:
			if ri != 0 and odd[ri]:
				holes_odd += 1
		var ev := 0
		for x in range(x0, x1 + 1):
			var px := (float(x) - half) * step
			while ev < events.size() and float(events[ev][0]) <= px:
				var r: int = events[ev][1]
				var now := not bool(odd[r])
				odd[r] = now
				if r != 0:
					holes_odd += 1 if now else -1
				ev += 1
			if bool(odd[0]) and holes_odd == 0:
				out.append(z * size + x)
	return out
