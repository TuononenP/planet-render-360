class_name StoSdfBronze
extends RefCounted

## One smooth skin for a cast figure: tapered capsules and ellipsoids blended
## with a polynomial smooth minimum into a signed-distance field on a grid,
## meshed with naive surface nets (one vertex per surface cell, a quad per
## crossed grid edge) and shaded with the field's own gradient, so a body,
## its neck, haunches and legs are a single continuous surface with no
## seams, creases or hard shading breaks. Metres, written onto a LandmarkMesh
## key. Features thinner than about two cells (ears, a baton, a brim) do not
## survive the grid: build those as ordinary members.

const FAR := 10.0

## Tapered capsule from `a` (radius `ra`) to `b` (`rb`), blended over `k` m.
static func capsule(a: Vector3, b: Vector3, ra: float, rb: float, k: float = 0.1) -> Dictionary:
	var m := maxf(ra, rb) + k
	return {"ellipsoid": false, "a": a, "b": b, "ra": ra, "rb": rb, "k": k,
		"lo": a.min(b) - Vector3(m, m, m), "hi": a.max(b) + Vector3(m, m, m)}

## Ellipsoid about `c` with half axes `r`, blended over `k` m.
static func egg(c: Vector3, r: Vector3, k: float = 0.1) -> Dictionary:
	return {"ellipsoid": true, "a": c, "r": r, "k": k,
		"lo": c - r - Vector3(k, k, k), "hi": c + r + Vector3(k, k, k)}

static func _distance(p: Dictionary, q: Vector3) -> float:
	var a: Vector3 = p["a"]
	if bool(p["ellipsoid"]):
		var r: Vector3 = p["r"]
		var d := q - a
		var k0 := Vector3(d.x / r.x, d.y / r.y, d.z / r.z).length()
		var k1 := Vector3(d.x / (r.x * r.x), d.y / (r.y * r.y), d.z / (r.z * r.z)).length()
		return k0 * (k0 - 1.0) / maxf(k1, 0.0001)
	var b: Vector3 = p["b"]
	var ab := b - a
	var h := clampf((q - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return (q - a - ab * h).length() - lerpf(float(p["ra"]), float(p["rb"]), h)

## Meshes the blend of `prims` (capsule / egg dictionaries) onto `lm` under
## `key` at grid spacing `cell`. Triangles are emitted with smooth normals.
static func mesh(lm: LandmarkMesh, key: String, prims: Array, cell: float) -> void:
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for p in prims:
		lo = lo.min(p["lo"])
		hi = hi.max(p["hi"])
	lo -= Vector3(cell, cell, cell)
	var nx := int(ceil((hi.x - lo.x) / cell)) + 2
	var ny := int(ceil((hi.y - lo.y) / cell)) + 2
	var nz := int(ceil((hi.z - lo.z) / cell)) + 2
	var f := PackedFloat32Array()
	f.resize(nx * ny * nz)
	f.fill(FAR)
	for p in prims:
		var k := float(p["k"])
		var plo: Vector3 = p["lo"]
		var phi: Vector3 = p["hi"]
		var x0 := maxi(int(floor((plo.x - lo.x) / cell)), 0)
		var x1 := mini(int(ceil((phi.x - lo.x) / cell)), nx - 1)
		var y0 := maxi(int(floor((plo.y - lo.y) / cell)), 0)
		var y1 := mini(int(ceil((phi.y - lo.y) / cell)), ny - 1)
		var z0 := maxi(int(floor((plo.z - lo.z) / cell)), 0)
		var z1 := mini(int(ceil((phi.z - lo.z) / cell)), nz - 1)
		for z in range(z0, z1 + 1):
			for y in range(y0, y1 + 1):
				var row := nx * (y + ny * z)
				for x in range(x0, x1 + 1):
					var d := _distance(p, lo + Vector3(x, y, z) * cell)
					var cur := f[row + x]
					var h := maxf(k - absf(cur - d), 0.0) / k
					f[row + x] = minf(cur, d) - h * h * k * 0.25
	# One vertex per cell the surface crosses.
	var cx := nx - 1
	var cy := ny - 1
	var cz := nz - 1
	var cell_v := PackedInt32Array()
	cell_v.resize(cx * cy * cz)
	cell_v.fill(-1)
	var pos := PackedVector3Array()
	var nor := PackedVector3Array()
	for z in cz:
		for y in cy:
			for x in cx:
				var i0 := x + nx * (y + ny * z)
				var c := [f[i0], f[i0 + 1], f[i0 + nx], f[i0 + nx + 1],
					f[i0 + nx * ny], f[i0 + nx * ny + 1], f[i0 + nx * ny + nx], f[i0 + nx * ny + nx + 1]]
				var inside := 0
				for v: float in c:
					if v < 0.0:
						inside += 1
				if inside == 0 or inside == 8:
					continue
				var sum := Vector3.ZERO
				var n := 0
				for e in EDGES:
					var va: float = c[e[0]]
					var vb: float = c[e[1]]
					if (va < 0.0) != (vb < 0.0):
						var t := va / (va - vb)
						sum += Vector3(e[2]).lerp(Vector3(e[3]), t)
						n += 1
				var at := sum / float(n)
				var g := Vector3(
					(c[1] + c[3] + c[5] + c[7] - c[0] - c[2] - c[4] - c[6]),
					(c[2] + c[3] + c[6] + c[7] - c[0] - c[1] - c[4] - c[5]),
					(c[4] + c[5] + c[6] + c[7] - c[0] - c[1] - c[2] - c[3]))
				cell_v[x + cx * (y + cy * z)] = pos.size()
				pos.append(lo + (Vector3(x, y, z) + at) * cell)
				nor.append(g.normalized() if g.length() > 0.0001 else Vector3.UP)
	# A quad across every grid edge the surface crosses.
	for z in range(1, nz - 1):
		for y in range(1, ny - 1):
			for x in range(1, nx - 1):
				var i := x + nx * (y + ny * z)
				var inside := f[i] < 0.0
				if x < nx - 1 and (f[i + 1] < 0.0) != inside and y < cy and z < cz:
					_quad(lm, key, pos, nor, [cell_v[x + cx * ((y - 1) + cy * (z - 1))], cell_v[x + cx * (y + cy * (z - 1))],
						cell_v[x + cx * (y + cy * z)], cell_v[x + cx * ((y - 1) + cy * z)]])
				if (f[i + nx] < 0.0) != inside and x < cx and z < cz:
					_quad(lm, key, pos, nor, [cell_v[(x - 1) + cx * (y + cy * (z - 1))], cell_v[x + cx * (y + cy * (z - 1))],
						cell_v[x + cx * (y + cy * z)], cell_v[(x - 1) + cx * (y + cy * z)]])
				if (f[i + nx * ny] < 0.0) != inside and x < cx and y < cy:
					_quad(lm, key, pos, nor, [cell_v[(x - 1) + cx * ((y - 1) + cy * z)], cell_v[x + cx * ((y - 1) + cy * z)],
						cell_v[x + cx * (y + cy * z)], cell_v[(x - 1) + cx * (y + cy * z)]])

static func _quad(lm: LandmarkMesh, key: String, pos: PackedVector3Array, nor: PackedVector3Array, q: Array) -> void:
	for v: int in q:
		if v < 0:
			return
	var uv: Array[Vector2] = []
	for v: int in q:
		uv.append(Vector2(pos[v].x + pos[v].z, pos[v].y))
	lm.tri(key, pos[q[0]], pos[q[1]], pos[q[2]], nor[q[0]], nor[q[1]], nor[q[2]], uv[0], uv[1], uv[2])
	lm.tri(key, pos[q[0]], pos[q[2]], pos[q[3]], nor[q[0]], nor[q[2]], nor[q[3]], uv[0], uv[2], uv[3])

## The 12 edges of a cell as [corner a, corner b, point a, point b]; corners
## are numbered x + 2 y + 4 z.
const EDGES := [
	[0, 1, Vector3(0, 0, 0), Vector3(1, 0, 0)], [2, 3, Vector3(0, 1, 0), Vector3(1, 1, 0)],
	[4, 5, Vector3(0, 0, 1), Vector3(1, 0, 1)], [6, 7, Vector3(0, 1, 1), Vector3(1, 1, 1)],
	[0, 2, Vector3(0, 0, 0), Vector3(0, 1, 0)], [1, 3, Vector3(1, 0, 0), Vector3(1, 1, 0)],
	[4, 6, Vector3(0, 0, 1), Vector3(0, 1, 1)], [5, 7, Vector3(1, 0, 1), Vector3(1, 1, 1)],
	[0, 4, Vector3(0, 0, 0), Vector3(0, 0, 1)], [1, 5, Vector3(1, 0, 0), Vector3(1, 0, 1)],
	[2, 6, Vector3(0, 1, 0), Vector3(0, 1, 1)], [3, 7, Vector3(1, 1, 0), Vector3(1, 1, 1)],
]
