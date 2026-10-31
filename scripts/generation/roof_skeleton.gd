class_name RoofSkeleton
extends RefCounted

## Chamfered roof for footprints a single ridge cannot span (courtyard
## blocks, concave civic wings, curved outlines): the roof height at a
## point follows its distance in from the eaves, rising along a profile
## (straight or mansard) over `run` and flat beyond. The distance field
## is sampled on inward offset contours (Clipper) plus the eave rings and
## Delaunay-triangulated, so concave notches, narrow wings and courtyards
## never fold into the vertical shards a mitred inset ring produced.

## [distance in / run, rise / rh] knots; contours are cut at each t.
const PROFILES := {
	"mansard": [[0.38, 0.75], [1.0, 1.0]],
	"straight": [[0.5, 0.5], [1.0, 1.0]],
}
const MERGE_M := 0.08

## Appends the roof's triangles (soup, via RoofGeometry.push_tri) rising
## rh above `top`. Returns false when nothing could be built.
static func faces(ring: PackedVector2Array, holes: Array, top: float, rh: float,
		mansard: bool, verts: PackedVector3Array, normals: PackedVector3Array,
		uvs: PackedVector2Array, fu: Vector2) -> bool:
	var m := WorldScale.metres_to_units()
	var run := clampf(rh * 1.1, 1.2 * m, 3.6 * m)
	var step := clampf(run * 1.2, 2.0 * m, 4.5 * m)
	var pts := PackedVector2Array()
	var lift := PackedFloat32Array()
	var seen := {}
	_add_ring(ring, step, 0.0, pts, lift, seen)
	for h in holes:
		_add_ring(h as PackedVector2Array, step, 0.0, pts, lift, seen)
	for knot in PROFILES["mansard" if mansard else "straight"]:
		var d: float = float(knot[0]) * run
		var f: float = float(knot[1])
		var grown: Array = []
		for h in holes:
			for g in Geometry2D.offset_polygon(h as PackedVector2Array, d, Geometry2D.JOIN_MITER):
				grown.append(g)
		var inner := Geometry2D.offset_polygon(ring, -d, Geometry2D.JOIN_MITER)
		for c in inner:
			_add_ring(c as PackedVector2Array, step, f, pts, lift, seen, [], grown)
		for g in grown:
			_add_ring(g as PackedVector2Array, step, f, pts, lift, seen, inner, [])
	if pts.size() < 3:
		return false
	var tri := Geometry2D.triangulate_delaunay(pts)
	var before := verts.size()
	for k in range(0, tri.size() - 2, 3):
		var a := tri[k]
		var b := tri[k + 1]
		var c := tri[k + 2]
		# Eave-level triangles lie on the seal cap: drop them (no z-fight).
		if lift[a] + lift[b] + lift[c] <= 0.0:
			continue
		if not _inside(ring, holes, [(pts[a] + pts[b] + pts[c]) / 3.0,
				(pts[a] + pts[b]) * 0.5, (pts[b] + pts[c]) * 0.5, (pts[c] + pts[a]) * 0.5]):
			continue
		RoofGeometry.push_tri(verts, normals, uvs, Vector2.ZERO,
			Vector3(pts[a].x, top + rh * lift[a], pts[a].y),
			Vector3(pts[b].x, top + rh * lift[b], pts[b].y),
			Vector3(pts[c].x, top + rh * lift[c], pts[c].y), fu, true)
	return verts.size() > before

## Ring points with edges split to `step`, each at relative height f.
## `within` (non-empty) keeps only points inside one of those rings,
## `outside` drops points inside any of them; near-duplicates merge.
static func _add_ring(r: PackedVector2Array, step: float, f: float,
		pts: PackedVector2Array, lift: PackedFloat32Array, seen: Dictionary,
		within: Array = [], outside: Array = []) -> void:
	var n := r.size()
	for i in n:
		var a := r[i]
		var b := r[(i + 1) % n]
		var parts := maxi(1, ceili((b - a).length() / step))
		for s in parts:
			var p := a.lerp(b, float(s) / parts)
			if not within.is_empty() and not _in_any(p, within):
				continue
			if _in_any(p, outside):
				continue
			var key := Vector2i(roundi(p.x / MERGE_M), roundi(p.y / MERGE_M))
			if seen.has(key):
				continue
			seen[key] = true
			pts.append(p)
			lift.append(f)

static func _inside(ring: PackedVector2Array, holes: Array, probes: Array) -> bool:
	for p in probes:
		if not Geometry2D.is_point_in_polygon(p, ring) or _in_any(p, holes):
			return false
	return true

static func _in_any(p: Vector2, rings: Array) -> bool:
	for r in rings:
		if Geometry2D.is_point_in_polygon(p, r as PackedVector2Array):
			return true
	return false
