class_name BridgeCamber
extends RefCounted

## Humps a parametric bridge (BridgeParam) built level at its banks'
## height: the deck keeps that height at both ends and rises `rise`
## metres to mid-span on an eased curve, as a river bridge between low quays
## does. Everything over the water rides up with it whole (girders, ribs
## and arches keep their depth and shape), and only what stands in the
## water's first FOOT_M stretches: the piers grow taller toward the
## middle, their feet stay on the water. Stretched in proportion to its
## height instead, a girder nearly as deep as a low deck swelled into a
## wall at mid-span. The triangles are first cut along the bridge so a
## long slab bends instead of staying a straight plank.

## Longest piece of a triangle along the bridge after cutting: this
## share of the half length, never under MIN_STEP_M.
const STEP_SHARE := 0.125
const MIN_STEP_M := 3.0
## Height over the water above which a part rides the hump whole
## (never more than FOOT_SHARE of the deck's height), metres.
const FOOT_M := 1.0
const FOOT_SHARE := 0.4
## Most cuts of one triangle (a guard, never reached by a sane model).
const MAX_PIECES := 4096

## How far the deck stands over its ends at `x`, `half` from the middle:
## level at the ends, so the deck eases onto its road with no crease, and
## steepest about a fifth of the way in.
static func lift(x: float, half: float, rise: float) -> float:
	var k := clampf(x / maxf(half, 0.001), -1.0, 1.0)
	var u := 1.0 - k * k
	return rise * u * u

## Steepest grade of `lift` is this many times rise / half (at k = 1/√3).
const LIFT_STEEPEST := 1.54
## Steepest grade of `ramp` is this many times tilt / half (at mid-span).
const RAMP_STEEPEST := 1.5

## How far the deck stands over its middle at `x` on banks of unequal
## height: `tilt` up at the +X end and down at the -X end, level at both
## so the deck meets each road without a crease.
static func ramp(x: float, half: float, tilt: float) -> float:
	var k := clampf(x / maxf(half, 0.001), -1.0, 1.0)
	return tilt * (1.5 * k - 0.5 * k * k * k)

## `tilt` raises the +X end and lowers the -X end by that much, on an
## S-curve along the bridge (banks of unequal height).
static func apply(lm: LandmarkMesh, half: float, deck: float, rise: float, tilt: float = 0.0) -> void:
	if (rise <= 0.0 and is_zero_approx(tilt)) or half <= 0.0 or deck <= 0.0:
		return
	var step := maxf(half * STEP_SHARE, MIN_STEP_M)
	var foot := minf(FOOT_M, deck * FOOT_SHARE)
	for key: String in lm._order:
		var s: LandmarkMesh.Surf = lm._surfs[key]
		var v := PackedVector3Array()
		var n := PackedVector3Array()
		var uv := PackedVector2Array()
		for t in range(0, s.v.size() - 2, 3):
			# Each edge longer than `step` along the bridge is halved at its
			# midpoint, the same point for both triangles sharing it: no cracks.
			var stack: Array = [[s.v[t], s.v[t + 1], s.v[t + 2], s.n[t], s.n[t + 1], s.n[t + 2],
				s.uv[t], s.uv[t + 1], s.uv[t + 2]]]
			var made := 0
			while not stack.is_empty():
				var tri: Array = stack.pop_back()
				var e := -1
				var longest := step
				for i in 3:
					var dx := absf((tri[i] as Vector3).x - (tri[(i + 1) % 3] as Vector3).x)
					if dx > longest:
						longest = dx
						e = i
				if e < 0 or made >= MAX_PIECES:
					for i in 3:
						v.append(tri[i])
						n.append(tri[3 + i])
						uv.append(tri[6 + i])
					continue
				made += 1
				var a := e
				var b := (e + 1) % 3
				var c := (e + 2) % 3
				var mv := ((tri[a] as Vector3) + (tri[b] as Vector3)) * 0.5
				var mn := ((tri[3 + a] as Vector3) + (tri[3 + b] as Vector3)).normalized()
				var mu := ((tri[6 + a] as Vector2) + (tri[6 + b] as Vector2)) * 0.5
				stack.append([tri[a], mv, tri[c], tri[3 + a], mn, tri[3 + c], tri[6 + a], mu, tri[6 + c]])
				stack.append([mv, tri[b], tri[c], mn, tri[3 + b], tri[3 + c], mu, tri[6 + b], tri[6 + c]])
		for i in v.size():
			var p := v[i]
			p.y += (lift(p.x, half, rise) + ramp(p.x, half, tilt)) * clampf(p.y / foot, 0.0, 1.0)
			v[i] = p
		s.v = v
		s.n = n
		s.uv = uv
