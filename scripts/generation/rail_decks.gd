class_name RailDecks
extends RefCounted

## One height for bridge tracks that run side by side. A station's
## viaduct is mapped a bridge way per track, and each deck followed the
## ground under its own line: on ground sloping across the viaduct the
## tracks stepped down it like terraces. Here every track takes the
## height of the highest one beside it, passed along from track to
## track, so a fan of tracks shares one level across.
## RailBuilder draws the decks and rails at these heights and
## StationTrains stands its trains on them.

## Spacing of the sampled heights along a track, and how far along a
## point looks for a track beside it.
const STEP_M := 2.0
const ALONG_M := 1.5
const PASSES := 48
## Tracks this far apart still share a level: a viaduct's tracks stand
## in groups with a strip between them, wider than the gap a parapet is
## left out over (RailBuilder.BESIDE_M).
const LEVEL_M := 12.0

var _m2u := 1.0
var _pts := PackedVector2Array()
var _dirs := PackedVector2Array()
var _hs := PackedFloat32Array()
var _cells := {}

static var _last: RailDecks
static var _last_rails: Array
static var _last_ground: GroundTruth

## The levels of `data`'s bridge tracks over `surf`'s ground; built once
## for the builders that share them.
static func of(data: LocationData, surf: RoadBuilder._Surface, m2u: float) -> RailDecks:
	if _last != null and is_same(_last_rails, data.railways) and _last_ground == surf.ground:
		return _last
	_last = RailDecks.new(data.railways, surf, m2u)
	_last_rails = data.railways
	_last_ground = surf.ground
	return _last

func _init(railways: Array, surf: RoadBuilder._Surface, m2u: float) -> void:
	_m2u = m2u
	for w in railways:
		if not (w is Dictionary) or not bool((w as Dictionary).get("bridge", false)) \
				or bool((w as Dictionary).get("tunnel", false)):
			continue
		var way: Dictionary = w
		var pts := PackedVector2Array()
		for p in RoadBuilder._resample(way.get("points", PackedVector2Array()), STEP_M * m2u):
			if surf.inside(p):
				pts.append(p)
		if pts.size() < 2:
			continue
		var deck := RoadBuilder.deck_profile(pts, surf, m2u, float(way.get("width_m", 3.3)) * m2u * 0.5, 0, false)
		if deck.size() != pts.size():
			continue
		for i in pts.size():
			var cell := _cell(pts[i])
			if not _cells.has(cell):
				_cells[cell] = PackedInt32Array()
			var ids: PackedInt32Array = _cells[cell]
			ids.append(_pts.size())
			_cells[cell] = ids
			_pts.append(pts[i])
			_dirs.append((pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized())
			_hs.append(deck[i])
	# Each point's tracks alongside, then the highest passed across them
	# until nothing rises.
	var links: Array[PackedInt32Array] = []
	for i in _pts.size():
		links.append(_beside(_pts[i], _dirs[i]))
	for pass_k in PASSES:
		var rose := false
		for i in _pts.size():
			for j in links[i]:
				if _hs[j] > _hs[i] + 0.0005 * m2u:
					_hs[i] = _hs[j]
					rose = true
		if not rose:
			break

func _cell(p: Vector2) -> Vector2i:
	return Vector2i((p / (LEVEL_M * _m2u)).floor())

## The sampled points of other tracks alongside `p` (heading `dir`).
func _beside(p: Vector2, dir: Vector2) -> PackedInt32Array:
	var out := PackedInt32Array()
	var cell := _cell(p)
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var ids: PackedInt32Array = _cells.get(cell + Vector2i(dx, dz), PackedInt32Array())
			for j in ids:
				var v := _pts[j] - p
				var side := absf(v.x * dir.y - v.y * dir.x)
				if side > RailBuilder.BESIDE_MIN_M * _m2u and side < LEVEL_M * _m2u \
						and absf(v.dot(dir)) < ALONG_M * _m2u:
					out.append(j)
	return out

## `deck` (RoadBuilder.deck_profile along `pts`) raised to the level of
## the tracks alongside, eased in and out at a ramp's grade where a
## track joins or leaves them. A track on its own keeps its profile.
func level(pts: PackedVector2Array, deck: PackedFloat32Array) -> PackedFloat32Array:
	var n := pts.size()
	var out := deck.duplicate()
	if _pts.is_empty() or n < 2 or deck.size() != n:
		return out
	var lift := PackedFloat32Array()
	var any := false
	for i in n:
		var dir := (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var high := deck[i]
		for j in _beside(pts[i], dir):
			high = maxf(high, _hs[j])
		lift.append(high - deck[i])
		any = any or high > deck[i]
	if not any:
		return out
	for i in range(1, n):
		lift[i] = maxf(lift[i], lift[i - 1] - RoadBuilder.RAMP_GRADE * pts[i].distance_to(pts[i - 1]))
	for i in range(n - 2, -1, -1):
		lift[i] = maxf(lift[i], lift[i + 1] - RoadBuilder.RAMP_GRADE * pts[i].distance_to(pts[i + 1]))
	for i in n:
		out[i] += lift[i]
	return out
