class_name UrbanSmooth
extends RefCounted

## Block-scale smoothing of a coarse surface-model DEM under a city, for
## GroundTruth. SRTM / EU-DEM class heights (no bare-earth model replacing
## them: Seoul, Busan, Istanbul ...) keep 3–8 m mounds 30–90 m across where
## city blocks and canopy stood even after BareEarth, so every street rolls
## over them. Grading each road on its own profile cannot remove them: two
## crossing streets settle at different heights and the junctions step.
## Here the ground itself is low-passed (two separable box passes, about a
## Gaussian of RADIUS_M) wherever mapped buildings stand, feathered out at
## the edge of the built area, and no post moves more than MAX_SHIFT_M, so
## hills inside a city (Namsan, Bugaksan's foot) keep their shape and only
## the block-scale mounds go. Bare-earth models and ArcticDEM are left alone
## (RoadGrading.coarse decides).

## Half-width of each box pass (m): two passes span about a block.
const RADIUS_M := 45.0
## Reach (m) of the built area around mapped footprints.
const URBAN_M := 60.0
## Largest cut or fill a post takes (source metres).
const MAX_SHIFT_M := 3.0

## Smooths `surface` (size × size posts, `step` units apart, source metres
## in Y; post (x, z) at ((x - half) * step, (z - half) * step)) in place.
static func apply(surface: PackedFloat32Array, size: int, step: float, half: float,
		buildings: Array) -> void:
	if size < 3 or buildings.is_empty():
		return
	var step_m := step / WorldScale.metres_to_units()
	var r := maxi(1, roundi(RADIUS_M / step_m))
	var built := BareEarth._footprint_mask(size, step, half, buildings)
	var urban := BareEarth._dilate(built, size, maxi(1, roundi(URBAN_M / step_m)))
	var weight := PackedFloat32Array()
	weight.resize(size * size)
	var any := false
	for i in size * size:
		weight[i] = 1.0 if urban[i] != 0 else 0.0
		any = any or urban[i] != 0
	if not any:
		return
	# A soft edge: the urban mask blurred once, so the smoothing fades out
	# over about one RADIUS_M instead of stepping at the mask.
	weight = _box(_box(weight, size, r, true), size, r, false)
	var smooth := surface.duplicate()
	for k in 2:
		smooth = _box(_box(smooth, size, r, true), size, r, false)
	for i in size * size:
		if weight[i] <= 0.0:
			continue
		var target := clampf(smooth[i], surface[i] - MAX_SHIFT_M, surface[i] + MAX_SHIFT_M)
		surface[i] = lerpf(surface[i], target, minf(weight[i], 1.0))

## One box pass of half-width `r` posts along rows (`horizontal`) or
## columns, the window clipped at the grid edge.
static func _box(src: PackedFloat32Array, size: int, r: int, horizontal: bool) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(size * size)
	for line in size:
		var sum := 0.0
		var n := 0
		for j in range(0, mini(r, size - 1) + 1):
			sum += src[_at(line, j, size, horizontal)]
			n += 1
		for j in size:
			out[_at(line, j, size, horizontal)] = sum / float(n)
			var add := j + r + 1
			var drop := j - r
			if add < size:
				sum += src[_at(line, add, size, horizontal)]
				n += 1
			if drop >= 0:
				sum -= src[_at(line, drop, size, horizontal)]
				n -= 1
	return out

static func _at(line: int, j: int, size: int, horizontal: bool) -> int:
	return line * size + j if horizontal else j * size + line
