class_name RailPlatforms
extends RefCounted

## Ground-level railway platforms, safety edge strips and sleek station canopies
## built from mapped `LocationData.rail_platforms` polygons and lines.
## Elevated rapid-transit guideway stations (Miami/Singapore) are handled by
## RailViaductLook; this builder handles surface heavy-rail stations such as
## Pasila (tracks 1–11), Helsinki Central, and stations worldwide.

## Finnish/European standard platform height over rail level (~0.55 m) plus
## track bed/rail lift (~0.18 m).
const PLATFORM_TOP_M := 0.72
const PLATFORM_FOUND_M := 0.45
const LINE_WIDTH_M := 3.4
const MIN_LENGTH_M := 16.0
const EDGE_INSET_M := 0.28
const EDGE_WIDTH_M := 0.18
const CANOPY_MIN_LEN_M := 42.0
const CANOPY_CLEAR_M := 4.4
const CANOPY_POST_STEP_M := 16.0
const MAX_CANOPY_W_M := 4.6
const OVERBUILD_PAD_M := 4.0

## Emits surface railway platform slabs, safety strips and open-air canopies
## into RailBuilder's `batches`.
static func build(batches: Dictionary, data: LocationData, surf: RoadBuilder._Surface, m2u: float) -> void:
	if data == null or data.rail_platforms.is_empty():
		return
	var overbuilds := _overbuild_boxes(data, m2u)
	var entries: Array = []
	for raw in data.rail_platforms:
		if not (raw is Dictionary):
			continue
		var pts: PackedVector2Array = (raw as Dictionary).get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var ext := _farthest_pair(pts)
		var length := (ext[0] as Vector2).distance_to(ext[1])
		if length < MIN_LENGTH_M * m2u:
			continue
		var mid: Vector2 = (ext[0] + ext[1]) * 0.5
		if not surf.inside(mid):
			continue
		entries.append({"pts": pts, "a": ext[0], "b": ext[1], "mid": mid, "len": length})
	if entries.is_empty():
		return
	# Longest first so small overlapping OSM sub-polygons can be skipped cleanly.
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["len"]) > float(b["len"]))
	var conc := RoadBuilder._batch(batches, "platform_concrete")
	var edge := RoadBuilder._batch(batches, "platform_edge")
	var canopy := RoadBuilder._batch(batches, "platform_canopy")
	var lamp := RoadBuilder._batch(batches, "platform_lamp")
	var emitted_polys: Array = []
	var slabs: Array = []
	for e: Dictionary in entries:
		var pts: PackedVector2Array = e["pts"]
		var mid: Vector2 = e["mid"]
		if _inside_any(emitted_polys, mid):
			continue
		var closed := pts.size() >= 4 and pts[0].distance_to(pts[pts.size() - 1]) < 0.5 * m2u
		var ring := _clean_ring(pts, m2u) if closed else _line_ring(pts, LINE_WIDTH_M * 0.5 * m2u)
		if ring.size() < 3:
			continue
		var box := _poly_box(ring)
		emitted_polys.append([box, ring])
		# Tiny deterministic height jitter (±6 mm) prevents z-fighting where
		# adjacent OSM platform halves share a boundary edge.
		var jitter := (TransitVehicles._hash(mid.x, mid.y, 19.3) - 0.5) * 0.012 * m2u
		var a: Vector2 = e["a"]
		var b: Vector2 = e["b"]
		var dir := (b - a).normalized()
		var n := Vector2(-dir.y, dir.x)
		var width := _span_across(ring, mid, n)
		_emit_slab(conc, ring, surf, m2u, jitter)
		slabs.append([ring, jitter])
		if float(e["len"]) >= CANOPY_MIN_LEN_M * m2u and width >= 2.4 * m2u:
			_emit_canopy(canopy, lamp, a, b, dir, n, minf(width * 0.72, MAX_CANOPY_W_M * m2u),
				surf, overbuilds, m2u)
	for slab: Array in slabs:
		_emit_safety_edges(edge, slab[0], emitted_polys, surf, m2u, float(slab[1]))

## Extrudes closed polygon `ring` from below ground up to PLATFORM_TOP_M,
## sampling terrain height per vertex so long platforms follow the grade.
static func _emit_slab(b: RoadBuilder._Batch, ring: PackedVector2Array, surf: RoadBuilder._Surface,
		m2u: float, jitter: float) -> void:
	var n := ring.size()
	var ys_top := PackedFloat32Array()
	var ys_bot := PackedFloat32Array()
	ys_top.resize(n)
	ys_bot.resize(n)
	for i in n:
		var gy := surf.height(ring[i].x, ring[i].y)
		ys_top[i] = gy + PLATFORM_TOP_M * m2u + jitter
		ys_bot[i] = gy - PLATFORM_FOUND_M * m2u
	# Top deck via ear-clipping triangulation.
	var tris := Geometry2D.triangulate_polygon(ring)
	if not tris.is_empty():
		var k0 := b.verts.size()
		for i in n:
			var p := ring[i]
			b.verts.append(Vector3(p.x, ys_top[i], p.y))
			b.normals.append(Vector3.UP)
			b.uvs.append(Vector2(p.x / (4.0 * m2u), p.y / (4.0 * m2u)))
		var i := 0
		while i + 2 < tris.size():
			var ia := k0 + tris[i]
			var ib := k0 + tris[i + 1]
			var ic := k0 + tris[i + 2]
			var cross := (b.verts[ib] - b.verts[ia]).cross(b.verts[ic] - b.verts[ia])
			if cross.y >= 0.0:
				b.indices.append(ia); b.indices.append(ib); b.indices.append(ic)
			else:
				b.indices.append(ia); b.indices.append(ic); b.indices.append(ib)
			i += 3
	# Perimeter vertical kerb walls.
	var cw := Geometry2D.is_polygon_clockwise(ring)
	for i in n:
		var j := (i + 1) % n
		var pa := ring[i]
		var pb := ring[j]
		var seg := pb - pa
		if seg.length_squared() < 1e-6:
			continue
		var out := Vector2(seg.y, -seg.x).normalized()
		if not cw:
			out = -out
		RoadBuilder._wall(b, pa, pb, ys_bot[i], ys_bot[j], ys_top[i], ys_top[j], out, true)

## High-contrast yellow safety strips inset slightly from track-facing platform
## edges (skipping interior seams shared between adjacent platform halves).
static func _emit_safety_edges(b: RoadBuilder._Batch, ring: PackedVector2Array, all_polys: Array,
		surf: RoadBuilder._Surface, m2u: float, jitter: float) -> void:
	var n := ring.size()
	var inset := EDGE_INSET_M * m2u
	var sw := EDGE_WIDTH_M * m2u
	var lift := (PLATFORM_TOP_M + 0.015) * m2u + jitter
	for i in n:
		var j := (i + 1) % n
		var pa := ring[i]
		var pb := ring[j]
		var seg := pb - pa
		var seg_len := seg.length()
		if seg_len < 12.0 * m2u:
			continue
		var inward := Vector2(-seg.y, seg.x).normalized()
		var edge_mid := (pa + pb) * 0.5
		if not Geometry2D.is_point_in_polygon(edge_mid + inward * (0.25 * m2u), ring):
			inward = -inward
		# Skip shared centre seams between paired island platform polygons.
		if _inside_any(all_polys, edge_mid - inward * (1.0 * m2u)):
			continue
		var a0 := pa + inward * inset
		var a1 := pa + inward * (inset + sw)
		var b0 := pb + inward * inset
		var b1 := pb + inward * (inset + sw)
		var ya := surf.height(pa.x, pa.y) + lift
		var yb := surf.height(pb.x, pb.y) + lift
		var k := b.verts.size()
		b.verts.append(Vector3(a0.x, ya, a0.y))
		b.verts.append(Vector3(a1.x, ya, a1.y))
		b.verts.append(Vector3(b0.x, yb, b0.y))
		b.verts.append(Vector3(b1.x, yb, b1.y))
		for _q in 4:
			b.normals.append(Vector3.UP)
		b.uvs.append(Vector2(0.0, 0.0)); b.uvs.append(Vector2(1.0, 0.0))
		b.uvs.append(Vector2(0.0, seg_len / m2u)); b.uvs.append(Vector2(1.0, seg_len / m2u))
		RoadBuilder._quad_up(b, k, k + 1, k + 2, k + 3)

## Sleek steel-and-glass open-air platform canopy along stretches clear of
## station overbuilds and bridges (e.g. north platforms of Pasila).
static func _emit_canopy(canopy: RoadBuilder._Batch, lamp: RoadBuilder._Batch, a: Vector2, b: Vector2,
		dir: Vector2, n: Vector2, width: float, surf: RoadBuilder._Surface, overbuilds: Array,
		m2u: float) -> void:
	var total := a.distance_to(b)
	# Sample in 8 m steps to find open-air runs (clear of concourse/bridge overbuilds).
	var step := 8.0 * m2u
	var count := maxi(2, int(floor(total / step)))
	var run_start := -1
	for i in count + 1:
		var t := float(i) / float(count)
		var p := a.lerp(b, t)
		var covered := _under_overbuild(overbuilds, p)
		var at_end := i == count
		if not covered and not at_end:
			if run_start < 0:
				run_start = i
		else:
			if run_start >= 0:
				var end_i := i if covered else count
				var pa := a.lerp(b, float(run_start) / float(count))
				var pb := a.lerp(b, float(end_i) / float(count))
				# Trim 10 m from the far open ends so canopies cover the boarding core.
				var seg_len := pa.distance_to(pb)
				if seg_len >= 28.0 * m2u:
					var trim := minf(8.0 * m2u, seg_len * 0.12)
					_emit_canopy_run(canopy, lamp, pa + dir * trim, pb - dir * trim, dir, n, width, surf, m2u)
				run_start = -1

static func _emit_canopy_run(canopy: RoadBuilder._Batch, lamp: RoadBuilder._Batch, pa: Vector2, pb: Vector2,
		dir: Vector2, n: Vector2, width: float, surf: RoadBuilder._Surface, m2u: float) -> void:
	var seg_len := pa.distance_to(pb)
	var mid := (pa + pb) * 0.5
	var y_plat := surf.height(mid.x, mid.y) + PLATFORM_TOP_M * m2u
	var y_roof := y_plat + CANOPY_CLEAR_M * m2u
	var hl := seg_len * 0.5
	var hw := width * 0.5
	var thick := 0.18 * m2u
	# Flat cantilevered canopy roof slab.
	RailViaductLook._frustum_box(canopy, mid, dir, n, hl, hw, y_roof, hl, hw, y_roof + thick, true, true)
	# Central spine lighting strip under the canopy soffit.
	RailViaductLook._frustum_box(lamp, mid, dir, n, hl - 1.5 * m2u, 0.18 * m2u, y_roof - 0.08 * m2u,
		hl - 1.5 * m2u, 0.18 * m2u, y_roof, false, true)
	# Slender central steel support posts.
	var posts := maxi(2, int(round(seg_len / (CANOPY_POST_STEP_M * m2u))) + 1)
	for k in posts:
		var u := lerpf(-hl + 2.5 * m2u, hl - 2.5 * m2u, float(k) / float(maxi(posts - 1, 1)))
		var cp := mid + dir * u
		var yp := surf.height(cp.x, cp.y) + PLATFORM_TOP_M * m2u
		RailViaductLook._frustum_box(canopy, cp, dir, n, 0.14 * m2u, 0.14 * m2u, yp,
			0.14 * m2u, 0.14 * m2u, y_roof)

static func _overbuild_boxes(data: LocationData, m2u: float) -> Array:
	var out: Array = []
	var pad := OVERBUILD_PAD_M * m2u
	for b in data.bridge_areas:
		if not (b is Dictionary):
			continue
		var pts: PackedVector2Array = (b as Dictionary).get("points", PackedVector2Array())
		if pts.size() >= 3:
			out.append([_poly_box(pts).grow(pad), pts])
	for b in data.buildings:
		if not (b is Dictionary):
			continue
		var kind := str((b as Dictionary).get("kind", ""))
		if kind in ["train_station", "roof", "canopy", "transportation"]:
			var pts: PackedVector2Array = (b as Dictionary).get("footprint", PackedVector2Array())
			if pts.size() >= 3:
				out.append([_poly_box(pts).grow(pad), pts])
	return out

static func _under_overbuild(overbuilds: Array, p: Vector2) -> bool:
	for o: Array in overbuilds:
		if (o[0] as Rect2).has_point(p) and Geometry2D.is_point_in_polygon(p, o[1]):
			return true
	return false

static func _inside_any(polys: Array, p: Vector2) -> bool:
	for poly: Array in polys:
		if (poly[0] as Rect2).has_point(p) and Geometry2D.is_point_in_polygon(p, poly[1]):
			return true
	return false

static func _clean_ring(pts: PackedVector2Array, m2u: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		if out.is_empty() or out[out.size() - 1].distance_to(p) > 0.05 * m2u:
			out.append(p)
	if out.size() >= 2 and out[0].distance_to(out[out.size() - 1]) < 0.5 * m2u:
		out.resize(out.size() - 1)
	return out

static func _line_ring(pts: PackedVector2Array, half_w: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in pts.size():
		var s := RoadBuilder._side(pts, i).normalized() * half_w
		left.append(pts[i] + s)
		right.append(pts[i] - s)
	right.reverse()
	left.append_array(right)
	return left

static func _poly_box(pts: PackedVector2Array) -> Rect2:
	var box := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		box = box.expand(p)
	return box

static func _span_across(ring: PackedVector2Array, mid: Vector2, n: Vector2) -> float:
	var lo := INF
	var hi := -INF
	for p in ring:
		var d := (p - mid).dot(n)
		lo = minf(lo, d)
		hi = maxf(hi, d)
	return maxf(hi - lo, 0.0)

static func _farthest_pair(pts: PackedVector2Array) -> Array:
	var a := pts[0]
	var b := pts[pts.size() - 1]
	var best := -1.0
	for i in pts.size():
		for j in range(i + 1, pts.size()):
			var d := pts[i].distance_squared_to(pts[j])
			if d > best:
				best = d
				a = pts[i]
				b = pts[j]
	return [a, b]
