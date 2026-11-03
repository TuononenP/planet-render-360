class_name RoadDrape
extends RefCounted

## Lays RoadBuilder's ribbons on the drawn terrain exactly. A ribbon quad
## only samples the ground at its four corners, so it cuts straight
## through every terrain crease between them (a street across a 9–25 m
## grid crease, a 64 m paved square over several cells) and the ground
## hides the road in patches. Each ribbon triangle is cut along the drawn
## mesh's grid lines and cell diagonals (fx, fz and fx + fz integer:
## TerrainBuilder's a-b-c / b-d-c split); every piece then lies over one
## flat terrain triangle, so corners lifted above the ground keep the
## whole piece above it. Cut points shared by neighbouring pieces are
## welded per ribbon.

## One convex piece: XZ, UV, junction fraction and normal per corner.
class _Poly extends RefCounted:
	var pos := PackedVector2Array()
	var uv := PackedVector2Array()
	var jf := PackedFloat32Array()
	var nrm := PackedVector3Array()

	func add(p: Vector2, u: Vector2, j: float, n: Vector3) -> void:
		pos.append(p); uv.append(u); jf.append(j); nrm.append(n)

	## Corner i lerped toward corner k by t, appended to `to`.
	func add_lerp(to: _Poly, i: int, k: int, t: float) -> void:
		to.add(pos[i].lerp(pos[k], t), uv[i].lerp(uv[k], t),
			lerpf(jf[i], jf[k], t), nrm[i].lerp(nrm[k], t))

	func add_from(to: _Poly, i: int) -> void:
		to.add(pos[i], uv[i], jf[i], nrm[i])

## Ribbon quad between rows r0 → r1, each [left, right, along-UV,
## junction fraction, normal]; `u1` is the across-UV of the right edge.
static func quad(b: RoadBuilder._Batch, surf: RoadBuilder._Surface, lift: float,
		attr: Color, w2: Vector2, u1: float, weld: Dictionary, r0: Array, r1: Array) -> void:
	var v0 := float(r0[2])
	var v1 := float(r1[2])
	var t0 := _Poly.new()
	t0.add(r0[0], Vector2(0.0, v0), r0[3], r0[4])
	t0.add(r0[1], Vector2(u1, v0), r0[3], r0[4])
	t0.add(r1[0], Vector2(0.0, v1), r1[3], r1[4])
	var t1 := _Poly.new()
	t1.add(r0[1], Vector2(u1, v0), r0[3], r0[4])
	t1.add(r1[1], Vector2(u1, v1), r1[3], r1[4])
	t1.add(r1[0], Vector2(0.0, v1), r1[3], r1[4])
	for t in [t0, t1]:
		_lay(b, surf, lift, attr, w2, weld, t)

## One flat triangle of a paved area (`pts`, three XZ corners), its UV
## the world XZ in 4 m units, laid like a ribbon piece.
static func tri(b: RoadBuilder._Batch, surf: RoadBuilder._Surface, lift: float,
		attr: Color, w2: Vector2, weld: Dictionary, pts: PackedVector2Array, m2u: float) -> void:
	var t := _Poly.new()
	for p in pts:
		t.add(p, p / m2u / 4.0, 1.0, surf.normal(p.x, p.y))
	_lay(b, surf, lift, attr, w2, weld, t)

## Cuts one convex piece along the drawn mesh's three line families and
## emits the pieces.
static func _lay(b: RoadBuilder._Batch, surf: RoadBuilder._Surface, lift: float,
		attr: Color, w2: Vector2, weld: Dictionary, t: _Poly) -> void:
	var pieces: Array = [t]
	for fam in 3:
		var next: Array = []
		for pc in pieces:
			_cut(pc as _Poly, fam, surf, next)
		pieces = next
	for pc in pieces:
		var model: Variant = surf.ground.shoreline
		var centre := RingGeometry.centroid((pc as _Poly).pos)
		if model != null and model.ready and model.patches.has(model.cell_at(centre)):
			var patch: Dictionary = model.patches[model.cell_at(centre)]
			var triangles: PackedVector3Array = patch["triangles"]
			for i in range(0, triangles.size(), 3):
				if int(patch["owners"][i / 3]) >= 0:
					continue
				var clipped: _Poly = pc
				for edge in 3:
					var a := Vector2(triangles[i + edge].x, triangles[i + edge].z)
					var bb := triangles[i + (edge + 1) % 3]
					clipped = _clip_shore(clipped, a, Vector2(bb.x, bb.z))
					if clipped.pos.size() < 3:
						break
				if clipped.pos.size() >= 3:
					_emit(b, surf, lift, attr, w2, weld, clipped)
		else:
			_emit(b, surf, lift, attr, w2, weld, pc as _Poly)

static func _clip_shore(poly: _Poly, a: Vector2, b: Vector2) -> _Poly:
	var out := _Poly.new()
	var dir := b - a
	for i in poly.pos.size():
		var j := (i + 1) % poly.pos.size()
		var da := dir.cross(poly.pos[i] - a)
		var db := dir.cross(poly.pos[j] - a)
		if da >= -0.00001:
			poly.add_from(out, i)
		if (da < -0.00001 and db > 0.00001) or (da > 0.00001 and db < -0.00001):
			poly.add_lerp(out, i, j, da / (da - db))
	return out

## Splits `poly` at every integer line of family `fam` (mesh-cell fx,
## fz or fx + fz) it crosses, appending the convex pieces to `out`.
static func _cut(poly: _Poly, fam: int, surf: RoadBuilder._Surface, out: Array) -> void:
	var g := PackedFloat32Array()
	var lo := INF
	var hi := -INF
	var inv := 1.0 / surf.mesh_step
	var hs := float(surf.mesh_size) * 0.5
	for p in poly.pos:
		var v := (p.x * inv + hs if fam != 1 else 0.0) + (p.y * inv + hs if fam != 0 else 0.0)
		g.append(v)
		lo = minf(lo, v)
		hi = maxf(hi, v)
	var k := floorf(lo) + 1.0
	if k >= hi - 1e-5:
		out.append(poly)
		return
	var cur := poly
	while k < hi - 1e-5:
		if k <= lo + 1e-5:
			k += 1.0
			continue
		var below := _Poly.new()
		var above := _Poly.new()
		var n := cur.pos.size()
		var ga := PackedFloat32Array()
		for i in n:
			var j := (i + 1) % n
			if g[i] <= k:
				cur.add_from(below, i)
			if g[i] >= k:
				cur.add_from(above, i)
				ga.append(g[i])
			if (g[i] < k and g[j] > k) or (g[i] > k and g[j] < k):
				var t := (k - g[i]) / (g[j] - g[i])
				cur.add_lerp(below, i, j, t)
				cur.add_lerp(above, i, j, t)
				ga.append(k)
		if below.pos.size() >= 3:
			out.append(below)
		cur = above
		g = ga
		k += 1.0
	if cur.pos.size() >= 3:
		out.append(cur)

## Adds a convex piece, its corners on the drawn surface plus `lift`,
## fanned into triangles that face up.
static func _emit(b: RoadBuilder._Batch, surf: RoadBuilder._Surface, lift: float,
		attr: Color, w2: Vector2, weld: Dictionary, pc: _Poly) -> void:
	var ids := PackedInt32Array()
	for i in pc.pos.size():
		var p := pc.pos[i]
		var key := Vector2i(roundi(p.x * 1000.0), roundi(p.y * 1000.0))
		var id: int = weld.get(key, -1)
		if id < 0:
			id = b.verts.size()
			weld[key] = id
			b.verts.append(Vector3(p.x, surf.height(p.x, p.y) + lift, p.y))
			b.normals.append(pc.nrm[i].normalized())
			b.uvs.append(pc.uv[i])
			attr.a = pc.jf[i]
			b.colors.append(attr)
			b.uv2s.append(w2)
		ids.append(id)
	for i in range(1, ids.size() - 1):
		var a := ids[0]
		var c := ids[i]
		var d := ids[i + 1]
		if a == c or c == d or a == d:
			continue
		var va := b.verts[a]
		var up := (b.verts[d] - va).cross(b.verts[c] - va).y
		if up >= 0.0:
			b.indices.push_back(a); b.indices.push_back(c); b.indices.push_back(d)
		else:
			b.indices.push_back(a); b.indices.push_back(d); b.indices.push_back(c)
