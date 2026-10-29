class_name LandmarkMesh
extends RefCounted

## Merged-geometry accumulator for landmark models (T5.3). Every
## primitive is emitted in true metres into one surface per material
## key, so a 3000-member lattice tower is a handful of draw calls, not
## thousands of nodes. UVs are in metres (materials set uv1_scale to
## 1 / texture tile size) and tangents are generated on commit so the
## photographic normal maps light correctly. Triangle winding is fixed
## per triangle against the intended normal (Godot front faces are
## clockwise), so callers never think about vertex order.

class Surf:
	var mat: Material
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()

var _surfs: Dictionary = {}
var _order: Array[String] = []

## Registers (or re-points) the material for a surface key.
func use(key: String, mat: Material) -> void:
	if not _surfs.has(key):
		_surfs[key] = Surf.new()
		_order.append(key)
	(_surfs[key] as Surf).mat = mat

func triangle_count() -> int:
	var t := 0
	for k in _order:
		t += (_surfs[k] as Surf).v.size() / 3
	return t

## One triangle; vertex order is swapped when it would face away from
## the summed vertex normals.
func tri(key: String, a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3,
		nc: Vector3, ua: Vector2, ub: Vector2, uc: Vector2) -> void:
	var s: Surf = _surfs[key]
	if (c - a).cross(b - a).dot(na + nb + nc) < 0.0:
		s.v.append_array([a, c, b])
		s.n.append_array([na, nc, nb])
		s.uv.append_array([ua, uc, ub])
	else:
		s.v.append_array([a, b, c])
		s.n.append_array([na, nb, nc])
		s.uv.append_array([ua, ub, uc])

## Flat quad a-b-c-d (in order around the edge) facing `normal`
## (computed from the corners when zero). UVs span the edge lengths.
func quad(key: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		normal: Vector3 = Vector3.ZERO, uv0: Vector2 = Vector2.ZERO) -> void:
	var n := normal
	if n == Vector3.ZERO:
		n = (b - a).cross(d - a).normalized()
	var w := a.distance_to(b)
	var h := a.distance_to(d)
	var ua := uv0
	var ub := uv0 + Vector2(w, 0)
	var uc := uv0 + Vector2(w, -h)
	var ud := uv0 + Vector2(0, -h)
	tri(key, a, b, c, n, n, n, ua, ub, uc)
	tri(key, a, c, d, n, n, n, ua, uc, ud)

## Axis box centred at `center` with full `size`, oriented by `basis`.
func box(key: String, center: Vector3, size: Vector3, basis: Basis = Basis()) -> void:
	var hx := basis.x * size.x * 0.5
	var hy := basis.y * size.y * 0.5
	var hz := basis.z * size.z * 0.5
	var faces := [[hx, hy, hz], [-hx, hy, -hz], [hz, hy, -hx], [-hz, hy, hx],
		[hy, hz, hx], [-hy, hz, -hx]]
	for f in faces:
		var o: Vector3 = center + f[0]
		var up: Vector3 = f[1]
		var side: Vector3 = f[2]
		quad(key, o - side - up, o + side - up, o + side + up, o - side + up,
			(f[0] as Vector3).normalized())

## Square-section member from `a` to `b`, `w` wide and `d` deep; `side`
## orients the width axis (projected perpendicular to the member).
func beam(key: String, a: Vector3, b: Vector3, w: float, d: float = -1.0,
		side: Vector3 = Vector3.ZERO, caps: bool = false) -> void:
	var axis := b - a
	var length := axis.length()
	if length < 0.001:
		return
	axis /= length
	var sv := side
	if sv == Vector3.ZERO:
		sv = Vector3.UP if absf(axis.y) < 0.9 else Vector3.RIGHT
		sv = axis.cross(sv)
	sv = (sv - axis * sv.dot(axis)).normalized()
	var dv := axis.cross(sv).normalized()
	var hw := sv * w * 0.5
	var hd := dv * (d if d > 0.0 else w) * 0.5
	var ring := [hw + hd, -hw + hd, -hw - hd, hw - hd]
	var u := 0.0
	for i in 4:
		var p0: Vector3 = ring[i]
		var p1: Vector3 = ring[(i + 1) % 4]
		var n := (p0 + p1).normalized()
		var e := p0.distance_to(p1)
		quad(key, a + p0, a + p1, b + p1, b + p0, n, Vector2(u, 0))
		u += e
	if caps:
		quad(key, a + ring[0], a + ring[1], a + ring[2], a + ring[3], -axis)
		quad(key, b + ring[0], b + ring[1], b + ring[2], b + ring[3], axis)

## Surface of revolution around +Y at `base`. `prof` is (radius, y)
## from bottom to top; `seg` sides (4 = square spire), stretched by
## sx/sz and turned by rot. smooth=false gives faceted normals. Ends
## with a non-zero radius are capped.
func lathe(key: String, base: Vector3, prof: PackedVector2Array, seg: int,
		sx: float = 1.0, sz: float = 1.0, rot: float = 0.0, smooth: bool = true,
		cap: bool = true) -> void:
	var rings: Array = []
	var norms: Array = []
	var vs: Array = []
	var acc := 0.0
	for j in prof.size():
		var tan_p := prof[mini(j + 1, prof.size() - 1)] - prof[maxi(j - 1, 0)]
		if j > 0:
			acc += prof[j].distance_to(prof[j - 1])
		vs.append(acc)
		var ring := PackedVector3Array()
		var nring := PackedVector3Array()
		for i in seg + 1:
			var a := rot + TAU * float(i) / float(seg)
			var dir := Vector3(cos(a), 0, sin(a))
			ring.append(base + Vector3(dir.x * prof[j].x * sx, prof[j].y, dir.z * prof[j].x * sz))
			nring.append((Vector3(dir.x / sx, 0, dir.z / sz).normalized() * tan_p.y
				+ Vector3.UP * -tan_p.x).normalized())
		rings.append(ring)
		norms.append(nring)
	for j in prof.size() - 1:
		var r0: PackedVector3Array = rings[j]
		var r1: PackedVector3Array = rings[j + 1]
		var circ := TAU * maxf(prof[j].x, prof[j + 1].x) * (sx + sz) * 0.5
		for i in seg:
			var u0 := circ * float(i) / float(seg)
			var u1 := circ * float(i + 1) / float(seg)
			var ua := Vector2(u0, -float(vs[j]))
			var ub := Vector2(u1, -float(vs[j]))
			var uc := Vector2(u1, -float(vs[j + 1]))
			var ud := Vector2(u0, -float(vs[j + 1]))
			if smooth:
				var n0: PackedVector3Array = norms[j]
				var n1: PackedVector3Array = norms[j + 1]
				if prof[j].x > 0.0001:
					tri(key, r0[i], r0[i + 1], r1[i + 1], n0[i], n0[i + 1], n1[i + 1], ua, ub, uc)
				if prof[j + 1].x > 0.0001:
					tri(key, r0[i], r1[i + 1], r1[i], n0[i], n1[i + 1], n1[i], ua, uc, ud)
			else:
				var mid := (r0[i] + r0[i + 1] + r1[i] + r1[i + 1]) * 0.25
				var dp := prof[j + 1] - prof[j]
				var fn := (mid - base - Vector3.UP * (mid.y - base.y)).normalized() * dp.y \
					- Vector3.UP * dp.x
				var slope := (r1[i] + r1[i + 1] - r0[i] - r0[i + 1]) * 0.5
				var tangent := (r0[i + 1] - r0[i]) if prof[j].x > 0.0001 else (r1[i + 1] - r1[i])
				var fn2 := slope.cross(tangent).normalized()
				if fn2.dot(fn) < 0.0:
					fn2 = -fn2
				if prof[j].x > 0.0001:
					tri(key, r0[i], r0[i + 1], r1[i + 1], fn2, fn2, fn2, ua, ub, uc)
				if prof[j + 1].x > 0.0001:
					tri(key, r0[i], r1[i + 1], r1[i], fn2, fn2, fn2, ua, uc, ud)
	if cap:
		for end in [0, prof.size() - 1]:
			if prof[end].x <= 0.0001:
				continue
			var ring_e: PackedVector3Array = rings[end]
			var c := base + Vector3(0, prof[end].y, 0)
			var n := Vector3.DOWN if end == 0 else Vector3.UP
			for i in seg:
				tri(key, c, ring_e[i], ring_e[i + 1], n, n, n,
					Vector2(c.x, c.z), Vector2(ring_e[i].x, ring_e[i].z),
					Vector2(ring_e[i + 1].x, ring_e[i + 1].z))

## Straight-sided frustum: shorthand for a two-ring lathe.
func frustum(key: String, base: Vector3, r0: float, r1: float, h: float, seg: int,
		rot: float = 0.0, sx: float = 1.0, sz: float = 1.0) -> void:
	lathe(key, base, PackedVector2Array([Vector2(r0, 0), Vector2(r1, h)]), seg,
		sx, sz, rot, seg > 8)

## Square pyramid/spire: half-width hw at base to tip (or top half-width).
func spire(key: String, base: Vector3, hw: float, h: float, top_hw: float = 0.0,
		sides: int = 4) -> void:
	var k := 1.0 / cos(PI / float(sides))
	lathe(key, base, PackedVector2Array([Vector2(hw * k, 0), Vector2(top_hw * k, h)]),
		sides, 1.0, 1.0, PI / float(sides), false)

## Vertical prism over an XZ polygon from y0 to y1, top capped.
func poly_prism(key: String, poly: PackedVector2Array, y0: float, y1: float,
		cap_top: bool = true) -> void:
	var cw := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		cw += p.x * q.y - q.x * p.y
	var u := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		var e := q - p
		var n := Vector3(e.y, 0, -e.x).normalized() * (1.0 if cw > 0.0 else -1.0)
		quad(key, Vector3(p.x, y0, p.y), Vector3(q.x, y0, q.y), Vector3(q.x, y1, q.y),
			Vector3(p.x, y1, p.y), n, Vector2(u, y1))
		u += e.length()
	if cap_top:
		var idx := Geometry2D.triangulate_polygon(poly)
		for t in range(0, idx.size(), 3):
			var a := poly[idx[t]]
			var b := poly[idx[t + 1]]
			var c := poly[idx[t + 2]]
			tri(key, Vector3(a.x, y1, a.y), Vector3(b.x, y1, b.y), Vector3(c.x, y1, c.y),
				Vector3.UP, Vector3.UP, Vector3.UP, a, b, c)

## Smooth surface through a grid of points (rows of equal length);
## normals from neighbours, flipped toward `outward` when it is set
## (a point the surface should face away from is `-outward`).
func grid(key: String, rows: Array, out_hint: Vector3 = Vector3.ZERO,
		hint_is_point: bool = false) -> void:
	var nv := rows.size()
	var nu := (rows[0] as PackedVector3Array).size()
	var norms: Array = []
	for j in nv:
		var nr := PackedVector3Array()
		var row: PackedVector3Array = rows[j]
		for i in nu:
			var du := row[mini(i + 1, nu - 1)] - row[maxi(i - 1, 0)]
			var dv := (rows[mini(j + 1, nv - 1)] as PackedVector3Array)[i] \
				- (rows[maxi(j - 1, 0)] as PackedVector3Array)[i]
			var n := du.cross(dv).normalized()
			var ref := (row[i] - out_hint) if hint_is_point else out_hint
			if ref != Vector3.ZERO and n.dot(ref) < 0.0:
				n = -n
			nr.append(n)
		norms.append(nr)
	var vacc := PackedFloat32Array()
	vacc.resize(nu)
	for j in nv - 1:
		var r0: PackedVector3Array = rows[j]
		var r1: PackedVector3Array = rows[j + 1]
		var n0: PackedVector3Array = norms[j]
		var n1: PackedVector3Array = norms[j + 1]
		var u0 := 0.0
		for i in nu - 1:
			var u1 := u0 + r0[i].distance_to(r0[i + 1])
			var va := vacc[i]
			var vb := vacc[i + 1]
			var vc := vb + r0[i + 1].distance_to(r1[i + 1])
			var vd := va + r0[i].distance_to(r1[i])
			tri(key, r0[i], r0[i + 1], r1[i + 1], n0[i], n0[i + 1], n1[i + 1],
				Vector2(u0, va), Vector2(u1, vb), Vector2(u1, vc))
			tri(key, r0[i], r1[i + 1], r1[i], n0[i], n1[i + 1], n1[i],
				Vector2(u0, va), Vector2(u1, vc), Vector2(u0, vd))
			u0 = u1
		for i in nu:
			vacc[i] += r0[i].distance_to(r1[i])

## X-braced lattice panel between a bottom edge (p0-p1) and a top edge
## (q0-q1), members `w` wide, `n` stacked X cells; `face_n` orients the
## member width so the lattice reads flat on the face.
func lattice_panel(key: String, p0: Vector3, p1: Vector3, q0: Vector3, q1: Vector3,
		w: float, n: int = 1, top_bar: bool = true) -> void:
	var face_n := (p1 - p0).cross(q0 - p0).normalized()
	for k in n:
		var t0 := float(k) / float(n)
		var t1 := float(k + 1) / float(n)
		var a0 := p0.lerp(q0, t0)
		var b0 := p1.lerp(q1, t0)
		var a1 := p0.lerp(q0, t1)
		var b1 := p1.lerp(q1, t1)
		beam(key, a0, b1, w, w * 0.6, face_n.cross(b1 - a0))
		beam(key, b0, a1, w, w * 0.6, face_n.cross(a1 - b0))
		if top_bar or k < n - 1:
			beam(key, a1, b1, w * 1.1, w * 0.6, face_n.cross(b1 - a1))

## Gabled roof over a W x L rectangle centred at `c` (eave level),
## ridge along the basis Z axis, `rise` above the eaves, `over` eave
## overhang; `gable_key` (if set) closes the two triangular ends.
func gable(key: String, c: Vector3, w: float, l: float, rise: float,
		basis: Basis = Basis(), over: float = 0.6, gable_key: String = "") -> void:
	var hx := basis.x * (w * 0.5 + over)
	var hz := basis.z * (l * 0.5 + over * 0.5)
	var up := basis.y * rise
	var r0 := c + up - hz
	var r1 := c + up + hz
	quad(key, c + hx - hz, c + hx + hz, r1, r0, (basis.x * rise + basis.y * w * 0.5).normalized())
	quad(key, c - hx + hz, c - hx - hz, r0, r1, (-basis.x * rise + basis.y * w * 0.5).normalized())
	if gable_key != "":
		var ex := basis.x * w * 0.5
		for sgn in [-1.0, 1.0]:
			var e: Vector3 = basis.z * l * 0.5 * sgn
			var n: Vector3 = basis.z * sgn
			tri(gable_key, c - ex + e, c + ex + e, c + up + e, n, n, n,
				Vector2(0, 0), Vector2(w, 0), Vector2(w * 0.5, -rise))

## Flat disc of radius r at `center` facing `normal` (clock dials).
func disc(key: String, center: Vector3, normal: Vector3, r: float, seg: int = 24) -> void:
	var n := normal.normalized()
	var a := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
	var b := n.cross(a)
	for i in seg:
		var t0 := TAU * float(i) / float(seg)
		var t1 := TAU * float(i + 1) / float(seg)
		var p0 := center + (a * cos(t0) + b * sin(t0)) * r
		var p1 := center + (a * cos(t1) + b * sin(t1)) * r
		tri(key, center, p0, p1, n, n, n, Vector2(0.5, 0.5) * r,
			Vector2(0.5 + 0.5 * cos(t0), 0.5 + 0.5 * sin(t0)) * r * 2.0,
			Vector2(0.5 + 0.5 * cos(t1), 0.5 + 0.5 * sin(t1)) * r * 2.0)

## One MeshInstance3D per surface key under `parent`, named
## `<prefix><key>`; returns the instances in registration order.
func commit(parent: Node3D, prefix: String = "") -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for k in _order:
		var s: Surf = _surfs[k]
		if s.v.is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = s.v
		arrays[Mesh.ARRAY_NORMAL] = s.n
		arrays[Mesh.ARRAY_TEX_UV] = s.uv
		var st := SurfaceTool.new()
		st.create_from_arrays(arrays, Mesh.PRIMITIVE_TRIANGLES)
		st.generate_tangents()
		var mesh := st.commit()
		mesh.surface_set_material(0, s.mat)
		var mi := MeshInstance3D.new()
		mi.name = prefix + k
		mi.mesh = mesh
		parent.add_child(mi)
		out.append(mi)
	return out

## Smooth (Catmull-Rom) lookup in a (key, value) table sorted by key;
## clamps outside the table. Used for tower taper profiles.
static func profile_at(table: PackedVector2Array, k: float) -> float:
	if k <= table[0].x:
		return table[0].y
	var last := table.size() - 1
	if k >= table[last].x:
		return table[last].y
	var i := 0
	while i < last - 1 and table[i + 1].x < k:
		i += 1
	var p1 := table[i]
	var p2 := table[i + 1]
	var p0 := table[maxi(i - 1, 0)]
	var p3 := table[mini(i + 2, last)]
	var t := (k - p1.x) / (p2.x - p1.x)
	var dx := p2.x - p1.x
	var m1 := (p2.y - p0.y) / maxf(p2.x - p0.x, 0.001) * dx
	var m2 := (p3.y - p1.y) / maxf(p3.x - p1.x, 0.001) * dx
	var t2 := t * t
	var t3 := t2 * t
	return (2.0 * t3 - 3.0 * t2 + 1.0) * p1.y + (t3 - 2.0 * t2 + t) * m1 \
		+ (-2.0 * t3 + 3.0 * t2) * p2.y + (t3 - t2) * m2
