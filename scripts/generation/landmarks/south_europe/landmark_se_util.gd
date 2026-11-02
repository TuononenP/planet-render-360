class_name SEuUtil
extends RefCounted

## Helpers shared by the south europe landmark builders (true metres on
## LandmarkMesh): dome profiles, column rows and rings, arched openings,
## stairs, battlements, a masonry arch bridge and smooth blob surfaces.

## Round dome profile (radius, y): quarter ellipse from spring to apex.
static func dome(r: float, h: float, steps: int = 10) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in steps + 1:
		var a := PI * 0.5 * float(i) / steps
		p.append(Vector2(r * cos(a), h * sin(a)))
	p[steps] = Vector2(0.0, h)
	return p

## Pointed (ogival) dome profile for h > r: one circular arc that meets
## the spring vertically and closes at the apex.
static func ogive(r: float, h: float, steps: int = 12) -> PackedVector2Array:
	var big_r := (h * h + r * r) / (2.0 * r)
	var phi_max := asin(h / big_r)
	var p := PackedVector2Array()
	for i in steps + 1:
		var phi := phi_max * float(i) / steps
		p.append(Vector2(maxf((r - big_r) + big_r * cos(phi), 0.0), big_r * sin(phi)))
	p[steps] = Vector2(0.0, h)
	return p

## `n` columns of height h on a straight line a..b (a, b at ground).
static func column_row(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, n: int, h: float,
		cr: float, seg: int = 10, inclusive: bool = true) -> void:
	for i in n:
		var t := float(i) / float(maxi(n - 1, 1)) if inclusive else (float(i) + 0.5) / float(n)
		lm.frustum(key, a.lerp(b, t), cr, cr * 0.82, h, seg)

## `n` columns of height h on a circle of radius r around c (at ground).
static func column_ring(lm: LandmarkMesh, key: String, c: Vector3, r: float, n: int, h: float,
		cr: float, seg: int = 8, start: float = 0.0) -> void:
	for i in n:
		var a := start + TAU * float(i) / float(n)
		lm.frustum(key, c + Vector3(cos(a) * r, 0, sin(a) * r), cr, cr * 0.82, h, seg)

## Flat recess w wide and h tall (rectangle topped by a round or pointed
## arch) standing on `o` (bottom centre), facing right x up.
static func opening(lm: LandmarkMesh, key: String, o: Vector3, right: Vector3, up: Vector3,
		w: float, h: float, pointed: bool = false) -> void:
	var hw := w * 0.5
	var rise := w * 0.866 if pointed else hw
	var h_rect := maxf(h - rise, 0.05)
	var n := right.cross(up).normalized()
	var m := o + up * h_rect
	lm.quad(key, o - right * hw, o + right * hw, m + right * hw, m - right * hw, n)
	var pts: Array[Vector3] = []
	var steps := 5
	for k in steps + 1:
		if pointed:
			var phi := PI / 3.0 * float(k) / steps
			pts.append(m + right * (-hw + w * cos(phi)) + up * (w * sin(phi)))
		else:
			var a := PI * 0.5 * float(k) / steps
			pts.append(m + right * (hw * cos(a)) + up * (hw * sin(a)))
	for k in steps + 1:
		var q := pts[steps - k]
		pts.append(m + right * (-(q - m).dot(right)) + up * (q - m).dot(up))
	for k in pts.size() - 1:
		var p0 := pts[k]
		var p1 := pts[k + 1]
		lm.tri(key, m, p0, p1, n, n, n, Vector2((m - o).dot(right), -h_rect),
			Vector2((p0 - o).dot(right), -(p0 - o).dot(up)), Vector2((p1 - o).dot(right), -(p1 - o).dot(up)))

## Row of `n` openings along a wall face: `o` is the face centre at ground
## level, `right` the wall direction, `out` the face normal.
static func face_row(lm: LandmarkMesh, key: String, o: Vector3, right: Vector3, out: Vector3,
		y: float, n: int, pitch: float, w: float, h: float, pointed: bool = false) -> void:
	var up := Vector3.UP
	var nrm := right.cross(up).normalized()
	var r := right if nrm.dot(out) > 0.0 else -right
	for i in n:
		var s := (float(i) - float(n - 1) * 0.5) * pitch
		opening(lm, key, o + right * s + up * y + out * 0.06, r, up, w, h, pointed)

## `n` openings spaced evenly around a cylinder of radius r whose frusta
## have `facets` sides (the wall plane sits at r*cos(pi/facets)), ring
## centre c at ground.
static func ring_openings(lm: LandmarkMesh, key: String, c: Vector3, r: float, facets: int,
		n: int, y: float, w: float, h: float, pointed: bool = false, phase: float = 0.0) -> void:
	var rr := r * cos(PI / float(facets)) + 0.04
	for i in n:
		var a := phase + TAU * float(i) / float(n)
		var out := Vector3(cos(a), 0, sin(a))
		opening(lm, key, c + out * rr + Vector3(0, y, 0), Vector3.UP.cross(out), Vector3.UP,
			w, h, pointed)

## Steps rising toward the wall: the top step meets the wall point `c`
## (at ground), the stair runs out along `dir` (horizontal unit).
static func steps_up(lm: LandmarkMesh, key: String, c: Vector3, dir: Vector3, width: float,
		tread: float, riser: float, n: int) -> void:
	var basis := Basis(Vector3.UP, atan2(dir.x, dir.z))
	for k in n:
		var depth := tread * float(k + 1)
		var hgt := riser * float(n - k)
		lm.box(key, c + dir * depth * 0.5 + Vector3(0, hgt * 0.5, 0), Vector3(width, hgt, depth), basis)

## Battlements: merlons of width m every 2m along a..b (a, b at the wall top).
static func crenels(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, m: float, h: float,
		thick: float) -> void:
	var d := b - a
	var count := int(d.length() / (m * 2.0))
	var basis := Basis(Vector3.UP, atan2(d.x, d.z))
	for i in count:
		var p := a.lerp(b, (float(i) + 0.5) / float(count))
		lm.box(key, p + Vector3(0, h * 0.5, 0), Vector3(thick, h, m), basis)

## Smooth surface through `rows`, ordered so the normal at the middle
## vertex faces `want` (rows reversed when it does not).
static func grid_facing(lm: LandmarkMesh, key: String, rows: Array, want: Vector3) -> void:
	var nv := rows.size()
	var nu := (rows[0] as PackedVector3Array).size()
	var j := nv / 2
	var i := nu / 2
	var du := (rows[j] as PackedVector3Array)[mini(i + 1, nu - 1)] - (rows[j] as PackedVector3Array)[maxi(i - 1, 0)]
	var dv := (rows[mini(j + 1, nv - 1)] as PackedVector3Array)[i] - (rows[maxi(j - 1, 0)] as PackedVector3Array)[i]
	var use_rows: Array = rows
	if du.cross(dv).dot(want) < 0.0:
		use_rows = []
		for row in rows:
			var rev := PackedVector3Array()
			var src: PackedVector3Array = row
			for k in range(src.size() - 1, -1, -1):
				rev.append(src[k])
			use_rows.append(rev)
	lm.grid(key, use_rows)

## Ellipsoid blob (radii rx, ry, rz) centred at c, y>=c.y half only when
## `half`; the upper part leans by `lean` (metres per metre of height).
static func blob(lm: LandmarkMesh, key: String, c: Vector3, rx: float, ry: float, rz: float,
		lean: Vector3 = Vector3.ZERO, half: bool = true, rings: int = 10, seg: int = 20) -> void:
	var rows: Array = []
	for j in rings + 1:
		var lat := (PI * 0.4925 if half else PI) * float(j) / rings
		var row := PackedVector3Array()
		for i in seg + 1:
			var a := TAU * float(i) / seg
			var y := ry * (sin(lat) if half else -cos(lat))
			var rr := cos(lat) if half else sin(lat)
			row.append(c + Vector3(cos(a) * rx * rr, y, sin(a) * rz * rr) + lean * y)
		rows.append(row)
	grid_facing(lm, key, rows, Vector3.UP)

## Masonry arch bridge along +X, z centred on `zc`: piers from y0, round
## arch rings, solid spandrel faces to the deck at deck_y and a parapet.
static func arch_bridge(lm: LandmarkMesh, key: String, x0: float, x1: float, deck_y: float,
		y0: float, arches: int, half_w: float, pier_w: float = 3.0, zc: float = 0.0) -> void:
	var step := (x1 - x0) / float(arches)
	var r := (step - pier_w) * 0.5
	var rise := minf(r * 0.9, (deck_y - y0) * 0.6)
	var spring := deck_y - 1.3 - rise
	for i in arches + 1:
		lm.box(key, Vector3(x0 + step * float(i), (spring + y0) * 0.5, zc),
			Vector3(pier_w, spring - y0, half_w * 2.0))
	for i in arches:
		var cx := x0 + step * (float(i) + 0.5)
		var prev := Vector3.ZERO
		for k in 11:
			var a := PI * (1.0 - float(k) / 10.0)
			var p := Vector3(cx + r * cos(a), spring + rise * sin(a), 0)
			if k > 0:
				for z in [-half_w, half_w]:
					var zz: float = zc + z
					var n := Vector3(0, 0, signf(z))
					lm.quad(key, Vector3(prev.x, prev.y, zz), Vector3(p.x, p.y, zz),
						Vector3(p.x, deck_y, zz), Vector3(prev.x, deck_y, zz), n)
				var inward := Vector3(cx - p.x, spring - p.y, 0).normalized()
				lm.quad(key, Vector3(prev.x, prev.y, zc - half_w), Vector3(p.x, p.y, zc - half_w),
					Vector3(p.x, p.y, zc + half_w), Vector3(prev.x, prev.y, zc + half_w), inward)
			prev = p
	lm.box(key, Vector3((x0 + x1) * 0.5, deck_y - 0.3, zc), Vector3(x1 - x0, 0.6, half_w * 2.0))
	lm.box(key, Vector3((x0 + x1) * 0.5, deck_y + 0.5, zc + half_w), Vector3(x1 - x0, 1.0, 0.6))
	lm.box(key, Vector3((x0 + x1) * 0.5, deck_y + 0.5, zc - half_w), Vector3(x1 - x0, 1.0, 0.6))

## Gilded ball and cross finial standing on `base`, `h` tall in total.
static func finial(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	lm.lathe(key, base, dome(h * 0.14, h * 0.2, 5), 8)
	lm.box(key, base + Vector3(0, h * 0.2 + h * 0.4, 0), Vector3(h * 0.05, h * 0.8, h * 0.05))
	lm.box(key, base + Vector3(0, h * 0.2 + h * 0.6, 0), Vector3(h * 0.3, h * 0.05, h * 0.05))
