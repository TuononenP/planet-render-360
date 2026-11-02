class_name LandmarkCoreBBridgeKit
extends RefCounted

## Shared bridge parts for the core bridges, in true metres on
## LandmarkMesh: round cables along a polyline, trusses between two
## chord polylines, sagging cable curves and deck lamp standards.

## Round tube of radius r through `pts` (a cable, a chain), `seg` sides,
## smooth normals; the ends are left open (they bury in saddles).
static func tube(lm: LandmarkMesh, key: String, pts: PackedVector3Array, r: float, seg: int = 8) -> void:
	var rings: Array = []
	var norms: Array = []
	for i in pts.size():
		var t := pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]
		t = t.normalized()
		var s := t.cross(Vector3.UP)
		if s.length() < 0.01:
			s = t.cross(Vector3.RIGHT)
		s = s.normalized()
		var u := s.cross(t).normalized()
		var ring := PackedVector3Array()
		var nring := PackedVector3Array()
		for k in seg + 1:
			var a := TAU * float(k) / float(seg)
			var d := s * cos(a) + u * sin(a)
			ring.append(pts[i] + d * r)
			nring.append(d)
		rings.append(ring)
		norms.append(nring)
	var v := 0.0
	for i in pts.size() - 1:
		var r0: PackedVector3Array = rings[i]
		var r1: PackedVector3Array = rings[i + 1]
		var n0: PackedVector3Array = norms[i]
		var n1: PackedVector3Array = norms[i + 1]
		var v1 := v + pts[i].distance_to(pts[i + 1])
		var circ := TAU * r
		for k in seg:
			var u0 := circ * float(k) / float(seg)
			var u1 := circ * float(k + 1) / float(seg)
			lm.tri(key, r0[k], r0[k + 1], r1[k + 1], n0[k], n0[k + 1], n1[k + 1],
				Vector2(u0, -v), Vector2(u1, -v), Vector2(u1, -v1))
			lm.tri(key, r0[k], r1[k + 1], r1[k], n0[k], n1[k + 1], n1[k],
				Vector2(u0, -v), Vector2(u1, -v1), Vector2(u0, -v1))
		v = v1

## Points of a cable from a to b sagging `sag` below the chord at its
## middle (a parabola), n + 1 points.
static func sag_points(a: Vector3, b: Vector3, sag: float, n: int) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for k in n + 1:
		var t := float(k) / float(n)
		pts.append(a.lerp(b, t) - Vector3(0, sag * 4.0 * t * (1.0 - t), 0))
	return pts

## Truss in one plane between a bottom and a top chord polyline (same
## point count, one panel point each): chords `cw` square, verticals and
## diagonals `w`, the diagonals turning at the middle (Warren with
## verticals, as on stiffening and deck trusses). `face_n` is the
## truss plane's normal, so members show their flat face.
static func truss(lm: LandmarkMesh, key: String, bottom: PackedVector3Array, top: PackedVector3Array,
		cw: float, w: float, face_n: Vector3, verticals: bool = true, chords: bool = true) -> void:
	var n := bottom.size()
	for i in n:
		if verticals:
			lm.beam(key, bottom[i], top[i], w, w, face_n.cross(top[i] - bottom[i]))
		if i == n - 1:
			break
		if chords:
			lm.beam(key, bottom[i], bottom[i + 1], cw, cw, face_n)
			lm.beam(key, top[i], top[i + 1], cw, cw, face_n)
		if i < n / 2:
			lm.beam(key, bottom[i], top[i + 1], w, w * 0.8, face_n.cross(top[i + 1] - bottom[i]))
		else:
			lm.beam(key, top[i], bottom[i + 1], w, w * 0.8, face_n.cross(bottom[i + 1] - top[i]))

## Deck lamp standard at `base`: fluted post, collar, an arm reaching
## over the road along `arm` and a lit lantern under its end.
static func lamp(lm: LandmarkMesh, post: String, glow: String, base: Vector3, h: float, arm: Vector3) -> void:
	lm.frustum(post, base, 0.22, 0.2, 0.9, 8)
	lm.frustum(post, base + Vector3(0, 0.9, 0), 0.12, 0.08, h - 0.9, 6)
	var top := base + Vector3(0, h, 0)
	lm.beam(post, top - Vector3(0, 0.6, 0), top + arm, 0.1, 0.1)
	lm.box(glow, top + arm - Vector3(0, 0.25, 0), Vector3(0.5, 0.35, 0.5), Basis(), 0.0)

## Pointed (two-centred Gothic) arch head over a passage running along
## X through a wall `depth` thick centred at x: `span` wide at z = cz,
## arcs of `radius` springing at `spring`. Fills the spandrels on both
## faces up to the crown and lines the soffit; returns the crown height.
static func pointed_arch(lm: LandmarkMesh, key: String, x: float, depth: float, cz: float, span: float,
		radius: float, spring: float) -> float:
	var hs := span * 0.5
	var off := radius - hs
	var rise := sqrt(radius * radius - off * off)
	var crown := spring + rise
	var tmax := acos(off / radius)
	for half in 2:
		var sgn := -1.0 if half == 0 else 1.0
		var centre := cz - sgn * off
		var pts := PackedVector2Array()
		for k in 9:
			var t := tmax * float(k) / 8.0
			pts.append(Vector2(centre + sgn * radius * cos(t), spring + radius * sin(t)))
		for f in [-1.0, 1.0]:
			var fx: float = x + f * depth * 0.5
			var nrm := Vector3(f, 0, 0)
			var corner := Vector3(fx, crown, cz + sgn * hs)
			for i in 8:
				var a := Vector3(fx, pts[i].y, pts[i].x)
				var b := Vector3(fx, pts[i + 1].y, pts[i + 1].x)
				lm.tri(key, corner, a, b, nrm, nrm, nrm, Vector2(corner.z, -corner.y),
					Vector2(a.z, -a.y), Vector2(b.z, -b.y))
		for i in 8:
			var p0 := pts[i]
			var p1 := pts[i + 1]
			var inward := Vector3(0, spring - (p0.y + p1.y) * 0.5, cz - (p0.x + p1.x) * 0.5).normalized()
			lm.quad(key, Vector3(x - depth * 0.5, p0.y, p0.x), Vector3(x + depth * 0.5, p0.y, p0.x),
				Vector3(x + depth * 0.5, p1.y, p1.x), Vector3(x - depth * 0.5, p1.y, p1.x), inward)
	return crown
