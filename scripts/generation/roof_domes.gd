class_name RoofDomes
extends RefCounted

## Lathed landmark roofs (dome, onion, cone) over a cleaned footprint
## ring, for mapped domes, drums and spires: every ring vertex is drawn
## in toward the centre along a profile as it rises, so a round part
## takes a true dome and an octagonal drum an octagonal (cloister) dome.
## Smooth normals; UVs run around the base perimeter and up the profile.
## A leaf class like RoofGeometry: it appends triangle soup to the same
## arrays and the caller builds the mesh.

## [radius scale, rise fraction] knots, base ring first, apex last.
const ONION: Array = [[1.0, 0.0], [1.18, 0.12], [1.28, 0.25], [1.24, 0.38],
	[1.05, 0.52], [0.75, 0.64], [0.45, 0.75], [0.22, 0.86], [0.08, 0.95], [0.0, 1.0]]
const CONE: Array = [[1.0, 0.0], [0.0, 1.0]]
const DOME_STEPS := 8
## Rings with fewer vertices are subdivided so the curve reads round.
const MIN_SIDES := 24
const SHAPES: Array[String] = ["dome", "onion", "cone"]

## The [radius scale, rise fraction] profile of `shape` (a quarter
## circle for the dome; `rh` then makes it segmental or tall).
static func profile(shape: String) -> Array:
	match shape:
		"onion":
			return ONION
		"cone":
			return CONE
	var out: Array = []
	for i in DOME_STEPS + 1:
		var t := float(i) / DOME_STEPS * PI * 0.5
		out.append([cos(t), sin(t)])
	return out

## Appends the roof's triangles rising rh above `top`. False when the
## ring is not star-shaped about `c` (a fan from it would fold): the
## caller then falls back to RoofGeometry.apex_faces.
static func faces(ring: PackedVector2Array, c: Vector2, top: float, rh: float,
		shape: String, verts: PackedVector3Array, normals: PackedVector3Array,
		uvs: PackedVector2Array) -> bool:
	if shape not in SHAPES or ring.size() < 3 or not star_shaped(ring, c):
		return false
	var base := ring if shape == "cone" else subdivided(ring, MIN_SIDES)
	var prof := profile(shape)
	var n := base.size()
	# Horizontal outward normal and apothem at each base vertex (mean of
	# its two edge normals), and its distance round the perimeter.
	var out_n: Array[Vector2] = []
	var apo := PackedFloat32Array()
	var along := PackedFloat32Array()
	var run := 0.0
	for i in n:
		var p := base[i]
		var nn := (_edge_normal(base[(i - 1 + n) % n], p, c) + _edge_normal(p, base[(i + 1) % n], c))
		nn = nn.normalized() if nn.length() > 0.0001 else (p - c).normalized()
		out_n.append(nn)
		apo.append(maxf((p - c).dot(nn), 0.0001))
		along.append(run)
		run += p.distance_to(base[(i + 1) % n])
	# Rings of points, profile arc length and smooth normals.
	var rings: Array = []
	var ring_n: Array = []
	var arc := PackedFloat32Array()
	var s_len := 0.0
	for k in prof.size():
		var s := float(prof[k][0])
		var h := float(prof[k][1])
		var k0 := maxi(k - 1, 0)
		var k1 := mini(k + 1, prof.size() - 1)
		var ds := float(prof[k1][0]) - float(prof[k0][0])
		var dh := float(prof[k1][1]) - float(prof[k0][1])
		if k > 0:
			var r_mean := (apo[0] + apo[n >> 1]) * 0.5
			s_len += Vector2((s - float(prof[k - 1][0])) * r_mean,
				(h - float(prof[k - 1][1])) * rh).length()
		arc.append(s_len)
		var pts := PackedVector3Array()
		var nrm := PackedVector3Array()
		for i in n:
			var q := c + (base[i] - c) * s
			pts.append(Vector3(q.x, top + rh * h, q.y))
			# Profile normal in the (outward, up) plane: (rh·dh, −R·ds).
			var o := out_n[i]
			var v := Vector2(rh * dh, -apo[i] * ds).normalized()
			if k == prof.size() - 1 and shape != "cone":
				v = Vector2(0.0, 1.0)
			nrm.append(Vector3(o.x * v.x, v.y, o.y * v.x).normalized())
		rings.append(pts)
		ring_n.append(nrm)
	var before := verts.size()
	for k in prof.size() - 1:
		var p0: PackedVector3Array = rings[k]
		var p1: PackedVector3Array = rings[k + 1]
		var n0: PackedVector3Array = ring_n[k]
		var n1: PackedVector3Array = ring_n[k + 1]
		for i in n:
			var j := (i + 1) % n
			var u0 := along[i] * 0.05
			var u1 := (along[i] + base[i].distance_to(base[j])) * 0.05
			var v0 := -arc[k] * 0.05
			var v1 := -arc[k + 1] * 0.05
			_tri(verts, normals, uvs, [p0[i], p0[j], p1[j]], [n0[i], n0[j], n1[j]],
				[Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1)])
			_tri(verts, normals, uvs, [p0[i], p1[j], p1[i]], [n0[i], n1[j], n1[i]],
				[Vector2(u0, v0), Vector2(u1, v1), Vector2(u0, v1)])
	return verts.size() > before

## True when every edge of the ring turns the same way about `c` (each
## ray from c meets the outline once), with c strictly inside.
static func star_shaped(ring: PackedVector2Array, c: Vector2) -> bool:
	var turn := 0.0
	for i in ring.size():
		var a := ring[i] - c
		var b := ring[(i + 1) % ring.size()] - c
		var cr := a.cross(b)
		if absf(cr) < 0.000001:
			if a.dot(b) <= 0.0:
				return false  # c on the outline
			continue
		if turn == 0.0:
			turn = signf(cr)
		elif signf(cr) != turn:
			return false
	return turn != 0.0

## The ring with each edge split evenly so it has at least `sides` points.
static func subdivided(ring: PackedVector2Array, sides: int) -> PackedVector2Array:
	if ring.size() >= sides:
		return ring
	var per := ceili(float(sides) / ring.size())
	var out := PackedVector2Array()
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		for s in per:
			out.append(a.lerp(b, float(s) / per))
	return out

static func _edge_normal(a: Vector2, b: Vector2, c: Vector2) -> Vector2:
	var e := b - a
	if e.length() < 0.0001:
		return Vector2.ZERO
	var nn := Vector2(e.y, -e.x).normalized()
	return -nn if nn.dot((a + b) * 0.5 - c) < 0.0 else nn

## One soup triangle with per-vertex normals, wound so its Godot front
## face agrees with them; degenerates (the collapsed apex) dropped.
static func _tri(verts: PackedVector3Array, normals: PackedVector3Array,
		uvs: PackedVector2Array, p: Array, nrm: Array, uv: Array) -> void:
	var a: Vector3 = p[0]
	var b: Vector3 = p[1]
	var d: Vector3 = p[2]
	var front := (d - a).cross(b - a)
	if front.length_squared() < 0.00000001:
		return
	var mean: Vector3 = (nrm[0] as Vector3) + (nrm[1] as Vector3) + (nrm[2] as Vector3)
	var order := [0, 1, 2] if front.dot(mean) >= 0.0 else [0, 2, 1]
	for o in order:
		verts.append(p[o])
		normals.append(nrm[o])
		uvs.append(uv[o])
