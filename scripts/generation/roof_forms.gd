class_name RoofForms
extends RefCounted

## Ridge-family roof faces for RoofGeometry, street-aware: on party
## edges (PartyWalls) a roof keeps a vertical gable instead of sloping
## down to the neighbour, so a terrace of parcels reads as one roof that
## runs along the street — the ridge turns parallel to the street and
## runs into the party walls, and only exposed ends are hipped. Narrow
## gable-fronted houses (Amsterdam, old German towns: `gable` relief) turn
## the ridge the other way, front to back, so the gable faces the street.
## Also the shapes beyond the original six: gambrel (two pitches on the
## long sides, gable ends), half-hipped (jerkinhead), saltbox (ridge off
## centre), skillion (one plane), round (barrel vault).
## A leaf like RoofGeometry: it returns faces through RoofGeometry.push_tri.

## Ridge-family shapes the party rule applies to.
const RIDGED: Array[String] = ["gabled", "hipped", "mansard", "gambrel",
	"half-hipped", "saltbox"]
## Ridge half-length share kept at an exposed end, per shape (1 = gable).
const HIP_END := {"gabled": 0.98, "hipped": 0.45, "mansard": 0.45,
	"gambrel": 0.98, "half-hipped": 0.72, "saltbox": 0.98}
## Mansard / gambrel break: share of the run inward, of the rise up, and
## the longest run (m) — a Paris mansard's lower slope is near vertical
## (≈70°) however deep the block, its terrasson above nearly flat.
const BREAK := {"mansard": [0.38, 0.75, 1.5], "gambrel": [0.30, 0.55, 99.0]}
const BARREL_SEGMENTS := 8

## Faces for one ridge-family shape. `party` holds one flag per ring edge
## (empty: none); `gable_front` turns the ridge to face party walls with
## its gables. Returns false when no ridge fits (caller fans an apex).
static func ridged(ring: PackedVector2Array, c: Vector2, top: float, rh: float,
		shape: String, party: PackedByteArray, gable_front: bool,
		verts: PackedVector3Array, normals: PackedVector3Array,
		uvs: PackedVector2Array) -> bool:
	var u := ridge_axis(ring, party, gable_front)
	var has_party := party.size() == ring.size() and party.has(1)
	var v := Vector2(-u.y, u.x)
	var lo := INF
	var hi := -INF
	for p in ring:
		var d := (p - c).dot(u)
		lo = minf(lo, d)
		hi = maxf(hi, d)
	var keep := float(HIP_END.get(shape, 0.98))
	# A party wall at an end stands a full gable there; an exposed end
	# keeps the shape's own hip.
	var k_hi := 0.995 if has_party and _end_party(ring, party, u) else keep
	var k_lo := 0.995 if has_party and _end_party(ring, party, -u) else keep
	var off := v * _saltbox_offset(ring, c, v) if shape == "saltbox" else Vector2.ZERO
	var e_hi := _fit(c + off, u, hi * k_hi, ring)
	var e_lo := _fit(c + off, -u, -lo * k_lo, ring)
	if e_hi <= 0.0 and e_lo <= 0.0:
		return false
	var r1 := c + off + u * e_hi
	var r2 := c + off - u * e_lo
	if BREAK.has(shape):
		var br: Array = BREAK[shape]
		_two_pitch(ring, c, u, r1, r2, top, rh, float(br[0]), float(br[1]),
			float(br[2]) * WorldScale.metres_to_units(), verts, normals, uvs)
	else:
		_one_pitch(ring, c, u, r1, r2, top, rh, verts, normals, uvs)
	return true

## The ridge direction ridged() uses: the ring's long side, or along the
## party walls (across them when `gable_front`) on a terrace parcel.
static func ridge_axis(ring: PackedVector2Array, party: PackedByteArray, gable_front: bool) -> Vector2:
	if party.size() == ring.size() and party.has(1):
		var pu := _party_axis(ring, party)
		return Vector2(-pu.y, pu.x) if gable_front else pu
	return RingGeometry.dominant_axis(ring)

## True for a parcel-like ring (few corners, near-rectangular in its own
## axes): the only footprints a party-aligned ridge fits cleanly — on
## irregular rings the ridge ends overshoot and gable faces shear into
## shards, so those keep the plain ridge.
static func boxy(ring: PackedVector2Array) -> bool:
	if ring.size() > 8:
		return false
	var u := RingGeometry.dominant_axis(ring)
	var v := Vector2(-u.y, u.x)
	var c := RingGeometry.centroid(ring)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in ring:
		var q := Vector2((p - c).dot(u), (p - c).dot(v))
		lo = lo.min(q)
		hi = hi.max(q)
	var box := (hi.x - lo.x) * (hi.y - lo.y)
	return box > 0.0 and absf(RingGeometry.signed_area(ring)) / box > 0.85

## Direction (unit) across the party walls: the outward normal of the
## longest party edge, folded like dominant_axis. The ridge of a street
## roof runs along it, wall to wall.
static func _party_axis(ring: PackedVector2Array, party: PackedByteArray) -> Vector2:
	var best := -1.0
	var axis := Vector2.RIGHT
	for i in ring.size():
		if party[i] == 0:
			continue
		var e := ring[(i + 1) % ring.size()] - ring[i]
		if e.length_squared() > best:
			best = e.length_squared()
			axis = Vector2(e.y, -e.x).normalized()
	if axis.x < -0.000001 or (absf(axis.x) <= 0.000001 and axis.y < 0.0):
		axis = -axis
	return axis

## True when a party edge faces direction `dir` (the ridge end there).
static func _end_party(ring: PackedVector2Array, party: PackedByteArray, dir: Vector2) -> bool:
	for i in ring.size():
		if party[i] == 1 and PartyWalls.outward(ring, i).dot(dir) > 0.7:
			return true
	return false

## Saltbox: the ridge moves a quarter of the span toward one side (the
## long rear slope runs down the other).
static func _saltbox_offset(ring: PackedVector2Array, c: Vector2, v: Vector2) -> float:
	return RingGeometry.half_extent(ring, c, v) * 0.35

## Ridge half-length from `c` toward `dir`, shrunk until its end sits in
## the ring (0 when none fits).
static func _fit(c: Vector2, dir: Vector2, len: float, ring: PackedVector2Array) -> float:
	var guard := 0
	while len > 0.05 and guard < 12 and not RingGeometry.point_in_ring(c + dir * len, ring):
		len *= 0.85
		guard += 1
	return len if len > 0.05 and RingGeometry.point_in_ring(c + dir * len, ring) else 0.0

## One quad per edge from the eaves to its projection on the ridge r1–r2.
static func _one_pitch(ring: PackedVector2Array, c: Vector2, u: Vector2,
		r1: Vector2, r2: Vector2, top: float, rh: float,
		verts: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array) -> void:
	var d := r2 - r1
	var denom := maxf(d.length_squared(), 0.000001)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		if (b - a).length() < 0.001:
			continue
		var pa := r1 + d * clampf((a - r1).dot(d) / denom, 0.0, 1.0)
		var pb := r1 + d * clampf((b - r1).dot(d) / denom, 0.0, 1.0)
		var a3 := Vector3(a.x, top, a.y)
		var b3 := Vector3(b.x, top, b.y)
		var pa3 := Vector3(pa.x, top + rh, pa.y)
		var pb3 := Vector3(pb.x, top + rh, pb.y)
		RoofGeometry.push_tri(verts, normals, uvs, c, a3, pa3, pb3, u)
		RoofGeometry.push_tri(verts, normals, uvs, c, a3, pb3, b3, u)

## Two pitches per edge: steep from the eaves to a break line `run` of the
## way in at `rise` of the height, then shallow to the ridge (mansard on
## every side; gambrel's gable ends come from a full-length ridge).
static func _two_pitch(ring: PackedVector2Array, c: Vector2, u: Vector2,
		r1: Vector2, r2: Vector2, top: float, rh: float, run: float, rise: float,
		max_run: float, verts: PackedVector3Array, normals: PackedVector3Array,
		uvs: PackedVector2Array) -> void:
	var d := r2 - r1
	var denom := maxf(d.length_squared(), 0.000001)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		if (b - a).length() < 0.001:
			continue
		var qa := r1 + d * clampf((a - r1).dot(d) / denom, 0.0, 1.0)
		var qb := r1 + d * clampf((b - r1).dot(d) / denom, 0.0, 1.0)
		var a3 := Vector3(a.x, top, a.y)
		var b3 := Vector3(b.x, top, b.y)
		var ma := a.lerp(qa, minf(run, max_run / maxf(a.distance_to(qa), 0.001)))
		var mb := b.lerp(qb, minf(run, max_run / maxf(b.distance_to(qb), 0.001)))
		var ma3 := Vector3(ma.x, top + rh * rise, ma.y)
		var mb3 := Vector3(mb.x, top + rh * rise, mb.y)
		var ta3 := Vector3(qa.x, top + rh, qa.y)
		var tb3 := Vector3(qb.x, top + rh, qb.y)
		RoofGeometry.push_tri(verts, normals, uvs, c, a3, b3, mb3, u)
		RoofGeometry.push_tri(verts, normals, uvs, c, a3, mb3, ma3, u)
		RoofGeometry.push_tri(verts, normals, uvs, c, ma3, mb3, tb3, u)
		RoofGeometry.push_tri(verts, normals, uvs, c, ma3, tb3, ta3, u)

## One plane rising across the short span (a lean-to: high against a
## party wall when there is one), with the side infills under it.
static func skillion(ring: PackedVector2Array, c: Vector2, top: float, rh: float,
		party: PackedByteArray, verts: PackedVector3Array, normals: PackedVector3Array,
		uvs: PackedVector2Array) -> void:
	var u := RingGeometry.dominant_axis(ring)
	var v := Vector2(-u.y, u.x)
	if party.size() == ring.size() and party.has(1):
		v = _party_axis(ring, party)
		if not _end_party(ring, party, v):
			v = -v
	var lv := maxf(RingGeometry.half_extent(ring, c, v), 0.01)
	var hs := PackedFloat32Array()
	for p in ring:
		hs.append(top + rh * clampf(0.5 + 0.5 * (p - c).dot(v) / lv, 0.0, 1.0))
	var idx := Geometry2D.triangulate_polygon(ring)
	for k in range(0, idx.size() - 2, 3):
		var p0 := ring[idx[k]]
		var p1 := ring[idx[k + 1]]
		var p2 := ring[idx[k + 2]]
		RoofGeometry.push_tri(verts, normals, uvs, c, Vector3(p0.x, hs[idx[k]], p0.y),
			Vector3(p1.x, hs[idx[k + 1]], p1.y), Vector3(p2.x, hs[idx[k + 2]], p2.y), u, true)
	for i in ring.size():
		var j := (i + 1) % ring.size()
		var a := ring[i]
		var b := ring[j]
		if hs[i] - top < 0.01 and hs[j] - top < 0.01:
			continue
		RoofGeometry.push_tri(verts, normals, uvs, c, Vector3(a.x, top, a.y),
			Vector3(b.x, top, b.y), Vector3(b.x, hs[j], b.y), u)
		RoofGeometry.push_tri(verts, normals, uvs, c, Vector3(a.x, top, a.y),
			Vector3(b.x, hs[j], b.y), Vector3(a.x, hs[i], a.y), u)

## Barrel vault along the long axis (four-cornered footprints; others
## fall back to gabled): arc strips across the short span plus the two
## arched end faces.
static func barrel(ring: PackedVector2Array, c: Vector2, top: float, rh: float,
		verts: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array) -> bool:
	if ring.size() != 4:
		return false
	var u := RingGeometry.dominant_axis(ring)
	var v := Vector2(-u.y, u.x)
	var lu := RingGeometry.half_extent(ring, c, u)
	var lv := RingGeometry.half_extent(ring, c, v)
	var prev_a := Vector3.ZERO
	var prev_b := Vector3.ZERO
	for s in BARREL_SEGMENTS + 1:
		var ang := PI * float(s) / float(BARREL_SEGMENTS)
		var dv := -cos(ang) * lv
		var y := top + sin(ang) * rh
		var pa := c + u * lu + v * dv
		var pb := c - u * lu + v * dv
		var a3 := Vector3(pa.x, y, pa.y)
		var b3 := Vector3(pb.x, y, pb.y)
		if s > 0:
			RoofGeometry.push_tri(verts, normals, uvs, c, prev_a, a3, b3, u, true)
			RoofGeometry.push_tri(verts, normals, uvs, c, prev_a, b3, prev_b, u, true)
			for end in [[prev_a, a3, c + u * lu], [prev_b, b3, c - u * lu]]:
				var m: Vector2 = end[2]
				RoofGeometry.push_tri(verts, normals, uvs, c, end[0], end[1],
					Vector3(m.x, top, m.y), u)
		prev_a = a3
		prev_b = b3
	return true
