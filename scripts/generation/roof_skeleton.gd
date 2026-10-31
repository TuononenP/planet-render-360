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
	# The slope reaches full height `run` in from the eaves; on a footprint
	# narrower than twice that it stops at the deepest point inside, so a
	# narrow house still rises to a full-height ridge.
	var run := minf(clampf(rh * 1.1, 1.2 * m, 3.6 * m), _depth(ring, holes) * 0.96)
	if run < 0.3 * m:
		return false
	# ...but no steeper than ~50° (the mansard's lower slope ~67°): a narrow
	# wing takes a lower roof rather than a near-vertical one.
	rh = minf(rh, run * 1.2)
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
	# Courtyards shrunk a hair for the probes: is_point_in_polygon counts a
	# point on the edge as inside, which dropped every slope triangle whose
	# base runs along the courtyard eave.
	var cores: Array = []
	for h in holes:
		cores.append_array(Geometry2D.offset_polygon(h as PackedVector2Array, -0.05 * m))
	for k in range(0, tri.size() - 2, 3):
		var a := tri[k]
		var b := tri[k + 1]
		var c := tri[k + 2]
		# Eave-level triangles lie on the seal cap: drop them (no z-fight).
		if lift[a] + lift[b] + lift[c] <= 0.0:
			continue
		if not _inside(ring, cores, [(pts[a] + pts[b] + pts[c]) / 3.0,
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

## Deepest inset (units) the footprint minus its courtyards allows: the
## largest d whose inward offset is still non-empty (bisection).
static func _depth(ring: PackedVector2Array, holes: Array) -> float:
	var lo := 0.0
	var hi := RingGeometry.aabb(ring).size.length() * 0.5
	for _i in 10:
		var d := (lo + hi) * 0.5
		if _survives(ring, holes, d):
			lo = d
		else:
			hi = d
	return lo

static func _survives(ring: PackedVector2Array, holes: Array, d: float) -> bool:
	var inner: Array = Geometry2D.offset_polygon(ring, -d, Geometry2D.JOIN_MITER)
	for h in holes:
		var next: Array = []
		for g in Geometry2D.offset_polygon(h as PackedVector2Array, d, Geometry2D.JOIN_MITER):
			for c in inner:
				next.append_array(Geometry2D.clip_polygons(c as PackedVector2Array, g as PackedVector2Array))
		inner = next
	return not inner.is_empty()

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
