class_name RoadGrading
extends RefCounted

## Road grading for GroundTruth: DEM noise and the 9–25 m post grid make
## a street ride every bump and crease of the terrain mesh, so its ribbon
## looks wobbly. Each street and main road gets a smoothed height profile
## along its centreline (a triangular low-pass over SMOOTH_M), and the
## posts around it are pulled onto that profile: fully across the
## carriageway plus a margin, easing out to the surroundings. The ribbon
## RoadBuilder drapes on the graded surface then runs flush and fair.
## Bridges, tunnels, footpaths and carved water posts are left alone.

## Half-window of the profile low-pass, metres of road.
const SMOOTH_M := 40.0
## Centreline sample spacing, metres.
const SAMPLE_M := 4.0
## Largest cut or fill a post takes (source metres), so a real hillside
## road is not bulldozed flat. DEM noise and post-grid creases fit within
## a metre; at 2.5 m a crest on a Turku hill street was cut 2.3 m, and on
## a 9–25 m grid the ground beside the street went down with it.
const MAX_SHIFT_M := 1.0

## Grades `surface` (size × size posts, `step` units apart, source
## metres in Y) in place. `level` marks carved water posts (-INF = dry).
static func grade(surface: PackedFloat32Array, level: PackedFloat32Array,
		size: int, step: float, roads: Array, m2u: float) -> void:
	if size < 2 or roads.is_empty():
		return
	var src := surface.duplicate()
	var best_w := PackedFloat32Array()
	best_w.resize(size * size)
	var best_h := PackedFloat32Array()
	best_h.resize(size * size)
	for road in roads:
		if not (road is Dictionary):
			continue
		var r: Dictionary = road
		if bool(r.get("bridge", false)) or bool(r.get("tunnel", false)):
			continue
		if RoadBuilder._rank(str(r.get("class", "unclassified"))) < 1:
			continue
		var pts: PackedVector2Array = r.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var half := maxf(float(r.get("width_m", 0.0)), 3.0) * 0.5 * m2u
		var line := GroundTruth._densify(pts, SAMPLE_M * m2u)
		var heights := PackedFloat32Array()
		var valid := PackedByteArray()
		var arc := PackedFloat32Array()
		var s := 0.0
		for i in line.size():
			if i > 0:
				s += line[i].distance_to(line[i - 1])
			arc.append(s)
			var p := line[i]
			heights.append(_sample(src, size, step, p))
			valid.append(1 if _dry(level, size, step, p) else 0)
		var prof := _smooth(heights, valid, arc, SMOOTH_M * m2u)
		for i in line.size():
			if valid[i] == 1:
				_stamp(line[i], prof[i], half, src, best_w, best_h, level, size, step)
	for i in size * size:
		if best_w[i] > 0.0:
			surface[i] = lerpf(surface[i], best_h[i], best_w[i])

## Triangular low-pass of the dry samples within `radius` of each one.
static func _smooth(h: PackedFloat32Array, valid: PackedByteArray,
		arc: PackedFloat32Array, radius: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var n := h.size()
	for i in n:
		var sum := 0.0
		var wsum := 0.0
		var j := i
		while j >= 0 and arc[i] - arc[j] <= radius:
			if valid[j] == 1:
				var w := 1.0 - (arc[i] - arc[j]) / radius
				sum += h[j] * w
				wsum += w
			j -= 1
		j = i + 1
		while j < n and arc[j] - arc[i] <= radius:
			if valid[j] == 1:
				var w2 := 1.0 - (arc[j] - arc[i]) / radius
				sum += h[j] * w2
				wsum += w2
			j += 1
		out.append(sum / wsum if wsum > 0.0 else h[i])
	return out

## Pulls posts near `p` toward `target`: weight 1 across the carriageway
## and a post of margin, easing to 0 by 1.8 posts out.
static func _stamp(p: Vector2, target: float, half: float, src: PackedFloat32Array,
		best_w: PackedFloat32Array, best_h: PackedFloat32Array,
		level: PackedFloat32Array, size: int, step: float) -> void:
	var inner := half + step * 0.5
	var reach := half + step * 1.8
	var hs := float(size) * 0.5
	var x0 := clampi(int(floor((p.x - reach) / step + hs)), 0, size - 1)
	var x1 := clampi(int(ceil((p.x + reach) / step + hs)), 0, size - 1)
	var z0 := clampi(int(floor((p.y - reach) / step + hs)), 0, size - 1)
	var z1 := clampi(int(ceil((p.y + reach) / step + hs)), 0, size - 1)
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			var i := z * size + x
			if not is_inf(level[i]):
				continue
			var d := Vector2((float(x) - hs) * step, (float(z) - hs) * step).distance_to(p)
			if d >= reach:
				continue
			var w := 1.0 - smoothstep(inner, reach, d)
			if w > best_w[i]:
				best_w[i] = w
				best_h[i] = clampf(target, src[i] - MAX_SHIFT_M, src[i] + MAX_SHIFT_M)

## True when the post nearest `p` is inside the surface and not water-carved.
static func _dry(level: PackedFloat32Array, size: int, step: float, p: Vector2) -> bool:
	var hs := float(size) * 0.5
	var x := roundi(p.x / step + hs)
	var z := roundi(p.y / step + hs)
	if x < 0 or z < 0 or x >= size or z >= size:
		return false
	return is_inf(level[z * size + x])

## Bilinear height of the post grid at world XZ (clamped to the edge).
static func _sample(h: PackedFloat32Array, size: int, step: float, p: Vector2) -> float:
	var hs := float(size) * 0.5
	var fx := clampf(p.x / step + hs, 0.0, float(size - 1))
	var fz := clampf(p.y / step + hs, 0.0, float(size - 1))
	var x0 := mini(int(fx), size - 2)
	var z0 := mini(int(fz), size - 2)
	var tx := fx - float(x0)
	var tz := fz - float(z0)
	var a := lerpf(h[z0 * size + x0], h[z0 * size + x0 + 1], tx)
	var b := lerpf(h[(z0 + 1) * size + x0], h[(z0 + 1) * size + x0 + 1], tx)
	return lerpf(a, b, tz)
